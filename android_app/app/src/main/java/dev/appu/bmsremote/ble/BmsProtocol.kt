package dev.appu.bmsremote.ble

import java.util.UUID

/** GATT layout of the ESP32 firmware. Keep in sync with esp32_sn65hvd230.ino and esp32_mcp2515.ino. */
object BmsProtocol {
    val SERVICE_UUID: UUID = UUID.fromString("8d3a0001-6c2b-4f6e-9b6a-2f1c5e7a4b10")
    val COMMAND_UUID: UUID = UUID.fromString("8d3a0002-6c2b-4f6e-9b6a-2f1c5e7a4b10")
    val STATUS_UUID: UUID = UUID.fromString("8d3a0003-6c2b-4f6e-9b6a-2f1c5e7a4b10")
    /** CAN monitor records (firmware protocol version 2 and newer). */
    val RAW_UUID: UUID = UUID.fromString("8d3a0004-6c2b-4f6e-9b6a-2f1c5e7a4b10")
    val CCCD_UUID: UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")
}

enum class BmsCommand(val code: Byte) {
    BmsReset(0x01),
    SystemReset(0x02),
    FetchData(0x03),
    StopLive(0x04),
    StartRaw(0x05),
    StopRaw(0x06);

    companion object {
        fun fromCode(code: Int): BmsCommand? = entries.firstOrNull { it.code.toInt() == code }
    }
}

/** The status packet the ESP32 sends (8 bytes in protocol 1, 10 in 2, 12 in 3). */
data class BmsStatus(
    val packMilliVolts: Int,
    val soc: Int,
    val live: Boolean,
    val fresh: Boolean,
    val lastCommand: BmsCommand?,
    val lastResult: Int,
    val commandCounter: Int,
    val protocolVersion: Int = 1,
    val rawStreaming: Boolean = false,
    /** CAN monitor frames lost at the CAN chip (protocol 3), or lost anywhere (protocol 2). */
    val rawLostAtChip: Int = 0,
    /** CAN monitor frames lost on the Bluetooth link (protocol 3 only). */
    val rawLostOnLink: Int = 0,
) {
    val packVolts: Float get() = packMilliVolts / 1000f
    val lastCommandSucceeded: Boolean get() = lastResult == 0
    /** Older firmware reports one combined loss figure. */
    val lossSplitKnown: Boolean get() = protocolVersion >= 3

    companion object {
        private const val FLAG_LIVE = 0x01
        private const val FLAG_FRESH = 0x02
        private const val FLAG_RAW = 0x04

        fun parse(bytes: ByteArray): BmsStatus? {
            if (bytes.size < 8) return null
            fun u8(i: Int) = bytes[i].toInt() and 0xFF
            fun u16(i: Int) = u8(i) or (u8(i + 1) shl 8)
            val flags = u8(3)
            return BmsStatus(
                packMilliVolts = u16(0),
                soc = u8(2),
                live = flags and FLAG_LIVE != 0,
                fresh = flags and FLAG_FRESH != 0,
                lastCommand = BmsCommand.fromCode(u8(4)),
                lastResult = u8(5),
                commandCounter = u8(6),
                protocolVersion = u8(7),
                rawStreaming = flags and FLAG_RAW != 0,
                rawLostAtChip = if (bytes.size >= 10) u16(8) else 0,
                rawLostOnLink = if (bytes.size >= 12) u16(10) else 0,
            )
        }
    }
}

/** One CAN frame seen (or sent, [tx]) by the ESP32. [timeUs] is the ESP32's clock in microseconds. */
class CanFrame(
    val timeUs: Long,
    val id: Int,
    val extended: Boolean,
    val rtr: Boolean,
    val data: ByteArray,
    val tx: Boolean,
) {
    val timeMs: Long get() = timeUs / 1000
}

/**
 * Turns CAN monitor notifications into frames. Protocol 3 sends a compact,
 * variable-length format with microsecond timestamps; protocol 2 sent fixed
 * 17-byte records with millisecond timestamps.
 */
class CanPacketDecoder {
    @Volatile var protocolVersion = 2
    private var lastBaseUs = -1L
    private var wrapOffsetUs = 0L

    fun reset() {
        lastBaseUs = -1L
        wrapOffsetUs = 0L
    }

    fun decode(bytes: ByteArray): List<CanFrame> =
        if (protocolVersion >= 3 && bytes.isNotEmpty() && bytes[0] == FORMAT_V3) decodeV3(bytes) else decodeV2(bytes)

    private fun decodeV3(bytes: ByteArray): List<CanFrame> {
        fun u8(i: Int) = bytes[i].toInt() and 0xFF
        fun u16(i: Int) = u8(i) or (u8(i + 1) shl 8)
        fun u32(i: Int) = (u16(i).toLong() or (u16(i + 2).toLong() shl 16))
        if (bytes.size < 5) return emptyList()

        // The ESP32's microsecond clock wraps every ~71 minutes; keep counting upwards.
        val base = u32(1)
        if (lastBaseUs >= 0 && base < lastBaseUs && lastBaseUs - base > WRAP / 2) wrapOffsetUs += WRAP
        lastBaseUs = base
        val baseUs = wrapOffsetUs + base

        val frames = ArrayList<CanFrame>(bytes.size / 13)
        var p = 5
        while (p + 3 <= bytes.size) {
            val flags = u8(p)
            val dt = u16(p + 1) * 10L
            val extended = flags and REC_EXT != 0
            val rtr = flags and REC_RTR != 0
            val dlc = (flags and 0x0F).coerceAtMost(8)
            val idSize = if (extended) 4 else 2
            val dataLen = if (rtr) 0 else dlc
            if (p + 3 + idSize + dataLen > bytes.size) break
            val id = if (extended) u32(p + 3).toInt() and 0x1FFFFFFF else u16(p + 3) and 0x7FF
            val dataStart = p + 3 + idSize
            frames += CanFrame(
                timeUs = baseUs + dt,
                id = id,
                extended = extended,
                rtr = rtr,
                data = bytes.copyOfRange(dataStart, dataStart + dataLen),
                tx = flags and REC_TX != 0,
            )
            p = dataStart + dataLen
        }
        return frames
    }

    private fun decodeV2(bytes: ByteArray): List<CanFrame> {
        fun u8(i: Int) = bytes[i].toInt() and 0xFF
        fun u32(i: Int) = u8(i) or (u8(i + 1) shl 8) or (u8(i + 2) shl 16) or (u8(i + 3) shl 24)
        val frames = ArrayList<CanFrame>(bytes.size / V2_RECORD_SIZE)
        var p = 0
        while (p + V2_RECORD_SIZE <= bytes.size) {
            val rawId = u32(p + 4)
            val extended = rawId and V2_EFF_FLAG != 0
            val dlcByte = u8(p + 8)
            val dlc = (dlcByte and 0x0F).coerceAtMost(8)
            frames += CanFrame(
                timeUs = (u32(p).toLong() and 0xFFFFFFFFL) * 1000,
                id = if (extended) rawId and 0x1FFFFFFF else rawId and 0x7FF,
                extended = extended,
                rtr = rawId and V2_RTR_FLAG != 0,
                data = bytes.copyOfRange(p + 9, p + 9 + dlc),
                tx = dlcByte and REC_TX != 0,
            )
            p += V2_RECORD_SIZE
        }
        return frames
    }

    private companion object {
        const val FORMAT_V3: Byte = 0x03
        const val REC_RTR = 0x20
        const val REC_EXT = 0x40
        const val REC_TX = 0x80
        const val WRAP = 1L shl 32
        const val V2_RECORD_SIZE = 17
        const val V2_EFF_FLAG = 0x80000000.toInt()
        const val V2_RTR_FLAG = 0x40000000
    }
}
