package com.shadowchat.designsystem

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

object ShadowRadii {
    val Panel = 32.dp
    val Card = 26.dp
    val Bubble = 24.dp
    val Control = 22.dp
}

@Composable
fun ShadowLiquidBackground(
    modifier: Modifier = Modifier,
    content: @Composable BoxScope.() -> Unit,
) {
    val colors = if (isSystemInDarkTheme()) {
        listOf(
            Color(0xFF11101A),
            Color(0xFF1C1830),
            Color(0xFF132437),
            Color(0xFF241829),
        )
    } else {
        listOf(
            ShadowColors.Porcelain,
            ShadowColors.LavenderMist,
            ShadowColors.IceBlue,
            ShadowColors.Blush,
        )
    }

    Box(
        modifier = modifier.background(
            Brush.linearGradient(
                colors = colors,
            ),
        ),
        content = content,
    )
}

@Composable
fun ShadowGlassPanel(
    modifier: Modifier = Modifier,
    radius: Dp = ShadowRadii.Panel,
    content: @Composable () -> Unit,
) {
    val darkTheme = isSystemInDarkTheme()

    Surface(
        modifier = modifier,
        shape = RoundedCornerShape(radius),
        color = if (darkTheme) Color(0xCC1D1A2A) else ShadowColors.GlassSurface,
        contentColor = if (darkTheme) Color(0xFFF7F1FF) else ShadowColors.DeepText,
        border = BorderStroke(1.dp, if (darkTheme) Color(0x33FFFFFF) else ShadowColors.GlassStroke),
        shadowElevation = 14.dp,
        tonalElevation = 0.dp,
        content = content,
    )
}

fun shadowAccentGradient(): Brush = Brush.horizontalGradient(
    colors = listOf(
        ShadowColors.AccentStart,
        ShadowColors.AccentEnd,
    ),
)
