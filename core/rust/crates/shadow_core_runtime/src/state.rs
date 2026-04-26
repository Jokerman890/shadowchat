use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum SessionState {
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
pub enum SessionEvent {
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
