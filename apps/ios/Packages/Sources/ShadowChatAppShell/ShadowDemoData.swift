import ShadowChatListFeature
import ShadowRoomTimelineFeature

struct ShadowShellRowData: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let trailing: String

    init(title: String, subtitle: String, trailing: String) {
        self.id = "\(title)-\(subtitle)-\(trailing)"
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }
}

struct ShadowShellHeroData {
    let name: String
    let subtitle: String
}

enum ShadowDemoData {
    static let chatRooms: [ChatListItemViewState] = [
        ChatListItemViewState(roomId: "sofia", title: "Sofia Martin", previewText: "Hey! Are we still on for dinner tonight?", sentAtLabel: "09:41", unreadCount: 2, trustLevel: .verified, isFavorite: true),
        ChatListItemViewState(roomId: "design-squad", title: "Design Squad", previewText: "Liam: I'll share the assets here.", sentAtLabel: "09:12", unreadCount: 8, trustLevel: .standard, isFavorite: true),
        ChatListItemViewState(roomId: "jason", title: "Jason Lee", previewText: "Sounds good, talk soon!", sentAtLabel: "Yesterday", unreadCount: 0, trustLevel: .verified),
        ChatListItemViewState(roomId: "family", title: "Family", previewText: "Mom: Don't forget Sunday lunch at grandma's!", sentAtLabel: "Sun", unreadCount: 4, trustLevel: .standard),
        ChatListItemViewState(roomId: "emma", title: "Emma Wilson", previewText: "Looks amazing!", sentAtLabel: "Sat", unreadCount: 1, trustLevel: .verified),
        ChatListItemViewState(roomId: "adventure", title: "Adventure Club", previewText: "Trail photos are ready.", sentAtLabel: "Fri", unreadCount: 0, trustLevel: .reduced),
        ChatListItemViewState(roomId: "noah", title: "Noah Johnson", previewText: "Can you review this later?", sentAtLabel: "Thu", unreadCount: 0, trustLevel: .standard),
        ChatListItemViewState(roomId: "daniel", title: "Daniel Carter", previewText: "Call me when you are free.", sentAtLabel: "Wed", unreadCount: 3, trustLevel: .reduced)
    ]

    static let callFilters = ["All", "Missed", "Voicemail"]

    static let callRows: [ShadowShellRowData] = [
        ShadowShellRowData(title: "Sofia Martin", subtitle: "Outgoing call, today", trailing: "Call"),
        ShadowShellRowData(title: "Daniel Carter", subtitle: "Missed call, yesterday", trailing: "Call"),
        ShadowShellRowData(title: "Adventure Club", subtitle: "Group call preview", trailing: "Call")
    ]

    static let updateRows: [ShadowShellRowData] = [
        ShadowShellRowData(title: "My Status", subtitle: "Add a soft glass status update", trailing: "New"),
        ShadowShellRowData(title: "Emma Wilson", subtitle: "Recent update", trailing: "View"),
        ShadowShellRowData(title: "Family", subtitle: "Viewed update", trailing: "View")
    ]

    static let profileHero = ShadowShellHeroData(name: "Sofia Martin", subtitle: "Online now")
    static let profileActions = ["Message", "Call", "Video", "Pay"]
    static let profileRows: [ShadowShellRowData] = [
        ShadowShellRowData(title: "About", subtitle: "Building calm, secure conversations.", trailing: "Edit"),
        ShadowShellRowData(title: "Media, Links, Docs", subtitle: "24 shared items", trailing: "Open"),
        ShadowShellRowData(title: "Starred Messages", subtitle: "Quick access shell", trailing: "Open")
    ]

    static let settingsHero = ShadowShellHeroData(name: "ShadowChat", subtitle: "Premium messenger shell")
    static let settingsRows: [ShadowShellRowData] = [
        "Account",
        "Privacy",
        "Notifications",
        "Appearance",
        "Chats",
        "Storage and Data",
        "Help Center",
        "Invite Friends"
    ].map { title in
        ShadowShellRowData(title: title, subtitle: "Settings group shell", trailing: "Open")
    }

    static func timelineSnapshot(roomId: String) -> RoomTimelineSnapshotViewState {
        let roomTitle = chatRooms.first { $0.roomId == roomId }?.title ?? "Conversation"
        return RoomTimelineSnapshotViewState(
            roomId: roomId,
            roomTitle: roomTitle,
            items: timelineItems(roomId: roomId, roomTitle: roomTitle)
        )
    }

    private static func timelineItems(roomId: String, roomTitle: String) -> [RoomTimelineItemViewState] {
        switch roomId {
        case "sofia":
            return [
                incoming("sofia-1", roomTitle, "Hey! Are we still on for dinner tonight?", "09:41"),
                outgoing("sofia-2", "Yes. I will be there at 8.", "09:43", .delivered),
                incoming("sofia-3", roomTitle, "Perfect. I saved us a table near the window.", "09:44"),
                outgoing("sofia-4", "Voice preview and media cards will land in the send pipeline slice.", "09:45", .sent)
            ]
        case "design-squad":
            return [
                incoming("design-1", "Liam", "I'll share the assets here.", "09:12"),
                outgoing("design-2", "Great. Keep the glass cards readable on small screens.", "09:14", .delivered),
                incoming("design-3", "Maya", "The lavender accent works best when the header stays calm.", "09:18")
            ]
        case "jason":
            return [
                incoming("jason-1", roomTitle, "Sounds good, talk soon!", "Yesterday"),
                outgoing("jason-2", "Thanks. I will send the notes after lunch.", "Yesterday", .read)
            ]
        case "family":
            return [
                incoming("family-1", "Mom", "Don't forget Sunday lunch at grandma's!", "Sun"),
                outgoing("family-2", "I have it saved. I will bring dessert.", "Sun", .delivered),
                incoming("family-3", "Alex", "I can pick up drinks on the way.", "Sun")
            ]
        case "emma":
            return [
                incoming("emma-1", roomTitle, "Looks amazing!", "Sat"),
                outgoing("emma-2", "Thank you. The final polish is starting to feel right.", "Sat", .read)
            ]
        case "adventure":
            return [
                incoming("adventure-1", roomTitle, "Trail photos are ready.", "Fri"),
                outgoing("adventure-2", "Nice. Send the album when you can.", "Fri", .sent),
                incoming("adventure-3", roomTitle, "Reminder: this demo room keeps reduced trust visible.", "Fri")
            ]
        case "noah":
            return [
                incoming("noah-1", roomTitle, "Can you review this later?", "Thu"),
                outgoing("noah-2", "Yes, I will take a look tonight.", "Thu", .delivered)
            ]
        case "daniel":
            return [
                incoming("daniel-1", roomTitle, "Call me when you are free.", "Wed"),
                outgoing("daniel-2", "I am in a meeting now. I will call after.", "Wed", .sent)
            ]
        default:
            return [
                incoming("unknown-1", roomTitle, "This local demo room has no Matrix-backed timeline yet.", "Now")
            ]
        }
    }

    private static func incoming(
        _ id: String,
        _ sender: String,
        _ body: String,
        _ time: String,
        _ deliveryState: RoomTimelineDeliveryState = .read
    ) -> RoomTimelineItemViewState {
        RoomTimelineItemViewState(
            messageId: id,
            senderDisplayName: sender,
            body: body,
            sentAtLabel: time,
            direction: .incoming,
            deliveryState: deliveryState
        )
    }

    private static func outgoing(
        _ id: String,
        _ body: String,
        _ time: String,
        _ deliveryState: RoomTimelineDeliveryState
    ) -> RoomTimelineItemViewState {
        RoomTimelineItemViewState(
            messageId: id,
            senderDisplayName: nil,
            body: body,
            sentAtLabel: time,
            direction: .outgoing,
            deliveryState: deliveryState
        )
    }
}

struct DemoChatListRepository: ChatListRepository {
    func loadChatList() async throws -> [ChatListItemViewState] {
        ShadowDemoData.chatRooms
    }
}

struct DemoRoomTimelineRepository: RoomTimelineRepository {
    func loadTimeline(roomId: String) async throws -> RoomTimelineSnapshotViewState {
        ShadowDemoData.timelineSnapshot(roomId: roomId)
    }
}
