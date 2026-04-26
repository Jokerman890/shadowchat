package com.shadowchat.features.timeline

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.shadowchat.designsystem.ShadowColors
import com.shadowchat.designsystem.ShadowGlassPanel
import com.shadowchat.designsystem.ShadowLiquidBackground
import com.shadowchat.designsystem.ShadowMotion
import com.shadowchat.designsystem.ShadowRadii
import com.shadowchat.designsystem.ShadowSpacing
import com.shadowchat.designsystem.shadowAccentGradient
import com.shadowchat.designsystem.shadowMotionEnabled

@Composable
fun RoomTimelineScreen(
    state: RoomTimelineUiState,
    onEvent: (RoomTimelineEvent) -> Unit,
    modifier: Modifier = Modifier,
    onBackRequested: (() -> Unit)? = null,
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
            TimelineHeader(
                title = timelineTitle(state),
                onBackRequested = onBackRequested,
            )

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
private fun TimelineHeader(
    title: String,
    onBackRequested: (() -> Unit)?,
) {
    ShadowGlassPanel(radius = ShadowRadii.Panel) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(ShadowSpacing.Md),
            horizontalArrangement = Arrangement.spacedBy(ShadowSpacing.Md),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            if (onBackRequested != null) {
                HeaderAction(
                    icon = TimelineActionIcon.Back,
                    label = stringResource(R.string.room_timeline_back_to_chats),
                    onClick = onBackRequested,
                )
            }
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
            HeaderAction(icon = TimelineActionIcon.Call, label = stringResource(R.string.room_timeline_call_action))
            HeaderAction(icon = TimelineActionIcon.Video, label = stringResource(R.string.room_timeline_video_action))
        }
    }
}

@Composable
private fun HeaderAction(
    icon: TimelineActionIcon,
    label: String,
    onClick: (() -> Unit)? = null,
) {
    val modifier = Modifier.shadowPressScale(onClick = onClick)

    ShadowGlassPanel(radius = ShadowRadii.Control) {
        TimelineActionIconCanvas(
            icon = icon,
            color = MaterialTheme.colorScheme.primary,
            modifier = modifier
                .size(42.dp)
                .padding(10.dp)
                .semantics { contentDescription = label },
        )
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
                .padding(horizontal = ShadowSpacing.Md, vertical = ShadowSpacing.Sm),
            horizontalArrangement = Arrangement.spacedBy(ShadowSpacing.Sm),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            ComposerAction(
                icon = TimelineActionIcon.Attach,
                label = stringResource(R.string.room_timeline_composer_attach),
            )
            Text(
                text = stringResource(R.string.room_timeline_composer_placeholder),
                modifier = Modifier.weight(1f),
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            ComposerAction(
                icon = TimelineActionIcon.Mic,
                label = stringResource(R.string.room_timeline_composer_mic),
            )
            ComposerAction(
                icon = TimelineActionIcon.Send,
                label = stringResource(R.string.room_timeline_composer_send),
                emphasized = true,
            )
        }
    }
}

@Composable
private fun ComposerAction(
    icon: TimelineActionIcon,
    label: String,
    emphasized: Boolean = false,
) {
    val modifier = Modifier.shadowPressScale()
    val backgroundModifier = if (emphasized) {
        Modifier.background(shadowAccentGradient(), CircleShape)
    } else {
        Modifier.background(ShadowColors.GlassSurface, CircleShape)
    }

    Box(
        modifier = modifier
            .size(42.dp)
            .then(backgroundModifier)
            .semantics { contentDescription = label },
        contentAlignment = Alignment.Center,
    ) {
        TimelineActionIconCanvas(
            icon = icon,
            color = if (emphasized) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.primary,
            modifier = Modifier.size(20.dp),
        )
    }
}

@Composable
private fun Modifier.shadowPressScale(onClick: (() -> Unit)? = null): Modifier {
    val motionEnabled = shadowMotionEnabled()
    var pressed by remember { mutableStateOf(false) }
    val scale by animateFloatAsState(
        targetValue = if (pressed) ShadowMotion.PressedScale else 1f,
        animationSpec = ShadowMotion.floatSpec(motionEnabled),
        label = "Timeline action press scale",
    )

    return this
        .graphicsLayer {
            scaleX = scale
            scaleY = scale
        }
        .pointerInput(Unit) {
            detectTapGestures(
                onPress = {
                    pressed = true
                    try {
                        tryAwaitRelease()
                    } finally {
                        pressed = false
                    }
                },
                onTap = {
                    onClick?.invoke()
                },
            )
        }
}

private enum class TimelineActionIcon {
    Attach,
    Back,
    Call,
    Mic,
    Send,
    Video,
}

@Composable
private fun TimelineActionIconCanvas(
    icon: TimelineActionIcon,
    color: Color,
    modifier: Modifier = Modifier,
) {
    Canvas(modifier = modifier) {
        val stroke = Stroke(width = 2.2.dp.toPx(), cap = StrokeCap.Round)
        when (icon) {
            TimelineActionIcon.Back -> {
                drawLine(
                    color = color,
                    start = androidx.compose.ui.geometry.Offset(size.width * 0.68f, size.height * 0.18f),
                    end = androidx.compose.ui.geometry.Offset(size.width * 0.32f, size.height * 0.5f),
                    strokeWidth = stroke.width,
                    cap = StrokeCap.Round,
                )
                drawLine(
                    color = color,
                    start = androidx.compose.ui.geometry.Offset(size.width * 0.32f, size.height * 0.5f),
                    end = androidx.compose.ui.geometry.Offset(size.width * 0.68f, size.height * 0.82f),
                    strokeWidth = stroke.width,
                    cap = StrokeCap.Round,
                )
            }
            TimelineActionIcon.Attach -> {
                drawLine(
                    color = color,
                    start = androidx.compose.ui.geometry.Offset(size.width / 2f, size.height * 0.2f),
                    end = androidx.compose.ui.geometry.Offset(size.width / 2f, size.height * 0.8f),
                    strokeWidth = stroke.width,
                    cap = StrokeCap.Round,
                )
                drawLine(
                    color = color,
                    start = androidx.compose.ui.geometry.Offset(size.width * 0.2f, size.height / 2f),
                    end = androidx.compose.ui.geometry.Offset(size.width * 0.8f, size.height / 2f),
                    strokeWidth = stroke.width,
                    cap = StrokeCap.Round,
                )
            }
            TimelineActionIcon.Call -> {
                val path = Path().apply {
                    moveTo(size.width * 0.22f, size.height * 0.18f)
                    cubicTo(size.width * 0.08f, size.height * 0.42f, size.width * 0.28f, size.height * 0.78f, size.width * 0.62f, size.height * 0.9f)
                    cubicTo(size.width * 0.82f, size.height * 0.98f, size.width * 0.94f, size.height * 0.82f, size.width * 0.84f, size.height * 0.66f)
                }
                drawPath(path = path, color = color, style = stroke)
            }
            TimelineActionIcon.Mic -> {
                drawRoundRect(
                    color = color,
                    topLeft = androidx.compose.ui.geometry.Offset(size.width * 0.34f, size.height * 0.12f),
                    size = androidx.compose.ui.geometry.Size(size.width * 0.32f, size.height * 0.48f),
                    cornerRadius = androidx.compose.ui.geometry.CornerRadius(size.width * 0.18f),
                    style = stroke,
                )
                drawArc(
                    color = color,
                    startAngle = 25f,
                    sweepAngle = 130f,
                    useCenter = false,
                    topLeft = androidx.compose.ui.geometry.Offset(size.width * 0.2f, size.height * 0.34f),
                    size = androidx.compose.ui.geometry.Size(size.width * 0.6f, size.height * 0.42f),
                    style = stroke,
                )
                drawLine(
                    color = color,
                    start = androidx.compose.ui.geometry.Offset(size.width / 2f, size.height * 0.74f),
                    end = androidx.compose.ui.geometry.Offset(size.width / 2f, size.height * 0.9f),
                    strokeWidth = stroke.width,
                    cap = StrokeCap.Round,
                )
            }
            TimelineActionIcon.Send -> {
                val path = Path().apply {
                    moveTo(size.width * 0.14f, size.height * 0.18f)
                    lineTo(size.width * 0.9f, size.height * 0.5f)
                    lineTo(size.width * 0.14f, size.height * 0.82f)
                    lineTo(size.width * 0.3f, size.height * 0.52f)
                    close()
                }
                drawPath(path = path, color = color)
            }
            TimelineActionIcon.Video -> {
                drawRoundRect(
                    color = color,
                    topLeft = androidx.compose.ui.geometry.Offset(size.width * 0.14f, size.height * 0.28f),
                    size = androidx.compose.ui.geometry.Size(size.width * 0.5f, size.height * 0.44f),
                    cornerRadius = androidx.compose.ui.geometry.CornerRadius(size.width * 0.12f),
                    style = stroke,
                )
                val path = Path().apply {
                    moveTo(size.width * 0.66f, size.height * 0.44f)
                    lineTo(size.width * 0.9f, size.height * 0.3f)
                    lineTo(size.width * 0.9f, size.height * 0.7f)
                    lineTo(size.width * 0.66f, size.height * 0.56f)
                    close()
                }
                drawPath(path = path, color = color)
            }
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
