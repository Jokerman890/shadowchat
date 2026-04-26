use serde::{Deserialize, Serialize};
use thiserror::Error;

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum SessionErrorKind {
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

#[derive(Debug, Clone, PartialEq, Eq, Error)]
pub enum SessionRuntimeError {
    #[error("session command is not supported by the current runtime skeleton")]
    UnsupportedCommand,
    #[error("session id does not match the active runtime session")]
    SessionMismatch,
    #[error("session is not active")]
    SessionNotActive,
}
