--!strict
-- Economy constants. Content prices live in their own configs (Crops, Fish, Shop...).

return {
	START_KOIN = 100, -- FINAL (dikembalikan dari 50 atas perintah user, 16 Nov)
	START_BUNGA = 10,

	MAX_BALANCE = 999_999_999_999, -- hard cap, keeps values integer-safe
	MAX_TRANSACTION = 100_000_000, -- any single add/spend above this is rejected as a bug/exploit
}
