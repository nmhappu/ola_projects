package dev.appu.bmsremote.ble

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** Packets are built byte by byte as the firmware's flushRaw() lays them out (protocol 3). */
class CanPacketDecoderTest {

    private fun packet(baseUs: Long, vararg records: ByteArray): ByteArray {
        val header = byteArrayOf(
            0x03,
            (baseUs and 0xFF).toByte(), (baseUs shr 8 and 0xFF).toByte(),
            (baseUs shr 16 and 0xFF).toByte(), (baseUs shr 24 and 0xFF).toByte(),
        )
        return records.fold(header) { acc, r -> acc + r }
    }

    private fun bytes(vararg v: Int) = ByteArray(v.size) { v[it].toByte() }

    private fun decoder() = CanPacketDecoder().apply { protocolVersion = 3 }

    @Test
    fun standardFrame() {
        // flags = dlc 8; dt = 25 (250 us); id 0x1A8; 8 data bytes
        val p = packet(1_000_000, bytes(0x08, 25, 0, 0xA8, 0x01, 0xCD, 0x02, 0xC8, 0x02, 0x6B, 0xCD, 0x6B, 0x1D))
        val f = decoder().decode(p).single()
        assertEquals(1_000_250L, f.timeUs)
        assertEquals(0x1A8, f.id)
        assertFalse(f.extended)
        assertFalse(f.rtr)
        assertFalse(f.tx)
        assertArrayEquals(bytes(0xCD, 0x02, 0xC8, 0x02, 0x6B, 0xCD, 0x6B, 0x1D), f.data)
    }

    @Test
    fun mixedRecords() {
        val p = packet(
            500,
            bytes(0x02, 0, 0, 0x52, 0x03, 0x27, 0x00),                     // 0x352, dlc 2
            bytes(0x40 or 0x04, 10, 0, 0x78, 0x56, 0x34, 0x12, 1, 2, 3, 4), // extended 0x12345678, dlc 4
            bytes(0x20 or 0x03, 20, 0, 0x00, 0x01),                         // remote 0x100, dlc 3, no data
            bytes(0x80 or 0x08, 30, 0, 0xC1, 0x07, 0, 0, 0, 0, 0, 0, 0, 0), // TX 0x7C1
        )
        val frames = decoder().decode(p)
        assertEquals(4, frames.size)
        assertEquals(0x352, frames[0].id)
        assertArrayEquals(bytes(0x27, 0x00), frames[0].data)
        assertEquals(0x12345678, frames[1].id)
        assertTrue(frames[1].extended)
        assertEquals(600L, frames[1].timeUs)
        assertArrayEquals(bytes(1, 2, 3, 4), frames[1].data)
        assertTrue(frames[2].rtr)
        assertEquals(0, frames[2].data.size)
        assertTrue(frames[3].tx)
        assertEquals(0x7C1, frames[3].id)
        assertEquals(800L, frames[3].timeUs)
    }

    @Test
    fun clockWrapKeepsCountingUp() {
        val d = decoder()
        val before = d.decode(packet(0xFFFF_FF00, bytes(0x00, 0, 0, 0x11, 0x00))).single()
        val after = d.decode(packet(0x0000_0100, bytes(0x00, 0, 0, 0x11, 0x00))).single()
        assertEquals(0xFFFF_FF00, before.timeUs)
        assertEquals((1L shl 32) + 0x100, after.timeUs)
    }

    @Test
    fun truncatedRecordIsDropped() {
        val p = packet(0, bytes(0x08, 0, 0, 0xA8, 0x01, 1, 2, 3))   // claims 8 bytes, has 3
        assertEquals(0, decoder().decode(p).size)
    }

    @Test
    fun oldFirmwareRecords() {
        // protocol 2: [time ms u32][id u32 with flags][dlc | tx][8 data bytes]
        val rec = bytes(0x10, 0x27, 0, 0, 0xA8, 0x01, 0, 0, 0x88, 9, 8, 7, 6, 5, 4, 3, 2)
        val f = CanPacketDecoder().decode(rec).single()
        assertEquals(10_000_000L, f.timeUs)
        assertEquals(0x1A8, f.id)
        assertTrue(f.tx)
        assertArrayEquals(bytes(9, 8, 7, 6, 5, 4, 3, 2), f.data)
    }

    @Test
    fun statusSplitsLoss() {
        val s = BmsStatus.parse(bytes(0xA0, 0xCD, 39, 0x04, 0, 0, 1, 3, 5, 0, 7, 0))!!
        assertEquals(3, s.protocolVersion)
        assertTrue(s.lossSplitKnown)
        assertEquals(5, s.rawLostAtChip)
        assertEquals(7, s.rawLostOnLink)
        val old = BmsStatus.parse(bytes(0xA0, 0xCD, 39, 0x04, 0, 0, 1, 2, 9, 0))!!
        assertFalse(old.lossSplitKnown)
        assertEquals(9, old.rawLostAtChip)
    }
}
