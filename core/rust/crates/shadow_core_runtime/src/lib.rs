//! Matrix runtime contract skeleton.
//!
//! This crate intentionally contains no Matrix SDK integration, no network
//! calls, no credential storage, and no productive persistence.

pub mod command;
pub mod dto;
pub mod error;
pub mod ffi;
pub mod runtime;
pub mod state;

pub use command::SessionCommand;
pub use dto::{DeviceId, HomeserverUrl, MatrixSessionId, SessionCapability, SessionSnapshot};
pub use error::{SessionErrorKind, SessionRuntimeError};
pub use ffi::{
    FfiSessionCapability, FfiSessionCommand, FfiSessionErrorKind, FfiSessionEvent,
    FfiSessionSnapshot, FfiSessionState,
};
pub use runtime::{MatrixSessionRuntime, NoopMatrixSessionRuntime};
pub use state::{SessionEvent, SessionState};
