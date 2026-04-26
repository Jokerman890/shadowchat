package com.shadowchat.features.chatlist

import com.shadowchat.designsystem.ShadowTrustTone

data class ChatListItemUi(
    val roomId: String,
    val title: String,
    val previewText: String = "",
    val sentAtLabel: String = "",
    val unreadCount: Int,
    val trustLevel: ChatListTrustLevel,
    val isFavorite: Boolean = false,
)

data class ChatListRoomSummary(
    val roomId: String,
    val displayName: String,
    val lastMessagePreview: String = "",
    val lastMessageSentAtLabel: String = "",
    val unreadCount: Int,
    val trustLevel: ChatListTrustLevel,
    val membership: ChatListMembership,
    val isFavorite: Boolean = false,
    val hasUnreadMentions: Boolean = false,
) {
    fun toChatListItemUi(): ChatListItemUi = ChatListItemUi(
        roomId = roomId,
        title = displayName,
        previewText = lastMessagePreview,
        sentAtLabel = lastMessageSentAtLabel,
        unreadCount = unreadCount,
        trustLevel = trustLevel,
        isFavorite = isFavorite,
    )
}

enum class ChatListTrustLevel {
    Verified,
    Standard,
    Reduced,
}

enum class ChatListMembership {
    Joined,
    Invited,
    Left,
    Knocked,
    Banned,
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
