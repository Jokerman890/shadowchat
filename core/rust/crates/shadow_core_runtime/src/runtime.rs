use shadow_core_domain::AccountId;

use crate::{
    command::SessionCommand,
    dto::{MatrixSessionId, SessionCapability, SessionSnapshot},
    error::{SessionErrorKind, SessionRuntimeError},
    state::{SessionEvent, SessionState},
};

pub trait MatrixSessionRuntime {
    fn snapshot(&self) -> SessionSnapshot;
    fn handle_command(
        &mut self,
        command: SessionCommand,
    ) -> Result<SessionEvent, SessionRuntimeError>;
}

#[derive(Debug, Clone)]
pub struct NoopMatrixSessionRuntime {
    snapshot: SessionSnapshot,
}

impl NoopMatrixSessionRuntime {
    pub fn new() -> Self {
        Self {
            snapshot: SessionSnapshot::not_configured(),
        }
    }

    fn activate_for_account(&mut self, account_id: AccountId) {
        self.snapshot.account_id = Some(account_id);
        self.snapshot.session_id = Some(MatrixSessionId("local-session-skeleton".to_owned()));
        self.snapshot.state = SessionState::Active;
        self.snapshot.capabilities = vec![
            SessionCapability::RoomListAvailable,
            SessionCapability::TimelineAvailable,
        ];
        self.snapshot.error = None;
    }

    fn ensure_session(&self, session_id: &MatrixSessionId) -> Result<(), SessionRuntimeError> {
        match &self.snapshot.session_id {
            Some(active) if active == session_id => Ok(()),
            _ => Err(SessionRuntimeError::SessionMismatch),
        }
    }
}

impl Default for NoopMatrixSessionRuntime {
    fn default() -> Self {
        Self::new()
    }
}

impl MatrixSessionRuntime for NoopMatrixSessionRuntime {
    fn snapshot(&self) -> SessionSnapshot {
        self.snapshot.clone()
    }

    fn handle_command(
        &mut self,
        command: SessionCommand,
    ) -> Result<SessionEvent, SessionRuntimeError> {
        match command {
            SessionCommand::DiscoverServer { .. } => {
                self.snapshot.state = SessionState::Discovering;
                Ok(SessionEvent::DiscoveryStarted)
            }
            SessionCommand::BeginLogin { .. } => {
                self.snapshot.state = SessionState::Authenticating;
                Ok(SessionEvent::LoginStarted)
            }
            SessionCommand::RestoreSession { account_id } => {
                self.activate_for_account(account_id);
                Ok(SessionEvent::RestoreCompleted)
            }
            SessionCommand::StartSync { session_id } => {
                self.ensure_session(&session_id)?;
                if self.snapshot.state != SessionState::Active {
                    self.snapshot.error = Some(SessionErrorKind::SyncUnavailable);
                    return Err(SessionRuntimeError::SessionNotActive);
                }
                self.snapshot.state = SessionState::Syncing;
                Ok(SessionEvent::SyncStarted)
            }
            SessionCommand::PauseSync { session_id } => {
                self.ensure_session(&session_id)?;
                self.snapshot.state = SessionState::Active;
                Ok(SessionEvent::SyncPaused)
            }
            SessionCommand::Logout { session_id } => {
                self.ensure_session(&session_id)?;
                self.snapshot = SessionSnapshot::not_configured();
                self.snapshot.state = SessionState::Unauthenticated;
                Ok(SessionEvent::LoggedOut)
            }
            SessionCommand::ClearLocalSession { .. } => {
                self.snapshot = SessionSnapshot::not_configured();
                Ok(SessionEvent::LoggedOut)
            }
            SessionCommand::CompleteLogin { .. } | SessionCommand::ResumeSync { .. } => {
                Err(SessionRuntimeError::UnsupportedCommand)
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use shadow_core_domain::AccountId;

    use super::*;

    #[test]
    fn default_snapshot_is_not_configured_and_secret_free() {
        let runtime = NoopMatrixSessionRuntime::new();
        let snapshot = runtime.snapshot();

        assert_eq!(snapshot.state, SessionState::NotConfigured);
        assert!(snapshot.account_id.is_none());
        assert!(snapshot.session_id.is_none());
        assert!(snapshot.capabilities.is_empty());
    }

    #[test]
    fn restore_session_activates_snapshot_without_network() {
        let mut runtime = NoopMatrixSessionRuntime::new();

        let event = runtime
            .handle_command(SessionCommand::RestoreSession {
                account_id: AccountId("@alice:example.org".to_owned()),
            })
            .expect("restore skeleton should be deterministic");
        let snapshot = runtime.snapshot();

        assert_eq!(event, SessionEvent::RestoreCompleted);
        assert_eq!(snapshot.state, SessionState::Active);
        assert_eq!(
            snapshot.account_id,
            Some(AccountId("@alice:example.org".to_owned()))
        );
        assert!(snapshot
            .capabilities
            .contains(&SessionCapability::RoomListAvailable));
        assert!(snapshot
            .capabilities
            .contains(&SessionCapability::TimelineAvailable));
    }

    #[test]
    fn sync_requires_matching_active_session() {
        let mut runtime = NoopMatrixSessionRuntime::new();

        runtime
            .handle_command(SessionCommand::RestoreSession {
                account_id: AccountId("@alice:example.org".to_owned()),
            })
            .expect("restore skeleton should be deterministic");

        let err = runtime
            .handle_command(SessionCommand::StartSync {
                session_id: MatrixSessionId("other-session".to_owned()),
            })
            .expect_err("mismatched session must be rejected");
        assert_eq!(err, SessionRuntimeError::SessionMismatch);

        let session_id = runtime
            .snapshot()
            .session_id
            .expect("restore should create a skeleton session id");
        let event = runtime
            .handle_command(SessionCommand::StartSync { session_id })
            .expect("matching active session can enter sync state");

        assert_eq!(event, SessionEvent::SyncStarted);
        assert_eq!(runtime.snapshot().state, SessionState::Syncing);
    }
}
