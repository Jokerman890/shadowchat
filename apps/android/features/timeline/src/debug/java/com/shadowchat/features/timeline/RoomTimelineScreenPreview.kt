package com.shadowchat.features.timeline

import android.content.res.Configuration
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.tooling.preview.Preview

@Preview(name = "Room timeline loaded", showBackground = true)
@Composable
private fun RoomTimelineLoadedPreview() {
    MaterialTheme {
        RoomTimelineScreen(
            state = RoomTimelineUiState.Loaded(
                roomTitle = "Security Review",
                items = previewTimelineItems,
            ),
            onEvent = {},
        )
    }
}

@Preview(
    name = "Room timeline loaded dark",
    showBackground = true,
    uiMode = Configuration.UI_MODE_NIGHT_YES,
)
@Composable
private fun RoomTimelineLoadedDarkPreview() {
    MaterialTheme {
        RoomTimelineScreen(
            state = RoomTimelineUiState.Loaded(
                roomTitle = "Security Review",
                items = previewTimelineItems,
            ),
            onEvent = {},
        )
    }
}

@Preview(name = "Room timeline empty", showBackground = true, fontScale = 1.3f)
@Composable
private fun RoomTimelineEmptyPreview() {
    MaterialTheme {
        RoomTimelineScreen(
            state = RoomTimelineUiState.Empty(roomTitle = "Weekend Plans"),
            onEvent = {},
        )
    }
}

@Preview(name = "Room timeline error", showBackground = true, widthDp = 600)
@Composable
private fun RoomTimelineErrorPreview() {
    MaterialTheme {
        RoomTimelineScreen(
            state = RoomTimelineUiState.Error,
            onEvent = {},
        )
    }
}

private val previewTimelineItems = listOf(
    RoomTimelineItemUi(
        messageId = "message-1",
        senderDisplayName = "Ari",
        body = "Can you review the key backup flow today?",
        sentAtLabel = "09:41",
        direction = RoomTimelineMessageDirection.Incoming,
        deliveryState = RoomTimelineDeliveryState.Read,
    ),
    RoomTimelineItemUi(
        messageId = "message-2",
        senderDisplayName = null,
        body = "Yes. I will check the recovery wording before lunch.",
        sentAtLabel = "09:43",
        direction = RoomTimelineMessageDirection.Outgoing,
        deliveryState = RoomTimelineDeliveryState.Delivered,
    ),
)
