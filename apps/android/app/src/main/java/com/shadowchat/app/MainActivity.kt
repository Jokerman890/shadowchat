package com.shadowchat.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewmodel.compose.viewModel
import com.shadowchat.designsystem.ShadowChatTheme
import com.shadowchat.features.chatlist.ChatListItemUi
import com.shadowchat.features.chatlist.ChatListRepository
import com.shadowchat.features.chatlist.ChatListRoute
import com.shadowchat.features.chatlist.ChatListViewModel

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContent {
            ShadowChatTheme {
                val chatListViewModel: ChatListViewModel = viewModel(
                    factory = ChatListViewModelFactory(EmptyChatListRepository),
                )

                ChatListRoute(
                    viewModel = chatListViewModel,
                    onRoomSelected = {},
                )
            }
        }
    }
}

private object EmptyChatListRepository : ChatListRepository {
    override suspend fun loadChatList(): List<ChatListItemUi> = emptyList()
}

private class ChatListViewModelFactory(
    private val repository: ChatListRepository,
) : ViewModelProvider.Factory {
    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        require(modelClass == ChatListViewModel::class.java) {
            "Unsupported ViewModel: ${modelClass.name}"
        }

        return ChatListViewModel(repository) as T
    }
}
