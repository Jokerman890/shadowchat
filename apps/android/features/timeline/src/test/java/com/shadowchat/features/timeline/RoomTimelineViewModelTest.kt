package com.shadowchat.features.timeline

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class RoomTimelineViewModelTest {
    private val dispatcher = StandardTestDispatcher()

    @Before
    fun setUp() {
        Dispatchers.setMain(dispatcher)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun loadPublishesLoadedState() = runTest(dispatcher) {
        val item = RoomTimelineItemUi(
            messageId = "message-1",
            senderDisplayName = "Ari",
            body = "Hello",
            sentAtLabel = "09:41",
            direction = RoomTimelineMessageDirection.Incoming,
            deliveryState = RoomTimelineDeliveryState.Read,
        )
        val viewModel = RoomTimelineViewModel(
            roomId = "room-1",
            repository = StubRoomTimelineRepository(
                Result.success(
                    RoomTimelineSnapshotUi(
                        roomId = "room-1",
                        roomTitle = "General",
                        items = listOf(item),
                    ),
                ),
            ),
        )

        viewModel.load()
        advanceUntilIdle()

        assertEquals(
            RoomTimelineUiState.Loaded(roomTitle = "General", items = listOf(item)),
            viewModel.state.value,
        )
    }

    @Test
    fun loadPublishesEmptyState() = runTest(dispatcher) {
        val viewModel = RoomTimelineViewModel(
            roomId = "room-2",
            repository = StubRoomTimelineRepository(
                Result.success(
                    RoomTimelineSnapshotUi(
                        roomId = "room-2",
                        roomTitle = "Quiet Room",
                        items = emptyList(),
                    ),
                ),
            ),
        )

        viewModel.load()
        advanceUntilIdle()

        assertEquals(RoomTimelineUiState.Empty(roomTitle = "Quiet Room"), viewModel.state.value)
    }

    @Test
    fun loadPublishesErrorState() = runTest(dispatcher) {
        val viewModel = RoomTimelineViewModel(
            roomId = "room-3",
            repository = StubRoomTimelineRepository(Result.failure(TestException())),
        )

        viewModel.load()
        advanceUntilIdle()

        assertEquals(RoomTimelineUiState.Error, viewModel.state.value)
    }

    @Test
    fun retryReloadsItems() = runTest(dispatcher) {
        val item = RoomTimelineItemUi(
            messageId = "message-2",
            senderDisplayName = null,
            body = "Recovered",
            sentAtLabel = "10:00",
            direction = RoomTimelineMessageDirection.Outgoing,
            deliveryState = RoomTimelineDeliveryState.Sent,
        )
        val viewModel = RoomTimelineViewModel(
            roomId = "room-4",
            repository = SequencedRoomTimelineRepository(
                results = ArrayDeque(
                    listOf(
                        Result.failure(TestException()),
                        Result.success(
                            RoomTimelineSnapshotUi(
                                roomId = "room-4",
                                roomTitle = "Recovered Room",
                                items = listOf(item),
                            ),
                        ),
                    ),
                ),
            ),
        )

        viewModel.load()
        advanceUntilIdle()
        assertEquals(RoomTimelineUiState.Error, viewModel.state.value)

        viewModel.onEvent(RoomTimelineEvent.RetryRequested)
        advanceUntilIdle()

        assertEquals(
            RoomTimelineUiState.Loaded(roomTitle = "Recovered Room", items = listOf(item)),
            viewModel.state.value,
        )
    }
}

private class StubRoomTimelineRepository(
    private val result: Result<RoomTimelineSnapshotUi>,
) : RoomTimelineRepository {
    override suspend fun loadTimeline(roomId: String): RoomTimelineSnapshotUi = result.getOrThrow()
}

private class SequencedRoomTimelineRepository(
    private val results: ArrayDeque<Result<RoomTimelineSnapshotUi>>,
) : RoomTimelineRepository {
    override suspend fun loadTimeline(roomId: String): RoomTimelineSnapshotUi =
        results.removeFirst().getOrThrow()
}

private class TestException : Throwable()
