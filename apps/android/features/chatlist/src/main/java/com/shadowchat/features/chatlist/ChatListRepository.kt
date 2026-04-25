package com.shadowchat.features.chatlist

interface ChatListRepository {
    suspend fun loadChatList(): List<ChatListItemUi>
}
