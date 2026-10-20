package dev.appu.bmsremote

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.animation.AnimatedContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import dev.appu.bmsremote.ui.BmsScreen
import dev.appu.bmsremote.ui.CanMonitorScreen
import dev.appu.bmsremote.ui.theme.BmsTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            BmsTheme {
                var showMonitor by rememberSaveable { mutableStateOf(false) }
                BackHandler(enabled = showMonitor) { showMonitor = false }
                // Themed backdrop, so the cross-fade never shows the (light) window background.
                Surface(Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
                    AnimatedContent(targetState = showMonitor, label = "screen") { monitor ->
                        if (monitor) {
                            CanMonitorScreen(onBack = { showMonitor = false })
                        } else {
                            BmsScreen(onOpenMonitor = { showMonitor = true })
                        }
                    }
                }
            }
        }
    }
}
