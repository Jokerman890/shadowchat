package com.shadowchat.designsystem

import androidx.compose.ui.graphics.Color

enum class ShadowTrustTone {
    Verified,
    Standard,
    Reduced,
}

object ShadowColors {
    val Porcelain = Color(0xFFFFFBFF)
    val LavenderMist = Color(0xFFF3EEFF)
    val IceBlue = Color(0xFFEAF5FF)
    val Blush = Color(0xFFFFEEF7)
    val GlassSurface = Color(0xEFFFFFFF)
    val GlassStroke = Color(0x99FFFFFF)
    val DeepText = Color(0xFF191327)
    val SoftText = Color(0xFF6E6680)
    val AccentStart = Color(0xFF7B61FF)
    val AccentEnd = Color(0xFF39A7FF)
    val VerifiedTrust = Color(0xFF22B573)
    val StandardTrust = Color(0xFF918AA5)
    val ReducedTrust = Color(0xFFFF9F2E)
    val UnreadBadge = Color(0xFF6757FF)
    val IncomingBubble = Color(0xF7FFFFFF)
    val OutgoingBubble = Color(0xFFEDE7FF)

    fun trustColor(tone: ShadowTrustTone): Color = when (tone) {
        ShadowTrustTone.Verified -> VerifiedTrust
        ShadowTrustTone.Standard -> StandardTrust
        ShadowTrustTone.Reduced -> ReducedTrust
    }
}
