package dev.appu.bmsremote.monitor

import dev.appu.bmsremote.ble.CanFrame
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** Payloads are taken from the Ola S1 Air ride logs (2026-10-21). */
class RideDataTest {

    private var phoneUs = 0L
    private val ride = RideData { phoneUs }

    private fun frame(timeUs: Long, id: Int, vararg bytes: Int) =
        CanFrame(timeUs, id, extended = false, rtr = false, data = ByteArray(bytes.size) { bytes[it].toByte() }, tx = false)

    private fun feed(atPhoneUs: Long, vararg frames: CanFrame) {
        phoneUs = atPhoneUs
        ride.onFrames(frames.toList())
    }

    private fun value(signal: RideSignal) = ride.snapshot().values[signal]

    @Test
    fun decodesRideSignals() {
        feed(
            5_000_000,
            frame(1_000_000, 0x313, 0xBB, 0x01, 0, 0, 0xB8, 0x0B, 0x0D, 0x02), // 44.3 km/h, 3000 m, 525 rpm
            frame(1_000_000, 0x11C, 0x06, 0x22, 0xC5, 0x6F, 0x0F, 0x05, 0, 0),  // 50.466 V
            frame(1_000_000, 0x223, 0xE8, 0x03, 0, 0, 0, 0x1E, 0x8D, 0),       // 36126 -> +61.26 A
            frame(1_000_000, 0x113, 0x02, 0x5A, 0x01, 0, 0, 0, 0x20, 0xCB),    // throttle 346
            frame(1_000_000, 0x225, 0, 0, 0, 0, 0, 70, 0, 0),                   // regen 70
            frame(1_000_000, 0x64D, 0xB7, 0x0B, 0, 0, 0xCF, 0x07, 0, 0),         // brake bit set
            frame(1_000_000, 0x352, 0x27, 0, 0, 0, 0, 0, 0, 0),                 // 39 %
            frame(1_000_000, 0x794, 0x4F, 0x01, 0, 0, 0x43, 0x01, 0, 0),         // 33.5 °C
            frame(1_000_000, 0x1A5, 0xB8, 0x0E, 0xBA, 0x0E, 0xBB, 0x0E, 0xB5, 0x0E),
            frame(1_000_000, 0x1AA, 0xBC, 0x0E, 0xB3, 0x0E, 0xBA, 0x0E, 0, 0),  // trailing 0 is not a cell
        )
        assertEquals(44.3f, value(RideSignal.Speed)!!, 0.01f)
        assertEquals(3000f, value(RideSignal.Trip)!!, 0f)
        assertEquals(525f, value(RideSignal.WheelRpm)!!, 0f)
        assertEquals(50.466f, value(RideSignal.Voltage)!!, 0.001f)
        assertEquals(61.26f, value(RideSignal.Current)!!, 0.01f)
        assertEquals(50.466f * 61.26f / 1000f, value(RideSignal.Power)!!, 0.01f)
        assertEquals(346f, value(RideSignal.Throttle)!!, 0f)
        assertEquals(70f, value(RideSignal.Regen)!!, 0f)
        assertEquals(1f, value(RideSignal.Brake)!!, 0f)
        assertEquals(39f, value(RideSignal.Soc)!!, 0f)
        assertEquals(33.5f, value(RideSignal.MotorTemp)!!, 0.01f)
        assertEquals(3.763f, value(RideSignal.CellMin)!!, 0.0001f)
        assertEquals(3.772f, value(RideSignal.CellMax)!!, 0.0001f)
    }

    @Test
    fun regenGivesNegativeCurrentAndPower() {
        feed(
            1_000_000,
            frame(0, 0x11C, 0x02, 0xE1, 0xD1, 0, 0, 0, 0, 0),   // 53.729 V
            frame(0, 0x223, 0, 0, 0, 0, 0, 0xE2, 0x60, 0),      // 24802 -> -51.98 A
        )
        assertEquals(-51.98f, value(RideSignal.Current)!!, 0.01f)
        assertTrue(value(RideSignal.Power)!! < -2.7f)
    }

    @Test
    fun keepsTenSecondWindowOnPhoneClock() {
        // ESP32 clock starts at 100 s; the phone's at 500 s. Samples every second for 15 s.
        for (s in 0..15) {
            feed(500_000_000L + s * 1_000_000L, frame(100_000_000L + s * 1_000_000L, 0x313, s * 10, 0, 0, 0, 0, 0, 0, 0))
        }
        val series = ride.snapshot().series.getValue(RideSignal.Speed)
        assertTrue(series.ageSeconds.all { it >= -11f && it <= 0f })
        assertEquals(0f, series.ageSeconds.last(), 0.001f)    // newest sample is "now"
        assertEquals(15f, series.values.last(), 0.001f)       // 150 / 10 km/h
        assertTrue(series.values.size in 11..12)
    }

    @Test
    fun receivingTurnsOffWhenFramesStop() {
        feed(1_000_000, frame(0, 0x352, 39, 0, 0, 0, 0, 0, 0, 0))
        assertTrue(ride.snapshot().receiving)
        phoneUs = 4_000_000
        assertFalse(ride.snapshot().receiving)
    }
}
