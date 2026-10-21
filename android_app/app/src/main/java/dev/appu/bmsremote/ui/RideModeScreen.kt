package dev.appu.bmsremote.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LoadingIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import dev.appu.bmsremote.R
import dev.appu.bmsremote.ble.ConnectionState
import dev.appu.bmsremote.monitor.RideData
import dev.appu.bmsremote.monitor.RideSignal
import dev.appu.bmsremote.monitor.RideSnapshot
import dev.appu.bmsremote.monitor.Series
import java.util.Locale
import kotlin.math.abs

@Composable
fun RideModeScreen(onBack: () -> Unit, viewModel: BmsViewModel = viewModel()) {
    val connection by viewModel.connection.collectAsStateWithLifecycle()
    val supported by viewModel.canMonitorSupported.collectAsStateWithLifecycle()
    val ride by viewModel.ride.collectAsStateWithLifecycle()
    var graphs by rememberSaveable { mutableStateOf(false) }

    DisposableEffect(viewModel) {
        viewModel.openRide()
        onDispose { viewModel.closeRide() }
    }
    // A mounted phone shouldn't go dark mid-ride.
    val view = LocalView.current
    DisposableEffect(view) {
        view.keepScreenOn = true
        onDispose { view.keepScreenOn = false }
    }

    RideModeContent(
        connected = connection is ConnectionState.Connected,
        supported = supported,
        ride = ride,
        graphs = graphs,
        onGraphsChange = { graphs = it },
        onBack = onBack,
    )
}

@OptIn(ExperimentalMaterial3Api::class, ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun RideModeContent(
    connected: Boolean,
    supported: Boolean,
    ride: RideSnapshot,
    graphs: Boolean,
    onGraphsChange: (Boolean) -> Unit,
    onBack: () -> Unit,
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Ride mode", style = MaterialTheme.typography.titleLargeEmphasized) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(painterResource(R.drawable.ic_arrow_back), contentDescription = "Back")
                    }
                },
                actions = {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        modifier = Modifier.padding(end = 12.dp),
                    ) {
                        Icon(painterResource(R.drawable.ic_chart), contentDescription = null, Modifier.size(20.dp))
                        Text("Graphs", style = MaterialTheme.typography.labelLarge)
                        Switch(
                            checked = graphs,
                            onCheckedChange = onGraphsChange,
                            modifier = Modifier.semantics { contentDescription = "Show graphs" },
                        )
                    }
                },
            )
        },
    ) { padding ->
        Column(Modifier.fillMaxSize().padding(padding)) {
            when {
                !connected -> RideNotice("Connect to a BMS Tool on the main screen first.")
                !supported -> RideNotice("This BMS Tool's firmware can't forward CAN frames. Flash the latest ESP32 firmware.")
                else -> {
                    if (!ride.receiving) WaitingBanner()
                    if (graphs) GraphGrid(ride) else ValueGrid(ride)
                }
            }
        }
    }
}

@Composable
private fun RideNotice(text: String) {
    Surface(
        shape = MaterialTheme.shapes.extraLarge,
        color = MaterialTheme.colorScheme.surfaceContainer,
        modifier = Modifier.fillMaxWidth().padding(20.dp),
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
private fun WaitingBanner() {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        modifier = Modifier.padding(horizontal = 24.dp, vertical = 8.dp),
    ) {
        LoadingIndicator(Modifier.size(32.dp))
        Text(
            "Waiting for data. Is the scooter switched on?",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

private val gridPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 8.dp, bottom = 24.dp)

// ------------------------------------------------------------------ values

@Composable
private fun ValueGrid(ride: RideSnapshot) {
    LazyVerticalGrid(
        columns = GridCells.Fixed(2),
        contentPadding = gridPadding,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        item(span = { GridItemSpan(2) }) { SpeedHero(ride) }
        items(RideSignal.entries.filter { it != RideSignal.Speed }, key = { it.name }) { signal ->
            ValueTile(signal, ride.values[signal])
        }
    }
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun SpeedHero(ride: RideSnapshot) {
    val colors = MaterialTheme.colorScheme
    val power = ride.values[RideSignal.Power]
    Surface(shape = MaterialTheme.shapes.extraLarge, color = colors.primaryContainer, contentColor = colors.onPrimaryContainer) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(24.dp),
            verticalAlignment = Alignment.Bottom,
        ) {
            Column(Modifier.weight(1f)) {
                Text("Speed", style = MaterialTheme.typography.labelLarge)
                Row(verticalAlignment = Alignment.Bottom, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(
                        format(ride.values[RideSignal.Speed], 0),
                        style = MaterialTheme.typography.displayLargeEmphasized,
                    )
                    Text("km/h", style = MaterialTheme.typography.titleMedium, modifier = Modifier.padding(bottom = 10.dp))
                }
            }
            Column(horizontalAlignment = Alignment.End) {
                Text(
                    when {
                        power == null -> "Power"
                        power < -0.05f -> "Regenerating"
                        else -> "Power"
                    },
                    style = MaterialTheme.typography.labelLarge,
                )
                Text(
                    "${format(power, 2)} kW",
                    style = MaterialTheme.typography.headlineMediumEmphasized,
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun ValueTile(signal: RideSignal, value: Float?) {
    val colors = MaterialTheme.colorScheme
    val text = when {
        value == null -> "--"
        signal == RideSignal.Brake -> if (value > 0.5f) "On" else "Off"
        else -> format(value, signal.decimals)
    }
    val highlight = (signal == RideSignal.Brake && value != null && value > 0.5f) ||
        (signal == RideSignal.Regen && value != null && value > 0f)
    Surface(
        shape = RoundedCornerShape(24.dp),
        color = if (highlight) colors.tertiaryContainer else colors.surfaceContainer,
        contentColor = if (highlight) colors.onTertiaryContainer else colors.onSurface,
    ) {
        Column(Modifier.fillMaxWidth().padding(16.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            TileTitle(signal)
            Row(verticalAlignment = Alignment.Bottom, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(text, style = MaterialTheme.typography.headlineSmallEmphasized)
                if (signal.unit.isNotEmpty() && signal != RideSignal.Brake) {
                    Text(signal.unit, style = MaterialTheme.typography.labelMedium, modifier = Modifier.padding(bottom = 4.dp))
                }
            }
        }
    }
}

@Composable
private fun TileTitle(signal: RideSignal) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        Text(
            signal.title,
            style = MaterialTheme.typography.labelLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        if (signal.likely) {
            Surface(shape = CircleShape, color = MaterialTheme.colorScheme.surfaceContainerHighest) {
                Text(
                    "likely",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(horizontal = 6.dp, vertical = 1.dp),
                )
            }
        }
    }
}

// ------------------------------------------------------------------ graphs

@Composable
private fun GraphGrid(ride: RideSnapshot) {
    LazyVerticalGrid(
        columns = GridCells.Fixed(2),
        contentPadding = gridPadding,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        items(RideSignal.entries, key = { it.name }) { signal ->
            GraphTile(signal, ride.values[signal], ride.series[signal])
        }
    }
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun GraphTile(signal: RideSignal, value: Float?, series: Series?) {
    val colors = MaterialTheme.colorScheme
    val lineColor = lineColorFor(signal)
    Surface(shape = RoundedCornerShape(24.dp), color = colors.surfaceContainer) {
        Column(Modifier.fillMaxWidth().padding(14.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            TileTitle(signal)
            Text(
                buildString {
                    append(
                        if (signal == RideSignal.Brake && value != null) (if (value > 0.5f) "On" else "Off")
                        else format(value, signal.decimals),
                    )
                    if (signal.unit.isNotEmpty() && signal != RideSignal.Brake) append(' ').append(signal.unit)
                },
                style = MaterialTheme.typography.titleMediumEmphasized,
            )
            LineChart(series, signal, lineColor, Modifier.fillMaxWidth().height(96.dp))
            Row {
                Text("−10 s", style = MaterialTheme.typography.labelSmall, color = colors.onSurfaceVariant)
                Spacer(Modifier.weight(1f))
                Text("now", style = MaterialTheme.typography.labelSmall, color = colors.onSurfaceVariant)
            }
        }
    }
}

@Composable
private fun lineColorFor(signal: RideSignal): Color {
    val c = MaterialTheme.colorScheme
    return when (signal) {
        RideSignal.Speed, RideSignal.WheelRpm, RideSignal.Trip -> c.primary
        RideSignal.Power, RideSignal.Current, RideSignal.Throttle -> c.tertiary
        RideSignal.Regen, RideSignal.Brake -> c.error
        else -> c.secondary
    }
}

/** A 10-second window: the right edge is now, and older samples slide off the left. */
@Composable
private fun LineChart(series: Series?, signal: RideSignal, color: Color, modifier: Modifier) {
    val gridColor = MaterialTheme.colorScheme.outlineVariant
    val labelColor = MaterialTheme.colorScheme.onSurfaceVariant
    val labelStyle = MaterialTheme.typography.labelSmall
    val range = series?.let { yRange(it, signal) }
    Row(modifier, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        Canvas(Modifier.weight(1f).fillMaxSize()) {
            val w = size.width
            val h = size.height
            // Three guide lines: top, middle, bottom.
            for (i in 0..2) {
                val y = h * i / 2f
                drawLine(gridColor, Offset(0f, y), Offset(w, y), strokeWidth = 1f)
            }
            if (series == null || range == null || series.values.isEmpty()) return@Canvas
            val (lo, hi) = range
            fun x(age: Float) = w * (1f + age / RideData.WINDOW_SECONDS)
            fun y(v: Float) = h * (1f - (v - lo) / (hi - lo))
            // Zero line when the range crosses it (current and power go negative in regen).
            if (lo < 0f && hi > 0f) drawLine(labelColor.copy(alpha = 0.5f), Offset(0f, y(0f)), Offset(w, y(0f)), strokeWidth = 1.5f)
            val path = Path()
            for (i in series.values.indices) {
                val px = x(series.ageSeconds[i]).coerceIn(0f, w)
                val py = y(series.values[i])
                if (i == 0) {
                    path.moveTo(px, py)
                } else {
                    if (signal.stepped) path.lineTo(px, y(series.values[i - 1]))
                    path.lineTo(px, py)
                }
            }
            // Hold the last value up to "now".
            path.lineTo(w, y(series.values.last()))
            drawPath(path, color, style = Stroke(width = 2.5.dp.toPx(), cap = StrokeCap.Round, join = StrokeJoin.Round))
        }
        if (range != null) {
            Column(Modifier.width(36.dp).fillMaxSize(), verticalArrangement = Arrangement.SpaceBetween) {
                Text(axisLabel(range.second), style = labelStyle, color = labelColor)
                Text(axisLabel(range.first), style = labelStyle, color = labelColor)
            }
        }
    }
}

/** Fits the visible samples, at least [RideSignal.minSpan] tall, with a little headroom. */
private fun yRange(series: Series, signal: RideSignal): Pair<Float, Float>? {
    if (series.values.isEmpty()) return null
    var lo = series.values.min()
    var hi = series.values.max()
    if (signal == RideSignal.Brake) return -0.1f to 1.1f
    if (hi - lo < signal.minSpan) {
        val mid = (hi + lo) / 2
        lo = mid - signal.minSpan / 2
        hi = mid + signal.minSpan / 2
    }
    val pad = (hi - lo) * 0.1f
    return (lo - pad) to (hi + pad)
}

private fun axisLabel(v: Float): String = when {
    abs(v) >= 100 -> "%.0f".format(Locale.US, v)
    abs(v) >= 10 -> "%.1f".format(Locale.US, v)
    else -> "%.2f".format(Locale.US, v)
}

private fun format(value: Float?, decimals: Int): String =
    if (value == null) "--" else "%.${decimals}f".format(Locale.US, value)
