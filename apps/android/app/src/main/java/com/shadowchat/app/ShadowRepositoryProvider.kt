package com.shadowchat.app

import com.shadowchat.features.chatlist.ChatListRepository
import com.shadowchat.features.timeline.RoomTimelineRepository

internal interface ShadowRepositoryProvider {
    val chatListRepository: ChatListRepository

    fun roomTimelineRepository(roomId: String): RoomTimelineRepository
}

internal object DemoShadowRepositoryProvider : ShadowRepositoryProvider {
    override val chatListRepository: ChatListRepository = DemoChatListRepository

    override fun roomTimelineRepository(roomId: String): RoomTimelineRepository = DemoRoomTimelineRepository
}
