package dev.appu.bmsremote.monitor

import dev.appu.bmsremote.ble.CanFrame

/**
 * Signals decoded from the scooter's CAN bus (logged on an Ola S1 Air).
 * [likely] marks decodings that fit the logs but aren't confirmed yet.
 * [minSpan] keeps a nearly flat graph from magnifying noise.
 */
enum class RideSignal(
    val title: String,
    val unit: String,
    val decimals: Int,
    val minSpan: Float,
    val likely: Boolean = false,
    val stepped: Boolean = false,
) {
    Speed("Speed", "km/h", 1, 20f),
    Power("Power", "kW", 2, 1f),
    Current("Pack current", "A", 1, 20f),
    Voltage("Pack voltage", "V", 2, 1f),
    Throttle("Throttle", "raw", 0, 50f),
    Regen("Regen level", "", 0, 20f, stepped = true),
    Brake("Brake", "", 0, 1f, likely = true, stepped = true),
    WheelRpm("Wheel speed", "rpm", 0, 100f),
    Soc("Charge", "%", 0, 2f, stepped = true),
    CellMin("Lowest cell", "V", 3, 0.05f),
    CellMax("Highest cell", "V", 3, 0.05f),
    MotorTemp("Motor temp", "°C", 1, 2f, likely = true),
    Trip("Trip", "m", 0, 10f),
}

/** One signal's recent samples: [ageSeconds] is negative (seconds before now), oldest first. */
class Series(val ageSeconds: FloatArray, val values: FloatArray)

data class RideSnapshot(
    val values: Map<RideSignal, Float> = emptyMap(),
    val series: Map<RideSignal, Series> = emptyMap(),
    /** True while frames arrived in the last 2 seconds. */
    val receiving: Boolean = false,
)

/**
 * Turns the raw CAN stream into ride signals and keeps the last [HISTORY_US] of each.
 * [onFrames] runs on a Bluetooth thread, [snapshot] on the main thread.
 */
class RideData(private val clockUs: () -> Long) {

    private class Sample(val timeUs: Long, val value: Float)

    private val lock = Any()
    private val history = RideSignal.entries.associateWith { ArrayDeque<Sample>() }
    private val latest = HashMap<RideSignal, Float>()
    private val cells = HashMap<Int, Float>()   // (id << 2 | slot) -> volts
    private var offsetUs: Long? = null          // phone clock minus ESP32 clock
    private var lastArrivalUs = 0L

    fun clear() = synchronized(lock) {
        history.values.forEach { it.clear() }
        latest.clear()
        cells.clear()
        offsetUs = null
    }

    fun onFrames(frames: List<CanFrame>) {
        val arrivalUs = clockUs()
        synchronized(lock) {
            lastArrivalUs = arrivalUs
            for (f in frames) {
                if (f.tx || f.extended || f.rtr) continue
                decode(f, phoneTime(f.timeUs, arrivalUs))
            }
        }
    }

    /**
     * Maps the ESP32's timestamp onto the phone's clock. Bluetooth only ever adds
     * delay, so the smallest (arrival - frame time) seen is the closest to the truth.
     * A big jump means the ESP32 restarted: start over.
     */
    private fun phoneTime(frameUs: Long, arrivalUs: Long): Long {
        val candidate = arrivalUs - frameUs
        val current = offsetUs
        offsetUs = if (current == null || kotlin.math.abs(candidate - current) > 2_000_000) candidate else minOf(current, candidate)
        return frameUs + offsetUs!!
    }

    private fun decode(f: CanFrame, t: Long) {
        val d = f.data
        fun u16(i: Int) = if (d.size >= i + 2) (d[i].toInt() and 0xFF) or ((d[i + 1].toInt() and 0xFF) shl 8) else null
        when (f.id) {
            0x313 -> {
                u16(0)?.let { add(RideSignal.Speed, t, it / 10f) }
                u16(4)?.let { add(RideSignal.Trip, t, it.toFloat()) }
                u16(6)?.let { add(RideSignal.WheelRpm, t, it.toFloat()) }
            }
            0x223 -> u16(5)?.let {
                add(RideSignal.Current, t, (it - 30_000) / 100f)
                updatePower(t)
            }
            0x11C -> u16(1)?.let {
                add(RideSignal.Voltage, t, it / 1000f)
                updatePower(t)
            }
            0x113 -> u16(1)?.let { add(RideSignal.Throttle, t, it.toFloat()) }
            0x225 -> if (d.size > 5) add(RideSignal.Regen, t, (d[5].toInt() and 0xFF).toFloat())
            0x64D -> if (d.size > 1) add(RideSignal.Brake, t, (d[1].toInt() and 0x01).toFloat())
            0x352 -> if (d.isNotEmpty()) add(RideSignal.Soc, t, (d[0].toInt() and 0xFF).toFloat())
            0x794 -> u16(0)?.let { add(RideSignal.MotorTemp, t, it / 10f) }
            0x1A5, 0x1A6, 0x1A9, 0x1AA -> {
                val slots = if (f.id == 0x1AA) 3 else 4
                for (slot in 0 until slots) {
                    val mv = u16(slot * 2) ?: continue
                    if (mv in 2000..4500) cells[(f.id shl 2) or slot] = mv / 1000f
                }
                if (cells.isNotEmpty()) {
                    add(RideSignal.CellMin, t, cells.values.min())
                    add(RideSignal.CellMax, t, cells.values.max())
                }
            }
        }
    }

    private fun updatePower(t: Long) {
        val v = latest[RideSignal.Voltage] ?: return
        val a = latest[RideSignal.Current] ?: return
        add(RideSignal.Power, t, v * a / 1000f)
    }

    private fun add(signal: RideSignal, t: Long, value: Float) {
        latest[signal] = value
        val q = history.getValue(signal)
        q.addLast(Sample(t, value))
        while (q.isNotEmpty() && q.first().timeUs < t - HISTORY_US) q.removeFirst()
    }

    fun snapshot(): RideSnapshot = synchronized(lock) {
        val now = clockUs()
        val series = history.mapValues { (_, q) ->
            val visible = q.filter { it.timeUs >= now - HISTORY_US }
            Series(
                FloatArray(visible.size) { (visible[it].timeUs - now) / 1_000_000f },
                FloatArray(visible.size) { visible[it].value },
            )
        }
        RideSnapshot(HashMap(latest), series, receiving = lastArrivalUs > 0 && now - lastArrivalUs < 2_000_000)
    }

    companion object {
        const val WINDOW_SECONDS = 10f
        /** A little more than the window, so the line runs in from the left edge. */
        private const val HISTORY_US = 11_000_000L
    }
}
