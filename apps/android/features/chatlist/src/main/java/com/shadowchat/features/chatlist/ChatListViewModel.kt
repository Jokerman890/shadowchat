package com.shadowchat.features.chatlist

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class ChatListViewModel(
    private val repository: ChatListRepository,
) : ViewModel() {
    private val _state = MutableStateFlow<ChatListUiState>(ChatListUiState.Loading)
    val state: StateFlow<ChatListUiState> = _state.asStateFlow()

    fun onEvent(event: ChatListEvent) {
        when (event) {
            ChatListEvent.Appeared -> {
                if (_state.value == ChatListUiState.Loading) {
                    load()
                }
            }
            ChatListEvent.RefreshRequested,
            ChatListEvent.RetryRequested -> load()
            is ChatListEvent.RoomSelected -> Unit
        }
    }

    fun load() {
        _state.value = ChatListUiState.Loading

        viewModelScope.launch {
            _state.value = try {
                val items = repository.loadChatList()
                if (items.isEmpty()) {
                    ChatListUiState.Empty
                } else {
                    ChatListUiState.Loaded(items)
                }
            } catch (_: Throwable) {
                ChatListUiState.Error
            }
        }
    }
}
