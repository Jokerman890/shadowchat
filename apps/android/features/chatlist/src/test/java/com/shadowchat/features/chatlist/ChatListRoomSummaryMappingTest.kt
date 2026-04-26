package com.shadowchat.features.chatlist

import org.junit.Assert.assertEquals
import org.junit.Test

class ChatListRoomSummaryMappingTest {
    @Test
    fun roomSummaryMapsToChatListItemUi() {
        val summary = ChatListRoomSummary(
            roomId = "sofia",
            displayName = "Sofia Martin",
            lastMessagePreview = "Dinner is still on.",
            lastMessageSentAtLabel = "09:41",
            unreadCount = 2,
            trustLevel = ChatListTrustLevel.Verified,
            membership = ChatListMembership.Joined,
            isFavorite = true,
            hasUnreadMentions = false,
        )

        val item = summary.toChatListItemUi()

        assertEquals("sofia", item.roomId)
        assertEquals("Sofia Martin", item.title)
        assertEquals("Dinner is still on.", item.previewText)
        assertEquals("09:41", item.sentAtLabel)
        assertEquals(2, item.unreadCount)
        assertEquals(ChatListTrustLevel.Verified, item.trustLevel)
        assertEquals(true, item.isFavorite)
    }
}
