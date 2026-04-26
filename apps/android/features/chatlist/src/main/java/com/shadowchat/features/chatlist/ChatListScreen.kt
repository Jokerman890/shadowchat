package com.shadowchat.features.chatlist

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.AssistChip
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.pluralStringResource
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
fun ChatListScreen(
    state: ChatListUiState,
    onEvent: (ChatListEvent) -> Unit,
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
            ChatListHeader()

            when (state) {
                ChatListUiState.Loading -> ChatListLoadingState()
                is ChatListUiState.Loaded -> ChatListLoadedState(
                    items = state.items,
                    onEvent = onEvent,
                )
                ChatListUiState.Empty -> ChatListEmptyState()
                ChatListUiState.Error -> ChatListErrorState(onEvent = onEvent)
            }
        }
    }
}

@Composable
private fun ChatListHeader() {
    Column(
        verticalArrangement = Arrangement.spacedBy(ShadowSpacing.Md),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(verticalArrangement = Arrangement.spacedBy(ShadowSpacing.Xs)) {
                Text(
                    text = stringResource(R.string.chat_list_title),
                    style = MaterialTheme.typography.headlineLarge,
                    color = MaterialTheme.colorScheme.onSurface,
                    fontWeight = FontWeight.Bold,
                )
                Text(
                    text = stringResource(R.string.chat_list_subtitle),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }

            Box(
                modifier = Modifier
                    .size(48.dp)
                    .clip(CircleShape)
                    .background(shadowAccentGradient()),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = stringResource(R.string.chat_list_compose_symbol),
                    style = MaterialTheme.typography.titleLarge,
                    color = Color.White,
                    fontWeight = FontWeight.Bold,
                )
            }
        }

        Row(
            horizontalArrangement = Arrangement.spacedBy(ShadowSpacing.Sm),
        ) {
            OutlinedTextField(
                value = "",
                onValueChange = {},
                readOnly = true,
                singleLine = true,
                placeholder = { Text(stringResource(R.string.chat_list_search_placeholder)) },
                modifier = Modifier.weight(1f),
            )
        }

        Row(
            horizontalArrangement = Arrangement.spacedBy(ShadowSpacing.Sm),
        ) {
            AssistChip(
                onClick = {},
                label = { Text(stringResource(R.string.chat_list_filter_all)) },
            )
            AssistChip(
                onClick = {},
                label = { Text(stringResource(R.string.chat_list_filter_unread)) },
            )
            AssistChip(
                onClick = {},
                label = { Text(stringResource(R.string.chat_list_filter_groups)) },
            )
            AssistChip(
                onClick = {},
                label = { Text(stringResource(R.string.chat_list_filter_favorites)) },
            )
        }
    }
}

@Composable
private fun ChatListLoadedState(
    items: List<ChatListItemUi>,
    onEvent: (ChatListEvent) -> Unit,
) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.spacedBy(ShadowSpacing.Md),
    ) {
        items(
            items = items,
            key = { item -> item.roomId },
        ) { item ->
            ChatListRow(
                item = item,
                onClick = { onEvent(ChatListEvent.RoomSelected(item.roomId)) },
            )
        }
    }
}

@Composable
private fun ChatListRow(
    item: ChatListItemUi,
    onClick: () -> Unit,
) {
    val label = chatListItemAccessibilityLabel(item)

    ShadowGlassPanel(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .semantics { contentDescription = label },
        radius = ShadowRadii.Card,
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = ShadowSpacing.Md, horizontal = ShadowSpacing.Md),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            AvatarBadge(title = item.title)

            Spacer(modifier = Modifier.width(ShadowSpacing.Md))

            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(ShadowSpacing.Xs),
            ) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(ShadowSpacing.Sm),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        text = item.title,
                        style = MaterialTheme.typography.titleMedium,
                        color = MaterialTheme.colorScheme.onSurface,
                        fontWeight = FontWeight.SemiBold,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.weight(1f, fill = false),
                    )
                    TrustIndicator(trustLevel = item.trustLevel)
                }
                Text(
                    text = item.previewText.ifBlank { trustPreviewLine(item.trustLevel) },
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }

            if (item.sentAtLabel.isNotBlank()) {
                Text(
                    text = item.sentAtLabel,
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(end = ShadowSpacing.Xs),
                )
            }

            if (item.unreadCount > 0) {
                UnreadBadge(unreadCount = item.unreadCount)
            }
        }
    }
}

@Composable
private fun AvatarBadge(title: String) {
    val initial = title.firstOrNull()?.uppercaseChar()?.toString().orEmpty()

    Box(
        modifier = Modifier
            .size(54.dp)
            .clip(CircleShape)
            .background(shadowAccentGradient()),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = initial,
            style = MaterialTheme.typography.titleLarge,
            color = Color.White,
            fontWeight = FontWeight.Bold,
        )
    }
}

@Composable
private fun TrustIndicator(trustLevel: ChatListTrustLevel) {
    Box(
        modifier = Modifier
            .size(18.dp)
            .background(
                color = ShadowColors.trustColor(trustLevel.toDesignTone()),
                shape = CircleShape,
            ),
        contentAlignment = Alignment.Center,
    ) {
        if (trustLevel == ChatListTrustLevel.Reduced) {
            Text(
                text = "!",
                color = MaterialTheme.colorScheme.onPrimary,
                style = MaterialTheme.typography.labelSmall,
                fontWeight = FontWeight.Bold,
            )
        }
    }
}

@Composable
private fun UnreadBadge(unreadCount: Int) {
    Box(
        modifier = Modifier
            .padding(start = ShadowSpacing.Md)
            .background(shadowAccentGradient(), CircleShape)
            .padding(horizontal = ShadowSpacing.Sm, vertical = ShadowSpacing.Xs),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = unreadCount.toString(),
            color = MaterialTheme.colorScheme.onPrimary,
            style = MaterialTheme.typography.labelMedium,
            fontWeight = FontWeight.SemiBold,
        )
    }
}

@Composable
private fun ChatListLoadingState() {
    val loadingLabel = stringResource(R.string.chat_list_loading)

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
private fun ChatListEmptyState() {
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
                Box(
                    modifier = Modifier
                        .size(48.dp)
                        .background(shadowAccentGradient(), CircleShape),
                )
                Text(
                    text = stringResource(R.string.chat_list_empty_title),
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurface,
                    fontWeight = FontWeight.SemiBold,
                )
                Text(
                    text = stringResource(R.string.chat_list_empty_body),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
    }
}

@Composable
private fun ChatListErrorState(onEvent: (ChatListEvent) -> Unit) {
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
                    text = "!",
                    color = ShadowColors.ReducedTrust,
                    style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.Bold,
                )
                Text(
                    text = stringResource(R.string.chat_list_error_title),
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurface,
                    fontWeight = FontWeight.SemiBold,
                )
                Text(
                    text = stringResource(R.string.chat_list_error_body),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                Button(onClick = { onEvent(ChatListEvent.RetryRequested) }) {
                    Text(text = stringResource(R.string.chat_list_retry))
                }
            }
        }
    }
}

@Composable
private fun trustPreviewLine(trustLevel: ChatListTrustLevel): String = when (trustLevel) {
    ChatListTrustLevel.Verified -> stringResource(R.string.chat_list_preview_verified)
    ChatListTrustLevel.Standard -> stringResource(R.string.chat_list_preview_standard)
    ChatListTrustLevel.Reduced -> stringResource(R.string.chat_list_preview_reduced)
}

@Composable
private fun chatListItemAccessibilityLabel(item: ChatListItemUi): String {
    val unreadPart = if (item.unreadCount > 0) {
        pluralStringResource(
            R.plurals.chat_list_item_unread_count,
            item.unreadCount,
            item.unreadCount,
        )
    } else {
        stringResource(R.string.chat_list_item_no_unread)
    }
    val trustPart = when (item.trustLevel) {
        ChatListTrustLevel.Verified -> stringResource(R.string.chat_list_trust_verified)
        ChatListTrustLevel.Standard -> stringResource(R.string.chat_list_trust_standard)
        ChatListTrustLevel.Reduced -> stringResource(R.string.chat_list_trust_reduced)
    }

    return stringResource(
        R.string.chat_list_item_accessibility,
        item.title,
        unreadPart,
        trustPart,
    )
}
