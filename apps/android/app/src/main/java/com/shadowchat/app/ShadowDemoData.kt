package com.shadowchat.app

import com.shadowchat.features.chatlist.ChatListItemUi
import com.shadowchat.features.chatlist.ChatListRepository
import com.shadowchat.features.chatlist.ChatListTrustLevel
import com.shadowchat.features.timeline.RoomTimelineDeliveryState
import com.shadowchat.features.timeline.RoomTimelineItemUi
import com.shadowchat.features.timeline.RoomTimelineMessageDirection
import com.shadowchat.features.timeline.RoomTimelineRepository
import com.shadowchat.features.timeline.RoomTimelineSnapshotUi

internal data class ShadowShellRowData(
    val title: String,
    val subtitle: String,
    val trailing: String,
)

internal data class ShadowShellHeroData(
    val name: String,
    val subtitle: String,
)

internal object ShadowDemoData {
    val chatRooms: List<ChatListItemUi> = listOf(
        ChatListItemUi("sofia", "Sofia Martin", "Hey! Are we still on for dinner tonight?", "09:41", 2, ChatListTrustLevel.Verified, true),
        ChatListItemUi("design-squad", "Design Squad", "Liam: I will share the assets here.", "09:12", 8, ChatListTrustLevel.Standard, true),
        ChatListItemUi("jason", "Jason Lee", "Sounds good, talk soon!", "Yesterday", 0, ChatListTrustLevel.Verified),
        ChatListItemUi("family", "Family", "Mom: Do not forget Sunday lunch at grandma's!", "Sun", 4, ChatListTrustLevel.Standard),
        ChatListItemUi("emma", "Emma Wilson", "Looks amazing!", "Sat", 1, ChatListTrustLevel.Verified),
        ChatListItemUi("adventure", "Adventure Club", "Trail photos are ready.", "Fri", 0, ChatListTrustLevel.Reduced),
        ChatListItemUi("noah", "Noah Johnson", "Can you review this later?", "Thu", 0, ChatListTrustLevel.Standard),
        ChatListItemUi("daniel", "Daniel Carter", "Call me when you are free.", "Wed", 3, ChatListTrustLevel.Reduced),
    )

    val callFilters: List<String> = listOf("All", "Missed", "Voicemail")

    val callRows: List<ShadowShellRowData> = listOf(
        ShadowShellRowData("Sofia Martin", "Outgoing call, today", "Call"),
        ShadowShellRowData("Daniel Carter", "Missed call, yesterday", "Call"),
        ShadowShellRowData("Adventure Club", "Group call preview", "Call"),
    )

    val updateRows: List<ShadowShellRowData> = listOf(
        ShadowShellRowData("My Status", "Add a soft glass status update", "New"),
        ShadowShellRowData("Emma Wilson", "Recent update", "View"),
        ShadowShellRowData("Family", "Viewed update", "View"),
    )

    val profileHero = ShadowShellHeroData("Sofia Martin", "Online now")
    val profileActions: List<String> = listOf("Message", "Call", "Video", "Pay")
    val profileRows: List<ShadowShellRowData> = listOf(
        ShadowShellRowData("About", "Building calm, secure conversations.", "Edit"),
        ShadowShellRowData("Media, Links, Docs", "24 shared items", "Open"),
        ShadowShellRowData("Starred Messages", "Quick access shell", "Open"),
    )

    val settingsHero = ShadowShellHeroData("ShadowChat", "Premium messenger shell")
    val settingsRows: List<ShadowShellRowData> = listOf(
        "Account",
        "Privacy",
        "Notifications",
        "Appearance",
        "Chats",
        "Storage and Data",
        "Help Center",
        "Invite Friends",
    ).map { title ->
        ShadowShellRowData(title, "Settings group shell", "Open")
    }

    fun timelineSnapshot(roomId: String): RoomTimelineSnapshotUi {
        val roomTitle = chatRooms.firstOrNull { it.roomId == roomId }?.title ?: "Conversation"
        return RoomTimelineSnapshotUi(
            roomId = roomId,
            roomTitle = roomTitle,
            items = timelineItems(roomId = roomId, roomTitle = roomTitle),
        )
    }

    private fun timelineItems(roomId: String, roomTitle: String): List<RoomTimelineItemUi> = when (roomId) {
        "sofia" -> listOf(
            incoming("sofia-1", roomTitle, "Hey! Are we still on for dinner tonight?", "09:41"),
            outgoing("sofia-2", "Yes. I will be there at 8.", "09:43", RoomTimelineDeliveryState.Delivered),
            incoming("sofia-3", roomTitle, "Perfect. I saved us a table near the window.", "09:44"),
            outgoing("sofia-4", "Voice preview and media cards will land in the send pipeline slice.", "09:45", RoomTimelineDeliveryState.Sent),
        )
        "design-squad" -> listOf(
            incoming("design-1", "Liam", "I will share the assets here.", "09:12"),
            outgoing("design-2", "Great. Keep the glass cards readable on small screens.", "09:14", RoomTimelineDeliveryState.Delivered),
            incoming("design-3", "Maya", "The lavender accent works best when the header stays calm.", "09:18"),
        )
        "jason" -> listOf(
            incoming("jason-1", roomTitle, "Sounds good, talk soon!", "Yesterday"),
            outgoing("jason-2", "Thanks. I will send the notes after lunch.", "Yesterday", RoomTimelineDeliveryState.Read),
        )
        "family" -> listOf(
            incoming("family-1", "Mom", "Do not forget Sunday lunch at grandma's!", "Sun"),
            outgoing("family-2", "I have it saved. I will bring dessert.", "Sun", RoomTimelineDeliveryState.Delivered),
            incoming("family-3", "Alex", "I can pick up drinks on the way.", "Sun"),
        )
        "emma" -> listOf(
            incoming("emma-1", roomTitle, "Looks amazing!", "Sat"),
            outgoing("emma-2", "Thank you. The final polish is starting to feel right.", "Sat", RoomTimelineDeliveryState.Read),
        )
        "adventure" -> listOf(
            incoming("adventure-1", roomTitle, "Trail photos are ready.", "Fri"),
            outgoing("adventure-2", "Nice. Send the album when you can.", "Fri", RoomTimelineDeliveryState.Sent),
            incoming("adventure-3", roomTitle, "Reminder: this demo room keeps reduced trust visible.", "Fri", RoomTimelineDeliveryState.Read),
        )
        "noah" -> listOf(
            incoming("noah-1", roomTitle, "Can you review this later?", "Thu"),
            outgoing("noah-2", "Yes, I will take a look tonight.", "Thu", RoomTimelineDeliveryState.Delivered),
        )
        "daniel" -> listOf(
            incoming("daniel-1", roomTitle, "Call me when you are free.", "Wed"),
            outgoing("daniel-2", "I am in a meeting now. I will call after.", "Wed", RoomTimelineDeliveryState.Sent),
        )
        else -> listOf(
            incoming("unknown-1", roomTitle, "This local demo room has no Matrix-backed timeline yet.", "Now"),
        )
    }

    private fun incoming(
        id: String,
        sender: String,
        body: String,
        time: String,
        deliveryState: RoomTimelineDeliveryState = RoomTimelineDeliveryState.Read,
    ) = RoomTimelineItemUi(
        messageId = id,
        senderDisplayName = sender,
        body = body,
        sentAtLabel = time,
        direction = RoomTimelineMessageDirection.Incoming,
        deliveryState = deliveryState,
    )

    private fun outgoing(
        id: String,
        body: String,
        time: String,
        deliveryState: RoomTimelineDeliveryState,
    ) = RoomTimelineItemUi(
        messageId = id,
        senderDisplayName = null,
        body = body,
        sentAtLabel = time,
        direction = RoomTimelineMessageDirection.Outgoing,
        deliveryState = deliveryState,
    )
}

internal object DemoChatListRepository : ChatListRepository {
    override suspend fun loadChatList(): List<ChatListItemUi> = ShadowDemoData.chatRooms
}

internal object DemoRoomTimelineRepository : RoomTimelineRepository {
    override suspend fun loadTimeline(roomId: String): RoomTimelineSnapshotUi = ShadowDemoData.timelineSnapshot(roomId)
}
