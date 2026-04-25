package com.shadowchat.designsystem

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

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
)

private val DarkColorScheme = darkColorScheme(
    primary = ShadowColors.UnreadBadge,
)
