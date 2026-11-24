--!strict
-- Feature switches. Change a value here only (K-73, owner 2026-11-24).
--
-- BANTU_ENABLED = false: Bantu Tetangga stays hidden until DAU is stable. Code is kept, nothing is deleted.
--   Off means: no Bantu UI and no Warga panel entry (its HUD button is gated by the bantu feature, which S6 opens);
--   the server rejects SocialBantu; S6 and side_tetangga are `blocked` (Config/Quests); the Agenda pool has no Bantu
--   task (it uses "tanam" instead); Surat letters that ask for Bantu are paid out at once (SuratService).

return {
	BANTU_ENABLED = false,
}
