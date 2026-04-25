package com.shadowchat.features.chatlist

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier

@Composable
fun ChatListRoute(
    viewModel: ChatListViewModel,
    onRoomSelected: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    val state by viewModel.state.collectAsState()

    LaunchedEffect(viewModel) {
        viewModel.onEvent(ChatListEvent.Appeared)
    }

    ChatListScreen(
        state = state,
        onEvent = { event ->
            when (event) {
                is ChatListEvent.RoomSelected -> onRoomSelected(event.roomId)
                else -> viewModel.onEvent(event)
            }
        },
        modifier = modifier,
    )
}
