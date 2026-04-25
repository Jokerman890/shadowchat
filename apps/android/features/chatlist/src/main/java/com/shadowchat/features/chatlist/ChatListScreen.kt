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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
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
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.shadowchat.designsystem.ShadowColors
import com.shadowchat.designsystem.ShadowSpacing

@Composable
fun ChatListScreen(
    state: ChatListUiState,
    onEvent: (ChatListEvent) -> Unit,
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
                text = stringResource(R.string.chat_list_title),
                style = MaterialTheme.typography.headlineMedium,
                modifier = Modifier.padding(top = ShadowSpacing.Xl, bottom = ShadowSpacing.Md),
            )

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
private fun ChatListLoadedState(
    items: List<ChatListItemUi>,
    onEvent: (ChatListEvent) -> Unit,
) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.spacedBy(ShadowSpacing.Xs),
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

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(8.dp))
            .clickable(onClick = onClick)
            .semantics { contentDescription = label }
            .padding(vertical = ShadowSpacing.Md, horizontal = ShadowSpacing.Sm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        TrustIndicator(trustLevel = item.trustLevel)

        Spacer(modifier = Modifier.width(ShadowSpacing.Md))

        Text(
            text = item.title,
            style = MaterialTheme.typography.titleMedium,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.weight(1f),
        )

        if (item.unreadCount > 0) {
            UnreadBadge(unreadCount = item.unreadCount)
        }
    }
}

@Composable
private fun TrustIndicator(trustLevel: ChatListTrustLevel) {
    Box(
        modifier = Modifier
            .size(24.dp)
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
            .background(ShadowColors.UnreadBadge, CircleShape)
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
        CircularProgressIndicator(
            modifier = Modifier.semantics {
                contentDescription = loadingLabel
            },
        )
    }
}

@Composable
private fun ChatListEmptyState() {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center,
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(ShadowSpacing.Sm),
        ) {
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .background(MaterialTheme.colorScheme.secondaryContainer, CircleShape),
            )
            Text(
                text = stringResource(R.string.chat_list_empty_title),
                style = MaterialTheme.typography.titleMedium,
            )
            Text(
                text = stringResource(R.string.chat_list_empty_body),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

@Composable
private fun ChatListErrorState(onEvent: (ChatListEvent) -> Unit) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center,
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(ShadowSpacing.Md),
        ) {
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .background(MaterialTheme.colorScheme.errorContainer, CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = "!",
                    color = MaterialTheme.colorScheme.onErrorContainer,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                )
            }
            Text(
                text = stringResource(R.string.chat_list_error_title),
                style = MaterialTheme.typography.titleMedium,
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
