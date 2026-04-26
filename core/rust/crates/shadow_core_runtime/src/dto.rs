use serde::{Deserialize, Serialize};
use shadow_core_domain::AccountId;

use crate::{error::SessionErrorKind, state::SessionState};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct MatrixSessionId(pub String);

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct HomeserverUrl(pub String);

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct DeviceId(pub String);

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum SessionCapability {
    RoomListAvailable,
    TimelineAvailable,
    SendAvailable,
    MediaAvailable,
    PushAvailable,
    EncryptionAvailable,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SessionSnapshot {
    pub account_id: Option<AccountId>,
    pub session_id: Option<MatrixSessionId>,
    pub state: SessionState,
    pub homeserver: Option<HomeserverUrl>,
    pub user_display_name: Option<String>,
    pub device_id: Option<DeviceId>,
    pub capabilities: Vec<SessionCapability>,
    pub last_sync_label: Option<String>,
    pub error: Option<SessionErrorKind>,
}

impl SessionSnapshot {
    pub fn not_configured() -> Self {
        Self {
            account_id: None,
            session_id: None,
            state: SessionState::NotConfigured,
            homeserver: None,
            user_display_name: None,
            device_id: None,
            capabilities: Vec::new(),
            last_sync_label: None,
            error: None,
        }
    }
}
