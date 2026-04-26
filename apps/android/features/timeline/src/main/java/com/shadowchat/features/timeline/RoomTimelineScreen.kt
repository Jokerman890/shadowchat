package com.shadowchat.features.timeline

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.shadowchat.designsystem.ShadowSpacing

@Composable
fun RoomTimelineScreen(
    state: RoomTimelineUiState,
    onEvent: (RoomTimelineEvent) -> Unit,
    modifier: Modifier = Modifier,
) {
    Surface(
        modifier = modifier.fillMaxSize(),
        color = MaterialTheme.colorScheme.background,
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = ShadowSpacing.Lg),
        ) {
            Text(
                text = timelineTitle(state),
                style = MaterialTheme.typography.headlineSmall,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.padding(top = ShadowSpacing.Xl, bottom = ShadowSpacing.Md),
            )

            when (state) {
                RoomTimelineUiState.Loading -> RoomTimelineLoadingState()
                is RoomTimelineUiState.Loaded -> RoomTimelineLoadedState(items = state.items)
                is RoomTimelineUiState.Empty -> RoomTimelineEmptyState()
                RoomTimelineUiState.Error -> RoomTimelineErrorState(onEvent = onEvent)
            }
        }
    }
}

@Composable
private fun timelineTitle(state: RoomTimelineUiState): String = when (state) {
    is RoomTimelineUiState.Empty -> state.roomTitle ?: stringResource(R.string.room_timeline_default_title)
    is RoomTimelineUiState.Loaded -> state.roomTitle ?: stringResource(R.string.room_timeline_default_title)
    RoomTimelineUiState.Error,
    RoomTimelineUiState.Loading -> stringResource(R.string.room_timeline_default_title)
}

@Composable
private fun RoomTimelineLoadedState(items: List<RoomTimelineItemUi>) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.spacedBy(ShadowSpacing.Sm),
    ) {
        items(
            items = items,
            key = { item -> item.messageId },
        ) { item ->
            RoomTimelineMessageRow(item = item)
        }
    }
}

@Composable
private fun RoomTimelineMessageRow(item: RoomTimelineItemUi) {
    val horizontalAlignment = when (item.direction) {
        RoomTimelineMessageDirection.Incoming -> Alignment.Start
        RoomTimelineMessageDirection.Outgoing -> Alignment.End
    }

    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = horizontalAlignment,
    ) {
        MessageBubble(item = item)
    }
}

@Composable
private fun MessageBubble(item: RoomTimelineItemUi) {
    val isOutgoing = item.direction == RoomTimelineMessageDirection.Outgoing
    val accessibilityLabel = messageAccessibilityLabel(item)
    val bubbleColor = if (isOutgoing) {
        MaterialTheme.colorScheme.primaryContainer
    } else {
        MaterialTheme.colorScheme.surfaceVariant
    }
    val contentColor = if (isOutgoing) {
        MaterialTheme.colorScheme.onPrimaryContainer
    } else {
        MaterialTheme.colorScheme.onSurfaceVariant
    }

    Column(
        modifier = Modifier
            .widthIn(max = 320.dp)
            .clip(RoundedCornerShape(18.dp))
            .background(bubbleColor)
            .semantics { contentDescription = accessibilityLabel }
            .padding(horizontal = ShadowSpacing.Md, vertical = ShadowSpacing.Sm),
        verticalArrangement = Arrangement.spacedBy(ShadowSpacing.Xs),
    ) {
        if (!isOutgoing && item.senderDisplayName != null) {
            Text(
                text = item.senderDisplayName,
                style = MaterialTheme.typography.labelMedium,
                color = contentColor,
                fontWeight = FontWeight.SemiBold,
            )
        }
        Text(
            text = item.body,
            style = MaterialTheme.typography.bodyLarge,
            color = contentColor,
        )
        Row(
            horizontalArrangement = Arrangement.spacedBy(ShadowSpacing.Xs),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = item.sentAtLabel,
                style = MaterialTheme.typography.labelSmall,
                color = contentColor.copy(alpha = 0.74f),
            )
            Text(
                text = deliveryStateLabel(item.deliveryState),
                style = MaterialTheme.typography.labelSmall,
                color = contentColor.copy(alpha = 0.74f),
            )
        }
    }
}

@Composable
private fun RoomTimelineLoadingState() {
    val loadingLabel = stringResource(R.string.room_timeline_loading)

    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center,
    ) {
        CircularProgressIndicator(
            modifier = Modifier.semantics {
                contentDescription = loadingLabel
            },
        )
    }
}

@Composable
private fun RoomTimelineEmptyState() {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center,
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(ShadowSpacing.Sm),
        ) {
            Text(
                text = stringResource(R.string.room_timeline_empty_title),
                style = MaterialTheme.typography.titleMedium,
            )
            Text(
                text = stringResource(R.string.room_timeline_empty_body),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

@Composable
private fun RoomTimelineErrorState(onEvent: (RoomTimelineEvent) -> Unit) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center,
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(ShadowSpacing.Md),
        ) {
            Text(
                text = stringResource(R.string.room_timeline_error_title),
                style = MaterialTheme.typography.titleMedium,
            )
            Text(
                text = stringResource(R.string.room_timeline_error_body),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Button(onClick = { onEvent(RoomTimelineEvent.RetryRequested) }) {
                Text(text = stringResource(R.string.room_timeline_retry))
            }
        }
    }
}

@Composable
private fun deliveryStateLabel(state: RoomTimelineDeliveryState): String = when (state) {
    RoomTimelineDeliveryState.Sending -> stringResource(R.string.room_timeline_delivery_sending)
    RoomTimelineDeliveryState.Sent -> stringResource(R.string.room_timeline_delivery_sent)
    RoomTimelineDeliveryState.Delivered -> stringResource(R.string.room_timeline_delivery_delivered)
    RoomTimelineDeliveryState.Read -> stringResource(R.string.room_timeline_delivery_read)
    RoomTimelineDeliveryState.Failed -> stringResource(R.string.room_timeline_delivery_failed)
}

@Composable
private fun messageAccessibilityLabel(item: RoomTimelineItemUi): String {
    val sender = item.senderDisplayName ?: stringResource(R.string.room_timeline_you)
    return stringResource(
        R.string.room_timeline_message_accessibility,
        sender,
        item.body,
        item.sentAtLabel,
        deliveryStateLabel(item.deliveryState),
    )
}
