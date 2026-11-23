--!strict
-- New-player guide.
--
-- 1) OLD GUIDE (client/Controllers/GuideController, "legacy" part): on-screen hints for the first loop (cangkul -> tanam ->
--    siram -> panen -> jual) and an arrow to the buyer (Pak Udin). It runs until the player has finished TRIES sale trips
--    (data.guide.sells, counted by ShopService each time something is sold), then stops for good. It only shows while no
--    tutorial below is running.
--
-- 2) TUTORIAL ENGINE (same controller + server/TutorialService): runs the tutorials listed in TUTORIALS, one at a time.
--    Progress lives in data.guide (step, done, skipped, fastLeft). The shape of one tutorial is documented below; the real
--    content (T1 Bertani, T1b, T2 ...) is added in later phases (docs/Implementation_Plan.md section 4).

export type Condition = {
	kind: string, -- see CONDITION KINDS
	n: number?, -- ">=" threshold (default 1)
	id: string?, -- item prefix / npc id / panel name, per kind
	dist: number?, -- studs, for "near" (default 25)
	any: { Condition }?, -- kind "any": true when one of these holds (v6.2.3 A1)
}

export type Reward = {
	xp: number?,
	koin: number?,
	bunga: number?,
	items: { [string]: number }?, -- inventory ids
	xpFill: boolean?, -- B2 (K-54): tops XP up to the Lv 2 threshold (catch XP varies, so no fixed number lands on Lv 2)
}

export type Step = {
	id: string, -- analytics: tut_<tutorial>_<step id>
	text: string, -- Locale key of the instruction (hint bar)
	textStuck: string?, -- Locale key shown after 90 s without progress (more explicit); default = text + "tut.stuck_suffix"
	done: Condition, -- the step counts as done when this holds (always ">=" style, never "exactly")
	highlight: string?, -- name of a button to ring + point at, in any open screen (e.g. "GarapButton", "KolamButton")
	target: { npc: string?, pos: Vector3?, spot: string?, land: boolean? }?, -- the ground arrow points here until the player is within `arrive` studs (spot = the nearest fishing spot of that Location, e.g. "sungai")
	arrive: number?, -- studs (default 25)
	reward: Reward?, -- paid once when the step completes (never on replay)
	modal: { title: string, body: string }?, -- kind "ack" only: the welcome modal (Locale keys); Mulai acks it, no skip
	coach: string?, -- Locale key of the coachmark bubble (defaults to text)
	repeatStep: boolean?, -- rule 2 (GUI 4.6): the step was already done once; toast only
	spotlight: boolean?, -- rule 1a (GUI 4.6): one dark hole around a FIXED HUD button, first time only. Default false = ring only
	greet: string?, -- Locale key: a sapaan said first in the cutscene of this step (Fase 2; {name} = the player). Used by panen_jual
}

export type Trigger = {
	kind: string, -- "newPlayer" | "level" | "done" | "manual" (see TRIGGER KINDS)
	n: number?, -- level, for "level"
	id: string?, -- tutorial id, for "done"
}

export type Tutorial = {
	id: string, -- unique, short ("t1", "t1b", "m1" ...): used in save data and analytics
	trigger: Trigger,
	intro: string?, -- Locale key: one line shown first (as the hint of step 0)
	steps: { Step }, -- 1-5 steps (T1 uses 5)
	reward: Reward?, -- paid once when the last step is done (never on replay)
	auto: boolean?, -- false = never starts by itself (only from Atur > Panduan); default true
	title: string, -- Locale key: name in the Panduan list
	studioOnly: boolean?, -- listed and run only in Studio (test tutorials)
}

-- CONDITION KINDS (checked on the client from the state snapshot and the world; all are ">=" n):
--   "always"                  true at once (an information step: shown until the player taps Lanjut or time passes)
--   "tiles"                   n or more tilled beds
--   "planted"                 n or more beds with a crop growing / ripe
--   "watered"                 n or more beds that are watered
--   "ripe"                    n or more ripe beds
--   "item"                    n or more of items whose id starts with `id` in the bag
--   "level"                   level >= n
--   "near"                    within `dist` studs of the NPC `id`
--   "panel"                   the screen/panel named `id` is open (ScreenGui Enabled)
--   "garap"                   Garap mode is open
--   "sells"                   n or more sale trips to the buyer (data.guide.sells, snapshot.guideSells)
--   "ack"                     the player pressed Next / Mulai in a dialog of the intro (id = step key); never by time
--   "pondmode"                Garap is open in its Kolam mode (the player opened the pond tool)
--   "ponds"                   n or more ponds of mine are built
--   "fish"                    n or more fish in the bag (any item written <fish>@<size>)
--   "sellfish"                the first fish was sold to Kak Fajar (snapshot.guide.fishSold, set by ShopService)
--   "quest"                   the quest named `id` is done (snapshot.quests.done)
--   "harvested"               the player has harvested at least once (snapshot.onboarding.first_harvest)
--   "any"                     one of `any` holds (v6.2.3 A1: a step is also done by the state a later step needs)
-- SEQUENCE (v6.2.3 A1): the tutorial is state-driven. When a step's condition holds, the step completes; when a LATER
-- step's condition holds, every step before it completes too (the server pays each one). "always" and "ack" never
-- complete a step early.
-- TRIGGER KINDS:
--   "newPlayer"   a save with no beds and nothing planted yet (starts at once on join)
--   "level"       level >= n
--   "done"        tutorial `id` is finished or skipped
--   "manual"      never auto-starts (replay only)

local TUTORIALS: { Tutorial } = {
	-- T1: the first loop. NO skip (v7.4 Bab 16.1); replayable from Atur > Panduan (no reward on replay).
	{
		id = "t1_awal",
		title = "tut.t1.title",
		trigger = { kind = "newPlayer" },
		auto = true,
		steps = {
			{
				-- Sapaan: a welcome modal (Mulai only, no skip). It completes only when the player taps Mulai (kind "ack").
				id = "sapa",
				text = "tut.t1.intro.1",
				done = { kind = "ack", id = "sapa" },
				modal = { title = "tut.t1.sapa_title", body = "tut.t1.sapa_body" },
			},
			{
				id = "cangkul",
				text = "tut.t1.s1",
				coach = "tut.coach.garap",
				done = { kind = "any", any = { { kind = "tiles", n = 1 }, { kind = "planted", n = 1 }, { kind = "harvested" } } },
				highlight = "GarapButton",
				spotlight = true, -- rule 1a (GUI 4.6): first time, fixed HUD button -> one hole. The only spotlight besides mancing
				reward = { xp = 1 },
			},
			{
				id = "tanam",
				text = "tut.t1.s2",
				coach = "tut.coach.tanam",
				textStuck = "tut.t1.s2_stuck",
				done = { kind = "planted", n = 1 }, -- only planting completes it (a harvest must not skip the step)
				highlight = "TanamButton",
				reward = { xp = 1 },
			},
			{
				id = "siram",
				text = "tut.t1.s3",
				coach = "tut.coach.siram", -- optional (v6.2.3 A1): watering OR a harvest completes it; Gerimis waters too
				done = { kind = "watered", n = 1 }, -- only watering completes it: Mak Sari says "siram", the player must do it
				highlight = "SiramButton",
				reward = { xp = 1 },
			},
			{
				-- B1 (K-54): after the first harvest, the player plants the free seeds again on new plots.
				id = "panen_1",
				text = "tut.t1.s4_harvest",
				done = { kind = "harvests", n = 1 },
				highlight = "PanenButton",
			},
			{
				id = "garap_5",
				repeatStep = true, -- rule 2 (GUI 4.6): repeat = toast only, no bubble, no ring, no spotlight
				text = "tut.t1.s5_garap",
				coach = "tut.coach.garap",
				done = { kind = "tiles", n = 6 }, -- 1 old plot + 5 new ones
				highlight = "GarapButton",
			},
			{
				id = "tanam_5",
				repeatStep = true, -- rule 2 (GUI 4.6): repeat = toast only, no bubble, no ring, no spotlight
				text = "tut.t1.s5_tanam",
				coach = "tut.coach.tanam",
				done = { kind = "planted", n = 5 }, -- the 5 free seeds still in the bag
				highlight = "TanamButton",
			},
			{
				-- All six free seeds harvested (the first harvest counts): never fewer.
				id = "tunggu_semua",
				repeatStep = true, -- rule 2 (GUI 4.6): repeat = toast only, no bubble, no ring, no spotlight
				text = "tut.t1.s5_tunggu",
				done = { kind = "harvests", n = 6 },
				highlight = "PanenButton",
			},
			{
				id = "panen_jual",
				repeatStep = true, -- rule 2 (GUI 4.6): repeat = toast only, no bubble, no ring, no spotlight
				text = "tut.t1.s4",
				coach = "tut.coach.panen",
				greet = "tut.t1.jual.1", -- Pak Udin's sapaan at the first sale (naskah 1.3)
				done = { kind = "sells", n = 1 },
				target = { npc = "pak_udin" },
				highlight = "PanenButton",
				reward = { xp = 20 }, -- v7.4 tabel 16.2: the Jual step pays the 20 XP (it used to be paid by t1b "warung")
			},
		},
		reward = { koin = 30 },
	},

	-- T1b: right after the first sale to Pak Udin (T1Ghost.client starts it): the warung, the rod gift and the first fish.
	-- The pond is NOT part of it (v7.4 Bab 16.5: the first pond only comes from MQ4 / Bundel Kakek Lv 3). Not auto-started (manual trigger), so a save that finished T1 long ago never gets it. Progress is saved
	-- like any tutorial, so a rejoin resumes it. The dialogs are Mak Sari's / Pak Udin's / Kak Fajar's (T1Dialog); the
	-- coachmark only highlights. NO skip (v7.4 Bab 16.1): the first fish is the point of this tutorial.
	{
		id = "t1b_kolam",
		title = "tut.t1b.title",
		trigger = { kind = "manual" },
		auto = false,
		steps = {
			{
				-- Pak Udin, at the warung: seeds and upgrades are sold here. Next to continue (kind "ack").
				-- Pays 20 XP once (Lv 2). Pak Udin only sends the player to Kak Fajar: no pond talk here (pond = Mak Sari later).
				id = "warung",
				text = "tut.t1b.warung",
				done = { kind = "ack", id = "warung" },
				-- No reward: the 20 XP moved to the T1 "panen_jual" step (v7.4 tabel 16.2). Total FTUE XP is unchanged.
			},
			{
				-- The fishing shop: Kak Fajar (Toko Pancing). Done only when Terima Hadiah was taken (rodGift), never by walking near.
				id = "kak_fajar",
				text = "tut.t1b.kak_fajar",
				done = { kind = "rodgift" },
				target = { npc = "kak_fajar" },
				arrive = 14,
			},
			{
				-- One fish at the river dock (the gift gave the Joran Bambu, so the rod is owned).
				id = "mancing",
				text = "tut.t1b.mancing",
				coach = "tut.coach.mancing", -- A3: the Mancing button (AksiButton) is ringed; cast, then pull, then the first fish
				highlight = "AksiButton",
				spotlight = true, -- rule 1a: first catch only (GuideController drops it after the first fish); fixed HUD button
				done = { kind = "fish", n = 3 }, -- B2 (K-54): three catches. The first two show only "Coba lagi" (GuideController), no dialogue
				target = { spot = "sungai_lahan" }, -- the arrow to the nearest river spot (sungai lahan, Lv 1; Task 1 moves it to the plot's own spot)
				arrive = 6,
				reward = { xp = 20 }, -- the same 20 XP as the warung step (paid once on the first fish)
			},
			{
				-- Playtest 2026-11-22: the first fish is SOLD to Kak Fajar (walk up = Jual cutscene, like Pak Udin). The step is
				-- finished by the "Ok, Kak Fajar" button after the sale (T1Ghost beat ackStep), so T1b and its "Selesai" banner
				-- come after that button. It opens NOTHING: the pond is gated by pond.kakekUnlocked (MQ4 / Bundel) alone.
				id = "jual_ikan",
				text = "tut.t1b.jual_ikan",
				done = { kind = "ack", id = "jual_ikan" },
				target = { npc = "kak_fajar" },
				arrive = 14,
				-- B2 (K-54): XP is topped up to exactly the Lv 2 threshold, so the tutorial ends at Lv 2 whatever the catches gave.
				reward = { xpFill = true },
			},
		},
	},
}

-- Studio-only smoke test of the engine (!tut in chat is not needed: it starts by itself on a fresh save in Studio).
local TEST_TUTORIAL: Tutorial = {
	id = "dev_test",
	title = "tut.dev_test.title",
	studioOnly = true,
	auto = false, -- set true to watch the engine start by itself on a fresh Studio save (then "!reset"); replay it from Atur > Panduan
	trigger = { kind = "newPlayer" },
	intro = "tut.dev_test.intro",
	steps = {
		{
			id = "garap",
			text = "tut.dev_test.s1",
			done = { kind = "garap" },
			highlight = "GarapButton",
		},
		{
			id = "tiles",
			text = "tut.dev_test.s2",
			textStuck = "tut.dev_test.s2_stuck",
			done = { kind = "tiles", n = 2 },
			highlight = "GarapButton", -- any named button of an open screen works
			reward = { xp = 1 },
		},
		{
			id = "npc",
			text = "tut.dev_test.s3",
			done = { kind = "near", id = "pak_udin", dist = 25 },
			target = { npc = "pak_udin" },
		},
	},
	reward = { koin = 5 },
}

return {
	TRIES = 1, -- the old sale-trip guide stops after the first sale, the same sale that finishes T1 (sells n = 1)
	BUYER_NPC = "pak_udin", -- the arrow points here once there is a crop to sell
	TUTORIALS = TUTORIALS,
	TEST_TUTORIAL = TEST_TUTORIAL,
	GAP_SECONDS = 120, -- pause between two auto-started tutorials
	STUCK_STRONG = 45, -- s without progress: brighter, bigger highlight
	STUCK_TEXT = 90, -- s without progress: the more explicit text
	REPLAY_MIN_SECONDS = 4, -- replay: each step stays at least this long
	FAST_PLANTINGS = 6, -- first plantings of a new save on the fast timer
	FAST_GROW_SECONDS = 20, -- (water -> -15 % of the rest; the first crop is 20 s on the fast timer)
	-- Playtest 2026-11-22: NO tutorial rain. A rain waters every crop, so the Siram step was done by the sky and the
	-- player never watered. Siram in T1 is the player's own action (Siram button / drag), nothing else completes it.
	-- FTUE Bab 16.3 (0:50): the first harvest of a new save is always Bagus (no chance roll; Update owner 2026-11-22). Once per save (guide.done.ftue_super).
	FTUE_FIRST_BAGUS = true,
	-- Mutasi DIHAPUS (Bab 29): panen pertama dijamin Bagus, Kualitas normal.
	-- Pemicu adegan jual NPC tutorial (Update owner playtest, item 2): jarak di mana adegan jual (Pak Udin, Kak Fajar) mulai.
	-- HARUS lebih kecil dari batas jual server (Shop.NPC_DISTANCE = 25 studs). Adegan juga menaruh pemain di titik berdiri.
	SALE_BEAT_RADIUS = 10,
	CUTSCENE_MAX_SECONDS = 6, -- Bab 16.2: every FTUE cutscene is at most 6 s (Cutscene logs it, no UI)
}
