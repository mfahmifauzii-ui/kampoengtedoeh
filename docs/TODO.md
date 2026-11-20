# TODO (diperbarui setelah Fase 0 dan keputusan owner 20 Nov, lihat Changelog v6.2.1)

> Status per 20 Nov 2026. Keputusan owner (T-01 sampai T-08) sudah masuk ke docs/Kampoeng_Tedoeh_Gameplay_Lengkap_v6.2.md. Keputusan T-09, T-24, T-25, T-27 sampai T-29, T-31, T-32, T-35 masuk ke v6.2.1 (Changelog 0.3.3). Waktu Early dan telat panen masuk v6.2.2 (Changelog 0.3.4).

| # | Pertanyaan / Item | Detail | Fase | Status |
|---|---|---|---|---|
| T-01 | Jumlah lahan 8 dan server max 8 player (Bab 3.1) | Diputuskan owner. Max player di Studio (Game Settings) masih harus diisi 8 secara manual. | Fase 0 | Diputuskan: 8 lahan, 8 player. TODO: set Max Players = 8 di Studio. |
| T-02 | Lahan awal 128x128, beli chunk 32x32 (Bab 3.1, 17.4) | Diputuskan owner. Sink ekspansi 88.790; total 623.000; konten rilis ~71%. | Fase 0 | Diputuskan. Kode: Config/Plots (tidak diubah). |
| T-03 | Grid: tanam 8 stud, Hias struktur 2 stud, furniture/dekor 1 stud | Diputuskan owner. Cek DecorGrid: BELUM sesuai. Decor.CELL = 2 untuk semua item (furniture ikut 2 stud). | Fase 4 | TERBUKA: ubah format posisi dekor agar furniture/dekor snap 1 stud (perlu migrasi data dekor, Fase 4). |
| T-04 | Bajak petak: batas per level dan biaya n x 150 | Diputuskan owner. Sudah dibuat (Config/Farm, FarmService). | Fase 1 | Selesai. Harga petak berikutnya sudah tampil di hint Garap (Fase 1). |
| T-05 | Ganti nama NPC | Diputuskan owner. Sudah dibuat. Narator tutorial (Mbok Minah) menjadi Mak Sari (lihat T-29). | Fase 1 | Selesai (commit ff4555e). Lihat T-30 untuk aset model Studio. |
| T-06 | Bang Tarno x8 -> Bang Jali x8 | Diputuskan owner. Sudah dibuat. Lapak Tarno diganti sign Pos Ronda. | Fase 1 | Selesai (commit ff4555e). |
| T-07 | Hapus pass decor dan plots | Diputuskan owner. Sudah dihapus (commit 11e5938). | Fase 9 | Selesai. |
| T-08 | Reset save, DataTemplate v62 tanpa migrasi | Diputuskan owner. Sudah dibuat (DATA_STAGE v62, Migrations.luau dihapus). | Fase 0 | Selesai (commit cba3137). Tapi field lama (koin, bunga, xp, farm, dll.) belum dipindah ke nama Bab 28, lihat T-24. |
| T-09 | Nama file Config: Inggris atau Indonesia | Belum diputuskan. Sementara pakai nama yang sudah ada (Crops, Fish, Decor, Quests, Events). | Fase 0 | Diputuskan (20 Nov): tetap pakai nama Inggris yang sudah ada (`Crops`, `Fish`, `Decor`, `Quests`, `Events`). Changelog v6.2.1 #10. |
| T-10 | Hari game 30 menit | Sudah dibuat (Config/World: 3/15/3/9). | Fase 0 | Selesai (commit 8f61da5). |
| T-11 | Reset harian 05:00 WIB | Sudah dibuat (Progression.RESET_HOUR, TimeKeys day dan week). | Fase 6 | Selesai untuk kunci waktu. Sistem reset per fitur belum ada. |
| T-12 | Gestur: 4 dari v6.2 | Sudah dibuat (Config/Social). Lambai, Tepuk, Ketawa memakai animasi bawaan. Jempol belum punya animasi. | Fase 7 | Terbuka untuk Jempol, lihat T-23. |
| T-13 | Peta: Pos Ronda, Gerobak, papan, pelataran event, 80 titik spawn | Belum dibuat. Pos Ronda sementara = sign Shop 3 dan Nek Ani di sana. | Fase 7 | Terbuka. |
| T-14 | Chunk dan sistem ekspansi | Diputuskan: pakai sistem chunk yang sudah ada. | Fase 4 | Selesai (keputusan). |
| T-15 | DataStore global Lapak | Belum dibuat. | Fase 7 | Terbuka. |
| T-16 | Bahan mentah (Kayu, Bambu, Batu, Tanah Liat, Pasir, Jerami, Ijuk) | Belum ada sebagai item. Hanya pelet dan tanaman/ikan. | Fase 4 | Terbuka (dibutuhkan juga oleh T-26). |
| T-17 | Kak Fajar di tepi Kanal | Kak Fajar masih di Toko Pancing (Shop 5). Tepi Kanal belum dibuat. | Fase 3 | Terbuka. |
| T-18 | Kolam: pakai PondService atau sistem Bab 7.2 | Belum diputuskan. | Fase 5 | Terbuka. |
| T-19 | Haptic Android | Belum riset. | Fase 10 | Terbuka. |
| T-20 | Tes 8 player di HP 4GB | Belum dijadwalkan. | Fase 10 | Terbuka. |
| T-21 | Pesanan Harian (Orders) diganti Agenda Harian | Orders sekarang memakai NPC v6.2 sebagai pemberi pesanan. Diganti Agenda di Fase 6. | Fase 6 | Terbuka. |
| T-22 | Update 1 dan 2 (Bab 26) | Di luar scope rilis. | - | Nanti. |
| T-23 | Animasi Jempol; Kayu dan Cacing sebagai item Playtime | Jempol belum punya animasi (gestur hanya ikon). Hadiah Playtime 30 dan 60 menit belum berisi Kayu dan Cacing karena item itu belum ada. | Fase 4-7 | Terbuka. |
| T-24 | Bab 28: nama field belum sesuai (koin, bunga, xp, level, farm, fishing, pond, decor, orders, quests, visits, playtime, book, titles, land, social, instantGrow, guide, purchaseIdCache) | Template v62 sudah punya sp, cabang, skill, land.lahanAwal, land.chunkLahan. Field lama belum diganti nama: butuh perubahan di hampir semua service. | Tiap fase | Diputuskan (20 Nov): per service saat disentuh, tanpa rename global. Changelog v6.2.1 #11. Progres: Fase 1 menyentuh FarmService, PlotService, ShopService, NpcService. |
| T-25 | Objek chunk: 3 ilalang + 1 semak per chunk | Asumsi dari kepadatan lahan awal. Bab 3.4 tidak menyebut jumlahnya. | Fase 0 | Diputuskan (20 Nov): 3 ilalang + 1 semak per chunk. Bab 3.4 v6.2.1. |
| T-26 | Hadiah bersihkan lahan: Jerami, Kayu, Bambu, Batu | Belum ada item bahan, jadi bersihkan belum memberi hadiah. Koin 200 saat lahan awal bersih sudah jalan. | Fase 4 | Terbuka (tergantung T-16). |
| T-27 | Bab 4.1 vs kode: Bunga dari hadiah Like (3, 10, 25) dan milestone title kebun_favorit | Config/Social LIKE_MILESTONES memberi Bunga dan title. Bab 4.1 tidak menyebut Like sebagai sumber Bunga. | Fase 4 | Diputuskan (20 Nov): Bunga diganti Koin 300 / 1.000 / 2.500, title kebun_favorit tetap. Changelog v6.2.1 #1. |
| T-28 | Bab 11/15 vs kode: Hadiah kunjungan (VISIT_REWARDS) hari ke-7 memberi 3 Bunga | Login Mingguan v6.2 memberi 10 Bunga di hari 7 (Bab 15.1). Visit reward masih ada. | Fase 6 | Diputuskan (20 Nov): VISIT_REWARDS dihapus seluruhnya. Login Mingguan (Fase 6) jadi satu-satunya login. Bunga Pesanan Mingguan dan Bunga kategori Ikan Album juga dihapus. Changelog v6.2.1 #2-4. |
| T-29 | Narator tutorial: Mbok Minah menjadi Mak Sari | Keputusan saya: narator FTUE = Mak Sari (mentor awal, Bab 10.1). Owner minta Mbok Minah dilebur ke Kak Fajar untuk toko ikan, jadi peran narator perlu dikonfirmasi. | Fase 1 | Dikonfirmasi owner (20 Nov): narator tutorial = Mak Sari. |
| T-30 | Model Studio dan peta belum diganti | Di Studio: ServerStorage.NpcModels bang_tarno -> bang_jali, mbok_minah -> mak_sari, mas_joko -> kak_fajar, mbak_arsi -> pak_amran, pak_darmo -> pak_udin. Papan 'Lapak Tarno' di peta: ganti teks ke Pos Ronda. Set Max Players = 8. | Fase 0 | Terbuka: dikerjakan di Studio oleh owner. |
| T-31 | Warung Mak Sari: kandidat Shop 7 (sebelumnya Warung Jamu) | Shop 7 satu-satunya warung selain warung utama. Owner minta tanya jika tidak yakin. | Fase 1 | Dikonfirmasi owner (20 Nov): Warung Mak Sari = Shop 7. Kode sudah sesuai (unlockLevel 6, baris kunci di npc.mak_sari.locked). |
| T-32 | Premium: PREMIUM_EXTRA_REROLLS = 1 masih ada | Bukan pengali Koin, jadi tidak dihapus di commit 1. Bab 19 melarang 'boost' Premium lainnya. | Fase 9 | Diputuskan (20 Nov): PREMIUM_EXTRA_REROLLS dihapus, label Premium +10% Koin dihapus. Changelog v6.2.1 #7. |
| T-33 | Objek awal lahan: HUD dan posisi rumah | Area bersih 24x24 dan jalan ke gerbang ditentukan dari angka, bukan dari posisi rumah yang sebenarnya. | Fase 0 | Perlu cek di Studio. |
| T-34 | HUD Bab 23.2 belum dicek | Layout HUD sekarang belum dicek di Studio (tidak ada file .rbxl di repo). | Fase 0 | Terbuka: cek di Studio. |
| T-35 | Sign toko kosong: Toko Bibit, Pasar Ikan, Toko Roti, Toko Kelontong | Tidak ada NPC di sana setelah rename. Masih berupa dekor. | Fase 3-7 | Diputuskan (20 Nov): dibiarkan sebagai dekor dulu. |
| T-36 | Tiga NPC v6.2 yang belum ada tempatnya: Pedagang Tamu dan Tamu Event | Dikonfigurasi dengan hidden = true. Tidak tampil sampai Fase 7. | Fase 7 | Terbuka. |

| T-37 | Album: kartu `ALBUM +1: Kangkung Embun` di FTUE 1:10 | Album sudah ada, tapi hanya entri crop (BookService.RecordCrop). Entri Mutasi (Ladang 120 entri, Bab 11) belum ada. Kartu tidak dibuat supaya tidak palsu. | Fase 2 | Terbuka: tambah entri Mutasi di Config/Book lalu kartu bisa dipanggil. |
| T-38 | NPC walk-up (Bab 22.3): pemicu | Helper `NpcService.WalkTo` sudah ada (50% kecepatan player, Config/Npcs WALK_SPEED). Pemicu di doc: Mak Sari MQ4/MQ7 (Lv 3/6) dan Pak Amran ke Kanal di FTUE 2:40. Belum ada yang memanggil. | Fase 3 dan 5 | Terbuka: panggil dari quest dan FTUE nanti. |
| T-39 | Telat panen: ambang 10 menit | Bab 5.1 tidak menyebut ambang. `Config/Farm` OVERDUE_AFTER_SECONDS = 600 adalah angka tim. | Fase 1 | Perlu konfirmasi owner. |
| T-40 | Cek cutscene <= 6 dtk (Bab 16.2) | `Cutscene` mencatat lama beat (log saja). Hitungannya dari Begin sampai End, jadi termasuk waktu dialog (tap Lanjut). Akibatnya bisa ada peringatan palsu di beat bicara. | Fase 1 | Terbuka: ukur hanya bagian kamera kalau mau akurat. |
| T-41 | Ubi Jalar 7 menit = batas, bukan di bawah | Owner minta Early tetap di bawah 7 menit, tapi Ubi Jalar sekarang 420 dtk = tepat 7 menit. Angka dari owner dipakai, changelog v6.2.2 tertulis maksimal 7 menit. | Fase 1 | Perlu konfirmasi owner. |
| T-42 | Koin/jam Early (Nanem) jauh di atas Bab 17.2 | 6 petak Early dengan Siram dan panen ulang tepat waktu: sekitar 1.970 Koin bersih/jam. Bab 17.2 Lv 1-20 Nanem: 700/jam. Estimasi ini ideal (tanpa jeda, tanpa jalan). | Fase 10 | Terbuka: cek saat playtest (Bab 17.8). |
| T-43 | Model tanaman Bayam, Sawi, Ubi Jalar | Pakai fallback generik (batang + 5 daun, warna crop, semua part terlihat). Belum ada model asli (Bab 21/22 aset). | Fase 8 | Terbuka: model asli nanti. |
| T-44 | Embun random dan Mutasi lain | Config/Mutasi hanya Embun (x1,5), untuk panen pertama FTUE. Roll acak (Embun 20%, Petir 10%, Emas 1%, Pelangi 3%) belum ada. | Fase 2 | Terbuka. |
