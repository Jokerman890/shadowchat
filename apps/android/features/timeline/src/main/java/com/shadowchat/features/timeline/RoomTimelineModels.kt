package com.shadowchat.features.timeline

data class RoomTimelineSnapshotUi(
    val roomId: String,
    val roomTitle: String?,
    val items: List<RoomTimelineItemUi>,
)

data class RoomTimelineItemUi(
    val messageId: String,
    val senderDisplayName: String?,
    val body: String,
    val sentAtLabel: String,
    val direction: RoomTimelineMessageDirection,
    val deliveryState: RoomTimelineDeliveryState,
)

enum class RoomTimelineMessageDirection {
    Incoming,
    Outgoing,
}

enum class RoomTimelineDeliveryState {
    Sending,
    Sent,
    Delivered,
    Read,
    Failed,
}

sealed interface RoomTimelineUiState {
    data object Loading : RoomTimelineUiState
    data class Loaded(
        val roomTitle: String?,
        val items: List<RoomTimelineItemUi>,
    ) : RoomTimelineUiState
    data class Empty(val roomTitle: String?) : RoomTimelineUiState
    data object Error : RoomTimelineUiState
}

sealed interface RoomTimelineEvent {
    data object Appeared : RoomTimelineEvent
    data object RefreshRequested : RoomTimelineEvent
    data object RetryRequested : RoomTimelineEvent
}
