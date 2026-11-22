# Roadmap Kampoeng Tedoeh — Implementasi v7.4

> Sumber kebenaran: `docs/Kampoeng_Tedoeh_v7.4.md`. File ini rencana kerja, bukan dokumen desain. Jangan ubah angka di v7.4 dari file ini.
> Detail file per tugas yang sudah DONE ada di pesan commit (`git log --oneline main..feat/v.7`), tidak diulang di sini.

## 1. Status Ringkasan (2026-11-22)

| Tahap | Status | Sisa |
|-------|--------|------|
| P0 | Done | Bab 29 kelar + Upgrade Tas Koin dihapus (`ce0a7f4`). |
| P1 | Done | 10/10 angka persis v7.3 (`c452303` … `3d1fc7b`). |
| P2 | Jalan | P2-1 s/d P2-7 + fix DONE. **Berikutnya: P2-8 (FTUE v7.4).** Lalu P2-9 Login/Season, P2-10 Blueprint/Akuarium/FX/KPI. |
| Studio | Belum | §6, tidak ada di `src/`. |

### 1.1 Delta v7.3 → v7.4 (hasil review 2026-11-22)

Angka ekonomi/sistem **tidak ada yang berubah**. v7.4 = v7.3 + doc fix P2-8 untuk FTUE + perapihan teks.

| Bab | Perubahan v7.4 | Dampak ke kode |
|-----|----------------|----------------|
| 16.1 | **No-skip LOCKED**: tidak ada `Lewati` / `Lewati langkah` / `Lewati panduan` / skip cutscene / coachmark / dialog. (v7.3 masih punya Lewati.) | Ada 4 tombol skip di kode → hapus (P2-8a). |
| 16.2 | Tabel FTUE + kolom "Catatan P2-8". FTUE lama dipertahankan, tidak ada FTUE/naskah baru. Mancing FTUE hanya di dermaga Kanal. | Lihat catatan gap di P2-8. |
| 16.3 (baru) | **Blok NPC selama Tutorial 1**: semua NPC di luar target langkah aktif jawab satu kalimat `Selesaikan tutorial dulu`, tanpa toko/dialog/quest/order/hadiah/bantu. | Belum ada di kode (P2-8b). |
| 16.4 (baru) | **Cutscene Jual Pertama proximity**: dekati Pak Udin → cutscene → GUI Jual yang sama dibuka → jual → tutup GUI → cutscene selesai → 20 XP. | Kode sekarang kebalikannya: cutscene main SETELAH jual dan menutup toko (P2-8c). |
| 16.5 (baru) | **Kolam keluar dari Tutorial 1.** Kolam pertama hanya lewat MQ4 / Bundel Kakek Lv 3. | T1b masih punya langkah `bangun_kolam` + `mancing_kolam`, dan `kolamUnlocked` diset tutorial (P2-8d). |
| 9.4 | Buff ditulis ulang (isi sama) + baris baru: "Buff + Skill stack, peluang Super tetap dibatasi cap Bab 17.6 / 5.4". | Bab 17.6/5.4 tidak punya angka cap peluang Super → BUTUH KEPUTUSAN OWNER (§5). |
| 9.2, 10.1, 14.7, 0.3, 5, 8.3, 29, 31 | Perapihan teks / pindah paragraf. Order Villager tambah "reroll = tier sama". | Cek reroll tier sama di P2-8e (verifikasi saja). |

## 2. Aturan Kerja (LOCKED)

- Kerjakan urut. Satu tahap = satu commit / satu laporan. Jangan campur tahap dalam 1 commit.
- Setiap tugas harus ada "Cara Cek" (grep / file:baris / nilai). Jangan tulis "sudah bener" tanpa cara cek.
- Jangan ubah v7.4.md. Jangan ubah map. Jangan ngarang angka. Angka tidak ada di v7.4 → STOP, tulis di §5 "BUTUH KEPUTUSAN OWNER".
- Selesai 1 tugas: ganti `[ ]` → `[x]`, tulis tanggal + commit + hasil verifikasi (selene / rojo build / grep).

## 3. Yang Sudah DONE (ringkas)

| Tahap | Commit | Isi + Cara Cek utama |
|-------|--------|----------------------|
| P0 | `ce0a7f4` | Bab 29 dihapus (Mutasi, Blueprint gating, dst.) + Upgrade Tas Koin. `grep -r "UPGRADES.backpack\|HasFreeSlot\|inv.full" src/` = 0. |
| P1-1 | `c452303` | 18 tanaman Bab 5.3 + byproduct Jerami/Daun Pisang. `Crops.luau` 18 entri. |
| P1-2 | `88a5580` | 20 ikan Bab 6.4 + Buka Lv + ukuran x0,8/1,0/1,2/1,5 (key `Jumbo`). |
| P1-3 | `2b56345` | 6 joran + 4 umpan + 9 alat Bab 6.3/17.5. |
| P1-4 | `7bcd6d2` | Album 214 (54+80+72+8) + milestone. |
| P1-5..8 | `261d762` `fa43281` `e5b440e` `20ac57b` | Playtime 5 peti 50-300 · `version = 72` · partikel 30/60/90 · cap hias 800. |
| P1-9/10 | `406ba10` `55cc20a` `3d1fc7b` | Agenda 5 tugas 150-400 Koin tanpa XP/Bunga · XP ikan per-ikan 10-600. |
| P2-1 | `2af3d12` `53d1049` | Nambang 6 node, 4 pukul, Critical, respawn 4 mnt + 7 mentah + 7 olahan + craft x10. |
| P2-2 | `bbbb2d0` `05a1940` | Ternak Ayam/Bebek/Sapi + kandang + pakan + Mood Hujan; kolam Tanah/Semen/Keramik + breeding + Kolam Kakek + instant Bunga. |
| P2-3 | `6145f9d` `52c8db6` | Dapur 24 resep T1-T3 + Warung + 4 buff aktif + Order Daily 3/Weekly 1 + reroll. |
| P2-4 | `2a29121` `c367762` `75e72bd` | Skill 16 + SP + pity 200 / Firasat; CABANG dihapus. |
| P2-5 | `531f2da` `8523c29` | Bantu / Hadiah / Gestur / Chat / Like / Galeri top 5. |
| P2-6 | `5406296` `e690225` | Gerobak Kaget / Pasar Malam / Kerja Bakti / Pesanan Tamu + Kalender 5 event. |
| P2-7 | `5904514` `94cc3c8` | Quest Harian/Mingguan + Toko Bunga + MQ1-12 + Surat 30 + Side 8 + Bundel 5. |

## 4. P2 — Sisa (urut, jangan dibalik)

### P2-8. FTUE v7.4 — Bab 16.1-16.5 (BUKAN rebuild FTUE)

Prinsip v7.4: FTUE lama (`Config/Onboarding.luau` T1 `t1_awal` + T1b `t1b_kolam`, `T1Ghost.client.luau`, `GuideController.luau`) dipertahankan. Hanya 4 hal di bawah.

- [ ] **P2-8a No-skip (Bab 16.1).** Hapus semua tombol skip tutorial:
    - `src/client/BeatSkip.luau` (tombol `Lewati` beat intro + warung) → hapus modul + 6 pemakaian di `T1Ghost.client.luau` (`BeatSkip.Begin/End/Requested`).
    - `GuideController.luau:1094-1135` (`SkipStepButton` "Lewati langkah" + `SkipAllButton` "Lewati panduan" + konfirmasi).
    - `FishingController.luau:138-142` (`PullCoachSkip` di coachmark tarik) + `coachHidden`.
    - Server `TutorialService.luau:105` (`beatskip`) + `:168` (`skipstep`/`skipall`) → tolak (jangan proses). `guide.skipped` tetap dibaca untuk save lama (jangan hapus field).
    - Locale `tut.skip*` (`id.luau:549-555`) dihapus.
    - Cara Cek: `grep -rn "BeatSkip\|tut.skip\|SkipStep\|SkipAll\|PullCoachSkip\|skipall\|skipstep" src/` = 0 (kecuali komentar baca save lama).
- [ ] **P2-8b Blok NPC selama Tutorial 1 (Bab 16.3).** Selama T1 belum selesai (0:00-10:00): semua NPC kecuali target langkah aktif (Mak Sari `sapa`, Kak Fajar `kak_fajar`/`mancing`, Pak Udin `panen_jual`) → prompt nonaktif + bubble `Selesaikan tutorial dulu`, tanpa toko/dialog/quest/order/hadiah/bantu. Termasuk Nek Ani, Pak Amran, Bang Jali, pedagang Gerobak/Pasar, Tamu.
    - File: `DialogueController.luau` + `NpcService.luau` (prompt), server guard di `ShopService` / `OrderService` / `QuestService` / `SocialService` / `RepeatService` (tolak bila tutorial jalan dan NPC bukan target), Locale 1 key baru.
    - Cara Cek: akun baru → dekati Nek Ani saat langkah Tanam → hanya bubble, tidak ada GUI; Remote `Buy`/`Sell` ke NPC non-target ditolak server.
- [ ] **P2-8c Cutscene Jual Pertama proximity (Bab 16.4).** Sekarang: jual dulu → `OnFirstSellSuccess` (`ShopService.luau:132-139`) → `runWarung` (`T1Ghost.client.luau:1020`) menutup toko lalu cutscene. Ganti jadi: langkah `panen_jual` aktif + dekat Pak Udin (jarak interaksi normal, tanpa klik) → `Cutscene.Begin` + dialog jual Pak Udin yang SUDAH ADA → buka `ShopController` tab Jual yang sama → player jual → GUI ditutup → cutscene selesai → 20 XP → lanjut langkah berikut. Tidak ada jual otomatis, harga tetap 100%, tidak bisa di-skip. Menjauh sebelum trigger = tidak terjadi apa-apa.
    - Catatan: v7.4 tabel 16.2 kasih 20 XP di langkah Jual; kode sekarang `panen_jual` tanpa reward + 20 XP di `t1b.warung`. Pindahkan 20 XP, total XP FTUE jangan berubah.
    - Cara Cek: akun baru → panen → jalan ke Pak Udin → cutscene + GUI Jual terbuka sendiri → jual 1 → tutup → kontrol balik + XP +20.
- [ ] **P2-8d Kolam keluar dari Tutorial 1 (Bab 16.5).**
    - `Onboarding.luau` T1b: hapus langkah `bangun_kolam` + `mancing_kolam` (T1b selesai di `after_catch`). Ganti id `t1b_kolam` → tetap pakai id lama (save lama), judul locale tanpa kata Kolam.
    - `T1Ghost.client.luau:125-132, 536, 592`: hapus baris Mak Sari soal kolam.
    - `TutorialService.luau:151` + `:255`: `kolamUnlocked` TIDAK lagi diset tutorial. Gate kolam = `pond.kakekUnlocked` (MQ4/Bundel) saja → hapus cek `guide.kolamUnlocked` di `PondService.luau:431` (field tetap ada untuk save lama).
    - Tombol Mancing di kolam/`KolamButton` tidak muncul selama T1.
    - Cara Cek: `grep -n "bangun_kolam\|mancing_kolam" src/` = 0; akun baru selesai FTUE → kolam masih terkunci sampai MQ4 Lv 3.
- [ ] **P2-8e Verifikasi saja (tanpa ubah angka):** Order reroll = tier sama (Bab 14.7 v7.4); buff tidak kena kegiatan pasif (Bab 9.4 daftar haram).
- Gap FTUE yang TIDAK dikerjakan (v7.4 bilang "FTUE lama dipertahankan, tidak ada naskah baru"): tabel 16.2 menyebut langkah Beli Bibit Bayam, Nambang 1 node Kayu, Hias Pagar Bambu, Surat #1, Agenda + Gerobak di akhir — FTUE lama di kode tidak punya langkah itu. Lihat §5 #1.

### P2-9. Login Mingguan + Peti Bunga + Title (Bab 15) + Season (Bab 19)

- [ ] Login 7 hari kumulatif + peti + title + Season 2 track
    - File: Service Login/Season baru (`RewardsController` + `ProgressionService` cuma komentar Fase 6; `PlaytimeService` sudah ada).
    - Angka: Login 100/150/200/2B/300/3B/500+5B kumulatif; Peti dari Login/Pencapaian/Album/Season/Event/Bundel (10 Bunga/bangunan)/Robux; Title permanen; Season 30 hari F2P (Koin/bahan/30 Bunga/dekor) + Premium 150 Bunga (kosmetik eksklusif tidak dijual lagi).
    - Cara Cek: klaim Login hari 1-2 + 1 Peti + 1 Title + Season track kebaca di UI.

### P2-10. Blueprint simpan/share (Bab 8.7) + Akuarium / Bingkai Album + FX / Animasi / GUI (Bab 20-23) + KPI / LiveOps (Bab 25-26)

- [ ] Slot simpan 3 + share kode + Akuarium 8 ikan + Bingkai % + partikel/suara/haptic + GUI + log analytics
    - File: simpan/share Blueprint baru (gating sudah dicabut); Akuarium/Bingkai cuma nama di `Unlock` (Lv 25/Lv 15); sisanya Studio (§6).
    - Angka: 3 slot gratis + share kode + ghost per bagian; Akuarium 8 ikan (termasuk Legenda/Jumbo); Bingkai tampilkan % Album; analytics Bab 25.2 (Plant/Water/Harvest/Cast/Bite/PullSuccess/Fish/Feed/Collect/Cook/WarungSale/Bantu/KerjaBakti/Quest/Surat/Album/Login/Playtime/GerobakKaget/PasarMalam); LiveOps Bab 26.
    - Ikut di sini: selene 5 error pre-existing (FarmFloat mismatched_arg_count x2, FishSpotFx / SettingsService / MapService if_same_then_else); Kucing Alun-alun + Joran Hilang (Side quest P2-7, belum ada sistem); decor event final (sekarang Part lampion/gapura sementara).
    - Cara Cek: simpan 1 desain + pakai kode di lahan sendiri (bahan sendiri kepotong); Akuarium isi 1 Legenda; `grep -r "WarungSale\|GerobakKaget" src/` ada hasil.

### Due tanggal

- [ ] Galeri: rumah snapshot read-only bila pemilik offline (sekarang toast offline) — due 2026-11-28.

## 5. BUTUH KEPUTUSAN OWNER / USULAN yang belum di-lock

Semua di bawah sudah jalan di kode sebagai USULAN interim; final ikut playtest Bab 17.8 atau keputusan owner.

1. **FTUE v7.4 tabel 16.2 vs FTUE lama di kode** — tabel menyebut Bayam/Nambang/Hias/Surat/Agenda+Gerobak, kode tidak punya. Tetap FTUE lama (default P2-8) atau tambah langkah?
2. **Cap peluang Super (Bab 9.4 v7.4)** — merujuk cap Bab 17.6 / 5.4, tapi dua bab itu tidak punya angka cap peluang Super. Angka berapa?
3. Album milestone 25/50/75/100% (USULAN di Bab 11).
4. Split reward Agenda (Panen 200 / Pancing 250 / Masak 300 / Bantu 150 / Nambang 400; v7.3 cuma kunci 150-400).
5. XP per pukulan Nambang = 0; suara Critical placeholder (`place_item` pitch-up).
6. Feeder per-ekor (bukan per-kandang); FeedMax 3→5 di Skill lv ≥ 1.
7. Warung 1 slot = 1 jenis + tumpukan; Dapur/Warung auto-place 2x2.
8. Biaya Koin 15.000/skill (Bab 17.4) tidak di-charge (SP saja); Kayu Kuat / Ikan Besar pakai nilai harapan.
9. Firasat bubble dekat Kak Fajar ≤ 25 stud (`Shop.NPC_DISTANCE`).
10. Chat `/e` diblokir; emote Jempol tanpa anim (TODO aset).
11. P2-6: harga varian 2x, Gelang 60/30/10, hadiah Tamu, tanggal Lebaran/Festival, QTY Tamu, pool Pasar; `nightCounter` in-memory.
12. P2-7: Quest Harian 3 + Mingguan 3 + reward Bunga + harga Toko Bunga + syarat Side + hadiah Surat; MQ5/7/8 Bubu/Tungku → Koin 150/200/250; MQ9 slot Warung ke-2 → 200 Koin; Empang = 1 token kolam gratis; Saung buff duduk belum; judul Title MQ11/Side.

### DEV ONLY — hapus / kunci Studio-only sebelum rilis

- Fallback node Nambang di (268,268) bila Hutan tidak punya 6 part `Mining`.
- `!kakek`, `!sp`, `!cuaca` dan perintah `DevService` lain.

## 6. Cek Studio (tidak ada di `src/`)

- [ ] Model NPC 6 (Pak Udin, Kak Fajar, Pak Amran, Mak Sari, Nek Ani, Bang Jali ×8) — rig + posisi + dialog (`ServerStorage.NpcModels`).
- [ ] Hutan Nambang: 6 part `Mining` + `NodeId` (ganti fallback DEV ONLY).
- [ ] Model Akuarium (Lv 25) + Bingkai Album (Lv 15).
- [ ] Model Dapur (Tungku + Meja Olah, Tier 1-3) + Warung Player.
- [ ] Map — SUDAH ADA, JANGAN DIUBAH. Cek saja: alun-alun, 8 lahan simetris, Hutan Nambang, 4 spot (Kanal/Danau/Sungai/Spot 4).
- [ ] Animasi player + hewan + ikan + NPC (Bab 22).
- [ ] Suara + haptic (Bab 20) — Ayam Pagi, jangkrik Sore, kunang Malam, Gerimis/Deres/Petir; haptic panen/Critical/tarik/Legenda; suara Critical crunchy.
- [ ] FPS ≥ 30 di HP 4GB, 8 player, hujan + Kerja Bakti (Bab 24/30.6).
- [ ] Playtest ulang P2-6 (Gerobak restock 15 mnt, Pasar +50% max 10, KB abis Deres) + Order reroll/reset 05:00.

## 7. Cara Verifikasi Tiap Tahap

- `selene src/` — 0 error di file yang disentuh.
- `rojo build default.project.json` — sukses, tidak ada require hilang.
- `grep -rni "mutasi|pelangi|greenhouse|rak pajangan|instant_grow|bibit unggul|backpack pass|blueprint gating" src/` — hanya komentar DIHAPUS.
- Playtest checklist Bab 30 v7.4 (termasuk 4 baris FTUE baru).
