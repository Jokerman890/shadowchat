package com.shadowchat.features.chatlist

import android.content.res.Configuration
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.tooling.preview.Preview

@Preview(name = "Chat list loaded", showBackground = true)
@Composable
private fun ChatListLoadedPreview() {
    MaterialTheme {
        ChatListScreen(
            state = ChatListUiState.Loaded(
                items = listOf(
                    ChatListItemUi(
                        roomId = "verified-room",
                        title = "Security Review",
                        unreadCount = 2,
                        trustLevel = ChatListTrustLevel.Verified,
                    ),
                    ChatListItemUi(
                        roomId = "standard-room",
                        title = "Weekend Plans",
                        unreadCount = 0,
                        trustLevel = ChatListTrustLevel.Standard,
                    ),
                    ChatListItemUi(
                        roomId = "reduced-room",
                        title = "Bridge Room",
                        unreadCount = 12,
                        trustLevel = ChatListTrustLevel.Reduced,
                    ),
                ),
            ),
            onEvent = {},
        )
    }
}

@Preview(
    name = "Chat list loaded dark",
    showBackground = true,
    uiMode = Configuration.UI_MODE_NIGHT_YES,
)
@Composable
private fun ChatListLoadedDarkPreview() {
    MaterialTheme {
        ChatListScreen(
            state = ChatListUiState.Loaded(
                items = listOf(
                    ChatListItemUi(
                        roomId = "verified-room",
                        title = "Security Review",
                        unreadCount = 2,
                        trustLevel = ChatListTrustLevel.Verified,
                    ),
                ),
            ),
            onEvent = {},
        )
    }
}

@Preview(name = "Chat list empty", showBackground = true, fontScale = 1.3f)
@Composable
private fun ChatListEmptyPreview() {
    MaterialTheme {
        ChatListScreen(
            state = ChatListUiState.Empty,
            onEvent = {},
        )
    }
}

@Preview(name = "Chat list error", showBackground = true, widthDp = 600)
@Composable
private fun ChatListErrorPreview() {
    MaterialTheme {
        ChatListScreen(
            state = ChatListUiState.Error,
            onEvent = {},
        )
    }
}
