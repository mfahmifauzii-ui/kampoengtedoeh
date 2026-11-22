# Roadmap Kampoeng Tedoeh — Implementasi v7.7

> Sumber kebenaran: `docs/Kampoeng_Tedoeh_v7.7.md` (v7.6, v7.5, dan v7.4 disimpan sebagai arsip). File ini rencana kerja, bukan dokumen desain. Jangan ubah angka di dokumen gameplay dari file ini.
> Dokumen pendamping (2026-11-22):
> - `docs/Quest_Kampoeng_Tedoeh_v0.3.md` — rantai Main / Side Quest + Feature Gate. **Disetujui owner**, jadi acuan quest.
> - `docs/Naskah_Dialog_Kampoeng_Tedoeh_v0.1.md` — naskah tutorial (sudah di kode) + naskah Main / Side Quest.
> - `docs/GUI_Kampoeng_Tedoeh_v0.1.md` — aturan & arahan GUI (mobile-first), target sentuh 24 / 32 / 40, bubble dialog, mockup Season & Pohon Skill.
> Detail file per tugas yang sudah DONE ada di pesan commit (`git log --oneline main..feat/v.7`), tidak diulang di sini.

## 1. Status Ringkasan (2026-11-22)

| Tahap | Status | Sisa |
|-------|--------|------|
| P0 | Done | Bab 29 kelar + Upgrade Tas Koin dihapus (`ce0a7f4`). |
| P1 | Done | 10/10 angka persis v7.3 (`c452303` … `3d1fc7b`). |
| P2 | Jalan | P2-1 s/d P2-9 DONE. **Tutorial (FTUE) DONE sampai jual ikan ke Kak Fajar** (owner 2026-11-22). Q (Quest, §10) **DONE** (Q-1..Q-5, 2026-11-22; Lampiran D #27-#29 dan #31 terbuka; #30 diputuskan). Berikutnya: **UI (GUI, §11)**, lalu P2-10. |
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

1. ~~FTUE tabel 16.2 vs FTUE lama~~ — **DIPUTUSKAN**: FTUE berhenti di jual ikan ke Kak Fajar; Bayam / Nambang / Hias / Surat / Agenda + Gerobak jadi quest (Quest v0.3).
2. ~~Cap peluang Super~~ — **DIPUTUSKAN** (`c0a69b0`): Super dihapus, Buff Tani +10% Bagus, cap Bagus 50% / Prima 20%.
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
13. ~~Jumlah spot sungai~~ — **DIPUTUSKAN** (`faba897`): 32 spot sungai lahan Lv 1 (ikan Early), kanal barat Lv 5, kanal timur Lv 10.
14. ~~Mini-game tarik~~ — **DIPUTUSKAN** (`4fb87e2`): nilai kode berlaku.
15. ~~Coachmark tarik~~ — **DIPUTUSKAN**: tidak dipasang lagi.
16. ~~Layout quest tracker~~ — **DIPUTUSKAN** (`27ccb1f`): tinggi menyesuaikan layar, maks 3 baris + "+N lainnya".
17. **Quest v0.3 Bab 8** — hadiah USULAN (M2, S1, S5, S7–S9) dan asumsi ±1.500 XP/jam: dicek saat playtest Q.
18. **GUI v0.1 Bab 9** — prasyarat skill, kartu pemain pindah ke kiri atas, tombol HUD Dapur dihapus, aset ikon baru, slot Tombol Aksi untuk Craft. Diputuskan sebelum tahap UI terkait.

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
| 1. FTUE klien (Kak Fajar di sungai lahan, NPC klien-only, validasi jual, starter chain) | `fadd5c2` `4f3500f` + Playtest 1–8 (§9.1) | **DONE** (owner 2026-11-22: tutorial sampai jual ikan ke Kak Fajar diterima; starter chain diganti rantai quest §10) | Spot sungai lahan, validasi jual server, starter chain, Agenda, panah: ada di `fadd5c2`. Kak Fajar klien-only: `4f3500f`, `1dfb78a`, `09f5c61`. Lihat Lampiran D #23 | Playtest 8 item 2 (bubble instruksi) dan ulang FTUE dari awal |

Verifikasi build: `rojo build default.project.json` berhasil (exit 0). `selene src`: 4 error, semuanya sudah ada sebelum sesi ini (FarmFloat x2, SettingsService, MapService).

### 9.1 Status Task 1 (per 2026-11-22)

Sudah di kode (commit `fadd5c2` dan `4f3500f`, lalu Playtest 1–8):
- Kak Fajar tutorial sebagai salinan klien di sungai lahan terdekat (`ReplicatedStorage.NpcTutorial`); Kak Fajar server disembunyikan untuk pemain itu saja (`4f3500f`, `1dfb78a`, `09f5c61`).
- Validasi jual ikan di server, dekat spot sungai lahan milik pemain (`fadd5c2`).
- Starter Quest Chain (bayam, nambang, pagar), Agenda terbuka setelah chain (`fadd5c2`).
- Baris dialog Pak Udin tentang Kak Fajar di sungai dekat lahan; panah tutorial ke spot itu (`fadd5c2`, `cceb339`).

Belum jelas dan perlu dicek sebelum Task 1 ditutup:
- Aturan global "bicara dengan NPC dan NPC menoleh pemain = klien-only" (§9 sebelumnya). Tidak ada commit eksplisit untuk ini; belum diverifikasi dari kode di pembaruan ini.
- Lampiran D #23 belum ditutup.
- Playtest 8 item 2 (bubble instruksi, `0f1df4c`) belum kamu konfirmasi.

### 9.2 Log Playtest (urut, dari commit di `feat/v.7`)

| Playtest | Commit | Isi |
|----------|--------|-----|
| 1 | `485ce04` | Pemicu adegan jual Pak Udin pindah ke Heartbeat (cek jarak tiap frame di klien) |
| 2 | `f2e62d8` | `SALE_BEAT_RADIUS` 10 (< `Shop.NPC_DISTANCE` 25), pemain dikunci, penjualan ditolak → bubble diulang |
| 3 | `cceb339` | Salinan Kak Fajar hidup seluruh segmen memancing; panah ke `RiverSpot` |
| 4 | `1dfb78a` | Model Kak Fajar disalin dari `ServerStorage.NpcModels` ke `ReplicatedStorage.NpcTutorial` saat server start |
| 5 | `09f5c61` | Kak Fajar alun-alun disembunyikan lengkap untuk pemain itu, dipindai ulang tiap cek |
| 6 | `5504c5b` | Quest `main`/`side`; banner hanya untuk main; tracker dengan tombol Tunjukkan |
| 7 | `55d7d92`, `43a5306`, `693ff3e`, `77c4547`, `db2931a`, `b7cb781`, `871559e`, `8df87f6` | Quest UI menunggu tutorial; salinan Kak Fajar tidak T-pose dan berdiri di tepi sungai; antrean dialog satu giliran; naskah tutorial bagian 1 ke Locale; balon sisa dibersihkan; teks Mak Sari tidak jadi toast |
| 8 | `a633e92`, `8cd0dfe`, `f80847a`, `0f1df4c` | Salinan Kak Fajar tidak di atas pohon; baris instruksi langkah diganti tanpa Next; bubble instruksi bisa minimize/restore |

Catatan: kolom "Playtest" di atas adalah nomor sesi dari pesan commit, bukan hasil tes baru dari AI di Studio.

## 10. Q — Quest setelah Tutorial (acuan: `Quest_Kampoeng_Tedoeh_v0.3.md`, `Naskah_Dialog_Kampoeng_Tedoeh_v0.1.md` Bab 2–3)

Keputusan owner 2026-11-22: rantai quest v0.3 disetujui apa adanya (Warung Lv 7, Bubu Lv 8, Hias Lv 5, Bang Jali Lv 3, Kolam lewat Kolam Kakek Lv 4). Main Quest = buka gameplay baru atau milestone cerita (MQ11, MQ12), pakai banner. Side Quest = lanjutan gameplay yang sudah terbuka, tanpa banner. Satu task = satu commit.

| Task | Isi | Commit | Cek AI | Playtest USER |
|------|-----|--------|--------|---------------|
| [x] Q-1 Data quest | M1–M9, MQ11, MQ12, S1–S9 + Side Bab 14.4 di `Config/Quests` (kind, giver, after, steps, reward, reveals); quest lama yang diganti dihapus; Bundel Kolam Kakek digabung ke M3; event Report yang kurang ditambah | `0c087b9` + `456b3e6` (fix count) | selene: 0 error baru (4 pre-existing: FarmFloat x2, SettingsService, MapService); rojo build exit 0. `grep -rn "mq[0-9]_\|starter_\|kolam_pertama" src` hanya komentar di QuestController. M8 `blocked` (sistem Bubu tidak ada). Event baru: `talk_*` (NpcService), `sell_bang_jali` (ShopService), `craft_papan` (MiningService), `eat`, `warung_place`, `catch_mid_kanal` / `catch_empang` (FishService), `kandang_*`, `beli_*`, `feed_animal`, `collect_egg` (RanchService), `bundel_sumur_tua`, `harvest_padi`, `buy_seed`, `agenda_done`; UI lewat remote `QuestReport`; kakek lewat `KakekSetor` (belum ada tombol). | Belum dites di Studio. Akun baru dari akhir tutorial: tracker menunjukkan M1 setelah Lv 2; Agenda terbuka saat M1 mulai; M2 "Kumpulkan 10 Batu dan 9 Kayu" langsung lolos kalau barang sudah ada. |
| [x] Q-2 Feature Gate | `PlayerData.features` (introduced / open); tombol & interaksi fitur tidak ada sampai langkah quest-nya; remote ditolak server; level buka fitur diselaraskan (Kolam 4, Bang Jali 3, Warung 7, Bubu 8, Sumur Tua 8, Hias 5) | Commit "Q-2 server: feature gate…" (2026-11-22). Server dan level: `494f65f`. Klien (`Q-2b`, commit ini): `FeatureClient.luau` + `FeatureGate.client.luau`. Sudah digerbang: tombol HUD Dapur, Hias (DecorButton), Bantu (SocialButton), Kolam (KolamButton, tetap + `pondKakek`), Meja Crafting (CraftButton); prompt Kolam dan Kandang (ambil/kelola) lewat atribut `Feature` di server. **Q-2c (klien, sesudah 28b056a):** digerbang: Warung (panel Dapur), Bang Jali (prompt NPC, atribut), Gerobak (tab Acara), Hutan (tombol Pukul tambang), Kanal barat / Empang (tombol Mancing dekat spot), Surat (baris quest, klien saja). **Server-only / belum ada UI klien:** Agenda (`AgendaService`, tidak ada UI klien), Sumur Tua / bundel (`BundelGive` tanpa pemanggil klien), Bubu (M8 diblok, tidak ada tombol). **Q-2d (sesudah Q-2c):** KBPungut (prompt Kerja Bakti) digerbang `gerobak`: atribut `Feature` + `FeatureGate.Check` di Triggered. Surat: gerbang server di `QuestService.onUiReport` (surat_read, Check), `SuratService.Report` (IsUsable, diam), dan toast login `SuratService.Init` (IsUsable). Klien tetap menyembunyikan baris surat. **Status: [x]** karena tiap fitur di FeatureGate punya situs klien atau server-only terdokumentasi: Agenda dan Sumur Tua/bundel server-only (lihat Q-2c), Bubu tertutup sampai M8 (tidak ada tombol, tidak ada pemanggil) | selene: 4 error pra-ada, 0 baru. rojo build exit 0. `FeatureGate.luau` (`Check` / `IsUsable`). `QuestService.syncFeatures` mengisi state dari progres quest (`reveals`). Gerbang server dipasang di: `BundelService.onGive` (bundel), `DapurService.onBuild` / `onCook` (dapur), `DecorService.onPlace` (hias), `MiningService.onHit` (hutan) / `onCraft` (craft), `PondService.onBuild` (kolam), `FishService.onDeposit` / `onWithdraw` / `spotOpen` (kolam, kanal_barat, empang), `RanchService.onKandang` / `onHewan` (kandang_*), `RepeatService.onGerobakBuy` (gerobak), `ShopService.onSell` untuk Bang Jali (jual_bang_jali), `SocialService.onBantu` (bantu), `WarungService.onBuild` / `onDisplay` (warung), `AgendaService.IsOpen` (agenda). Level: Kolam 4 (`Fishing.POND.UNLOCK_LEVEL`), Warung 7 (`Dapur.WARUNG_UNLOCK`), Sumur Tua 8 (`Bundel` sumur_tua), Unlock table diperbarui. Bang Jali 3 dan Hias 5 mengikuti langkah quest S3 / M4 (Lv 3 / Lv 5). Bubu 8 mengikuti M8 yang masih `blocked`. Save version 75. | Klien belum: tombol dan prompt terkunci masih tampil (server menolak). Playtest USER: akun baru tanpa tombol bergerbang; tiap tombol muncul di langkah quest yang benar; remote bergerbang ditolak saat dipanggil manual. |
| [x] Q-3 Alur quest | Quest dengan baris Naskah (`dlg.<prefix>.start.1`) ditawarkan, bukan mulai otomatis: server `QuestService.offeredIds` kirim `QuestOffers`; klien `QuestOfferController` tampilkan `!` di pemberi (sembunyi saat tutorial), dialog Mulai dari Naskah lalu `QuestAccept` (server `onAccept` mulai quest). Main: banner Dimulai/Selesai (`BannerController`, sudah ada) + dialog Selesai dari Naskah. Side: dialog Mulai, lalu toast satu baris pemberi saat selesai (`HudController` mengganti toast judul). Naskah ditambah ke `Locale` (56 kunci `dlg.*`, disalin dari Naskah Bab 2-3). `Locale.has` baru. Bang Jali: `TalkPrompt` dilepas dari gerbang `jual_bang_jali` (koreksi Q-2c: quest s3 memulai dari bicara dengan Bang Jali, gerbang itu hanya terbuka setelah s3 mulai). Tanpa Naskah: side_* dan kolektor (lihat Lampiran D #27). Commit: ini (2026-11-22). | 0e9d488 | selene: 4 error pra-ada, 0 baru. rojo build exit 0. Pemberi dengan tawaran (sesuai Naskah): Nek Ani (M1, M9, S6), Pak Amran (M2, M4, S4), Kak Fajar (M3, MQ11, S5, S9; M8 diblok), Pak Udin (M5, S1, S7, S8), Mak Sari (M6, M7, MQ12-auto, S2), Bang Jali (S3). Gerbang fitur tidak dicek di `!` (tawaran datang dari status quest di server). | USER: (1) akun baru setelah tutorial: `!` muncul di Nek Ani (M1, butuh Lv 2) dan Pak Udin (S1, Lv 1); tidak ada `!` lain. (2) Terima M1: dialog Mulai dulu, lalu banner Dimulai; `!` hilang. (3) Side (S1): dialog Mulai, lalu quest mulai dengan toast, tanpa banner; selesai: toast satu baris pemberi. (4) Selesai Main: banner Selesai lalu dialog penutup pemberi. (5) Tutorial 1: tidak ada `!`. (6) Bang Jali: bisa diajak bicara (S3) sebelum sale. |
| [x] Q-4 Tracker, Quest Log, layer | Tracker: Main di atas, baris 32 px (`UiKit.TOUCH_ROW`), tap baris membuka Quest Log, `Tunjukkan` 24 px (`UiKit.TOUCH_MIN`), maks 3 baris + `+N lainnya` tetap. Quest Log (`QuestController.openLog`, `UiKit.panel`): tab Main / Side (tab kosong tidak digambar), bagian Aktif / Tersedia (dari tawaran server) / Selesai / Berikutnya (`???` sampai level). Dibangun saat dibuka, dihancurkan saat tutup (`UiKit.closePanel`). Layer: `UiKit.LAYER` (sudah ada): panel 40 (`UiKit.panel`, sebelumnya 0 = di bawah HUD), HUD 20 (QuestUI, HudController), banner 80 (`BannerController`, sebelumnya 50), dialog 120 (`T1Dialog`), fade 150 (`FadeManager`), toast 60 (`FeedbackController`, sebelumnya 70), modal 100 dan hadiah 60 di `UiKit`. Commit: 460c204. | 460c204 | selene: 4 error pra-ada, 0 baru. rojo build exit 0. `grep DisplayOrder`: semua hit di file yang disentuh pakai `UiKit.LAYER`. Lampiran D #29 ditutup: 19 hit sisa sudah diganti dengan `UiKit.LAYER` (pemetaan per file di commit message closure layer; layer baru: WORLD_BACK -2, CUTSCENE 110, MENU 200, MENU_PANEL 210, COVER 250). | USER: (1) layar landscape pendek: tracker tidak menutupi kartu XP atau tombol Craft; urutan Main paling atas; ukuran baris 32 px. (2) `Tunjukkan` mengarahkan langkah quest Main (emas 4 dtk). (3) Tap baris membuka Quest Log di tab yang benar; tab Side hilang bila tidak ada quest Side. (4) Panel Quest Log di atas HUD; banner Dimulai/Selesai di atas panel. (5) Tutup panel: tidak ada sisa layar. |
| [x] Q-5 Docs | Bab 6 Quest v0.3 diterapkan ke `docs/Kampoeng_Tedoeh_v7.7.md` (salinan v7.6 + perubahan), Changelog 0.3.4 (Q-1..Q-5, Lampiran D #27-#29), Lampiran D #30 (Kolam Tanah Lv 4, diputuskan owner 2026-11-22) dan #31 (gerbang). v7.6 tidak diubah. Angka yang berubah hanya dari Bab 6 yang sudah disetujui. | Commit ini (2026-11-22). Hash di `git log`. | Cek AI: `git diff -- docs/Kampoeng_Tedoeh_v7.6.md` kosong. Changelog 0.3.4 memuat Q-1..Q-5. Angka cocok dengan kode: `Dapur.WARUNG_UNLOCK` 7, `Fishing.POND.UNLOCK_LEVEL` 4 (berbeda dari #13 Lv 2, lihat Lampiran D #30). | Tidak ada (dokumen). Lampiran D #30 sudah diputuskan (Kolam Tanah Lv 4). |

## 11. UI — Perbaikan GUI (acuan: `GUI_Kampoeng_Tedoeh_v0.1.md`), setelah Q

| Tahap | Isi | Status |
|-------|-----|--------|
| [x] UI-1 Fondasi | Token di UiKit: warna (GOLD, GOLD_DEEP, SHADE, INK_DARK, LOCKED, WATER), teks (TEXT_DISPLAY 36 … TEXT_CAPTION 12), radius (R_SM 8, R_MD 14, R_LG 20, R_ROUND), target sentuh (TOUCH 32 standar, TOUCH_CTA 40, TOUCH_ROW 32, TOUCH_MIN 24, TOUCH_HUD 50 untuk pil HUD). Bubble dialog dua varian (instruksi 48-72 px, percakapan 64-96 px) di `T1Dialog` (`METRICS`, `layoutFor`); minimize / restore instruksi (`0f1df4c`) tidak berubah. Pemakaian `UiKit.TOUCH`: `UiKit.button` (32), `FarmController` Gembor (32), `FarmController` HarvestAll (`TOUCH_CTA` 40), pil HUD `UiKit` (`TOUCH_HUD` 50), pilihan dialog (32). Lampiran D #32 dan #33 (keputusan owner). | Commit: lihat hash di `git log` (commit UI-1 fondasi). | Cek AI: selene 4 error pra-ada, 0 baru (warning style +1, `UDim2` di `T1Dialog`/`UiKit`, bukan error). rojo build exit 0. `grep UiKit.TOUCH`: 4 pemakaian, semua tier 32 (`UiKit.button`, Gembor ukuran dan posisi, pilihan dialog lewat `uiKit.TOUCH`). HarvestAll `TOUCH_CTA`, pil HUD `TOUCH_HUD`. | USER: (1) tombol di HP terasa pas (32 standar, 40 untuk Panen Semua), tidak terlalu kecil untuk jempol. (2) Bubble instruksi kompak dan terbaca, 1-2 baris, tidak menutupi petak / karakter. (3) Bubble percakapan (NPC) kompak, 3 baris maks, Next dan pilihan terlihat. (4) Minimize / restore bubble instruksi tetap jalan (tutup dengan Next, lalu muncul lagi di langkah berikutnya). (5) Tidak ada yang menimpa area thumbstick (kiri bawah). |
| [ ] UI-2 HUD | Ikon Acara / Skill / Hadiah; kartu pemain keluar dari zona thumbstick; satu slot Tombol Aksi; label tombol baru + tekan lama (`attachTip` masih kosong) | Menunggu keputusan §5 #18 |
| [x] UI-3 Hadiah | Hadiah satu panel dengan tab Harian (Peti Main, Login Mingguan), Musim (Season Pass: track horizontal Gratis dan Premium, Premium terkunci selama `PREMIUM_OPEN = false`), Koleksi (Peti Bunga, Title, Milestone Album lewat `BookController.RenderClaims`). Panel dibangun saat dibuka dan dihancurkan saat tutup (`UiKit.closePanel`). Tombol HUD `RewardButton` tetap satu-satunya pintu masuk. Hanya presentasi; remote klaim dan `Config/Rewards` tidak berubah. Belum dibuat (Lampiran D #34): Login sebagai kartu, Peti Main sebagai bar, Klaim Semua. | lihat git log (commit UI-3) | 2026-11-22. Cek AI: selene 4 error pra-ada, 0 baru. rojo build exit 0. `git diff --stat`: hanya `src/client/Controllers/RewardsController.luau`, `BookController.luau` (ekspor `RenderClaims`), dan `src/shared/Locale/id.luau`. Tidak ada `Config/Rewards`, `src/server`, atau remote yang berubah. | USER: (1) tab Harian, Musim, Koleksi berganti dan isinya sesuai. (2) Klaim Harian tetap jalan: Peti Main, Login, Peti Bunga, Title, Milestone Album. (3) Musim: track Gratis bisa digeser ke samping dengan jempol di HP landscape, dan terbuka di hari ini. (4) Premium terkunci (abu) dan tidak ada tombol beli selama `PREMIUM_OPEN = false`. (5) Panel terbuka di atas HUD, tutup dengan X atau tap luar tanpa sisa layar. |
| [ ] UI-4 Skill | Pohon Skill + drawer (mockup Bab 10) | Menunggu keputusan prasyarat skill |
| [ ] UI-5 Stasiun | Dapur + Warung, Meja Crafting, Kandang, Kolam | |
| [ ] UI-6 Lainnya | Acara, Pesanan, Quest Log versi penuh | |

## 12. Bug playtest 2026-11-22

Aturan: satu bug = satu commit, dengan Cara Cek (selene, rojo build, grep / file:baris). Quest (Q-1..Q-5) dan map tidak disentuh.

| Bug | Commit | Cek AI | Playtest USER |
|-----|--------|--------|---------------|
| [x] B-1 Cutscene Kak Fajar telat saat didekati di sungai | `4f4b95b` | selene 0 error (T1Ghost, KakFajarTutorial). rojo build exit 0. Penyebab di kode: gift beat menunggu jalan ke titik berdiri (MoveTo) dan polling sampai 6 dtk sebelum `Cutscene.Begin` (`T1Ghost.client.luau` runGiftBeat); salinan dibangun tiap 0.25 dtk (`KakFajarTutorial` CHECK_SECONDS). Diganti: beat mulai di frame trigger (`Cutscene.Begin` langsung), salinan 0.1 dtk, log `[beat-timing]` (`beatLog`). **Belum diukur di Studio.** | Jalan ke Kak Fajar, catat waktu dari masuk radius sampai kamera pindah. Target < 0.3 dtk. Lihat log `[beat-timing]` di Output. |
| [x] B-2 Tombol ♥ muncul di mana-mana di kebun orang lain | `36fec7d` | selene 0 error baru. rojo build exit 0. `SocialController.plotUnderMe` sekarang cek jarak ke `Sign` plot (12 stud, `LIKE_SIGN_RADIUS`), cek tiap 0.2 dtk (`CHECK_SECONDS`). Sembunyi bila `FishingActive`, `UiKit.anyPanelOpen()`, atau `KTBeatBusy`. `LikeUI.DisplayOrder = UiKit.LAYER.ACTION` (10). | Di sungai dan di jalan depan kebun orang: tombol tidak muncul. Dekat papan "Kebun <nama>": muncul. Saat memancing: tidak tumpang tindih "Tarik!". |
| [x] B-3 Kolam sendiri tidak bisa memancing dan tidak bisa menaruh / mengambil ikan | `38e3624` (server) + `1d1403e` (UI) | selene: 0 error baru (4 pre-existing). rojo build exit 0. Stok per kolam `pond.list[].stock` (`Types.PondEntry`), version 74. `FishService.onDeposit` / `onWithdraw` (remote `PondDeposit` / `PondWithdraw`): cek pemilik, jarak `CAST_DISTANCE`, isi tas, kapasitas `pondCap`. Mancing di kolam = `startPondCast`: ambil acak dari stok, kembali ke stok bila lepas / batal / tas tidak menerima. Timer `collectPond` dan `CollectPrompt` dihapus. Prompt "Kolam" (`PondOpen`) membuka sheet `PondController.rebuildKolam`. Quest: `pond_deposit` per ikan, `catch_pond` tetap. **Catatan:** tas tidak punya kapasitas (`InventoryService.CanAdd` hanya cek item valid), jadi "tas penuh" tidak bisa terjadi; pesan `pond.bag_full` hanya untuk kasus item tidak valid. Feature gate kolam menunggu Q-2. | Setor 3 ikan, ambil 1, mancing di kolam sampai kosong ("Kolam masih kosong"), kolam penuh (10/10) menolak setoran, prompt "Kolam" hilang saat jauh. |
| [x] B-4 Pemain bisa jalan saat memancing | `37f925f` | selene 0 error. rojo build exit 0. `PlayerLock` jadi penghitung hold (`Acquire(reason, humanoidOnly)`), `Set` lama dipertahankan untuk Cutscene / Banner / Fade. `FishingController.holdForFishing` dipasang di status menunggu, dilepas di `showIdle` (semua jalur akhir server kirim `idle`, `FishService.endSession`), tombol X, panel dibuka (loop 0.25 dtk), dan `CharacterRemoving`. Respawn saat memegang: `CharacterAdded` pasang ulang. | Lempar pancing lalu coba jalan dan lompat: tidak bisa. Batal (X), mati, dan buka panel: gerak kembali normal. Kamera tetap bebas. |
| [x] B-5 Memancing hanya di klien, pemain lain tidak melihat | `0b09e6c` (atribut `Fishing`) + `ca5e8e2` (visual server, pembersihan) + `6419190` (klien, pancing tutorial). Kode selesai; belum diuji di Studio. | selene: 4 error pra-ada, 0 baru (FarmFloat x2, SettingsService, MapService). rojo build exit 0 tiap commit. Atribut `Fishing`: `FishService.lua` `endSession` (414), `beginCast` (419), `scheduleBite` (438), `onReel` (667). Visual `Workspace.FishingVisuals`: `startVisuals`, `destroyVisuals`, `watchSession`; pembersihan di `CharacterRemoving` (1063), `PlayerRemoving`, `PlotService.Released`. Animasi: `Fishing.ANIMS` (ID kosong, `playAnim` tidak memutar). Pancing tutorial: `shared/Modules/FishingTutorial.isActive`, dipakai server dan klien (`RodAnimController`, `FishingController`). Arah dan ujung joran (`TIP_FALLBACK`) belum dicek di Studio. | Dengan dua akun: joran, tali, dan pelampung terlihat di akun kedua. Lempar lalu batal (X): visual hilang. Lempar lalu mati: visual hilang, umpan kembali. Lempar lalu jalan > 24 stud: batal (watchdog). Dua pemain di spot berdekatan: dua pelampung terpisah. Animasi: joran pose statis sampai ID permanen dipasang (§12.4). Pancing tutorial Kak Fajar: visual tidak muncul di akun lain (wajar). |
| [x] UI-B1 Teks bubble terpotong (baris ke-3 hilang) | lihat git log | Penyebab: `T1Dialog.layoutFor` menjepit tinggi bubble ke `maxH` (72 instruksi), jadi baris setelah batas terpotong. Sekarang tinggi = teks terukur + padding, tanpa jepitan maks. Naskah panjang melebihi 72 px (tidak dijepit lagi). selene 4 error pra-ada. rojo build exit 0. `T1Dialog.lua` baris `height = math.max(m.minH, ...)`. | USER: bubble instruksi Mak Sari dan Kak Fajar (baris panjang) tampil penuh 3 baris, tidak terpotong. |

### 12.1 Catatan B-1 (dengan waktu)

- Penyebab: gift beat (Kak Fajar di sungai) jalan dulu ke titik berdiri 5 stud di depannya, lalu menunggu sampai 6 dtk sebelum kamera pindah. Trigger sendiri (Heartbeat, radius 10 stud) sudah cepat.
- Penyebab kedua: salinan Kak Fajar dibangun di poll 0.25 dtk. Sebelum itu `T1Dialog.NpcModel` memakai model server yang disembunyikan dan jauh, jadi trigger tertunda.
- Tidak diukur di Studio dari sesi ini. Angka "< 0.3 dtk" harus dicek dengan log `[beat-timing]`.

### 12.2 Catatan B-3 (dead code vs jalan)

- Jalan: "Mancing" di kolam (`FishService.startCast` lewat `FishPrompt`), "Ambil Ikan" (`collectPond`, timer 600 dtk per ikan, offline).
- Tidak dipakai dari sisi desain stok: `collectPond` membuat ikan dari waktu, bukan dari stok. Bila stok jadi sumber, timer harus dihapus atau dibatasi.
- Breeding (`PondController`, `BreedStart/Collect/Instant`) jalan dan tidak terkait stok.
- Yang belum ada: `Deposit`, `Withdraw`, `Catch` dari stok, sheet "Kolam", event kuis M3 "setor 3 ikan Early" lewat kolam.

### 12.4 Rencana B-5 (status: kode selesai, belum diuji di Studio)

**Animasi (B-5, belum diuji di Studio):** ID permanen ada di commit `1ce551c`: memancing di `Config/Fishing.ANIMS` (FishingIdle, FishingCast, FishingReel, FishingCatch), tanam/siram di `Config/Farm.ANIMS` (FarmPlant, FarmWater). `FarmFx` dan `RodAnimController` memakai ID ini dulu dan kembali ke sequence `CustomAnims` hanya bila ID kosong. Checklist playtest ada di bawah.

**Catatan terbuka di luar B-5 (per 2026-11-22):**
- **Bag tanpa kapasitas (B-3).** `InventoryService.CanAdd` hanya cek item valid, jadi "tas penuh" tidak pernah terjadi. Perlu keputusan owner: beri kapasitas tas atau hapus syarat "tas penuh" dari playtest.
- **B-1 belum diukur di Studio.** Target < 0.3 dtk hanya bisa dicek dengan log `[beat-timing]` di Output.
- **Feature gate (Q-2)**: server selesai (`494f65f`), klien sebagian (Q-2b, lihat §10). **Q-3..Q-5** belum dikerjakan; B-3 (gate kolam) sudah ada gerbang klien di tombol Kolam.

Yang sudah ada di server: roll ikan saat lempar (`startCast`), gigitan dengan `task.delay` (server), validasi reel (`REEL_MIN_SECONDS`, skor 0..1), `endSession` untuk semua jalur akhir, dan `PlayerRemoving` membersihkan sesi.

**Status kode (2026-11-22):** selesai: (a) `0b09e6c`, (b) `ca5e8e2`, (c) `6419190`. Perubahan perilaku: server kini membatalkan pancing bila pemain menjauh lebih dari `Fishing.LEAVE_DISTANCE` (24 stud) dari spot (sebelumnya server tidak mengecek jarak saat memancing). ID animasi permanen sudah diisi di `Config/Fishing.ANIMS` dan `Config/Farm.ANIMS` (commit `1ce551c`). Belum ada yang diuji di Studio dari sesi ini.

**Status animasi (2026-11-22):** `KeyframeSequenceProvider:RegisterKeyframeSequence` di Studio mengembalikan ID sementara (hash) untuk FishingCast / FishingIdle / FishingReel / FishingCatch. Dokumen Roblox menulis ID ini hanya berlaku di Studio, bukan untuk server live. Asset ID yang permanen harus dibuat dengan Publish ke Roblox (Animation Editor, atau klik kanan KeyframeSequence > Publish to Roblox). **Update (commit `1ce551c`):** owner sudah Publish, dan ID permanen sudah masuk: FishingCast, FishingIdle, FishingReel, FishingCatch (`Config/Fishing.ANIMS`), FarmPlant dan FarmWater (`Config/Farm.ANIMS`, baru). **Belum diuji di Studio.**

**Playtest USER (animasi, belum diuji):**
- [ ] Tanam: animasi FarmPlant diputar. Siram: animasi FarmWater diputar.
- [ ] Joran memancing: animasi diputar saat lempar (FishingCast), menunggu (FishingIdle), tarik (FishingReel), dan dapat ikan (FishingCatch).
- [ ] Dengan dua akun: pemain kedua melihat joran dan animasi memancing pemain pertama.

### 12.3 Keputusan yang dibutuhkan (B-3, B-5)

1. B-3: timer "Ambil Ikan" dihapus (ikan kolam hanya dari setoran), atau tetap ada sebagai hasil ekstra?
