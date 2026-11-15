--!strict
-- New-player guide.
--
-- 1) OLD GUIDE (client/Controllers/GuideController, "legacy" part): on-screen hints for the first loop (cangkul -> tanam ->
--    siram -> panen -> jual) and an arrow to the buyer (Pak Darmo). It runs until the player has finished TRIES sale trips
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
	target: { npc: string? , pos: Vector3? }?, -- the ground arrow points here until the player is within `arrive` studs
	arrive: number?, -- studs (default 25)
	reward: Reward?, -- paid once when the step completes (never on replay)
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
	steps: { Step }, -- 1-4 steps
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
-- TRIGGER KINDS:
--   "newPlayer"   a save with no beds and nothing planted yet (starts at once on join)
--   "level"       level >= n
--   "done"        tutorial `id` is finished or skipped
--   "manual"      never auto-starts (replay only)

local TUTORIALS: { Tutorial } = {
	-- (empty on purpose: T1 and the rest come in phase P2+)
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
			done = { kind = "near", id = "pak_darmo", dist = 25 },
			target = { npc = "pak_darmo" },
		},
	},
	reward = { koin = 5 },
}

return {
	TRIES = 3,
	BUYER_NPC = "pak_darmo", -- the arrow points here once there is a crop to sell
	TUTORIALS = TUTORIALS,
	TEST_TUTORIAL = TEST_TUTORIAL,
	GAP_SECONDS = 120, -- pause between two auto-started tutorials
	STUCK_STRONG = 45, -- s without progress: brighter, bigger highlight
	STUCK_TEXT = 90, -- s without progress: the more explicit text
	REPLAY_MIN_SECONDS = 4, -- replay: each step stays at least this long
	FAST_PLANTINGS = 6, -- first plantings of a new save on the fast timer
	FAST_GROW_SECONDS = 20, -- (water -> -20 % = 16 s, like every crop)
}
