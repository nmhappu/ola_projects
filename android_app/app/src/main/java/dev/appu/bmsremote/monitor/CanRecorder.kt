package dev.appu.bmsremote.monitor

import android.os.SystemClock
import dev.appu.bmsremote.ble.CanFrame
import java.io.Writer

/** One CAN ID in the live table. [changedMask] bit n = byte n changed in the last moment. */
class IdRow(
    val key: Long,
    val label: String,
    val tx: Boolean,
    val data: ByteArray,
    val changedMask: Int,
    val hz: Float,
)

data class MonitorSnapshot(
    val rows: List<IdRow> = emptyList(),
    val framesPerSecond: Float = 0f,
    val totalFrames: Long = 0,
    val lostFrames: Int = 0,
    val recording: Boolean = false,
    val recordedFrames: Int = 0,
    val recordingMs: Long = 0,
    val hasRecording: Boolean = false,
    val recordingFull: Boolean = false,
)

/**
 * Keeps the live per-ID table and, while recording, every frame in order.
 * [onFrames] is called on a Bluetooth thread; everything else on the main thread.
 */
class CanRecorder {

    private class IdState(val label: String, val tx: Boolean) {
        var data = ByteArray(0)
        var count = 0L
        var countAtSnapshot = 0L
        var hz = 0f
        val changedAt = LongArray(8)
    }

    private class Mark(val timeMs: Long, val label: String)

    private val lock = Any()
    private val ids = HashMap<Long, IdState>()
    private val entries = ArrayList<Any>()   // CanFrame or Mark, in arrival order
    private var total = 0L
    private var totalAtSnapshot = 0L
    private var lastSnapshotAt = SystemClock.elapsedRealtime()
    private var lastFrameTimeMs = 0L
    private var recording = false
    private var recordedFrames = 0
    private var recordingFull = false
    private var recordStart = 0L
    private var recordEnd = 0L

    val isRecording: Boolean get() = synchronized(lock) { recording }

    fun onFrames(frames: List<CanFrame>) {
        val now = SystemClock.elapsedRealtime()
        synchronized(lock) {
            for (f in frames) {
                total++
                lastFrameTimeMs = f.timeMs
                val state = ids.getOrPut(keyOf(f)) { IdState(labelOf(f), f.tx) }
                if (state.count > 0) {
                    val old = state.data
                    for (i in f.data.indices) {
                        if (i >= old.size || old[i] != f.data[i]) state.changedAt[i] = now
                    }
                }
                state.data = f.data
                state.count++
                if (recording) {
                    if (recordedFrames < MAX_RECORDED_FRAMES) {
                        entries += f
                        recordedFrames++
                    } else {
                        recordingFull = true
                    }
                }
            }
        }
    }

    /** Clears the live table (the recording is kept). */
    fun resetLive() = synchronized(lock) {
        ids.clear()
        total = 0
        totalAtSnapshot = 0
        lastSnapshotAt = SystemClock.elapsedRealtime()
    }

    fun startRecording() = synchronized(lock) {
        entries.clear()
        recordedFrames = 0
        recordingFull = false
        recordStart = SystemClock.elapsedRealtime()
        recording = true
    }

    fun stopRecording() = synchronized(lock) {
        if (recording) recordEnd = SystemClock.elapsedRealtime()
        recording = false
    }

    fun discardRecording() = synchronized(lock) {
        recording = false
        entries.clear()
        recordedFrames = 0
        recordingFull = false
    }

    /** Adds a "# mark" line at the current position of the recording. */
    fun mark(label: String) = synchronized(lock) {
        if (recording) entries += Mark(lastFrameTimeMs, label)
    }

    fun snapshot(lostFrames: Int): MonitorSnapshot = synchronized(lock) {
        val now = SystemClock.elapsedRealtime()
        val seconds = ((now - lastSnapshotAt) / 1000f).coerceAtLeast(0.001f)
        val rows = ids.entries.sortedBy { it.key }.map { (key, s) ->
            s.hz = (s.count - s.countAtSnapshot) / seconds
            s.countAtSnapshot = s.count
            var mask = 0
            for (i in s.data.indices) {
                if (s.changedAt[i] != 0L && now - s.changedAt[i] < CHANGE_HIGHLIGHT_MS) mask = mask or (1 shl i)
            }
            IdRow(key, s.label, s.tx, s.data, mask, s.hz)
        }
        val fps = (total - totalAtSnapshot) / seconds
        totalAtSnapshot = total
        lastSnapshotAt = now
        MonitorSnapshot(
            rows = rows,
            framesPerSecond = fps,
            totalFrames = total,
            lostFrames = lostFrames,
            recording = recording,
            recordedFrames = recordedFrames,
            recordingMs = if (recording) now - recordStart else recordEnd - recordStart,
            hasRecording = recordedFrames > 0,
            recordingFull = recordingFull,
        )
    }

    /** Writes the recording in the format analyze_cells.py and can_sniffer.ino use. */
    fun writeTo(out: Writer, headerLines: List<String>) {
        val copy = synchronized(lock) { ArrayList(entries) }
        headerLines.forEach { out.write("# $it\n") }
        out.write("# time_ms\tid\tdlc\tdata\n")
        val sb = StringBuilder(64)
        for (e in copy) {
            sb.setLength(0)
            when (e) {
                is Mark -> sb.append("# mark ").append(e.timeMs).append(' ').append(e.label)
                is CanFrame -> {
                    sb.append(e.timeMs).append('\t').append(labelOf(e)).append('\t').append(e.data.size).append('\t')
                    if (e.rtr) sb.append("RTR") else e.data.forEach { sb.append(HEX[it.toInt() and 0xFF]).append(' ') }
                    if (e.tx) sb.append("\tTX")
                }
            }
            sb.append('\n')
            out.write(sb.toString())
        }
    }

    companion object {
        const val MAX_RECORDED_FRAMES = 300_000
        private const val CHANGE_HIGHLIGHT_MS = 1_500L
        private val HEX = Array(256) { "%02X".format(it) }

        private fun keyOf(f: CanFrame): Long =
            (f.id.toLong() and 0x1FFFFFFFL) or (if (f.extended) 1L shl 32 else 0L) or (if (f.tx) 1L shl 33 else 0L)

        fun labelOf(f: CanFrame): String = if (f.extended) "x%08X".format(f.id) else "%03X".format(f.id)
    }
}
