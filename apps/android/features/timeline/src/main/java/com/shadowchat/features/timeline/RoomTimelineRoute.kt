package com.shadowchat.features.timeline

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier

@Composable
fun RoomTimelineRoute(
    viewModel: RoomTimelineViewModel,
    modifier: Modifier = Modifier,
) {
    val state by viewModel.state.collectAsState()

    LaunchedEffect(viewModel) {
        viewModel.onEvent(RoomTimelineEvent.Appeared)
    }

    RoomTimelineScreen(
        state = state,
        onEvent = viewModel::onEvent,
        modifier = modifier,
    )
}
