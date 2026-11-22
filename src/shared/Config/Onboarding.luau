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
	block: boolean?, -- coachmark overlay blocks every other tap (default true); false = ring + bubble only
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
		intro = "tut.t1.intro",
		trigger = { kind = "newPlayer" },
		auto = true,
		steps = {
			{
				-- Sapaan: a welcome modal (Mulai only, no skip). It completes only when the player taps Mulai (kind "ack").
				id = "sapa",
				text = "tut.t1.intro",
				done = { kind = "ack", id = "sapa" },
				modal = { title = "tut.t1.sapa_title", body = "tut.t1.sapa_body" },
			},
			{
				id = "cangkul",
				text = "tut.t1.s1",
				coach = "tut.coach.garap",
				done = { kind = "any", any = { { kind = "tiles", n = 1 }, { kind = "planted", n = 1 }, { kind = "harvested" } } },
				highlight = "GarapButton",
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
				id = "panen_jual",
				text = "tut.t1.s4",
				coach = "tut.coach.panen",
				block = false, -- after Panen the player must reach Pak Udin (outside the hole): no overlay here
				greet = "tut.t1.s4_greet", -- Pak Udin's sapaan at the first sale (the cutscene, T1Ghost runWarung)
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
				done = { kind = "fish" },
				target = { spot = "sungai" }, -- the arrow to the dock (nearest fishing spot of that Location)
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
				-- XP top-up so the tutorial ends just under Lv 2 (230 XP, Config/Progression xpToNext(1)). Tutorial XP before
				-- this step: 1+1+1 (cangkul/tanam/siram) + 20 (panen_jual) + 20 (mancing) = 43. Free seeds: 6 x kangkung (12 XP
				-- each) = 72. 230 - 72 - 43 = 115. After the tutorial the player is at 158 + the 1st harvest (12) = 170, and
				-- harvesting the 5 seeds left (5 x 12 = 60) reaches 230 -> Lv 2 -> the Kolam quest (Config/Quests kolam_pertama).
				reward = { xp = 115 },
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
	CUTSCENE_MAX_SECONDS = 6, -- Bab 16.2: every FTUE cutscene is at most 6 s (Cutscene logs it, no UI)
}
