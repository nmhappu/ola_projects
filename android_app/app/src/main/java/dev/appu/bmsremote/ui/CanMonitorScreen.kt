package dev.appu.bmsremote.ui

import android.content.Intent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LoadingIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import dev.appu.bmsremote.R
import dev.appu.bmsremote.ble.ConnectionState
import dev.appu.bmsremote.monitor.CanRecorder
import dev.appu.bmsremote.monitor.IdRow
import dev.appu.bmsremote.monitor.MonitorSnapshot
import java.util.Locale

@Composable
fun CanMonitorScreen(onBack: () -> Unit, viewModel: BmsViewModel = viewModel()) {
    val connection by viewModel.connection.collectAsStateWithLifecycle()
    val supported by viewModel.canMonitorSupported.collectAsStateWithLifecycle()
    val monitor by viewModel.monitor.collectAsStateWithLifecycle()
    val snackbar = remember { SnackbarHostState() }
    val context = LocalContext.current

    DisposableEffect(viewModel) {
        viewModel.openMonitor()
        onDispose { viewModel.closeMonitor() }
    }
    LaunchedEffect(viewModel) {
        viewModel.messages.collect { snackbar.showSnackbar(it) }
    }
    LaunchedEffect(viewModel) {
        viewModel.shares.collect { uri ->
            val send = Intent(Intent.ACTION_SEND).apply {
                type = "text/tab-separated-values"
                putExtra(Intent.EXTRA_STREAM, uri)
                putExtra(Intent.EXTRA_SUBJECT, "CAN log from BMS Remote")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            context.startActivity(Intent.createChooser(send, "Send CAN log"))
        }
    }

    CanMonitorContent(
        connected = connection is ConnectionState.Connected,
        supported = supported,
        monitor = monitor,
        snackbar = snackbar,
        onBack = onBack,
        onStartRecording = viewModel::startRecording,
        onStopRecording = viewModel::stopRecording,
        onMark = viewModel::addMark,
        onExport = viewModel::exportRecording,
        onDiscard = viewModel::discardRecording,
    )
}

@OptIn(ExperimentalMaterial3Api::class, ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun CanMonitorContent(
    connected: Boolean,
    supported: Boolean,
    monitor: MonitorSnapshot,
    snackbar: SnackbarHostState,
    onBack: () -> Unit,
    onStartRecording: () -> Unit,
    onStopRecording: () -> Unit,
    onMark: () -> Unit,
    onExport: () -> Unit,
    onDiscard: () -> Unit,
) {
    Scaffold(
        snackbarHost = { SnackbarHost(snackbar) },
        topBar = {
            TopAppBar(
                title = { Text("CAN monitor", style = MaterialTheme.typography.titleLargeEmphasized) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(painterResource(R.drawable.ic_arrow_back), contentDescription = "Back")
                    }
                },
            )
        },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            when {
                !connected -> Notice("Connect to a BMS Tool on the main screen first.")
                !supported -> Notice("This BMS Tool's firmware can't forward CAN frames. Flash the latest ESP32 firmware.")
                else -> {
                    Stats(monitor)
                    RecordingCard(monitor, onStartRecording, onStopRecording, onMark, onExport, onDiscard)
                    LiveFrames(monitor.rows, Modifier.weight(1f))
                }
            }
        }
    }
}

@Composable
private fun Notice(text: String) {
    Surface(
        shape = MaterialTheme.shapes.extraLarge,
        color = MaterialTheme.colorScheme.surfaceContainer,
        modifier = Modifier.fillMaxWidth(),
    ) {
        Text(
            text,
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(20.dp),
        )
    }
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun Stats(monitor: MonitorSnapshot) {
    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        StatTile("%.0f".format(Locale.US, monitor.framesPerSecond), "frames/s", Modifier.weight(1f))
        StatTile("${monitor.rows.size}", "CAN IDs", Modifier.weight(1f))
        StatTile(
            "${monitor.lostFrames}", "lost",
            Modifier.weight(1f),
            warn = monitor.lostFrames > 0,
        )
    }
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun StatTile(value: String, label: String, modifier: Modifier, warn: Boolean = false) {
    val colors = MaterialTheme.colorScheme
    Surface(
        shape = RoundedCornerShape(20.dp),
        color = if (warn) colors.errorContainer else colors.surfaceContainer,
        contentColor = if (warn) colors.onErrorContainer else colors.onSurface,
        modifier = modifier,
    ) {
        Column(Modifier.padding(horizontal = 16.dp, vertical = 12.dp)) {
            Text(value, style = MaterialTheme.typography.headlineSmallEmphasized)
            Text(
                label,
                style = MaterialTheme.typography.labelMedium,
                color = if (warn) colors.onErrorContainer else colors.onSurfaceVariant,
            )
        }
    }
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun RecordingCard(
    monitor: MonitorSnapshot,
    onStart: () -> Unit,
    onStop: () -> Unit,
    onMark: () -> Unit,
    onExport: () -> Unit,
    onDiscard: () -> Unit,
) {
    val colors = MaterialTheme.colorScheme
    val height = ButtonDefaults.MediumContainerHeight
    Surface(
        shape = MaterialTheme.shapes.extraLarge,
        color = colors.surfaceContainerLow,
        modifier = Modifier.fillMaxWidth(),
    ) {
        Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            when {
                monitor.recording -> {
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        Box(Modifier.size(12.dp).clip(CircleShape).background(colors.error))
                        Text("Recording", style = MaterialTheme.typography.titleMediumEmphasized, modifier = Modifier.weight(1f))
                        Text(
                            "${duration(monitor.recordingMs)} · ${"%,d".format(Locale.US, monitor.recordedFrames)} frames",
                            style = MaterialTheme.typography.bodyMedium,
                            color = colors.onSurfaceVariant,
                        )
                    }
                    Text(
                        if (monitor.recordingFull) {
                            "Recording is full (${"%,d".format(Locale.US, CanRecorder.MAX_RECORDED_FRAMES)} frames). Stop it and export."
                        } else {
                            "Add a mark each time you do something: plug in the charger, switch the scooter on, press a reset."
                        },
                        style = MaterialTheme.typography.bodyMedium,
                        color = if (monitor.recordingFull) colors.error else colors.onSurfaceVariant,
                    )
                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        FilledTonalButton(
                            onClick = onMark,
                            shapes = ButtonDefaults.shapesFor(height),
                            modifier = Modifier.weight(1f).heightIn(min = height),
                        ) {
                            ButtonLabel(R.drawable.ic_flag, "Mark")
                        }
                        Button(
                            onClick = onStop,
                            shapes = ButtonDefaults.shapesFor(height),
                            colors = ButtonDefaults.buttonColors(containerColor = colors.error, contentColor = colors.onError),
                            modifier = Modifier.weight(1f).heightIn(min = height),
                        ) {
                            ButtonLabel(R.drawable.ic_stop, "Stop")
                        }
                    }
                }
                monitor.hasRecording -> {
                    Text("Recording ready", style = MaterialTheme.typography.titleMediumEmphasized)
                    Text(
                        "${"%,d".format(Locale.US, monitor.recordedFrames)} frames over ${duration(monitor.recordingMs)}. " +
                            "Export it and send the file for analysis.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = colors.onSurfaceVariant,
                    )
                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
                        Button(
                            onClick = onExport,
                            shapes = ButtonDefaults.shapesFor(height),
                            modifier = Modifier.weight(1f).heightIn(min = height),
                        ) {
                            ButtonLabel(R.drawable.ic_share, "Export")
                        }
                        TextButton(onClick = onDiscard, shapes = ButtonDefaults.shapes()) { Text("Discard") }
                    }
                }
                else -> {
                    Text("Record", style = MaterialTheme.typography.titleMediumEmphasized)
                    Text(
                        "Capture every CAN frame to a file you can export and send for analysis.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = colors.onSurfaceVariant,
                    )
                    Button(
                        onClick = onStart,
                        shapes = ButtonDefaults.shapesFor(height),
                        modifier = Modifier.fillMaxWidth().heightIn(min = height),
                    ) {
                        ButtonLabel(R.drawable.ic_record, "Start recording")
                    }
                }
            }
        }
    }
}

@Composable
private fun ButtonLabel(icon: Int, text: String) {
    Icon(painterResource(icon), contentDescription = null, Modifier.size(20.dp))
    Spacer(Modifier.width(8.dp))
    Text(text, style = MaterialTheme.typography.titleMedium)
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun LiveFrames(rows: List<IdRow>, modifier: Modifier) {
    Column(modifier, verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                "Live frames",
                style = MaterialTheme.typography.titleMediumEmphasized,
                modifier = Modifier.weight(1f).padding(start = 4.dp),
            )
            Text(
                "changed bytes highlighted",
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        if (rows.isEmpty()) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                modifier = Modifier.padding(start = 4.dp),
            ) {
                LoadingIndicator(Modifier.size(36.dp))
                Text(
                    "Waiting for CAN frames. Is the scooter switched on?",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        } else {
            LazyColumn(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                itemsIndexed(rows, key = { _, row -> row.key }) { index, row ->
                    FrameRow(row, segmentShape(index, rows.size))
                }
                item { Spacer(Modifier.size(16.dp)) }
            }
        }
    }
}

@Composable
private fun FrameRow(row: IdRow, shape: androidx.compose.ui.graphics.Shape) {
    val colors = MaterialTheme.colorScheme
    val bytes = buildAnnotatedString {
        row.data.forEachIndexed { i, b ->
            if (i > 0) append(' ')
            val text = "%02X".format(b.toInt() and 0xFF)
            if (row.changedMask and (1 shl i) != 0) {
                withStyle(SpanStyle(color = colors.primary, fontWeight = FontWeight.Bold)) { append(text) }
            } else {
                append(text)
            }
        }
    }
    Surface(shape = shape, color = colors.surfaceContainer, modifier = Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Column(Modifier.width(76.dp)) {
                Text(
                    if (row.tx) "${row.label} TX" else row.label,
                    style = MaterialTheme.typography.titleSmall,
                    fontFamily = FontFamily.Monospace,
                    color = if (row.tx) colors.tertiary else colors.onSurface,
                )
                Text(
                    "%.1f Hz".format(Locale.US, row.hz),
                    style = MaterialTheme.typography.labelSmall,
                    color = colors.onSurfaceVariant,
                )
            }
            Text(bytes, style = MaterialTheme.typography.bodyMedium, fontFamily = FontFamily.Monospace)
        }
    }
}

private fun segmentShape(index: Int, count: Int): RoundedCornerShape {
    val top = if (index == 0) 20.dp else 4.dp
    val bottom = if (index == count - 1) 20.dp else 4.dp
    return RoundedCornerShape(topStart = top, topEnd = top, bottomStart = bottom, bottomEnd = bottom)
}

private fun duration(ms: Long): String {
    val s = ms / 1000
    return "%d:%02d".format(Locale.US, s / 60, s % 60)
}
