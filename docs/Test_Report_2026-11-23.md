# Test Report — Kampoeng Tedoeh — full regression pass 2026-11-23

Plan: `docs/Test_Plan_Kampoeng_Tedoeh_v0.1.md` (v0.1)
Branch: `feat/v.7`
Baseline (last playtest log): `68da23a` "docs: Roadmap (status Q/B, §12 bug playtest 2026-11-22)". No git tags exist in the repo, so the range `68da23a..HEAD` (54 commits) is the scope.
Tooling present: `selene` 0.32.0, `rojo` 7.7.1, `stylua` (Aftman, `~/.aftman/bin`). Absent: `luau-analyze`, `luau-lsp`, `lune`, `luau`, TestEZ/Jest (`wally.toml` does not exist).

> Layers A–C were executed by Claude Code. Nothing here was run in Roblox Studio. Only layer D is for the owner. No game code was changed in this pass.

---

## 1. Summary

| Layer | Pass | Fail | Partial / not verified | Not available | Pending owner |
|-------|------|------|------------------------|---------------|---------------|
| A — Automated gates | 2 (A-1, A-2) | 0 | 1 (A-4) | 1 (A-3) | — |
| B — Static audits (UI) | 3 (B-UI-1, B-UI-4, B-UI-7) | 2 (B-UI-3 minor, B-UI-6 spec gap) | 2 (B-UI-2, B-UI-5) | — | B-UI-8 report only |
| B — Static audits (SRV) | 3 (B-SRV-2, B-SRV-5, B-SRV-6) | 0 | 3 (B-SRV-1, B-SRV-3, B-SRV-4) | — | — |
| B — Doc ↔ code (B-DOC) | 5 (1, 3, 4, 6, 8 partial) | 4 (2, 5, 7 unlock, 10) | 1 (9) | — | Doc decisions in Lampiran D |
| B — Quests & NPC (B-STORY) | 3 (1, 4, 6) | 0 | 3 (2, 3, 5) | — | — |
| C — Logic checks | 0 | 0 | 7 cases checked by hand, not executed | 7 (no runner) | — |
| D — Studio checklist | blank, see §5 | | | | Owner, 14 items × 4 device sizes × 2 account types |

### Severity counts (findings, §2)

| Severity | Count |
|----------|-------|
| Blocker | 0 |
| Major | 3 |
| Minor | 10 |

**Result in one line:** the build compiles and lints with no new errors; the static audit found no blocker. The main problems are documentation that disagrees with the code and a misplaced block of Lampiran D decisions.

---

## 2. Findings (sorted by severity)

Format: ID · what was checked · expected · actual · file:line · severity · suggested fix. Doc gaps are in Lampiran D (`docs/Kampoeng_Tedoeh_v7.7.md`, items #50–#60). Code bugs are in Roadmap §12 (rows T-1 to T-4).

### Major

**M-1 · Lampiran D integrity (B-DOC, structure)** — Lampiran D items #36–#49 are inside Bab 4.4 *Unlock* (`docs/Kampoeng_Tedoeh_v7.7.md`, about lines 281–295), not in the Lampiran D section (line 1393, which holds #1–#35). A stray Unlock row `| 45 | Durian |` (line 291) has the same number as Lampiran D #45 (line 290).
Expected: one Lampiran D table, unique numbers. Actual: 14 decision rows in the wrong place, one number collision.
Fix: move #36–#49 into Lampiran D, renumber the Durian row out of the decision list. → Lampiran D #50.

**M-2 · Kapak Bunga documented, not implemented (B-DOC-5)** — Skill Tree Bab 6 decision 2 and Bab 18.3 say Kapak Bunga is +1 bahan per node, an alternative to Kapak Besi. `kapak_bunga` does not exist in code.
Expected: `kapak_bunga` in `Farm.TOOLS` with `bonusBahan = 1`. Actual: absent (`src/shared/Config/Farm.luau:42-52` lists only gembor, sabit, sepatu, kapak_batu, kapak_besi, kapak_baja).
Fix: owner decides — implement (needs a Bunga price and a Bunga cost path) or remove from the docs. → Lampiran D #51.

**M-3 · Gameplay rules in Bab 6.1 are stale (B-DOC-2)** — two player-facing rules contradict the code:
- (a) Bab 6.1 says the reel window is 1.5 s after the bite. Code has no window (REEL_WINDOW removed 16 Nov, comment at `src/shared/Config/Fishing.luau:56`). Code uses REEL_MIN_SECONDS 2.5 (`Fishing.luau:55`, server check at `src/server/Services/FishService.luau:696`), which the doc does not mention.
- (b) Bab 6.1 says walking more than 8 studs from the spot cancels the cast. Code uses `LEAVE_DISTANCE = 24` (`Fishing.luau:59`, `FishService.luau:389`). Lampiran D #26 already records 24 as a proposal awaiting owner approval, but Bab 6.1 still says 8.
Fix: owner approves #26; update Bab 6.1 for both rules. → Lampiran D #52, #53.

### Minor

**m-1 · Second toast implementation (B-UI-3)** — `UiKit.rewardPopup` (`src/client/UiKit.luau:2229-2250`) builds its own ScreenGui `RewardPopups` and its own chip. Nothing in `src/` calls it. Expected by B-2 / UI-B14: one toast component. Fix: delete it, or route it through `toastStack`. → Roadmap §12 **T-1**.

**m-2 · FTUE XP for "Siram / Panen" (B-DOC-10)** — Bab 16.2 row "1:30 Siram / Panen (opsional) — 20 XP". Code: step `siram` pays `reward = { xp = 1 }` (`src/shared/Config/Onboarding.luau:127`). Fix: owner picks 20 or 1, then the tutorial total (Lampiran D #11) is rechecked. → Lampiran D #54.

**m-3 · Unlock table drift and stale references (B-DOC-7)** — Bab 4.4 lists Lele (Lv 2), Mujair, Nila and Kanal Barat (Lv 5). `src/shared/Config/Unlock.luau` does not list them. Header of `Unlock.luau:2` and `src/shared/Config/Progression.luau:2` cite `docs/Kampoeng_Tedoeh_Gameplay_Lengkap_v6.2.md`, which is not in `docs/`. XP curve itself matches (`200 + 30n`, `Progression.luau:20-22` = Bab 4.2 line 252). → Lampiran D #55; Roadmap **T-3** (stale comments).

**m-4 · Missing `typeof` check in a remote handler (B-SRV-1)** — `OrderService.luau:202` `onReroll(player, uid: any)` compares `order.uid == uid` with no type check. Not a crash, but `src/shared/Modules/Net.luau` says every handler MUST validate its arguments. Fix: `if typeof(uid) ~= "number" then return end` at the top. → Roadmap **T-2**.

**m-5 · Rod tuning not documented (B-DOC-1 area)** — `Fishing.luau` rodList has `biteMult`, `rareBonus`, `legendaryBonus`. Bab 6.3 table lists only price, box and requirement. The bite formula in Bab 6.1 is matched by code (`FishService.luau:449-466`), so the gap is the per-rod table only. → Lampiran D #56.

**m-6 · Tas tab order not specified (B-UI-6)** — Code order (`src/client/Controllers/InventoryController.luau:22-27`): Semua, Bibit, Panen, Ikan, **Alat, Umpan**. Test plan expects Umpan before Alat. GUI doc does not specify the order. Bait filter itself is correct (`categoryOf`, lines 33-38). → Lampiran D #59.

**m-7 · ZIndex rule scope (B-UI-1)** — `DisplayOrder` is all via `UiKit.LAYER` (pass). Raw `ZIndex` numbers are used all over (HudController, FarmController, FishingController, UiKit), as inner stacking. The rule "no raw DisplayOrder / ZIndex" is ambiguous. → Lampiran D #58.

**m-8 · Kerja Bakti "where" text (B-STORY-5)** — Quest step text is `Ikut 10 Kerja Bakti` (`src/shared/Config/Quests.luau:351`). The "where" hint exists in the Quest Log (`kb.active`, "Pungut sampah di plaza", `Locale/id.luau:1001`). Whether the Quest Log text is clear enough needs a look in Studio. → Roadmap **T-4** (Studio check).

**m-9 · Test plan expectation wrong for Skill button (D10)** — Plan says the Skill button is "locked" before Lv 2. Code hides it (D-39, `SkillController.luau:431-432`, consistent with Lampiran D #3). Fix: change the wording in the test plan. → Lampiran D #60.

**m-10 · Stale Lampiran D heading** — `docs/Kampoeng_Tedoeh_v7.7.md:1393` says "(v7.5, BELUM DIPUTUSKAN)" in v7.7. → Lampiran D #57.

---

## 3. Layer A — Automated gates

| ID | Check | Result | Evidence |
|----|-------|--------|----------|
| A-1 | `selene src` | **PASS** | 4 errors, 0 parse errors, 91 warnings. The 4 errors: `src/client/FarmFloat.luau:195` (mismatched_arg_count), `:197` (same), `src/server/Services/SettingsService.luau:27` (if_same_then_else), `src/server/Services/MapService.luau:1093` (if_same_then_else). Count equals the pre-existing count stated in Roadmap §12. The repo has no saved baseline list, so "no new errors" is confirmed by count and by these four files only. Warnings are not gated by the plan. |
| A-2 | `rojo build` | **PASS** | `rojo build default.project.json` → exit 0, output written to `%TEMP%`, not to the repo. |
| A-3 | Luau analyze | **NOT AVAILABLE** | `luau-analyze` and `luau-lsp` are not on PATH. Not installed (plan says do not install heavy tooling). |
| A-4 | Commits in scope have a Roadmap row | **PARTIAL** | 54 commits in `68da23a..HEAD`. Feature commits were checked by ID against `docs/Roadmap.md`: Q-1…Q-5 (Q-1 and Q-2 present), UI-1, UI-3, UI-B1…B15 (the "UI bug N" commits), ST-1…ST-3, F-1…F-3, B-1…B-5, D-38…D-40 all have rows. Docs-only commits (e.g. `e08ca87`, `16af09a`, `6c80efe`) do not need rows. Not checked one by one: the 15 B-5 / Roadmap-doc commits. |

---

## 4. Layer B — Static audits

### B-UI (HUD and GUI)

| ID | Check | Result | Evidence |
|----|-------|--------|----------|
| B-UI-1 | Raw DisplayOrder / ZIndex outside `UiKit.LAYER` | **PASS** for DisplayOrder (0 raw numbers; every `DisplayOrder =` uses `UiKit.LAYER.*`). ZIndex scope ambiguous → m-7. | grep `DisplayOrder\s*=` in `src/client` |
| B-UI-2 | Hidden layers never shown or shown while empty | **NOT VERIFIED** (needs Studio) | ~300 `Visible = false` / `Transparency = 1` occurrences; cannot be decided by grep. Covered by D-section item 3 and 8. |
| B-UI-3 | One toast implementation; anchor (0.5, 0); AutomaticSize Y; min height; max width; max 3 stacked | **FAIL (minor, m-1)** | Single chain: `HudController.Toast` (`HudController.luau:433`) → `UiKit.toastStack` / `toastChip` (`UiKit.luau:1525`, `1577`). Constants: `TOAST_MAX_VISIBLE = 3` (`UiKit.luau:1496`), `TOAST_MIN_H = 40`, `TOAST_WIDTH_SHARE = 0.5`, anchor `UDim2.new(0.5, 0, 0, top)` (in `toastStack`, `UiKit.luau:1525-1575`), `AutomaticSize.Y` (`UiKit.luau:1531`). Second implementation: `UiKit.rewardPopup` (`UiKit.luau:2229`). |
| B-UI-4 | HUD uses named anchors; strip above dock with documented gap | **PASS** (static) | `UiKit.HUD` table (`UiKit.luau:1471-1483`); `UiKit.hudStripBottomGap` (`:1487`) = DOCK_BOTTOM + 2×DOCK_H (one dock button of gap, as the comment says). Minor: `FarmController.luau:516` and `:1152` use a hard-coded y = 124 instead of `UiKit.HUD.TRACKER_TOP` (118); not a tracker/toast/strip/chip, so not counted. |
| B-UI-5 | No empty visible frame (fishing status strip) | **NOT VERIFIED** (needs Studio) | `FishingController.luau:102` `statusFrame.Visible = false` at build; label text is set by state (`:615`, `:624`). Did not trace every path that shows the strip. Covered by D-6. |
| B-UI-6 | Tas tabs Semua/Bibit/Panen/Ikan/Umpan/Alat; bait only in Umpan and Semua | **PARTIAL** | Bait filter correct (`InventoryController.luau:33-38`). Order differs from plan → m-6. |
| B-UI-7 | Skill tree: 6 branches, node states, drawer, "Efek mulai Lv 3", node labels | **PASS** (static) | Branches `CABANG_ORDER` (`Skills.luau`, six entries); node states "maxed / locked / noSP / noKoin / buyable" (`SkillController.luau:100`); breakpoint text `skill.effect_from = "Efek mulai Lv {n}"` (`Locale/id.luau:732`). Node name labels are D-40, which is still open (Roadmap §15), so the plan's expectation for node labels is not met yet. |
| B-UI-8 | Hadiah UI-3b status, Acara/Skill icon placeholders | **REPORT** | UI-3 (tabs Harian / Musim / Koleksi) landed in `9b5239a`. No row named "UI-3b" exists in `docs/Roadmap.md` or in code. Acara/Skill placeholder icons: D-39 commit `27edbdd` adds placeholders. |

### B-SRV (server authority)

| ID | Check | Result | Evidence |
|----|-------|--------|----------|
| B-SRV-1 | Every remote handler validates player, types, ranges, ownership | **PARTIAL** | 70 `Net.On` registrations across 24 services. A heuristic scan flagged candidates, but the heuristic is weak (it did not follow named handler functions). Manual result on flagged ones: `onStoreBuy` (`MonetizationService.luau:163-164`), `onWithdraw` (`FishService.luau:852-854`), `SettingsService.onSet` (`:14-27`) all validate types; `onReroll` does not (m-4). Not fully reviewed: the remaining ~60 handlers. |
| B-SRV-2 | `SkillService.buy`: order max → prereq → SP → Koin, atomic, returns reason | **PASS** | `src/server/Services/SkillService.luau` `buy`: max (`level >= maxLevel` → "max"), `Skills.missing` → "locked", SP → "noSP", `EconomyService.TrySpend` before `data.sp -=` → "noKoin". Cost 1 SP and 3.000 Koin (`Skills.luau`). FeatureGate check first (D-39). |
| B-SRV-3 | Fishing: bite on server, reel validated (time + range), bait consumed server-side, count returned | **PASS** (static), bait count sync not traced | Bite delay: `FishService.luau:449-466` (server). Reel: type check, `score ~= score`, `elapsed < REEL_MIN_SECONDS` return (`:690-697`); score clamped `math.clamp(score + …, 0, 1)` (`:722`). Bait: `InventoryService.Add(…, 1)` on refund; consumption path not traced end-to-end. |
| B-SRV-4 | No client-side grants of Koin, Bunga, XP, items | **PARTIAL** | C→S remotes that carry amounts: `Sell`, `ShopBuy`, `PasarJual(count)`, `BundelGive(count)`, `RanchPakan`. Server-side validation of each not traced. No grant-like remote found in `Net.lua` DEFINITIONS. |
| B-SRV-5 | `metNpcs` persisted, default for old saves, set from any dialogue source | **PASS** (name differs) | The field is `data.guide.hasMet` (not `metNpcs`): default `{}` in `DataTemplate.luau:172`; set from talk (`TutorialService.luau:179-191`, `onHasMet`), quest accept/finish (`QuestService.luau:90`, `:108`), shop (`ShopService.luau:79`, `:335`), kak_fajar gift (`TutorialService.luau:266`). Old-save default relies on the profile reconcile in `DataService`; not traced. |
| B-SRV-6 | Feature ids match between server and client; Skill gated at Player Lv 2 | **PASS** | Quest reveals (`Config/Quests.luau`): agenda, bantu, bubu, bundel, craft, dapur, empang, gerobak, hias, hutan, jual_bang_jali, kanal_barat, kandang_ayam, kandang_bebek, kolam, surat, warung. Client `FeatureClient.IsOpen` / `GateHud` use only ids from this set plus "skill". `FeatureGate.LEVEL_GATES = { skill = 2 }` (`FeatureGate.luau:21-23`). |

### B-DOC (doc ↔ code numbers, Single Source v7.7 / Skill Tree v7.7)

| ID | Item | Doc says | Code says | Result |
|----|------|----------|-----------|--------|
| B-DOC-1 | Bite wait | With bait 3–6 s; without 6–12 s; rain ×2; Jangkrik −30%; Buff Pancing −20% (Bab 6.1, 3.3, 6.3) | `Fishing.luau:49-53` (3–6, 6–12, rain 2); Jangkrik `biteReduction = 0.3` (`:36`); `Dapur.luau:137` BUFF_PANCING_BITE = 0.8 | **PASS** (rod biteMult undocumented → m-5) |
| B-DOC-2 | Reel | Window 1.5 s; FILL_GAIN 0.28; FILL_DRAIN 0.06; start 30%; 0% = escape | No window; `FishingController.luau:45` 0.28, `:46` 0.06, `:353` start 0.3; `:384-386`. Min reel 2.5 s (server). | **MISMATCH** window (M-3a); fill numbers PASS |
| B-DOC-3 | Skills: 16 × 5, 1 SP and 3.000 Koin per level, prerequisites, OR groups, Tetangga Baik | Skill Tree Bab 1, 2 | `Skills.luau` 16 entries, prereqs identical (checked each row), OR groups on Panen Raya and Ikan Besar, Tetangga total 5 + level 10 | **PASS** |
| B-DOC-4 | Breakpoints Lv 3 | Tempat Pakan Besar, Tukang Cepat, Tetangga Baik | `breakpoint = 3` on all three (`Skills.luau`); `effectLevel` (function in the same file) | **PASS** |
| B-DOC-5 | Mining | Best axe only; Besi +1, Baja +2; Tukang +1/+2; cap +4 per node; Kapak Bunga +1 | `MiningService.luau:78-90` (best axe), `:157` cap `NODE_BONUS_MAX` = 4; `Farm.luau:50-51` Besi 1, Baja 2; `kapak_bunga` **missing** | **MISMATCH** (M-2); rest PASS. Buff Tukang/Tebang "+1 only on Critical" not traced. |
| B-DOC-6 | Rod unlock and tool tables use Player Lv | Bab 6.3, 17.5 | Rod table = doc (`Fishing.luau` rodList, `unlockLevel` = Player Lv). Tool table = doc (`Farm.luau:42-52`). | **PASS** |
| B-DOC-7 | XP curve and level-up toast | XP `200 + 30n` (Bab 4.2 line 252) | `Progression.luau:20-22` = same formula. Toast `level.up_unlocks` = "Level {level}! Terbuka: {unlocks}" (`Locale/id.luau:697`). Unlock table drift → m-3. | **PASS** for curve; **MINOR MISMATCH** for unlock list |
| B-DOC-8 | Bait and shop prices | Cacing 10 / Jangkrik 25 / Pelet 45 / Udang Kecil 80; tools (Bab 17.5) | Baits `Fishing.luau:34-39` = same. Tools `Farm.luau:42-52` = all 8 prices and requirements match Bab 17.5. Shop buy/sell values not checked. | **PASS** (partial: shop sell values not checked) |
| B-DOC-9 | Economy sink / faucet constants | Bab 17.4 / 17.8 | Chunk price `Plots.luau:74` = 1500 × 1.2ⁿ (matches Bab 17.4). `Economy.luau` holds only START_KOIN, caps. Petak price and faucet not traced. | **PARTIAL** |
| B-DOC-10 | FTUE steps and rewards | Joran Bambu from Kak Fajar; first fish Wader Cakul; Siram 20 XP; Panen/Jual 20 XP; jual_ikan top-up | Gift = Joran Bambu (`Onboarding.luau:171`, comment). Wader Cakul = `wader_cakul` (`Fish.luau:25`). `panen_jual` xp 20 (`:138`). `siram` xp **1** (`:127`) → m-2. `jual_ikan` xp 115 (decided, #11). | **MISMATCH** (m-2); rest PASS |

### B-STORY (quests and NPCs)

| ID | Check | Result | Evidence |
|----|-------|--------|----------|
| B-STORY-1 | Each NPC has one intro (`npc.<id>.meet`) used only when never met; greet lines have no intro | **PASS** (static) | `Locale/id.luau:423-498`: `greet` lines have no introduction ("Saya beli …"); `meet` lines introduce ("Halo, {name}! Saya X …"). Bang Jali greet 1–8 checked, none introduce. The `meet` key is only used in `FirstMeetDialogue` (`DialogueController.luau:295`), which is gated by `HasMet`. |
| B-STORY-2 | Quest chain reachable, no dead end | **NOT DONE** | Requires a manual walk of Quest v0.3 with each unlock. Not done in this pass. |
| B-STORY-3 | Pak Udin story continues, no re-intro | **NOT VERIFIED** | Covered by D-1, not traced in code. |
| B-STORY-4 | Bang Jali shop does not open before `jual_bang_jali` | **PASS** | `ShopController.luau:550` (client) and `ShopService.luau:80`, `:337` (server) gate buy and sell on `bang_jali*` + `FeatureGate.Check("jual_bang_jali")`. |
| B-STORY-5 | Kerja Bakti text names where and how many | **PARTIAL** | "How many" yes (`Quests.luau:351`). "Where": Quest Log hint names the plaza (`Locale/id.luau:1001`, `kb.active`). Studio check → m-8 / T-4. |
| B-STORY-6 | Banner hides other GUI and restores it | **PASS** (static) | `BannerController.luau:104` `UiKit.hideOthers(gui)`, `:121` `UiKit.restoreOthers()`, counter-based. |

---

## 5. Layer C — Logic checks

**Status: not available.** No Luau runner is in the repo or the toolchain (`aftman.toml` lists rojo, selene, StyLua only; no `wally.toml`, no `lune`). Per plan, no framework was added, no `tests/` folder was created.

Cases below were checked **by hand against the Config values** (arithmetic only, not executed). They are "unverified, needs runner" for execution.

| # | Case | Hand check | Status |
|---|------|------------|--------|
| 1 | Prereq helper: locked/OR/total | Logic read in `Skills.missing` (`Skills.luau`, function `missing`). Matches Skill Tree Bab 2. | Unverified, needs runner |
| 2 | Cost: 5 levels = 5 SP / 15.000 Koin; 16 skills = 80 SP / 240.000 Koin | 5×1 = 5; 5×3.000 = 15.000; 16×5 = 80; 80×3.000 = 240.000. ✓ | Hand-checked, needs runner |
| 3 | SP budget: Lv 60 → 59 SP, 177.000 Koin | 60−1 = 59; 59×3.000 = 177.000. ✓ | Hand-checked, needs runner |
| 4 | Breakpoint: Lv 1–2 no effect; Lv 3 and 5 effects | `effectLevel` returns 0 below breakpoint (`Skills.luau`). Tetangga/Tukang bonus at ≥3 and ≥5. | Hand-checked, needs runner |
| 5 | Mining bonus: best axe, cap 8 | Base 4 + min(4, Besi 1 + Tukang) — max 8. ✓ | Hand-checked, needs runner |
| 6 | Bite delay ranges | `FishService.luau:449-466`: with bait ×[3,6]×0.7 (Jangkrik) or ×1 (no reduction) — range is [3,6]; without bait [6,12]; rain ×2. Sampling not run. | Hand-checked, needs runner |
| 7 | Level curve strictly increasing, no gaps | `200 + 30n` strictly increasing; Unlock table has gaps by design (not a list of every level). | Hand-checked, needs runner |

---

## 6. Layer D — Manual Studio checklist (blank, for the owner)

Owner fills each `[ ]`. Claude Code did not mark anything. Use a **fresh account** and an **existing account**. Device sizes: 1920×1080, 844×390, 667×375, 390×844.

Legend: `[ ] Pass` · `[ ] Fail` · notes: ____________

1. **FTUE and NPCs** — fresh account meets Pak Udin, Kak Fajar, Bang Jali once each with intro. `[ ] Pass` `[ ] Fail` notes: ____
   - No NPC re-introduces. `[ ] Pass` `[ ] Fail` ____
   - Story continues after each dialogue. `[ ] Pass` `[ ] Fail` ____
   - Joran Bambu + Pelet gift received. `[ ] Pass` `[ ] Fail` ____
   - Existing account never sees an intro for an NPC it already met. `[ ] Pass` `[ ] Fail` ____
2. **Dialogue UI** — long text stays inside bubble. `[ ] Pass` `[ ] Fail` ____ · `!` marker does not cover NPC name. `[ ] Pass` `[ ] Fail` ____ · Next works at last line. `[ ] Pass` `[ ] Fail` ____
3. **Quests** — Kerja Bakti text clear (see T-4). `[ ] Pass` `[ ] Fail` ____ · Banner Dimulai/Selesai hides and restores GUI. `[ ] Pass` `[ ] Fail` ____ · Tracker wraps, no clipping at screen edge. `[ ] Pass` `[ ] Fail` ____
4. **Shop** — Bang Jali shop does not open before unlock. `[ ] Pass` `[ ] Fail` ____ · Toko GUI renders. `[ ] Pass` `[ ] Fail` ____ · Buy/sell changes Koin correctly. `[ ] Pass` `[ ] Fail` ____
5. **Tas** — all tabs work. `[ ] Pass` `[ ] Fail` ____ · Umpan tab holds only bait. `[ ] Pass` `[ ] Fail` ____ · No clipped tab labels. `[ ] Pass` `[ ] Fail` ____
6. **Fishing** — with bait, bite ≈ 3–6 s. `[ ] Pass` `[ ] Fail` ____ · Without bait ≈ 6–12 s. `[ ] Pass` `[ ] Fail` ____ · Bait chip shows name and count, −1 per cast, "Umpan habis" at 0. `[ ] Pass` `[ ] Fail` ____ · Status strip always has text. `[ ] Pass` `[ ] Fail` ____ · Cancel readable. `[ ] Pass` `[ ] Fail` ____ · Walking away cancels and returns bait (note: 24 studs, see M-3b). `[ ] Pass` `[ ] Fail` ____ · Rain ≈ 2× longer. `[ ] Pass` `[ ] Fail` ____ · Cast / reel animations play. `[ ] Pass` `[ ] Fail` ____
7. **Farming** — plant and water animations play (FarmPlant 72416432910267, FarmWater 106687765397165). `[ ] Pass` `[ ] Fail` ____ · Crops grow on time. `[ ] Pass` `[ ] Fail` ____
8. **Toasts** — level-up, collection, fish-caught toasts centred, below currency bar, readable, stack max 3, never overlap tracker or right buttons; narrow portrait drops below tracker. `[ ] Pass` `[ ] Fail` ____
9. **Hadiah** — button number not clipped. `[ ] Pass` `[ ] Fail` ____ · Hadiah state noted (UI-3b). `[ ] Pass` `[ ] Fail` ____
10. **Skill** — button hidden before Lv 2 (see m-9). `[ ] Pass` `[ ] Fail` ____ · Tree shows 6 branches with node names (D-40 open). `[ ] Pass` `[ ] Fail` ____ · Locked node shows requirement. `[ ] Pass` `[ ] Fail` ____ · Buy deducts 1 SP + 3.000 Koin. `[ ] Pass` `[ ] Fail` ____ · Each failure reason shows right message. `[ ] Pass` `[ ] Fail` ____ · Panen Raya unlocks with either parent at Lv 3. `[ ] Pass` `[ ] Fail` ____ · Tetangga Baik needs total ≥ 5 and Player Lv 10. `[ ] Pass` `[ ] Fail` ____ · "Efek mulai Lv 3" shown on breakpoint skills. `[ ] Pass` `[ ] Fail` ____ · Tempat Pakan Besar no effect at Lv 1–2. `[ ] Pass` `[ ] Fail` ____
11. **Mining** — best axe only; Tukang Cepat adds to it; a node never gives more than 8 bahan. `[ ] Pass` `[ ] Fail` ____
12. **Economy sanity** — play 30 min on a normal route; note Koin earned and spent; compare with Bab 17 (target sink ratio 65–80%). Koin earned ____ Koin spent ____ ratio ____ `[ ] Pass` `[ ] Fail`
13. **Persistence** — leave and rejoin; Koin, SP, skills, bait, met NPCs (`guide.hasMet`), quest progress persist. `[ ] Pass` `[ ] Fail` ____
14. **Performance** — no console errors or warnings in Output during the full run. Paste any: ____________ `[ ] Pass` `[ ] Fail`

Device check (repeat items 2, 3, 5, 6, 8, 10 on each): 1920×1080 `[ ]` · 844×390 `[ ]` · 667×375 `[ ]` · 390×844 `[ ]`

---

## 7. Lampiran D and Roadmap changes made in this pass

**Lampiran D (`docs/Kampoeng_Tedoeh_v7.7.md`), new items:**

| # | Topic | Status |
|---|-------|--------|
| 50 | Items #36–#49 inside Bab 4.4 Unlock; #45 collision (M-1) | Doc fix needed |
| 51 | Kapak Bunga documented, not in code (M-2) | Owner decision |
| 52 | Reel window 1.5 s stale; min reel 2.5 s undocumented (M-3a) | Doc update |
| 53 | Leave distance 8 stud in Bab 6.1 vs 24 in code (M-3b, see #26) | Owner approves #26, then doc update |
| 54 | FTUE Siram XP 20 (doc) vs 1 (code) (m-2) | Owner decision |
| 55 | Unlock table drift and stale v6.2 references (m-3) | Doc/code sync |
| 56 | Rod tuning numbers (biteMult, rareBonus, legendaryBonus) not in Bab 6.3 (m-5) | Doc update |
| 57 | Stale "(v7.5, BELUM DIPUTUSKAN)" heading (m-10) | Doc fix |
| 58 | ZIndex rule scope undefined (m-7) | Doc rule |
| 59 | Tas tab order not specified (m-6) | Doc decision |
| 60 | Test plan D10 expects Skill button locked; code hides (m-9) | Test plan wording fix |

**Roadmap §12 (`docs/Roadmap.md`), new rows:** T-1 (second toast), T-2 (onReroll typeof), T-3 (stale comment references), T-4 (Kerja Bakti Studio check). All open `[ ]`. No code was changed.

---

## 8. What could not be tested, and why

- **A-3 Luau analyze**: no `luau-analyze` / `luau-lsp` on this machine. Not installed.
- **Layer C runtime**: no Luau runner (no `lune`, `luau`, TestEZ, Jest). Cases hand-checked only (§5).
- **Studio behaviour** (all of D; B-UI-2, B-UI-5, B-STORY-3, B-STORY-5 "where"): needs Roblox Studio playtest.
- **B-STORY-2** (quest chain walk): not done in this pass.
- **B-SRV-1 / B-SRV-4**: heuristic scan plus manual review of the flagged handlers only; the rest of the ~70 remote handlers were not reviewed.
- **B-DOC-8 shop sell values, B-DOC-9 faucet / petak price**: not traced.
- **Bait consumption and bait-count sync (B-SRV-3)**: not traced end to end.
- **Old-save default for `guide.hasMet` (B-SRV-5)**: relies on profile reconcile; not traced.
- **Plan naming**: the plan uses `metNpcs`; code uses `guide.hasMet`. Checked under the code name.

---

## 9. Final notes

- Commit: see the git log entry `test: full regression pass 2026-11-23`.
- Studio checklist is in §6 (section D of the plan).
