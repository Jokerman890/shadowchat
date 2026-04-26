use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct AccountId(pub String);

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct RoomId(pub String);

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum TrustLevel {
    Verified,
    Standard,
    Reduced,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct RoomDisplayName(pub String);

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum RoomMembership {
    Joined,
    Invited,
    Left,
    Knocked,
    Banned,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct RoomLastMessageSummary {
    pub body: String,
    pub sent_at_label: Option<String>,
    pub sender_display_name: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct RoomUnreadState {
    pub unread_count: u32,
    pub has_unread_mentions: bool,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct RoomSummary {
    pub room_id: RoomId,
    pub display_name: RoomDisplayName,
    pub last_message: Option<RoomLastMessageSummary>,
    pub unread: RoomUnreadState,
    pub trust_level: TrustLevel,
    pub membership: RoomMembership,
    pub is_favorite: bool,
}

impl RoomSummary {
    pub fn chat_list_item(&self) -> ChatListItem {
        ChatListItem {
            room_id: self.room_id.clone(),
            title: self.display_name.0.clone(),
            unread_count: self.unread.unread_count,
            trust_level: self.trust_level.clone(),
        }
    }
}

impl From<RoomSummary> for ChatListItem {
    fn from(summary: RoomSummary) -> Self {
        Self {
            room_id: summary.room_id,
            title: summary.display_name.0,
            unread_count: summary.unread.unread_count,
            trust_level: summary.trust_level,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ChatListItem {
    pub room_id: RoomId,
    pub title: String,
    pub unread_count: u32,
    pub trust_level: TrustLevel,
}
