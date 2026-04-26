package com.shadowchat.designsystem

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

@Composable
fun ShadowChatTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    MaterialTheme(
        colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme,
        content = content,
    )
}

private val LightColorScheme = lightColorScheme(
    primary = ShadowColors.UnreadBadge,
    onPrimary = Color.White,
    primaryContainer = ShadowColors.OutgoingBubble,
    onPrimaryContainer = ShadowColors.DeepText,
    secondaryContainer = ShadowColors.IceBlue,
    onSecondaryContainer = ShadowColors.DeepText,
    background = ShadowColors.Porcelain,
    onBackground = ShadowColors.DeepText,
    surface = ShadowColors.GlassSurface,
    onSurface = ShadowColors.DeepText,
    surfaceVariant = ShadowColors.IncomingBubble,
    onSurfaceVariant = ShadowColors.SoftText,
)

private val DarkColorScheme = darkColorScheme(
    primary = ShadowColors.UnreadBadge,
    onPrimary = Color.White,
    primaryContainer = Color(0xFF2B2443),
    onPrimaryContainer = Color(0xFFF7F1FF),
    secondaryContainer = Color(0xFF1F3044),
    onSecondaryContainer = Color(0xFFEAF5FF),
    background = Color(0xFF11101A),
    onBackground = Color(0xFFF7F1FF),
    surface = Color(0xE61D1A2A),
    onSurface = Color(0xFFF7F1FF),
    surfaceVariant = Color(0xFF252233),
    onSurfaceVariant = Color(0xFFC9C1D9),
)
