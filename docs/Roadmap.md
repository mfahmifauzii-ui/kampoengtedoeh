# Roadmap Kampoeng Tedoeh — Implementasi v7.5

> Sumber kebenaran: `docs/Kampoeng_Tedoeh_v7.6.md` (v7.5 dan v7.4 disimpan sebagai arsip). File ini rencana kerja, bukan dokumen desain. Jangan ubah angka di v7.5 dari file ini.
> Detail file per tugas yang sudah DONE ada di pesan commit (`git log --oneline main..feat/v.7`), tidak diulang di sini.

## 1. Status Ringkasan (2026-11-22)

| Tahap | Status | Sisa |
|-------|--------|------|
| P0 | Done | Bab 29 kelar + Upgrade Tas Koin dihapus (`ce0a7f4`). |
| P1 | Done | 10/10 angka persis v7.3 (`c452303` … `3d1fc7b`). |
| P2 | Jalan | P2-1 s/d P2-7 + fix DONE. P2-8 (FTUE v7.4) kode selesai (a-e), **menunggu playtest kamu** (§4). Lalu P2-9 Login/Season, P2-10 Blueprint/Akuarium/FX/KPI. |
| Studio | Belum | §6, tidak ada di `src/`. |

### 1.1 Delta v7.3 → v7.4 (hasil review 2026-11-22)

Angka ekonomi/sistem **tidak ada yang berubah**. v7.4 = v7.3 + doc fix P2-8 untuk FTUE + perapihan teks.

| Bab | Perubahan v7.4 | Dampak ke kode |
|-----|----------------|----------------|
| 16.1 | **No-skip LOCKED**: tidak ada `Lewati` / `Lewati langkah` / `Lewati panduan` / skip cutscene / coachmark / dialog. (v7.3 masih punya Lewati.) | Tombol skip sudah dihapus (P2-8a, kode selesai). |
| 16.2 | Tabel FTUE + kolom "Catatan P2-8". FTUE lama dipertahankan, tidak ada FTUE/naskah baru. Mancing FTUE hanya di dermaga Kanal. | Lihat catatan gap di P2-8. |
| 16.3 (baru) | **Blok NPC selama Tutorial 1**: semua NPC di luar target langkah aktif jawab satu kalimat `Selesaikan tutorial dulu`, tanpa toko/dialog/quest/order/hadiah/bantu. | Sudah di kode (P2-8b, kode selesai). |
| 16.4 (baru) | **Cutscene Jual Pertama proximity**: dekati Pak Udin → cutscene → GUI Jual yang sama dibuka → jual → tutup GUI → cutscene selesai → 20 XP. | Sudah di kode (P2-8c, kode selesai). |
| 16.5 (baru) | **Kolam keluar dari Tutorial 1.** Kolam pertama hanya lewat MQ4 / Bundel Kakek Lv 3. | Sudah di kode (P2-8d, kode selesai). |
| 9.4 | Buff ditulis ulang (isi sama) + baris baru: "Buff + Skill stack, peluang Super tetap dibatasi cap Bab 17.6 / 5.4". | Bab 17.6/5.4 tidak punya angka cap peluang Super → BUTUH KEPUTUSAN OWNER (§5). |
| 9.2, 10.1, 14.7, 0.3, 5, 8.3, 29, 31 | Perapihan teks / pindah paragraf. Order Villager tambah "reroll = tier sama". | Reroll tier sama sudah dicek dari kode (P2-8e). |

### 1.2 Delta v7.4 → v7.5 (2026-11-22, sesi playtest 2)

Dokumen v7.5 mencatat perubahan kode dan GUI yang sudah dikerjakan (Bab 0.3.2) serta deviasi yang belum diputuskan (Lampiran D). Angka desain tidak berubah. Belum di-commit saat tabel ini ditulis; lihat `git log` untuk hash.

| Area | Perubahan | Status | Cek |
|------|-----------|--------|-----|
| Mancing | 32 spot sungai (8 per sungai sumbu), tanpa platform, penanda riak | Kode jadi, owner setuju jumlah. Bertentangan dengan Bab 4 → Lampiran D #1 | `grep -n "RIVER_SPOTS\|buildRiverSpots" src/` |
| Mancing | Prompt dermaga dihapus, tombol Mancing bulat + joran, posisi kanan bawah | Kode jadi | `setupSpot` di FishService, `AksiButton` di FishingController |
| Mancing | Panel reel 260×108, coachmark tarik dihapus, track bingkai bambu, zona & progress glossy | Kode jadi. Nilai balancing belum dites main → Lampiran D #2, #3 | `reelFrame.Size` di FishingController |
| Quest | Tracker tanpa panel, lebar 200, teks krem outline gelap | Kode jadi | `tracker.BackgroundTransparency = 1` di QuestController |
| Font | Semua GUI FredokaOne | Kode jadi (grep `Enum.Font.` = FredokaOne saja) | `grep -rn "Enum.Font\." src/` |
| Craft | Tombol Craft hanya Lv 4+ dan dekat "Meja Crafting" (10 stud), melayang di atas meja | Kode jadi. Butuh objek meja di Studio → Lampiran D #7 | `refreshCraft` di MiningController, `CRAFT_*` di Config/Mining |
| NPC | Bang Jali membelakangi warung mini | Kode jadi | `miniStand` di NpcService |
| Bug | Bubble dialog NPC tidak hilang setelah tutorial | Kode jadi (`clearSink` di T1Ghost) | `NpcTalkOpen` di `clearSink` |
| XP | XP top-up +115 di langkah `jual_ikan` (tutorial 158 XP, 6 bibit = 230 = Lv 2) | Kode jadi, belum playtest → Lampiran D #11 | `reward = { xp = 115 }` di `Config/Onboarding` |
| Quest | Quest menunggu `t1b_kolam` selesai; saat selesai langsung dievaluasi | Kode jadi, belum playtest → Lampiran D #12 | `startAvailable` + `TutorialService.Finished` di QuestService |
| Quest | Quest Kolam tanpa `requireKakek` (mulai Lv 2) | Kode jadi → Lampiran D #13 | `kolam_pertama` di `Config/Quests` |
| Petak | Cangkul petak ke-7+ pakai modal harga (merah + "koin belum cukup" jika kurang) | Kode jadi, belum playtest | `tryTill` di GarapController |
| Petak | Hapus Petak refund 50% hanya untuk petak berbayar (`paid`) | Kode jadi → Lampiran D #14 | `TILE_REFUND_RATE` di `Config/Farm`, `onLevel` di FarmService |
| Galeri | Pemilik offline = lahan kosong; toast dan rumah snapshot dihapus | Kode jadi → Lampiran D #19 | `onVisit` di SocialService |
| Kolam | Bangun kolam terbuka di Lv 2 (`Fishing.POND.UNLOCK_LEVEL`) | Kode jadi → Lampiran D #13 | `PondService`, `InventoryService` (pondKakek) |
| P2-9 | Login Mingguan (ulang tiap minggu), Peti Bunga 25, Title (10, auto dari Album), Season 30 hari F2P + Premium 150 Bunga | Kode jadi, belum playtest → Lampiran D #15–#18 | `Config/Rewards`, `RewardsService`, `RewardsController` |

## 2. Aturan Kerja (LOCKED)

- Kerjakan urut. Satu tahap = satu commit / satu laporan. Jangan campur tahap dalam 1 commit.
- Setiap tugas harus ada "Cara Cek" (grep / file:baris / nilai). Jangan tulis "sudah bener" tanpa cara cek.
- Jangan ubah v7.4.md. Jangan ubah map. Jangan ngarang angka. Angka tidak ada di v7.4 → STOP, tulis di §5 "BUTUH KEPUTUSAN OWNER".
- Selesai 1 tugas: ganti `[ ]` → `[x]`, tulis tanggal + commit + hasil verifikasi (selene / rojo build / grep).
- **Pembagian verifikasi (ditambah 2026-11-22):** tiap item punya dua baris:
  - `Cek AI` = yang aku bisa buktikan dari kode (selene, rojo build, grep, baca file:baris). Aku TIDAK bisa menjalankan Roblox Studio dari sesi ini (tool Studio tidak tersedia), jadi aku tidak mengklaim "sudah dites di Studio".
  - `Playtest USER` = yang hanya bisa dilihat di Studio (alur, tampilan, timing, multiplayer). Ditandai `[ ]` sampai kamu konfirmasi.

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

### P2-8. FTUE v7.5 — Bab 16.1-16.5 (BUKAN rebuild FTUE) — **DONE** (owner accepted 2026-11-22)

Prinsip v7.4: FTUE lama (`Config/Onboarding.luau` T1 `t1_awal` + T1b `t1b_kolam`, `T1Ghost.client.luau`, `GuideController.luau`) dipertahankan. Hanya 4 hal di bawah.

**Pembagian verifikasi (per 2026-11-22):** `Cek AI` = dibuktikan dari kode (selene, rojo build, grep). `Tes AI` = sudah saya jalankan di Studio (Play, lewat tool Studio). `Playtest USER` = yang masih perlu kamu lihat langsung (tampilan, rasa, timing). Semua perubahan **belum di-commit**.

- [x] **P2-8a No-skip (Bab 16.1).** Cek AI: selene 0 error di file yang disentuh, rojo build ok, `grep BeatSkip|tut.skip|SkipStep|SkipAll|PullCoachSkip` = 0 (kecuali komentar). Tes AI: Play → scan seluruh PlayerGui, 0 tombol bertulisan Lewati/Skip. Playtest USER: 1 kali jalan akun baru, cek dialog intro, warung, coachmark tarik, dan panel Tutorial tidak punya tombol skip.
- [x] **P2-8b Blok NPC selama Tutorial 1 (Bab 16.3).** Cek AI: `TutorialService.NpcBlocked` + pemanggilnya di NpcService (prompt), ShopService (Buy/Sell), OrderService (Deliver/Reroll), RepeatService (Gerobak/Pasar/Gelang/Tamu), SocialService (Bantu/Hadiah). Locale `npc.tut_block` = "Selesaikan tutorial dulu". Tes AI: remote `ShopBuy` ke Nek Ani saat step `sapa` → menerima `npc.tut_block` (bukan `shop.too_far`), helper membaca target `mak_sari`. **Catatan jujur:** prompt di dunia masih terlihat; yang diblok adalah interaksinya (server menolak dan menampilkan satu baris). Membuat prompt hilang per pemain perlu kode klien tambahan, belum saya kerjakan. Playtest USER: dekati Nek Ani/Pak Amran saat step Tanam → hanya muncul "Selesaikan tutorial dulu", tidak ada toko/dialog. Dan dekati Mak Sari saat step sapa → dialog tetap jalan.
- [x] **P2-8c Cutscene Jual Pertama proximity (Bab 16.4).** Cek AI: `T1Ghost.runSaleBeat` + `saleBeatDue`, `ShopController.Open(npc, "sell")`, 20 XP pindah dari `t1b.warung` ke `panen_jual` (`Onboarding.luau`), `Cutscene.Begin(..., interactive=true)` tidak kena cek 6 detik. Tes AI (Play): step `panen_jual` + jalan ke Pak Udin → fade, kamera ke Pak Udin, sapaan "Halo, Piko!", lalu GUI Jual terbuka sendiri di tab Jual; jual 1 kangkung → Pak Udin bilang "naik ke Lv 2", kamera kembali. Koin 200 → 255 dan Lv 2. **Belum saya cek angka XP tepat 20** karena XP awal tidak dicatat sebelum jual. Playtest USER: rasa dan tempo cutscene, jarak trigger (18 stud), dan apakah player berhasil menutup GUI Jual setelah jual.
- [x] **P2-8d Kolam keluar dari Tutorial 1 (Bab 16.5).** Cek AI: `Onboarding` T1b hanya 4 langkah (tanpa `bangun_kolam`/`mancing_kolam`), `kolamUnlocked` tidak lagi di-set tutorial, `PondService` gate = `pond.kakekUnlocked` saja, tombol `KolamButton` di dock hanya muncul kalau `pondKakek` true, quest kartu `kolam_pertama` disembunyikan selama T1b. Tes AI (Play): akun baru → `KolamButton` `Visible=false`; `!kakek` → `Visible=true`; `!tut reset` lalu kembali. Playtest USER: selesaikan T1b di akun baru, pastikan tidak ada prompt/tombol kolam, dan kolam baru terbuka di MQ4 Lv 3.
- [x] **P2-8e Verifikasi saja (tanpa ubah angka).** Cek AI (baca kode): reroll Order memakai `newOrder(data)` dengan `data.level`, jadi tier tetap sama. Buff `Buffs.active` hanya dipanggil di FarmService (tani) dan FishService (pancing), tidak di kegiatan pasif. Playtest USER: tidak perlu.

### Revisi dari playtest kamu (2026-11-22, sesi 2)

Sudah dikerjakan (kode + tes AI di Studio, belum di-commit):
- **Siram/tanam tidak bisa di-skip lagi**: step `tanam` hanya selesai dari tanam, `siram` hanya dari menyiram (sebelumnya panen juga menyelesaikannya).
- **Cutscene Pak Udin**: kamera dua-shot memperlihatkan pemain berjalan ke Pak Udin, Pak Udin menoleh, hanya bubble dialog yang tampil, lalu fade. Dites AI: alur berjalan sampai fade dan GUI kembali.
- **Jual lewat bubble**: pilihan "1. Jual semua" di bubble, tanpa GUI jual dan tanpa modal. Dites AI: penjualan terjadi, GUI Jual tidak terbuka.
- **Teks Pak Udin**: "Wah, hasil panenmu bagus ya, kalau ada lagi nanti jangan lupa mampir kesini ya!" (tanpa Lv 2). Dites AI: level tetap 1.
- **Fade setelah Terima Hadiah Kak Fajar** sebelum panah ke spot.
- **Foto Kak Fajar** di bubble setelah tangkapan; teks diganti (tidak lagi menyuruh bikin kolam). Dites AI: foto tampil.
- **Label "Basic Mancing · Terbuka"** disembunyikan; hanya spot terkunci yang punya label. Dites AI.
- **Tombol Mancing** jadi bulat dengan ikon joran di posisi yang kamu tandai (84 px). Dites AI: muncul dan posisinya sesuai.
- **Balancing mini-game**: kiri lebih lambat (0,55 vs 0,9), isi lebih cepat (0,28 vs 0,15), kehilangan lebih kecil (0,06 vs 0,10). **Belum dites main**: nilainya masih tebakan, perlu kamu rasakan.
- **Panel "Menunggu ikan menggigit"** dikecilkan (196x54). Belum dicek visual.
- **Banner Selesai / Dimulai** (Genshin-style): bar hitam masuk, judul emas, pemain dikunci ±3 detik. Dibuat di `BannerController`, **belum dites** di Studio.
- **GUI**: tombol Acara/Skill/Dapur tidak lagi terpotong; tinggi tracker quest dibatasi (200 px) supaya tidak menimpa Craft. Tracker yang dibatasi bisa memotong daftar quest panjang; perlu kamu lihat.

Belum dikerjakan: sisa tumpang tindih GUI di sudut kiri bawah (kartu XP) perlu dicek ulang setelah restart Play.

### Ringkasan playtest untuk kamu (P2-8)

| Bagian | Sudah dites AI di Studio | Perlu kamu playtest |
|---|---|---|
| 8a tombol skip hilang | Ya (scan GUI) | Dialog intro + coachmark, sekali jalan penuh |
| 8b NPC diblok | Ya (remote ditolak + pesan) | Rasa pesan & apakah prompt terasa "mati" |
| 8c Jual Pertama | Ya (alur sampai Lv 2) | Cutscene, tempo, jarak trigger, XP 20 tepat |
| 8d kolam keluar T1 | Ya (tombol dok) | Akun baru sampai akhir T1b + MQ4 |
| 8e verifikasi | Kode | tidak perlu |

- Gap FTUE yang TIDAK dikerjakan (v7.4 bilang "FTUE lama dipertahankan, tidak ada naskah baru"): tabel 16.2 menyebut langkah Beli Bibit Bayam, Nambang 1 node Kayu, Hias Pagar Bambu, Surat #1, Agenda + Gerobak di akhir — FTUE lama di kode tidak punya langkah itu. Lihat §5 #1.

### P2-9. Login Mingguan + Peti Bunga + Title (Bab 15) + Season (Bab 19)

- [x] Login 7 hari kumulatif (diulang tiap minggu) + peti + title + Season 2 track — **kode jadi, belum playtest** (angka usulan di Lampiran D #15–#18)
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

- [x] Galeri: pemilik offline = lahan kosong, tidak ada toast, tidak ada rumah snapshot. **Dihapus** (keputusan owner 2026-11-22, Lampiran D #19). Tidak ada due date lagi.

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
13. **v7.5 — jumlah spot sungai**: 32 spot tambahan (8 per sungai sumbu) bertentangan dengan Bab 4 ("Empat spot mancing"). Diterima sebagai bagian dokumen, atau dokumen direvisi?
14. **v7.5 — mini-game tarik**: kode pakai isi +28%/detik, kehilangan -6%/detik, kiri 0,55 / kanan 0,9. Dokumen Bab 6.2 bilang +15% / -10%. Nilai mana yang berlaku setelah playtest?
15. **v7.5 — coachmark tarik**: frame "Tahan Tarik! Jaga ikan…" dihapus atas permintaan owner. Dipasang lagi di FTUE, atau dokumen direvisi?
16. **v7.5 — layout quest tracker**: batas tinggi 200 px tidak menyesuaikan layar. Tracker menyesuaikan layar, atau tombol Craft/elemen lain yang pindah?

### DEV ONLY — hapus / kunci Studio-only sebelum rilis

- Fallback node Nambang di (268,268) bila Hutan tidak punya 6 part `Mining`.
- `!kakek`, `!sp`, `!cuaca` dan perintah `DevService` lain.

## 6. Cek Studio (tidak ada di `src/`)

- [ ] Model NPC 6 (Pak Udin, Kak Fajar, Pak Amran, Mak Sari, Nek Ani, Bang Jali ×8) — rig + posisi + dialog (`ServerStorage.NpcModels`).
- [ ] Hutan Nambang: 6 part `Mining` + `NodeId` (ganti fallback DEV ONLY).
- [ ] Model Akuarium (Lv 25) + Bingkai Album (Lv 15).
- [ ] Objek **"Meja Crafting"** di Workspace (nama persis, part atau model) — tombol Craft tidak muncul tanpa ini (`CRAFT_TABLE` di Config/Mining).
- [ ] Spot sungai (32): terlihat dari jarak normal, riak tampil, tidak tertutup pagar lahan. Panah tutorial `sungai` tidak salah arah (Lampiran D #4).
- [ ] Model Dapur (Tungku + Meja Olah, Tier 1-3) + Warung Player.
- [ ] Map — SUDAH ADA, JANGAN DIUBAH. Cek saja: alun-alun, 8 lahan simetris, Hutan Nambang, 4 spot (Kanal/Danau/Sungai/Spot 4).
- [ ] Animasi player + hewan + ikan + NPC (Bab 22).
- [ ] Suara + haptic (Bab 20) — Ayam Pagi, jangkrik Sore, kunang Malam, Gerimis/Deres/Petir; haptic panen/Critical/tarik/Legenda; suara Critical crunchy.
- [ ] FPS ≥ 30 di HP 4GB, 8 player, hujan + Kerja Bakti (Bab 24/30.6).
- [ ] Playtest ulang P2-6 (Gerobak restock 15 mnt, Pasar +50% max 10, KB abis Deres) + Order reroll/reset 05:00.

## 7. Orchestrator (skill `roblox-build-orchestrator`)

- Ledger: `build-runs/kt-v7-sisa/` (run dari root project). Setiap tahap: `run_log.py start --stage <s>` → kerja → `run_log.py end --stage <s> --status ok|fell-back`. Stall 30 menit → fallback + `event --kind fallback`.
- **Spine (satu thread, semua tulis Studio/`src/` di sini):** `p2-8-ftue` → `p2-9-login-season` → `p2-10-code` → `assembly-playtest` → `publish`.
- **Fan-out (worker, tulis file ke disk saja, tanpa Studio):** `ui` (panel Login/Season/Blueprint/Akuarium) · `3d-meshes` (Akuarium, Bingkai, Dapur, Warung, decor event) · `animation` (Bab 22 + emote Jempol) · `vfx` (Bab 21/23) · `sfx` (Critical crunchy + ambience Bab 20). Jalan setelah spec P2-9/P2-10 ada. **Tidak ada worker map** (map JANGAN diubah).
- Run selesai hanya bila `run_log.py debts` bersih. 9 debt lama (fallback P2-1..P2-7 + repo) sudah tercatat di ledger.

## 8. Cara Verifikasi Tiap Tahap

- `selene src/` — 0 error di file yang disentuh.
- `rojo build default.project.json` — sukses, tidak ada require hilang.
- `grep -rni "mutasi|pelangi|greenhouse|rak pajangan|instant_grow|bibit unggul|backpack pass|blueprint gating" src/` — hanya komentar DIHAPUS.
- Playtest checklist Bab 30 v7.4 (termasuk 4 baris FTUE baru).

## 9. Task Owner 2026-11-22 (Task 1–7, di branch `feat/v.7`)

Dokumen acuan: `docs/Kampoeng_Tedoeh_v7.6.md` (Changelog 0.3.3). Aturan: satu task = satu commit, ada "Cara Cek", tidak mengubah map fisik di Studio, angka tidak dikarang (yang belum ada masuk Lampiran D).

| Task | Commit | Status | Cara Cek (hasil) | Playtest USER |
|------|--------|--------|------------------|---------------|
| P2-8 pending + sesi ini | `e34e7fc` | Kode jadi | selene: 0 error di file yang disentuh | Lihat FTUE sampai jual ikan |
| 4. Mini-game tarik (dokumen) | `4fb87e2` | Dokumen | `grep FILL_GAIN src/client/Controllers/FishingController.luau` = 0.28, cocok dengan Bab 6.2 | Tidak perlu, nilai sudah diterima |
| 5. Quest tracker | `27ccb1f` | Kode jadi | selene 0 error; `grep MAX_ROWS`, `quest.more` ada | Cek tracker tidak menimpa kartu XP di kiri bawah pada layar landscape pendek |
| 3. Super dihapus, kualitas cap | `c0a69b0` | Kode jadi | selene 0 error; `grep -i super src` tinggal komentar dan `ftue_super` (sengaja, agar save tidak berubah) | Panen Bagus / Prima dan Buff Tani +10% |
| 2. Sungai lahan, kanal barat Lv 5, kanal timur Lv 10 | `faba897` | Kode jadi | selene 0 error; `grep "sungai_lahan"` di Config/Fish dan Fishing | Naik Lv 5 untuk mancing di kanal barat; spot sungai lahan terbuka di Lv 1 |
| 6. Peti / Title / Season | `efdebdc` | Kode jadi | selene 0 error; Title dari kode; Season Premium `PREMIUM_OPEN = false` | Cek peti dari Title, Album 25/50/75/100%, dan Season hari 30 |
| 7. Docs v7.6 | `1025e46` | Sebagian | Lampiran D ditutup / dibuka; Changelog 0.3.3 | Baca Changelog 0.3.3 |
| 1. FTUE klien (Kak Fajar di sungai lahan, NPC klien-only, validasi jual, starter chain) | — | **BELUM DIKERJAKAN** | Lihat Lampiran D #23 | Setelah dikerjakan |

Verifikasi build: `rojo build default.project.json` berhasil (exit 0). `selene src`: 4 error, semuanya sudah ada sebelum sesi ini (FarmFloat x2, SettingsService, MapService).

### Sisa untuk dikerjakan (Task 1, belum di kode)
- Kak Fajar tutorial sebagai NPC klien di sungai lahan terdekat (klon dari ReplicatedStorage), sembunyikan Kak Fajar server untuk pemain itu saja.
- Aturan global: bicara dengan NPC dan NPC menoleh pemain = klien-only.
- Validasi jual ikan di server (langkah `jual_ikan` + dekat sungai lahan milik pemain, posisi dihitung di server).
- Event starter chain: tanam Bayam, buka Surat #1. Agenda + Gerobak setelah chain.
- Pak Udin: baris dialog bahwa Kak Fajar ada di sungai dekat lahan.
- Panah tutorial ke sungai lahan terdekat (Lampiran D #4).
