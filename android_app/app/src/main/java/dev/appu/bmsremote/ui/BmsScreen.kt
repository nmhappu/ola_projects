package dev.appu.bmsremote.ui

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularWavyProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.Icon
import androidx.compose.material3.LoadingIndicator
import androidx.compose.material3.MaterialShapes
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.SheetValue
import androidx.compose.material3.rememberBottomSheetState
import androidx.compose.material3.toShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import dev.appu.bmsremote.R
import dev.appu.bmsremote.ble.BmsCommand
import dev.appu.bmsremote.ble.BmsStatus
import dev.appu.bmsremote.ble.ConnectionState
import dev.appu.bmsremote.ble.FoundDevice
import dev.appu.bmsremote.ui.theme.BmsTheme
import kotlinx.coroutines.launch
import java.util.Locale

@Composable
fun BmsScreen(onOpenRide: () -> Unit, onOpenMonitor: () -> Unit, viewModel: BmsViewModel = viewModel()) {
    val connection by viewModel.connection.collectAsStateWithLifecycle()
    val status by viewModel.status.collectAsStateWithLifecycle()
    val monitor by viewModel.monitor.collectAsStateWithLifecycle()
    val snackbar = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()

    LaunchedEffect(viewModel) {
        viewModel.messages.collect { snackbar.showSnackbar(it) }
    }

    val connect = rememberConnectAction(
        isBluetoothEnabled = { viewModel.isBluetoothEnabled },
        onReady = viewModel::connect,
        onDenied = { scope.launch { snackbar.showSnackbar("Bluetooth permission is needed to find the BMS Tool") } },
    )

    BmsContent(
        connection = connection,
        status = status,
        snackbar = snackbar,
        onConnect = connect,
        onDisconnect = viewModel::disconnect,
        onChoose = viewModel::choose,
        onCommand = viewModel::send,
        monitorSubtitle = when {
            monitor.recording -> "Recording · ${"%,d".format(Locale.US, monitor.recordedFrames)} frames"
            monitor.hasRecording -> "Recording ready to export"
            else -> "See, record and export raw CAN frames"
        },
        onOpenRide = onOpenRide,
        onOpenMonitor = onOpenMonitor,
    )
}

@Composable
private fun BmsContent(
    connection: ConnectionState,
    status: BmsStatus?,
    snackbar: SnackbarHostState,
    onConnect: () -> Unit,
    onDisconnect: () -> Unit,
    onChoose: (String) -> Unit,
    onCommand: (BmsCommand) -> Unit,
    monitorSubtitle: String,
    onOpenRide: () -> Unit,
    onOpenMonitor: () -> Unit,
) {
    var confirm by remember { mutableStateOf<BmsCommand?>(null) }
    val connected = connection is ConnectionState.Connected

    Scaffold(snackbarHost = { SnackbarHost(snackbar) }) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp, vertical = 16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Header()
            ConnectionCard(connection, onConnect, onDisconnect)
            BatteryCard(
                status = status,
                connected = connected,
                onStop = { onCommand(BmsCommand.StopLive) },
            )
            Actions(
                enabled = connected,
                live = status?.live == true,
                onFetch = { onCommand(BmsCommand.FetchData) },
                onBmsReset = { confirm = BmsCommand.BmsReset },
                onSystemReset = { confirm = BmsCommand.SystemReset },
            )
            ToolsSection(monitorSubtitle, onOpenRide, onOpenMonitor)
        }
    }

    if (connection is ConnectionState.Choosing) {
        DevicePickerSheet(
            devices = connection.devices,
            onChoose = onChoose,
            onCancel = onDisconnect,
        )
    }

    confirm?.let { command ->
        ConfirmResetDialog(
            command = command,
            onConfirm = {
                onCommand(command)
                confirm = null
            },
            onDismiss = { confirm = null },
        )
    }
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun Header() {
    Column(Modifier.padding(top = 24.dp, bottom = 8.dp, start = 4.dp)) {
        Text("BMS Remote", style = MaterialTheme.typography.displaySmallEmphasized)
        Text(
            "Ola S1 X · ESP32 CAN tool",
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun ConnectionCard(
    state: ConnectionState,
    onConnect: () -> Unit,
    onDisconnect: () -> Unit,
) {
    val colors = MaterialTheme.colorScheme
    val connected = state is ConnectionState.Connected
    val badgeColor by animateColorAsState(
        targetValue = if (connected) colors.primaryContainer else colors.surfaceContainerHighest,
        animationSpec = MaterialTheme.motionScheme.defaultEffectsSpec(),
        label = "badge",
    )
    val (title, subtitle) = when (state) {
        ConnectionState.Disconnected -> "Not connected" to "Tap Connect to find the BMS Tool"
        ConnectionState.Scanning -> "Searching" to "Looking for BMS Tools nearby"
        is ConnectionState.Choosing -> "Choose a tool" to "${state.devices.size} BMS Tools found nearby"
        is ConnectionState.Connecting -> "Connecting" to state.name
        is ConnectionState.Pairing -> "Pairing" to "Enter the ESP32 passkey when Android asks"
        is ConnectionState.Connected -> state.name to "Connected · encrypted"
        is ConnectionState.Failed -> "Couldn't connect" to state.message
    }

    Surface(
        shape = MaterialTheme.shapes.extraLarge,
        color = colors.surfaceContainer,
        modifier = Modifier.fillMaxWidth(),
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Box(
                modifier = Modifier
                    .size(52.dp)
                    .clip(MaterialShapes.Cookie9Sided.toShape())
                    .background(badgeColor),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    painterResource(R.drawable.ic_bluetooth),
                    contentDescription = null,
                    tint = if (connected) colors.onPrimaryContainer else colors.onSurfaceVariant,
                )
            }
            Column(Modifier.weight(1f)) {
                Text(title, style = MaterialTheme.typography.titleMediumEmphasized)
                Text(
                    subtitle,
                    style = MaterialTheme.typography.bodyMedium,
                    color = if (state is ConnectionState.Failed) colors.error else colors.onSurfaceVariant,
                )
            }
            when (state) {
                ConnectionState.Scanning, is ConnectionState.Connecting, is ConnectionState.Pairing ->
                    LoadingIndicator(Modifier.size(44.dp))
                is ConnectionState.Connected ->
                    TextButton(onClick = onDisconnect, shapes = ButtonDefaults.shapes()) { Text("Disconnect") }
                is ConnectionState.Choosing ->
                    TextButton(onClick = onDisconnect, shapes = ButtonDefaults.shapes()) { Text("Cancel") }
                else ->
                    Button(onClick = onConnect, shapes = ButtonDefaults.shapes()) {
                        Text(if (state is ConnectionState.Failed) "Retry" else "Connect")
                    }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun BatteryCard(status: BmsStatus?, connected: Boolean, onStop: () -> Unit) {
    val colors = MaterialTheme.colorScheme
    val live = status?.live == true
    val hasValues = status != null && (status.packMilliVolts > 0 || status.soc > 0)
    val soc = if (hasValues) status.soc.coerceIn(0, 100) else 0
    val progress by animateFloatAsState(
        targetValue = soc / 100f,
        animationSpec = MaterialTheme.motionScheme.slowSpatialSpec(),
        label = "soc",
    )

    Surface(
        shape = MaterialTheme.shapes.extraLarge,
        color = colors.surfaceContainerLow,
        modifier = Modifier.fillMaxWidth(),
    ) {
        Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(20.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    "Battery",
                    style = MaterialTheme.typography.titleMediumEmphasized,
                    modifier = Modifier.weight(1f),
                )
                when {
                    !connected -> StatusPill("Offline", colors.surfaceContainerHighest, colors.onSurfaceVariant)
                    live && status.fresh -> StatusPill("Live", colors.primary, colors.onPrimary, dot = true)
                    live -> StatusPill("No CAN data", colors.errorContainer, colors.onErrorContainer)
                    else -> StatusPill("Paused", colors.secondaryContainer, colors.onSecondaryContainer)
                }
            }

            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(24.dp),
            ) {
                Box(Modifier.size(136.dp), contentAlignment = Alignment.Center) {
                    CircularWavyProgressIndicator(progress = { progress }, modifier = Modifier.fillMaxSize())
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(
                            if (hasValues) "$soc" else "--",
                            style = MaterialTheme.typography.displaySmallEmphasized,
                        )
                        Text("% SOC", style = MaterialTheme.typography.labelMedium, color = colors.onSurfaceVariant)
                    }
                }
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text("Pack voltage", style = MaterialTheme.typography.labelLarge, color = colors.onSurfaceVariant)
                    Text(
                        if (hasValues) String.format(Locale.US, "%.2f V", status.packVolts) else "-- V",
                        style = MaterialTheme.typography.headlineLargeEmphasized,
                    )
                }
            }

            if (live) {
                OutlinedButton(
                    onClick = onStop,
                    shapes = ButtonDefaults.shapes(),
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Icon(painterResource(R.drawable.ic_stop), contentDescription = null, Modifier.size(18.dp))
                    Spacer(Modifier.width(8.dp))
                    Text("Stop live data")
                }
            }
        }
    }
}

@Composable
private fun StatusPill(text: String, container: Color, content: Color, dot: Boolean = false) {
    Surface(shape = CircleShape, color = container, contentColor = content) {
        Row(
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            if (dot) Box(Modifier.size(8.dp).clip(CircleShape).background(content))
            Text(text, style = MaterialTheme.typography.labelLarge)
        }
    }
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun Actions(
    enabled: Boolean,
    live: Boolean,
    onFetch: () -> Unit,
    onBmsReset: () -> Unit,
    onSystemReset: () -> Unit,
) {
    val height = ButtonDefaults.MediumContainerHeight
    val colors = MaterialTheme.colorScheme

    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text(
            "Actions",
            style = MaterialTheme.typography.titleMediumEmphasized,
            modifier = Modifier.padding(start = 4.dp, top = 8.dp),
        )
        Button(
            onClick = onFetch,
            enabled = enabled,
            shapes = ButtonDefaults.shapesFor(height),
            contentPadding = ButtonDefaults.contentPaddingFor(height, hasStartIcon = true),
            modifier = Modifier.fillMaxWidth().heightIn(min = height),
        ) {
            ActionLabel(R.drawable.ic_download, if (live) "Fetch again" else "Fetch data", height)
        }
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            FilledTonalButton(
                onClick = onBmsReset,
                enabled = enabled,
                shapes = ButtonDefaults.shapesFor(height),
                contentPadding = ButtonDefaults.contentPaddingFor(height, hasStartIcon = true),
                modifier = Modifier.weight(1f).heightIn(min = height),
            ) {
                ActionLabel(R.drawable.ic_refresh, "BMS reset", height)
            }
            FilledTonalButton(
                onClick = onSystemReset,
                enabled = enabled,
                shapes = ButtonDefaults.shapesFor(height),
                colors = ButtonDefaults.filledTonalButtonColors(
                    containerColor = colors.errorContainer,
                    contentColor = colors.onErrorContainer,
                ),
                contentPadding = ButtonDefaults.contentPaddingFor(height, hasStartIcon = true),
                modifier = Modifier.weight(1f).heightIn(min = height),
            ) {
                ActionLabel(R.drawable.ic_power, "System reset", height)
            }
        }
        if (!enabled) {
            Text(
                "Connect to the BMS Tool to use these.",
                style = MaterialTheme.typography.bodyMedium,
                color = colors.onSurfaceVariant,
                modifier = Modifier.padding(start = 4.dp),
            )
        }
    }
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun ToolsSection(monitorSubtitle: String, onOpenRide: () -> Unit, onOpenMonitor: () -> Unit) {
    val colors = MaterialTheme.colorScheme
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text(
            "Tools",
            style = MaterialTheme.typography.titleMediumEmphasized,
            modifier = Modifier.padding(start = 4.dp, top = 8.dp),
        )
        ToolEntry(
            icon = R.drawable.ic_speed,
            title = "Ride mode",
            subtitle = "Live speed, power, regen and cells, with graphs",
            badge = colors.primaryContainer,
            onBadge = colors.onPrimaryContainer,
            onClick = onOpenRide,
        )
        ToolEntry(
            icon = R.drawable.ic_list,
            title = "CAN monitor",
            subtitle = monitorSubtitle,
            badge = colors.tertiaryContainer,
            onBadge = colors.onTertiaryContainer,
            onClick = onOpenMonitor,
        )
    }
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun ToolEntry(icon: Int, title: String, subtitle: String, badge: Color, onBadge: Color, onClick: () -> Unit) {
    val colors = MaterialTheme.colorScheme
    Surface(
        onClick = onClick,
        shape = MaterialTheme.shapes.extraLarge,
        color = colors.surfaceContainer,
        modifier = Modifier.fillMaxWidth(),
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Box(
                modifier = Modifier
                    .size(44.dp)
                    .clip(MaterialShapes.Cookie9Sided.toShape())
                    .background(badge),
                contentAlignment = Alignment.Center,
            ) {
                Icon(painterResource(icon), contentDescription = null, tint = onBadge)
            }
            Column(Modifier.weight(1f)) {
                Text(title, style = MaterialTheme.typography.titleMediumEmphasized)
                Text(subtitle, style = MaterialTheme.typography.bodyMedium, color = colors.onSurfaceVariant)
            }
            Icon(painterResource(R.drawable.ic_chevron_right), contentDescription = null, tint = colors.onSurfaceVariant)
        }
    }
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun ActionLabel(icon: Int, text: String, height: Dp) {
    Icon(painterResource(icon), contentDescription = null, Modifier.size(ButtonDefaults.iconSizeFor(height)))
    Spacer(Modifier.width(ButtonDefaults.MediumIconSpacing))
    Text(text, style = ButtonDefaults.textStyleFor(height), maxLines = 1)
}

@OptIn(ExperimentalMaterial3Api::class, ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun DevicePickerSheet(
    devices: List<FoundDevice>,
    onChoose: (String) -> Unit,
    onCancel: () -> Unit,
) {
    ModalBottomSheet(
        onDismissRequest = onCancel,
        // Hidden + Expanded only: the sheet opens fully, no half-height step.
        sheetState = rememberBottomSheetState(SheetValue.Hidden, setOf(SheetValue.Hidden, SheetValue.Expanded)),
    ) {
        Column(
            modifier = Modifier.padding(start = 20.dp, end = 20.dp, bottom = 32.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp),
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                Column(Modifier.weight(1f)) {
                    Text("Choose a BMS Tool", style = MaterialTheme.typography.headlineSmallEmphasized)
                    Text(
                        "Each name ends with the last 4 characters of that ESP32's Bluetooth address.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
                LoadingIndicator(Modifier.size(40.dp))
            }
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                devices.forEachIndexed { index, device ->
                    DeviceRow(
                        device = device,
                        shape = segmentShape(index, devices.size),
                        onClick = { onChoose(device.address) },
                    )
                }
            }
        }
    }
}

/** Grouped-list shape: large outer corners on the first and last item, small ones between. */
private fun segmentShape(index: Int, count: Int): Shape {
    val top = if (index == 0) 24.dp else 6.dp
    val bottom = if (index == count - 1) 24.dp else 6.dp
    return RoundedCornerShape(topStart = top, topEnd = top, bottomStart = bottom, bottomEnd = bottom)
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun DeviceRow(device: FoundDevice, shape: Shape, onClick: () -> Unit) {
    val colors = MaterialTheme.colorScheme
    Surface(
        onClick = onClick,
        shape = shape,
        color = colors.surfaceContainerHigh,
        modifier = Modifier.fillMaxWidth(),
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Box(
                modifier = Modifier
                    .size(44.dp)
                    .clip(MaterialShapes.Cookie9Sided.toShape())
                    .background(colors.secondaryContainer),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    painterResource(R.drawable.ic_bluetooth),
                    contentDescription = null,
                    tint = colors.onSecondaryContainer,
                )
            }
            Column(Modifier.weight(1f)) {
                Text(device.name, style = MaterialTheme.typography.titleMediumEmphasized)
                Text(device.address, style = MaterialTheme.typography.bodySmall, color = colors.onSurfaceVariant)
            }
            SignalBars(device.rssi)
        }
    }
}

@Composable
private fun SignalBars(rssi: Int) {
    val (level, label) = when {
        rssi >= -60 -> 3 to "Strong signal"
        rssi >= -75 -> 2 to "Good signal"
        else -> 1 to "Weak signal"
    }
    val colors = MaterialTheme.colorScheme
    Row(
        horizontalArrangement = Arrangement.spacedBy(3.dp),
        verticalAlignment = Alignment.Bottom,
        modifier = Modifier.semantics { contentDescription = label },
    ) {
        for (bar in 1..3) {
            Box(
                Modifier
                    .width(5.dp)
                    .height((6 + bar * 5).dp)
                    .clip(RoundedCornerShape(2.dp))
                    .background(if (bar <= level) colors.primary else colors.outlineVariant)
            )
        }
    }
}

@Composable
private fun ConfirmResetDialog(command: BmsCommand, onConfirm: () -> Unit, onDismiss: () -> Unit) {
    val (icon, title, body) = when (command) {
        BmsCommand.SystemReset -> Triple(
            R.drawable.ic_power,
            "Reset the S1X system?",
            "Sends the System Reset S1X command (CAN ID 0x7C2) to the scooter. Only do this with the scooter parked.",
        )
        else -> Triple(
            R.drawable.ic_refresh,
            "Reset the BMS?",
            "Sends the BMS Reset command (CAN ID 0x7C1) to the battery management system. Only do this with the scooter parked.",
        )
    }
    AlertDialog(
        onDismissRequest = onDismiss,
        icon = { Icon(painterResource(icon), contentDescription = null) },
        title = { Text(title) },
        text = { Text(body) },
        confirmButton = { TextButton(onClick = onConfirm) { Text("Reset") } },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel") } },
    )
}

/** Asks for Bluetooth permissions and to turn Bluetooth on, then calls [onReady]. */
@SuppressLint("MissingPermission")
@Composable
private fun rememberConnectAction(
    isBluetoothEnabled: () -> Boolean,
    onReady: () -> Unit,
    onDenied: () -> Unit,
): () -> Unit {
    val context = LocalContext.current
    val permissions = remember {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            arrayOf(Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_CONNECT)
        } else {
            arrayOf(Manifest.permission.ACCESS_FINE_LOCATION)
        }
    }
    val enableBluetooth = rememberLauncherForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) {
        if (isBluetoothEnabled()) onReady()
    }
    val connectIfEnabled = {
        if (isBluetoothEnabled()) onReady()
        else enableBluetooth.launch(Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE))
    }
    val requestPermissions = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { results ->
        if (results.values.all { it }) connectIfEnabled() else onDenied()
    }
    return {
        val missing = permissions.any {
            ContextCompat.checkSelfPermission(context, it) != PackageManager.PERMISSION_GRANTED
        }
        if (missing) requestPermissions.launch(permissions) else connectIfEnabled()
    }
}

@Preview(showBackground = true)
@Composable
private fun BmsContentPreview() {
    BmsTheme {
        BmsContent(
            connection = ConnectionState.Connected("OLA BMS Tool"),
            status = BmsStatus(
                packMilliVolts = 52640, soc = 78, live = true, fresh = true,
                lastCommand = BmsCommand.FetchData, lastResult = 0, commandCounter = 1,
            ),
            snackbar = remember { SnackbarHostState() },
            onConnect = {},
            onDisconnect = {},
            onChoose = {},
            onCommand = {},
            monitorSubtitle = "See, record and export raw CAN frames",
            onOpenRide = {},
            onOpenMonitor = {},
        )
    }
}
