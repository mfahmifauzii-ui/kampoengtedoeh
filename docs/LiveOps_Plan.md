# Live-Ops Plan — Phase 11 (first 6 months after launch)

Budget is **8 h/week, solo**. This plan uses about 6 h of it. The other ~2 h stay free for bugs and real life.
**Rule: every update ships calm.** No countdown timers, no "last chance" copy, and seasonal items come back next year.

---

## 1. Weekly rhythm (8 h)

| When | Time | Work |
|---|---|---|
| Monday | 45 min | **Metrics review** (§4): write 3 lines in `docs/liveops_log.md`: what moved, why, what you'll do |
| Monday | 15 min | Read the group wall / comments; tag bugs |
| Tue–Thu | ~5 h | The current content item from §2 (config + model + UI) |
| Friday | 1 h | Studio test (2 players), Monetization Review if anything is sold, publish |
| Buffer | ~1 h | Hotfixes, or rest |

**Publish day:** Friday afternoon WIB, before the weekend peak, never right before you're away.
**Hotfix rule:** data or purchase bugs get fixed the same day. Everything else waits for Friday.

---

## 2. Calendar (launch ~1 Feb 2027)

| Window | Update | Type | Effort | Why |
|---|---|---|---|---|
| 1 Feb | **Launch** | – | – | – |
| 8 Feb – 21 Mar | **Ramadan & Lebaran** (already built) | event | 0 h (check dates) | Early retention beat in week 2 |
| Feb wk 3 | **v1.0.1: launch fixes** | patch | 6 h | Whatever the funnel and Error Report show |
| Mar | **Set "Warung Kopi" decor** (8–10 items, Koin + 2 Bunga) | content, config-only | 10 h | Fresh decor goals; partial Koin sink |
| Apr – mid May | **v1.1: Masak + Warung Pemain** | system | 35–40 h | **Main Koin sink** (Playtest_Plan imbalance #1); new daily loop |
| May | **2 crops + 2 fish** (e.g. kacang panjang, kopi; patin, sepat) | content, config-only | 6 h | Keep the Book growing; Book % recalculates automatically |
| ~21 Jun – mid Jul | **Libur sekolah: v1.2** (EN locale + photo mode) | system | 20 h | Biggest player peak of the year; EN opens new markets |
| 10 – 24 Aug | **Agustusan event** (bendera, umbul-umbul, gapura, panjat pinang decor) | event, config-only | 8 h | National, inclusive, very Indonesian |
| Sep – Oct | **v1.3: rumah interior** or cross-server visits (choose from data) | system | 30 h | Decor depth for late-game players |

**Event inclusivity:** Lebaran is the first event. Add **Imlek** and **Natal & Tahun Baru** in the 2027–28 cycle, so every community sees its own season in the kampung. Keep each event focused on culture and decorations, with no religious practice as a game mechanic.

---

## 3. Content pipeline (what's config-only)

| Add | Files | Code? |
|---|---|---|
| Decor item / set | `Config/Decor.luau` + `decor.<id>` locale (+ model in `ReplicatedStorage/DecorModels`) | no. A new set enters the Book only if you add its `set` to the filter in `Config/Book.luau` |
| Event | `Config/Events.luau` entry + `event.<id>` / `.desc` locale + decor with `event = "<id>"` | no |
| Crop / fish | `Config/Crops` or `Config/Fish` + locale | no (orders, Book, unlocks pick them up) |
| Order NPC | `Config/Orders.NPCS` + locale | no |
| Level reward | `Progression.LEVEL_MILESTONES` | no |
| New loop (cooking) | new service + remotes + data fields | **yes: add data fields to the template; restructures need a migration** |

**Before each publish:**
- `py -3 tools/balance_sim.py` if prices or XP changed
- `docs/Monetization_Review.md` if anything is sold
- Data template changes are additive only (or add a migration and bump `version`)

---

## 4. Weekly metrics (Creator Dashboard)

| Metric | Healthy | If below → do this |
|---|---|---|
| Funnel step 1→4 (plant → sell) | ≥ 75% | Look at the first broken step; improve the goal chip text or the first-time hint |
| Funnel 4→7 (catch → order → decor) | ≥ 40% | Make the first order easier; give one free decor in the first order |
| D1 retention | ≥ 25% | Day-1 hook: stronger visit reward on day 2, or a crop ready "besok pagi" |
| D7 retention | ≥ 8% | Weekly order more visible; add mid-level goals |
| Avg session | ≥ 15 min | Shorter early crops; more fish variety at Sungai daytime |
| Koin sinks / sources | ≥ 40% | Ship the next Koin sink sooner (v1.1) |
| Bunga earned free / day | 1–3 | <1: +1 Bunga for finishing all 3 daily orders |
| Payer conversion | 0.5–2% | Lower: check that prices show and the Toko is findable. **Never** add popups |
| Error Report | 0 new data/purchase errors | Hotfix same day |

**Compare week over week**, not against other games. One bad week means nothing. Act on a trend over 3 weeks.

---

## 5. Monetization in live-ops

- Event decor: mostly **Koin**, with at most 1–2 items for Bunga. Never Robux-only, and never random.
- New passes only for convenience that's already fair without them. Candidates for v1.1+: Auto-Collect (pond + finished crops) and VIP Warung (cosmetic + sell anywhere).
- Price changes: lower is fine; **never raise** a price on something players already see as normal.
- Run `Monetization_Review.md` for every update that sells anything.

---

## 6. Community (light)

- **Roblox group "Kampung Teduh":** update notes (2–3 lines per update), and bug reports on the wall.
- In the game description, keep a short "Update terbaru" line at the top.
- Speak to a 9+ audience: friendly, short, Indonesian first.
- Never promise dates you might miss. Say "segera" until the update is in Studio and tested.

---

## 7. Risks

1. **Solo burnout:** 8 h/week is the ceiling, not the floor. If a week is lost, the calendar shifts; events (date-bound) still run because they are data.
2. **Data:** any schema change after launch = migration + test with an old save (copy one from the playtest store).
3. **Cultural events:** have someone from that community look at the decor and copy before release.
4. **Platform policy changes** (ratings, monetization rules): check the Roblox DevForum announcements in the monthly review.
5. **Koin inflation:** if v1.1 slips past May, add a temporary sink (expensive decor set) so late players still have goals.
