package com.shadowchat.designsystem

import android.animation.ValueAnimator
import androidx.compose.animation.core.FiniteAnimationSpec
import androidx.compose.animation.core.tween
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

object ShadowMotion {
    const val PressMillis = 110
    const val StateTransitionMillis = 180
    const val ScreenTransitionMillis = 220

    val PressedScale = 0.985f
    val SelectedScale = 1.06f

    fun floatSpec(enabled: Boolean): FiniteAnimationSpec<Float> = tween(
        durationMillis = if (enabled) StateTransitionMillis else 0,
    )

    fun dpSpec(enabled: Boolean): FiniteAnimationSpec<Dp> = tween(
        durationMillis = if (enabled) StateTransitionMillis else 0,
    )
}

@Composable
fun shadowMotionEnabled(): Boolean = remember {
    ValueAnimator.areAnimatorsEnabled()
}

fun shadowScreenTransitionMillis(enabled: Boolean): Int = if (enabled) {
    ShadowMotion.ScreenTransitionMillis
} else {
    0
}
