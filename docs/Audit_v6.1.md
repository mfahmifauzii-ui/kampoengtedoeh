# Audit Proyek vs Gameplay v6.1 (Bab 3–29)

> Sumber kebenaran: `docs/Kampoeng_Tedoeh_Gameplay_Lengkap_v6.1.md`. Dokumen ini hanya audit. **Belum ada kode yang diubah dan belum ada yang dihapus.**
> Dibuat 20 Nov 2026 dengan membaca `src/` (scripts, Config, Locale, default.project.json). Isi `Workspace` (peta, model, GUI) tidak ada di repo (ada di file .rbxl Studio), jadi bagian peta & GUI hanya bisa dicek di Studio. Setiap "❓" perlu dicek di Studio.

Legenda: ✅ ada & cocok, keep · ⚠️ ada tapi konflik, harus diubah · ❌ belum ada, build nanti · 🗑 kandidat hapus/ganti (belum dihapus)

---

## Ringkasan

| Area | Kondisi |
|------|---------|
| Fondasi | Cocok: ProfileStore (session lock + autosave + BindToClose), struktur Config per modul, StreamingEnabled, WorldClock, tutorial engine, Economy config. |
| Dunia & peta | Alun-alun dengan beringin & 8 shophouse sudah ada (keep). Lahan 8, bukan 10. Lahan awal 128 stud, bukan 96. Belum ada kondisi awal ilalang & 5 bangunan rusak. |
| Konten | Tanaman 8/18, ikan 12/20, hewan 0/3, dekor 30/80, resep 0/9, joran 4/6. Belum ada Dapur, Ternak, Bubu, Nambang, Gerobak, Pasar Malam, Kerja Bakti, Event penuh, Surat Kakek, Bundel Kakek, Mutasi, Legenda pity. |
| NPC | **Nama lama masih dipakai** (Pak Darmo, Mbok Minah, Mas Joko). Belum ada Mak Sari, Pak Udin, Bang Jali, Kak Fajar, Pak Amran, Nek Ani, Pedagang Tamu. |
| Monetisasi | **Ada pelanggaran keras:** produk Robux → Koin (Bab 29). Pass "offline pond" menjual kapasitas kolam (Bab 18.5). |
| Level | Cap 30 (v6.1: 60). Rumus XP beda. Tidak ada Level Cabang / Skill Point. |
| Hari & reset | Siklus 24 menit (v6.1: 30). Reset harian 00:00 WIB (v6.1: 05:00 WIB). |
| Gotong Royong global | Tidak ada di kode (bagus, tetap dijaga). |

---

## Tabel per Bab

### Bab 3 — Dunia, Lahan, Server, Waktu & Cuaca

| Bagian | Status | Detail | Aksi |
|--------|--------|--------|------|
| 3.1 Server max 10 | ⚠️ | `Plots.COUNT` = 8, komentar minta Max Players = 8. | Ubah ke 10, atau kurangi lahan (lihat TODO T-01). |
| 3.1 Lahan 10 melingkar | ⚠️ | Ada 8 lahan (2 per sumbu jalan). | Keputusan T-01. |
| 3.1 Alun-alun + beringin tengah | ✅ | `Map.luau` TOWN, `MapService.buildBanyan`, 8 SHOPS melingkar. | Keep (sesuai instruksi). |
| 3.1 Pos Ronda, Gerobak, Papan Agenda/Galeri/Lapak, pelataran event, 80 titik spawn kotoran | ❌ | Tidak ada. | Tambah (lihat Fase 7). |
| 3.1 Lahan awal 96×96 | ⚠️ | `Plots.START = 128`, `REGION = 192`. | Keputusan T-02. |
| 3.1 Ekspansi 120/140/160 | ❌ | Ada sistem chunk 32 stud (`Plots.CHUNK`), beda model. | Ganti ke 3 tahap ekspansi (Bab 17.4). |
| 3.1 Grid 2×2 stud | ⚠️ | `Land.TILE = 8` (grid 8 stud). | Ubah ke 2 stud, atau dokumentasikan. Keputusan T-03. |
| 3.1 Hutan Nambang | ⚠️ | Ada "hutan" di pojok (`LandService`, `MapService`) sebagai dekor tanah kosong, belum node nambang. | Bangun Hutan + node per-player. |
| 3.1 Perairan: Kanal, Danau, Sungai, 4 spot | ⚠️ | Spot ada tapi namanya `sungai`, `empang`, `kolam`. Tidak ada Kanal, Danau, Spot 4. | Ubah nama & jumlah spot (lihat Bab 6). |
| 3.2 Hari game 30 menit (3/15/3/9) | ⚠️ | `World.CYCLE`: pagi 5, siang 8, sore 4, malam 7 (= 24 menit). | Ubah ke 3/15/3/9 di Config/World. |
| 3.2 Reset harian 05:00 WIB | ⚠️ | `Progression.UTC_OFFSET` = 7 jam, reset 00:00 WIB. | Tambah offset 5 jam untuk reset harian. Dipakai di semua sistem reset (Fase 6). |
| 3.2 HUD ikon fase (bukan jam) | ❓ | Perlu cek HUD. | Cek di Studio. |
| 3.3 Cuaca: Terik 8–15 → Hujan 3 menit, tidak hujan 2× | ⚠️ | `World.RAIN`: roll 25% tiap 20 menit, hujan 4–6 menit. Tidak ada state Terik/Hujan. | Ganti dengan state machine sesuai Bab 3.3. |
| 3.3 Jenis Gerimis/Deres/Petir/Pelangi | ❌ | Hanya satu jenis hujan (visual). | Build. Tidak ada efek gameplay per jenis. |
| 3.3 Mutasi Embun/Petir + Pelangi | ❌ | Tidak ada. | Build (Fase 2). |
| 3.4 Kondisi awal lahan (ilalang 40, semak 12, batu 8, tunggul 4, 5 bangunan rusak, bitmask) | ❌ | Tidak ada. | Build (Fase 0 + Fase 5). |

### Bab 4 — Mata Uang & Level

| Bagian | Status | Detail | Aksi |
|--------|--------|--------|------|
| 4.1 Koin, Bunga | ✅ | `Economy.START_KOIN = 100`, `START_BUNGA = 10`. | Cocokkan nilai start dengan v6.1 (tidak disebut di v6.1, perlu konfirmasi). |
| 4.1 Bahan mentah (7) & olahan (7) | ⚠️ | Ada sebagai item (`Bambu` muncul di 19 file), tapi bukan 7+7 sesuai Bab 8.2. Belum ada Ijuk, Tanah Liat, Pasir, Jerami sebagai bahan. | Verifikasi di `Config/Inventory` / `Modules/Items`. |
| 4.1 Skill Point (SP) | ❌ | Tidak ada. | Build (Fase 0 / Fase 8). |
| 4.2 Level Player cap 60 | ⚠️ | `Progression.MAX_LEVEL = 30`. | Ubah ke 60. |
| 4.2 Level Cabang (Bertani, Mancing, Beternak, Tukang) | ❌ | Tidak ada. | Build (Fase 0). |
| 4.3 Rumus XP `200 + 30×n` | ⚠️ | `xpToNext = 20·L^1.5 + 10·(L−8)^2.1`. | Ganti rumus (Config/Progression). |
| 4.4 Tabel buka konten per Lv | ⚠️ | Unlock tersebar di setiap config (`unlockLevel`). Tidak ada Config/Unlock terpusat. | Buat `Config/Unlock` sesuai Bab 4.4. |
| 4.5 Skill cabang (16 skill) | ❌ | Tidak ada. | Build (Fase 8 atau 10). |

### Bab 5 — NANEM

| Bagian | Status | Detail | Aksi |
|--------|--------|--------|------|
| 5.1 Loop tanam/siram/panen | ⚠️ | Ada, tapi lahan dibajak bebas (Garap), bukan petak tetap. Siram kurangi waktu 20% (v6.1: 15%) dan tidak ada tanda Basah sekali per siklus. | Sesuaikan ke v6.1 atau putuskan (T-04). |
| 5.1 Telat panen scale 1,1 | ❌ | Tidak ada. | Build. |
| 5.2 Petak 6 awal, max 36, harga n×150 | ⚠️ | Model "tile bebas" (`MAX_TILES = 100`). Tidak ada petak berbayar. | Keputusan T-04. |
| 5.2 Greenhouse | ❌ | Tidak ada. | Build (Fase 8 atau nanti). |
| 5.3 Tanaman rilis 18 | ⚠️ | 8 tanaman, harga & waktu berbeda (`Config/Crops`). Contoh: Kangkung 60 dtk & jual 8 (v6.1: 4 mnt & jual 25). | Ganti isi Config/Crops ke tabel 5.3. |
| 5.4 Mutasi (Embun/Petir/Emas/Pelangi) | ❌ | Tidak ada. | Build (Fase 2). |
| 5.4 Banner server Mutasi | ❌ | Tidak ada. | Build (Fase 2). |
| 5.5 Pasar Harian +30% | ❌ | Tidak ada. | Build (Fase 7). |
| 5.5 Rotasi +5% XP | ❌ | Tidak ada. | Build. |
| 5.5 Orang-orangan Sawah | ❌ | Tidak ada (dekor Berkah belum ada). | Build (Fase 4). |

### Bab 6 — MANCING

| Bagian | Status | Detail | Aksi |
|--------|--------|--------|------|
| 6.1 Loop lempar/tunggu/gigitan/tarik | ⚠️ | `FishingController` & `FishService` ada. Waktu gigitan & jendela 1,5 dtk perlu dicek. | Cek di Studio (Fase 3). |
| 6.1 Lapak Kak Fajar di pinggir Kanal | ⚠️ | Kak Fajar tidak ada. Umpan & rod dijual Mas Joko (`Npcs`). | Ganti NPC & pindah ke Kanal. |
| 6.1 Jalan >8 stud = pancingan ketarik | ❓ | Perlu cek. | Cek. |
| 6.2 Mini-game tarik (kotak +15%, ikan lawan arah) | ❓ | Perlu cek di FishingController. | Cek; sesuaikan ke Bab 6.2. |
| 6.2 Mode Bantu (default OFF) | ❌ | Tidak ada. | Build (Bab 23.3 Settings). |
| 6.3 Joran 6 tingkat (Bambu, Kayu, Kayu Jati, Bambu Wulung, Besi, Pusaka) | ⚠️ | 4 joran (Bambu, Rotan, Fiber, Juragan) dengan harga & syarat lain. | Ganti ke 6 joran Bab 6.3. |
| 6.3 Umpan 4 (Cacing, Jangkrik, Pelet, Udang Kecil) | ⚠️ | Ada `bait`/`pelet`. Jenis & efek beda. | Ganti ke Bab 6.3. |
| 6.4 Ikan 20 (Early/Mid/Late/Legenda) | ⚠️ | 12 ikan, tier C/U/R/L, nama beda (Wader, Nila, Mas, Bawal, Gurame, Udang Galah, Koi, Arwana). | Ganti isi Config/Fish ke tabel 6.4. Nama Koi & Udang Galah tidak ada di v6.1. |
| 6.4 Berat Kecil/Sedang/Besar/Jumbo | ⚠️ | `Fish.SIZES` ada, multiplier beda. | Sesuaikan. |
| 6.5 Legenda 3 (Gurame Raja, Belut Emas, Ikan Dewa) + pity 200 | ❌ | Hanya 1 Legenda (Arwana). Tidak ada pity. | Build (Fase 3). |
| 6.5 Pengumuman Legenda ke server | ❌ | Tidak ada. | Build (Fase 3 + Fase 2 banner). |
| 6.6 Bubu (3 tipe, overnight 6 jam) | ❌ | Tidak ada. | Build (Fase 5). |

### Bab 7 — TERNAK + KOLAM

| Bagian | Status | Detail | Aksi |
|--------|--------|--------|------|
| 7.1 Ternak darat (Ayam, Bebek, Sapi) | ❌ | Tidak ada hewan & kandang. | Build (Fase 5). |
| 7.1 Tempat Pakan (jatah siklus) | ❌ | Tidak ada. | Build (Fase 5). |
| 7.1 Pakan Jagung | ❌ | Tidak ada. | Build (Fase 5). |
| 7.2 Kolam (Tanah / Semen / Keramik, max 4) | ⚠️ | `PondService` + `pond` upgrade 2 tingkat. Tidak ada breeding, tidak ada pakan ikan, tidak ada Kolam Kakek. | Ganti / tambah sesuai 7.2. |
| 7.2 Kapasitas kolam (dijual di Game Pass) | ⚠️ | `Monetization.PASSES.offline` = "2× pond capacity". | 🗑 Hapus pass ini (Bab 18.5 melarang jual slot kolam). |

### Bab 8 — NAMBANG, CRAFTING, HIAS

| Bagian | Status | Detail | Aksi |
|--------|--------|--------|------|
| 8.1 Hutan Nambang node per-player, ritme pukul | ❌ | Tidak ada. | Build (Fase 4). |
| 8.2 Crafting (Papan, Bata, Semen, Anyaman, dll) | ❌ | Tidak ada meja crafting. | Build (Fase 4). |
| 8.3 Menu Hias (80 piece, 12 warna, 4 material, ghost, undo 10) | ⚠️ | `Config/Decor` 30 item, `DecorService`, `DecorGrid`. Undo, warna & material belum dicek. | Tambah ke 80 piece. Cek sisanya. |
| 8.3 Cap 800 piece per lahan | ❓ | Cek `DecorService`. | Cek. |
| 8.3 Mode tembus dinding | ❓ | Cek. | Cek. |
| 8.4 Dekor Berkah (30 dengan stat) | ❌ | Tidak ada dekor dengan stat. | Build (Fase 4). |
| 8.5 Set Dekor (4 set) | ❌ | Tidak ada. | Build (Fase 4 atau 8). |
| 8.6 Pajangan (Rak, Akuarium, Bingkai Album) | ❌ | Tidak ada. | Build (Fase 8). |
| 8.7 Blueprint (3 slot gratis, bagikan kode) | ⚠️ | `Config/Blueprints` ada, dijual Mbak Arsi. Slot & bagi kode belum ada. | Sesuaikan. |
| 8.7 Visit (Mampir) | ✅ | `Social` VISIT_OFFSET, `SocialService`. | Keep. Cek aturan "tidak bisa bangun/hapus/ambil". |
| 8.7 Like (1× per lahan, +20 Koin max 10/hari) | ⚠️ | Like ada, tapi hadiah = Bunga 3/10/25 di milestone (`Social`). Hadiah per like belum ada. | Ubah ke Bab 8.7. |
| 8.7 Galeri Kampung (papan 5 lahan) | ❌ | Tidak ada. | Build (Fase 7). |
| 8.7 Lomba Hias bulanan | ❌ | Tidak ada. | Build nanti (LiveOps). |

### Bab 9 — DAPUR

| Bagian | Status | Detail | Aksi |
|--------|--------|--------|------|
| 9 Inti Dapur (Tungku, 3 tier) | ❌ | Tidak ada. | Build (Fase 5). |
| 9 Resep 9 | ❌ | Tidak ada. | Build (Fase 5 & 8). |
| 9 Warung Mak Sari (beli olahan 100%) | ⚠️ | Warung ada tapi dipegang Pak Darmo, dan jual hasil mentah, bukan olahan. | Ubah ke Mak Sari, jual olahan. |

### Bab 10 — NPC & SISTEM JUAL

| Bagian | Status | Detail | Aksi |
|--------|--------|--------|------|
| 10.1 Mak Sari | ❌ | Tidak ada. | Build (Fase 1). |
| 10.1 Pak Udin | ⚠️ | Tidak ada. Bu Wati jual bibit unggul, Mas Joko jual alat pancing. | Gabung ke Pak Udin. |
| 10.1 Bang Jali (beli semua 90%) | ❌ | Tidak ada. | Build (Fase 1). |
| 10.1 Kak Fajar | ❌ | Tidak ada. | Build (Fase 3). |
| 10.1 Pak Amran | ⚠️ | Mbak Arsi (tukang, jual blueprint). | Ganti nama & peran ke Pak Amran. |
| 10.1 Nek Ani | ❌ | Tidak ada. | Build (Fase 7). |
| 10.1 Kakek Daeng (hanya lewat surat) | ❌ | Tidak ada. | Build (Fase 6). |
| 10.1 Pedagang Tamu | ❌ | Tidak ada. | Build (Fase 7). |
| 10.1 Tamu Event | ❌ | Tidak ada. | Build (Fase 7). |
| 10.1 **Nama lama dilarang** | ⚠️ | `pak_darmo` (22 file), `mbok_minah` (13), `mas_joko` (13) masih dipakai. | 🗑 Ganti nama. Lihat T-05. |
| 10.1 Bang Tarno ×8 (Warung Mini) | 🗑 | Tidak ada di v6.1. | Hapus atau ganti (Bang Jali ada satu). Lihat T-06. |
| 10.2 Tabel jual | ⚠️ | Pak Darmo beli hasil 100% tapi ada kuota harian (20/tanaman). Mbok Minah beli ikan 100%. Bang Tarno 90% hasil tanam. Di v6.1 tidak ada kuota. | Sesuaikan. Kuota Pak Darmo dihapus. |
| 10.2 Bubble "Tunjukin jalan" | ❌ | Tidak ada. | Build. |

### Bab 11 — ALBUM KAMPUNG

| Bagian | Status | Detail | Aksi |
|--------|--------|--------|------|
| 11 Album (254 entri: Ladang, Sungai, Kandang, Rumah, Dapur) | ⚠️ | `Book.luau` ada, kategori dibangkitkan dari crops/fish/decor. Tanpa Mutasi, Kandang, Dapur. | Ganti kategori (Fase 2, 3, 4, 5). |
| 11 Milestone 25/50/75/100% → Bunga + dekor + title | ⚠️ | Ada claim, tapi isi hadiah belum sesuai Bab 15.3. | Sesuaikan. |
| 11 Kartu Album "Bagikan" | ❌ | Tidak ada. | Build (nanti). |

### Bab 12 — SOSIAL

| Bagian | Status | Detail | Aksi |
|--------|--------|--------|------|
| 12.2 Bantu tetangga (siram/panen lahan teman, batas 1+1 per lahan, 5 lahan/hari) | ❌ | Ada "help" di beberapa file, tapi bukan fitur ini. | Build (Fase 7). |
| 12.3 Kirim Hadiah (3/hari, max 500 Koin nilai, Lv 20) | ❌ | Tidak ada fitur kirim hadiah. Kata "Kirim" dipakai di dialog/orders lain. | Build (Fase 7). |
| 12.4 Lapak Tetangga (4 slot, harga 80–130%, pajak 5%) | ❌ | Tidak ada. Hanya `Lapak Tarno` (lama). | Build (Fase 7). |
| 12.5 Gestur 4 (Lambai, Jempol, Tepuk, Ketawa) | ⚠️ | `Social.EMOTES` = Roblox built-in: wave, cheer, point, **dance**. "dance" = joget, dilarang (Bab 12.5 dan Bab 29). | 🗑 Hapus `dance` & `point`. Ganti dengan 4 gestur v6.1 + ikon di atas kepala. |
| 12.6 Chat bawaan Roblox | ✅ | Game tidak buat chat sendiri. | Keep. |
| 12.6 Bubble Cepat (8 kalimat) | ❌ | Tidak ada. | Build (Fase 7). |

### Bab 13 — EVENT BERULANG

| Bagian | Status | Detail | Aksi |
|--------|--------|--------|------|
| 13.1 Gerobak Kaget (restock 15 menit, 3 slot) | ❌ | Tidak ada. | Build (Fase 7). |
| 13.1 Bibit Varian (6) & Hewan Varian (2) | ❌ | Tidak ada (tanaman Varian belum ada). | Build (Fase 8). |
| 13.2 Pasar Malam + Pedagang Tamu + Lempar Gelang | ❌ | Tidak ada. | Build (Fase 7). |
| 13.3 Hari Hujan Petir (Sabtu 19–20 WIB) | ❌ | Tidak ada. | Build (LiveOps, Fase 2 + 7). |
| 13.4 Kerja Bakti Kilat (dipicu hujan Deres/Petir) | ❌ | Tidak ada. Gotong Royong global juga tidak ada (bagus). | Build (Fase 7). |
| 13.5 Event Musiman + Pesanan Tamu + Toko Tamu | ⚠️ | `Config/Events` hanya "lebaran 2027", hanya dekor berbayar. Tidak ada hiasan alun-alun, tamu, pesanan, Toko Tamu, mini-game. | Ganti dengan sistem Bab 13.5. |
| 13.5 Config Events: event bisa dinyalakan/dimatikan lewat Config saja | ✅ | `Events.luau`: data-driven. | Keep, dan perluas. |
| "Pesanan Harian" (Orders) — 5 warga (pak_rt, bu_sari, dll) | ⚠️ | `Config/Orders` & `OrderService`. Mirip Agenda Harian tapi aturannya beda. Nama NPC tidak ada di v6.1. | Ganti ke Agenda Harian Bab 14.4. |

### Bab 14 — QUEST

| Bagian | Status | Detail | Aksi |
|--------|--------|--------|------|
| 14 Tabel quest (jenis & aturan) | ⚠️ | `Config/Quests`: "misi_utama", "kolam_pertama", tanam/panen/pancing. | Ganti dengan MQ1–MQ12. |
| 14.1 MQ1–MQ12 | ❌ | MQ belum ada. | Build (Fase 1, 3, 5, 6, 7). |
| 14.2 Surat Kakek 30 | ❌ | Tidak ada. | Build (Fase 6). |
| 14.3 Side Quest 10 | ⚠️ | Quest samping belum ada sesuai daftar. | Build (Fase 6). |
| 14.4 Agenda Harian (5 tugas, selesai 3 → bonus) | ❌ | Tidak ada (Orders berbeda). | Build (Fase 6). |
| 14.5 Bundel Kakek (5 bangunan + setoran cicil) | ❌ | Tidak ada. | Build (Fase 5). |

### Bab 15 — HADIAH & PROGRESI

| Bagian | Status | Detail | Aksi |
|--------|--------|--------|------|
| 15.1 Login Mingguan 7 hari (kumulatif) | ⚠️ | `Progression.VISIT_REWARDS` (7 langkah, kumulatif) mirip, tapi isi beda, dan ada Bunga 3 di hari 7 (v6.1: 10 Bunga). Reset per 7 hari tidak sejalan dengan Senin 05:00. | Ganti ke Login Mingguan Bab 15.1. |
| 15.2 Hadiah Waktu Bermain (10/30/60 menit, Koin saja) | ⚠️ | `Progression.PLAYTIME`: 6 peti (5–60 menit), ada **Bunga 1 & 2** dan pelet (v6.1: tanpa Bunga). | 🗑 Bunga dari playtime dihapus. Ubah ke 3 peti Bab 15.2. |
| 15.3 Peti Bunga (7 hari setelah klaim, 20 Bunga) | ❌ | Tidak ada. | Build (Fase 6). |
| 15.3 Pencapaian (11 kategori, Tier 1–3) | ❌ | Tidak ada. Hanya milestone level & like. | Build (Fase 6). |
| 15.4 Title (Dari Pencapaian) | ⚠️ | 29 file menyebut Title. Milestone level 20 & 30 memberi title lama (`petani_rajin`, `sesepuh_kampung`). | Ganti isi title ke Bab 15.4. |
| 15.5 Peta Progresi | ❌ | Tidak ada. | Build (Fase 6). |
| Level milestone Bunga (`LEVEL_UP_REWARD` bunga 2, `LEVEL_MILESTONES` bunga 10/15/25) | ⚠️ | Bunga dari level-up **tidak** ada di Bab 4.1 (sumber Bunga). | 🗑 Hapus Bunga dari level-up & milestone. Ganti ke Koin atau hadiah v6.1. |

### Bab 16 — TUTORIAL & FTUE

| Bagian | Status | Detail | Aksi |
|--------|--------|--------|------|
| 16.1–16.2 Prinsip & aturan skip (Lewati, coachmark 20 dtk, 1 aturan) | ✅ | `Onboarding` + `TutorialService` + `CoachmarkController` (`Lewati` ada di 23 file). | Keep. Verifikasi aturan 20 dtk & posisi 16px. |
| 16.3 FTUE 4 menit (Pulang Kampung, Mak Sari, Gerimis tutorial, Super + Embun dijamin, Pak Amran, Rumah Jadi) | ⚠️ | T1 ada, isi & NPC beda (Mbak Arsi, Mas Joko, Bu Wati). Tidak ada Gerimis tutorial, tidak ada jaminan Super+Embun. | Tulis ulang T1 (Fase 1 & 3). |
| 16.3 Cutscene ≤6 dtk (3 buah) | ⚠️ | `Cutscene.luau` ada. Isi belum sesuai. | Sesuaikan (Fase 1). |
| 16.4 Tutorial lanjutan MQ4–MQ8 | ❌ | Tidak ada. | Build (Fase 5). |

### Bab 17 — EKONOMI

| Bagian | Status | Detail | Aksi |
|--------|--------|--------|------|
| 17.1 Semua angka di Config | ⚠️ | Sebagian besar sudah di Config. Tapi ada angka hardcode di komentar/logic lama (contoh: `MINI_BUY_MULT = 0.9` di Npcs). | Audit angka di Fase 0. |
| 17.2–17.4 Faucet, sink, porsi Koin | ❌ | Angka beda total. | Ganti semua harga sesuai Bab 17.4. |
| 17.5 Alat Koin (Gembor, Sabit, Sepatu, Kapak) | ⚠️ | Gembor ada (`Farm.TOOLS`), beda harga & efek. | Ganti ke Bab 17.5. |
| 17.6 Cap bonus 25% per jenis | ❌ | Tidak ada sistem stat bonus. | Build (Fase 4 + 6). |
| 17.8 Validasi ekonomi | ❌ | Tidak ada. | Playtest (Fase 10). |

### Bab 18 — MONETISASI

| Bagian | Status | Detail | Aksi |
|--------|--------|--------|------|
| 18.1 Prinsip Bunga = gaya/kenyamanan | ⚠️ | `Monetization.PRODUCTS` sudah punya `instant_grow`. | Sesuaikan. |
| 18.3 Paket Bunga (49/99/229 Robux → 50/120/300) | ⚠️ | Angka beda dari Bab 18.4 (49→55, 129→160, dst). | Ganti ke tabel 18.4. |
| **18.4 Paket Robux → Koin** (`koin_s/m/l`, 25/75/199 Robux) | 🗑 **LANGGAR Bab 29** | "Robux → Koin" dilarang. | **Hapus.** Prioritas tertinggi. |
| 18.4 Paket Pemula (1× seumur akun) | ❌ | Tidak ada. | Build (Fase 9). |
| 18.4 Game Pass (Tas Besar 149, Lapak Besar 199, Buku Blueprint 99, Pemutar Musik 79) | ⚠️ | Ada 4 pass, tapi isi beda: `backpack` 99 (+40 slot), `decor` 149 (+100 limit), `plots` 199 (diskon 20% lahan). | Sesuaikan ke Bab 18.4. |
| 18.4 Pass "offline" 2× kapasitas kolam | 🗑 **LANGGAR Bab 18.5** | Menjual slot kolam. | Hapus. |
| 18.4 Pass "plots" diskon 20% lahan | ⚠️ | Diskon ekspansi lahan tidak ada di v6.1. Berisiko jadi pay-to-win ringan. | Hapus atau ganti. Keputusan T-07. |
| 18.4 Pass "decor" +100 limit dekor | ⚠️ | Tidak ada di v6.1 (cap 800 piece per lahan, tidak bisa dibeli). | Hapus. Keputusan T-07. |
| 18.4 Private Server | ❌ | Fitur Roblox, bisa diaktifkan lewat setting. | Cek saat Fase 9. |
| 18.5 Instant Grow (tanaman, olahan, kolam; kurva Bunga) | ⚠️ | Ada `instant_grow` 15 Robux per token, limit 3/hari. Model v6.1 pakai Bunga, kurva 0/1/12/30/50. | Ganti ke Bunga + kurva Bab 18.3. |
| 18.5 "Premium Order Koin ×1,1" | ⚠️ | `PREMIUM_ORDER_KOIN_MULT`. Bab 19 melarang boost Koin per jam Premium. | Hapus. |
| 18.5 Yang TIDAK dijual (loot box, skip bangun, dll) | ✅ | Tidak ada loot box/gacha. | Keep. |

### Bab 19 — SEASON PASS

| Bagian | Status | Detail | Aksi |
|--------|--------|--------|------|
| 19 Season Pass (28 hari, 30 level, Free/Premium/Premium+) | ❌ | Tidak ada. | Build (Fase 9). |

### Bab 20 — EXPERIENCE

| Bagian | Status | Detail | Aksi |
|--------|--------|--------|------|
| 20.1–20.2 SFX & rasa | ⚠️ | `Sfx`, `SoundBank`, `AudioController` ada. Belum sesuai tabel. | Sesuaikan Fase 10. |
| 20.2 Haptic 5 momen | ❌ | Tidak ada haptic. | Build (Fase 10). |
| 20.2 Volume default SFX 70 / Musik 30 / Ambient 50 | ❓ | Cek `Config/Audio`. | Cek. |
| 20.2 Tidak ada suara gagal / merah "GAGAL!" | ❓ | Cek `FeedbackController`. | Cek. |

### Bab 21 — EFFECTS

| Bagian | Status | Detail | Aksi |
|--------|--------|--------|------|
| 21.1 Cap partikel 120, glow 6, setting Hidup/Kurang/Mati | ❌ | `Vfx.luau` ada (partikel dibuat per efek, tanpa cap global). Tidak ada setting efek. | Build cap & setting (Fase 10). |
| 21.2 Tabel efek (~30 aksi) | ⚠️ | Hanya sebagian efek ada (`Vfx`). Mutasi, Legenda, Kerja Bakti, Bundel belum. | Build per fase. |
| 21.3 Cahaya & cuaca global (Gerimis/Deres/Petir/Pelangi, kilat ≤0,1 dtk, 1×/20 dtk) | ❌ | Lighting ada per phase & hujan. Kilat petir & tipe cuaca belum. | Build (Fase 2). |

### Bab 22 — ANIMASI

| Bagian | Status | Detail | Aksi |
|--------|--------|--------|------|
| 22.1 Tween, tidak ada teleport | ❓ | Perlu cek. NPC `NpcService` menaruh NPC langsung di posisi (teleport?). | Cek. |
| 22.2 Animasi player (tanam, siram, panen, lempar, tarik, ...) | ⚠️ | `RodAnimController` ada. Animasi lain belum. | Build per fase. |
| 22.3 NPC jalan ke player (Mak Sari MQ4/MQ7, Pak Amran FTUE) | ❌ | Tidak ada. | Build (Fase 1, 5). |
| 22.4 Tanaman sway, Ayam, Bebek, Sapi, Ikan kolam | ❌ | Tidak ada (belum ada hewan). | Build (Fase 5). |
| 22.5 UI tween (Back Out pop-up, toast slide) | ❓ | `UiKit` ada. Cek. | Cek. |

### Bab 23 — GUI

| Bagian | Status | Detail | Aksi |
|--------|--------|--------|------|
| 23.1 Zona Roblox | ❓ | Cek di Studio. | Cek. |
| 23.2 HUD Final (pil Koin+Bunga, profil+Lv+fase+cuaca, tracker Agenda, bawah 5 tombol, Aksi 72×72) | ⚠️ | `HudController` ada, tapi tata letak belum tentu sama. Tidak ada tracker Agenda, tidak ada fase & cuaca di HUD. | Cek di Studio, lalu buat ulang sesuai 23.2. |
| 23.2 Kerja Bakti tracker | ❌ | Belum ada sistemnya. | Build (Fase 7). |
| 23.3 Menu Utama (Tas, Hias, Agenda, Sosial, Peta, Profil, Bunga Shop, Settings) | ⚠️ | Ada Book, Shop, Decor, Orders, Quest, Settings, dll. Belum sesuai. | Ubah struktur menu (Fase 0 HUD). |
| 23.4 Toko & Penjual (Tab Beli/Jual, Gerobak tab) | ⚠️ | `ShopController` ada. Tab Gerobak belum. | Sesuaikan. |
| 23.5 Dialog & coachmark (≤2 baris, font 14) | ❓ | `DialogueController`. Cek. | Cek. |

### Bab 24 — PERFORMA HP 4GB

| Bagian | Status | Detail | Aksi |
|--------|--------|--------|------|
| StreamingEnabled ON | ✅ | `default.project.json` `$properties StreamingEnabled: true`. | Keep. Cek radius 256/96. |
| LOD lahan jauh >160 stud | ❌ | Tidak ada. | Build (Fase 4 / 10). |
| Tanpa Union untuk bangunan | ✅ | Tidak ada `UnionOperation` di `src` (tidak bisa dicek isi `.rbxl`). | Cek Workspace. |
| Semua Anchored | ❓ | Cek di Studio. | Cek. |
| Save Hias padat 12 byte, Base64 | ❌ | Belum ada save Hias array. Save sekarang per item (`decor.placed`). | Build (Fase 4). |
| Cap partikel 120 & glow 6 | ❌ | Tidak ada. | Build (Fase 10). |
| Hewan max 22 per lahan | ❌ | Belum ada hewan. | Build (Fase 5). |
| Kotoran Kerja Bakti max 70 | ❌ | Belum ada. | Build (Fase 7). |

### Bab 25 — KPI & ANALYTICS

| Bagian | Status | Detail | Aksi |
|--------|--------|--------|------|
| 25.2 Event log wajib (25+ event) | ⚠️ | `AnalyticsHooks` hanya log funnel onboarding. Event lain belum. | Build (sesuai fase). |
| 25.2 Pakai AnalyticsService | ✅ | `AnalyticsHooks` sudah pakai `AnalyticsService`. | Keep. |

### Bab 26 — LIVEOPS

| Bagian | Status | Detail | Aksi |
|--------|--------|--------|------|
| 26 Jadwal (gerobak, malam, badai, harian, mingguan, season, update) | ❌ | Belum ada. | Build (Fase 7 & 9). Update 1 & 2 **tidak** dikerjakan sekarang. |

### Bab 27 — ROADMAP

Lihat bagian "Rencana" di bawah.

### Bab 28 — STRUKTUR DATA & CONFIG

| Bagian | Status | Detail | Aksi |
|--------|--------|--------|------|
| `PlayerData` version 61 | ⚠️ | `DataTemplate.version = 13`. Struktur jauh berbeda (koin, bunga, farm, fishing, tools, pond, decor, orders, quests, visits). | Susun ulang sesuai Bab 28 + migrasi (`Data/Migrations`). Keputusan T-08. |
| Config/Tanaman, Config/Ikan, Config/Hias, Config/Quest, Config/Event | ⚠️ | Ada dengan nama Inggris: `Crops`, `Fish`, `Decor`, `Quests`, `Events`. | Rename di Fase 0 (atau pakai nama lama, lihat T-09). |
| Config/Economy | ✅ | Ada. | Keep, isi sesuai v6.1. |
| Config/Weather | ⚠️ | Ada sebagai bagian `Config/World`. | Pisah dan ubah (Fase 2). |
| Config/Unlock, Hewan, Resep, Set, Mutasi, Legenda, Gerobak, Surat, Title, Pencapaian, Season, BungaShop, Instant, LahanAwal, Bundel, KerjaBakti | ❌ | Belum ada. | Build sesuai fase. |
| Config/Map, Plots, Npcs, Shop, Social, Orders, Farm, Fishing, Inventory, Buffs, Book, Blueprints, Audio, UiAssets | ✅/⚠️ | Ada, tapi isi beda. Config ini tidak ada di Bab 28 (boleh, asal angka dari Config). | Keep sebagai Config tambahan, isi disesuaikan. |
| Global DataStore `Lapak_<UserId>`, `Galeri_<WeekId>` | ❌ | Belum ada. | Build (Fase 7). |

### Bab 29 — LARANGAN KERAS

| Larangan | Status | Di mana |
|----------|--------|---------|
| Robux → Koin | 🗑 **LANGGAR** | `Monetization.PRODUCTS` `koin_s/m/l`. |
| Menjual slot kolam | 🗑 **LANGGAR** | `Monetization.PASSES.offline`. |
| Hadiah playtime berisi Bunga | 🗑 **LANGGAR** | `Progression.PLAYTIME` (Bunga 1 & 2). |
| Bunga dari level-up / milestone (tidak ada di sumber Bunga Bab 4.1) | 🗑 **Melanggar Prinsip #12 & Bab 4.1** | `Progression.LEVEL_UP_REWARD`, `LEVEL_MILESTONES`. |
| Gestur joget (dance) | 🗑 **LANGGAR** | `Social.EMOTES`. |
| Nama NPC lama | 🗑 **LANGGAR** | `Npcs.lua` (pak_darmo, mbok_minah, mas_joko, dll). |
| Streak login yang reset | ✅ aman | Login pakai kumulatif (`visits.count`). |
| Kelangkaan per server | ✅ aman | Tidak ada. |
| Kerja Bakti / Gotong Royong global | ✅ aman | Belum ada. |
| Bunga ↔ Koin | ✅ aman | Tidak ada tukar. |
| Pupuk, hama | ✅ aman | Tidak ada. |
| Tanaman / hewan mati | ✅ aman | Belum ada hewan. Tanaman tidak mati. |
| Dekor Berkah > 25% | ❌ | Belum ada, nanti dibatasi. |
| Loot box / gacha / iklan | ✅ aman | Tidak ada. |
| Instant untuk Bubu/Ternak | ✅ aman | Belum ada. |

---

## Yang Harus Diubah / Dihapus (Belum Dihapus)

Tandai untuk dihapus atau diganti saat fase terkait. **Tidak ada yang dihapus sekarang.**

| # | Item | Lokasi | Tindakan | Prioritas |
|---|------|--------|----------|-----------|
| D-01 | Produk Robux → Koin (`koin_s/m/l`) | `Config/Monetization` | Hapus | Tinggi (langgar Bab 29) |
| D-02 | Game Pass "offline" (2× kapasitas kolam) | `Config/Monetization` | Hapus | Tinggi (langgar Bab 18.5) |
| D-03 | Gestur `dance` & `point` | `Config/Social` (EMOTES) | Ganti 4 gestur v6.1 | Tinggi |
| D-04 | Bunga dari PLAYTIME (1 & 2) | `Config/Progression` | Ganti ke Koin saja, 3 peti | Tinggi |
| D-05 | Bunga dari LEVEL_UP & LEVEL_MILESTONES | `Config/Progression` | Hapus Bunga | Tinggi |
| D-06 | NPC nama lama: Pak Darmo, Mbok Minah, Mas Joko | `Config/Npcs`, Locale, `NpcService`, `ShopService`, dll | Ganti ke Mak Sari, Pak Udin, Kak Fajar, dst. | Tinggi |
| D-07 | Bang Tarno ×8 (Warung Mini), Lapak Tarno | `Config/Npcs`, `MapService` | Hapus, ganti Bang Jali | Sedang |
| D-08 | Kuota harian Pak Darmo | `Config/Npcs` QUOTA | Hapus | Sedang |
| D-09 | Pass "decor" (+100 limit) & "plots" (diskon 20%) | `Config/Monetization` | Hapus | Sedang |
| D-10 | PREMIUM_ORDER_KOIN_MULT (boost Koin Premium) | `Config/Monetization` | Hapus | Sedang |
| D-11 | Visit reward Bunga 3 | `Config/Progression` VISIT_REWARDS | Ganti ke Surat Kakek / Login Mingguan | Sedang |
| D-12 | Mode konten lama: Orders (5 warga) | `Config/Orders`, `OrderService` | Ganti ke Agenda Harian | Sedang |
| D-13 | Quest lama (misi_utama, kolam_pertama, tanam/panen/pancing) | `Config/Quests` | Ganti ke MQ1–MQ12 | Sedang |
| D-14 | `Config/Events` lebaran 2027 (dekor-only) | `Config/Events` | Ganti ke kalender Bab 13.5 | Rendah |
| D-15 | Rain acak 25%/20 menit | `Config/World` RAIN | Ganti ke state machine Bab 3.3 | Sedang (Fase 2) |
| D-16 | Siklus hari 5/8/4/7 menit | `Config/World` CYCLE | Ubah ke 3/15/3/9 | Rendah |
| D-17 | Reset harian 00:00 WIB | `Config/Progression` UTC_OFFSET | Ubah ke 05:00 WIB | Sedang (Fase 6) |
| D-18 | Rumus XP lama & MAX_LEVEL 30 | `Config/Progression` | Ganti ke 200+30n, cap 60 | Sedang (Fase 0) |
| D-19 | Joran 4 & umpan lama | `Config/Fishing` | Ganti ke 6 joran Bab 6.3 | Sedang (Fase 3) |
| D-20 | Tanaman 8 & ikan 12 (isi config) | `Config/Crops`, `Config/Fish` | Ganti ke 18 & 20 | Sedang (Fase 1, 3, 8) |
| D-21 | Playtime: 6 peti sampai 60 menit | `Config/Progression` | Ganti ke 3 peti Bab 15.2 | Rendah |
| D-22 | Pass `backpack` 99 & isi Game Pass | `Config/Monetization` | Sesuaikan ke Bab 18.4 | Rendah |
| D-23 | Paket Bunga harga/jumlah beda | `Config/Monetization` | Sesuaikan ke Bab 18.4 | Rendah |
| D-24 | `DataTemplate.version = 13` & struktur lama | `Data/DataTemplate` | Migrasi ke Bab 28 | Tinggi (Fase 0) |

---

## Rencana (Peta Bab 27 → Tugas Konkret)

Aturan: urut dari Fase 0. Setiap angka dari Config. Fase berikutnya tidak dimulai sebelum Definition of Done lolos.

### Fase 0 — Fondasi

| Tugas | File | Catatan |
|-------|------|---------|
| Ganti `Config/Progression` ke Bab 4.2–4.3 (cap 60, rumus XP, Level Cabang) | `shared/Config/Progression.luau` | Hapus D-05, D-18 |
| Tambah `Config/Unlock` (tabel Bab 4.4) | `shared/Config/Unlock.luau` (baru) | |
| Ubah `Config/World` ke hari 3/15/3/9 & reset 05:00 WIB | `shared/Config/World.luau`, `Progression.luau` | D-16, D-17 |
| Susun ulang `DataTemplate` ke Bab 28 + migrasi | `shared/Config/DataTemplate.luau`, `server/Data/Migrations.luau` | D-24. Tidak ada save lama yang harus dijaga (perlu konfirmasi, lihat T-08) |
| Tambah `Config/LahanAwal` + bitmask 64 bit | `shared/Config/LahanAwal.luau` (baru), `server/Services/PlotService.luau` | Bab 3.4 |
| Tambah `ServerClock` (hari game) | `shared/Modules/WorldClock.luau` (sudah ada), `server/Services/WorldService.luau` | Cek ulang |
| HUD kosong sesuai Bab 23.2 | `client/Controllers/HudController.luau` | Cek di Studio |
| Lahan 96×96 (T-02) | `shared/Config/Plots.luau` | Keputusan dulu |

**Definition of Done:** masuk-keluar tanpa hilang data (ProfileStore test), hari game jalan, reset 05:00 WIB benar, HUD tidak nabrak tombol Roblox, lahan awal ilalang & 5 bangunan rusak muncul (kosong tapi bitmask bekerja).

### Fase 1 — Nanem + FTUE bagian 1

| Tugas | File | Catatan |
|-------|------|---------|
| Ganti isi Config/Crops ke 6 tanaman pertama (Kangkung, Bayam, Tomat, Sawi, Jagung, Ubi) + sisanya nanti | `shared/Config/Crops.luau` | D-20 |
| Petak 6 awal, buka petak `n×150` (Bab 5.2) | `shared/Config/Farm.luau`, `FarmService` | Keputusan T-04 |
| Pak Udin, Bang Jali, Mak Sari (NPC baru) | `shared/Config/Npcs.luau`, `NpcService`, Locale | D-06, D-07 |
| Siram & Super (5%, +5% Basah) | `FarmService` | |
| FTUE 0:00–1:40 | `shared/Config/Onboarding.luau` (T1) | Bab 16.3 |

**DoD:** timer offline benar, FTUE nanem < 2 menit.

### Fase 2 — Cuaca + Mutasi

| Tugas | File | Catatan |
|-------|------|---------|
| State machine cuaca (Terik 8–15, Hujan 3, tidak 2× hujan, Pelangi 40% 60 dtk) | `shared/Config/World.luau`, `server/Services/WorldService.luau` | D-15 |
| Jenis hujan Gerimis/Deres/Petir + efek | `WorldService`, `WorldController` | Bab 3.3 |
| Mutasi (Embun, Petir, Emas, Pelangi) saat panen | `FarmService`, `Config/Mutasi` (baru) | Bab 5.4 |
| Banner server Mutasi Pelangi/Emas | `client/Controllers/FeedbackController` | |
| Album tab Ladang (120 entri) | `Config/Book`, `BookService` | Bab 11 |

**DoD:** siklus cuaca sesuai, mutasi muncul sesuai syarat, banner tampil di semua client.

### Fase 3 — Mancing

| Tugas | File | Catatan |
|-------|------|---------|
| Spot Kanal, Danau, Sungai, Spot 4 | `shared/Config/Map.luau`, `Fishing` | Spot lama diganti nama |
| 20 ikan & 6 joran & umpan (Bab 6) | `Config/Fish`, `Config/Fishing` | D-19, D-20 |
| Kak Fajar + lapak (jual umpan, beli ikan 100%) | `Npcs.luau`, `ShopService` | |
| Legenda 3 + pity 200 (per player) | `FishService`, `Config/Legenda` (baru) | Bab 6.5 |
| Pengumuman Legenda ke server | `FishService`, banner | |
| Mini-game tarik & Mode Bantu | `FishingController` | Cek dulu |
| FTUE mancing (2:00) | `Onboarding` | |

**DoD:** 20 tangkapan tanpa bug, pity tercatat per player.

### Fase 4 — Hias + Nambang

| Tugas | File | Catatan |
|-------|------|---------|
| Hutan Nambang + node per-player + ritme pukul | `server/Services/` baru (`NambangService`), `client/Controllers/` baru | Bab 8.1 |
| Crafting (Meja, 7 olahan) | `Config/Resep` (baru), `CraftService` | |
| Menu Hias 40 piece (dari 30 yang ada), refund, cap 800 | `DecorService`, `DecorController`, `Config/Decor` | D-20 |
| Dekor Berkah (30 dengan stat) & set | `Config/Decor`, `Config/Set` (baru) | Cap 25% |
| Save Hias array padat (12 byte, Base64) | `DecorService` | Bab 24 |
| FTUE rumah (3:00) | `Onboarding` | Bab 16.3 |
| Visit + Like (hadiah 20 Koin) | `SocialService`, `Social.luau` | Bab 8.7 |

**DoD:** bangun rumah kecil, save-load 800 piece < 1 dtk.

### Fase 5 — Ternak + Kolam + Bubu + Dapur

| Tugas | File | Catatan |
|-------|------|---------|
| Ayam, Bebek, Sapi + Kandang + Tempat Pakan | `Config/Hewan` (baru), `LivestockService` | Bab 7.1 |
| Kolam (Tanah/Semen/Keramik) + breeding + Kolam Kakek | `PondService`, `Config/Kolam` (baru) | D-19 area. Bab 7.2 |
| Bubu (3 tipe, 6 jam) | `Config/Bubu` (baru), `BubuService` | Bab 6.6 |
| Dapur Tier 1–2 + 9 resep | `Config/Resep`, `CookService` | Bab 9 |
| MQ4–MQ8 | `Config/Quests` | D-13 |
| `BundelService` + Kolam Kakek + Sumur Tua | `Config/Bundel` (baru), `BundelService` | Bab 14.5 |

**DoD:** semua loop pasif jalan offline, setoran Bundel tersimpan walau dicicil lintas sesi.

### Fase 6 — Quest & Retensi

| Tugas | File | Catatan |
|-------|------|---------|
| Main Quest MQ1–MQ12 | `Config/Quests` | D-13 |
| Surat Kakek (30) | `Config/Surat` (baru), `SuratService` | Bab 14.2 |
| Agenda Harian (5 tugas, 05:00 WIB) | `Config/Agenda` (baru), `AgendaService` | D-12 |
| Side Quest 10 | `Config/Quests` | |
| Login Mingguan + Playtime (3 peti) | `Config/Progression` | D-04, D-11 |
| Peti Bunga + Pencapaian + Title | `Config/Pencapaian` (baru), `Config/Title` (baru) | Bab 15.3–15.4 |
| Peta Progresi | `client/Controllers/` | |

**DoD:** reset 05:00 WIB benar di semua sistem.

### Fase 7 — Sosial & Event

| Tugas | File | Catatan |
|-------|------|---------|
| Bantu Tetangga | `SocialService` | Bab 12.2 |
| Kotak Pos + Kirim Hadiah | `SocialService`, `Config/Social` | Bab 12.3 |
| Lapak Tetangga (DataStore global `Lapak_<UserId>`) | `LapakService` | Bab 12.4 |
| Gestur 4 + Bubble Cepat | `Config/Social` | D-03 |
| Gerobak Kaget (15 menit) | `Config/Gerobak` (baru), `GerobakService` | Bab 13.1 |
| Pasar Malam | `Config/PasarMalam` (baru) | Bab 13.2 |
| Kerja Bakti Kilat (memori server + PlayerData) | `Config/KerjaBakti` (baru), `KerjaBaktiService` | Bab 13.4 |
| Event Musiman + Pesanan Tamu (Agustusan) | `Config/Events` | D-14 |
| Pos Ronda Nek Ani, Papan Agenda/Galeri/Lapak, pelataran event, 80 titik spawn | `MapService` | Map tetap |

**DoD:** Kerja Bakti 100% bisa dicapai 1 player sendirian, batas 4 hadiah/hari tercatat di PlayerData, Lapak tidak bisa duplikasi item, event bisa nyala/mati hanya lewat Config.

### Fase 8 — Konten Lengkap Rilis

| Tugas | File | Catatan |
|-------|------|---------|
| 18 tanaman, 20 ikan, Sapi, 80 piece, 9 resep, 4 Set, Pajangan, Album lengkap | Config terkait | D-20 |
| Bundel Lumbung + Saung + Empang & Dermaga | `Config/Bundel` | |
| Skill Cabang (16 skill) | `Config/Skill` (baru) | Bab 4.5 |

**DoD:** semua unlock sesuai Bab 4.4, 5 Bundel bisa dipulihkan.

### Fase 9 — Monetisasi

| Tugas | File | Catatan |
|-------|------|---------|
| Hapus D-01, D-02, D-09, D-10 | `Config/Monetization` | |
| Bunga Shop, Alat & Dekor Bunga, Pet, Lemari Gaya, Instant | `Config/BungaShop` (baru), `Config/Instant` (baru) | Bab 18.3 |
| Developer Product + ProcessReceipt idempotent | `MonetizationService` (sudah ada `PURCHASE_ID_CACHE_SIZE`) | Cek ulang |
| Game Pass (Tas, Lapak, Blueprint, Musik) | `Config/Monetization` | D-22 |
| Season Pass | `Config/Season` (baru), `SeasonService` | Bab 19 |

**DoD:** pembelian tidak dobel / hilang saat server crash.

### Fase 10 — Polish, Performa, Playtest

| Tugas | File | Catatan |
|-------|------|---------|
| Bab 20: SFX, haptic 5 momen | `Sfx`, `AudioController`, `Config/Audio` | |
| Bab 21: efek & cap partikel 120 / glow 6, setting efek | `Vfx`, `Config/Audio` | |
| Bab 22: animasi & tween | `UiKit`, `NpcService` | |
| Bab 24: LOD, StreamingRadius, Anchored | `default.project.json`, Workspace | |
| Bab 25: analytics event log | `AnalyticsHooks` | |
| Bab 30: playtest | `docs/Playtest_Plan.md` | |

**DoD:** semua FAIL wajib = 0.

---

## Yang Dibiarkan Tanpa Keputusan (Lihat TODO)

Lihat `docs/TODO.md`. Ringkasnya: ukuran lahan, jumlah lahan, grid 2 atau 8 stud, pass plots/decor, struktur save lama, dan nama file Config.
