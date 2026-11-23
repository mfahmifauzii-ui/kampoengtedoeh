--!strict
-- DEV access (K-64, Putaran 2). Who may use the DEV commands (chat "!..." and the DevCmd remote, see DevService.IsAllowed).
--   Studio: always allowed.
--   Live: only the UserIds below, and only while LIVE_ENABLED is true.
-- R10.5 and gate G3 (Roadmap Bab 21): LIVE_ENABLED = false and an automated AUTO check before public release.

return {
	LIVE_ENABLED = true, -- false = live servers refuse the DEV commands even for the owner
	UserIds = { 9416491408 }, -- the owner's account (was OWNER_USER_ID in DevService)
}
