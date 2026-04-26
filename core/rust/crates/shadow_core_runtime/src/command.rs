use serde::{Deserialize, Serialize};
use shadow_core_domain::AccountId;

use crate::dto::MatrixSessionId;

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum SessionCommand {
    DiscoverServer { server_hint: String },
    BeginLogin { auth_hint: Option<String> },
    CompleteLogin { callback_payload: String },
    RestoreSession { account_id: AccountId },
    StartSync { session_id: MatrixSessionId },
    PauseSync { session_id: MatrixSessionId },
    ResumeSync { session_id: MatrixSessionId },
    Logout { session_id: MatrixSessionId },
    ClearLocalSession { account_id: AccountId },
}
