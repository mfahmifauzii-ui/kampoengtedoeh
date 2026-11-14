# Kampung Teduh — Design Doc (v0.2, updated Phase 10)

Cozy, no-fail life-sim in an Indonesian kampung. Pillars: **Bertani**, **Mancing**, **Menghias**.
Shared village server (**4 players**, X-shaped map, see `Map_Plan.md`), each player owns one plot. Indonesian-first UI, target age 9+.

---

## 0. Schedule reality check ⚠️

The **15 Nov 2026** target is **7 days away** (8 h total). Phases 1–10 estimate to **~85 h**.

| Phase | Est. hours | Week of (8 h/wk) |
|---|---|---|
| 1 Foundation | 8 | 9 Nov |
| 2 Farming slice | 8 | 16 Nov |
| 3 Fishing slice | 10 | 23 Nov – 30 Nov |
| 4 Inventory / shop / sell | 6 | 30 Nov |
| 5 Decor placement | 12 | 7 – 14 Dec |
| 6 Orders + Book + levels | 10 | 21 Dec |
| 7 Day/night, weather, audio | 8 | 28 Dec |
| 8 Monetization + analytics | 6 | 4 Jan |
| 9 Social-lite (mampir, likes) | 5 | 11 Jan |
| 10 Playtest, balance, launch prep | 12 | 11 – 25 Jan |

**Proposal:** 15 Nov becomes "Foundation done + farming in progress". Hours exclude your UI and building time.
- **Closed playtest (friends):** ~18 Jan 2027
- **Public launch:** ~1 Feb 2027. Ramadan 2027 begins around 8 Feb, so the first live event (Ramadan → Lebaran) arrives within a week of launch. That's a strong early retention beat.

---

## 1. Loops

**Micro (30–90 s):** plant or cast → short wait → harvest or catch → soft popup + sound + XP tick.
**Session (10–20 min):** do the 3 daily orders → coins + XP → buy a seed or rod tier, expand the plot → unlock the next crop, fish or decor.
**Meta (days/weeks):** Collection Book → decorate the pekarangan → level gates → likes from visitors → (post-launch) events.

**Always-visible next goal:** a HUD chip shows the single nearest goal. Priority order: an order you can finish now, then the next unlock (with the level or coins still needed), then the next Book entry.

**No fail states:** the reel mini-game can't lose a fish (performance only sets size), crops never wither, and there are no energy bars.

---

## 2. Currencies

| | **Koin** (soft) | **Bunga** (premium-lite) |
|---|---|---|
| Earn | selling, orders | free: level-ups, weekly order, daily visit step 7, like milestones, Book (≈2/day early, ≈1/day late — see Playtest_Plan) |
| Spend | seeds, tools, expansions, basic decor | cosmetic decor, rod skins, extra order reroll |
| Buy with Robux | small packs (Phase 8) | packs (Phase 8) |

Rule: **nothing that gates progression costs only Bunga.** Everything that affects progress can be bought with Koin.

Starting wallet: 100 Koin, 10 Bunga.

---

## 3. Farming (8 crops)

Plot tiles start at **6** and expand in steps of +3: 300 / 800 / 2 000 / 5 000 / 12 000 Koin → **21 max**. The Extra Plot pass adds +4.
Growth runs on server `os.time()`, so crops keep growing offline.
**Watering is optional** and cuts the remaining time by 20%. During **rain**, all tiles count as watered.

| Crop | Unlock Lv | Seed | Grow | Sell | Profit/min | XP |
|---|---|---|---|---|---|---|
| Kangkung | 1 | 5 | 1 m | 9 | 4.0 | 2 |
| Cabai | 1 | 10 | 3 m | 20 | 3.3 | 3 |
| Tomat | 3 | 15 | 5 m | 30 | 3.0 | 5 |
| Terong | 5 | 25 | 10 m | 50 | 2.5 | 8 |
| Jagung | 8 | 40 | 20 m | 85 | 2.3 | 12 |
| Singkong | 11 | 60 | 45 m | 140 | 1.8 | 20 |
| Padi | 14 | 80 | 2 h | 220 | 1.2 | 35 |
| Pisang (tree, regrows ×3) | 18 | 200 | 8 h / cycle | 120 × 3 bunches | ~0.75 | 40 |

Design intent: short crops pay more per minute (rewarding active play), and long crops pay for being away (offline-friendly). Neither is a trap.

---

## 4. Fishing (12 fish)

**Locations**
- **Sungai** (shared river)
- **Empang** (shared village pond, unlocks at Lv 4)
- **Kolam** (ponds you dig yourself on your plot, unlock at Lv 6 via the quest "Kolam Pertamamu"; the first one is free)

**Flow:** tap to cast → bite in 4–10 s (rod and bait shorten this) → **reel mini-game**: hold to keep a marker in a soft zone for about 3 s. **You always catch the fish**; how well you reel sets the size (S/M/L), worth ×1.0 / ×1.2 / ×1.5 value.

**Base rarity weights:** Common 70 / Uncommon 22 / Rare 7 / Legendary 1. A Legendary can only roll when its conditions are met.
**Rain:** Rare ×1.5, Legendary ×2.

| Fish | Rarity | Where | Condition | Sell |
|---|---|---|---|---|
| Wader | C | Sungai | – | 8 |
| Nila | C | Empang, Kolam | – | 10 |
| Mujair | C | Empang | – | 10 |
| Lele | C | Kolam, Empang | ×2 at night | 14 |
| Ikan Mas | U | Empang, Kolam | – | 25 |
| Bawal | U | Empang | – | 28 |
| Gabus | U | Sungai | sore / malam | 35 |
| Belut | U | Sungai | rain | 40 |
| Gurame | R | Empang | pagi | 80 |
| Udang Galah | R | Sungai | malam | 90 |
| Koi Kampung | R | Kolam | ×2 in rain | 150 |
| Arwana | L | Sungai | rain **and** malam | 500 |

**Rods**

| Rod | Price | Unlock | Effect |
|---|---|---|---|
| Joran Bambu | start | – | – |
| Joran Rotan | 500 | Lv 5 | bite −15%, Rare +2 |
| Joran Fiber | 2 000 | Lv 10 | bite −25%, Rare +4 |
| Joran Juragan | 6 000 | Lv 18 | bite −35%, Rare +6, Legendary +1 |

**Bait (optional consumable):** Cacing is free and unlimited (baseline). Pelet costs 5 Koin each and cuts bite time by 30%.

**Kolam offline catch:** 1 Common/Uncommon fish every 10 min, capped at **10 per pond**. Coin upgrades raise the cap to 20 → 30 (all ponds, and the ponds look nicer: stone rim, then lily pads + lamps), and the 2× Offline pass doubles it. Collect with one tap at each pond.

**Building ponds:** Garap → *Kolam* digs a 16×16 pond (real water terrain, 8 studs deep) anywhere on your green land; *Hapus Kolam* fills it back in and refunds 50% of what was paid (uncollected fish are lost). Up to 4 ponds. Price: 1st free, then 400 / 900 / 1.600 koin (Config/Fishing POND.PRICES). Soil and decor can't overlap a pond.

---

## 5. Inventory & selling

- **Backpack:** 40 slots, stack size 99. Coin upgrades raise it to 60 / 80 / 100 (1 000 / 4 000 / 10 000). The Bigger Backpack pass adds +40.
- **Sell:** at **Warung Pak Darmo** in the village center, either everything or one stack at a time. Prices are fixed for MVP.
- **No trading** between players at MVP. That avoids scams, dupes and the policy surface that comes with trading.
- **Cooking** (gorengan, es teh, nasi liwet, pisang goreng) and the player-owned warung → **post-launch v1.1**.

---

## 6. Decoration

- **Grid:** 2-stud grid, 90° rotation, placement only inside your own plot bounds. Collisions are checked on the server. Operations: place, move, rotate, store.
- **Item limit:** 150 placed items. The Decor Expansion pass adds +100.
- **Plot layout:** 96×96 studs, containing a fixed rumah panggung, the farm area, any ponds the player digs and a free pekarangan for decor. House **interior** decor → post-launch.
- **MVP set "Pondok Sawah" (12 items):** bale bambu, kursi bambu, meja kayu, lampu teplok, pot tanah liat, pagar bambu (lurus + sudut), jalan batu, orang-orangan sawah, gentong air, jemuran, sepeda onthel.
  - Completing the set grants a cosmetic title plus a bonus decor item.
- **Basic utility decor:** about 6 items for Koin (fences, paths, plants, lamps).
- **Bunga-exclusive variants:** 3–4 recolors or premium pieces.

---

## 7. Orders

- **NPC warga (5):** Pak RT, Bu Sari (warung), Mbah Karto (petani), Mas Yudi (nelayan), Dik Rara.
- **Daily orders:** 3 per day. Each asks for 1–3 item types drawn from the player's unlocked content. Reward is about **1.5× sell value** in Koin plus XP. One free reroll per day; extra rerolls cost 2 Bunga.
- **Weekly order:** a bigger mixed request. Reward is about 3× value + **5 Bunga** + a decor item.
- **Day reset:** 00:00 WIB (UTC+7).
- **Kunjungan Harian (login reward):** the counter is **cumulative, not consecutive**, so missing a day only pauses it. The 7-step cycle is:

  | Step | Reward |
  |---|---|
  | 1 | 50 Koin |
  | 2 | 75 Koin |
  | 3 | 100 Koin |
  | 4 | seed pack |
  | 5 | 150 Koin |
  | 6 | 200 Koin |
  | 7 | 3 Bunga |

---

## 8. Progression & Collection Book

**Levels:** 1–30 at MVP. XP needed for the next level is `floor(20·L^1.5 + 10·max(0, L−8)^2.1)` (Phase 10; see `Playtest_Plan.md`).

| Pacing target | Model result (35 min/day) |
|---|---|
| Lv 5: first session (~20 min) | day 1 |
| Lv 10: day 3 | day 3 |
| Lv 20: week 2 | day 11 |
| Lv 30: ~week 5 | day 31 |

Each level-up grants 2 Bunga plus whatever it unlocks. One-time extras: Lv20 (10 Bunga + title), Lv25 (15 Bunga), Lv30 (25 Bunga + title).

**Collection Book (32 entries):** 8 crops, 12 fish, 12 Pondok Sawah decor.
- Fish also record their largest size caught (a bragging stat).
- Milestones:
  - 25%: 500 Koin
  - 50%: 10 Bunga
  - 75%: Lampion Gantung (decor)
  - 100%: title "Warga Teladan" + exclusive gazebo

---

## 9. World: time & weather (server-wide)

- **Day cycle:** 24 real minutes (pagi 5 / siang 8 / sore 4 / malam 7). Each phase has its own Lighting/Atmosphere preset.
- **Rain:** rolled every 20 min with a 25% chance and lasts 4–6 min. Effects: auto-waters crops, boosts rare fish, plays the rain ambience.

---

## 10. Social (MVP-lite)

- **Mampir:** teleport to another player's plot from the Warga panel (built Phase 9).
- **Suka:** 1 like per visitor, per plot, per WIB day, only while standing on that plot. The total is shown on the plot sign. Milestones pay the owner once: 10 → 3 Bunga, 50 → 10 Bunga, 200 → 25 Bunga + title.
- **Emotes:** Roblox defaults only (wave, cheer, point, dance). Building permissions on your plot belong to the owner alone.
- **Events (built Phase 9):** date-driven `Config/Events.luau`; event decor is buyable only during the event and kept forever. First event: Ramadan & Lebaran 2027.
- **Post-launch:** cross-server friend visits and photo mode.

---

## 11. Monetization (built in Phase 8)

| Type | Item | Draft price (R$) | MVP? |
|---|---|---|---|
| Pass | Bigger Backpack (+40) | 99 | ✅ |
| Pass | 2× Offline Capacity | 149 | ✅ |
| Pass | Decor Expansion (+100) | 149 | ✅ |
| Pass | Extra Plot Slots (+4) | 199 | ✅ |
| Pass | Auto-Collect | 249 | v1.1 |
| Pass | VIP Warung (cosmetic + sell-all anywhere) | 299 | v1.1 |
| Product | Bunga 50 / 120 / 300 | 49 / 99 / 229 | ✅ |
| Product | Koin S / M / L | 25 / 75 / 199 | ✅ |
| Product | Instant Grow (one tile, max 3/day) | 15 | ✅ |
| Premium | +10% Koin from orders, +1 daily reroll | – | ✅ |
| Private servers | | 50/mo | ✅ |

- **No random paid items** anywhere.
- **No popups:** the shop opens only when the player taps it.
- A **Monetization Review** checklist runs before each release.

---

## 12. Tech plan

- **Toolchain:** Rojo 7.7.1 + VS Code, `--!strict` where practical.
- **Data:** recommend **ProfileStore** (loleris, Apache-2.0) for session locking, autosave and safe release, rather than hand-rolling session locks. Schema is versioned with migration functions.
- **Remotes:** one `Net` module with named remotes. Every handler gets type checks, a per-player rate limit and an ownership/distance check.
- **Config:** all content lives in `Shared/Config/*.luau` (Crops, Fish, Decor, Orders, Levels, Shop, Locale_id).
- **Performance:** StreamingEnabled, plot-level model streaming, pooled VFX, no per-frame server loops (growth is computed from timestamps when needed).

```
src/
  server/Services/      DataService, EconomyService, FarmService, FishService,
                        InventoryService, DecorService, OrderService, WorldService, SocialService
  shared/Config/        Crops, Fish, Decor, Orders, Levels, Shop, Locale/id
  shared/Modules/       Net, Types, Util, RateLimit
  client/Controllers/   HudController, FarmController, FishController, DecorController, ...
  gui/                  (your UI)
```

**Data schema v1 (sketch)**

```lua
{
  version = 1,
  koin = 100, bunga = 10, xp = 0, level = 1,
  inventory = { [itemId] = count }, backpackTier = 0,
  plots = { tiles = { [i] = { crop = id?, plantedAt = t?, watered = bool } }, expansions = 0 },
  pond = { tier = 0, list = { {uid, cx, cz, paid, lastCollect} }, nextUid = 1 },
  quests = { active = { [id] = {step, count} }, done = { [id] = true } },
  rod = "bambu", ownedRods = {},
  decor = { { id, x, z, rot } }, -- grid coords relative to the plot
  orders = { day = "2026-11-08", list = {}, rerolls = 0, weekly = {} },
  book = { crops = {}, fish = { [id] = maxSize }, decor = {} },
  visits = { count = 0, lastDay = "" }, likes = { received = 0, givenToday = {} },
  purchases = { [receiptId] = true }, -- dev product idempotency
}
```

---

## 13. Scope cut

| MVP (launch) | Post-launch |
|---|---|
| 8 crops, 12 fish, 1 decor set | Cooking + player warung |
| 3 locations, 4 rods | House interior decor |
| Daily + weekly orders, Book, Lv 1–30 | 17 Agustusan event (framework + Lebaran already built) |
| Day/night + rain | Cross-server visits, photo mode, pets |
| 4 passes, Bunga/Koin packs, Instant Grow | Auto-Collect, VIP Warung, more decor sets |
| ID locale | EN locale |

---

## 14. Risks

1. **Launch date:** see §0.
2. **Data loss:** use ProfileStore. Never save from the client. Grant dev products through ProcessReceipt with a receipt log.
3. **Exploits:** time only from server `os.time()`. Validate placement against plot bounds and the grid server-side. Rate-limit casts, harvests and sells. Rewards come from the server's roll, never from the client's reel result beyond size tier.
4. **Performance:** 4 plots × up to 250 decor items is heavy on mobile. Keep decor to ≤ 8 parts per item and rely on streaming. Revisit if needed.
5. **Policy:** no paid random items. Fill in the age questionnaire honestly (no violence → expect a mild rating). Treat Lebaran/Ramadan respectfully and keep the events inclusive.
6. **Coin packs** can feel pay-to-progress. Keep them small, and never sell items that can't be earned.
