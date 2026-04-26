package com.shadowchat.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewmodel.compose.viewModel
import com.shadowchat.designsystem.ShadowChatTheme
import com.shadowchat.designsystem.ShadowColors
import com.shadowchat.designsystem.ShadowGlassPanel
import com.shadowchat.designsystem.ShadowLiquidBackground
import com.shadowchat.designsystem.ShadowRadii
import com.shadowchat.designsystem.ShadowSpacing
import com.shadowchat.designsystem.shadowAccentGradient
import com.shadowchat.features.chatlist.ChatListItemUi
import com.shadowchat.features.chatlist.ChatListRepository
import com.shadowchat.features.chatlist.ChatListRoute
import com.shadowchat.features.chatlist.ChatListTrustLevel
import com.shadowchat.features.chatlist.ChatListViewModel
import com.shadowchat.features.timeline.RoomTimelineDeliveryState
import com.shadowchat.features.timeline.RoomTimelineItemUi
import com.shadowchat.features.timeline.RoomTimelineMessageDirection
import com.shadowchat.features.timeline.RoomTimelineRepository
import com.shadowchat.features.timeline.RoomTimelineRoute
import com.shadowchat.features.timeline.RoomTimelineSnapshotUi
import com.shadowchat.features.timeline.RoomTimelineViewModel

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContent {
            ShadowChatTheme {
                val chatListViewModel: ChatListViewModel = viewModel(
                    factory = ChatListViewModelFactory(DemoChatListRepository),
                )

                ShadowChatAppShell(chatListViewModel = chatListViewModel)
            }
        }
    }
}

@Composable
private fun ShadowChatAppShell(chatListViewModel: ChatListViewModel) {
    var selectedTab by remember { mutableStateOf(AppTab.Chats) }
    var selectedRoomId by remember { mutableStateOf<String?>(null) }

    ShadowLiquidBackground(modifier = Modifier.fillMaxSize()) {
        Scaffold(
            modifier = Modifier.fillMaxSize(),
            containerColor = Color.Transparent,
            bottomBar = {
                ShadowBottomBar(
                    selectedTab = selectedTab,
                    onTabSelected = {
                        selectedTab = it
                        selectedRoomId = null
                    },
                )
            },
        ) { contentPadding ->
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(contentPadding),
            ) {
                when (selectedTab) {
                    AppTab.Chats -> {
                        val roomId = selectedRoomId
                        if (roomId == null) {
                            ChatListRoute(
                                viewModel = chatListViewModel,
                                onRoomSelected = { selectedRoomId = it },
                            )
                        } else {
                            val timelineViewModel: RoomTimelineViewModel = viewModel(
                                key = roomId,
                                factory = RoomTimelineViewModelFactory(
                                    roomId = roomId,
                                    repository = DemoRoomTimelineRepository,
                                ),
                            )

                            Column {
                                Button(
                                    onClick = { selectedRoomId = null },
                                    modifier = Modifier.padding(start = ShadowSpacing.Lg, top = ShadowSpacing.Lg),
                                ) {
                                    Text(text = stringResource(R.string.timeline_back_to_chats))
                                }
                                RoomTimelineRoute(viewModel = timelineViewModel)
                            }
                        }
                    }
                    AppTab.Calls -> CallsShell()
                    AppTab.Updates -> UpdatesShell()
                    AppTab.Profile -> ProfileShell()
                    AppTab.Settings -> SettingsShell()
                }
            }
        }
    }
}

@Composable
private fun ShadowBottomBar(
    selectedTab: AppTab,
    onTabSelected: (AppTab) -> Unit,
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = ShadowSpacing.Lg, vertical = ShadowSpacing.Md),
    ) {
        ShadowGlassPanel(radius = ShadowRadii.Panel) {
            NavigationBar(
                containerColor = Color.Transparent,
                tonalElevation = ShadowSpacing.Xs,
            ) {
                AppTab.entries.forEach { tab ->
                    NavigationBarItem(
                        selected = selectedTab == tab,
                        onClick = { onTabSelected(tab) },
                        icon = {
                            Text(
                                text = stringResource(tab.symbolResId),
                                style = MaterialTheme.typography.titleMedium,
                            )
                        },
                        label = { Text(text = stringResource(tab.labelResId)) },
                    )
                }
            }
        }
    }
}

@Composable
private fun CallsShell() {
    ShellScaffold(title = stringResource(R.string.tab_calls), symbol = stringResource(R.string.tab_calls_symbol)) {
        PillRow(listOf("All", "Missed", "Voicemail"))
        ShellRow("Sofia Martin", "Outgoing call, today", "Call")
        ShellRow("Daniel Carter", "Missed call, yesterday", "Call")
        ShellRow("Adventure Club", "Group call preview", "Call")
    }
}

@Composable
private fun UpdatesShell() {
    ShellScaffold(title = stringResource(R.string.tab_updates), symbol = stringResource(R.string.tab_updates_symbol)) {
        ShellRow("My Status", "Add a soft glass status update", "New")
        ShellRow("Emma Wilson", "Recent update", "View")
        ShellRow("Family", "Viewed update", "View")
    }
}

@Composable
private fun ProfileShell() {
    ShellScaffold(title = stringResource(R.string.tab_profile), symbol = stringResource(R.string.tab_profile_symbol)) {
        AvatarHero("Sofia Martin", "Online now")
        PillRow(listOf("Message", "Call", "Video", "Pay"))
        ShellRow("About", "Building calm, secure conversations.", "Edit")
        ShellRow("Media, Links, Docs", "24 shared items", "Open")
        ShellRow("Starred Messages", "Quick access shell", "Open")
    }
}

@Composable
private fun SettingsShell() {
    ShellScaffold(title = stringResource(R.string.tab_settings), symbol = stringResource(R.string.tab_settings_symbol)) {
        AvatarHero("ShadowChat", "Premium messenger shell")
        listOf(
            "Account",
            "Privacy",
            "Notifications",
            "Appearance",
            "Chats",
            "Storage and Data",
            "Help Center",
            "Invite Friends",
        ).forEach { title ->
            ShellRow(title, "Settings group shell", "Open")
        }
    }
}

@Composable
private fun ShellScaffold(
    title: String,
    symbol: String,
    content: @Composable ColumnScope.() -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(ShadowSpacing.Lg),
        verticalArrangement = Arrangement.spacedBy(ShadowSpacing.Md),
    ) {
        Row(
            horizontalArrangement = Arrangement.spacedBy(ShadowSpacing.Md),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = symbol,
                style = MaterialTheme.typography.headlineSmall,
                modifier = Modifier
                    .background(shadowAccentGradient(), CircleShape)
                    .padding(ShadowSpacing.Md),
                color = Color.White,
                fontWeight = FontWeight.Bold,
            )
            Text(
                text = title,
                style = MaterialTheme.typography.headlineLarge,
                fontWeight = FontWeight.Bold,
            )
        }

        content()
    }
}

@Composable
private fun PillRow(labels: List<String>) {
    Row(horizontalArrangement = Arrangement.spacedBy(ShadowSpacing.Sm)) {
        labels.forEach { label ->
            Text(
                text = label,
                style = MaterialTheme.typography.labelLarge,
                modifier = Modifier
                    .background(ShadowColors.GlassSurface, CircleShape)
                    .padding(horizontal = ShadowSpacing.Md, vertical = ShadowSpacing.Sm),
            )
        }
    }
}

@Composable
private fun AvatarHero(name: String, subtitle: String) {
    ShadowGlassPanel(radius = ShadowRadii.Panel) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(ShadowSpacing.Lg),
            horizontalArrangement = Arrangement.spacedBy(ShadowSpacing.Md),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            DemoAvatar(initial = name.first().toString())
            Column {
                Text(text = name, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                Text(text = subtitle, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}

@Composable
private fun ShellRow(title: String, subtitle: String, trailing: String) {
    ShadowGlassPanel(
        modifier = Modifier.fillMaxWidth(),
        radius = ShadowRadii.Card,
    ) {
        Row(
            modifier = Modifier.padding(ShadowSpacing.Md),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            DemoAvatar(initial = title.first().toString())
            Spacer(modifier = Modifier.width(ShadowSpacing.Md))
            Column(modifier = Modifier.weight(1f)) {
                Text(text = title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                Text(text = subtitle, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            Text(text = trailing, style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.primary)
        }
    }
}

@Composable
private fun DemoAvatar(initial: String) {
    Box(
        modifier = Modifier
            .size(52.dp)
            .background(shadowAccentGradient(), CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        Text(text = initial, color = Color.White, fontWeight = FontWeight.Bold)
    }
}

private enum class AppTab(
    val labelResId: Int,
    val symbolResId: Int,
) {
    Chats(R.string.tab_chats, R.string.tab_chats_symbol),
    Calls(R.string.tab_calls, R.string.tab_calls_symbol),
    Updates(R.string.tab_updates, R.string.tab_updates_symbol),
    Profile(R.string.tab_profile, R.string.tab_profile_symbol),
    Settings(R.string.tab_settings, R.string.tab_settings_symbol),
}

private object DemoChatListRepository : ChatListRepository {
    override suspend fun loadChatList(): List<ChatListItemUi> = listOf(
        ChatListItemUi("sofia", "Sofia Martin", "Hey! Are we still on for dinner tonight?", "09:41", 2, ChatListTrustLevel.Verified, true),
        ChatListItemUi("design-squad", "Design Squad", "Liam: I will share the assets here.", "09:12", 8, ChatListTrustLevel.Standard, true),
        ChatListItemUi("jason", "Jason Lee", "Sounds good, talk soon!", "Yesterday", 0, ChatListTrustLevel.Verified),
        ChatListItemUi("family", "Family", "Mom: Do not forget Sunday lunch at grandma's!", "Sun", 4, ChatListTrustLevel.Standard),
        ChatListItemUi("emma", "Emma Wilson", "Looks amazing!", "Sat", 1, ChatListTrustLevel.Verified),
        ChatListItemUi("adventure", "Adventure Club", "Trail photos are ready.", "Fri", 0, ChatListTrustLevel.Reduced),
        ChatListItemUi("noah", "Noah Johnson", "Can you review this later?", "Thu", 0, ChatListTrustLevel.Standard),
        ChatListItemUi("daniel", "Daniel Carter", "Call me when you are free.", "Wed", 3, ChatListTrustLevel.Reduced),
    )
}

private object DemoRoomTimelineRepository : RoomTimelineRepository {
    override suspend fun loadTimeline(roomId: String): RoomTimelineSnapshotUi {
        val title = DemoChatListRepository.loadChatList().firstOrNull { it.roomId == roomId }?.title ?: "Conversation"
        return RoomTimelineSnapshotUi(
            roomId = roomId,
            roomTitle = title,
            items = listOf(
                RoomTimelineItemUi("m1", title, "Hey! Are we still on for dinner tonight?", "09:41", RoomTimelineMessageDirection.Incoming, RoomTimelineDeliveryState.Read),
                RoomTimelineItemUi("m2", null, "Yes. I will be there at 8.", "09:43", RoomTimelineMessageDirection.Outgoing, RoomTimelineDeliveryState.Delivered),
                RoomTimelineItemUi("m3", title, "Perfect. I saved us a table near the window.", "09:44", RoomTimelineMessageDirection.Incoming, RoomTimelineDeliveryState.Read),
                RoomTimelineItemUi("m4", null, "Voice preview and media cards will land in the send pipeline slice.", "09:45", RoomTimelineMessageDirection.Outgoing, RoomTimelineDeliveryState.Sent),
            ),
        )
    }
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

private class RoomTimelineViewModelFactory(
    private val roomId: String,
    private val repository: RoomTimelineRepository,
) : ViewModelProvider.Factory {
    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        require(modelClass == RoomTimelineViewModel::class.java) {
            "Unsupported ViewModel: ${modelClass.name}"
        }

        return RoomTimelineViewModel(roomId, repository) as T
    }
}
