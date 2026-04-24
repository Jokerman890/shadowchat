use shadow_core_domain::{ChatListItem, RoomId, TrustLevel};

pub struct RoomListService;

impl RoomListService {
    pub fn bootstrap(&self) -> Vec<ChatListItem> {
        vec![ChatListItem {
            room_id: RoomId("example-room".to_owned()),
            title: "Welcome".to_owned(),
            unread_count: 0,
            trust_level: TrustLevel::Standard,
        }]
    }
}
