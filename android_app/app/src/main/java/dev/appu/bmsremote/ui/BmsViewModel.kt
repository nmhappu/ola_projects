package dev.appu.bmsremote.ui

import android.app.Application
import android.net.Uri
import androidx.core.content.FileProvider
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import dev.appu.bmsremote.ble.BmsBleClient
import dev.appu.bmsremote.ble.BmsCommand
import dev.appu.bmsremote.ble.BmsStatus
import dev.appu.bmsremote.ble.ConnectionState
import dev.appu.bmsremote.monitor.CanRecorder
import dev.appu.bmsremote.monitor.MonitorSnapshot
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class BmsViewModel(app: Application) : AndroidViewModel(app) {

    private val client = BmsBleClient(app, viewModelScope)

    val connection: StateFlow<ConnectionState> = client.connection
    val status: StateFlow<BmsStatus?> = client.status
    val canMonitorSupported: StateFlow<Boolean> = client.canMonitorSupported

    private val _messages = MutableSharedFlow<String>(extraBufferCapacity = 4)
    /** One-off messages for the snackbar. */
    val messages: SharedFlow<String> = _messages.asSharedFlow()

    private val _shares = MutableSharedFlow<Uri>(extraBufferCapacity = 1)
    /** Exported log files, ready for the share sheet. */
    val shares: SharedFlow<Uri> = _shares.asSharedFlow()

    val isBluetoothEnabled: Boolean get() = client.isBluetoothEnabled

    // ---- CAN monitor ----
    private val recorder = CanRecorder()
    private val _monitor = MutableStateFlow(MonitorSnapshot())
    val monitor: StateFlow<MonitorSnapshot> = _monitor.asStateFlow()
    private var monitorOpen = false
    private var streaming = false
    private var markCount = 0
    private var recordingStartedAt: Date? = null
    private var tickerJob: Job? = null

    init {
        client.rawListener = recorder::onFrames
        viewModelScope.launch { client.errors.collect { _messages.emit(it) } }
        viewModelScope.launch {
            // The ESP32 bumps commandCounter for every command it handles; report each one once.
            var lastCounter: Int? = null
            client.status.collect { s ->
                if (s == null) {
                    lastCounter = null
                    return@collect
                }
                val previous = lastCounter
                lastCounter = s.commandCounter
                if (previous != null && previous != s.commandCounter) describe(s)?.let { _messages.emit(it) }
            }
        }
        viewModelScope.launch {
            // The ESP32 stops streaming when the phone disconnects; restart it after a reconnect.
            combine(connection, canMonitorSupported) { c, supported -> c is ConnectionState.Connected && supported }
                .collect { ready ->
                    if (!ready) streaming = false
                    else if (monitorOpen || recorder.isRecording) startStreaming()
                }
        }
    }

    fun connect() = client.connect()
    fun disconnect() = client.disconnect()
    fun choose(address: String) = client.choose(address)

    fun send(command: BmsCommand) {
        if (recorder.isRecording) recorder.mark("app sent ${command.name}")
        client.send(command)
    }

    fun openMonitor() {
        monitorOpen = true
        startStreaming()
        if (tickerJob?.isActive != true) {
            tickerJob = viewModelScope.launch {
                while (isActive) {
                    _monitor.value = recorder.snapshot(status.value?.rawDropped ?: 0)
                    delay(SNAPSHOT_INTERVAL_MS)
                }
            }
        }
    }

    fun closeMonitor() {
        monitorOpen = false
        tickerJob?.cancel()
        // Keep streaming in the background while a recording is running.
        if (!recorder.isRecording) stopStreaming()
        _monitor.value = recorder.snapshot(status.value?.rawDropped ?: 0)
    }

    fun startRecording() {
        markCount = 0
        recordingStartedAt = Date()
        recorder.startRecording()
        startStreaming()
    }

    fun stopRecording() {
        recorder.stopRecording()
        if (!monitorOpen) stopStreaming()
    }

    fun discardRecording() = recorder.discardRecording()

    fun addMark() {
        markCount++
        recorder.mark("Mark $markCount")
        _messages.tryEmit("Mark $markCount added")
    }

    fun exportRecording() {
        val app = getApplication<Application>()
        val started = recordingStartedAt ?: Date()
        val device = (connection.value as? ConnectionState.Connected)?.name ?: "BMS Tool"
        val snapshot = recorder.snapshot(status.value?.rawDropped ?: 0)
        viewModelScope.launch {
            try {
                val uri = withContext(Dispatchers.IO) {
                    val dir = File(app.cacheDir, "exports").apply { mkdirs() }
                    dir.listFiles()?.forEach { it.delete() }   // keep only the newest export
                    val stamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(started)
                    val file = File(dir, "can_log_$stamp.tsv")
                    file.bufferedWriter().use { out ->
                        recorder.writeTo(
                            out,
                            listOf(
                                "BMS Remote CAN log",
                                "device: $device",
                                "started: " + SimpleDateFormat("yyyy-MM-dd HH:mm:ss Z", Locale.US).format(started),
                                "frames: ${snapshot.recordedFrames}, lost by ESP32: ${snapshot.lostFrames}",
                            ),
                        )
                    }
                    FileProvider.getUriForFile(app, "${app.packageName}.files", file)
                }
                _shares.emit(uri)
            } catch (e: Exception) {
                _messages.emit("Export failed: ${e.message}")
            }
        }
    }

    private fun startStreaming() {
        if (streaming || connection.value !is ConnectionState.Connected || !canMonitorSupported.value) return
        streaming = true
        recorder.resetLive()
        client.startCanMonitor()
    }

    private fun stopStreaming() {
        if (!streaming) return
        streaming = false
        client.stopCanMonitor()
    }

    private fun describe(s: BmsStatus): String? {
        if (!s.lastCommandSucceeded) {
            // Result codes from the firmware's SendResult.
            return when (s.lastResult) {
                2 -> "CAN is busy, try again."
                3 -> "CAN bus errors: check CAN-H/CAN-L aren't swapped. The tool is recovering."
                4 -> "No reply on the CAN bus. Is the scooter on and CAN-H/CAN-L connected?"
                else -> "CAN send failed (error ${s.lastResult})."
            }
        }
        return when (s.lastCommand) {
            BmsCommand.BmsReset -> "BMS reset sent"
            BmsCommand.SystemReset -> "System reset sent"
            BmsCommand.FetchData -> "Fetching live data"
            BmsCommand.StopLive, BmsCommand.StartRaw, BmsCommand.StopRaw, null -> null
        }
    }

    override fun onCleared() {
        client.rawListener = null
        client.disconnect()
    }

    private companion object {
        const val SNAPSHOT_INTERVAL_MS = 500L
    }
}
