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
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import dev.appu.bmsremote.ui.BmsScreen
import dev.appu.bmsremote.ui.CanMonitorScreen
import dev.appu.bmsremote.ui.RideModeScreen
import dev.appu.bmsremote.ui.theme.BmsTheme

private enum class Screen { Main, Ride, Monitor }

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            BmsTheme {
                var screen by rememberSaveable { mutableStateOf(Screen.Main) }
                BackHandler(enabled = screen != Screen.Main) { screen = Screen.Main }
                // Themed backdrop, so the cross-fade never shows the (light) window background.
                Surface(Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
                    AnimatedContent(targetState = screen, label = "screen") { current ->
                        when (current) {
                            Screen.Main -> BmsScreen(
                                onOpenRide = { screen = Screen.Ride },
                                onOpenMonitor = { screen = Screen.Monitor },
                            )
                            Screen.Ride -> RideModeScreen(onBack = { screen = Screen.Main })
                            Screen.Monitor -> CanMonitorScreen(onBack = { screen = Screen.Main })
                        }
                    }
                }
            }
        }
    }
}
