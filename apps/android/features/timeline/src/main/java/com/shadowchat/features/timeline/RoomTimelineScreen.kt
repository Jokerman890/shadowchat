package com.shadowchat.features.timeline

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
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
import com.shadowchat.designsystem.ShadowColors
import com.shadowchat.designsystem.ShadowGlassPanel
import com.shadowchat.designsystem.ShadowLiquidBackground
import com.shadowchat.designsystem.ShadowRadii
import com.shadowchat.designsystem.ShadowSpacing
import com.shadowchat.designsystem.shadowAccentGradient

@Composable
fun RoomTimelineScreen(
    state: RoomTimelineUiState,
    onEvent: (RoomTimelineEvent) -> Unit,
    modifier: Modifier = Modifier,
) {
    ShadowLiquidBackground(
        modifier = modifier.fillMaxSize(),
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = ShadowSpacing.Lg)
                .padding(top = ShadowSpacing.Xl),
            verticalArrangement = Arrangement.spacedBy(ShadowSpacing.Md),
        ) {
            TimelineHeader(title = timelineTitle(state))

            when (state) {
                RoomTimelineUiState.Loading -> RoomTimelineLoadingState()
                is RoomTimelineUiState.Loaded -> RoomTimelineLoadedState(items = state.items)
                is RoomTimelineUiState.Empty -> RoomTimelineEmptyState()
                RoomTimelineUiState.Error -> RoomTimelineErrorState(onEvent = onEvent)
            }

            if (state is RoomTimelineUiState.Loaded) {
                TimelineComposer()
            }
        }
    }
}

@Composable
private fun TimelineHeader(title: String) {
    ShadowGlassPanel(radius = ShadowRadii.Panel) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(ShadowSpacing.Md),
            horizontalArrangement = Arrangement.spacedBy(ShadowSpacing.Md),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(20.dp))
                    .background(shadowAccentGradient())
                    .padding(horizontal = ShadowSpacing.Md, vertical = ShadowSpacing.Sm),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = stringResource(R.string.room_timeline_room_symbol),
                    color = MaterialTheme.colorScheme.onPrimary,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                )
            }
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleLarge,
                    color = MaterialTheme.colorScheme.onSurface,
                    fontWeight = FontWeight.Bold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                Text(
                    text = stringResource(R.string.room_timeline_shell_label),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
            Text(
                text = stringResource(R.string.room_timeline_call_action),
                style = MaterialTheme.typography.labelLarge,
                color = MaterialTheme.colorScheme.primary,
            )
            Text(
                text = stringResource(R.string.room_timeline_video_action),
                style = MaterialTheme.typography.labelLarge,
                color = MaterialTheme.colorScheme.primary,
            )
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
private fun ColumnScope.RoomTimelineLoadedState(items: List<RoomTimelineItemUi>) {
    LazyColumn(
        modifier = Modifier.weight(1f),
        verticalArrangement = Arrangement.spacedBy(ShadowSpacing.Md),
    ) {
        item {
            Box(
                modifier = Modifier.fillMaxWidth(),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = stringResource(R.string.room_timeline_day_today),
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier
                        .background(ShadowColors.GlassSurface, RoundedCornerShape(20.dp))
                        .padding(horizontal = ShadowSpacing.Md, vertical = ShadowSpacing.Xs),
                )
            }
        }

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
        ShadowColors.OutgoingBubble
    } else {
        ShadowColors.IncomingBubble
    }
    val contentColor = if (isOutgoing) {
        MaterialTheme.colorScheme.onSurface
    } else {
        MaterialTheme.colorScheme.onSurface
    }

    Column(
        modifier = Modifier
            .widthIn(max = 320.dp)
            .clip(RoundedCornerShape(ShadowRadii.Bubble))
            .background(bubbleColor)
            .semantics { contentDescription = accessibilityLabel }
            .padding(horizontal = ShadowSpacing.Lg, vertical = ShadowSpacing.Md),
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
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Text(
                text = deliveryStateLabel(item.deliveryState),
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
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
        ShadowGlassPanel(radius = ShadowRadii.Panel) {
            CircularProgressIndicator(
                modifier = Modifier
                    .padding(ShadowSpacing.Xl)
                    .semantics {
                        contentDescription = loadingLabel
                    },
            )
        }
    }
}

@Composable
private fun TimelineComposer() {
    ShadowGlassPanel(radius = ShadowRadii.Panel) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(ShadowSpacing.Md),
            horizontalArrangement = Arrangement.spacedBy(ShadowSpacing.Sm),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = stringResource(R.string.room_timeline_composer_placeholder),
                modifier = Modifier.weight(1f),
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Text(
                text = stringResource(R.string.room_timeline_composer_send),
                color = MaterialTheme.colorScheme.primary,
                fontWeight = FontWeight.Bold,
            )
        }
    }
}

@Composable
private fun RoomTimelineEmptyState() {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center,
    ) {
        ShadowGlassPanel(
            modifier = Modifier.widthIn(max = 360.dp),
            radius = ShadowRadii.Panel,
        ) {
            Column(
                modifier = Modifier.padding(ShadowSpacing.Xl),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(ShadowSpacing.Sm),
            ) {
                Text(
                    text = stringResource(R.string.room_timeline_empty_title),
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurface,
                    fontWeight = FontWeight.SemiBold,
                )
                Text(
                    text = stringResource(R.string.room_timeline_empty_body),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
    }
}

@Composable
private fun RoomTimelineErrorState(onEvent: (RoomTimelineEvent) -> Unit) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center,
    ) {
        ShadowGlassPanel(
            modifier = Modifier.widthIn(max = 360.dp),
            radius = ShadowRadii.Panel,
        ) {
            Column(
                modifier = Modifier.padding(ShadowSpacing.Xl),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(ShadowSpacing.Md),
            ) {
                Text(
                    text = stringResource(R.string.room_timeline_error_title),
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurface,
                    fontWeight = FontWeight.SemiBold,
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
