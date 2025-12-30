package com.statshark.nfl.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

// StatShark Colors
private val SharkBlue = Color(0xFF1E3A8A)
private val SharkTeal = Color(0xFF14B8A6)
private val SharkGray = Color(0xFF64748B)

private val DarkColorScheme = darkColorScheme(
    primary = SharkTeal,
    secondary = SharkBlue,
    tertiary = SharkGray
)

private val LightColorScheme = lightColorScheme(
    primary = SharkBlue,
    secondary = SharkTeal,
    tertiary = SharkGray

    /* Other default colors to override
    background = Color(0xFFFFFBFE),
    surface = Color(0xFFFFFBFE),
    onPrimary = Color.White,
    onSecondary = Color.White,
    onTertiary = Color.White,
    onBackground = Color(0xFF1C1B1F),
    onSurface = Color(0xFF1C1B1F),
    */
)

@Composable
fun StatSharkTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}
