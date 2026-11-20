# TODO — Hal yang Belum Jelas di Gameplay v6.1

> Dibuat saat audit (20 Nov 2026). Sesuai aturan v6.1: kalau tidak jelas, tulis di sini dan jangan menebak. Keputusan dari Anda dibutuhkan sebelum fase terkait dimulai. Yang "Blokir" berarti fase tersebut tidak bisa mulai sebelum dijawab.

| # | Pertanyaan | Kenapa Tidak Jelas | Blokir Fase | Status |
|---|-----------|--------------------|-------------|--------|
| T-01 | Jumlah lahan: 10 (v6.1 Bab 3.1 & Max 10 player) atau 8 (peta sekarang)? | v6.1 bilang "10 lahan melingkar". Peta sekarang (`Config/Plots`, `Map`) punya 8 lahan & 8 shophouse. Anda minta peta tetap. | Fase 0 | Terbuka |
| T-02 | Lahan awal 96×96 (v6.1) atau 128×128 (sekarang)? | v6.1 Bab 3.1 & Bab 3.4 bilang 96. Sekarang `START = 128`, `REGION = 192`. | Fase 0 | Terbuka |
| T-03 | Grid: 1 sel = 2×2 stud (v6.1 Bab 3.1) atau 8 stud (sekarang `Land.TILE`)? | Bab 3.1 & Bab 8.3 pakai 2×2. Kode pakai 8 untuk petak tanam. Bisa jadi 2×2 hanya untuk Hias. | Fase 4 | Terbuka |
| T-04 | Sistem tanam: petak tetap (v6.1 Bab 5.2: 6 awal, buka `n×150`, max 36) atau lahan bebas (`Garap`, sekarang)? | Dua model bertentangan. Prinsip #8 (lahan 100% bebas) bisa dipenuhi keduanya. | Fase 1 | Terbuka |
| T-05 | Nama pengganti NPC lama: Pak Darmo, Mbok Minah, Mas Joko, Bu Wati, Mbak Arsi, Bang Tarno. Apakah peran & posisinya dipetakan langsung seperti di bawah? | v6.1 Bab 10.1 melarang nama lama dan punya daftar NPC baru. Usulan pemetaan: Pak Darmo→Pak Udin (toko bibit), Mas Joko→Kak Fajar (pancing; tapi Kak Fajar di pinggir Kanal), Mbok Minah→Pak Udin atau Bang Jali (ikan), Mbak Arsi→Pak Amran (tukang), Bu Wati→Pak Udin (bibit unggul, bisa digabung), Bang Tarno→Bang Jali. Konfirmasi. | Fase 1 | Terbuka |
| T-06 | Warung Mini ×8 (Bang Tarno) apakah dihapus semua? | v6.1 tidak punya Warung Mini. Ada 8 `Warung Mini` hand-placed di Workspace. | Fase 1 | Terbuka |
| T-07 | Game Pass "decor" (+100 limit) & "plots" (diskon 20% lahan) dihapus? | Tidak ada di v6.1 Bab 18.4. Diskon lahan berisiko P2W ringan. Usulan: hapus keduanya. | Fase 9 | Terbuka |
| T-08 | Save lama pemain: apakah harus dimigrasi ke struktur Bab 28, atau game belum rilis dan boleh reset? | `DataTemplate.version = 13` dan ProfileStore sudah jalan. Kalau sudah ada player nyata, migrasi wajib. | Fase 0 | Terbuka |
| T-09 | Nama file Config: ikuti Bab 28 (`Tanaman`, `Ikan`, `Hias`, `Quest`, `Event`) atau pakai nama sekarang (`Crops`, `Fish`, `Decor`, `Quests`, `Events`)? | Bab 28 pakai nama Indonesia. Kode pakai Inggris. Usulan: pakai nama sekarang, sebutkan di Bab 28 sebagai alias. | Fase 0 | Terbuka |
| T-10 | Hari game: 30 menit (3/15/3/9, v6.1) atau 24 menit (sekarang)? | v6.1 Bab 3.2 & 0.2 jelas 30 menit. Hanya perlu konfirmasi bahwa sekarang boleh diubah. | Fase 0 | Usulan: ikut v6.1 |
| T-11 | Reset harian: 05:00 WIB (v6.1) atau 00:00 WIB (sekarang)? | v6.1 Bab 3.2 jelas 05:00. Usulan: ikut v6.1. | Fase 6 | Usulan: ikut v6.1 |
| T-12 | Gestur: 4 dari v6.1 (Lambai, Jempol, Tepuk, Ketawa). Apakah emote Roblox bawaan untuk `wave`, `cheer` tetap? | Kode pakai emote built-in Roblox. `dance` dan `point` dilarang/tidak ada di v6.1. | Fase 7 | Usulan: pakai 4 gestur custom |
| T-13 | Map: apakah Pos Ronda, Gerobak, Papan Agenda/Galeri/Lapak, pelataran event, dan 80 titik spawn kotoran akan dibuat di `MapService` (procedural) atau manual di Studio (`Workspace.Map`)? | `MapService` bisa membangun peta jika `Workspace.Map` belum ada. Peta yang dibangun manual di Studio tidak ada di repo. | Fase 7 | Terbuka |
| T-14 | Apakah Expansion lahan (v6.1: 120/140/160 pada Lv 12/30/50) menggantikan sistem chunk 32 stud? | `Plots.CHUNK` beda model. Perlu keputusan kalau mau tetap pakai chunk. | Fase 4 | Terbuka |
| T-15 | Apakah aturan "Lapak tidak boleh duplikasi item" dan "Lapak harga 80–130%" perlu DataStore global `Lapak_<UserId>` atau cukup Global DataStore yang sudah ada? | Bab 28 minta Global DataStore. Belum ada DataStore global. | Fase 7 | Terbuka |
| T-16 | Bahan mentah (7) dan olahan (7): apakah item sudah ada di `Modules/Items`? | Kata "Bambu" ada di 19 file, tapi Ijuk, Tanah Liat, Pasir, Jerami belum dicek. | Fase 4 | Perlu cek |
| T-17 | Kak Fajar di Kanal: apakah posisi Kanal dan Danau sudah ada di peta sekarang atau perlu dibuat? | Spot air di kode: `sungai`, `empang`, `kolam`. v6.1: Kanal, Danau, Sungai, Spot 4. | Fase 3 | Perlu cek di Studio |
| T-18 | Kolam sekarang (`PondService`) dipertahankan atau diganti dengan Kolam Bab 7.2 (Tanah/Semen/Keramik, breeding)? | Sistem sekarang beda total. | Fase 5 | Terbuka |
| T-19 | Haptic: apakah ada API di Roblox untuk Android (`HapticService`) yang bisa dipakai di 4GB? | Tidak ada haptic di kode. v6.1 minta 5 momen. | Fase 10 | Perlu riset |
| T-20 | Target 10 player di HP 4GB: apakah tes ini sudah dijadwalkan? | Bab 30 minta tes nyata. | Fase 10 | Terbuka |
| T-21 | Apakah "Pesanan Harian" (Orders, 5 warga) dihapus, atau dipakai sebagai Agenda Harian? | Mirip tapi beda aturan. | Fase 6 | Usulan: ganti ke Agenda |
| T-22 | Perlu Update 1 & 2 (Bab 26) dikerjakan sekarang atau nanti? | v6.1 Bab 26 menulis konten Update 1–2. Scope rilis hanya sampai Fase 10. | — | Usulan: nanti |
