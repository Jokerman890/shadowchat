use shadow_core_domain::AccountId;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Session {
    pub account_id: AccountId,
}

pub struct SessionStore {
    current: Option<Session>,
}

impl SessionStore {
    pub fn new() -> Self {
        Self { current: None }
    }

    pub fn replace(&mut self, session: Session) {
        self.current = Some(session);
    }

    pub fn current(&self) -> Option<&Session> {
        self.current.as_ref()
    }
}
