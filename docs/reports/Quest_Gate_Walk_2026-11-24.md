# Jalan gerbang quest Lv 0–10 (di atas kertas) — 2026-11-24

> Snapshot satu kali, setelah `feat(R2.3)` (67a1a00) dan `feat(R2.5)` (b84da32). Tidak ada tes Play. `src/` dibaca, tidak diubah di laporan ini.
> Dibaca dari: `Config/Quests` (step dan `reveals`), `FeatureGate`, `QuestService.Report`, server reporter tiap event, `Config/Crops`, `Config/Ranch`, `RepeatService.kbStart`, `WeatherService` (RAIN_ROLL), `WarungService`, `FishService.SPOT_FEATURE`.

## 1. Urutan dari akhir tutorial sampai Lv 10

Quest main berurutan lewat `after`. Quest side jalan paralel. Kolom "Gerbang" = fitur yang harus terbuka (`reveals` dari step sebelumnya, atau level).

| Lv | Quest | Pemberi | Gerbang / sumber | Bisa solo? | Catatan |
|----|-------|---------|------------------|-----------|---------|
| 1 | S1 Bibit Kedua | Pak Udin | level 1 | Ya | `buy_seed`, `plant_bayam` |
| 1 | side_kolektor | Nek Ani | Album 25% (auto) | Ya, lambat | Album dari koleksi biasa |
| 1 | side_kerjabakti | Nek Ani | level 1; `kb` 10 | **Tergantung cuaca** (lihat G5) | `kbStart` hanya saat hujan Deres atau Petir berakhir |
| 2 | M1 Kampung Hari Ini | Nek Ani | level 2; `agenda` (langkah 1), `gerobak` (langkah 3) | Ya | Sudah diperbaiki R2.3: `agenda_open`, `gerobak_view` punya pengirim |
| 2 | S2 Surat Pertama | Mak Sari | level 2; `surat` (dari langkah 1) | Ya | Sudah diperbaiki R2.3: `surat_read` dikirim dari tap baris Surat |
| 3 | S3 Tetangga di Depan | Bang Jali | level 3; `jual_bang_jali` | Ya | `sell_bang_jali` lewat ShopService |
| 3 | S4 Rangka | Pak Amran | level 3 | Ya | `talk_pak_amran` dari NpcService |
| 4 | M2 Ke Hutan | Pak Amran | level 4 (setelah M1); `hutan`, `craft` | Ya | Nambang + Craft Papan |
| 4 | M3 Kolam Kakek | Kak Fajar | level 4 (setelah M2); `kolam` | Ya | `freePond` memberi kolam gratis |
| 5 | M4 Pagar Pertama | Pak Amran | level 5 (setelah M3); `hias` | Ya | |
| 5 | M5 Kokok Pertama | Pak Udin | level 5 (setelah M4); `kandang_ayam` | Ya | `giveHewan` memberi ayam |
| 5 | S5 Ikan Kanal | Kak Fajar | level 5; `kanal_barat` | Ya | `catch_mid_kanal` |
| 5 | S6 Kenalan Tetangga | Nek Ani | level 5; `bantu` | **Tidak ditawarkan** (K-73, `blocked`) | Ditunda |
| 5 | side_tetangga | Nek Ani | level 5; `bantu` 10 | **Tidak ditawarkan** (K-73, `blocked`) | Ditunda |
| 6 | M6 Dapur Pertama | Mak Sari | level 6 (setelah M5); `dapur` | Ya | |
| 6 | side_resep | Mak Sari | level 6; `dapur` | Ya | |
| 7 | M7 Warung Pertama | Mak Sari | level 7 (setelah M6); `warung` | Ya | Penjualan Warung jalan sendiri (`processSales`) |
| 7 | side_warung | Mak Sari | level 7; `warung` | Ya | 10 penjualan, lambat |
| 8 | M8 Jebakan Kak Fajar | Kak Fajar | level 8 (setelah M7); `bubu` | Ya | |
| 8 | M9 Sumur Tua | Nek Ani | level 8 (setelah M8); `bundel` | Ya | |
| 8 | side_rumah_rapi | Pak Amran | level 8; decor 20 | Ya | |
| 8 | side_prima | Mak Sari | level 8; Kualitas Prima 5 | Ya, acak | Kualitas Prima bergantung RNG, tidak ada gerbang |
| 9 | S7 Sawah | Pak Udin | level 9; padi Lv 8 sudah terbuka | Ya | |
| 10 | S8 Kandang Bebek | Pak Udin | level 10; `kandang_bebek` (langkah 1); bebek Lv 10 | Ya | |
| 10 | S9 Empang | Kak Fajar | level 10; `empang` (langkah 1); `SPOT_FEATURE` | Ya | |
| 10 | side_jumbo | Kak Fajar | level 10; ikan Jumbo | Ya, acak | |

**Cek sumber gerbang:** semua `reveals` di 03 Lv 0–10 punya step yang mengisinya. Setiap gerbang yang dibaca server (`FeatureGate.Check`, `IsUsable`) memakai id yang sama dengan `reveals`. Tidak ada id yang dibaca tapi tidak pernah diisi, kecuali `bantu` (karena S6 diblokir, lihat G1).

**Cek event:** setiap event step Lv 0–10 punya pengirim server (`QuestService.Report`, `reportQuest`, atau `UI_EVENTS` lewat `QuestReport`). Dua event UI yang sebelumnya tanpa pengirim (`gerobak_view`, `surat_read`) sudah diperbaiki di R2.3.

## 2. Celah (gap) yang nyata

Gap ditulis sebagai baris TODO di Roadmap (R2.G1–R2.G6). Tidak ada yang diperbaiki di tugas ini.

| ID | Celah | Jenis | Tingkat | Ditutup oleh |
|----|-------|-------|---------|--------------|
| G1 | **Warga panel tidak punya pintu masuk.** Tombol Warga (HUD `SocialButton`) memakai gerbang fitur `bantu`, yang hanya dibuka S6. Dengan Bantu mati (K-73), Mampir, emote, Pulang, dan hadiah ikut hilang. Solo tidak punya tempat untuk Warga. | Gerbang tanpa sumber | Tinggi | fix(R2.G1) `b8b72e4`, K-75 |
| G2 | **Skill Tetangga Baik bisa dibeli tanpa efek** (`tetanggaBonus` hanya dipakai Bantu). | Konten tanpa efek | Rendah | fix(R2.G2) `1d1084e`, K-76 |
| G3 | **Teks surat 6, 13, 20, 29 menyebut Bantu.** Surat dibayar diam-diam (K-73). Surat lain masih teks placeholder (R8.3). | Teks | Sedang | fix(R2.G3) `7d1fdd8`, K-77 |
| G4 | **Season "Bantu 20 lahan" (K-58) tidak ada di kode.** Tidak ada kartu di Hadiah > Musim dan tidak ada `season.bantu`. Dokumen mengklaimnya ada. | Dokumen melebihi kode | Sedang | fix(R2.G4) `62dc38e`, K-78 |
| G5 | **side_kerjabakti (Lv 1) hanya bisa dimulai lewat hujan Deres atau Petir yang berakhir** (`kbStart`). Tidak ada jadwal dan tidak ada tombol. Dengan RAIN_ROLL Deres 30% dan Petir 15%, sumbernya ada tapi tidak bisa dipaksa. Pemain bisa menunggu lama di Lv 1–2. | Gerbang tanpa kontrol pemain | Sedang | fix(R2.G5) `7b1fc1b`, K-79 (dokumen; pemicu tidak diubah) |
| G6 | **Agenda hanya 3–4 tugas sebelum Lv 6.** Lv 1–3: Panen, Mancing, Tanam (3). Lv 4–5 dengan Hutan: + Nambang (4). Lv 6+: 5 (GDD 14.5 "5 tugas/hari"). | Spesifikasi | Rendah | fix(R2.G6) `51671cb`, K-80 |

**Yang sudah ditutup di R2.3 / R2.5 dan tidak lagi jadi gap:** M1 macet di langkah Gerobak (`gerobak_view`), S2 tidak bisa selesai (`surat_read`), Pesanan muncul sebelum M1, S6 dan Ringan Tangan menunggu Bantu (`blocked`), Agenda memilih tugas Bantu (diganti Tanam 5), surat 6/13/20/29 macet (dibayar langsung).

**Di luar walk (tidak diperiksa):** Quest Lv 11+, Kucing Alun-alun dan Joran Hilang (K-16, ditunda, belum ada di kode), Mingguan, dan Kebun Favorit (like, ditunda oleh G1).

## 2b. Walk ulang Lv 0–10 (setelah G1–G6, 2026-11-24)

Dibaca ulang dari kode yang sudah berubah (K-75–K-80). Tidak ada perbaikan di bagian ini; setiap gap baru jadi baris TODO di Roadmap.

| ID | Celah baru | Tingkat | Baris Roadmap |
|----|-----------|---------|---------------|
| N1 | **side_kerjabakti ditawarkan di Lv 1, tapi prompt pungut hanya terbuka setelah M1 langkah 3 (gerbang `gerobak`, Lv 2).** Quest tidak bisa maju di Lv 1. `unlockLevel` tidak cocok dengan gerbangnya. | Sedang | R2.G7 |
| N2 | **Solo tidak punya konten sosial sama sekali** (Warga butuh 2 pemain, K-75). Tidak ada quest yang macet karenanya, tapi tidak ada sesuatu yang bisa dilakukan solo di sisi sosial. | Rendah | R2.G8 |
| N3 | **Surat 6/13/20/29 dibayar tanpa toast saat fitur Surat belum terbuka** (sebelum S2, Lv 2). Pemain mendapat Koin/Bunga tanpa tahu sebabnya, dan surat itu tidak pernah terbaca. | Rendah | R2.G9 |

Sudah diperiksa dan tidak ada gap baru: M1–M9 dan S1–S9 Lv 0–10 (gerbang dan event punya sumber), S6 dan Ringan Tangan `blocked`, Agenda 3/4/5 tugas sesuai syarat (K-80), Tetangga Baik tidak tampil, surat text alt, Season Bantu tidak dibangun (K-78).

## 3. Keputusan yang dipakai (ringkas)

- K-73: Bantu mati, Kebun Warga batal, slot Agenda Bantu diganti Tanam 5 (150 Koin, 25 XP).
- K-74: Surat 1 dibaca lewat tap baris Surat; Gerobak = panel Acara tab Gerobak; Pesanan memakai gerbang `agenda`.

## 4. Pengecekan

- `selene src`: 0 error, 85 warning (baseline tetap).
- `rojo build`: exit 0.
- Tidak ada Play run. Semua di atas dari baca kode.
