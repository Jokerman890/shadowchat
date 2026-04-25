package com.shadowchat.designsystem

import androidx.compose.ui.graphics.Color

enum class ShadowTrustTone {
    Verified,
    Standard,
    Reduced,
}

object ShadowColors {
    val VerifiedTrust = Color(0xFF2EAD6B)
    val StandardTrust = Color(0xFF8A8D93)
    val ReducedTrust = Color(0xFFC77700)
    val UnreadBadge = Color(0xFF2B6DFF)

    fun trustColor(tone: ShadowTrustTone): Color = when (tone) {
        ShadowTrustTone.Verified -> VerifiedTrust
        ShadowTrustTone.Standard -> StandardTrust
        ShadowTrustTone.Reduced -> ReducedTrust
    }
}
