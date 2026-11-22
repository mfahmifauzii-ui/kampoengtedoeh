# KAMPOENG TEDOEH — Test Plan for Claude Code (v0.1)

Purpose: verify everything built since the last playtest (Q-2 to Q-4, UI-1, UI-3, the 10-bug batch, ST-1 to ST-3, NPC-intro fix, F-1 to F-3, B-1 to B-3, B-5 fishing animations) **without Studio**, and produce a checklist for the owner for the parts that need Studio.

Claude Code cannot run a Roblox playtest. This plan therefore has three layers: (A) automated gates, (B) static audits and logic checks, (C) a manual Studio checklist that Claude Code only prepares, never marks as passed.

## 0. Rules

- This is a test task. **Do not change game behavior.** Only add test files and the report. If a check fails, log it, do not silently fix it (exception: trivial typos in docs).
- Every finding goes to the report with: ID, what was checked, expected, actual, file:line, severity (blocker / major / minor).
- Real bugs go to `docs/Roadmap.md` §12 as new rows. Unclear doc gaps go to Lampiran D. Don't invent numbers.
- Single source of truth: gameplay numbers = `docs/Kampoeng_Tedoeh_v7.7.md`; skills = `docs/Skill_Tree_Kampoeng_Tedoeh_v7.7.md`; UI = `docs/GUI_Kampoeng_Tedoeh_v0.1.md`; quests/dialog = `docs/Quest_Kampoeng_Tedoeh_v0.3.md` and `docs/Naskah_Dialog_Kampoeng_Tedoeh_v0.1.md`. v7.6 and older are archive, never use them as expected values.
- Deliverables: `docs/Test_Report_<date>.md` plus any spec files under `tests/`. One commit, message `test: full regression pass <date>`.

## A. Automated gates

| ID | Check | Pass condition |
|----|-------|----------------|
| A-1 | `selene src` | Only the 4 pre-existing errors, nothing new. List them by file. |
| A-2 | `rojo build -o /tmp/test.rbxlx` (or the project's build command) | Exit 0. |
| A-3 | Luau type/analyze pass if `luau-analyze` or `luau-lsp` is available | No new errors vs. previous commit. If the tool is missing, mark "not available", don't install heavy tooling. |
| A-4 | `git log` since the last tested tag/commit | Every commit in scope has a Roadmap row; list commits without one. |

## B. Static audits (grep / read the code)

### B-UI (HUD and GUI)
| ID | Check | Expected |
|----|-------|----------|
| B-UI-1 | Raw `DisplayOrder` / `ZIndex` numbers outside `UiKit.LAYER` | 0 occurrences. |
| B-UI-2 | Hidden layers: frames/labels created with `Visible = false` or `Transparency = 1` that are never shown, or shown while empty | None. Every part/slot exists only while its content is active. |
| B-UI-3 | Toasts: search for any toast/notification frame created outside the single `UiKit` toast component | Exactly one implementation, all features call it. Check anchor (0.5, 0), X = 0.5 scale, AutomaticSize Y, min height, max width, stacking max 3. |
| B-UI-4 | HUD layout map (`UiKit.HUD`): every HUD element uses a named anchor; context strip has the documented gap above the bottom dock | No hard-coded positions for tracker, toast, strip, chip. |
| B-UI-5 | Empty frames: any frame in the HUD that can be visible with no text/content (e.g. the fishing status strip) | None. |
| B-UI-6 | Tas (inventory) tabs: Semua, Bibit, Panen, Ikan, Umpan, Alat. Bait only in Umpan and Semua. Tab row fits or scrolls | Matches. |
| B-UI-7 | Skill tree panel: 6 branches (Bertani, Mancing, Ternak, Tukang, Masak, Sosial), node states (locked, buyable, noSP, noKoin, maxed), drawer, "Efek mulai Lv 3" for breakpoint skills, node name labels | Matches Skill Tree doc Bab 3. |
| B-UI-8 | Hadiah UI-3b status, Acara/Skill icon placeholders | Report current state, no judgment. |

### B-SRV (server authority)
| ID | Check | Expected |
|----|-------|----------|
| B-SRV-1 | Every `RemoteEvent`/`RemoteFunction` handler validates player, args types, ranges, and ownership server-side | List handlers that trust client values. |
| B-SRV-2 | `SkillService.buy`: checks max, prerequisites, SP, Koin before deducting; returns `ok/max/locked/noSP/noKoin`; cost 3.000 Koin + 1 SP per level; atomic (no partial deduction) | Matches. |
| B-SRV-3 | Fishing: bite delay computed on server; reel result validated (time and range); bait consumed server-side; bait count returned to client | Matches. |
| B-SRV-4 | No client-side grants of Koin/Bunga/XP/items | None. |
| B-SRV-5 | `metNpcs` (or equivalent) is persisted, has a default for old saves, and is set from any dialogue source | Matches. |
| B-SRV-6 | FeatureGate: server and client use the same feature ids; Skill panel gated at Player Lv 2 | Matches. |

### B-DOC (doc ↔ code number sync)
Build a table, expected (doc, with section) vs actual (code, file:line). Mark mismatches.

| ID | Item | Doc source |
|----|------|------------|
| B-DOC-1 | Bite wait: 3-6 s with bait, 6-12 s without bait; rain ×2 (6-12 / 12-24); Jangkrik 30% faster; Buff Pancing 20% faster | v7.7 Bab 3.3, 6.2, 6.3 |
| B-DOC-2 | Reel: window 1.5 s to start pulling, FILL_GAIN 0.28, FILL_DRAIN 0.06, start progress 30%, 0% = fish escapes and bait lost | v7.7 Bab 6.2 |
| B-DOC-3 | Skills: 16 skills × 5 levels, SP per level 1, cost 3.000 Koin per level, prerequisites per skill, OR groups for Panen Raya and Ikan Besar, Tetangga Baik (sum of levels ≥ 5, Player Lv 10) | Skill Tree Bab 1, 2 |
| B-DOC-4 | Breakpoint skills no effect at Lv 1-2: Tempat Pakan Besar, Tukang Cepat, Tetangga Baik (Lv 3 and Lv 5 effects) | Skill Tree Bab 1.1 |
| B-DOC-5 | Mining: best axe only, Kapak + Tukang Cepat stack, max +4 per node, buff Tukang/Tebang +1 only on Critical, Kapak Bunga +1 alternative to Besi | Skill Tree Bab 6 |
| B-DOC-6 | Rod `unlockLevel` and tool tables use Player Lv | v7.7 Bab 6.3, 17.5 |
| B-DOC-7 | XP/level curve and level-up unlock list used by the "Level N! Terbuka: ..." toast | v7.7 level chapters |
| B-DOC-8 | Prices: bait (Cacing 10 / Jangkrik 25 / Pelet 45 / Udang Kecil 80), shop buy and sell values | v7.7 Bab 17 |
| B-DOC-9 | Economy sink and faucet constants referenced in Bab 17.4 / 17.8 | v7.7 Bab 17 |
| B-DOC-10 | FTUE steps and rewards (Kak Fajar gives Joran Bambu, first fish Wader Cakul, XP amounts) | v7.7 Bab 16.5 |

### B-STORY (quests and NPCs)
| ID | Check | Expected |
|----|-------|----------|
| B-STORY-1 | NPC introductions: grep every dialogue line that introduces an NPC ("Saya X", "Perkenalkan", name + role) | Each NPC has one intro variant used only when never met; all other variants have no introduction. |
| B-STORY-2 | Quest chain order from the Quest doc: every step reachable, no dead-end, no step that requires an item or feature unlocked later | Walk the chain on paper and list the unlock for each step. |
| B-STORY-3 | Pak Udin story continues after the first dialogue (no re-introduction, next step triggers) | Matches. |
| B-STORY-4 | Bang Jali selling dialogue does not open the shop before selling is unlocked | Matches. |
| B-STORY-5 | Kerja Bakti quest text is clear: names where to go and how many | Matches Quest doc. |
| B-STORY-6 | Banner "Dimulai/Selesai" hides other GUI while shown and restores it | Matches. |

## C. Logic checks (headless, only if a Luau runner exists)

Check for `lune`, `luau`, TestEZ or Jest in the repo or toolchain (`aftman.toml`, `wally.toml`, `foreman.toml`). If one exists, write pure-logic specs under `tests/` for **shared Config modules only** (no Instances, no game services). If none exists, do not add a framework: write the cases into the report as "unverified, needs runner".

Cases:
1. Skills prerequisite helper: every skill at Lv 0 with insufficient Player Lv returns locked; OR group passes with either parent at Lv 3; Tetangga Baik fails at total 4 and passes at 5 (with Player Lv 10).
2. Skill cost: buying levels 1-5 of one skill costs 5 SP and 15.000 Koin total; all 16 skills cost 80 SP and 240.000 Koin.
3. SP budget: SP = level - 1; at Lv 60 max 59 SP, 177.000 Koin.
4. Breakpoint effect helper: Lv 1-2 → no effect; Lv 3 and Lv 5 → documented values (Tempat Pakan Besar, Tukang Cepat, Tetangga Baik).
5. Mining bonus: best axe only; Besi +1, Baja +2 plus Tukang Cepat Lv 3 (+1) and Lv 5 (+2); clamp max +4; base node 4 → max 8.
6. Bite delay function (if pure): with bait in [3, 6], without in [6, 12], rain doubles both; sample 1000 times each and assert the range.
7. Level curve: XP required is strictly increasing, level-up unlock list has no gaps.

## D. Manual Studio checklist (prepared, not executed, by Claude Code)

Claude Code writes this section into the report as an empty checklist the owner fills (`[ ]` Pass / Fail / notes). Test with **a fresh account and an existing account**, and at device sizes: 1920×1080, 844×390, 667×375, 390×844.

1. **FTUE and NPCs:** fresh account meets Pak Udin, Kak Fajar, Bang Jali once each with intro; no NPC re-introduces; story continues after each dialogue; Joran Bambu + Pelet gift is received; existing account never sees an intro for an NPC it already met.
2. **Dialogue UI:** long text stays inside the bubble; `!` marker does not cover the overhead GUI; Next works at the last line.
3. **Quests:** Kerja Bakti text is clear; banner Dimulai/Selesai hides other GUI and restores it; tracker text wraps, no clipping at screen edge.
4. **Shop:** Bang Jali shop does not open before unlock; Toko GUI renders correctly; buy/sell changes Koin correctly.
5. **Tas:** all tabs; Umpan tab holds only bait; no clipped tab labels.
6. **Fishing:** with bait, bite in about 3-6 s; without bait about 6-12 s; bait chip shows name and count, count drops by 1 per cast, "Umpan habis" at 0; status strip always has text; Cancel button is readable; walking away from the spot cancels and returns the bait; rain makes bites about 2× longer; animations (cast, reel) play.
7. **Farming:** plant and water animations play (ids FarmPlant 72416432910267, FarmWater 106687765397165); tanaman grows on time.
8. **Toasts:** level-up, collection, fish-caught toasts are horizontally centered, below the currency bar, readable height, stack max 3, never overlap tracker or right buttons; narrow portrait drops below the tracker.
9. **Hadiah:** button number not clipped; Hadiah screen state (note UI-3b status).
10. **Skill:** button locked before Lv 2; tree shows 6 branches with node names; locked node shows its requirement; buying deducts 1 SP + 3.000 Koin; each failure reason shows the right message; Panen Raya unlocks with either parent at Lv 3; Tetangga Baik needs total levels ≥ 5 and Player Lv 10; "Efek mulai Lv 3" for breakpoint skills; Tempat Pakan Besar changes nothing at Lv 1-2.
11. **Mining:** best axe only; Tukang Cepat adds to it; a node never gives more than 8 bahan.
12. **Economy sanity:** play 30 minutes with a normal route and note Koin earned and spent; compare with the Bab 17 faucet and sink figures (target ratio 65-80%).
13. **Persistence:** leave and rejoin; Koin, SP, skills, bait, metNpcs, quest progress all persist.
14. **Performance:** no console errors or warnings in Output during the full run; paste any.

## E. Report format (`docs/Test_Report_<date>.md`)

1. Summary table: layer (A, B, C, D) × pass / fail / not available / pending owner.
2. Findings list sorted by severity, each with ID, file:line, expected vs actual, suggested fix (one line).
3. Doc ↔ code mismatch table (B-DOC).
4. The blank manual checklist (section D) for the owner.
5. New Roadmap §12 rows and new Lampiran D items created by this pass.
6. What could not be tested and why.

Final report to the owner in chat: commit hash, counts per severity, the top 5 findings, and the line "Studio checklist is in the report, section D".
