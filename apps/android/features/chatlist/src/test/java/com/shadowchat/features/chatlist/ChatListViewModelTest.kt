package com.shadowchat.features.chatlist

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
class ChatListViewModelTest {
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
        val item = ChatListItemUi(
            roomId = "room-1",
            title = "General",
            unreadCount = 3,
            trustLevel = ChatListTrustLevel.Verified,
        )
        val viewModel = ChatListViewModel(StubChatListRepository(Result.success(listOf(item))))

        viewModel.load()
        advanceUntilIdle()

        assertEquals(ChatListUiState.Loaded(listOf(item)), viewModel.state.value)
    }

    @Test
    fun loadPublishesEmptyState() = runTest(dispatcher) {
        val viewModel = ChatListViewModel(StubChatListRepository(Result.success(emptyList())))

        viewModel.load()
        advanceUntilIdle()

        assertEquals(ChatListUiState.Empty, viewModel.state.value)
    }

    @Test
    fun loadPublishesErrorState() = runTest(dispatcher) {
        val viewModel = ChatListViewModel(StubChatListRepository(Result.failure(TestException())))

        viewModel.load()
        advanceUntilIdle()

        assertEquals(ChatListUiState.Error, viewModel.state.value)
    }

    @Test
    fun retryReloadsItems() = runTest(dispatcher) {
        val item = ChatListItemUi(
            roomId = "room-2",
            title = "Recovered",
            unreadCount = 0,
            trustLevel = ChatListTrustLevel.Standard,
        )
        val viewModel = ChatListViewModel(
            SequencedChatListRepository(
                results = ArrayDeque(
                    listOf(
                        Result.failure(TestException()),
                        Result.success(listOf(item)),
                    ),
                ),
            ),
        )

        viewModel.load()
        advanceUntilIdle()
        assertEquals(ChatListUiState.Error, viewModel.state.value)

        viewModel.onEvent(ChatListEvent.RetryRequested)
        advanceUntilIdle()
        assertEquals(ChatListUiState.Loaded(listOf(item)), viewModel.state.value)
    }
}

private class StubChatListRepository(
    private val result: Result<List<ChatListItemUi>>,
) : ChatListRepository {
    override suspend fun loadChatList(): List<ChatListItemUi> = result.getOrThrow()
}

private class SequencedChatListRepository(
    private val results: ArrayDeque<Result<List<ChatListItemUi>>>,
) : ChatListRepository {
    override suspend fun loadChatList(): List<ChatListItemUi> = results.removeFirst().getOrThrow()
}

private class TestException : Throwable()
