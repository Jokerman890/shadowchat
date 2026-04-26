use shadow_core_domain::{
    ChatListItem, RoomDisplayName, RoomId, RoomLastMessageSummary, RoomMembership, RoomSummary,
    RoomUnreadState, TrustLevel,
};

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum RoomListError {
    Unavailable,
}

pub trait RoomListAdapter {
    fn load_room_summaries(&self) -> Result<Vec<RoomSummary>, RoomListError>;
}

#[derive(Debug, Clone)]
pub struct StaticRoomListAdapter {
    rooms: Vec<RoomSummary>,
}

impl StaticRoomListAdapter {
    pub fn new(rooms: Vec<RoomSummary>) -> Self {
        Self { rooms }
    }

    pub fn demo() -> Self {
        Self::new(vec![RoomSummary {
            room_id: RoomId("example-room".to_owned()),
            display_name: RoomDisplayName("Welcome".to_owned()),
            last_message: Some(RoomLastMessageSummary {
                body: "ShadowChat is ready for the next Room List adapter slice.".to_owned(),
                sent_at_label: Some("Now".to_owned()),
                sender_display_name: Some("ShadowChat".to_owned()),
            }),
            unread: RoomUnreadState {
                unread_count: 0,
                has_unread_mentions: false,
            },
            trust_level: TrustLevel::Standard,
            membership: RoomMembership::Joined,
            is_favorite: false,
        }])
    }
}

impl RoomListAdapter for StaticRoomListAdapter {
    fn load_room_summaries(&self) -> Result<Vec<RoomSummary>, RoomListError> {
        Ok(self.rooms.clone())
    }
}

pub struct RoomListService<A: RoomListAdapter = StaticRoomListAdapter> {
    adapter: A,
}

impl RoomListService<StaticRoomListAdapter> {
    pub fn new() -> Self {
        Self::with_adapter(StaticRoomListAdapter::demo())
    }
}

impl Default for RoomListService<StaticRoomListAdapter> {
    fn default() -> Self {
        Self::new()
    }
}

impl<A: RoomListAdapter> RoomListService<A> {
    pub fn with_adapter(adapter: A) -> Self {
        Self { adapter }
    }

    pub fn load_room_summaries(&self) -> Result<Vec<RoomSummary>, RoomListError> {
        self.adapter.load_room_summaries()
    }

    pub fn bootstrap(&self) -> Vec<ChatListItem> {
        self.load_room_summaries()
            .unwrap_or_default()
            .into_iter()
            .map(ChatListItem::from)
            .collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn service_loads_room_summaries_from_adapter() {
        let service =
            RoomListService::with_adapter(StaticRoomListAdapter::new(vec![RoomSummary {
                room_id: RoomId("sofia".to_owned()),
                display_name: RoomDisplayName("Sofia Martin".to_owned()),
                last_message: Some(RoomLastMessageSummary {
                    body: "Dinner is still on.".to_owned(),
                    sent_at_label: Some("09:41".to_owned()),
                    sender_display_name: Some("Sofia".to_owned()),
                }),
                unread: RoomUnreadState {
                    unread_count: 2,
                    has_unread_mentions: false,
                },
                trust_level: TrustLevel::Verified,
                membership: RoomMembership::Joined,
                is_favorite: true,
            }]));

        let summaries = service.load_room_summaries().expect("summary load");

        assert_eq!(summaries.len(), 1);
        assert_eq!(summaries[0].room_id, RoomId("sofia".to_owned()));
        assert_eq!(
            summaries[0].display_name,
            RoomDisplayName("Sofia Martin".to_owned())
        );
        assert_eq!(summaries[0].membership, RoomMembership::Joined);
        assert_eq!(summaries[0].unread.unread_count, 2);
    }

    #[test]
    fn bootstrap_keeps_legacy_chat_list_projection() {
        let service =
            RoomListService::with_adapter(StaticRoomListAdapter::new(vec![RoomSummary {
                room_id: RoomId("design-squad".to_owned()),
                display_name: RoomDisplayName("Design Squad".to_owned()),
                last_message: None,
                unread: RoomUnreadState {
                    unread_count: 8,
                    has_unread_mentions: true,
                },
                trust_level: TrustLevel::Standard,
                membership: RoomMembership::Joined,
                is_favorite: true,
            }]));

        let items = service.bootstrap();

        assert_eq!(
            items,
            vec![ChatListItem {
                room_id: RoomId("design-squad".to_owned()),
                title: "Design Squad".to_owned(),
                unread_count: 8,
                trust_level: TrustLevel::Standard,
            }]
        );
    }
}
