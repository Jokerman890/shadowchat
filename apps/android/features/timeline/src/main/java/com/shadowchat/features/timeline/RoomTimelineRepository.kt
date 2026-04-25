package com.shadowchat.features.timeline

interface RoomTimelineRepository {
    suspend fun loadTimeline(roomId: String): RoomTimelineSnapshotUi
}
