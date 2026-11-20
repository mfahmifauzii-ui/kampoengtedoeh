# KAMPOENG TEDOEH — Dokumen Gameplay Lengkap
## v6.2 — Single Source of Truth untuk Claude Code

> Dokumen ini menggantikan SEMUA versi sebelumnya (v1.0 sampai v6.1). Kalau ada konflik dengan dokumen lain, dokumen ini yang menang.
> Aturan revisi: setiap aturan hanya ditulis di SATU bab. Bab lain cukup merujuk (`lihat Bab X`). Tidak ada lagi aturan yang ditulis ulang di 3 tempat dengan angka beda.
> Revisi berikutnya wajib nomor baru (v6.3) + isi Changelog di Bab 0.3.

---

## 0. Ringkasan

### 0.1 Ringkasan 1 Paragraf

Kampoeng Tedoeh adalah game Roblox cozy farming + fishing + ranching + building berlatar kampung Indonesia, untuk HP Android 4GB, target umur 9-16 tahun, netral gender. Player adalah cucu Kakek Daeng yang pulang mengurus lahan warisan dan menemukan surat-surat yang ditinggalkan kakeknya. Tidak ada fail, tidak ada stamina, tidak ada hukuman. Tanaman, hewan, dan bangunan tidak pernah mati atau rusak. Sesi ideal 20-40 menit. Yang bikin player cerita ke temannya: **panen mutasi saat hujan petir, Ikan Legenda yang diumumkan ke satu server, dan Gerobak Kaget yang restock tiap 15 menit.** Yang bikin player balik besok: **bubu, kolam, Surat Kakek harian, Bundel Kakek (memulihkan bangunan peninggalan Kakek), dan Kerja Bakti Kilat setiap habis badai.** Tidak ada satu pun sistem yang butuh banyak player supaya bisa selesai.

Tagline tim: `Kampung lo, rumah lo, panen lo — tiap hujan petir bisa jadi panen emas.`

### 0.2 Target Desain (Angka yang Dikunci)

| Target | Angka | Bab Rujukan |
|--------|-------|-------------|
| Sesi ideal | 20-40 menit | Bab 2 |
| Player inti (2 jam/hari) capai Level Cap rilis (Lv 60) | ~32 hari | Bab 4, 17 |
| Player santai (45 menit/hari) di hari ke-30 | ~Lv 26 | Bab 4 |
| Konten rilis selesai saat Lv 60 | ~71% | Bab 17 |
| Level Cap naik | +20 tiap Update Besar (Lv 80 bulan ke-2, Lv 100 bulan ke-4) | Bab 26 |
| Retensi D1 / D7 / D30 | 35% / 15% / 6% | Bab 25 |
| Konversi bayar | 3% | Bab 18 |

### 0.3 Changelog v5.2 → v6.0 (Kenapa Berubah)

| # | Perubahan | Alasan |
|---|-----------|--------|
| 1 | Target main 5 jam/hari → 2 jam/hari (inti), 45 menit/hari (santai) | 5 jam/hari tidak realistis & tidak sehat untuk umur 9-16. Ekonomi dihitung ulang. |
| 2 | Level Cap rilis Lv 60, naik +20 tiap Update Besar | Konten rilis tidak cukup untuk 100 level. Cap naik = alasan balik tiap update. |
| 3 | Siang/malam pakai **hari game 30 menit**, bukan jam WIB | Anak main jam 15:00-18:00 tidak pernah lihat malam. Ikan malam jadi tidak terjangkau. |
| 4 | Sistem **Mutasi Panen** baru | Hook viral utama. Hujan jadi momen yang ditunggu, bukan cuma bonus kecil. |
| 5 | Ikan Dewa (1 per server per malam) → **3 Ikan Legenda per-player + pity** | Hilangkan rebutan & server hopping, tetap langka, tetap bisa diumumkan. |
| 6 | **Gerobak Kaget** (restock 15 menit) | Alasan ngecek toko, momen "eh ada Semangka Kotak!", tanpa FOMO yang menghukum. |
| 7 | **Surat Kakek** (30 surat, 1 per hari login, kumulatif) | Retensi emosional + cerita, bukan cuma angka. |
| 8 | **Lapak Tetangga + Kirim Hadiah** | Ekonomi antar-player yang aman untuk anak (tanpa barter, harga dikunci). |
| 9 | ~~Gotong Royong Mingguan global~~ (dihapus di v6.1, lihat 0.3.1) | - |
| 10 | Bonus % dari Dekor + Set + Title dikunci **max +25% per jenis** | Dulu bisa numpuk +40% dan merusak ekonomi. |
| 11 | Hanya **Dekor Berkah** (30 dari 80) yang punya stat | Dulu semua dekor punya stat, player jadi hias demi angka, bukan demi suka. |
| 12 | Bunga F2P ~220/bulan (dulu 394-604) + pack dibuat lebih worth | Dulu Bunga gratis terlalu banyak, pack tidak laku, SP kanibal pack. |
| 13 | Hadiah Playtime max 60 menit, Koin saja, tidak ada Bunga | Tidak memberi hadiah anak yang main 3 jam non-stop. Aman untuk orang tua. |
| 14 | Bang Jali menerima SEMUA barang (90%) | Dulu 3 penjual dengan aturan beda bikin bingung anak 9 tahun. |
| 15 | Cutscene + Coachmark: satu aturan saja (Bab 16.2) | Dulu 4 versi aturan skip yang saling bertabrakan. |
| 16 | Scope rilis dipotong (18 tanaman, 20 ikan, 3 hewan, 80 piece hias) | 36+36+178 terlalu berat. Sisanya masuk LiveOps (Bab 26). |
| 17 | 4 Gestur ramah (Lambai, Jempol, Tepuk, Ketawa) | Sosial butuh cara "ngomong" tanpa chat. Tetap tidak ada hug/joget. |
| 18 | Skala server 8 → 10 player + StreamingEnabled | Lebih ramai, tetap aman untuk HP 4GB. |

### 0.3.1 Changelog v6.0 → v6.1

| # | Perubahan | Alasan |
|---|-----------|--------|
| 1 | **Gotong Royong global DIHAPUS** | Target global lintas server bergantung jumlah player. Saat game masih sepi, target tidak pernah selesai dan player merasa sia-sia. |
| 2 | **Kerja Bakti Kilat** (Bab 13.4) menggantikan Kerja Bakti harian | Dipicu cuaca (setelah badai alun-alun kotor). Target dihitung dari player di server saat itu, jadi 1 player pun bisa 100%. Tidak butuh data global. |
| 3 | **Event Musiman + Pesanan Tamu** (Bab 13.5) | Hiasan alun-alun saat event dipasang otomatis dari Config (tidak tergantung setoran). Progres event 100% pribadi. |
| 4 | **Bundel Kakek** (Bab 14.5) + **Kondisi Awal Lahan** (Bab 3.4) | Lahan awal penuh ilalang + 5 bangunan Kakek yang rusak. Memulihkannya = tujuan jangka menengah pribadi + cerita + before/after yang enak di-screenshot. |
| 5 | Prinsip baru #16: Tidak bergantung jumlah player | Dikunci supaya sistem global serupa tidak masuk lagi. |
| 6 | Balai Gotong Royong → **Pos Ronda Nek Ani**. Alun-alun didefinisikan ulang: bulat, Pohon Beringin di tengah | Sesuai map yang sudah dibuat. |

### 0.3.2 Changelog v6.1 → v6.2 (Keputusan Owner, Fase 0)

| # | Perubahan | Alasan |
|---|-----------|--------|
| 1 | Max server **10 → 8** player. Jumlah lahan tetap **8** (bukan 10). Angka turunan ikut berubah: kotoran Kerja Bakti max **58** (`10 + 6 × 8`), perf & playtest pakai 8 player (Bab 3.1, 13.4, 24, 30). | T-01. Peta sudah 8 lahan. |
| 2 | Lahan awal **96 → 128** stud, kotak cadangan maksimal **192×192**. Sistem ekspansi 3 tahap (120/140/160) **dihapus** dari Bab 3.1, 4.4, 17.4. Diganti **beli chunk 32×32 stud** dengan harga naik (`1.500 × 1,2^n` Koin, dibulatkan 10), tanpa syarat level. | T-02. Sistem chunk sudah ada di kode (`Config/Plots`). |
| 3 | Sink "Ekspansi Lahan" **73.000 → 88.790** (14 chunk yang bisa dibeli). Total sink **607.000 → 623.000**. Konten rilis selesai saat Lv 60: **~73% → ~71%** (442.000 / 623.000). | T-02. Dihitung ulang dari `Config/Plots`. |
| 4 | Objek awal lahan (ilalang 40, semak 12, batu 8, tunggul 4, bangunan Kakek 5) dipertahankan. Posisinya dibuat untuk start 128×128, area bersih 24×24 tetap. Chunk yang dibeli juga dapat ilalang & semak (tanpa bangunan rusak). Bitmask hanya untuk 64 objek bersihkan (40+12+8+4); 5 bangunan dicatat di Bundel (Bab 14.5). | T-02. Memperjelas Bab 3.4 yang belum menyebut bitmask vs bangunan. |
| 5 | Grid Hias: **struktur snap 2 stud, furniture & dekor snap 1 stud** (sebelumnya: 1 sel 2×2, furniture 0,5 sel). Grid petak tanam tetap **8×8 stud**. | T-03. |
| 6 | Petak tanam **4×4 → 8×8 stud** (sesuai `Land.TILE`). Garap (bajak) tetap bebas di lahan sendiri, tetapi jumlah petak yang dibajak dibatasi tabel Bab 5.2 (6 di awal, 36 di Lv 25). Petak ke-n di atas 6 membayar `n × 150` Koin. | T-04. |
| 7 | Total petak 7–36 dikoreksi **94.000 → 96.750** Koin (sesuai rumus `n × 150`, sama dengan Bab 17.4). | Koreksi angka yang tidak konsisten di v6.1. |
| 8 | **NPC diganti nama** (Bab 10.1): Pak Darmo → **Pak Udin** (warung utama, tanpa kuota harian, beli hasil mentah 100%). Bu Wati dilebur ke Pak Udin. Mas Joko + Mbok Minah → **Kak Fajar** (joran & umpan, beli ikan 100%). Mbak Arsi → **Pak Amran**. **Mak Sari** di Warung Mak Sari (Shop 7), beli olahan 100%, sebelum Dapur terbuka hanya menampilkan baris sapaan. **Nek Ani** (Pos Ronda), **Pedagang Tamu**, **Tamu Event** ditambahkan. | T-05. |
| 9 | Bab 10.2: ikan hanya dibeli **Kak Fajar** (kolom Pak Udin untuk ikan dihapus). | Konsisten dengan T-05 (Mbok Minah hanya dilebur ke Kak Fajar). |
| 10 | **Bang Tarno ×8 → Bang Jali ×8**, satu di depan setiap lahan. Beli semua barang 90%, tidak menjual apa pun (Bab 10.2). **Lapak Tarno dihapus.** | T-06. |
| 11 | Daftar nama lama yang dilarang (Bab 10.1) diperluas: Bu Wati, Mbak Arsi, Bang Tarno, Pak RT, Bu Sari, Mbah Karto, Mas Yudi, Dik Rara. Villager Pesanan Harian diganti NPC v6.1 (Pak Udin, Kak Fajar, Pak Amran, Mak Sari, Nek Ani). | T-05, Bab 29 "Nama NPC lama". |
| 12 | Game Pass **`decor`** (+100 limit dekor) dan **`plots`** (diskon 20% harga lahan) dihapus. Keduanya tidak ada di Bab 18.4. | T-07. |
| 13 | Bab 18.5 & Bab 29: **Pass kapasitas kolam** dihapus (menjual slot kolam). Produk **Robux → Koin dihapus** (langgar Bab 29). | Penegasan Bab 18.5 & 29. Sudah sejak v6.0, kode lama masih punya. |
| 14 | Bab 12.5 & Bab 29: gestur **joget (`dance`) dan tunjuk (`point`) dihapus**. Gestur sah hanya 4: Lambai, Jempol, Tepuk Tangan, Ketawa. | Penegasan Bab 12.5. |
| 15 | Bab 15.2: hadiah Playtime **tanpa Bunga** (sudah tertulis di v6.1; kode lama masih memberi Bunga). Bab 4.1 & Bab 29 diperjelas. | Penegasan. |
| 16 | Bab 4.1 & Prinsip #12: **tidak ada Bunga dari level-up dan milestone level**. Milestone title lama dihapus. | Penegasan. Bunga hanya dari sumber di Bab 4.1. |
| 17 | Bab 19: **Premium Roblox tidak memberi pengali Koin apa pun** (termasuk hadiah pesanan). | Penegasan Bab 19. |
| 18 | Bab 13.4, 24, 30: kotoran Kerja Bakti max **70 → 58**; angka perf & playtest "10 player" → "8 player" (sebagai akibat #1). | T-01. |
| 19 | Bab 28: `PlayerData.version` **61 → 62**. `Lahan.Ukuran` **96 → 128**. Ditambah `Lahan.Chunk` (bitmask per chunk yang dibeli). **Tanpa kode migrasi**: save lama direset (game belum rilis). | T-08. |
| 20 | Bab 27 Fase 0: lahan **96×96 → 128×128** (kotak 192×192, chunk 32×32). | T-02. |
| 21 | Penutup: versi dokumen **v6.2**, revisi berikutnya v6.3. | Aturan revisi. |
| 22 | Bab 4.3: XP Lv 59→60 **1.970 → 2.170** (rumus `200 + 30 × n` menghasilkan 2.170; total 64.900 sudah benar). | Koreksi angka contoh di v6.1. |
| 23 | Bab 4.2 & 4.3: Level Cabang **dimulai dari Lv 0** (10 langkah XP, total 12.000 untuk Lv 10). | Supaya tabel 10 angka cocok dengan total 12.000. |
| 24 | Bab 3.2 & 15.1: reset harian **dan mingguan 05:00 WIB** (sebelumnya 00:00 WIB di kode). | T-11. |
| 25 | Bab 3.2 & 3.3: hari game 30 menit tetap; jam fase di kode disesuaikan ke 3/15/3/9 menit. | T-10. |

### 0.4 Self-Score v6.0 (Di Atas Kertas)

| Aspek | v5.2 | v6.0 | Yang Bikin Naik |
|-------|------|------|-----------------|
| Nanem | 80 | 90 | Mutasi + cuaca terhubung |
| Mancing | 78 | 90 | Legenda per-player + pity + pengumuman |
| Ternak + Kolam + Bubu | 72 | 85 | Siklus lebih pendek, pas jadwal sekolah |
| Hias + Nambang | 80 | 90 | Nambang ritme (skill), Dekor Berkah, Pajangan Panen |
| Dapur | 62 | 82 | 9 resep, Bang Jali terima semua |
| Quest & Progresi | 76 | 91 | Surat Kakek, Agenda Harian, Level Cap bertahap |
| Sosial | 58 | 87 | Lapak, Hadiah, Gestur, Kerja Bakti Kilat |
| Ekonomi | 70 | 90 | Target realistis, cap bonus, faucet/sink terhitung |
| Monetisasi | 60 | 88 | Kosmetik, pet, pack worth, LTV naik tanpa P2W |
| Experience | 86 | 92 | Ditambah momen pengumuman & mutasi |
| GUI | 78 | 88 | Satu layout final, tanpa revisi berlapis |
| Kelayakan Scope | 52 | 88 | MVP dipotong, LiveOps terjadwal |
| Kualitas Dokumen | 58 | 95 | 1 aturan = 1 tempat |
| **Rata-rata** | **71** | **~90** | |

> Catatan jujur: skor 90 ini skor desain. Skor akhir tetap ditentukan eksekusi (game feel, performa HP 4GB, thumbnail, dan kecepatan update).

---

## 1. Prinsip Desain — LOCKED

| # | Prinsip | Artinya di Kode |
|---|---------|-----------------|
| 1 | Cozy, tanpa fail | Tanaman tidak mati/layu. Hewan tidak mati/sakit/kabur. Bangunan tidak roboh. Quest tidak gagal karena waktu. Hapus bangunan refund 100%. |
| 2 | Tanpa stamina | Tidak ada energi. Batas main hanya dari waktu tumbuh, bukan dari bar energi. |
| 3 | Siram itu bonus | Tanaman tumbuh tanpa siram. Siram mempercepat + menaikkan peluang Mutasi. |
| 4 | Tanpa pupuk, tanpa hama | Tidak ada item pupuk. Tidak ada hama. Tidak ada efek "tahan hama". |
| 5 | Langka itu momen, bukan rebutan | Semua kelangkaan dihitung per-player (pity), tidak ada barang langka yang "habis" karena player lain. |
| 6 | Hias karena suka | Hanya Dekor Berkah yang punya stat. Mayoritas dekor murni visual. |
| 7 | Hias per-satuan | Tidak ada rumah jadi. Tidak ada Robux / Bunga untuk beli rumah jadi atau skip bangun. |
| 8 | Lahan 100% bebas | Tidak ada zona dikunci di dalam lahan. Ghost merah muda hanya jika nabrak / di luar lahan. |
| 9 | Waktu itu server | Hari game, cuaca, reset harian diatur server. Tidak ada furniture yang memajukan waktu. |
| 10 | HP 4GB adalah target | RAM 4GB, Helio G99 / Unisoc T7250. Semua cap & render untuk HP ini. |
| 11 | Dua ekonomi terpisah | Koin (main) dan Bunga (premium) tidak bisa ditukar dua arah. |
| 12 | Bunga = kenyamanan & gaya, bukan kekuatan | Bunga membeli QoL, kosmetik, waktu. Tidak membeli Koin, XP, level, bahan mentah, hewan. Semua konten bisa dicapai F2P. |
| 13 | Sehat untuk anak | Tidak ada hadiah untuk main >60 menit non-stop. Tidak ada streak yang reset. Tidak ada loot box. Tidak ada iklan. |
| 14 | Jangan terlalu diinfokan | UI tampilkan angka & ikon. Tidak ada paragraf penjelasan. Info pertama kali = toast 1x, lalu diam. |
| 15 | 1 aturan, 1 tempat | Kode & dokumen: setiap angka hanya didefinisikan di 1 Config. |
| 16 | Tidak bergantung jumlah player | Tidak ada target / progres yang butuh banyak player atau lintas server untuk selesai. Target bersama selalu dihitung dari player di server saat itu. Semua progres jangka panjang bersifat pribadi. Game harus tetap lengkap dimainkan walau server cuma berisi 1 orang. |

---

## 2. Target Pemain & Bentuk Sesi

### 2.1 Persona

| Persona | Umur | Main | Yang Dicari | Ditangkap Oleh |
|---------|------|------|-------------|----------------|
| **Dika Santai** | 9-11 | 30-45 menit/hari, HP ibu | Lucu, gampang, pamer ke teman | Tutorial cepat, hewan lucu, Mutasi, Gestur |
| **Nisa Dekorator** | 11-14 | 1-2 jam/hari | Rumah cantik, foto, like | Hias, Blueprint, Galeri Kampung, Lemari Gaya |
| **Raka Kolektor** | 12-16 | 2+ jam/hari | Lengkap 100%, langka | Album, Ikan Legenda, Mutasi Pelangi, Level Cap |
| **Player Roblox Umum** | 10-16 | Coba 5 menit dulu | Ada yang seru di menit pertama | FTUE Bab 16, panen pertama dijamin Super |

### 2.2 Bentuk Sesi 30 Menit (Contoh, Bukan Paksaan)

| Menit | Aktivitas | Sistem |
|-------|-----------|--------|
| 0-3 | Login, ambil bubu + telur + anak kolam, buka Surat Kakek | Bab 7, 14.2 |
| 3-10 | Panen + tanam ulang, cek Gerobak Kaget | Bab 5, 13.1 |
| 10-20 | Mancing (sering pas hujan) | Bab 6 |
| 20-25 | Nambang 1 putaran | Bab 8 |
| 25-30 | Hias 1-2 piece / Lapak / bantu tetangga, tanam Late sebelum logout | Bab 8, 12 |

### 2.3 Batas Sehat (LOCKED)

- Hadiah Waktu Bermain hanya sampai 60 menit (Bab 15.2). Setelah 60 menit tidak ada hadiah tambahan.
- Setelah 120 menit main dalam 1 hari WIB, muncul toast lembut 1x: `Udah 2 jam nih. Jangan lupa minum & istirahat ya!` Tidak mengunci, tidak menghukum.
- Tidak ada streak yang reset. Semua login reward kumulatif.

---

## 3. Dunia, Lahan, Server, Waktu & Cuaca

### 3.1 Dunia

| Item | Spesifikasi |
|------|-------------|
| Server | Max 8 player (T-01). StreamingEnabled ON. |
| Peta Server | Alun-alun di tengah, 8 lahan melingkar (2 per jalan sumbu), Kanal + Danau + Sungai di sisi timur, Hutan Nambang di sisi barat. |
| Lahan Awal | 128x128 stud. Kotak cadangan maksimal 192x192 stud (6×6 chunk). |
| Beli Chunk | Lahan bertambah per chunk 32×32 stud, dari dalam lahan yang sudah dimiliki. Harga chunk ke-n (n mulai 0): `1.500 × 1,2^n` Koin, dibulatkan 10. Tanpa syarat level. 14 chunk bisa dibeli (kolom depan tidak bisa dibeli). Total 88.790 Koin. Lihat Bab 17.4. |
| Grid | Petak tanam 8×8 stud (`Land.TILE`). Hias: struktur snap 2 stud, furniture & dekor snap 1 stud. Rotasi 0/90/180/270. |
| Alun-alun | Bentuk bulat, **Pohon Beringin besar di tengah** (landmark, terlihat dari semua lahan). Pelataran di bawah beringin = tempat Tamu Event + panggung saat Event Musiman. Melingkar di sekeliling: Toko Pak Udin, Warung Mak Sari, Tukang Kayu Pak Amran, Pos Ronda Nek Ani, Gerobak Kaget, Papan Agenda, Papan Galeri Kampung, Papan Lapak Tetangga. |
| Hutan Nambang | Area bersama (bukan map terpisah), node bahan per-player (tidak rebutan). |
| Perairan | Kanal (Early), Danau (Mid), Sungai (Mid/Late) — 4 spot mancing. Kak Fajar di pinggir Kanal. |

### 3.2 Hari Game (LOCKED)

1 hari game = **30 menit nyata**, berjalan terus selama server hidup.

| Fase | Durasi Nyata | Visual | Gameplay |
|------|--------------|--------|----------|
| Pagi | 3 menit | Kabut tipis, ayam berkokok | Gurame Raja hanya Pagi (Bab 6.5) |
| Siang | 15 menit | Cerah warm | Normal |
| Sore | 3 menit | Oranye lembut, jangkrik mulai | Normal |
| Malam | 9 menit | Biru gelap, lampu warm otomatis, kunang-kunang | Ikan malam, Pasar Malam (Bab 13.2) |

- Reset harian (Agenda, Login, Bantu, batas hadiah Kerja Bakti Kilat) tetap **05:00 WIB** kalender nyata.
- HUD menampilkan ikon fase (☀️/🌅/🌙), bukan jam digital.

### 3.3 Cuaca (LOCKED — Satu-satunya Definisi Cuaca)

| Aturan | Detail |
|--------|--------|
| Siklus | Terik **8-15 menit** (random per siklus) → Hujan **3 menit** → Terik 8-15 menit → dst. Tidak pernah hujan 2x berturut-turut. |
| Jenis hujan | Gerimis 55%, Deres 30%, Petir 15%. Di-roll saat Terik habis. |
| Pelangi | Setelah Hujan Deres atau Petir selesai, 40% chance Pelangi muncul **60 detik**. |
| Tidak ada salju | Tidak ada salju / es / musim dingin. |
| Tidak mengunci | Semua aktivitas tetap bisa saat hujan. Kecepatan jalan tidak berubah. |

| Cuaca | Visual | Efek Gameplay |
|-------|--------|---------------|
| Terik | Langit biru, cahaya kuning | Nambang +10% bahan |
| Gerimis | Partikel 30, `tik-tik` | Semua tanaman luar tersiram 1x. Mutasi Embun aktif (Bab 5.4). Mancing +5% peluang Langka |
| Deres | Partikel 80, `syuuu`, genangan | Tersiram 1x. Mutasi Embun aktif. Mancing +10% peluang Langka. **Setelah reda: memicu Kerja Bakti Kilat (Bab 13.4).** |
| Petir | Partikel 80, kilat tiap 20 detik, `DUAR` | Tersiram 1x. **Mutasi Petir aktif.** Mancing +15% Langka. Lemparan pertama setelah kilat dijamin ikan min. Mid. Belut Emas hanya muncul di sini. **Setelah reda: memicu Kerja Bakti Kilat versi besar (ada Dahan Beringin patah).** |
| Pelangi | Pelangi di langit 60 detik + kilau di tanaman | **Mutasi Pelangi aktif** untuk tanaman yang dipanen selama Pelangi. |

- HUD: ikon cuaca + timer kecil (`Hujan 07:32` / `Hujan: 02:15`).
- Info pertama kali tiap jenis cuaca: toast 1x per akun (bukan per sesi), lalu tidak muncul lagi.

### 3.4 Kondisi Awal Lahan — "Lahan Kakek yang Gak Keurus" (v6.1, LOCKED)

Lahan baru sengaja kelihatan terbengkalai. Itu cerita pulang kampung, dan before/after-nya jadi kebanggaan player.

| Objek Awal | Jumlah | Aturan | Hasil Dibersihkan |
|------------|--------|--------|-------------------|
| Area bersih awal | 1 area 24x24 | Sudah bersih: 6 petak + rangka rumah + jalan setapak ke gerbang | - |
| Ilalang | 40 rumpun | 1 tap (alat apa saja / tangan). Tidak tumbuh lagi. | 1 Jerami |
| Semak | 12 | 2 tap | 1 Kayu + 10% 1 Bambu |
| Batu Kecil | 8 | 2 tap | 2 Batu |
| Tunggul Pohon | 4 | 3 tap | 3 Kayu |
| Bangunan Kakek Rusak | 5 | Lihat Bundel Kakek (Bab 14.5) | Dipulihkan, bukan dibersihkan |

- **Tidak mengunci lahan (Prinsip #8):** menaruh petak / piece Hias / kandang di atas ilalang, semak, batu kecil, atau tunggul = objek itu otomatis dibersihkan dan bahannya masuk tas. Ghost tetap hijau.
- Posisi objek awal di-generate dari 1 template tetap (sama untuk semua player), disimpan sebagai bitmask `LahanAwal` (1 bit per objek, 64 objek = 8 byte).
- Chunk yang dibeli (Bab 3.1) juga berisi ilalang & semak (template per chunk, kepadatan sama dengan lahan awal) — tanpa bangunan rusak.
- Posisi objek dibuat untuk lahan awal 128×128. Bitmask hanya untuk 64 objek bersihkan (ilalang 40 + semak 12 + batu 8 + tunggul 4). 5 bangunan Kakek dicatat di Bundel (Bab 14.5), bukan di bitmask.
- Pencapaian kecil: bersihkan semua objek awal → `Lahan Kakek Bersih` + 200 Koin + dekor Papan Nama Lahan.

---

## 4. Mata Uang & Level

### 4.1 Mata Uang

| Mata Uang | Dapat Dari | Dipakai Untuk | Bisa Ditukar? |
|-----------|-----------|---------------|---------------|
| **Koin** | Jual hasil, Agenda, Bantu, Lapak, Kerja Bakti | Bibit, umpan, pakan, hewan, alat, petak, ekspansi, skill | Tidak ke Bunga |
| **Bunga** | Peti Bunga, Login Mingguan, Pencapaian, Season, Event, Robux | Alat Bunga (QoL), Dekor Bunga, kosmetik, pet, instant | Tidak ke Koin |
| **Bahan** | Nambang, panen tertentu (Padi → Jerami) | Craft piece hias, alat, kandang | Tidak dijual di toko mana pun |
| **Skill Point (SP)** | 1 per naik Level Player | Skill Cabang (+ Koin) | Tidak |

### 4.2 Level Player vs Level Cabang (JANGAN TERTUKAR)

| Jenis | Max | Naik Dari | Fungsi |
|-------|-----|-----------|--------|
| **Level Player** | **Cap rilis 60** (Lv 80 Update 1, Lv 100 Update 2) | XP dari semua aktivitas | **Membuka konten** (tanaman, ikan, hewan, area, fitur) + 1 SP per level |
| Level Cabang: Bertani, Mancing, Beternak, Tukang | Lv 10 masing-masing | XP Cabang dari aktivitas itu saja | Membuka **alat** cabang itu + syarat skill |

Aturan untuk anak 9 tahun: **"Konten baru = Level Player. Alat baru = Level Cabang."** Tidak ada syarat campuran selain yang tertulis di tabel unlock.

### 4.3 Rumus XP (LOCKED)

- XP naik dari Lv `n` ke `n+1` = `200 + 30 × n`
- Lv 1→2: 230 XP. Lv 20→21: 800 XP. Lv 59→60: 2.170 XP. Lv 99→100: 3.170 XP.
- Total Lv 1→60: ~64.900 XP. Total Lv 1→100: ~168.300 XP.

| Fase | Level | XP / Jam (Rata-rata) | Koin / Jam (Rata-rata) | Jam ke Fase Ini Selesai |
|------|-------|----------------------|------------------------|--------------------------|
| Awal | 1-20 | 700 | 2.000 | ~14 jam |
| Tengah | 21-45 | 1.000 | 6.000 | ~29 jam |
| Akhir | 46-60 | 1.300 | 12.000 | ~20 jam |
| **Total ke Cap 60** | | | | **~63 jam ≈ 32 hari × 2 jam** |

- Player santai 45 menit/hari × 30 hari = 22,5 jam ≈ Lv 26.
- XP Cabang: setiap aksi memberi XP Player DAN XP Cabang dengan angka yang sama. Cabang Lv 10 butuh 12.000 XP Cabang (tabel: 300, 600, 900, 1.200, 1.500, 1.500, 1.500, 1.500, 1.500, 1.500).

### 4.4 Tabel Buka Konten per Level Player (LOCKED)

| Lv | Yang Kebuka |
|----|-------------|
| 1 | Nanem (Kangkung, Bayam), Mancing Kanal, Rumah Pertama, bersihkan lahan (Bab 3.4) |
| 2 | Tomat, Sawi, Bang Jali |
| 3 | Jagung, Ubi Jalar, **Bundel: Kolam Kakek** (lalu Kolam Tanah tambahan bisa dibeli) |
| 4 | Hutan Nambang + Meja Crafting |
| 5 | Ayam + Kandang Ayam, Danau |
| 6 | Singkong, Bubu, Dapur Tier 1, **Bundel: Sumur Tua** |
| 8 | Cabai, Padi, Lapak lihat-saja |
| 10 | Bebek, Sungai (Spot 3), Rak Pajangan Panen, petak 13-24 |
| 12 | Stroberi, **Bundel: Lumbung Kakek** |
| 15 | Pisang, Tebu, Kolam Semen, Dapur Tier 2, Pohon Aren (Ijuk), Bingkai Album |
| 18 | Spot 4 (Sungai Malam) |
| 20 | Lapak Tetangga (jual), Kirim Hadiah, **Bundel: Saung Kakek** |
| 22 | Sapi + Kandang Sapi, Jahe |
| 25 | Kopi, Teh, Akuarium, Greenhouse, Kaca, petak 25-36 |
| 30 | Kolam Keramik, Melati, **Bundel: Empang & Dermaga Kakek** |
| 35 | Dapur Tier 3, Mangga |
| 40 | Bubu Besi, Rumah 2 Lantai (atap & tangga tingkat) |
| 45 | Durian |
| 50 | Atap Joglo (set Joglo) |
| 60 | Title `Warga Kampoeng Tedoeh`, Mahkota Lampion (dekor) |
| 61-100 | Diisi Update 1 & 2 (Bab 26) |

### 4.5 Skill Cabang

- Tiap cabang 4 skill × 5 level. Biaya per level: Lv1 500 Koin + 1 SP, Lv2 1.000 + 1 SP, Lv3 2.000 + 1 SP, Lv4 4.000 + 1 SP, Lv5 7.500 + 1 SP. **Per skill: 15.000 Koin + 5 SP.**
- Syarat skill Lv N: Level Cabang ≥ 2N.
- Total semua skill (16): 240.000 Koin + 80 SP. Player Lv 60 punya 59 SP → sengaja belum penuh, sisanya di Update 1.

| Cabang | Skill 1 | Skill 2 | Skill 3 | Skill 4 |
|--------|---------|---------|---------|---------|
| Bertani | Tangan Hijau: tumbuh +2%/lv | Bibit Hemat: 4%/lv bibit kembali saat panen | Mata Embun: peluang Mutasi +0,4%/lv (absolut) | Panen Raya: +2% Koin Nanem/lv |
| Mancing | Mata Elang: kotak +1%/lv | Tangan Sabar: ikan 4% lebih lambat/lv | Firasat: pity Legenda -10 lemparan/lv | Umpan Hemat: 6%/lv umpan tidak terpakai |
| Beternak | Kandang Nyaman: cooldown -3%/lv | Tempat Pakan Besar: Lv3 & Lv5 +1 jatah siklus | Kolam Subur: breeding -4%/lv | Peternak Pasar: +2% Koin Ternak/lv |
| Tukang | Ayunan Mantap: Critical lebih lebar 4%/lv | Bahan Bonus: +3% bahan/lv | Hemat Bahan: 4%/lv bahan kembali saat craft | Gerobak: Lv5 bahan nambang langsung masuk tas tanpa diambil |

> Prinsip: setiap Alat Bunga punya versi Koin (Bab 17.5) atau skill dengan efek mirip. Alat Bunga sedikit lebih nyaman + lebih cepat didapat, tapi F2P tidak tertinggal jauh.

---

## 5. NANEM — Semi-Pasif, Core

### 5.1 Loop

Pilih petak kosong → Tanam bibit (bayar bibit) → Tumbuh (jalan walau offline) → Siram opsional → Panen (Koin + XP + roll Super + roll Mutasi) → Petak kosong, tanam lagi.

- Satu aksi tanam / panen ≈ 1 detik aktif per petak. 12 petak ≈ 30 detik.
- **Siram:** mengurangi sisa waktu tumbuh 15% (sekali per fase tumbuh, max 1x per tanaman per siklus) + menandai tanaman `Basah` (dibutuhkan Mutasi Emas, Bab 5.4). Hujan otomatis menyiram semua tanaman luar 1x.
- **Telat panen:** tanaman jadi sedikit lebih besar (scale 1,1), tidak layu, tidak hilang.

### 5.2 Petak

| Item | Aturan |
|------|--------|
| Petak awal | 6 |
| Max rilis | 36 |
| Buka petak ke-n | `n × 150` Koin (petak 7 = 1.050, petak 36 = 5.400). Total petak 7-36 = 96.750 Koin. Syarat: petak 7-12 tanpa level, petak 13-24 butuh Lv 10, petak 25-36 butuh Lv 25. |
| Ukuran petak | 8×8 stud (`Land.TILE`). Garap (bajak) bebas di mana saja di lahan sendiri; jumlah petak yang dibajak dibatasi baris di atas. |
| Greenhouse | Lv 25 (Bertani Lv 6), 2x3 petak, tanaman di dalam tumbuh 10% lebih cepat, tidak kena hujan (tidak ikut Mutasi Embun/Petir, tapi bisa Emas). Pilihan strategi, bukan upgrade wajib. |

### 5.3 Tanaman Rilis (18) — LOCKED

Aturan harga: Bibit ≈ 30% harga jual. Late harus 30-50x Early karena waktu tunggunya 60-120x dan cocok untuk offline.

| # | Tanaman | Tier | Waktu | Bibit | Jual | XP | Buka Lv |
|---|---------|------|-------|-------|------|----|---------|
| 1 | Kangkung | Early | 4 mnt | 8 | 25 | 12 | 1 |
| 2 | Bayam | Early | 6 mnt | 10 | 32 | 15 | 1 |
| 3 | Tomat | Early | 7 mnt | 12 | 36 | 16 | 2 |
| 4 | Sawi | Mid | 20 mnt | 25 | 80 | 35 | 2 |
| 5 | Jagung | Mid | 30 mnt | 35 | 110 | 45 | 3 |
| 6 | Ubi Jalar | Early | 8 mnt | 12 | 38 | 18 | 3 |
| 7 | Singkong | Mid | 25 mnt | 30 | 95 | 40 | 6 |
| 8 | Cabai | Mid | 30 mnt | 40 | 125 | 50 | 8 |
| 9 | Padi | Late | 2 jam | 120 | 400 | 140 | 8 |
| 10 | Stroberi | Late | 2 jam | 130 | 420 | 150 | 12 |
| 11 | Pisang | Late | 3 jam | 160 | 520 | 180 | 15 |
| 12 | Tebu | Mid | 40 mnt | 50 | 160 | 60 | 15 |
| 13 | Jahe | Mid | 35 mnt | 45 | 140 | 55 | 22 |
| 14 | Kopi | Late | 4 jam | 200 | 650 | 220 | 25 |
| 15 | Teh | Late | 6 jam | 260 | 850 | 280 | 25 |
| 16 | Melati | Mid | 30 mnt | 40 | 130 | 50 | 30 |
| 17 | Mangga | Late | 8 jam | 320 | 1.100 | 360 | 35 |
| 18 | Durian | Late | 8 jam | 380 | 1.300 | 400 | 45 |

- Padi juga memberi 2 Jerami per panen (bahan). Jagung bisa jadi pakan ayam di Dapur (Bab 9).
- **Super Panen:** base 5%, +5% jika Basah. Super = 2x Koin + 50% XP.

### 5.4 Mutasi Panen (BARU, Hook Viral Utama) — LOCKED

Saat panen, server roll Mutasi. Mutasi menempel di hasil panen (item jadi `Kangkung Emas`, dll). Hanya 1 Mutasi per hasil panen (yang paling tinggi menang).

| Mutasi | Syarat | Peluang | Harga Jual | Visual |
|--------|--------|---------|------------|--------|
| **Embun** | Tanaman **selesai tumbuh** saat Gerimis/Deres | 20% | x1,5 | Butir embun berkilau |
| **Petir** | Tanaman selesai tumbuh saat Hujan Petir | 10% | x3 | Kilatan biru kecil, suara `zzt` |
| **Emas** | Tanaman Basah saat panen (kapan saja) | 1% | x5 | Emas mengkilap, partikel emas |
| **Pelangi** | Dipanen saat Pelangi aktif (60 detik) | 3% | x10 | Gradasi pelangi, partikel 7 warna |

- Skill Mata Embun menambah peluang absolut (+0,4%/lv, max +2%) ke semua Mutasi.
- **Pengumuman server:** Mutasi Pelangi + Emas pada tanaman Late → banner kecil ke semua player di server: `🌈 Nisa panen DURIAN PELANGI!` (3 detik, atas tengah, tidak mengunci).
- **Pajangan Panen:** hasil Mutasi bisa dipajang sebagai dekor (Rak Pajangan, Bab 8.6) — tidak dijual = jadi pamer.
- Album Kampung mencatat setiap kombinasi Tanaman × Mutasi pertama kali (18 × 4 = 72 entri).
- Desain sengaja: player **menunda panen / menanam pas mau hujan** → hujan jadi momen "semua orang lari ke ladang". Itu momen yang bisa direkam & di-share.

### 5.5 Fitur Nanem Lain

| Fitur | Aturan |
|-------|--------|
| Pasar Harian | 2 tanaman +30% per hari WIB (1 Early, 1 Mid/Late). Berlaku di semua penjual. Ikon koin kecil di atas petak yang laku. |
| Rotasi | Tanam beda dari siklus lalu di petak yang sama: +5% XP. Tidak ada hukuman jika sama. |
| Orang-orangan Sawah | Dekor Berkah, +3% Super radius 5 petak. |
| Bantu Tetangga | Siram & panen di lahan teman, lihat Bab 12.2. |

---

## 6. MANCING — Aktif, Fokus Pendek

### 6.1 Loop

Pergi ke spot → Pilih umpan → Lempar (0,6 detik) → Tunggu gigitan (3-6 detik pakai umpan, 6-12 detik tanpa umpan) → Gigitan: jendela 1,5 detik untuk mulai tarik → Tarik (mini-game) → Dapat ikan (kartu ikan) → Ulangi.

- Satu siklus 10-25 detik.
- Umpan dan jual ikan bisa dilakukan di **Lapak Kak Fajar** di pinggir Kanal (beli umpan, jual ikan 100%) — player tidak perlu bolak-balik ke Alun-alun.
- Jalan menjauh >8 stud dari spot = pancingan ketarik otomatis, umpan kembali (tidak hilang).

### 6.2 Mini-game Tarik

- Bar horizontal, ikon ikan gerak kiri-kanan, kotak player digeser (Tahan = kanan, Lepas = kiri).
- Progress mulai 30%. Ikan di kotak +15%/detik, di luar -10%/detik. 100% = dapat. 0% = lepas, umpan hilang, tidak ada hukuman lain.
- Perilaku: Early pelan & mudah ditebak (5-8 detik), Mid sering ganti arah (10-15 detik), Late cepat + dash (15-25 detik), Legenda dash + pause tiba-tiba (20-30 detik).
- **Mode Bantu (Settings, default OFF):** kotak +10% lebar & ikan 15% lebih lambat, untuk anak kecil / aksesibilitas. Tidak ada pengurangan hadiah.

### 6.3 Joran & Umpan

| Joran | Harga | Kotak | Syarat |
|-------|-------|-------|--------|
| Bambu | Gratis (tutorial) | 30% | Mancing Lv 1 |
| Kayu | 900 Koin + 10 Bambu | 33% | Mancing Lv 2 |
| Kayu Jati | 3.500 Koin + 20 Bambu | 36% | Mancing Lv 4 |
| Bambu Wulung | 9.000 Koin + 30 Bambu | 39% | Mancing Lv 6 |
| Besi | 18.000 Koin + 30 Bambu + 15 Batu | 42% | Mancing Lv 8 |
| Pusaka | 35.000 Koin + 40 Bambu + 20 Batu + 10 Ijuk | 45% | Mancing Lv 10 |

| Umpan | Harga | Efek |
|-------|-------|------|
| Cacing | 10 Koin | Standar |
| Jangkrik | 25 Koin | Gigitan 30% lebih cepat |
| Pelet | 45 Koin | +15% peluang Mid+ |
| Udang Kecil | 80 Koin (Mancing Lv 6) | +10% peluang Late+ |

### 6.4 Ikan Rilis (20) — LOCKED

Berat di-roll per tangkapan: Kecil x0,8 (40%), Sedang x1,0 (40%), Besar x1,2 (15%), Jumbo x1,5 (5%). Harga di tabel = Sedang.

| # | Ikan | Tier | Spot | Waktu | Jual | XP | Buka Lv |
|---|------|------|------|-------|------|----|---------|
| 1 | Wader Cakul | Early | Kanal | Kapan saja | 20 | 10 | 1 |
| 2 | Betok | Early | Kanal | Kapan saja | 26 | 12 | 1 |
| 3 | Sepat | Early | Kanal | Kapan saja | 30 | 14 | 2 |
| 4 | Lele | Early | Kanal | Malam | 45 | 18 | 2 |
| 5 | Mujair | Mid | Danau | Kapan saja | 70 | 26 | 5 |
| 6 | Nila | Mid | Danau | Kapan saja | 90 | 32 | 5 |
| 7 | Tawes | Mid | Danau | Siang | 110 | 38 | 6 |
| 8 | Gurame | Mid | Danau | Kapan saja | 160 | 50 | 8 |
| 9 | Patin | Mid | Sungai | Kapan saja | 180 | 55 | 10 |
| 10 | Gabus | Mid | Sungai | Hujan | 200 | 60 | 10 |
| 11 | Baung | Mid | Sungai | Malam | 220 | 65 | 12 |
| 12 | Jelawat | Late | Sungai | Kapan saja | 350 | 95 | 15 |
| 13 | Toman | Late | Sungai | Sore/Malam | 420 | 110 | 18 |
| 14 | Tapah | Late | Spot 4 | Malam | 600 | 150 | 18 |
| 15 | Sidat | Late | Spot 4 | Malam + Hujan | 650 | 160 | 22 |
| 16 | Semah | Late | Danau | Pagi | 520 | 130 | 25 |
| 17 | Belida | Late | Spot 4 | Kapan saja | 700 | 170 | 30 |
| 18 | **Gurame Raja** | Legenda | Danau | Pagi | 2.200 | 550 | 15 |
| 19 | **Belut Emas** | Legenda | Kanal | Hujan Petir | 2.000 | 500 | 20 |
| 20 | **Ikan Dewa** | Legenda | Spot 4 | Malam | 2.500 | 600 | 30 |

### 6.5 Ikan Legenda — Per-Player + Pity (LOCKED)

| Aturan | Detail |
|--------|--------|
| Peluang | 0,5% per lemparan **jika** spot + waktu/cuaca cocok dan Level cukup. |
| Pity | Counter per player per jenis Legenda, hanya naik saat lemparan di kondisi yang cocok. Lemparan ke-**200** dijamin Legenda (dikurangi skill Firasat, min 150). Counter reset setelah dapat. |
| Per-player | Tidak ada batas per server. Player lain tidak mengurangi peluang lo. Tidak ada alasan server hopping. |
| Firasat | Saat pity ≥ 75%, Kak Fajar (kalau dekat) bubble: `Airnya lagi tenang banget... firasatku bagus.` + gelembung emas di pelampung. Tidak ada angka pity di UI. |
| Pengumuman | Dapat Legenda → banner ke semua player di server: `🌟 Raka dapet IKAN DEWA (Jumbo)!` 3 detik + fanfare kecil untuk semua. |
| Tidak bisa dibiakkan | Legenda tidak bisa masuk kolam breeding. Bisa dipajang di Akuarium (Bab 8.6) atau dijual. |
| Tidak bisa dijual di Lapak / dihadiahkan | Biar tidak jadi barang dagangan. |

### 6.6 Bubu (Overnight)

| Bubu | Harga | Isi per Panen | Waktu | Max |
|------|-------|---------------|-------|-----|
| Bambu | 400 Koin + 10 Bambu | 3-4 ikan Early | 6 jam | 3 bubu total |
| Kayu | 1.500 Koin + 20 Kayu | 4-6 ikan Early/Mid | 6 jam | (gabungan semua tipe) |
| Besi | 4.000 Koin + 15 Batu + 10 Kayu | 6-8 ikan Mid, 5% 1 ikan Late | 6 jam | |

- 6 jam = pas untuk "pasang sebelum sekolah, panen pulang sekolah" atau "pasang malam, panen pagi".
- Bubu TIDAK bisa di-instant pakai Bunga. Bubu tidak pernah memberi Legenda.

---

## 7. TERNAK + KOLAM — Pasif

### 7.1 Ternak Darat

Loop: Beli hewan → Isi Tempat Pakan (beli pakan) → Produksi jalan walau offline → Ambil produk → Jual / olah.

- Hewan tidak mati/sakit/kabur. Tidak ada daging. Produk: telur, susu (wol di Update 1).
- **Tempat Pakan (anti-AFK, LOCKED):** tiap kandang menampung max **3 jatah siklus** (skill Tempat Pakan Besar: max 5). Setiap 1 siklus produksi memakai 1 jatah per ekor. Jatah habis = produksi berhenti (hewan tetap sehat, idle lucu). Produk menumpuk max 3 per ekor; kalau penuh, produksi berhenti sampai diambil.

| Hewan | Buka Lv | Harga / Ekor | Max (Kandang Lv1/Lv2) | Pakan / Jatah | Produk | Cooldown | Jual | XP |
|-------|---------|--------------|------------------------|---------------|--------|----------|------|----|
| Ayam | 5 | 300 Koin | 6 / 10 | 15 Koin | Telur Ayam | 15 mnt | 40 | 10 |
| Bebek | 10 | 600 Koin | 5 / 8 | 20 Koin | Telur Bebek | 20 mnt | 55 | 13 |
| Sapi | 22 | 3.500 Koin | 2 / 4 | 30 Koin | Susu | 30 mnt | 160 | 28 |

| Kandang | Bangun | Upgrade ke Lv 2 |
|---------|--------|------------------|
| Ayam (12x12) | 800 Koin + 15 Kayu | 3.000 Koin + 20 Papan |
| Bebek (14x14) | 1.200 Koin + 20 Kayu | 5.000 Koin + 25 Papan + 10 Bata |
| Sapi (18x16) | 4.000 Koin + 30 Kayu + 15 Bata | 10.000 Koin + 30 Bata + 15 Semen |

- **Pakan Jagung:** 5 Jagung di Dapur → 6 jatah Pakan Ayam (alternatif gratis dari ladang sendiri, mengikat Nanem ke Ternak).
- Sesi ternak ideal: 1-2 menit (isi pakan semua kandang + ambil semua produk dengan 1 tombol `Ambil Semua` di depan kandang).

### 7.2 Kolam (Bagian dari Beternak)

Loop: Simpan 2 ikan sejenis (non-Legenda) → Isi Pakan Ikan (20 Koin / siklus) → Tunggu → 1 anak ikan → Jual / jadi indukan.

| Tier Kolam | Buka Lv | Harga | Waktu Breeding | Kapasitas Simpan |
|------------|---------|-------|----------------|------------------|
| Tanah | 3 | 1.000 Koin + 20 Batu | 6 jam | 10 ikan |
| Semen | 15 | 3.000 Koin + 20 Bata + 15 Semen | 5 jam | 20 ikan |
| Keramik | 30 | 6.000 Koin + 30 Bata + 25 Semen | 4 jam | 30 ikan |

- Max 4 kolam. **Kolam pertama = Kolam Kakek** (didapat dari Bundel Kakek, Bab 14.5): tier Tanah, gratis, breeding 10% lebih cepat dari kolam biasa, bisa di-upgrade ke Semen/Keramik dengan harga normal. Kolam ke-2 sampai ke-4 dibeli (Kolam Tanah bisa dibeli setelah Kolam Kakek pulih).
- 1 anak per kolam per siklus. Anak ikan dijual 100% harga jenisnya (berat Sedang).
- Kolam bisa di-instant Bunga (Bab 18.5).
- Kolam juga jadi "akuarium jalan": ikan berenang terlihat oleh tamu.

---

## 8. NAMBANG + CRAFTING + HIAS

### 8.1 Nambang — Ada Skill, Bukan Cuma Tap

- Lokasi: Hutan Nambang (Lv 4). Node: Pohon (Kayu), Rumpun Bambu (Bambu), Batu Kali (Batu), Tebing Tanah (Tanah Liat), Pinggir Kali (Pasir), Pohon Aren (Ijuk, Lv 15).
- **Node per-player:** setiap player melihat node miliknya sendiri (instanced). Tidak ada rebutan. Node habis respawn **4 menit**.
- **Ritme Pukul:** tiap pukulan, lingkaran mengecil di node. Pencet saat lingkaran pas di tanda = **Critical** (+2 bahan, suara crunchy, partikel besar). Pencet asal = normal (+1 bahan). Satu node = 4 pukulan. Anak kecil tetap dapat bahan walau tidak pernah Critical.
- Terik: +10% bahan (Bab 3.3). Skill Tukang menambah.
- Rata-rata 1 putaran Hutan (± 5 menit) = 30-45 bahan campuran.
- Jerami juga dari panen Padi. Bahan mentah TIDAK dijual di toko mana pun.

### 8.2 Bahan

| Mentah (7) | Olahan (craft gratis di Meja Crafting) |
|------------|-----------------------------------------|
| Kayu, Bambu, Batu, Tanah Liat, Pasir, Jerami, Ijuk | Papan (2 Kayu), Bata (2 Tanah Liat), Semen (2 Pasir + 1 Batu), Anyaman (3 Bambu), Atap Ijuk (3 Ijuk), Genteng (3 Tanah Liat), Kaca (3 Pasir, Lv 25) |

Craft olahan: instan, gratis, hanya bahan. Craft massal: tombol `x10`.

### 8.3 Hias — Loop

Kumpul bahan → Buka Menu Hias → Pilih piece → Warna (12) + Material (4) → Ghost (hijau = bisa, merah muda = nabrak) → Pasang (bahan terpotong) → Putar / copy / undo 10 langkah → Pamer.

- Katalog rilis: **80 piece** (Struktur 25, Atap 10, Furniture 25, Dekor 20). Update menambah ±20 piece per update.
- Material: Kayu, Bambu, Batu, Cat. Warna: 12 lingkaran warna, palet warm kampung.
- Cap per lahan: **800 piece** (rumah + luar). Penuh → toast `Lahan sudah penuh hiasan`.
- Hanya di lahan sendiri. Bangun tidak bisa saat mancing aktif. Mode Hias: player bisa tembus dinding sendiri (anti kejebak).
- Validasi lembut: tanpa pintu / tanpa tiang → toast `Belum ada pintu nih` 1x, tetap boleh.
- Hapus = refund 100%, bahan terbang ke tas.

### 8.4 Dekor Berkah (Satu-satunya Dekor dengan Stat) — LOCKED

- Dari 80 piece rilis, **30 adalah Dekor Berkah** (ditandai ikon daun kecil di katalog). 50 lainnya murni visual.
- 1 Dekor Berkah = 1 stat. Duplikat tidak stack (stat dihitung 1x per jenis). Tidak ada popup; panel Stats yang berubah.
- Contoh stat: `+3% Koin Nanem`, `+3% XP Mancing`, `+3% Bahan Nambang`, `+5% Super Panen`, `-3% Cooldown Ternak`.
- Dekor Bunga (Bab 18.3) = Dekor Berkah dengan 2 stat.

### 8.5 Set Dekor

| Set | Isi | Bonus Lengkap |
|-----|-----|---------------|
| Set Kampung | Pagar Bambu, Bale-bale, Sumur Tua, Lampu Minyak, Lampion Bambu | +5% Koin Nanem |
| Set Sungai | Dermaga Kayu, Jembatan Bambu, Lampu Sungai, Perahu Mini, Bendera Kampung | +5% Koin Mancing |
| Set Kandang | Gerobak Jerami, Kincir Kecil, Papan Nama Kandang, Ember Seng, Lumbung Mini | +5% Koin Ternak |
| Set Joglo (Lv 50) | Atap Joglo, Saka Guru, Lantai Tegel, Gebyok, + 1 Dekor Bunga bebas | +5% XP semua |

- Set ditampilkan `Set Kampung 3/5` di panel Stats. Lengkap = 1 baris stat baru + efek kecil sekali (Bab 21).

### 8.6 Pajangan

| Pajangan | Buka | Fungsi |
|----------|------|--------|
| Rak Pajangan Panen | Lv 10 | Pajang 6 hasil Mutasi. Tamu bisa lihat label `Durian Pelangi — dipanen 12 Des`. |
| Akuarium | Lv 25 | Pajang 8 ikan (termasuk Legenda, termasuk ukuran Jumbo). |
| Bingkai Album | Lv 15 | Tampilkan % Album Kampung di dinding. |

Pajangan = alasan visit & like, dan alasan menyimpan barang langka alih-alih menjual.

### 8.7 Blueprint, Visit, Galeri

- **Blueprint:** simpan desain (3 slot gratis), bagikan kode ke teman. Teman tetap harus punya bahan sendiri. Saat dipakai, ghost blueprint muncul transparan dan bisa dipasang per bagian.
- **Visit:** jalan-jalan, duduk, foto. Tidak bisa bangun/hapus/ambil.
- **Like:** `👍 Bagus!` 1x per lahan selamanya per player. Pemberi like +20 Koin (max 10 like berhadiah per hari). Like masuk hitungan mingguan.
- **Galeri Kampung:** papan di Alun-alun berisi 5 lahan dengan like mingguan terbanyak (global, bukan per server). Pencet = visit (teleport ke server pemilik jika online, atau "rumah snapshot" read-only jika offline).
- **Lomba Hias Bulanan:** tema (contoh: `Kampung 17-an`), juara dipilih dari like + kurasi tim. Hadiah Bunga + dekor eksklusif + title.

---

## 9. DAPUR & OLAHAN

- **Inti Dapur** (Tungku + Meja Olah) dicraft di Meja Crafting, ditaruh bebas di lahan. Bangunan dapur di sekitarnya murni Hias.
- Olahan jalan walau offline. Tidak bisa gosong / gagal.

| Tier | Buka | Craft Inti | Slot | Waktu Olah |
|------|------|------------|------|------------|
| 1 Tungku | Lv 6 | 10 Kayu + 8 Batu + 5 Tanah Liat | 1 | 100% |
| 2 Kampung | Lv 15 | 15 Papan + 10 Bata | 2 | 85% |
| 3 Lengkap | Lv 35 | 20 Papan + 15 Bata + 10 Semen | 3 | 70% |

Upgrade: craft Inti baru, ganti yang lama (refund 100%), olahan berjalan tidak hilang.

| Resep | Tier | Bahan | Waktu | Jual | XP |
|-------|------|-------|-------|------|----|
| Pakan Jagung | 1 | 5 Jagung | 3 mnt | (6 jatah pakan ayam) | 20 |
| Tumis Kangkung | 1 | 5 Kangkung + 1 Garam* | 5 mnt | 160 | 40 |
| Sambal Tomat | 1 | 4 Tomat + 2 Cabai | 6 mnt | 320 | 60 |
| Telur Asin | 2 | 4 Telur Bebek + 1 Garam* | 20 mnt | 350 | 90 |
| Selai Stroberi | 2 | 4 Stroberi + 2 Tebu | 30 mnt | 2.200 | 300 |
| Pepes Ikan | 2 | 2 Nila + 1 Jahe + 1 Daun Pisang** | 25 mnt | 450 | 110 |
| Kopi Tubruk | 3 | 4 Kopi + 1 Tebu | 40 mnt | 3.000 | 380 |
| Teh Melati | 3 | 3 Teh + 2 Melati | 45 mnt | 3.000 | 390 |
| Es Krim Durian | 3 | 2 Durian + 3 Susu + 1 Tebu | 60 mnt | 4.200 | 520 |

\* Garam: dibeli di Pak Udin (10 Koin). ** Daun Pisang: bonus 2 per panen Pisang.

- Prinsip harga: olahan ≈ 1,5-1,8x total nilai bahan. Olahan adalah cara terbaik menukar waktu offline jadi Koin.
- Olahan bisa jadi syarat Agenda & Surat Kakek.

---

## 10. NPC & SISTEM JUAL

### 10.1 NPC (LOCKED)

| NPC | Panggilan | Lokasi | Peran |
|-----|-----------|--------|-------|
| Mak Sari | Mak | Tutorial di lahan → Warung Mak Sari (Alun-alun, Shop 7) | Mentor awal. Warung: beli olahan 100%. Sebelum Dapur Tier 1 (Lv 6) warung terlihat, hanya baris: `Nanti kalau udah bisa masak, jual ke Mak ya.` |
| Pak Udin | Pak | Warung utama, Alun-alun | Jual bibit (termasuk bibit unggul), pakan, hewan, garam, alat. Beli hasil mentah 100%. Tanpa kuota harian. Bu Wati dilebur ke sini. |
| Bang Jali | Bang | Depan tiap lahan (8, satu per lahan) | Beli **semua** barang (mentah + olahan + ikan) 90%. Tidak jual apa pun. Menggantikan Bang Tarno. |
| Kak Fajar | Kak | Pinggir Kanal | Guru mancing. Lapak: jual joran & umpan, beli ikan 100%. Mas Joko & Mbok Minah dilebur ke sini. |
| Pak Amran | Pak | Tukang Kayu, Alun-alun | Hadiah rangka rumah pertama, jual alat Tukang, Blueprint. Mbak Arsi dilebur ke sini. |
| Nek Ani | Nek | Pos Ronda, Alun-alun | Memukul kentongan & memimpin Kerja Bakti Kilat setelah badai (Bab 13.4). Menyambut Tamu Event. (Baru, T-05.) |
| Kakek Daeng | Kakek | Hanya lewat Surat Kakek | Kakek player (sudah wafat, diceritakan lembut). |
| Pedagang Tamu | (rotasi) | Pasar Malam | Beli 1 jenis barang +50% tiap malam game (Bab 13.2). |
| Tamu Event | (per event) | Pelataran Beringin | Hanya saat Event Musiman. Memberi Pesanan Tamu pribadi + membuka Toko Tamu (Bab 13.5). |

Nama lama DILARANG: Mbok Minah, Pak Darmo, Mas Joko, Bu Wati, Mbak Arsi, Bang Tarno, Pak Sastro, Mbah Wiryo, Bang Udin, Pak RT, Bu Sari, Mbah Karto, Mas Yudi, Dik Rara.

### 10.2 Tabel Jual (LOCKED)

| Barang | Pak Udin | Kak Fajar | Warung Mak Sari | Bang Jali |
|--------|----------|-----------|------------------|-----------|
| Hasil tanam mentah | 100% | - | - | 90% |
| Produk ternak | 100% | - | - | 90% |
| Ikan | - | 100% | - | 90% |
| Olahan | - | - | 100% | 90% |

- UI jual selalu tampilkan harga diterima sebelum pencet. Di Bang Jali: `Bang Jali bayar 29 Koin (90%) · Di toko 32 Koin`.
- Salah tempat jual → bubble ramah NPC + tombol `Tunjukin jalan` (panah ke tempat yang benar). Tidak ada error merah.
- Pasar Harian & Mutasi dikali di semua penjual.

---

## 11. ALBUM KAMPUNG — Koleksi (BARU)

| Tab | Isi Rilis | Entri |
|-----|-----------|-------|
| Ladang | 24 tanaman (18 + 6 Bibit Varian) × (Normal, Embun, Petir, Emas, Pelangi) | 120 |
| Sungai | 20 ikan × rekor berat terberat + Jumbo pertama | 40 |
| Kandang | 3 hewan + 2 Hewan Varian (Gerobak Kaget) | 5 |
| Rumah | 80 piece pernah dipasang | 80 |
| Dapur | 9 resep pernah dimasak | 9 |
| **Total** | | **254** |

- Tiap entri baru: kartu kecil `ALBUM +1` 1 detik.
- Milestone Album per tab (25/50/75/100%) → Bunga + dekor + title (Bab 15.3).
- **Kartu Album:** tombol `Bagikan` membuat gambar kartu (mode foto) dengan nama player, % Album, dan 3 entri terlangka → bahan share ke teman / medsos.
- Album target selesai: ~3 bulan untuk Raka Kolektor (dengan konten Update 1-2 menambah entri).

---

## 12. SOSIAL

### 12.1 Prinsip Sosial

Sosial harus **memberi**, tidak pernah **mengambil**. Tidak ada PvP, tidak ada mencuri, tidak ada barter item ↔ item.

### 12.2 Bantu Tetangga

| Aturan | Detail |
|--------|--------|
| Cara | Visit lahan → tombol Siram (tanaman belum Basah) / Panen (tanaman siap). |
| Batas | Per lahan per hari: 1 Siram + 1 Panen. Per player per hari: max 5 lahan. Reset 05:00 WIB. |
| Hadiah pembantu | +40 Koin + 10 XP per bantuan. Tidak memakai barang pembantu. |
| Hadiah dibantu | Siram: tanaman jadi Basah (ikut peluang Mutasi Emas). Panen: hasil masuk tas pemilik + 1 bibit sejenis bonus. Mutasi tetap milik pemilik. |
| Kotak Pos | Pemilik lahan dapat ringkasan saat login: `Piko nyiram 1 tanamanmu 🌱`. Tombol `Bales Lambai` (kirim Gestur Lambai ke Piko). |

### 12.3 Kirim Hadiah (Lv 20)

- 3 hadiah per hari WIB ke teman Roblox (friend) atau player di server yang sama.
- Isi: barang dari tas (hasil tanam, ikan non-Legenda, olahan, bahan olahan). Max nilai jual 500 Koin per hadiah. Tidak bisa kirim Koin / Bunga / Legenda / item Bunga.
- Penerima ambil di Kotak Pos + catatan otomatis `Hadiah dari Nisa 🎁`.
- Title `Dermawan` dari 100 hadiah terkirim.

### 12.4 Lapak Tetangga (Lv 20) — Ekonomi Antar-Player yang Aman

| Aturan | Detail |
|--------|--------|
| Slot | 4 slot jual per player (Game Pass Lapak Besar: 8). |
| Barang | Hasil tanam (termasuk Mutasi), ikan non-Legenda, produk ternak, olahan. **Tidak boleh:** bahan mentah, Legenda, item Bunga. |
| Harga | Penjual pilih 80%-130% dari harga dasar (slider, step 5%). Mutasi dihitung dari harga Mutasi. Tidak bisa pasang harga absurd. |
| Pembeli | Bayar Koin. Item masuk tas langsung. Satu klik, tanpa nego, tanpa chat. |
| Pajak | 5% dari harga jual hilang (sink Koin). |
| Jangkauan | Papan Lapak di Alun-alun menampilkan lapak player di server + lapak teman Roblox (lintas server). |
| Kadaluarsa | Barang tidak laku 24 jam kembali ke tas penjual. |
| Kenapa aman | Tidak ada barter, tidak ada nego, harga dikunci → tidak ada scam ala trading Roblox. |

Manfaat: barang Mutasi jadi bernilai sosial ("lapak Raka jual Kopi Petir!"), dan player kolektor bisa melengkapi Album tanpa grind sendiri.

### 12.5 Gestur (Pengganti Emote)

- 4 gestur: Lambai 👋, Jempol 👍, Tepuk Tangan 👏, Ketawa 😄. Animasi 1,5 detik + ikon di atas kepala.
- Tidak ada hug, cium, joget, atau gestur fisik antar-player.
- Gestur Bunga (kosmetik): +4 gestur tambahan di Lemari Gaya (contoh: Panen Bahagia, Pamer Ikan). Tetap aman, tidak ada kontak fisik.

### 12.6 Chat

- Pakai chat bawaan Roblox (filter Roblox). Game tidak membuat chat sendiri.
- Ditambah **Bubble Cepat**: 8 kalimat siap pakai (`Ayo mancing!`, `Hujan bentar lagi!`, `Makasih!`, `Rumahmu bagus!`, dll) untuk akun yang chat-nya dimatikan orang tua.

---

## 13. EVENT BERULANG (Hook Harian)

### 13.1 Gerobak Kaget (Restock 15 Menit)

| Aturan | Detail |
|--------|--------|
| Lokasi | Gerobak di Alun-alun + tombol di Toko Pak Udin. |
| Restock | Tiap **15 menit nyata**, global semua server (jadwal sama, pakai jam server UTC). |
| Isi | 3 slot acak dari pool **Bibit Varian** + **Hewan Varian** + **Bibit Biasa diskon 30%**. |
| Bibit Varian (rilis 6) | Jagung Ungu, Tomat Kuning, Semangka Kotak (tanaman baru, Late 3 jam), Cabai Pelangi, Stroberi Putih, Pisang Merah. Tumbuh seperti biasa, jual +50% dari versi normal, punya entri Album sendiri, ikut Mutasi. |
| Hewan Varian (rilis 2) | Ayam Cemani (hitam), Bebek Belang. Produksi sama, kosmetik + entri Album. |
| Peluang slot | Biasa diskon 60%, Bibit Varian 35%, Hewan Varian 5%. |
| Batas | Per player per restock: max 3 beli per slot. Stok TIDAK habis karena player lain. |
| Notifikasi | Toast kecil 1x saat ada Varian: `Gerobak Kaget: ada Semangka Kotak!` (bisa dimatikan di Settings). |
| Bukan FOMO menghukum | Varian selalu muncul lagi di restock lain. Rata-rata tiap Varian muncul 4-6x per hari. |

### 13.2 Pasar Malam (Tiap Malam Game, 9 Menit)

- Lampion menyala di Alun-alun + musik gamelan pelan.
- **Pedagang Tamu** (rotasi 6 NPC: Pak Kumis Jamu, Bu Rina Kue, dll) membeli 1 jenis barang acak dengan harga +50%, max 10 per player per malam.
- Mini-game opsional: **Lempar Gelang** (3x gratis per malam, hadiah Koin kecil / bahan / tiket dekor). Tidak pakai Robux.

### 13.3 Mingguan & Bulanan

| Event | Jadwal | Isi |
|-------|--------|-----|
| Hari Hujan Petir | Sabtu 19:00-20:00 WIB | Selama 1 jam, peluang hujan Petir naik jadi 40%. Momen ramai mingguan. |
| Lomba Hias | Bulanan | Bab 8.7 |
| Event Musiman | Ikut kalender Indonesia, 10-14 hari | Bab 13.5 |
| Kerja Bakti Kilat | Setiap Hujan Deres / Petir selesai | Bab 13.4 |

### 13.4 Kerja Bakti Kilat — Dipicu Badai (v6.1, LOCKED)

**Konsep:** setelah Hujan Deres atau Hujan Petir reda, alun-alun dan jalan kampung jadi kotor. Nek Ani memukul kentongan: `Tong-tong-tong! Ayo kerja bakti, abis badai nih!` Semua player di server boleh ikut bersih-bersih selama 8 menit.

| Aturan | Detail |
|--------|--------|
| Pemicu | `WeatherService` mengirim event `HujanSelesai(jenis)`. Jika jenis = Deres atau Petir → `KerjaBaktiService:Mulai()`. Gerimis tidak memicu. Frekuensi rata-rata: 1x tiap 25-40 menit. |
| Durasi | 8 menit nyata. Timer di HUD. |
| Area | Alun-alun (melingkar sekitar beringin) + jalan utama kampung. Tidak di Hutan, tidak di perairan. |
| Jumlah kotoran | Dihitung **sekali saat mulai**: `10 + 6 × jumlah player di server`, max 58 (`10 + 6 × 8`, server max 8 player). 1 player = 16 objek, 8 player = 58 objek. Player yang masuk/keluar di tengah tidak mengubah jumlah. |
| Shared | Objek kotoran sama untuk semua player di server (bukan per-player). Objek yang sudah dibersihkan hilang untuk semua. |
| Target | 100% = semua objek bersih. Progress bar bersama `Kampung bersih 62%`. |
| Cozy | Tidak dibersihkan = tidak ada hukuman. Saat timer habis, sisa kotoran memudar sendiri (dianggap dibersihkan warga lain). Kecepatan jalan, toko, NPC tidak terganggu. |

| Jenis Kotoran | Aksi | Waktu | Poin | Bonus Bahan | Muncul di |
|---------------|------|-------|------|-------------|-----------|
| Daun Berserakan | Sapu | 1 dtk | 1 | - | Deres & Petir |
| Sampah Hanyut | Pungut | 1 dtk | 1 | 10%: 1 Bambu / 1 Ijuk | Deres & Petir |
| Pot Terguling | Berdirikan | 1 dtk | 1 | - | Deres & Petir |
| Ranting Patah | Angkat | 1,5 dtk | 2 | 1 Kayu | Deres & Petir |
| Genangan | Kuras (ember otomatis) | 2 dtk | 2 | - | Deres & Petir |
| **Dahan Beringin Patah** | Potong 3 tap | 3 dtk | 5 | 3 Kayu | Petir saja, 1-3 buah |

**Hadiah (per player, disimpan di DataStore player — tidak ada data global):**
- Per poin: **15 Koin + 3 XP**. Poin berhadiah max **20 per Kerja Bakti** (di atas 20 tetap boleh bantu, tidak dapat Koin lagi).
- Kampung 100% sebelum timer habis: semua yang punya ≥1 poin dapat **+150 Koin** + buff **Diskon Warga** (bibit, umpan, pakan di Toko Pak Udin −10% selama 1 hari game = 30 menit). Nek Ani + NPC tepuk tangan, daun beringin berkilau.
- Batas hadiah: **4 Kerja Bakti per hari WIB per player** (counter `KerjaBakti.n` di PlayerData, reset 05:00). Setelah 4, tetap boleh ikut (visual + Pencapaian), Koin/XP tidak ada. Toast 1x: `Makasih udah rajin! Hadiah Kerja Bakti hari ini udah penuh.`
- Pindah server untuk mengejar badai tidak berguna karena batas ada di data player.

**Lahan pribadi:** saat badai reda, tiap lahan player yang online mendapat 3-5 ranting/daun (Bab 3.4 aturan bersih-bersih). Opsional, memberi bahan kecil, hilang sendiri setelah 1 hari game.

**HUD:** tracker kiri tengah berganti sementara: `🧹 Kerja Bakti 62% · 05:12 · Kamu: 8 poin`. Objek kotoran terdekat diberi outline lembut.

**Implementasi:** `KerjaBaktiService` (server) spawn objek dari pool titik spawn tetap (`Workspace.AlunAlun.SpawnKotoran`, 80 titik) secara acak. Klik/aksi divalidasi server (jarak ≤ 8 stud, objek belum dibersihkan, cooldown aksi 0,8 dtk per player). Semua objek Anchored, mesh sederhana.

### 13.5 Event Musiman + Pesanan Tamu (v6.1, LOCKED)

**Prinsip:** event 100% pribadi. Alun-alun dihias otomatis, bukan hasil setoran. Tidak ada target global.

| Aturan | Detail |
|--------|--------|
| Kalender rilis | Agustusan (10-24 Agu), Lebaran (mengikuti tanggal), Tahun Baru (28 Des - 7 Jan), Hari Tani (20-30 Sep), Festival Panen (event original, 1x per tahun). Durasi 10-14 hari. |
| Hiasan alun-alun | Dipasang otomatis dari `Config/Event` di semua server saat event mulai, dicopot saat selesai. Contoh Agustusan: umbul-umbul merah putih di sekeliling toko, bendera di puncak beringin, lampion merah putih di dahan beringin (nyala malam), panggung kecil di pelataran beringin. |
| Tamu Event | 1-2 NPC tamu di pelataran beringin. Contoh: Pak Lurah Seberang (Agustusan), Bu Rina Kue (Lebaran), Mbak Tari Penari (Festival Panen). |
| Pesanan Tamu | Tiap player dapat **8 pesanan pribadi** per event. Pesanan terbuka **2 per hari login selama event** (kumulatif, bukan per tanggal) → player yang login 4 hari dapat semua 8. Player yang baru join di hari ke-10 tetap bisa membuka semua 8 jika login 4 hari sebelum event habis; kalau sisa hari < 4, 4 pesanan terakhir terbuka sekaligus di 3 hari terakhir event. |
| Isi pesanan | Dari pool sesuai Level player: Early (Lv 1-15), Mid (16-35), Late (36+). Contoh Lv 5: `Pak Lurah butuh 10 Kangkung + 5 Telur Ayam buat konsumsi lomba`. Contoh Lv 40: `Bu Rina butuh 2 Selai Stroberi + 1 Kopi Tubruk buat kue Lebaran`. Max 3 jenis barang per pesanan, ±10-20 menit main. |
| Hadiah pesanan | Per pesanan: Koin (sesuai tier) + **Token Event** (5-10 per pesanan). Lengkap 8/8: title event (`Panitia Agustusan 2026`) + dekor utama event (contoh: Gapura Merah Putih) + **15 Bunga**. |
| Toko Tamu | Tukar Token Event dengan dekor tema, outfit tema, gestur tema, warna cat tema. Harga 10-60 Token. Total Token dari 8 pesanan + mini-game ≈ cukup untuk 70% isi Toko Tamu → pemain milih, bukan borong. |
| Mini-game event | Opsional, solo, 3x gratis per hari. Agustusan: Panjat Pinang (time-trial tap ritme), Balap Karung (vs waktu). Lebaran: Susun Ketupat (puzzle). Hadiah 1-3 Token. Tidak ada leaderboard global. |
| Event selesai | Toko Tamu tutup. Token sisa otomatis jadi Koin (1 Token = 50 Koin). Dekor event tetap milik player. Yang menyelesaikan ≥1 pesanan dapat **Plakat Kenang-kenangan** (dekor kecil `Agustusan 2026`) — koleksi plakat tiap tahun. |
| Monetisasi | Tidak ada Robux / Bunga untuk Token atau pesanan. Lemari Gaya boleh menjual outfit tema event (Bunga), terpisah dari Toko Tamu. |

---

## 14. QUEST

| Jenis | Pemberi | Aktif | Gagal? | Reset |
|-------|---------|-------|--------|-------|
| Main Quest | Bergantian NPC | 1 | Tidak | Tidak pernah |
| Surat Kakek | Kotak Pos | 1 surat baru per hari login | Tidak | Kumulatif |
| Side Quest | NPC | Max 3 | Tidak | Tidak pernah |
| Agenda Harian | Papan Agenda | 5 tugas | Tidak (hangus jika tidak selesai) | 05:00 WIB |
| Bundel Kakek | Bangunan rusak di lahan | Dibuka bertahap (5) | Tidak | Tidak pernah (cicil) |
| Kerja Bakti Kilat | Nek Ani | Setelah badai | Tidak | Per kejadian, batas hadiah 4/hari |
| Pesanan Tamu | Tamu Event | Selama event | Tidak | Per event |

### 14.1 Main Quest (Rilis: MQ1-MQ12)

| Quest | Trigger | Membuka | Hadiah |
|-------|---------|---------|--------|
| MQ1 Pulang Kampung | Masuk pertama | Nanem + Jual | 100 Koin + 4 Bibit Kangkung |
| MQ2 Kali Masa Kecil | Selesai MQ1 | Mancing | Joran Bambu + 10 Cacing |
| MQ3 Rumah Pertama | Selesai MQ2 | Hias dasar | Rangka Rumah (4 Pondasi + 4 Tiang) + 20 Kayu |
| MQ4 Kolam Kakek | Lv 3 | Bundel Kakek + Kolam | Kolam Kakek pulih (gratis, Bab 14.5) |
| MQ5 Hutan di Barat | Lv 4 | Nambang + Crafting | Kapak & Palu |
| MQ6 Kokok Pertama | Lv 5 | Ternak Ayam | 1 Ayam + 6 Pakan |
| MQ7 Tungku Mak Sari | Lv 6 | Dapur | Bahan Inti Dapur |
| MQ8 Jebakan Kak Fajar | Lv 6 | Bubu | 1 Bubu Bambu |
| MQ9 Pasar Kampung | Lv 20 | Lapak + Hadiah | 1 slot Lapak ekstra (permanen) |
| MQ10 Kandang Sapi | Lv 22 | Sapi | 1 Sapi |
| MQ11 Atap Leluhur | Lv 50 | Set Joglo | Saka Guru + warna Joglo |
| MQ12 Kampungku | Lv 60 | Perayaan | Title `Warga Kampoeng Tedoeh` + Mahkota Lampion |

### 14.2 Surat Kakek (BARU — Retensi Emosional)

| Aturan | Detail |
|--------|--------|
| Jumlah | 30 surat rilis (+15 tiap Update Besar). |
| Cara dapat | 1 surat baru tiap **hari berbeda** player login (kumulatif, bukan streak). Bolong seminggu tidak apa-apa, surat menunggu. |
| Isi | 3-4 kalimat cerita Kakek Daeng (kenangan, tips kampung, lelucon) + 1 tugas kecil opsional (`Kakek dulu suka mancing Gabus pas hujan. Coba deh.`) |
| Hadiah | Buka surat: 100-300 Koin. Selesaikan tugas surat: bahan / resep / dekor kenangan (Foto Kakek, Kursi Rotan Kakek, Peta Kakek). Surat 7, 14, 21, 30 memberi dekor kenangan spesial. |
| Kenapa | Anak suka cerita yang berlanjut. "Besok surat apa ya?" adalah alasan balik yang tidak memaksa. |
| Tone | Hangat, lucu, tidak sedih berlebihan. Kematian Kakek tidak dibahas detail. |

Contoh Surat #1: `Cucuku, kalau kamu baca ini, berarti kamu sudah pulang. Lahan ini memang berantakan, tapi tanahnya baik. Tanam kangkung dulu, dia anak yang sabar. — Kakek`

### 14.3 Side Quest (Contoh Rilis: 10)

| Side Quest | NPC | Isi | Hadiah |
|------------|-----|-----|--------|
| Kucing Alun-alun | Pak Udin | Kasih makan kucing 3 hari berbeda | Title `Penyayang Kucing` + pet kucing kampung (kosmetik, gratis) |
| Joran Hilang | Kak Fajar | Cari 3 joran hilang di pinggir air | Joran Kayu + 200 Koin |
| Rumah Rapi | Pak Amran | Pasang 20 piece | Warna dinding spesial |
| Koleksi 10 Ikan | Kak Fajar | 10 jenis ikan | Akuarium Kecil |
| Resep Mak | Mak Sari | Masak 3 resep berbeda | Resep Pepes Ikan |
| Embun Pagi | Mak Sari | Panen 5 Mutasi Embun | Gembor Embun (kosmetik) |
| Tetangga Baik | Nek Ani | Bantu 10 lahan | 300 Koin + Bubble Cepat ekstra |
| dst. 3 lagi | | | |

### 14.4 Agenda Harian

- 5 tugas per hari WIB dari Papan Agenda: 1 Nanem, 1 Mancing, 1 Ternak/Dapur, 1 Sosial/Hias, 1 Bebas.
- Tugas disesuaikan Level (tidak minta Durian ke player Lv 5).
- Hadiah per tugas: 150-400 Koin + 50-150 XP. **Selesai 3 dari 5** → Bonus Agenda: 1 bahan langka + 20 Poin Season. **Selesai 5 dari 5** → +10 Poin Season tambahan.
- Bisa ganti 1 tugas per hari gratis (tombol `Ganti`).
- Key: UserId + Tanggal WIB, disimpan di server.

### 14.5 Bundel Kakek — Memulihkan Peninggalan Kakek (v6.1, LOCKED)

**Konsep:** di lahan awal ada 5 bangunan peninggalan Kakek Daeng yang rusak (Bab 3.4). Tiap bangunan punya daftar setoran (bundel). Setoran lengkap → bangunan pulih + fitur permanen + Surat Kakek spesial. 100% pribadi, tidak tergantung player lain.

| Bangunan | Buka | Ukuran | Kondisi Rusak (Visual) | Setoran | Setelah Pulih |
|----------|------|--------|------------------------|---------|---------------|
| **Kolam Kakek** | Lv 3 (MQ4) | 8x8 | Kolam kering, retak, penuh batu runtuhan | Tahap 1: bersihkan reruntuhan (5 tap → dapat 10 Batu). Tahap 2: 3 ikan apa saja + 10 Batu | Kolam tier Tanah gratis, breeding 10% lebih cepat dari kolam biasa |
| **Sumur Tua** | Lv 6 | 4x4 | Bibir sumur ambruk, katrol patah | 15 Batu + 5 Bata + 10 Kangkung + 5 Tomat | Tiap Pagi game, semua petak dalam radius 3 petak dari sumur otomatis tersiram (Basah) |
| **Lumbung Kakek** | Lv 12 | 8x8 | Atap bolong, pintu copot, tiang miring | 30 Papan + 20 Padi + 10 Jagung + 1 hasil Mutasi apa saja | Tas +20 slot (permanen, menumpuk dengan Game Pass Tas Besar) |
| **Saung Kakek** | Lv 20 | 6x6 | Atap ijuk rontok, lantai bambu bolong | 15 Anyaman + 10 Atap Ijuk + 3 olahan berbeda | Duduk di Saung 5 detik → buff `Istirahat Sejenak`: +5% XP semua selama 10 menit (sekali per hari game) |
| **Empang & Dermaga Kakek** | Lv 30 | 10x10 | Empang dangkal penuh lumpur, dermaga papan patah | 30 Papan + 10 Semen + 10 ikan tier Mid + 1 ikan Jumbo apa saja | Spot mancing pribadi di lahan: ikan Kanal + Danau yang sudah terbuka (bukan Legenda, bukan ikan Malam/Pagi khusus). Kak Fajar mampir sesekali duduk di dermaga |

**Aturan (LOCKED):**

| Aturan | Detail |
|--------|--------|
| Cicil | Setoran boleh dicicil per item. Item yang disetor langsung terpakai dan tercatat di `PlayerData.Bundel[id].deposit`. Logout/pindah server aman. |
| Cara setor | Dekati bangunan rusak → ikon `!` + panel kecil daftar setoran (ikon item + `7/20`) → tombol `Setor` (otomatis ambil dari tas sebanyak yang ada). |
| Sebelum Level cukup | Bangunan terlihat rusak + gembok kecil + teks `Lv 12`. Tidak bisa setor. |
| Pindah posisi | Bangunan rusak & yang sudah pulih bisa dipindah di Mode Hias (Prinsip #8). Tidak bisa dihapus. Tidak dihitung ke cap 800 piece. Empang & Dermaga butuh area kosong 10x10. |
| Pulih | Cutscene ≤6 detik (bisa di-skip, Bab 16.2): debu berputar → bangunan berubah jadi bagus → Mak Sari / NPC terkait berkomentar. Lalu Surat Kakek spesial tentang bangunan itu masuk Kotak Pos (di luar 30 surat harian). |
| Hadiah tambahan | Tiap bangunan pulih: **10 Bunga** + 300-1.500 Koin (naik per bangunan) + 1 dekor kenangan (Ember Kakek, Timba Kakek, Karung Padi Kakek, Kendi Kakek, Caping Kakek). |
| Semua 5 pulih | Title `Penerus Kakek Daeng` (Bab 15.4) + dekor **Foto Kakek Daeng berbingkai** + cutscene penutup singkat (Mak Sari: `Kakekmu pasti bangga.`). |
| LiveOps | Update Besar boleh menambah 1 Bundel baru di area ekspansi / area baru (contoh Update 1: Kebun Teh Kakek di Bukit). |

**Implementasi:** `Config/Bundel` berisi `{ id, unlockLv, ukuran, setoran = { {itemId, n} }, hadiah, fiturId }`. `BundelService` (server) memvalidasi setoran dari tas player, menyimpan progres, memicu `FiturService:Aktifkan(fiturId)` saat lengkap. Model bangunan: 2 versi (Rusak, Pulih) di ReplicatedStorage, swap saat pulih.

---

## 15. HADIAH & PROGRESI JANGKA PANJANG

### 15.1 Login Mingguan (Kumulatif, Bukan Streak) — LOCKED

- Siklus 7 hari, reset **Senin 05:00 WIB**. Tiap hari berbeda login dalam minggu itu = +1. Bolong tidak reset.
- Klaim 1x per hari WIB. Tidak diklaim hari itu tetap bisa diklaim sampai reset Senin.

| Hari ke- | Hadiah |
|----------|--------|
| 1 | 100 Koin |
| 2 | 5 Bibit (sesuai Level) |
| 3 | 10 bahan campuran |
| 4 | 300 Koin |
| 5 | 6 Pakan + 10 Cacing |
| 6 | 500 Koin + 1 Bibit Varian acak |
| 7 | **10 Bunga** + 1.000 Koin |

### 15.2 Hadiah Waktu Bermain (Sehat) — LOCKED

- Menit **aktif** per hari WIB (kumulatif antar-login di hari yang sama). Diam 3 menit = timer pause.

| Menit Aktif Hari Ini | Hadiah |
|----------------------|--------|
| 10 | 50 Koin |
| 30 | 150 Koin + 5 Kayu |
| 60 | 300 Koin + 10 Cacing |

- Tidak ada milestone di atas 60 menit. Tidak ada Bunga dari playtime.

### 15.3 Peti Bunga & Pencapaian

**Peti Bunga:** muncul di spot kosong acak di lahan **7 hari setelah klaim terakhir**, max 1, tidak hilang, isi **20 Bunga**. Tidak ada timer di UI.

**Pencapaian Kampung (rilis):**

| Pencapaian | Tier 1 | Tier 2 | Tier 3 |
|------------|--------|--------|--------|
| Panen Raya | 100 panen — 10 Bunga | 1.000 — 30 Bunga | 5.000 — 80 Bunga |
| Pemancing | 50 ikan — 10 | 500 — 30 | 2.000 — 80 |
| Peternak | 100 produk — 10 | 1.000 — 30 | 4.000 — 80 |
| Tukang | 50 piece — 10 | 300 — 30 | 800 — 80 |
| Juru Masak | 20 olahan — 10 | 200 — 30 | 800 — 80 |
| Tetangga | 20 bantuan — 10 | 200 — 30 | 800 — 80 |
| Warga Teladan | 50 poin Kerja Bakti — 10 | 500 — 30 | 2.000 — 80 |
| Penerus Kakek | 1 Bundel pulih — 10 | 3 pulih — 20 | 5 pulih — 50 |
| Pemburu Mutasi | 10 Mutasi — 10 | 100 — 30 | 1 Pelangi tiap tanaman Late — 100 |
| Pemburu Legenda | 1 Legenda — 20 | 3 jenis — 50 | 3 jenis ukuran Jumbo — 100 |
| Album | 25% — 20 | 50% — 50 | 100% — 150 |

Total pencapaian rilis ≈ 1.390 Bunga (terbagi berbulan-bulan, paling banyak di bulan 1-2).

### 15.4 Title (Dari Pencapaian Permanen) — LOCKED

- Disimpan di DataStore player, tidak tergantung server. Hanya 1 title dipakai; hanya title yang dipakai yang memberi bonus.
- Bonus: awal 2%, tengah 3%, akhir 5%. Ikut **cap bonus 25%** (Bab 17.6). Tidak ada title / apa pun yang memberi +% Bunga.
- Title baru → toast `Title Baru: Petani Pemula` + tombol `Pakai` (langsung terpakai) / `Nanti`. Pertama kali saja: coachmark menunjuk Profil > Title.

| Title | Syarat | Bonus |
|-------|--------|-------|
| Pendatang Baru | Tutorial selesai | - |
| Petani Pemula / Petani Ulung / Raja Panen | 100 / 1.000 / 5.000 panen | +2% Koin Nanem / +3% Koin Nanem / +5% XP Nanem |
| Pemancing Pemula / Master Mancing / Legenda Danau | 50 ikan / 500 ikan / 3 jenis Legenda | +2% Koin Mancing / +3% XP Mancing / +5% peluang Langka |
| Peternak Pemula / Juragan Ternak | 100 / 4.000 produk | +2% Koin Ternak / +5% Koin Ternak |
| Koki Kampung / Master Dapur | 20 / 800 olahan | +2% Koin Olahan / +5% Koin Olahan |
| Tukang Muda / Arsitek Kampung | 50 piece / 800 piece + 1 Set lengkap | +2% Bahan / +5% Bahan |
| Pemburu Pelangi | 10 Mutasi Pelangi | +3% peluang Mutasi (relatif) |
| Tetangga Baik / Dermawan | 200 bantuan / 100 hadiah terkirim | +3% Koin semua / +3% XP semua |
| Warga Teladan | 500 poin Kerja Bakti | +3% Bahan |
| Penerus Kakek Daeng | 5 Bundel Kakek pulih | +3% XP semua |
| Panitia [Event] [Tahun] | 8/8 Pesanan Tamu satu event | - (kosmetik, beda tiap event) |
| Penyayang Kucing | Side Quest | - (kosmetik ikon kucing) |
| Juara Lomba Hias | Menang Lomba Hias | - (kosmetik bingkai emas) |
| Warga Kampoeng Tedoeh | MQ12 (Lv 60) | +2% Koin + 2% XP + 2% Bahan, warna emas |

### 15.5 Peta Progresi

- Profil > Peta Progresi: garis Lv 1 → Level Cap saat ini, bendera tiap level yang membuka sesuatu (Bab 4.4). Marker `Kamu di sini — Lv 38`. Bendera berikutnya berkedip pelan + teks `2 level lagi: Ekspansi Lahan`.
- Level di atas Cap tampil dengan gembok + `Segera hadir di Update berikutnya`.
- Sumber data: Config yang sama dengan Bab 4.4 (1 aturan, 1 tempat).

---

## 16. TUTORIAL & FTUE

### 16.1 Prinsip

1. Menit pertama harus ada "wow" kecil: panen pertama **dijamin Super + Embun** (tutorial memicu Gerimis 20 detik).
2. Cerita lewat orang, instruksi lewat coachmark. NPC tidak pakai bahasa gaming.
3. Tutorial wajib hanya **4 menit** (MQ1-MQ3). Sistem lain dikenalkan saat Level membukanya (MQ4+), bukan dipaksa di awal.
4. Bubble max 2 baris, max 2 bubble per beat (3 untuk beat emosional).
5. Tidak ada step yang bisa gagal / expired. Checkpoint tiap step.

### 16.2 Aturan Skip (SATU-SATUNYA DEFINISI) — LOCKED

| Elemen | Aturan |
|--------|--------|
| Cutscene | Hanya 3: Pulang Kampung, Hadiah Pak Amran, Rumah Pertama Jadi. Tiap cutscene ≤ 6 detik total. Tombol `Lewati >` di kanan atas (di bawah tombol Settings, jarak 16px) sejak detik pertama, semua akun. Hadiah tetap diberikan. |
| Bubble NPC | `Lanjut >` mempercepat. Player tetap bisa jalan. |
| Coachmark | Panah + teks kecil, hilang saat target yang benar dipencet. Jalan menjauh tidak menghilangkannya. Tombol lain tetap bisa dipencet. Jika 20 detik tidak dipencet, muncul `Lewati >` kecil (anti soft-lock); step dianggap selesai, hadiah tetap. Coachmark hanya muncul pertama kali sistem dikenalkan. |

### 16.3 FTUE Menit per Menit

| Waktu | Beat | Detail |
|-------|------|--------|
| 0:00 | Cutscene Pulang Kampung | Player turun dari angkot di gapura kampung, kamera menyapu lahan Kakek yang penuh ilalang + bangunan rusak, Mak Sari melambai (≤6 detik) |
| 0:10 | Mak Sari | `Lhooo... [Nama]! Gede banget sekarang kamu!` / `Lahan Kakek nunggu kamu.` |
| 0:20 | Tanam | Coachmark petak → Tanam Kangkung (petak sudah siap, tidak perlu cangkul) |
| 0:30 | Siram | Coachmark gembor → Siram. Gerimis tutorial turun 20 detik (pakai sistem cuaca, override sekali) |
| 0:50 | Panen | Kangkung tumbuh cepat (tutorial 20 detik). Panen: **SUPER PANEN + EMBUN** dijamin. Efek penuh. |
| 1:10 | Album | Kartu `ALBUM +1: Kangkung Embun` 1 detik |
| 1:20 | Jual | Mak Sari: `Bang Jali di depan, tapi ke Pak Udin dapetnya penuh.` Coachmark ke Bang Jali (dekat) — boleh pilih Pak Udin. Dapat Koin pertama. |
| 1:40 | Kali | Mak Sari: `Kak Fajar nyariin kamu di kali.` Panah ke Kanal (jarak dekat, 15 detik jalan) |
| 2:00 | Mancing | Kak Fajar kasih Joran Bambu. Lempar → gigitan (dijamin) → tarik (ikan Early pelan) → Wader Cakul. Kartu `IKAN BARU!` |
| 2:40 | Pak Amran | Kak Fajar: `Pak Amran titip sesuatu buat kamu.` Pak Amran datang ke Kanal (jalan, bukan teleport) |
| 2:50 | Cutscene Hadiah | Pak Amran kasih Rangka + Kayu (≤6 detik) |
| 3:00 | Hias | Coachmark Hias → pasang 1 Dinding + 1 Atap di Rangka yang sudah berdiri di lahan |
| 3:40 | Cutscene Rumah Jadi | Lampu rumah menyala, Mak Sari: `Sekarang ini bener-bener rumahmu.` |
| 3:50 | Bebas | Agenda Harian kebuka + Surat Kakek #1 di Kotak Pos (coachmark 1x) + Gerobak Kaget toast |
| 4:00 | Naik Lv 2 | Konfeti kecil, Peta Progresi bendera Lv 2 |

Target: 90% player baru menyelesaikan FTUE. Total klik inti ≈ 25.

### 16.4 Tutorial Lanjutan (Dipicu Level, Bukan Dipaksa)

| MQ | Pemicu | NPC | Durasi | Inti |
|----|--------|-----|--------|------|
| MQ4 Kolam Kakek | Lv 3 | Mak Sari datang ke lahan | 1,5 mnt | Mak Sari: `Dulu Kakekmu suka mancing terus taruh ikannya di sini.` Coachmark bersihkan reruntuhan (5 tap) → setor 3 ikan + 10 Batu → cutscene pulih → taruh 2 ikan sejenis + pakan → percepat 10 detik sekali, dijelaskan `biasanya 6 jam`. Mak Sari: `Bangunan Kakek yang lain juga bisa kamu benerin pelan-pelan.` |
| MQ5 Hutan di Barat | Lv 4 | Pak Amran | 1,5 mnt | Pukul 1 pohon dengan ritme → craft Papan → pasang Papan |
| MQ6 Kokok Pertama | Lv 5 | Pak Udin | 1 mnt | Ayam gratis → isi pakan → ambil telur (dipercepat sekali) |
| MQ7 Tungku Mak Sari | Lv 6 | Mak Sari | 1,5 mnt | Craft Inti Dapur (bahan diberi jika kurang) → Tumis Kangkung → jual di Warung |
| MQ8 Jebakan Kak Fajar | Lv 6 | Kak Fajar | 1 mnt | Pasang bubu → percepat sekali → panen |

Kalau player mengabaikan MQ, NPC tidak mengejar. Ikon `!` kecil di atas NPC saja.

---

## 17. EKONOMI

### 17.1 Prinsip

1. Semua angka di Config (`Config/Economy`), bukan hardcode.
2. Penghasilan dihitung **bersih** (sudah dikurangi bibit, umpan, pakan).
3. Konten rilis ~71% selesai saat Level Cap 60. Sisa 27% + konten Update 1 menjembatani ke Lv 80.
4. Tidak ada cara Robux → Koin (langsung maupun tidak langsung).

### 17.2 Faucet (Sumber Koin) per Jam, Player Inti

| Fase | Nanem | Mancing | Ternak + Kolam + Bubu | Olahan | Agenda/Sosial/Event | Total Bersih / Jam |
|------|-------|---------|-----------------------|--------|----------------------|--------------------|
| Lv 1-20 | 700 | 600 | 150 | 100 | 450 | **2.000** |
| Lv 21-45 | 1.800 | 1.400 | 900 | 1.100 | 800 | **6.000** |
| Lv 46-60 | 3.300 | 2.600 | 2.000 | 3.000 | 1.100 | **12.000** |

Total Koin bersih sampai Lv 60 ≈ 14 jam × 2.000 + 29 × 6.000 + 20 × 12.000 ≈ **442.000 Koin**.

### 17.3 Pembagian Waktu (Agar Semua Sistem Dipakai)

Target porsi Koin player inti: Nanem 30% | Mancing 25% | Ternak+Kolam+Bubu 15% | Olahan 15% | Agenda/Sosial/Event 15%. Kalau playtest menunjukkan 1 sistem >40%, turunkan sistem itu, jangan naikkan yang lain.

### 17.4 Sink (Biaya Menyelesaikan Konten Rilis)

| Sink | Total Koin | Rincian |
|------|-----------|---------|
| Petak 7-36 | 96.750 | `n × 150` |
| Beli chunk lahan (14 chunk, Bab 3.1) | 88.790 | `1.500 × 1,2^n` untuk n = 0..13, dibulatkan 10 (lihat Bab 3.1) |
| Joran | 66.400 | Bab 6.3 |
| Alat Bertani | 15.800 | Bab 17.5 |
| Alat Tukang | 13.000 | Bab 17.5 |
| Kandang + upgrade | 24.000 | Bab 7.1 |
| Hewan (max slot) | 21.800 | 10 Ayam + 8 Bebek + 4 Sapi |
| Kolam (4, sampai Keramik) | 39.000 | 3 Kolam Tanah baru + 4 upgrade Semen + 4 upgrade Keramik |
| Bubu (3 sampai Besi) | 17.700 | Bab 6.6 |
| Skill (16 × 15.000) | 240.000 | Bab 4.5 |
| **Total** | **~623.000** | |

**442.000 / 623.000 ≈ 71%.** Sink kecil berulang (pajak Lapak 5%, Gerobak Kaget, Garam, pakan ekstra) tidak dihitung, berfungsi sebagai rem inflasi.

### 17.5 Alat Koin (Versi F2P dari Alat Bunga)

| Alat | Harga | Syarat | Efek |
|------|-------|--------|------|
| Gembor Plastik | Gratis | - | Siram 1 petak |
| Gembor Seng | 2.000 Koin + 10 Kayu | Bertani Lv 3 | Siram 2 petak (garis) |
| Gembor Kuningan | 8.000 Koin + 20 Papan | Bertani Lv 8 | Siram 3 petak (garis) |
| Sabit Kayu | Gratis | - | Panen 1 petak |
| Sabit Besi | 5.000 Koin + 10 Batu | Bertani Lv 5 | Panen 3 petak (garis) |
| Sepatu Bot | 800 Koin + 5 Ijuk | Bertani Lv 2 | Jalan +5% di lahan sendiri |
| Kapak Batu | Gratis | - | Normal |
| Kapak Besi | 3.000 Koin + 15 Batu | Tukang Lv 3 | +1 bahan per node |
| Kapak Baja | 10.000 Koin + 20 Batu + 10 Semen | Tukang Lv 7 | +2 bahan per node |

### 17.6 Cap Bonus (LOCKED)

- Bonus dari **Dekor Berkah + Dekor Bunga + Set + Title** dijumlah per jenis stat (contoh: `Koin Nanem`), dan dikunci **max +25%**.
- Skill cabang di luar cap (max +10% per jenis).
- Panel Stats menampilkan `Koin Nanem +25% (MAX)` dengan warna emas jika mentok. Tidak ada popup.
- Contoh max teoretis: Koin Nanem = 25% (dekor/set/title) + 10% (skill Panen Raya) = +35%. Sudah dihitung dalam faucet fase akhir.

### 17.7 Harga Lain

- Pasar Harian: +30%, 2 barang, semua penjual.
- Super: 2x Koin + 50% XP.
- Mutasi: x1,5 / x3 / x5 / x10 (Bab 5.4). Mutasi **menumpuk** dengan Super: Durian Emas + Super = 1.300 × 5 × 2 = 13.000 Koin. Peluangnya sangat kecil (1% × 10%), ini jackpot yang sengaja ada.
- Agenda: 150-400 Koin per tugas.

### 17.8 Validasi Ekonomi (Wajib Saat Playtest)

| Cek | Target | Kalau Meleset |
|-----|--------|---------------|
| Jam ke Lv 60 (player inti) | 55-70 jam | Ubah XP aksi, jangan ubah rumus level |
| % sink selesai di Lv 60 | 65-80% | Ubah harga Skill dulu (sink terbesar) |
| Porsi Koin 1 sistem | ≤ 40% | Turunkan sistem dominan |
| Koin mengendap (median saldo player Lv 60) | ≤ 50.000 | Tambah sink kosmetik Koin di Update |
| Mutasi Emas/Pelangi per player per minggu | 3-8 | Ubah peluang Mutasi |

---

## 18. MONETISASI

### 18.1 Prinsip

1. Bunga membeli **gaya, kenyamanan, waktu** — bukan kekuatan atau konten.
2. Semua harga kelihatan. Tidak ada loot box, gacha, iklan, timer bayar.
3. F2P bisa mencapai 100% konten Koin dan 100% Album.
4. Pembeli harus merasa **pack lebih worth dari yang dulu**, supaya beli Bunga terasa wajar.

### 18.2 Sumber Bunga F2P per Bulan

| Sumber | Bulan 1 | Bulan 2+ |
|--------|---------|----------|
| Peti Bunga (4×20) | 80 | 80 |
| Login Mingguan (4×10) | 40 | 40 |
| Pencapaian + Album | 80 | 30 |
| Season Free | 40 | 40 |
| Bundel Kakek + Pesanan Tamu | 30 | 20 |
| Event / Lomba Hias | 10 | 10 |
| **Total** | **~280** | **~230** |

### 18.3 Barang Bunga (Bunga Shop)

**Alat Bunga (QoL, ada versi Koin-nya di Bab 17.5):**

| Alat | Harga | Syarat | Efek | Versi Koin |
|------|-------|--------|------|------------|
| Gembor Melati | 180 | Bertani Lv 4 | Siram area 3x3 + jejak air berkilau | Gembor Kuningan (garis 3) |
| Sabit Kenanga | 180 | Bertani Lv 5 | Panen area 3x3 | Sabit Besi (garis 3) |
| Sepatu Bunga | 120 | Bertani Lv 2 | Jalan +10% di lahan sendiri + jejak kelopak | Sepatu Bot (+5%) |
| Kapak Anggrek | 200 | Tukang Lv 4 | Zona Critical 15% lebih lebar | Skill Ayunan Mantap |
| Joran Sakura | 250 | Mancing Lv 6 | Kotak 40% + ikan 10% lebih lambat + tali pink | Bambu Wulung (39%) |
| Joran Teratai | 300 | Mancing Lv 8 | +5% peluang Jumbo + tali emas | - |

**Dekor Bunga (12, Dekor Berkah 2 stat, ikut cap 25%):** 80-200 Bunga. Contoh: Lampion Bunga Gantung (80: +3% Koin Nanem + 3% XP Nanem), Air Mancur Bunga (200: +3% Koin Olahan + 3% XP Olahan), Gapura Bunga (150), Pohon Sakura (200).

**Pet Kosmetik (6):** mengikuti player, idle lucu, bisa duduk di bale-bale. **Tanpa stat.** Kucing Oren (250), Ayam Jago (250), Kambing Kecil (300), Burung Kutilang (300), Kelinci (350), Kerbau Mini (500). Pet gratis: Kucing Kampung dari Side Quest.

**Lemari Gaya (rotasi mingguan):** outfit karakter (caping, sarung, kebaya, batik, kaos kampung), skin alat, gestur ekstra, skin atap. 60-250 Bunga per item. 8 item per minggu, item kembali dalam rotasi 6-8 minggu (tidak hilang selamanya).

**Instant (Tanaman, Olahan, Kolam — BUKAN Bubu, BUKAN Ternak):** kurva piecewise linear tanpa min/max.

| Sisa Waktu | 0 | 1 mnt | 1 jam | 4 jam | 8 jam |
|------------|---|-------|-------|-------|-------|
| Bunga | 0 | 1 | 12 | 30 | 50 |

Tombol `Selesaikan — X Bunga`. Konfirmasi hanya jika X > 30.

### 18.4 Paket Robux

| Paket | Robux | Bunga | Bunga / Robux |
|-------|-------|-------|---------------|
| Kantong Bunga | 49 | 55 | 1,12 |
| Karung Bunga | 129 | 160 | 1,24 |
| Gerobak Bunga | 279 | 380 | 1,36 |
| Pesta Bunga | 599 | 900 | 1,50 |
| Panen Raya Bunga | 1.199 | 2.000 | 1,67 |
| **Paket Pemula** (1x seumur akun) | 99 | 150 + Pet Ayam Jago + Pagar Bambu Spesial | Paling worth |

**Game Pass (sekali beli):**

| Pass | Robux | Isi |
|------|-------|-----|
| Tas Besar | 149 | Tas +60 slot |
| Lapak Besar | 199 | Lapak 4 → 8 slot |
| Buku Blueprint | 99 | Blueprint 3 → 8 slot |
| Pemutar Musik Kampung | 79 | Radio di rumah, 8 lagu tradisional instrumental |

**Private Server:** aktif, 100 Robux/bulan (fitur bawaan Roblox) — "Kampung Pribadi" untuk main dengan teman.

**Season Pass:** Bab 19.

### 18.5 Yang TIDAK Dijual (LOCKED)

Loot box / gacha · Koin · XP · Level · Skill Point · Bahan mentah · Hewan · Rumah jadi · Skip bangun · Instant Bubu · Ikan Legenda · Pity · Iklan berhadiah · Timer bayar baru · Slot petak / kolam / kandang.

### 18.6 Proyeksi (Asumsi Kasar)

| Metrik | Target |
|--------|--------|
| Konversi bayar (30 hari) | 3% |
| Pembelian pertama paling umum | Paket Pemula 99 R |
| ARPPU / bulan | ~450 Robux |
| Total Bunga untuk "punya semua" (alat + dekor + pet + 1 rotasi Lemari) | ~6.000 Bunga ≈ 4.000 Robux → plafon belanja naik ~60% dari v5.2 tanpa P2W |
| Premium Payout | Sesi 20-40 menit + Pasar Malam + Kerja Bakti Kilat menaikkan waktu main player Roblox Premium |

---

## 19. SEASON PASS — "Musim Panen"

| Aturan | Detail |
|--------|--------|
| Durasi | 28 hari, global (kalender WIB). Season 1 mulai saat rilis. Tiap season punya tema (Musim Hujan, Musim Mangga, Agustusan). |
| Level | 30 level × 100 Poin = 3.000 Poin |
| Sumber Poin | Quest Season harian (3 tugas = 100 Poin/hari) + Agenda bonus (20 + 10) + Quest Season mingguan (3 tugas = 400 Poin/minggu) |
| Pace | Rajin tiap hari: selesai ~hari 17. Main separuh hari: selesai ~hari 27. Sengaja longgar untuk anak yang sekolah. |
| Skip level | 25 Bunga per level |
| Hadiah otomatis | Naik level = hadiah langsung masuk tas, tanpa klaim satu-satu |

| | Free | Premium (299 Robux) | Premium+ (649 Robux) |
|---|------|---------------------|----------------------|
| Bunga | 40 | +300 (total 340) | +300 (total 340) |
| Koin | 6.000 | +12.000 | +12.000 |
| Bahan, bibit, umpan, pakan | Ya | Lebih banyak | Lebih banyak |
| Kosmetik eksklusif season | 1 dekor | +1 Pet skin + 2 dekor + 1 skin atap + 1 gestur + 1 outfit | Semua Premium + langsung naik 10 level + bingkai profil animasi |

- Kenapa Premium tetap laku walau Bunga-nya < Pesta Bunga: kosmetik eksklusif season **tidak akan dijual lagi** (satu-satunya barang terbatas di game, dan itu kosmetik, jadi aman).
- Premium tidak memberi XP boost, Koin boost per jam, atau pengali Koin apa pun (termasuk hadiah pesanan).

---

## 20. EXPERIENCE — Game Feel, Suara, Haptic

### 20.1 Filosofi Rasa

| Sistem | Suara Khas | Rasa |
|--------|------------|------|
| Nanem | `pluk` yang puas | Adem, nagih |
| Mutasi | `TING` berlapis + kilau | Kaget senang, pengen pamer |
| Mancing | `cemplung!` | Tegang tapi santai |
| Legenda | Fanfare gamelan pendek | Momen besar satu server |
| Ternak | `tuk-tuk` gemoy | Lucu, pengen dielus |
| Hias / Nambang | `klik` / `tok` crunchy | Bangga |

Bukan game yang teriak-teriak. Game yang bisik-bisik, tapi sesekali bikin satu server teriak "WOOO".

### 20.2 Aturan Global

1. Feedback setiap aksi < 0,2 detik.
2. Hierarki rasa: Biasa (kecil, cepat) < Super < Ikan Baru < Mutasi Emas/Petir < Legenda / Mutasi Pelangi (paling besar, dengan pengumuman).
3. Pop-up scale-up 0,15 detik + bounce kecil. Angka melayang naik 40px, fade 0,8 detik. Item terbang ke ikon tas 0,4 detik.
4. **Haptic hanya 5 momen (LOCKED):** Gigitan ikan, Mutasi Emas/Petir/Pelangi, Ikan Baru/Legenda, Kilat Petir, Naik Level. Bisa dimatikan di Settings.
5. Semua SFX variasi pitch ±5%. Panen massal = 1 suara + 1 angka total.
6. Volume default: SFX 70%, Musik 30%, Ambient 50%.
7. Tidak ada suara gagal minor / turun. Ikan lepas: `plup` pelan + toast abu-abu `Ikan lepas... coba lagi ya`.
8. Warna bahasa UI: Sukses = emas/kuning, Info = putih/hijau, Tidak bisa = abu-abu/krem, Gagal = abu-abu lembut. Dilarang merah menyala + `GAGAL!`.
9. Musik: Alun-alun (gamelan pelan), rumah (akustik kampung), Pasar Malam (gamelan ceria). Saat tarik ikan, musik turun 70%, ambient naik.

---

## 21. EFFECTS

### 21.1 Prinsip

- Satu aksi = satu efek utama. Efek langka harus beda jauh. Cahaya warm (255, 200, 120), efek Bunga ungu-pink lembut.
- Max partikel aktif di layar **120**. Max glow aktif **6**. Settings: `Efek: Hidup / Kurang / Mati`.

### 21.2 Tabel Efek

| Aksi | Visual | Durasi | Partikel | Suara |
|------|--------|--------|----------|-------|
| Tanam | Tanah mengembang + daun pop | 0,4 dtk | 4 | `tuk` |
| Siram | Air melengkung + tanah gelap (tanda Basah tetap terlihat) | 0,8 dtk | 8 | `srrr` |
| Siap Panen | Glow kuning lembut + ikon tangan, terlihat 20 stud | Loop | glow | - |
| Panen Biasa | Daun terbang + angka melayang | 0,8 dtk | 5 | `pluk` |
| Super Panen | Bintang emas + `SUPER!` | 1 dtk | 15 | `TING` |
| Mutasi Embun | Butir air berkilau + `EMBUN!` biru muda | 1 dtk | 10 | `ting` air |
| Mutasi Petir | Kilatan biru + `PETIR!` + getar | 1,2 dtk | 15 | `zzt-TING` |
| Mutasi Emas | Ledakan kilau emas + `EMAS!` besar + getar | 1,5 dtk | 20 | `TING` berlapis |
| Mutasi Pelangi | 7 warna spiral + `PELANGI!` + banner server | 2 dtk | 30 | Fanfare kecil |
| Lempar | Garis melengkung + riak | 0,6 dtk | 6 | `wusss... plung!` |
| Gigitan | Pelampung tenggelam + `!` + getar | 0,5 dtk | 10 | `cemplung!` |
| Dapat Ikan | Ikan lompat + kartu ikan 1,5 dtk | 1,5 dtk | 8 | `plup` + `ting` |
| Ikan Baru | Kartu emas + `IKAN BARU!` | 2 dtk | 20 | Fanfare kecil |
| Ikan Legenda | Air bercahaya + ikan lompat slow-mo 0,5 dtk + banner server | 2,5 dtk | 30 | Fanfare gamelan |
| Ambil Produk Ternak | Produk muncul + terbang ke tas | 0,5 dtk | 2 | `tok` / `gluk` |
| Anak Ikan Lahir | Bintang kecil + `+1` | 1 dtk | 6 | `ting` |
| Nambang Critical | Partikel besar + `CRITICAL!` kecil | 0,5 dtk | 8 | crunchy |
| Pasang Piece | Jatuh 1 stud + bounce + debu | 0,4 dtk | 3 | `klik` |
| Hapus Piece | Pecah jadi bahan → terbang ke tas | 0,5 dtk | 6 | `prak` lembut |
| Olahan Selesai | Glow emas di Inti Dapur | Loop | glow | `TING` |
| Peti Bunga Dibuka | Bunga beterbangan + `+20 Bunga` | 1,5 dtk | 20 | `TING` + angin |
| Set Lengkap | Kunang-kunang + baris stat baru (sekali saja) | 2 dtk | 25 | Fanfare kecil |
| Naik Level | Bar flash emas + konfeti kecil | 0,5 dtk | 15 | `TING` naik |
| Gerobak Kaget Restock | Terpal gerobak terbuka + 3 kilau | 1 dtk | 6 | Bel sepeda `kring` |
| Kerja Bakti Mulai | Kotoran muncul (fade-in 1 dtk) + kentongan Nek Ani | 1 dtk | 0 | `tong-tong-tong` |
| Bersihkan Kotoran | Objek mengecil + debu kecil + `+1` | 0,4 dtk | 3 | `srek` / `byur` (genangan) |
| Dahan Beringin Dipotong | Dahan jatuh pelan + daun beterbangan | 0,8 dtk | 8 | `krek` |
| Kampung 100% Bersih | Daun beringin berkilau + NPC tepuk tangan | 2 dtk | 20 | Gamelan pendek |
| Babat Ilalang / Semak | Rumput rebah + partikel daun | 0,3 dtk | 4 | `sret` |
| Setor Bundel | Item terbang ke bangunan rusak + angka `7/20` naik | 0,5 dtk | 3 | `tuk` |
| Bangunan Kakek Pulih | Debu berputar → swap model → kilau emas | ≤6 dtk (cutscene) | 25 | Fanfare gamelan lembut |
| Pesanan Tamu Selesai | Token terbang + `+8 Token` | 1 dtk | 8 | `TING` |

### 21.3 Cahaya & Cuaca Global

| Kondisi | Cahaya | Partikel | Suara |
|---------|--------|----------|-------|
| Pagi | Kabut tipis, putih warm | 0 | Ayam berkokok 1x |
| Siang | Putih warm | 0 | Burung + angin |
| Sore | Oranye lembut, transisi 30 detik | 0 | Jangkrik mulai |
| Malam | Biru gelap + lampu warm otomatis | 15 kunang-kunang | Jangkrik + katak |
| Gerimis | Abu-abu lembut | 30 | `tik-tik` |
| Deres / Petir | Abu gelap (+kilat putih 0,1 dtk tiap 20 dtk) | 80 | `syuuu` (+`DUAR` vol 0,5) |
| Pelangi | Pelangi + cahaya hangat | 0 (+kilau tanaman) | Chime lembut |

Tidak ada strobe. Kilat petir ≤ 0,1 detik, max 1 kali per 20 detik (aman fotosensitif). Settings `Kilat: Lembut` mengganti flash dengan peredupan.

---

## 22. ANIMASI

### 22.1 Prinsip

- Semua Tween, tidak ada teleport objek. Easing: `Quad Out` muncul, `Back Out` pop-up, `Sine InOut` idle. Jangan `Linear` untuk karakter.
- Aksi 0,2-0,4 detik, emosional 0,8-1,5 detik. Tidak ada animasi yang mengunci input > 1 detik (kecuali cutscene yang bisa di-skip).
- Idle itu hidup: tidak ada karakter / hewan / tanaman diam total > 3 detik.
- HP kentang: durasi animasi UI dipotong 50%, tidak dimatikan.

### 22.2 Player

| Aksi | Animasi | Durasi |
|------|---------|--------|
| Idle | Napas + kedip 4 dtk + lihat sekeliling 6 dtk | Loop |
| Tanam | Jongkok + tangan ke tanah | 0,8 dtk |
| Siram | Gembor miring, air keluar 0,2 dtk setelahnya | 0,8 dtk |
| Panen | Tarik tanaman → ke tas | 0,6 dtk |
| Lempar | Ayun belakang 0,3 + depan 0,3 | 0,6 dtk |
| Tarik | Condong sesuai tension | Selama tarik |
| Nambang | Ayun kapak/palu, sinkron ritme | 0,4 dtk |
| Pasang Hias | Tangan ke depan + piece bounce 1x | 0,4 dtk |
| Duduk / Tiduran | Duduk di kursi, tiduran di kasur (`Zzz`, tidak skip waktu) | 0,8 / 1,5 dtk |
| Gestur (4) | Lambai / Jempol / Tepuk / Ketawa + ikon di kepala | 1,5 dtk |

### 22.3 NPC

| NPC | Idle | Spesial |
|-----|------|---------|
| Mak Sari | Tangan di pinggang, senyum | Jalan ke lahan player saat MQ4/MQ7 (50% kecepatan player) |
| Pak Udin | Pegang dagu, angguk | Kasih Koin saat jual pertama |
| Bang Jali | Duduk, kaki goyang, baca buku | Timbang barang saat beli |
| Kak Fajar | Duduk di pinggir Kanal, kaki di air | Tunjuk air saat Firasat |
| Pak Amran | Pegang palu | Jalan ke Kanal saat FTUE |
| Nek Ani | Duduk di Pos Ronda, pegang tongkat | Pukul kentongan saat Kerja Bakti mulai; tepuk tangan + angkat tongkat saat 100% |
| Tamu Event | Berdiri di pelataran beringin + gerak sesuai tema (kipas, bawa nampan kue) | Lambaian saat pesanan selesai |
| Pedagang Tamu | Menata dagangan | Datang jalan kaki saat Malam, pergi saat Pagi |

NPC tidak pernah teleport di depan player.

### 22.4 Tanaman, Hewan, Objek

| Objek | Idle | Berubah |
|-------|------|---------|
| Tanaman | Sway 5° tiap 3-4 dtk, delay acak per petak | Tumbuh: scale 0,8→1,0 + daun pop. Mutasi: material/warna berubah saat siap panen (Embun berkilau, Emas mengkilap, dll) agar player LIHAT sebelum panen |
| Ayam | Matuk + 2 langkah | Lari ke tempat pakan |
| Bebek | Berenang di genangan kandang | Celup kepala |
| Sapi | Ngunyah + ekor | Jalan pelan |
| Ikan Kolam | Berenang loop | Anak muncul kecil |
| Pet | Ikut player 3 stud di belakang, duduk saat player diam | Melompat kecil saat player panen Mutasi |
| Pintu / Lampu | Buka otomatis saat dekat / nyala otomatis malam | Fade 0,2-0,5 dtk |

### 22.5 UI

| Elemen | Masuk | Keluar |
|--------|-------|--------|
| Pop-up | Scale 0,8→1,0 + fade, Back Out 0,15 dtk | Quad Out 0,1 dtk |
| Toast | Slide 20px + fade 0,2 dtk, tampil 2 dtk | Slide + fade 0,2 dtk |
| Banner Server (Mutasi/Legenda) | Slide dari atas + kilau, tampil 3 dtk | Fade |
| Tombol ditekan | Scale 0,9 + gelap 0,1 dtk | Kembali |
| Bar progress | Smooth, real-time | - |
| Kartu Ikan / Album | Slide dari bawah, hilang sendiri 1,5 dtk | Fade |

Pencet 2x cepat = animasi kedua langsung jalan (tidak antre).

---

## 23. GUI

### 23.1 Zona Roblox (Jangan Dilawan)

| Zona | Pemilik | Aturan |
|------|---------|--------|
| Kiri atas (±320×60 px) | Roblox (logo, menu, chat, mic) | Kosong dari GUI game |
| Kanan atas (±60×60 px) | **GUI game: tombol Settings oranye kayu** | Pertahankan |
| Kiri bawah | Joystick Roblox (dinamis) | Kosong dari GUI game |
| Kanan bawah pojok | Tombol Lompat Roblox | Kosong dari GUI game |

### 23.2 HUD Final (LOCKED)

```
+------------------------------------------------------+
| [Roblox ☰ 💬 🎤]                     [⚙ Settings game] |
|            [ 🪙 1.250 ]   [ 🌸 35 ]                  |  Baris 1: Pil Koin + Bunga
|   [👤 Lv 12 ▓▓▓░░ | ☀️ Siang | 🌧 Hujan 07:32]        |  Baris 2: Profil mini + fase + cuaca
|                                                      |
| [📋 Agenda 3/5  ▸]                                   |  Kiri tengah: tracker Agenda
| [Toast]                                              |
|                                                      |
|                    (lahan kelihatan)                 |
|                                                      |
|  (Joystick)                                          |
|     [Tas][Hias][Agenda][Sosial][Peta]  [AKSI] [Lompat]|
+------------------------------------------------------+
```

| Area | Isi | Ukuran |
|------|-----|--------|
| Atas tengah Baris 1 | Pil Koin + Pil Bunga (tap Bunga = Bunga Shop) | Pil 110×36, 16px di bawah bar Roblox |
| Atas tengah Baris 2 | Avatar 32×32 + Lv + XP bar 100px + ikon fase + ikon cuaca + timer | Tinggi 36, max lebar 340 (HP 360px: sembunyikan timer, tampilkan ikon saja) |
| Kiri tengah | Tracker Agenda (1 baris, tugas terdekat) + Toast di bawahnya | 220×48, Y=120px |
| Bawah tengah | Tas, Hias, Agenda, Sosial (badge Kotak Pos), Peta | 5 × 56×56, jarak 8, 16px dari bawah |
| Kanan bawah | Tombol Aksi kontekstual 72×72, 16px di kiri tombol Lompat | Tanam / Panen / Siram / Lempar / Tarik / Ambil / Pukul / Buka |

- HUD game + Roblox ≤ 25% layar. Lahan harus kelihatan.
- Saat Kerja Bakti Kilat aktif, tracker kiri tengah sementara berganti jadi `🧹 Kerja Bakti 62% · 05:12 · Kamu: 8 poin`, lalu kembali ke Agenda saat selesai.
- Semua tombol 16px dari tepi layar & tombol Roblox.
- Warna: panel coklat kayu (80, 50, 30) transparansi 0,95, teks krem/putih, tombol utama hijau daun (70, 160, 80), tombol Bunga ungu-pink (180, 100, 200), hapus merah lembut (200, 100, 100), nonaktif abu (120, 120, 120).
- Pop-up wajib-pencet hanya: konfirmasi beli > 10.000 Koin / > 30 Bunga, dan pembelian Robux (dialog Roblox).

### 23.3 Menu Utama

| Menu | Isi |
|------|-----|
| Tas | Tab: Ladang, Ikan, Ternak, Olahan, Bahan. Grid 4 kolom ikon 64×64 + jumlah. Detail: harga di penjual terbaik + tombol `Jual ke Bang Jali` (kalau di lahan). Badge Mutasi di ikon. |
| Hias | Mode Bangun / Hias / Hapus. Kategori Struktur, Atap, Furniture, Dekor, Pajangan. Lingkaran 12 warna + 4 material. Filter `Dekor Berkah`. Baris Stats bawah: `Koin Nanem +12% · Set Kampung 3/5`. Tombol Undo + Simpan + Blueprint. |
| Agenda | Tab: Agenda Harian, Main, Side, Bundel Kakek (5 bangunan + progres setoran + `Lacak`), Event (Pesanan Tamu, hanya saat event), Season. Progress `7/10` + tombol `Lacak` (panah) / `Klaim`. |
| Sosial | Kotak Pos (Surat Kakek, Hadiah masuk, ringkasan Bantuan), Teman online + `Visit`, Kirim Hadiah, Galeri Kampung, Gestur, Bubble Cepat. |
| Peta | Peta server (lahan player + ikon NPC + ikon cuaca), teleport jalan cepat ke Alun-alun / Kanal / Danau / Sungai / Hutan (gratis, animasi lari 1 detik). |
| Profil (tap avatar) | Title, Peta Progresi, Album Kampung, Stats bonus, Pencapaian, Pet. |
| Bunga Shop (tap pil Bunga) | Tab: Alat Bunga, Dekor Bunga, Pet, Lemari Gaya, Paket. |
| Settings (⚙) | Musik / SFX / Ambient, Efek (Hidup/Kurang/Mati), Getar, Kilat Lembut, Mode Bantu Mancing, Notif Gerobak Kaget, Bahasa (Indonesia; English di Update 2). |

### 23.4 Toko & Penjual

- **Toko Pak Udin:** Tab Beli / Jual. Baris: ikon 48 + nama + harga + `Beli` (abu jika kurang). Tab Gerobak Kaget di dalam toko dengan timer restock `Restock 08:12`.
- **Warung Mak Sari:** hanya Jual Olahan.
- **Bang Jali:** hanya Jual, semua barang, tampil `90%` + perbandingan harga toko.
- **Lapak Kak Fajar:** Beli umpan, Jual ikan.
- **Papan Lapak Tetangga:** daftar lapak (foto avatar + 4 barang + harga). Tab `Server` / `Teman`.
- Salah jual = bubble NPC + `Tunjukin jalan`.

### 23.5 Dialog & Coachmark

- Bubble di atas kepala NPC, max 2 baris, font 14, `Lanjut >`. Player tetap bisa jalan.
- Coachmark: panah + teks 12 di kotak hitam 0,5. Aturan skip: Bab 16.2.

---

## 24. PERFORMA — HP 4GB

| Aturan | Nilai |
|--------|-------|
| StreamingEnabled | ON. StreamingTargetRadius 256 stud, MinRadius 96. |
| Lahan jauh | Model LOD: lahan player lain di luar 160 stud dirender versi low-detail (atap + bentuk dasar). |
| Cap piece per lahan | 800, semua Anchored, tanpa Union, sharing texture atlas. |
| Save Hias | Array padat (12 byte/piece: id 2, pos 6, rot 1, warna 1, material 1, flag 1), dikompres Base64. |
| Partikel layar | Max 120 |
| Glow | Max 6 |
| Hewan | Max 22 hewan per lahan (sesuai max slot), animasi idle di-pause di luar 80 stud |
| Ikan kolam | Render max 6 ikan per kolam, sisanya data saja |
| Kotoran Kerja Bakti | Max 58 objek, Anchored, mesh ≤ 200 tris, tanpa partikel loop |
| Objek awal lahan | Ilalang/semak memakai 3 mesh instanced; lahan player lain di luar 160 stud tidak merender ilalang |
| Hiasan Event alun-alun | Max 150 piece tambahan, di-stream bersama alun-alun |
| FPS target | ≥ 30 normal, ≥ 25 saat Hujan Deres + 8 player |
| Memori target | ≤ 1,2 GB client di HP 4GB |
| Network | Event cuaca & Gerobak broadcast 1x saat berubah + timer dihitung client dari timestamp server (bukan broadcast tiap detik) |

---

## 25. KPI & ANALYTICS

### 25.1 Target

| KPI | Target Soft Launch | Target Sehat |
|-----|--------------------|--------------|
| FTUE selesai | 85% | 90% |
| D1 | 30% | 35% |
| D7 | 12% | 15% |
| D30 | 4% | 6% |
| Rata-rata sesi | 22 menit | 28 menit |
| Sesi per DAU | 1,8 | 2,2 |
| DAU / MAU | 15% | 20% |
| Konversi bayar | 2% | 3% |
| Like rata-rata thumbnail (Roblox) | 85% | 90% |

### 25.2 Event Analytics (Wajib Log)

`ftue_step(step)`, `level_up(lv)`, `harvest(crop, mutation, super)`, `catch(fish, size, legendary, pity)`, `weather_join(type)` (player online saat hujan dimulai), `gerobak_view/buy(item)`, `letter_open(n)`, `agenda_complete(n)`, `help_given/received`, `gift_sent`, `lapak_list/sell(price_pct)`, `visit(target)`, `like`, `kerja_bakti(points, pct, playersInServer)`, `bundle_deposit(bundle, item, n)`, `bundle_complete(bundle, daysSinceUnlock)`, `land_cleared(pct)`, `event_order_complete(event, n)`, `event_token_spend(item)`, `bunga_earn(source)`, `bunga_spend(item)`, `robux_purchase(product)`, `session_start/end(minutes)`.

Gunakan Roblox AnalyticsService (Funnel + Economy + Custom Events).

### 25.3 Pertanyaan yang Harus Dijawab Data

1. Di step FTUE mana player paling banyak keluar?
2. Apakah player online saat hujan lebih lama sesinya?
3. Berapa % player D1 yang membuka Surat Kakek #2?
4. Sistem mana yang paling banyak menghasilkan Koin (cek ≤40%)?
5. Item Bunga mana yang paling sering dibeli pertama?
6. Berapa hari rata-rata dari Lv 12 sampai Lumbung Kakek pulih? (target 5-10 hari)
7. Berapa % Kerja Bakti Kilat yang mencapai 100% saat server berisi 1-3 player? (target ≥ 70%)

---

## 26. LIVEOPS

| Waktu | Konten |
|-------|--------|
| Tiap 15 menit | Gerobak Kaget restock |
| Tiap 30 menit | Hari game (Pasar Malam tiap malam) |
| Tiap badai (±25-40 menit) | Kerja Bakti Kilat |
| Harian | Agenda, Surat Kakek, Pasar Harian |
| Mingguan | Hari Hujan Petir (Sabtu, otomatis = lebih banyak Kerja Bakti besar), Lemari Gaya rotasi, Galeri Kampung |
| Tiap 2 minggu | Update kecil: 1-2 Bibit Varian, 5 piece hias, perbaikan balance |
| Tiap 28 hari | Season baru (tema baru) + Lomba Hias |
| Bulan ke-2 | **Update 1 "Bukit Teh":** Level Cap 80, Domba + Wol + Benang, 6 tanaman, 6 ikan (+Legenda Arwana Kali), area Bukit, 20 piece, Surat Kakek 31-45, resep Tier 3 baru, Bundel baru: Kebun Teh Kakek |
| Bulan ke-4 | **Update 2 "Pesisir":** Level Cap 100, perahu & mancing laut dangkal, 6 ikan laut (+Legenda), Kambing, 20 piece, Surat 46-60, Bundel baru: Perahu Kakek, bahasa Inggris |
| Event Kalender (Bab 13.5) | Agustusan, Lebaran, Tahun Baru, Hari Tani, Festival Panen — tiap event: hiasan alun-alun dari Config + 1-2 Tamu + 8 Pesanan + Toko Tamu + 1-2 mini-game |

Aturan LiveOps: update besar selalu menambah **Level Cap + Surat Kakek + Album entri + 1 Legenda + 1 Bundel Kakek**. Lima hal itu adalah alasan player lama balik. Semua konten LiveOps wajib lolos Prinsip #16 (tetap jalan dengan 1 player).

---

## 27. ROADMAP PEMBUATAN (Untuk Claude Code)

Kerjakan URUT. Jangan lanjut fase berikutnya sebelum Definition of Done lolos.

| Fase | Isi | Estimasi | Definition of Done |
|------|-----|----------|---------------------|
| 0 Fondasi | Struktur project, Config, PlayerData + DataStore (session lock, retry, autosave 60 dtk + saat keluar), Global DataStore, lahan 128×128 (kotak 192×192, chunk 32×32) + grid + objek awal lahan (Bab 3.4, bitmask), karakter + kamera, ServerClock (hari game 30 menit + reset 05:00 WIB), HUD kosong sesuai Bab 23.2 | 1,5 minggu | Masuk-keluar tanpa kehilangan data, hari game jalan, HUD tidak nabrak Roblox |
| 1 Nanem + FTUE bagian 1 | Petak, 6 tanaman pertama, siram, Super, Pak Udin, Bang Jali, Mak Sari, FTUE 0:00-1:40 | 1,5 minggu | Timer offline benar, FTUE nanem < 2 menit |
| 2 Cuaca + Mutasi | WeatherService (Bab 3.3), Mutasi (Bab 5.4), banner server, Album tab Ladang | 1 minggu | Siklus cuaca sesuai, mutasi muncul sesuai syarat, banner tampil di semua client |
| 3 Mancing | Kanal + Danau, 8 ikan pertama, mini-game, Kak Fajar + lapaknya, FTUE mancing, Legenda Belut Emas + pity | 1,5 minggu | 20 tangkapan tanpa bug, pity tercatat per player |
| 4 Hias + Nambang | Hutan + ritme pukul, crafting, Menu Hias 40 piece, refund, cap, save array, FTUE rumah, Visit + Like | 2 minggu | Bangun rumah kecil, save-load 800 piece < 1 dtk |
| 5 Ternak + Kolam + Bubu + Dapur | Ayam, Bebek, Tempat Pakan, Kolam, Bubu, Dapur Tier 1-2, MQ4-MQ8, `BundelService` + Kolam Kakek & Sumur Tua | 2 minggu | Semua loop pasif berjalan offline, setoran Bundel tersimpan walau dicicil lintas sesi |
| 6 Quest & Retensi | Main Quest, Surat Kakek 30, Agenda, Side 10, Login Mingguan, Playtime, Peti Bunga, Pencapaian, Title, Peta Progresi | 1,5 minggu | Reset 05:00 WIB benar di semua sistem |
| 7 Sosial & Event | Bantu Tetangga, Kotak Pos, Kirim Hadiah, Lapak Tetangga, Gestur, Bubble Cepat, Gerobak Kaget, Pasar Malam, Kerja Bakti Kilat, Event Musiman + Pesanan Tamu (1 event contoh: Agustusan) | 2 minggu | Kerja Bakti 100% bisa dicapai 1 player sendirian, batas 4 hadiah/hari tercatat di data player, Lapak tidak bisa duplikasi item, event bisa dinyalakan/dimatikan hanya lewat Config |
| 8 Konten Lengkap Rilis | 18 tanaman, 20 ikan, Sapi, 80 piece, 9 resep, 4 Set, Pajangan, Album lengkap, Bundel Lumbung + Saung + Empang & Dermaga | 2 minggu | Semua unlock sesuai Bab 4.4, 5 Bundel bisa dipulihkan |
| 9 Monetisasi | Bunga Shop, Alat/Dekor Bunga, Pet, Lemari Gaya, Instant, Developer Product + ProcessReceipt idempotent, Game Pass, Season Pass | 1 minggu | Pembelian tidak dobel / hilang saat server crash |
| 10 Polish, Performa, Playtest | Bab 20-24, analytics Bab 25, playtest Bab 30, soft launch | 2 minggu | Semua FAIL wajib = 0 |
| **Total MVP** | | **~18 minggu** | |

---

## 28. STRUKTUR DATA

```lua
PlayerData = {
  Version = 62,
  Profil = { Nama, TitleAktif, TitlesDidapat = {}, PetAktif, Outfit = {} },
  Level = { Player = 1, XP = 0, SP = 0,
            Cabang = { Bertani = {Lv, XP}, Mancing = {Lv, XP}, Beternak = {Lv, XP}, Tukang = {Lv, XP} },
            Skill = { [skillId] = lv } },
  Mata = { Koin = 0, Bunga = 0 },
  Bahan = { Mentah = { Kayu, Bambu, Batu, TanahLiat, Pasir, Jerami, Ijuk },
            Olahan = { Papan, Bata, Semen, Anyaman, AtapIjuk, Genteng, Kaca } },
  Tas = { Ladang = {}, Ikan = {}, Ternak = {}, Olahan = {} }, -- item: {id, mutasi?, berat?, n}
  Lahan = { Ukuran = 128,
            Petak = { {pos, cropId, plantedAt, basah, mutasiRoll?} },
            Kandang = { {tipe, lv, hewan = {}, jatahPakan, produkTertumpuk} },
            Kolam = { {tier, ikan = {}, siklusMulai} },
            Bubu = { {tipe, spot, pasangAt} },
            Dapur = { tier, slot = { {resep, mulai} } },
            Hias = "<array padat base64>",
            Pajangan = { Rak = {}, Akuarium = {} },
            PetiBunga = { lastClaim, posisi? },
            LahanAwal = "<2 x 32 bit: objek awal yang belum dibersihkan>",
            Chunk = { [chunkId] = "<2 x 32 bit: objek chunk yang belum dibersihkan>" } },
  Bundel = { [bundelId] = { deposit = { [itemId] = n }, pulih = false, pos = {x, z, rot} } },
  KerjaBakti = { tanggalWIB, n = 0, poinTotal = 0 },  -- n = jumlah Kerja Bakti berhadiah hari ini (max 4)
  Event = { eventId, hariLogin = 0, pesananTerbuka = 0, pesananSelesai = {}, token = 0, plakat = {} },
  Album = { [entryId] = firstTimestamp },
  Pity = { GurameRaja = 0, BelutEmas = 0, IkanDewa = 0 },
  Quest = { Main = {id, step}, Side = { {id, progress} }, Surat = { terbuka = n, tugasSelesai = {} },
            Agenda = { tanggalWIB, tugas = {}, klaim = {} } },
  Hadiah = { LoginMinggu = { mingguKe, hariTerhitung, tanggalTerakhir, klaim = {} },
             Playtime = { tanggalWIB, menitAktif, klaim = {} } },
  Sosial = { BantuHariIni = { tanggalWIB, lahan = {} }, HadiahTerkirim = { tanggalWIB, n },
             LikeDiberikan = { [userId] = true }, Lapak = { {item, hargaPct, listedAt} } },
  Pencapaian = { [id] = progress },
  Season = { id, poin, level, premium = 0, klaim = {} },
  Pembelian = { [receiptId] = true }, -- idempotensi
  Stats = { totalPanen, totalIkan, ... }
}
```

```
Config/Tanaman, Config/Ikan, Config/Hewan, Config/Resep, Config/Hias, Config/Set,
Config/Unlock (Bab 4.4), Config/Economy (XP, harga, cap bonus), Config/Weather,
Config/Mutasi, Config/Legenda, Config/Gerobak, Config/Quest (Trigger, Dialog, Completion, Reward),
Config/Surat, Config/Title, Config/Pencapaian, Config/Season, Config/BungaShop, Config/Instant,
Config/LahanAwal (template objek awal), Config/Bundel, Config/KerjaBakti (jenis kotoran, rumus jumlah, hadiah, batas),
Config/Event (jadwal, hiasan alun-alun, Tamu, pool pesanan per tier, Toko Tamu, mini-game)
```

Global DataStore:
- `Lapak_<UserId>` → listing aktif (untuk lintas server teman)
- `Galeri_<WeekId>` → top 5 like + snapshot rumah

> Tidak ada counter progres global lintas server (Prinsip #16). Kerja Bakti Kilat hidup di memori server saja; hadiah & batasnya di PlayerData.

---

## 29. LARANGAN KERAS — Build Gagal Jika Dilanggar

| Dilarang | Kenapa |
|----------|--------|
| UnionOperation untuk bangunan | Lag |
| Physics nyala di bangunan | Semua Anchored |
| Save Hias JSON panjang | Array padat |
| Bahan mentah dijual di toko | Hanya dari Nambang / panen |
| Beli piece jadi / rumah jadi / skip bangun (Koin, Bunga, Robux) | Hias per-satuan |
| Pupuk, hama, tanaman mati, hewan sakit | Cozy |
| Quest gagal karena waktu | Cozy |
| Streak login yang reset | Sehat |
| Target / progres yang butuh jumlah player global atau lintas server | Prinsip #16 — game harus jalan walau sepi |
| Kerja Bakti Kilat menyimpan progres ke DataStore global | Cukup memori server + PlayerData |
| Bangunan Kakek bisa dihapus / dibeli jadi pakai Koin, Bunga, Robux | Harus dipulihkan lewat setoran |
| Ilalang / objek awal lahan mengunci penempatan | Menaruh barang di atasnya = auto-bersih |
| Hukuman karena tidak ikut Kerja Bakti (kotoran permanen, NPC marah, diskon hilang) | Cozy |
| Token Event dijual pakai Robux / Bunga | Event 100% usaha |
| Hadiah playtime > 60 menit / Bunga dari playtime | Sehat |
| Loot box / gacha / iklan berhadiah / timer bayar | Etika anak |
| Robux → Koin, XP, Level, SP, bahan, hewan, slot | Anti P2W |
| Bunga ↔ Koin | Dua ekonomi terpisah |
| Efek +% Bunga dari apa pun | Bunga sumber tetap |
| Bonus dekor/set/title > 25% per jenis | Cap ekonomi |
| Kelangkaan per server (barang langka "habis" karena player lain) | Langka = per-player |
| Ikan Legenda bisa dibiakkan / dijual di Lapak / dihadiahkan | Menjaga nilai |
| Barter item ↔ item / nego harga di Lapak | Anti-scam |
| Lapak harga di luar 80-130% | Anti-scam & anti-inflasi |
| Gestur kontak fisik (hug, cium, joget berdua) | Aman untuk anak |
| Chat custom tanpa filter Roblox | Kebijakan Roblox |
| Instant untuk Bubu / Ternak | Alasan login besok |
| Nama NPC lama (Mbok Minah, Pak Darmo, Mas Joko, Bu Wati, Mbak Arsi, Bang Tarno, Pak Sastro, Mbah Wiryo, Bang Udin, Pak RT, Bu Sari, Mbah Karto, Mas Yudi, Dik Rara) | Sudah diganti (lihat Bab 10.1) |
| Angka yang tidak berasal dari Config | 1 aturan, 1 tempat |
| Kilat strobe / flash > 0,1 detik | Fotosensitif |
| ProcessReceipt tanpa idempotensi | Pembelian dobel / hilang |

---

## 30. PLAYTEST CHECKLIST

Playtest di HP beneran. Minimal: 1 anak 9-10 tahun (30 menit), 1 anak 12-14 (2 jam), 1 player Roblox umum (1 jam), 1 sesi di HP 4GB dengan 8 player.

### 30.1 FTUE & Tutorial (WAJIB)

| No | Test | Diharapkan |
|----|------|------------|
| F1 | Akun baru dari awal | FTUE selesai ≤ 5 menit, tanpa stuck |
| F2 | Skip semua cutscene | Hadiah tetap, alur lanjut |
| F3 | Diamkan coachmark 20 detik | `Lewati >` muncul, step selesai jika dipencet |
| F4 | Panen pertama | Super + Embun dijamin, efek tampil |
| F5 | HP 360px | `Lewati`, coachmark, tombol tidak ketutup HUD Roblox |
| F6 | MQ4-MQ8 diabaikan | Tidak ada NPC yang memaksa, hanya `!` |

### 30.2 Core Loop (WAJIB)

| No | Test | Diharapkan |
|----|------|------------|
| C1 | Tanam Late, logout 8 jam, login | Siap panen, waktu benar |
| C2 | Siram lalu panen 50x | Basah tercatat, peluang Emas ~1% dalam data |
| C3 | Tanaman selesai tumbuh saat Petir | Peluang Mutasi Petir, visual berubah sebelum panen |
| C4 | Panen saat Pelangi | Mutasi Pelangi mungkin, banner server tampil |
| C5 | Mancing 30x di Kanal | Siklus 10-25 dtk, ikan lepas tanpa popup merah |
| C6 | Pity Legenda (cheat counter 199) | Lemparan berikutnya Legenda, counter reset |
| C7 | 2 player mancing Legenda sama di server sama | Keduanya bisa dapat, tidak saling mengurangi |
| C8 | Tempat Pakan habis | Produksi berhenti, hewan tetap sehat & idle |
| C9 | Kolam 2 ikan + pakan, tunggu | 1 anak sesuai tier |
| C10 | Bubu, coba instant | Tidak ada tombol instant |
| C11 | Nambang tanpa Critical sama sekali | Tetap dapat bahan normal |
| C12 | Pasang 2 Dekor Berkah sama | Stat 1x saja |
| C13 | Bonus mentok | Stat tampil `+25% (MAX)` |
| C14 | Masak Tumis Kangkung | 5 menit (tier 1), jual di Warung 100%, di Bang Jali 90% |
| C15 | Jual olahan ke Pak Udin | Bubble ramah + `Tunjukin jalan` |

### 30.3 Cuaca & Waktu (WAJIB)

| No | Test | Diharapkan |
|----|------|------------|
| W1 | Main 60 menit | 2 hari game penuh, malam terlihat |
| W2 | Catat cuaca 60 menit | Terik 8-15 → Hujan 3 → ..., tidak hujan berturut |
| W3 | Pelangi | Hanya setelah Deres/Petir, 60 detik |
| W4 | Reset 05:00 WIB | Agenda, Kerja Bakti, Bantu, Playtime reset bersamaan |

### 30.4 Sosial & Ekonomi Antar-Player (WAJIB)

| No | Test | Diharapkan |
|----|------|------------|
| S1 | Bantu siram + panen lahan teman | Batas 1+1 per lahan, 5 lahan per hari, barang pembantu tidak berkurang |
| S2 | Kirim hadiah ke-4 hari itu | Ditolak |
| S3 | Kirim Legenda / item Bunga | Tidak bisa dipilih |
| S4 | Lapak harga 150% | Slider mentok 130% |
| S5 | Beli Lapak bersamaan oleh 2 player | Hanya 1 berhasil, tidak ada duplikasi item |
| S6 | Kerja Bakti Kilat dengan 1 player di server (Hujan Deres selesai) | 16 objek muncul, bisa 100% sendirian dalam 8 menit, bonus 100% didapat |
| S7 | Kerja Bakti Kilat ke-5 dalam 1 hari (pindah-pindah server) | Bisa ikut, tidak dapat Koin/XP, toast batas 1x |
| S7b | Hujan Gerimis selesai | Tidak memicu Kerja Bakti |
| S7c | Dua player klik objek yang sama bersamaan | Hanya 1 dapat poin, objek hilang untuk semua |
| S7d | Tidak ikut Kerja Bakti sama sekali | Kotoran memudar saat timer habis, tidak ada efek negatif |
| S8 | Like lahan yang sama 2x | Tombol `Sudah Like` |
| S9 | Join event di hari ke-10 dari 14, login tiap hari | Tetap bisa membuka & menyelesaikan 8 pesanan |
| S10 | Event berakhir dengan Token sisa | Token jadi Koin (1:50), dekor event tetap, Plakat didapat |
| S11 | Akun baru | Lahan penuh ilalang + 5 bangunan rusak, area 24x24 bersih |
| S12 | Taruh petak di atas ilalang | Ghost hijau, ilalang auto-bersih, Jerami masuk tas |
| S13 | Setor Lumbung sebagian, logout, login di server lain | Progres setoran sama persis |
| S14 | Pulihkan Bundel | Cutscene bisa di-skip, fitur aktif, Surat spesial masuk, 10 Bunga masuk 1x |
| S15 | Coba hapus bangunan Kakek di Mode Hias | Tidak bisa dihapus, bisa dipindah |

### 30.5 Monetisasi (WAJIB)

| No | Test | Diharapkan |
|----|------|------------|
| M1 | Beli Paket Pemula 2x | Kedua kali tidak tersedia |
| M2 | Server crash saat beli Bunga | Setelah login, Bunga masuk tepat 1x |
| M3 | Cari loot box / iklan / jual Koin | Tidak ada |
| M4 | Instant tanaman 4 jam | 30 Bunga, sesuai kurva |
| M5 | Season Premium | Hadiah premium masuk otomatis per level, tidak dobel |

### 30.6 Performa & GUI (WAJIB untuk PF, boleh patch untuk G/S)

| No | Test | Diharapkan |
|----|------|------------|
| PF1 | HP 4GB, 8 player, Hujan Deres, 30 menit | FPS ≥ 25, tidak crash, memori ≤ 1,2 GB |
| PF2 | Lahan 800 piece, visit | Load ≤ 2 detik |
| PF3 | Server restart | Progres aman (DataStore) |
| G1 | Tombol Aksi 72×72 di HP 360px | Tidak kepencet Lompat |
| G2 | HUD ≤ 25% layar | Lahan terlihat |
| S1x | Haptic | Hanya 5 momen (Bab 20.2) |

### 30.7 Hasil Playtest

| Playtester | HP | Durasi | Seru (1-10) | Momen Paling Diingat | Bingung di Mana | Bug |
|------------|----|--------|-------------|----------------------|-----------------|-----|
| Anak 9-10 | | 30 mnt | | | | |
| Anak 12-14 | | 2 jam | | | | |
| Player Roblox umum | | 1 jam | | | | |
| HP 4GB | | 30 mnt | | | | |

Pertanyaan wajib ke playtester: "Kalau cerita ke teman, kamu bakal cerita apa?" — jawaban yang diharapkan: Mutasi, Legenda, rumah, atau Surat Kakek. Kalau jawabannya "nanem doang", hook belum kena.

**Keputusan Rilis:** FAIL di F, C, W, S, M, PF → jangan rilis. FAIL di G / S1x → boleh soft launch, perbaiki di patch.

---

## Penutup — Pesan untuk Claude Code

Kerjakan sesuai Bab 27, urut dari Fase 0. Semua angka ambil dari Bab yang ditunjuk dan simpan di Config — jangan karang angka baru. Jangan bikin fitur yang ada di Bab 29. Kalau ada yang tidak jelas, tulis TODO di `Docs/TODO.md` dan lanjut, jangan berhenti. Kalau ragu antara 2 desain, pilih yang lebih santai, lebih ramah, dan lebih sedikit teks.

Game ini harus terasa cozy setiap hari, dan sesekali bikin satu server teriak "WOOO" bareng.

Dokumen ini v6.2. Revisi berikutnya v6.3 + isi Changelog Bab 0.3.
