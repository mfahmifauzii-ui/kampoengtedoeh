# KAMPOENG TEDOEH — Dokumen Quest v0.3 (DRAFT)

> Status: **DRAFT untuk review owner.** Belum jadi sumber kebenaran. Setelah disetujui, isinya digabung ke dokumen gameplay (Bab 14 + Bab 4.4) di versi berikutnya. Sampai itu, `Kampoeng_Tedoeh_v7.5.md` / v7.6 tetap SSOT.
> v0.3 menggantikan v0.2: quest dibagi Main (buka gameplay baru, ada banner) dan Side (lanjutan tutorial, tanpa banner).
> Naskah dialog: `docs/Naskah_Dialog_Kampoeng_Tedoeh_v0.1.md`.
> Angka bertanda **USULAN** belum di-lock. Angka tanpa tanda diambil dari dokumen gameplay atau `Config/Quests.luau`.

---

## 1. Tujuan

Setelah FTUE selesai di "jual ikan ke Kak Fajar", pemain selalu tahu langkah berikutnya. Setiap fitur dikenalkan oleh quest pada saat fitur itu dibutuhkan, bukan muncul sendiri di HUD.

Contoh acuan (owner): Kolam punya syarat level, tapi tombol buat Kolam **tidak muncul** sampai quest menyuruh pemain membuat kolam.

---

## 2. Mekanisme "Buka Lewat Quest" (Feature Gate) — USULAN LOCK

| State | Kondisi | Yang dilihat pemain |
|-------|---------|---------------------|
| **Terkunci** | Level belum cukup | Tidak ada apa-apa. Tidak ada tombol abu-abu, tidak ada teaser. |
| **Siap** | Level cukup, langkah quest belum sampai | Quest muncul di tracker, NPC pemberi punya tanda `!`. **Tombol / prompt fitur masih disembunyikan.** |
| **Dikenalkan** | Langkah yang menyuruh pakai fitur sedang aktif | Tombol / prompt muncul, disorot (glow + panah), satu baris instruksi. |
| **Terbuka** | Langkah itu selesai sekali | Fitur terbuka permanen. |

Aturan:

1. **Level = syarat, Quest = pintu.** Naik level hanya memunculkan quest. Tombol fitur muncul dari langkah quest.
2. **Level buka fitur = level quest pengenalnya.** Tabel Unlock (Bab 4.4 gameplay) diselaraskan dengan Bab 4 dokumen ini.
3. **Tidak ada jalan buntu.** Langkah yang menyuruh pakai fitur harus bisa dikerjakan saat itu: bahan / Koin / item disediakan quest atau dijamin sudah dimiliki.
4. **Satu Main Quest aktif.** Paling atas di tracker, dengan tombol `Tunjukkan` (panah ke target). Side, Agenda, Order tetap jalan bersamaan. Detail Main vs Side di Bab 4.
5. **Antre kalau loncat level.** Quest pengenal muncul berurutan sesuai Bab 4, tidak sekaligus.
6. **Agenda / Harian / Mingguan / Order / Side** hanya memakai fitur yang sudah **Terbuka**.
7. **Tidak gagal karena waktu.**
8. **Client-side untuk kesan, server untuk hasil.** Dialog NPC, tanda `!`, sorotan, panah, NPC menoleh = client-side. Progres, hadiah, status Terbuka = server (PlayerData).
9. **Kepadatan:** maks 1 quest di Lv 1, maks 3 quest (Main + Side) per level setelahnya. Tiap quest 1–3 langkah, ±2–5 menit.
10. **XP quest kecil:** total XP quest Lv 1–10 ≤ 25% dari XP sampai Lv 10 (3.150 XP). Level naik dari main, bukan dari quest.

---

## 3. Hitungan Pace

- XP naik level: `200 + 30 x n` (Bab 4.2). Kumulatif: Lv 2 = 230, Lv 3 = 490, Lv 4 = 780, Lv 5 = 1.100, Lv 6 = 1.450, Lv 7 = 1.830, Lv 8 = 2.240, Lv 9 = 2.680, Lv 10 = 3.150.
- FTUE selesai di 158 XP (±10 menit). Sisa ke Lv 2 = 72 XP = 6 panen Kangkung, jadi **Lv 1 setelah FTUE hanya ±3 menit**.
- Asumsi pemain aktif campur (nanem + mancing sungai): **±1.500 XP/jam** (nanem saja ±970, mancing Early ±2.500). Dicek ulang saat playtest (Bab 17.8).

| Level | Menit dari awal main (perkiraan) | Lama di level ini | Quest (lihat Bab 4.3) |
|-------|-----------------------------------|-------------------|-------------|
| 1 (setelah FTUE) | 10 | ±3 mnt | 1 |
| 2 | 13 | ±10 mnt | 2 |
| 3 | 23 | ±12 mnt | 2 |
| 4 | 35 | ±13 mnt | 3 |
| 5 | 48 | ±14 mnt | 3 |
| 6 | 62 | ±15 mnt | 1 (3 langkah) |
| 7 | 77 | ±16 mnt | 1 |
| 8 | 93 | ±18 mnt | 2 |
| 9 | 111 | ±19 mnt | 1 |
| 10 | 130 | – | 2 |

Sesi pertama (±30–40 menit) berakhir di sekitar Lv 4: pemain baru masuk Hutan dan dapat Kolam Kakek (M3) sebagai "hadiah besar" sesi pertama.

---

## 4. Main Quest vs Side Quest

| | **Main Quest** | **Side Quest** |
|---|---|---|
| Isi | Membuka **gameplay baru** (sistem yang belum pernah dipakai pemain) **atau milestone cerita Kakek** (MQ11, MQ12) | **Lanjutan tutorial** dari gameplay yang sudah terbuka (bibit baru, lokasi baru, hewan baru, cara jual lain) |
| Banner `Dimulai` / `Selesai` | **Ya** (BannerController, pemain dikunci ±3 detik) | **Tidak.** Cukup baris di tracker + toast kecil saat selesai |
| Tracker | Selalu paling atas, tombol `Tunjukkan` | Di bawah Main. Kalau tidak ada Main aktif, Side teratas dapat tombol `Tunjukkan` |
| Jumlah aktif | Maks 1 | Boleh beberapa (tracker menampilkan maks 3, Bab 2 #9) |
| Feature Gate (Bab 2) | Berlaku | Berlaku juga (contoh: Kanal barat dibuka Side) |
| Menahan jalur | Ya, Main berikutnya menunggu Main sebelumnya | Tidak pernah menahan Main |

### 4.1 Main Quest (Lv 1 → Lv 10)

| # | Lv | Quest | Pemberi | Gameplay baru | Langkah | Hadiah | Asal |
|---|----|-------|---------|---------------|---------|--------|------|
| M1 | 2 | **Kampung Hari Ini** | Nek Ani | Agenda + Gerobak Kaget | Lihat Agenda → Selesaikan 1 tugas Agenda → Lihat Gerobak Kaget | 100 Koin | Baris FTUE 10:00 (hadiah sama) |
| M2 | 4 | **Ke Hutan** | Pak Amran | Nambang + Crafting | Pergi ke Hutan → Kumpulkan 10 Batu + 9 Kayu → Craft 2 Papan di Meja Crafting (pakai 4 Kayu, sisa 5 untuk M3) | 20 XP + 50 Koin (USULAN) | Baris FTUE 5:00 + Unlock Meja Crafting |
| M3 | 4 | **Kolam Kakek** | Kak Fajar | Kolam (beternak ikan) | Ngobrol → **Bangun Kolam Kakek** (setor 10 Batu + 5 Kayu + 3 ikan Early; tombol Kolam baru muncul di langkah ini) → Tangkap 1 ikan di kolam | Kolam Tanah gratis, breeding 10% lebih cepat + 300 Koin + 60 XP | MQ4 + Bundel Kolam Kakek + `kolam_pertama` |
| M4 | 5 | **Pagar Pertama** | Pak Amran | Hias | Pasang 1 Pagar Bambu (tombol Hias muncul) | – | Baris FTUE 6:00 |
| M5 | 5 | **Kokok Pertama** | Pak Udin | Ternak | Terima Ayam → Isi pakan → Ambil 1 telur | Ayam gratis + Kandang Lv 1 | MQ6 |
| M6 | 6 | **Dapur Pertama** | Mak Sari | Dapur + Buff Olahan | Craft Tungku → Masak 1 olahan → Makan 1 olahan | 200 Koin | MQ7 + Bab 9.4 |
| M7 | 7 | **Warung Pertama** | Mak Sari | Warung Player | Pasang Warung → Jual 1 olahan di Warung | 200 Koin | MQ9 |
| M8 | 8 | **Jebakan Kak Fajar** | Kak Fajar | Bubu | Pasang 1 Bubu (selesai saat terpasang; Bubu butuh 6 jam, jadi panen tidak ditunggu) | 1 Bubu Bambu | MQ5 + MQ8 digabung |
| M9 | 8 | **Sumur Tua** | Nek Ani | Bundel Kakek | Pulihkan Bundel Sumur Tua | 300 Koin + 5 Bunga | MQ10 |

- M2 minta 10 Batu + 9 Kayu: 4 Kayu habis untuk 2 Papan, sisanya (10 Batu + 5 Kayu) pas untuk setoran M3. M3 baru muncul setelah M2 selesai.
- 3 ikan Early untuk M3 sudah dimiliki dari mancing sungai dekat lahan. Kalau belum ada, langkah M3 menunjuk ke sungai terdekat dulu.

### 4.2 Side Quest (Lv 1 → Lv 10)

| # | Lv | Quest | Pemberi | Lanjutan dari | Langkah | Fitur yang dibuka | Hadiah | Asal |
|---|----|-------|---------|---------------|---------|-------------------|--------|------|
| S1 | 1 | **Bibit Kedua** | Pak Udin | Nanem | Beli 2 Bibit Bayam → Tanam 2 Bayam | – (Tab Beli sudah terbuka di akhir FTUE) | 50 Koin (USULAN) | Baris FTUE 4:00 |
| S2 | 2 | **Surat Pertama** | Mak Sari | Cerita Kakek | Baca Surat Kakek #1 | Tombol Surat | (hadiah Surat #1) | Baris FTUE 8:00 |
| S3 | 3 | **Tetangga di Depan** | Bang Jali | Jual | Jual 1 barang ke Bang Jali | Prompt jual Bang Jali | – | Unlock Bang Jali |
| S4 | 3 | **Rumah dari Kakek** | Pak Amran | Lahan | Ngobrol dengan Pak Amran | Rangka rumah pertama di lahan | – | Bab 10.1 |
| S5 | 5 | **Ikan Kanal** | Kak Fajar | Mancing | Tangkap 1 ikan Mid di dermaga Kanal barat | Mancing Kanal barat | 100 Koin (USULAN) | Kanal barat Lv 5 |
| S6 | 5 | **Tetangga Baik (kenalan)** | Nek Ani | Sosial | Bantu 1 lahan pemain lain | Prompt Bantu | +40 Koin +10 XP dari Bantu | Bab 12.2 |
| S7 | 9 | **Sawah** | Pak Udin | Nanem | Tanam 1 Padi → Panen (dapat Jerami) | – | 100 Koin (USULAN) | Unlock Padi |
| S8 | 10 | **Kandang Bebek** | Pak Udin | Ternak | Bangun Kandang Bebek → Beli 1 Bebek | Kandang Bebek | 200 Koin (USULAN) | Unlock Lv 10 |
| S9 | 10 | **Empang** | Kak Fajar | Mancing | Tangkap 1 ikan di Empang (Kanal timur) | Mancing Empang | 200 Koin (USULAN) | Unlock Lv 10 |

Side Quest Bab 14.4 gameplay yang sudah ada (Kucing Alun-alun, Joran Hilang, Rumah Rapi, Tetangga Baik 10x, Resep Mak, Panen Prima, Ikan Jumbo, Kolektor Album, Kerja Bakti 10x, Warung Laris) tetap Side Quest, tanpa banner.

### 4.3 Per Level (ringkas)

| Lv | Lama di level | Main | Side |
|----|---------------|------|------|
| 1 | ±3 mnt | – | S1 |
| 2 | ±10 mnt | M1 | S2 |
| 3 | ±12 mnt | – | S3, S4 |
| 4 | ±13 mnt | M2 → M3 | – |
| 5 | ±14 mnt | M4 → M5 | S5, S6 |
| 6 | ±15 mnt | M6 | – |
| 7 | ±16 mnt | M7 | – |
| 8 | ±18 mnt | M8 → M9 | – |
| 9 | ±19 mnt | – | S7 |
| 10 | – | – | S8, S9 |

Petak 13–24 (Lv 10) tidak butuh quest: cukup syarat level di modal beli petak.

### 4.4 Setelah Lv 10

Main Quest untuk gameplay baru: Kirim Hadiah (Lv 20), Akuarium (Lv 25), Rumah 2 Lantai (Lv 40). Main Quest milestone cerita: **MQ11 Legenda Pertama** (Lv 15) dan **MQ12 Warga Kampoeng Tedoeh** (semua Main + 50% Album), hadiah tetap seperti Bab 14.2 gameplay. Side Quest untuk lanjutan: Lumbung (Lv 12), Dapur Kampung / Kolam Semen / Pohon Aren / Bingkai Album (Lv 15), Spot 4 (Lv 18), Saung (Lv 20), Sapi (Lv 22), Kaca (Lv 25), Kolam Keramik / Empang & Dermaga Kakek (Lv 30), Dapur Lengkap (Lv 35), Bubu Besi (Lv 40), Set Joglo (Lv 50). Detail di v0.4.

---

## 5. Fitur yang Disembunyikan Sampai Quest

| Fitur / UI | Lv | Muncul di |
|------------|----|-----------|
| Tab Beli Pak Udin | 1 | Akhir FTUE |
| Tombol Surat | 2 | S2 |
| Tombol Agenda, Gerobak Kaget | 2 | M1 |
| Prompt jual Bang Jali | 3 | S3 |
| Rangka rumah | 3 | S4 |
| Hutan Nambang, Tombol Craft | 4 | M2 |
| Tombol Kolam | 4 | M3 langkah 2 |
| Tombol Hias | 5 | M4 |
| Kandang Ayam, Ambil Semua | 5 | M5 |
| Mancing Kanal barat | 5 | S5 |
| Prompt Bantu | 5 | S6 |
| Tombol Dapur, Makan, ikon buff | 6 | M6 |
| Warung Player | 7 | M7 |
| Bubu | 8 | M8 |
| Bundel Kakek | 8 | M9 |
| Kandang Bebek | 10 | S8 |
| Mancing Empang | 10 | S9 |

Tidak di-gate quest (cukup level): bibit baru di toko, ikan baru di spot yang sudah terbuka, joran / umpan baru, skill (SP), Login / Peti / Season, Album, Settings, petak 13+.

---

## 6. Perubahan ke Dokumen Gameplay (kalau v0.2 disetujui)

| Bab | Sebelum | Sesudah |
|-----|---------|---------|
| 4.4 Unlock | Bang Jali Lv 2 | Lv 3 |
| 4.4 / 7.2 / 14.6 | Kolam Tanah Lv 3, Kolam Kakek Lv 3 (MQ4 + Bundel) | Kolam Kakek = M3 Lv 4. Kolam Tanah tambahan dibeli setelah M3. `Fishing.POND.UNLOCK_LEVEL` 2 → 4 |
| 14.2 | `kolam_pertama` Lv 2 terpisah | Digabung ke M3 |
| 4.4 / 9.3 | Warung Lv 6 | Lv 7 |
| 4.4 / 6.6 | Bubu Bambu Lv 6 | Lv 8 |
| 14.6 | Sumur Tua Lv 6 | Lv 8 (bareng MQ10) |
| 14.2 | MQ5 + MQ8 terpisah | Digabung jadi M8 |
| 16.2 / 16.5 | Mancing FTUE di dermaga Kanal, Kolam Lv 2 | Mancing FTUE di sungai dekat lahan; Kolam Lv 4 |

---

## 7. Keputusan Owner (2026-11-22)

- Surat Kakek = **Side** (S2), tanpa banner.
- MQ11 + MQ12 = **Main** sebagai milestone cerita, dengan banner.

## 8. BUTUH KEPUTUSAN OWNER

1. **Hadiah USULAN** (M2, S1, S5, S7–S9): 50–200 Koin. Dicek di playtest supaya pace level tidak bergeser.
2. **Asumsi ±1.500 XP/jam** untuk pemain aktif. Kalau playtest jauh beda, tabel Bab 3 dihitung ulang.
3. **Warung Lv 7 dan Bubu Lv 8** menggeser level buka fitur di dokumen gameplay (sebelumnya Lv 6). Setuju?
