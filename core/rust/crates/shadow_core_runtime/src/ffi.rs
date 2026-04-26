use serde::{Deserialize, Serialize};
use shadow_core_domain::AccountId;

use crate::{
    command::SessionCommand,
    dto::{DeviceId, HomeserverUrl, MatrixSessionId, SessionCapability, SessionSnapshot},
    error::SessionErrorKind,
    state::{SessionEvent, SessionState},
};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct FfiSessionSnapshot {
    pub account_id: Option<String>,
    pub session_id: Option<String>,
    pub state: FfiSessionState,
    pub homeserver: Option<String>,
    pub user_display_name: Option<String>,
    pub device_id: Option<String>,
    pub capabilities: Vec<FfiSessionCapability>,
    pub last_sync_label: Option<String>,
    pub error: Option<FfiSessionErrorKind>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum FfiSessionCommand {
    DiscoverServer { server_hint: String },
    BeginLogin { auth_hint: Option<String> },
    CompleteLogin { callback_payload: String },
    RestoreSession { account_id: String },
    StartSync { session_id: String },
    PauseSync { session_id: String },
    ResumeSync { session_id: String },
    Logout { session_id: String },
    ClearLocalSession { account_id: String },
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum FfiSessionState {
    NotConfigured,
    Discovering,
    Unauthenticated,
    Authenticating,
    Restoring,
    Active,
    Syncing,
    Offline,
    Expired,
    Locked,
    Failed,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum FfiSessionEvent {
    DiscoveryStarted,
    DiscoveryCompleted,
    LoginStarted,
    LoginCompleted,
    RestoreStarted,
    RestoreCompleted,
    SessionBecameActive,
    SyncStarted,
    SyncPaused,
    SyncRecovered,
    SessionExpired,
    SessionLocked,
    SessionFailed,
    LoggedOut,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum FfiSessionErrorKind {
    NetworkUnavailable,
    ServerDiscoveryFailed,
    AuthenticationRequired,
    AuthenticationExpired,
    RestoreFailed,
    DeviceUntrusted,
    CryptoStateUnavailable,
    SyncUnavailable,
    RateLimited,
    ServerRejected,
    StorageUnavailable,
    Unknown,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum FfiSessionCapability {
    RoomListAvailable,
    TimelineAvailable,
    SendAvailable,
    MediaAvailable,
    PushAvailable,
    EncryptionAvailable,
}

impl From<SessionSnapshot> for FfiSessionSnapshot {
    fn from(value: SessionSnapshot) -> Self {
        Self {
            account_id: value.account_id.map(|id| id.0),
            session_id: value.session_id.map(|id| id.0),
            state: value.state.into(),
            homeserver: value.homeserver.map(|url| url.0),
            user_display_name: value.user_display_name,
            device_id: value.device_id.map(|id| id.0),
            capabilities: value
                .capabilities
                .into_iter()
                .map(FfiSessionCapability::from)
                .collect(),
            last_sync_label: value.last_sync_label,
            error: value.error.map(FfiSessionErrorKind::from),
        }
    }
}

impl From<FfiSessionSnapshot> for SessionSnapshot {
    fn from(value: FfiSessionSnapshot) -> Self {
        Self {
            account_id: value.account_id.map(AccountId),
            session_id: value.session_id.map(MatrixSessionId),
            state: value.state.into(),
            homeserver: value.homeserver.map(HomeserverUrl),
            user_display_name: value.user_display_name,
            device_id: value.device_id.map(DeviceId),
            capabilities: value
                .capabilities
                .into_iter()
                .map(SessionCapability::from)
                .collect(),
            last_sync_label: value.last_sync_label,
            error: value.error.map(SessionErrorKind::from),
        }
    }
}

impl From<SessionCommand> for FfiSessionCommand {
    fn from(value: SessionCommand) -> Self {
        match value {
            SessionCommand::DiscoverServer { server_hint } => Self::DiscoverServer { server_hint },
            SessionCommand::BeginLogin { auth_hint } => Self::BeginLogin { auth_hint },
            SessionCommand::CompleteLogin { callback_payload } => {
                Self::CompleteLogin { callback_payload }
            }
            SessionCommand::RestoreSession { account_id } => Self::RestoreSession {
                account_id: account_id.0,
            },
            SessionCommand::StartSync { session_id } => Self::StartSync {
                session_id: session_id.0,
            },
            SessionCommand::PauseSync { session_id } => Self::PauseSync {
                session_id: session_id.0,
            },
            SessionCommand::ResumeSync { session_id } => Self::ResumeSync {
                session_id: session_id.0,
            },
            SessionCommand::Logout { session_id } => Self::Logout {
                session_id: session_id.0,
            },
            SessionCommand::ClearLocalSession { account_id } => Self::ClearLocalSession {
                account_id: account_id.0,
            },
        }
    }
}

impl From<FfiSessionCommand> for SessionCommand {
    fn from(value: FfiSessionCommand) -> Self {
        match value {
            FfiSessionCommand::DiscoverServer { server_hint } => {
                Self::DiscoverServer { server_hint }
            }
            FfiSessionCommand::BeginLogin { auth_hint } => Self::BeginLogin { auth_hint },
            FfiSessionCommand::CompleteLogin { callback_payload } => {
                Self::CompleteLogin { callback_payload }
            }
            FfiSessionCommand::RestoreSession { account_id } => Self::RestoreSession {
                account_id: AccountId(account_id),
            },
            FfiSessionCommand::StartSync { session_id } => Self::StartSync {
                session_id: MatrixSessionId(session_id),
            },
            FfiSessionCommand::PauseSync { session_id } => Self::PauseSync {
                session_id: MatrixSessionId(session_id),
            },
            FfiSessionCommand::ResumeSync { session_id } => Self::ResumeSync {
                session_id: MatrixSessionId(session_id),
            },
            FfiSessionCommand::Logout { session_id } => Self::Logout {
                session_id: MatrixSessionId(session_id),
            },
            FfiSessionCommand::ClearLocalSession { account_id } => Self::ClearLocalSession {
                account_id: AccountId(account_id),
            },
        }
    }
}

impl From<SessionState> for FfiSessionState {
    fn from(value: SessionState) -> Self {
        match value {
            SessionState::NotConfigured => Self::NotConfigured,
            SessionState::Discovering => Self::Discovering,
            SessionState::Unauthenticated => Self::Unauthenticated,
            SessionState::Authenticating => Self::Authenticating,
            SessionState::Restoring => Self::Restoring,
            SessionState::Active => Self::Active,
            SessionState::Syncing => Self::Syncing,
            SessionState::Offline => Self::Offline,
            SessionState::Expired => Self::Expired,
            SessionState::Locked => Self::Locked,
            SessionState::Failed => Self::Failed,
        }
    }
}

impl From<FfiSessionState> for SessionState {
    fn from(value: FfiSessionState) -> Self {
        match value {
            FfiSessionState::NotConfigured => Self::NotConfigured,
            FfiSessionState::Discovering => Self::Discovering,
            FfiSessionState::Unauthenticated => Self::Unauthenticated,
            FfiSessionState::Authenticating => Self::Authenticating,
            FfiSessionState::Restoring => Self::Restoring,
            FfiSessionState::Active => Self::Active,
            FfiSessionState::Syncing => Self::Syncing,
            FfiSessionState::Offline => Self::Offline,
            FfiSessionState::Expired => Self::Expired,
            FfiSessionState::Locked => Self::Locked,
            FfiSessionState::Failed => Self::Failed,
        }
    }
}

impl From<SessionEvent> for FfiSessionEvent {
    fn from(value: SessionEvent) -> Self {
        match value {
            SessionEvent::DiscoveryStarted => Self::DiscoveryStarted,
            SessionEvent::DiscoveryCompleted => Self::DiscoveryCompleted,
            SessionEvent::LoginStarted => Self::LoginStarted,
            SessionEvent::LoginCompleted => Self::LoginCompleted,
            SessionEvent::RestoreStarted => Self::RestoreStarted,
            SessionEvent::RestoreCompleted => Self::RestoreCompleted,
            SessionEvent::SessionBecameActive => Self::SessionBecameActive,
            SessionEvent::SyncStarted => Self::SyncStarted,
            SessionEvent::SyncPaused => Self::SyncPaused,
            SessionEvent::SyncRecovered => Self::SyncRecovered,
            SessionEvent::SessionExpired => Self::SessionExpired,
            SessionEvent::SessionLocked => Self::SessionLocked,
            SessionEvent::SessionFailed => Self::SessionFailed,
            SessionEvent::LoggedOut => Self::LoggedOut,
        }
    }
}

impl From<FfiSessionEvent> for SessionEvent {
    fn from(value: FfiSessionEvent) -> Self {
        match value {
            FfiSessionEvent::DiscoveryStarted => Self::DiscoveryStarted,
            FfiSessionEvent::DiscoveryCompleted => Self::DiscoveryCompleted,
            FfiSessionEvent::LoginStarted => Self::LoginStarted,
            FfiSessionEvent::LoginCompleted => Self::LoginCompleted,
            FfiSessionEvent::RestoreStarted => Self::RestoreStarted,
            FfiSessionEvent::RestoreCompleted => Self::RestoreCompleted,
            FfiSessionEvent::SessionBecameActive => Self::SessionBecameActive,
            FfiSessionEvent::SyncStarted => Self::SyncStarted,
            FfiSessionEvent::SyncPaused => Self::SyncPaused,
            FfiSessionEvent::SyncRecovered => Self::SyncRecovered,
            FfiSessionEvent::SessionExpired => Self::SessionExpired,
            FfiSessionEvent::SessionLocked => Self::SessionLocked,
            FfiSessionEvent::SessionFailed => Self::SessionFailed,
            FfiSessionEvent::LoggedOut => Self::LoggedOut,
        }
    }
}

impl From<SessionErrorKind> for FfiSessionErrorKind {
    fn from(value: SessionErrorKind) -> Self {
        match value {
            SessionErrorKind::NetworkUnavailable => Self::NetworkUnavailable,
            SessionErrorKind::ServerDiscoveryFailed => Self::ServerDiscoveryFailed,
            SessionErrorKind::AuthenticationRequired => Self::AuthenticationRequired,
            SessionErrorKind::AuthenticationExpired => Self::AuthenticationExpired,
            SessionErrorKind::RestoreFailed => Self::RestoreFailed,
            SessionErrorKind::DeviceUntrusted => Self::DeviceUntrusted,
            SessionErrorKind::CryptoStateUnavailable => Self::CryptoStateUnavailable,
            SessionErrorKind::SyncUnavailable => Self::SyncUnavailable,
            SessionErrorKind::RateLimited => Self::RateLimited,
            SessionErrorKind::ServerRejected => Self::ServerRejected,
            SessionErrorKind::StorageUnavailable => Self::StorageUnavailable,
            SessionErrorKind::Unknown => Self::Unknown,
        }
    }
}

impl From<FfiSessionErrorKind> for SessionErrorKind {
    fn from(value: FfiSessionErrorKind) -> Self {
        match value {
            FfiSessionErrorKind::NetworkUnavailable => Self::NetworkUnavailable,
            FfiSessionErrorKind::ServerDiscoveryFailed => Self::ServerDiscoveryFailed,
            FfiSessionErrorKind::AuthenticationRequired => Self::AuthenticationRequired,
            FfiSessionErrorKind::AuthenticationExpired => Self::AuthenticationExpired,
            FfiSessionErrorKind::RestoreFailed => Self::RestoreFailed,
            FfiSessionErrorKind::DeviceUntrusted => Self::DeviceUntrusted,
            FfiSessionErrorKind::CryptoStateUnavailable => Self::CryptoStateUnavailable,
            FfiSessionErrorKind::SyncUnavailable => Self::SyncUnavailable,
            FfiSessionErrorKind::RateLimited => Self::RateLimited,
            FfiSessionErrorKind::ServerRejected => Self::ServerRejected,
            FfiSessionErrorKind::StorageUnavailable => Self::StorageUnavailable,
            FfiSessionErrorKind::Unknown => Self::Unknown,
        }
    }
}

impl From<SessionCapability> for FfiSessionCapability {
    fn from(value: SessionCapability) -> Self {
        match value {
            SessionCapability::RoomListAvailable => Self::RoomListAvailable,
            SessionCapability::TimelineAvailable => Self::TimelineAvailable,
            SessionCapability::SendAvailable => Self::SendAvailable,
            SessionCapability::MediaAvailable => Self::MediaAvailable,
            SessionCapability::PushAvailable => Self::PushAvailable,
            SessionCapability::EncryptionAvailable => Self::EncryptionAvailable,
        }
    }
}

impl From<FfiSessionCapability> for SessionCapability {
    fn from(value: FfiSessionCapability) -> Self {
        match value {
            FfiSessionCapability::RoomListAvailable => Self::RoomListAvailable,
            FfiSessionCapability::TimelineAvailable => Self::TimelineAvailable,
            FfiSessionCapability::SendAvailable => Self::SendAvailable,
            FfiSessionCapability::MediaAvailable => Self::MediaAvailable,
            FfiSessionCapability::PushAvailable => Self::PushAvailable,
            FfiSessionCapability::EncryptionAvailable => Self::EncryptionAvailable,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn snapshot_mapping_is_value_based_and_secret_free() {
        let snapshot = SessionSnapshot {
            account_id: Some(AccountId("@alice:example.org".to_owned())),
            session_id: Some(MatrixSessionId("session-1".to_owned())),
            state: SessionState::Active,
            homeserver: Some(HomeserverUrl("https://matrix.example.org".to_owned())),
            user_display_name: Some("Alice".to_owned()),
            device_id: Some(DeviceId("DEVICEID".to_owned())),
            capabilities: vec![
                SessionCapability::RoomListAvailable,
                SessionCapability::TimelineAvailable,
            ],
            last_sync_label: Some("just now".to_owned()),
            error: None,
        };

        let ffi = FfiSessionSnapshot::from(snapshot);

        assert_eq!(ffi.account_id.as_deref(), Some("@alice:example.org"));
        assert_eq!(ffi.session_id.as_deref(), Some("session-1"));
        assert_eq!(ffi.state, FfiSessionState::Active);
        assert_eq!(
            ffi.capabilities,
            vec![
                FfiSessionCapability::RoomListAvailable,
                FfiSessionCapability::TimelineAvailable,
            ]
        );
    }

    #[test]
    fn command_mapping_preserves_string_payloads() {
        let ffi = FfiSessionCommand::RestoreSession {
            account_id: "@alice:example.org".to_owned(),
        };

        let command = SessionCommand::from(ffi);

        assert_eq!(
            command,
            SessionCommand::RestoreSession {
                account_id: AccountId("@alice:example.org".to_owned()),
            }
        );
    }

    #[test]
    fn error_mapping_keeps_security_relevant_categories_explicit() {
        let ffi = FfiSessionErrorKind::from(SessionErrorKind::DeviceUntrusted);
        let core = SessionErrorKind::from(ffi.clone());

        assert_eq!(ffi, FfiSessionErrorKind::DeviceUntrusted);
        assert_eq!(core, SessionErrorKind::DeviceUntrusted);
    }
}
