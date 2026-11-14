# Playtest Plan & Balance

Tanpa tanggal. Playtest #1 dilakukan setelah tahap R2 (peta cincin + lahan chunk) di `Roadmap.md`, sebelum fitur baru apa pun. Peserta: **3–5 orang dari target (perempuan ±16+)**, ditambah **playtest AI persona** untuk menemukan kebingungan lebih dulu.
Catatan: AI persona tidak bisa menilai "seru" dan cenderung sopan; ia hanya menemukan kebingungan dan bug. Rasa bosan dan senang hanya bisa dinilai orang asli.
Angka di bagian 1 dihitung untuk desain lama (tanpa kuota warung); jalankan ulang `balance_sim.py` setelah R1.

---

## 1. Balance model (tools/balance_sim.py)

Average-case model: 35 active min/day (25 min on day 1), half fishing, half farming, 3 daily orders,
offline crops once a day, 25% of income spent on decor. Run: `py -3 tools/balance_sim.py`.
The script copies numbers from `src/shared/Config` — update it when you change a config.

**XP curve (changed):** `floor(20·L^1.5 + 10·max(0, L−8)^2.1)` — total to Lv30 ≈ 81k XP.

| Level | Target | Old curve (20·L^1.5) | New curve |
|---|---|---|---|
| Lv 5 | first session | day 1 | day 1 ✅ |
| Lv 10 | day 3 | day 3 | day 3 ✅ |
| Lv 18 (all content unlocked) | – | day ~7 | day ~9 |
| Lv 20 | week 2 | day 8 ❌ | day 11 ✅ |
| Lv 30 | ~week 5 | day 16 ❌ | day 31 ✅ |

**Other changes in Phase 10**
- Late levels had no unlocks → one-time level rewards: **Lv20** 10 Bunga + title *Petani Rajin*,
  **Lv25** 15 Bunga, **Lv30** 25 Bunga + title *Sesepuh Kampung* (`Progression.LEVEL_MILESTONES`).
- Decor unlocks spread out so mid levels have something new: Jemuran Lv7, Gentong Air Lv9,
  Orang-orangan Sawah Lv12, Bale Bambu Lv15.

**Known imbalances (watch in playtest, fix post-launch)**
1. **Koin piles up after ~day 10.** Once the farm is maxed and the Juragan rod is bought (≈26k Koin total), Koin only buys cheap decor.
   - The model shows 40k+ banked by day 14.
   - Fix with **new Koin sinks**, not by cutting income. Kuota harian Pak Darmo (R1), pembelian chunk lahan (R2), dan upgrade sudah jadi sink awal; masak + warung pemain, rumah, dan set hiasan baru menyusul.
2. **Free Bunga ≈ 2/day early, ≈ 1/day after Lv30** (weekly order 5, visit day 7: 3, likes, Book). The design doc said 3–5/day.
   - It's still enough for a 50-Bunga gazebo within ~2 weeks.
   - If testers feel starved: +1 Bunga for finishing all 3 daily orders.
3. **Weekly order is a big spike** (≈36× the value target in Koin). That's fine as a weekly highlight; lower `WEEKLY_REWARD_MULT` to 2 if it feels like too much.

**Tuning knobs (one config file each):** XP curve → `Progression`; crop speed/price → `Crops`; fish value/odds → `Fish`;
order rewards → `Orders`; upgrade costs → `Shop`; decor prices/levels → `Decor`.

---

## 2. Playtest goals

0. **Apakah ini terasa seru?** Pertanyaan utama; tanpa jawaban ya, fitur lain tidak ditambah.
1. **Can a new player get going without help?** Plant, harvest, sell, fish, deliver an order and place decor in the first session.
2. **Is it calm?** No moment that feels like pressure, waiting walls, or "you must pay".
3. **Does it run on phones?** Touch fishing, touch decor placement, FPS and memory on a low-end Android.
4. **Pacing:** does Lv5 come in about 20 minutes? Do players say "one more order"?

## 3. Session script (for you as host)

1. **Before:** set `DATA_STAGE = "playtest"` (already set). Publish. Share the private-server or friends-only link. Pastikan Max Players sesuai jumlah slot lahan.
2. **Say only:** "Mainkan seperti biasa, ngomong aja apa yang kamu pikirkan." Don't explain the controls.
3. **Watch for 20 minutes and write down:**
   - the first moment they look lost
   - which HUD button they never tap
   - which toasts they miss
4. **Then let them play freely.** Ask them to come back tomorrow (D1).
5. **Day 3:** ask the survey below.

## 4. Survey (Indonesian, 2 minutes)

1. Apa yang paling kamu suka? (bertani / mancing / menghias / pesanan / mampir)
2. Ada bagian yang bikin bingung? Di mana?
3. Pernah merasa bosan menunggu? Kapan?
4. Dari 1–5, seberapa santai rasanya?
5. Kamu mau main lagi besok? Kenapa?
6. (Mobile) Ada tombol yang susah ditekan?

## 5. Metrics (Creator Dashboard → Analytics)

| Funnel step (AnalyticsHooks) | Target |
|---|---|
| 1 joined → 2 first_plant | ≥ 90% |
| → 3 first_harvest | ≥ 85% |
| → 4 first_sell | ≥ 75% |
| → 5 first_catch | ≥ 65% |
| → 6 first_order | ≥ 50% |
| → 7 first_decor | ≥ 40% |

- **D1 retention ≥ 25%, D7 ≥ 8%, average session ≥ 15 min** (healthy for a new cozy game).
- **Economy:** in the Economy dashboard, check sources vs sinks per day. Koin sinks should stay above ~40% of sources in week 1.
- Biggest drop in the funnel = the next thing to fix, before anything else.

## 6. Exit criteria for public launch

- No data loss or errors in 3 playtest days (check the Error Report in the dashboard).
- Funnel steps 1→4 at target.
- Runs on at least one low-end phone at ≥ 30 FPS with 8–10 lahan terisi.
- Every Launch Checklist item ticked.
