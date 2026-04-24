use anyhow::Result;
use shadow_core_domain::AccountId;

pub struct AuthService;

impl AuthService {
    pub fn login(&self, user_hint: &str) -> Result<AccountId> {
        Ok(AccountId(user_hint.to_owned()))
    }
}
