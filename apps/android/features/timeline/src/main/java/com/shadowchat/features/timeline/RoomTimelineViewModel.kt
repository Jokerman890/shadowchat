package com.shadowchat.features.timeline

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class RoomTimelineViewModel(
    private val roomId: String,
    private val repository: RoomTimelineRepository,
) : ViewModel() {
    private val _state = MutableStateFlow<RoomTimelineUiState>(RoomTimelineUiState.Loading)
    val state: StateFlow<RoomTimelineUiState> = _state.asStateFlow()

    fun onEvent(event: RoomTimelineEvent) {
        when (event) {
            RoomTimelineEvent.Appeared -> {
                if (_state.value == RoomTimelineUiState.Loading) {
                    load()
                }
            }
            RoomTimelineEvent.RefreshRequested,
            RoomTimelineEvent.RetryRequested -> load()
        }
    }

    fun load() {
        _state.value = RoomTimelineUiState.Loading

        viewModelScope.launch {
            _state.value = try {
                val snapshot = repository.loadTimeline(roomId)
                if (snapshot.items.isEmpty()) {
                    RoomTimelineUiState.Empty(roomTitle = snapshot.roomTitle)
                } else {
                    RoomTimelineUiState.Loaded(
                        roomTitle = snapshot.roomTitle,
                        items = snapshot.items,
                    )
                }
            } catch (_: Throwable) {
                RoomTimelineUiState.Error
            }
        }
    }
}
