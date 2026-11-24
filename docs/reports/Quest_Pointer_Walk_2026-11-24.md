# Jalan Pointer M1–M9 dan S1–S9 (di atas kertas), 2026-11-24

Dasar: owner playtest 2026-11-24, butir 8. Dibaca dari `src/shared/Config/Quests.luau`, `QuestController`, `QuestOfferController`.
Tidak ada Play run. Status di sini = yang dibaca dari kode, belum dilihat di HP.

## Cara membaca "pointer"

Tiap langkah dilihat dengan tiga pointer:

- **Baris tracker**: teks langkah tampil saat quest dilacak (Main selalu; Side saat ditawarkan atau diambil, K-94).
- **"!" dan panah ke pemberi**: hanya saat quest ditawarkan (Tersedia) atau siap diserahkan. Untuk langkah berjalan, tidak ada.
- **Panah ke tempat**: hanya kalau langkah punya `target` di Config (K-95). Panah = nama NPC (lewat `Npcs`) atau nama objek di Workspace.

Langkah yang hanya punya baris tracker, tanpa panah, dihitung **GAP** (lihat daftar di bawah).

## Main M1–M9

| Quest | Langkah | Teks sekarang | Pointer sekarang | Status |
|---|---|---|---|---|
| M1 Kampung Hari Ini (Nek Ani, Lv2) | s1 `agenda_open` | Buka Agenda | "!" Nek Ani, baris tracker. Tombol Papan tidak ditunjuk | GAP-A (tombol HUD tanpa panah) |
| | s2 `agenda_done` | Selesaikan 1 tugas Agenda | baris tracker, tanpa tempat | GAP-A |
| | s3 `gerobak_view` | Lihat Gerobak Kaget di alun-alun | baris tracker, tanpa target | GAP-B (tidak ada target) |
| M2 Ke Hutan (Pak Amran, Lv4) | s1 `mine` | Pergi ke Hutan Nambang | baris tracker, tanpa target | GAP-B |
| | s2 item batu/kayu | Kumpulkan 10 Batu dan 9 Kayu | baris tracker (jumlah dari teks) | OK teks, tanpa panah |
| | s3 `craft_papan` | Craft 2 Papan di Meja Crafting | baris tracker, tanpa target. Meja Crafting = `Mining.CRAFT_TABLE` di Workspace | GAP-C (target belum diisi) |
| M3 Kolam Kakek (Kak Fajar, Lv4) | s1 `kakek_setor` | Bangun Kolam Kakek (10 Batu, 5 Kayu, 3 ikan Early) | baris tracker. Tempat kolam belum ada target | GAP-B |
| | s2 `catch_pond` | Tangkap 1 ikan di kolammu | baris tracker, tanpa target | GAP-B |
| M4 Pagar Pertama (Pak Amran, Lv5) | s1 `decor_placed` | Pasang 1 Pagar Bambu | baris tracker. Tombol Hias tidak ditunjuk | GAP-A |
| M5 Kokok Pertama (Pak Udin, Lv5) | s1 `feed_animal` | Isi pakan ayam | baris tracker. Kandang ayam belum ada target | GAP-B |
| | s2 `collect_egg` | Ambil 1 telur | baris tracker | GAP-B |
| M6 Dapur Pertama (Mak Sari, Lv6) | s1 `craft_tungku` | Craft Tungku di Meja Crafting | panah ke **Meja Crafting** (target `Meja Crafting`) | OK (walk ulang, K-103) |
| | s2 `dapur_built` | Pasang Tungku di lahanmu (tombol Aksi) | panah ke **lahanmu** (target `lahan` = Origin plot sendiri). Tombol Aksi "Pasang Tungku" muncul saat Tungku di tas | OK (walk ulang, K-103) |
| | s3 `cook` | Masak 1 olahan di Tungku (tombol Aksi) | panah ke **Tungku** (target `Tungku`); tombol Aksi "Masak" muncul dekat Tungku | OK (walk ulang, K-103) |
| | s4 `eat` | Makan 1 olahan | panah ke **Tungku** | OK |
| M7 Warung Pertama (Mak Sari, Lv7) | s1 `warung_place` | Pasang Warung | baris tracker, tanpa target | GAP-B |
| | s2 `warung_sale` | Jual 1 olahan di Warung | baris tracker, tanpa target | GAP-B |
| M8 Jebakan Kak Fajar (Kak Fajar, Lv8) | s1 `bubu_place` | Pasang 1 Bubu | baris tracker, tanpa target (sungai) | GAP-B |
| M9 Sumur Tua (Nek Ani, Lv8) | s1 `bundel_sumur_tua` | Pulihkan Sumur Tua (10 Kayu, 5 Batu, 2 olahan) | baris tracker, tanpa target | GAP-B |

Catatan: M1–M9 tiap "start" dan "selesai" punya "!" pemberi (offer dan siap diserahkan). Itu sudah ada.

## Side S1–S9

| Quest | Langkah | Teks sekarang | Pointer sekarang | Status |
|---|---|---|---|---|
| S1 Bibit Kedua (Pak Udin, Lv1) | s1 `buy_seed` | Beli 2 Bibit Bayam | baris tracker. Panah ke Pak Udin hanya saat ditawarkan | GAP-E (langkah beli tanpa panah ke toko) |
| | s2 `plant_bayam` | Tanam 2 Bayam | baris tracker, tanpa target (petak sendiri) | GAP-B |
| S2 Surat Pertama (Mak Sari, Lv2) | s1 `surat_read` | Baca Surat Kakek #1 | **Tombol Baca** di baris S2 dan baris Surat (K-95) | OK (tanpa panah, K-95) |
| S3 Tetangga Baru (Bang Jali, Lv3) | s1 `sell_bang_jali` | Jual 1 barang ke Bang Jali | baris tracker, tanpa target | GAP-E |
| S4 Rangka Rumah (Pak Amran, Lv3) | s1 `talk_pak_amran` | Ngobrol dengan Pak Amran | baris tracker. Target yang benar = `pak_amran` (belum diisi) | GAP-C (target belum diisi) |
| S5 Ikan Kanal (Kak Fajar, Lv5) | s1 `catch_mid_kanal` | Tangkap 1 ikan Mid di Kanal Barat | baris tracker, tanpa target (sungai) | GAP-B |
| S6 Tetangga Baik | diblok (BANTU, K-73) | — | — | tidak diwalk |
| S7 Sawah (Pak Udin, Lv9) | s1 `plant_padi` / s2 `harvest_padi` | Tanam / Panen 1 Padi | baris tracker, tanpa target | GAP-B |
| S8 Kandang Bebek (Pak Udin, Lv10) | s1 `kandang_bebek` / s2 `beli_bebek` | Bangun Kandang Bebek / Beli 1 Bebek | baris tracker, tanpa target | GAP-B |
| S9 Empang (Kak Fajar, Lv10) | s1 `catch_empang` | Tangkap 1 ikan di Kanal Timur | baris tracker, tanpa target | GAP-B |

## Daftar gap

- **GAP-A: tombol HUD tanpa panah** (Papan/Agenda, Hias, Dapur/DapurButton). Panah dunia tidak menunjuk tombol layar. Perlu keputusan: tombol diberi sorot (coachmark) atau cukup teks. Owner belum memutuskan.
- **GAP-B: langkah tanpa tempat di dunia** (hutan, kolam, sungai, kandang, petak, warung, sumur, bubu, Kanal Timur, Gerobak). Perlu nama objek di Workspace atau titik sungai/kolam. Lihat R5.8d.
- **GAP-C: target sudah ada di dunia tapi belum diisi di Config**: M2 s3 (`Meja Crafting`), S4 (`pak_amran`). Perbaikan satu baris per langkah, belum dikerjakan di batch ini (owner: "jangan perbaiki lebih dari butir di atas").
- **GAP-D (M6): TUTUP.** Craft Tungku di Meja Crafting (R5.8a, K-101) dan Aksi dapur dekat Tungku (R5.8b, K-102) sudah dibangun. Walk ulang M6 di atas: 4 langkah, masing-masing punya panah. Belum diuji di Play.
- **GAP-E: langkah beli/jual di NPC** (S1 s1, S3 s1): panah ke NPC hanya saat ditawarkan. Setelah diambil, tidak ada panah ke toko atau NPC. Target `pak_udin` dan `bang_jali` bisa diisi (sama dengan GAP-C).

## Ringkas

- Langkah tanpa gap: S2 (dengan Baca), M6 s2/s3 (setelah Tungku berdiri), dan semua "!" pemberi saat ditawarkan atau siap diserahkan.
- Langkah dengan gap: sisanya. Teks tracker selalu ada, jadi tidak ada langkah yang tanpa petunjuk sama sekali. Yang kurang adalah panah.
