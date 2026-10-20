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

/** The status packet the ESP32 sends (8 bytes in protocol 1, 10 in protocol 2). */
data class BmsStatus(
    val packMilliVolts: Int,
    val soc: Int,
    val live: Boolean,
    val fresh: Boolean,
    val lastCommand: BmsCommand?,
    val lastResult: Int,
    val commandCounter: Int,
    val rawStreaming: Boolean = false,
    val rawDropped: Int = 0,
) {
    val packVolts: Float get() = packMilliVolts / 1000f
    val lastCommandSucceeded: Boolean get() = lastResult == 0

    companion object {
        private const val FLAG_LIVE = 0x01
        private const val FLAG_FRESH = 0x02
        private const val FLAG_RAW = 0x04

        fun parse(bytes: ByteArray): BmsStatus? {
            if (bytes.size < 8) return null
            fun u8(i: Int) = bytes[i].toInt() and 0xFF
            val flags = u8(3)
            return BmsStatus(
                packMilliVolts = u8(0) or (u8(1) shl 8),
                soc = u8(2),
                live = flags and FLAG_LIVE != 0,
                fresh = flags and FLAG_FRESH != 0,
                lastCommand = BmsCommand.fromCode(u8(4)),
                lastResult = u8(5),
                commandCounter = u8(6),
                rawStreaming = flags and FLAG_RAW != 0,
                rawDropped = if (bytes.size >= 10) u8(8) or (u8(9) shl 8) else 0,
            )
        }
    }
}

/** One CAN frame seen (or sent, [tx]) by the ESP32. [timeMs] is the ESP32's clock. */
class CanFrame(
    val timeMs: Long,
    val id: Int,
    val extended: Boolean,
    val rtr: Boolean,
    val data: ByteArray,
    val tx: Boolean,
) {
    companion object {
        private const val RECORD_SIZE = 17
        private const val EFF_FLAG = 0x80000000.toInt()
        private const val RTR_FLAG = 0x40000000
        private const val TX_FLAG = 0x80

        /** Splits a CAN monitor notification into frames. */
        fun parseRecords(bytes: ByteArray): List<CanFrame> {
            fun u8(i: Int) = bytes[i].toInt() and 0xFF
            fun u32(i: Int) = u8(i) or (u8(i + 1) shl 8) or (u8(i + 2) shl 16) or (u8(i + 3) shl 24)
            val frames = ArrayList<CanFrame>(bytes.size / RECORD_SIZE)
            var p = 0
            while (p + RECORD_SIZE <= bytes.size) {
                val rawId = u32(p + 4)
                val extended = rawId and EFF_FLAG != 0
                val dlcByte = u8(p + 8)
                val dlc = (dlcByte and 0x0F).coerceAtMost(8)
                frames += CanFrame(
                    timeMs = u32(p).toLong() and 0xFFFFFFFFL,
                    id = if (extended) rawId and 0x1FFFFFFF else rawId and 0x7FF,
                    extended = extended,
                    rtr = rawId and RTR_FLAG != 0,
                    data = bytes.copyOfRange(p + 9, p + 9 + dlc),
                    tx = dlcByte and TX_FLAG != 0,
                )
                p += RECORD_SIZE
            }
            return frames
        }
    }
}
