package com.shadowchat.features.chatlist

import com.shadowchat.designsystem.ShadowTrustTone

data class ChatListItemUi(
    val roomId: String,
    val title: String,
    val unreadCount: Int,
    val trustLevel: ChatListTrustLevel,
)

enum class ChatListTrustLevel {
    Verified,
    Standard,
    Reduced,
}

fun ChatListTrustLevel.toDesignTone(): ShadowTrustTone = when (this) {
    ChatListTrustLevel.Verified -> ShadowTrustTone.Verified
    ChatListTrustLevel.Standard -> ShadowTrustTone.Standard
    ChatListTrustLevel.Reduced -> ShadowTrustTone.Reduced
}

sealed interface ChatListUiState {
    data object Loading : ChatListUiState
    data class Loaded(val items: List<ChatListItemUi>) : ChatListUiState
    data object Empty : ChatListUiState
    data object Error : ChatListUiState
}

sealed interface ChatListEvent {
    data object Appeared : ChatListEvent
    data object RefreshRequested : ChatListEvent
    data object RetryRequested : ChatListEvent
    data class RoomSelected(val roomId: String) : ChatListEvent
}
