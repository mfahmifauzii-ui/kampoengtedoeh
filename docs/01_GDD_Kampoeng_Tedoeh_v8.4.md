# KAMPOENG TEDOEH — Game Design Document v8.4
## Single Source of Truth (gameplay, angka, aturan)

> **Versi sekarang: v8.4 = semua keputusan K-01…K-66** (Audit Bab 3). Menggantikan `Kampoeng_Tedoeh_v7.4…v7.7.md` dan `Skill_Tree_Kampoeng_Tedoeh_v7.7.md` (sekarang Bab 4.5).
> **Nomor bab sengaja sama dengan v7.x** supaya komentar kode "Bab 9.4" dll. tetap benar.
> Angka di kode yang masih beda dari dokumen ini diselaraskan oleh tugas `R1.x`, bukan dengan menurunkan dokumen.
> Riwayat perubahan ringkas: tabel "Riwayat revisi" di akhir dokumen. Riwayat lengkap ada di git dan di Audit Bab 4.

### Cara Baca

| Tanda | Arti |
|-------|------|
| **LOCKED** | Angka/aturan final. Jangan diubah tanpa keputusan owner dan nomor versi baru. |
| **USULAN** | Sudah jalan di kode, angka belum dikunci owner. Boleh disetel saat balancing. |
| **✔ K-xx** | Sudah **DIPUTUSKAN** (Audit Bab 3.0). Teks di baris itu = aturan final. Kalau kode belum sama, tugas `R…` di Roadmap menyamakannya. |
| **⚠ belum ada di kode** | Hanya status implementasi, bukan menunggu keputusan. |
| `id_kode` | Nama di kode / Config. |

Aturan revisi: angka berubah → versi naik (v8.1, v8.2 …) + satu baris di Audit Bab 4 atau changelog commit. Setiap angka hanya ditulis di **satu** bab; bab lain merujuk.

---

## 0. Ringkasan

### 0.1 Satu Paragraf

Kampoeng Tedoeh adalah game Roblox cozy farming + fishing + ranching + cooking + building berlatar kampung Indonesia, untuk 16+, netral gender. Pemain adalah cucu Kakek Daeng yang pulang mengurus lahan warisan dan menemukan surat-surat kakeknya. Tidak ada fail, tidak ada stamina, tidak ada hukuman. Tanaman, hewan, dan bangunan tidak pernah mati atau rusak. Sesi ideal 20–40 menit. Yang bikin pemain cerita ke temannya: **panen Prima saat hujan, Ikan Legenda yang diumumkan ke satu server, Gerobak Kaget yang restock tiap 15 menit, dan Olahan yang dimakan sendiri jadi buff.** Yang bikin balik besok: **bubu, kolam, Surat Kakek harian, Order Villager harian, Bundel Kakek, dan Kerja Bakti Kilat setiap habis hujan deres / petir.** Tidak ada sistem yang butuh banyak pemain supaya bisa selesai.

Tagline: `Kampung lo, rumah lo, panen lo — tiap hujan bisa jadi panen Prima.`

### 0.2 Target Desain

| Target | Angka | Rujukan |
|--------|-------|---------|
| Sesi ideal | 20–40 menit | Bab 2 |
| Pemain inti (2 jam/hari) capai Lv 60 | ~32 hari (55–70 jam main) | Bab 17.8 ✔ K-11 (acuan; disetel di R9.1) |
| Pemain santai (45 menit/hari) hari ke-30 | ~Lv 26 | ✔ K-11 |
| Sink terselesaikan saat Lv 60 | 65–80% (hitungan terakhir 79–81%, perlu simulasi ulang) | Bab 17.4 |
| Level Cap | Lv 60 saat rilis, +20 tiap Update Besar | Bab 26 |
| Retensi D1 / D7 / D30 | 35% / 15% / 6% | Bab 25 |
| Konversi bayar | 3% | Bab 18 |

---

## 1. Prinsip Desain — LOCKED

| # | Prinsip | Artinya di kode |
|---|---------|-----------------|
| 1 | Cozy, tanpa fail | Tanaman tidak mati/layu. Hewan tidak mati/sakit/kabur. Bangunan tidak roboh. Quest tidak gagal karena waktu. Hapus bangunan & dekor refund 100%. Petak bukan bangunan: refund 50% (Bab 5.2). ✔ K-09 |
| 2 | Tanpa stamina | Batas main hanya dari waktu tumbuh. |
| 3 | Siram itu bonus | Tanaman tumbuh tanpa siram. Siram mempercepat + menandai Basah. (Di tutorial siram wajib, Bab 16.) |
| 4 | Tanpa pupuk, tanpa hama | — |
| 5 | Langka itu momen, bukan rebutan | Kelangkaan dihitung per pemain (pity). |
| 6 | Hias karena suka | Hanya Dekor Berkah yang punya stat. |
| 7 | Hias per satuan | Tidak ada rumah jadi. Tidak ada Robux/Bunga untuk skip bangun. |
| 8 | Lahan 100% bebas | Tidak ada zona dikunci di dalam lahan. |
| 9 | Waktu itu server | Hari game, cuaca, reset harian diatur server. |
| 10 | HP 4GB adalah target | RAM 4GB, Helio G99 / Unisoc T7250. Anggaran aset di `04_Asset_Bible.md` Bab 2. |
| 11 | Dua ekonomi terpisah | Koin dan Bunga tidak bisa ditukar dua arah. |
| 12 | Bunga = kenyamanan & gaya | Tidak membeli Koin, XP, level, bahan mentah, hewan. Semua konten bisa F2P. |
| 13 | Sehat untuk 16+ | Tidak ada hadiah main > 60 menit, streak yang reset, loot box, iklan, desain judi/FOMO. |
| 14 | Jangan terlalu diinfokan | UI = angka & ikon. Info pertama kali = toast 1x, lalu diam. |
| 15 | 1 aturan, 1 tempat | Setiap angka hanya di 1 Config dan 1 bab dokumen. |
| 16 | Tidak bergantung jumlah pemain | Game lengkap walau server cuma 1 orang. Target bersama dihitung dari pemain di server saat itu. ⚠ K-73: Kebun Warga dibatalkan, Bantu disembunyikan. Solo: Warga (Mampir, Suka, hadiah) hanya tampil di 2+ pemain (K-75). Sosial solo diterima dan kembali bersama `BANTU_ENABLED` (K-82). |
| 17 | Kualitas, bukan lotre | Kualitas dari timing + siram. Tidak ada Mutasi, Pelangi, Greenhouse, Super. |

**Gating — LOCKED.** Boleh: Level, Koin, Quest (feature gate, `03_Quest_Naskah.md` Bab 2). Dilarang: Blueprint gating, Backpack/Tas gating, Bibit Unggul, apa pun di balik Robux selain kosmetik & QoL.

---

## 2. Target Pemain & Sesi

### 2.1 Persona (16+)

| Persona | Main | Dicari | Ditangkap oleh |
|---------|------|--------|----------------|
| Santai | 30–45 mnt/hari, HP | Cozy, gampang, cerita | Tutorial cepat, hewan, Kualitas, Gestur |
| Dekorator | 1–2 jam/hari | Rumah cantik, like | Hias, Blueprint, Galeri |
| Kolektor | 2+ jam/hari | Lengkap 100%, langka | Album 214, Legenda, Prima |
| Roblox umum | Coba 5 menit | Seru di menit pertama | FTUE Bab 16, panen pertama dijamin Bagus |

### 2.2 Contoh Sesi 30 Menit (bukan paksaan)

| Menit | Aktivitas |
|-------|-----------|
| 0–3 | Login, ambil telur, isi bubu & kolam, buka Surat Kakek |
| 3–10 | Panen + tanam ulang, cek Gerobak Kaget |
| 10–20 | Mancing (hujan = momen bagus, ✔ K-01) |
| 20–25 | Nambang 1 putaran |
| 25–30 | Hias / Warung / bantu tetangga, tanam Late sebelum logout |

### 2.3 Batas Sehat — LOCKED

- Hadiah Waktu Bermain hanya sampai 60 menit (Bab 15.2).
- Setelah 120 menit main dalam 1 hari WIB: toast 1x `Udah 2 jam nih. Jangan lupa minum & istirahat ya!`
- Tidak ada streak yang reset.

---

## 3. Dunia, Waktu & Cuaca

> Map sudah ada di Studio. **Layout map tidak diubah.** Menambah prop (meja, papan, spot, dekor event) di map boleh, asal tidak memindah terrain / jalan / lahan.

### 3.1 Dunia & Server

| Item | Aturan |
|------|--------|
| Server | Maks 8 pemain. StreamingEnabled ON. |
| Lahan awal | 128×128 stud, bersih (tanpa ilalang / bangunan rusak). Pengecualian: kerangka Bundel Kakek (Bab 14.6) dan rangka rumah hadiah Pak Amran (S4) muncul saat quest-nya. |
| Beli chunk | 32×32 stud, harga chunk ke-n (n mulai 0) = `1.500 × 1,2^n` dibulatkan 10. 14 chunk, total 88.790. Maks 192×192. |
| Grid | Petak tanam 8×8 stud (`Land.TILE`). Hias: struktur snap 2 stud, furniture/dekor 1 stud. Rotasi 0/90/180/270. |
| Hutan Nambang | Area bersama, node per pemain. |

**Perairan (lokasi mancing):**

| Nama di game | Id kode | Buka | Isi |
|--------------|---------|------|-----|
| Sungai Lahan | `sungai_lahan` | Lv 1 | 32 spot (8 per sungai sumbu, 4 per tepi), tanpa dermaga, penanda riak. Early saja. |
| Kanal Barat | `sungai` | Lv 5 (S5) | Dermaga. Mid + Belut Emas. |
| Kanal Timur | `empang` | Lv 10 (S9) | Dermaga. Late + Gurame Raja + Ikan Dewa. |
| Kolam pemain | `kolam` | Lv 4 (M3, ✔ K-43) | Mancing dari stok kolam sendiri (Bab 7.2). |
| Empang & Dermaga Kakek | bundel | Lv 30 | Spot pribadi di lahan (Bab 14.6). |

Danau dan Spot 4 **tidak ada** di map. ✔ K-22 (dihapus dari desain; Lv 18 = "Kanal Timur malam"). Kata "Empang" untuk pemain hanya dipakai di Bundel. ✔ K-23

### 3.2 Hari Game — LOCKED

1 hari game = 30 menit nyata.

| Fase | Durasi | Gameplay |
|------|--------|----------|
| Pagi | 3 mnt | Gurame Raja, Semah |
| Siang | 15 mnt | Normal (Tawes) |
| Sore | 3 mnt | Toman mulai |
| Malam | 9 mnt | Ikan malam, Pasar Malam (Bab 13.2) |

Reset harian (Agenda, Login, Bantu, Order, batas Kerja Bakti) = **05:00 WIB**. HUD menampilkan ikon fase, bukan jam.

### 3.3 Cuaca — LOCKED

| Aturan | Detail |
|--------|--------|
| Siklus | Terik 8–15 mnt (acak) → Hujan 3 mnt → Terik … Tidak pernah hujan 2x berturut. |
| Jenis hujan | Gerimis 55%, Deres 30%, Petir 15%. |
| Tanda | 10 detik sebelum hujan: awan gelap + suara + ikon. Tidak ada ramalan. |
| Terik | Netral. |

**Efek hujan:**
- Semua tanaman luar tersiram 1x (potong sisa 15%) dan tumbuh **2x lebih cepat** selama hujan.
- Mancing ✔ K-01 + K-49: tidak ada batas waktu gigitan (ikan menunggu di kail sejak keputusan 16 Nov). Hujan tidak lagi menggandakan waktu tunggu (K-49).
- **Mood Hujan:** 5 menit setelah hujan, produk ternak yang diambil +10% Koin; breeding kolam yang dimulai di jendela itu −10% waktu.
- Kerja Bakti Kilat setelah Deres / Petir (Bab 13.4).

Contoh LOCKED: tanaman 30 mnt, siram −4,5 → sisa 25,5; hujan 3 mnt memotong 6 → sisa 19,5; total 22,5 mnt.

---

## 4. Mata Uang, Level, Unlock, Skill

### 4.1 Mata Uang

| Mata uang | Dapat dari | Dipakai untuk | Tidak bisa |
|-----------|------------|---------------|------------|
| Koin | Jual hasil, Warung, Agenda, Order, Bantu, Like, Kerja Bakti, Login, Hadiah Main, quest | Bibit, umpan, pakan, hewan, alat, petak, chunk, skill, bangunan | Ke Bunga |
| Bunga | Login Mingguan, Peti Bunga, Album, Season, Event, Bundel, quest tertentu, Robux | Alat Bunga (QoL), kosmetik, dekor Bunga, instant Kolam, reroll Order, slot Blueprint, Season Premium | Ke Koin, XP, level, bahan mentah, hewan |
| Bahan | Nambang, Jerami (Padi), Daun Pisang (Pisang) | Craft hias, alat, bangunan | Tidak dijual dan tidak dibeli di mana pun (✔ K-42) |

- **Nilai awal (v8.2, ✔ K-48):** Koin awal 100, Bunga awal 10 (`Config/Economy`). Ikut kode, bukan angka desain baru.
- **Hadiah kategori Album (v8.2, ✔ K-48):** kategori Ladang dan Sungai lengkap = 300 Koin masing-masing (`Config/Book`).

### 4.2 Level Pemain

- Level Cap rilis **Lv 60**, +20 tiap Update Besar.
- XP naik level Lv n → n+1 = `200 + 30 × n`. Contoh Lv 1→2 = 230; **Lv 59→60 = 1.970**. Total Lv 1→60 = **64.900 XP**.
- Kumulatif: Lv 2 = 230, Lv 3 = 490, Lv 4 = 780, Lv 5 = 1.100, Lv 6 = 1.450, Lv 7 = 1.830, Lv 8 = 2.240, Lv 9 = 2.680, Lv 10 = 3.150, Lv 20 = 9.500, Lv 26 = 14.750, Lv 45 = 38.500.
- XP didapat dari: Panen, Mancing, Ternak, Masak, Bantu, Kerja Bakti, quest. Nambang ✔ K-08: **2 XP per bahan** (disetel di R9.1).
- Tidak ada Bunga dari level-up.

### 4.3 SP

- 1 SP per level (SP di Lv n = n − 1). Sampai Lv 60 = 59 SP.
- Skill tidak bisa dibeli dengan Bunga / Robux. Tidak ada reset skill.

### 4.4 Unlock (urut level)

Kolom "Pintu" = cara fitur muncul. "Level" = cukup naik level. Quest = muncul di langkah quest itu (`03_Quest_Naskah.md`).

| Lv | Buka | Pintu |
|----|------|-------|
| 1 | Kangkung, Bayam; Wader Cakul, Betok; Joran Bambu; Sungai Lahan; Tab Beli Pak Udin | Level / akhir FTUE |
| 2 | Tomat, Sawi; Sepat, Lele; Joran Kayu; Sepatu Bot | Level |
| 2 | Pohon Skill (Bertani, Mancing) | Level (`FeatureGate.LEVEL_GATES.skill`) |
| 2 | Agenda + Gerobak Kaget (+ Kerja Bakti); Surat Kakek | M1; S2 |
| 3 | Jagung, Ubi Jalar, Pakan Jagung; Gembor Seng, Kapak Besi | Level |
| 3 | Jual ke Bang Jali; Rangka rumah | S3; S4 |
| 4 | Hutan Nambang + Meja Crafting + skill Tukang; Joran Kayu Jati | M2 / Level |
| 4 | Kolam Kakek, lalu Kolam Tanah bisa dibeli | M3 |
| 5 | Ayam + Kandang Ayam + skill Ternak; Mujair, Nila; Sabit Besi | M5 / Level |
| 5 | Hias; Kanal Barat; Bantu | M4; S5; S6 |
| 6 | Singkong; Jahe ✔ K-02; Tawes; Udang Kecil; Bambu Wulung; Dapur Tier 1 + Makan/buff + skill Masak | Level / M6 |
| 7 | Warung Player; Kapak Baja | M7 / Level |
| 8 | Cabai, Padi, Tebu ✔ K-02; Gurame; Joran Besi; Gembor Kuningan | Level |
| 8 | Bubu Bambu; Bundel Sumur Tua | M8; M9 |
| 10 | Bebek + Kandang Bebek; Patin, Gabus; Joran Pusaka; Petak 13–24; Kanal Timur; capstone skill & Tetangga Baik | Level / S8 / S9 |
| 12 | Stroberi; Baung | Level |
| 15 | Pisang, Melati ✔ K-02; Jelawat; Gurame Raja (Legenda); Dapur Tier 2; Kolam Semen; Pohon Aren (Ijuk); Bingkai Album; Bundel Lumbung | Level |
| 18 | Toman, Tapah; **Kanal Timur malam** ✔ K-22 | Level |
| 20 | Belut Emas (Legenda); Kirim Hadiah; Bundel Saung Kakek | Level |
| 22 | Sapi; Sidat | Level |
| 25 | Kopi, Teh; Semah; Kaca; Akuarium; Petak 25–36 | Level |
| 30 | Belida; Ikan Dewa (Legenda); Kolam Keramik; Bundel Empang & Dermaga Kakek | Level |
| 35 | Mangga; Dapur Tier 3 | Level |
| 45 | Durian | Level |
| 50 | Set Joglo | Level |

Bibit/ikan/joran/umpan baru tidak digerbang quest — cukup level.

### 4.5 Skill Tree — 16 skill, 6 cabang

#### 4.5.1 Aturan beli — LOCKED

- 1 level skill = **1 SP + Koin yang naik**: Lv 1 = 1.000, Lv 2 = 2.000, Lv 3 = 3.000, Lv 4 = 4.000, Lv 5 = 5.000 ✔ K-12. Total per skill 15.000; total semua 240.000 (kode saat ini 3.000 rata → R1.8).
- Maks 1 skill = 5 level = 5 SP + 15.000 Koin. Semua skill = 80 SP + 240.000 Koin (tercapai Lv 81).
- **K-76 (Bantu disembunyikan):** selama `BANTU_ENABLED = false`, Tetangga Baik tidak tampil dan tidak bisa dibeli, sehingga cabang Sosial tidak tampil. Yang tersedia 15 skill, 5 cabang. Semua skill yang bisa dibeli = 75 SP + 225.000 Koin (tercapai Lv 76). Angka di atas (16 skill, 80 SP) berlaku saat flag hidup. Tidak ada skill lain yang prasyaratnya memakai total level Tetangga Baik.
- Sampai Lv 60 pemain hanya punya 59 SP → harus memilih cabang. Belanja skill maksimal sampai Lv 60 = 177.000 Koin.
- Beli hanya bila **Player Lv** cukup **dan** prasyarat skill terpenuhi (dihitung dari level skill). Tidak ada level cabang.
- "N SP di mana pun" = jumlah level semua skill ≥ N.
- Skill berada di luar cap Dekor (maks +10% per jenis, Bab 17.6).
- Server menolak dengan alasan: `ok / max / locked / noSP / noKoin`. Beli atomik (tidak ada potong sebagian).

#### 4.5.2 Skill bertahap

Tempat Pakan Besar (efek di Lv 3), Tukang Cepat (Lv 3 dan 5), Tetangga Baik (Lv 3 dan 5). Lv 1–2 = investasi tanpa efek; drawer wajib menulis **"Efek mulai Lv 3"**. Skill lain berefek sejak Lv 1.

#### 4.5.3 Pohon

| Cabang | Tier | Skill | Efek per Lv (maks Lv 5) | Prasyarat |
|--------|------|-------|-------------------------|-----------|
| Bertani | Root | Tangan Hijau | Tumbuh +2%/lv | Player Lv 2 |
| Bertani | Cabang A | Bibit Hemat | 4%/lv bibit kembali saat panen | Tangan Hijau Lv 2 + Player Lv 4 |
| Bertani | Cabang B | Mata Kualitas | Peluang Bagus +2%/lv, Prima +0,5%/lv | Tangan Hijau Lv 2 + Player Lv 6 |
| Bertani | Capstone | Panen Raya | +2% Koin Nanem/lv | (Bibit Hemat Lv 3 ATAU Mata Kualitas Lv 3) DAN Player Lv 10 |
| Mancing | Root | Joran Kuat | Kotak tarik +2%/lv | Player Lv 2 |
| Mancing | Cabang A | Umpan Hemat | 5%/lv umpan kembali saat lepas | Joran Kuat Lv 2 + Player Lv 4 |
| Mancing | Cabang B | Firasat | Pity −10/lv (min 150) | Joran Kuat Lv 2 + Player Lv 6 |
| Mancing | Capstone | Ikan Besar | Peluang Besar/Jumbo +2%/lv | (Umpan Hemat Lv 3 ATAU Firasat Lv 3) DAN Player Lv 10 |
| Ternak | Root | Tempat Pakan Besar | Jatah maks 3 → 5 (efek Lv 3) | Player Lv 5 |
| Ternak | Cabang | Telur Cepat | Cooldown −2%/lv | Tempat Pakan Besar Lv 2 + Player Lv 8 |
| Ternak | Capstone | Susu Melimpah | +2% Koin Ternak/lv | Telur Cepat Lv 3 + Player Lv 12 |
| Tukang | Root | Kayu Kuat | +2% bahan Nambang/lv | Player Lv 4 |
| Tukang | Capstone | Tukang Cepat | +1 bahan/node di Lv 3, +2 di Lv 5 | Kayu Kuat Lv 3 + Player Lv 8 |
| Masak | Root | Koki Cepat | Waktu olah −3%/lv | Player Lv 6 |
| Masak | Capstone | Rasa Prima | Peluang Olahan **naik 1 tingkat kualitas** +1%/lv ✔ K-05 | Koki Cepat Lv 3 + Player Lv 10 |
| Sosial | Tunggal | Tetangga Baik | +1 lahan Bantu/hari di Lv 3, +2 di Lv 5 | Total level skill ≥ 5 + Player Lv 10 ✔ K-17 |

"+2%" pada Joran Kuat dan "+10%" pada buff Pancing: Claude Code menulis di sini apakah poin persen atau relatif, sesuai kode (Audit A-50).

#### 4.5.4 Tumpukan bonus — LOCKED

- Kapak: hanya kapak terbaik dihitung (Besi +1, Baja +2, Kapak Bunga +1 = alternatif Besi).
- Kapak + Tukang Cepat menumpuk, **maks +4 bahan per node** (dasar 4 → maks 8).
- Buff Tukang/Tebang hanya +1 saat Critical, tidak menembus batas +4.

#### 4.5.5 Tampilan

Layout di `05_GUI_Spec.md` Bab 6.2. Node: Terkunci (abu + prasyarat), Bisa dibeli (nyala), Kurang SP/Koin (tombol nonaktif + alasan), Maks (bingkai emas). Garis dahan menyala sampai node tertinggi yang dibeli.

---

## 5. NANEM — Semi-pasif, Core

### 5.1 Loop

Pilih petak → Tanam (bayar bibit) → Tumbuh (jalan walau offline) → Siram (opsional, wajib di tutorial) → Panen (Koin + XP + Kualitas) → tanam lagi.

**Bibit habis (T3, K-72):** tanam tanpa bibit untuk tanaman itu → satu toast Ok `Bibit {crop} habis. Beli di Pak Udin`. Toast tetap sampai di-Ok, atau hilang saat pemain membeli bibit. Tidak ada gelap, tidak memblokir joystick.

- Aksi tanam / panen ≈ 1 detik per petak.
- **Siram:** potong sisa waktu 15% (1x per siklus) + tanda Basah. Hujan menyiram otomatis.
- **Telat panen:** tanaman sedikit membesar (scale 1,1) setelah 10 menit matang. Tidak layu.

### 5.2 Petak

| Item | Aturan |
|------|--------|
| Petak awal | 6 (gratis) |
| Maks | 36 |
| Harga petak ke-n | `n × 150` (petak 7 = 1.050, petak 36 = 5.400). Total 7–36 = 96.750. Petak 13–24 butuh Lv 10, 25–36 butuh Lv 25. |
| Konfirmasi | Petak ke-7+ membuka modal harga. Koin kurang: harga merah, tombol dikunci, teks "Koin kamu belum cukup". |
| Hapus petak | Refund **50%** harga petak yang dibeli (harga dicatat per petak, `paid`). Petak gratis tanpa refund. ✔ K-09 |
| Garap | Bebas di mana saja di lahan sendiri. Tap kotak tidak valid → pindah ke kotak valid terdekat. |

### 5.3 Tanaman (18) — LOCKED

Bibit ≈ 30% harga jual.

| # | Tanaman | Tier | Waktu | Bibit | Jual | XP | Lv |
|---|---------|------|-------|-------|------|----|----|
| 1 | Kangkung | Early | 3 mnt | 8 | 25 | 12 | 1 |
| 2 | Bayam | Early | 5 mnt | 10 | 32 | 15 | 1 |
| 3 | Tomat | Early | 6 mnt | 12 | 36 | 16 | 2 |
| 4 | Sawi | Mid | 20 mnt | 25 | 80 | 35 | 2 |
| 5 | Jagung | Mid | 30 mnt | 35 | 110 | 45 | 3 |
| 6 | Ubi Jalar | Early | 7 mnt | 12 | 38 | 18 | 3 |
| 7 | Singkong | Mid | 25 mnt | 30 | 95 | 40 | 6 |
| 8 | Cabai | Mid | 30 mnt | 40 | 125 | 50 | 8 |
| 9 | Padi | Late | 2 jam | 120 | 400 | 140 | 8 |
| 10 | Stroberi | Late | 2 jam | 130 | 420 | 150 | 12 |
| 11 | Pisang | Late | 3 jam | 160 | 520 | 180 | 15 |
| 12 | Tebu | Mid | 40 mnt | 50 | 160 | 60 | 8 |
| 13 | Jahe | Mid | 35 mnt | 45 | 140 | 55 | 6 |
| 14 | Kopi | Late | 4 jam | 200 | 650 | 220 | 25 |
| 15 | Teh | Late | 6 jam | 260 | 850 | 280 | 25 |
| 16 | Melati | Mid | 30 mnt | 40 | 130 | 50 | 15 |
| 17 | Mangga | Late | 8 jam | 320 | 1.100 | 360 | 35 |
| 18 | Durian | Late | 8 jam | 380 | 1.300 | 400 | 45 |

- Padi +2 Jerami per panen. Pisang +2 Daun Pisang per panen (hanya untuk Pepes).
- Super Panen **dihapus**. Tidak ada pengali Koin/XP selain Kualitas.

### 5.4 Kualitas Panen — LOCKED

| Kualitas | Harga | Visual |
|----------|-------|--------|
| Biasa | ×1,0 | Normal |
| Bagus | ×1,1 | Kilau lembut |
| Prima | ×1,25 | Kilau emas, partikel kecil |

| Kondisi panen | Biasa | Bagus | Prima |
|---------------|-------|-------|-------|
| Tepat waktu (≤ 5 mnt setelah matang) + Basah | 50% | 35% | 15% |
| Hanya salah satu | 65% | 25% | 10% |
| Telat + tidak Basah | 85% | 12% | 3% |

- Bonus: Mata Kualitas (+2% Bagus, +0,5% Prima per lv), Buff Tani (+10% absolut ke Bagus), Orang-orangan Sawah (+3% Bagus, radius 5 petak).
- **Batas akhir setelah semua bonus: Bagus maks 50%, Prima maks 20%.** Biasa sisanya.
- Panen pertama FTUE selalu Bagus.
- Panen Prima tanaman Late → banner 3 detik ke server: `Raka panen DURIAN PRIMA!`
- Kualitas beda = stack beda di Tas.

### 5.5 Fitur Nanem Lain

| Fitur | Aturan |
|-------|--------|
| Pasar Harian | 2 tanaman +30% per hari WIB (1 Early, 1 Mid/Late), semua penjual. Ikon koin di atas petak. |
| Rotasi | Tanam beda dari siklus lalu di petak yang sama: +5% XP. |
| Bantu Tetangga | Bab 12.2. |

---
- **Gembor Emas (K-62):** kosmetik di tab Alat, dipasang lewat Pakai. Quest side_prima memberi item ini.


## 6. MANCING — Aktif, Fokus Pendek

### 6.1 Loop

Dekati spot → Tombol Mancing (bulat, ikon joran) → Lempar (0,6 dtk) → Tunggu gigitan → Gigitan: ikan menunggu di kail sampai pemain mulai tarik (tidak ada batas waktu, ✔ K-49) → Mini-game tarik → Kartu ikan → ulangi.

- Waktu tunggu: dengan umpan **3–6 dtk**. Urutan pengali: dasar → joran (`rod.biteMult`, ✔ K-26: angka disalin dari kode ke tabel 6.3 di R0.4) → umpan (Jangkrik ×0,7) → Buff Pancing (×0,8) → hujan (**tidak ada pengali**; hujan memperlebar jendela gigitan ✔ K-01). Kolam (kolam pemain) tidak memakai umpan dan punya aturannya sendiri: **6–12 dtk** (`Fishing.POND_BITE_*`).
- **Sungai dan empang wajib umpan (K-86, 2026-11-24).** Tanpa umpan di Tas, lemparan ditolak server; tombol Pancing mati dan chip berkata "Umpan habis, beli di Kak Fajar". Aturan tanpa umpan 6–12 dtk untuk sungai dan empang dihapus.
- Umpan otomatis: umpan pertama yang dimiliki menurut urutan Cacing → Jangkrik → Pelet → Udang Kecil. Tidak ada pilih umpan (final).
- Chip umpan di atas tombol: ikon, nama, jumlah, `-1` saat terpakai, "Umpan habis, beli di Kak Fajar" saat umpan habis (K-86; "Tanpa umpan" tidak dipakai lagi).
- **Pemain dikunci selama memancing.** Server membatalkan bila pemain lebih dari 24 stud dari spot (watchdog); umpan kembali. ✔ K-25
- Visual memancing (joran, tali, pelampung, animasi) direplikasi ke pemain lain.
- Lapak Kak Fajar (beli umpan, jual ikan 100%) di pinggir kanal alun-alun.

### 6.2 Mini-game Tarik — LOCKED

- Bar horizontal, ikan gerak kiri-kanan, kotak pemain: Tahan = kanan (`ZONE_SPEED 0.9` lebar bar/dtk), Lepas = kiri (`ZONE_SPEED_LEFT 0.55`).
- Progres mulai 30%. Ikan di kotak **+28%/dtk** (`FILL_GAIN 0.28`), di luar **−6%/dtk** (`FILL_DRAIN 0.06`). 100% = dapat. 0% = lepas, umpan hilang, tanpa hukuman lain.
- Lebar kotak dihitung **server** (joran + Joran Kuat + Buff Pancing) dan dikirim bersama gigitan.
- Perilaku ikan: Early pelan (5–8 dtk), Mid sering ganti arah (10–15), Late cepat + dash (15–25), Legenda dash + jeda (20–30).
- Mode Bantu (Settings, default OFF): kotak +10% & ikan 15% lebih lambat, hadiah sama.
- Tidak ada coachmark tarik.

### 6.3 Joran & Umpan — LOCKED

"Lv N" = **Player Lv N**.

| Joran | Harga | Kotak | Syarat | biteMult |
|-------|-------|-------|--------|----------|
| Bambu | Gratis (tutorial) | 30% | Lv 1 | dari kode |
| Kayu | 900 Koin + 10 Bambu | 33% | Lv 2 | dari kode |
| Kayu Jati | 3.500 + 20 Bambu | 36% | Lv 4 | dari kode |
| Bambu Wulung | 9.000 + 30 Bambu | 39% | Lv 6 | dari kode |
| Besi | 18.000 + 30 Bambu + 15 Batu | 42% | Lv 8 | dari kode |
| Pusaka | 35.000 + 40 Bambu + 20 Batu + 10 Ijuk | 45% | Lv 10 | dari kode |

| Umpan | Harga | Efek |
|-------|-------|------|
| Cacing | 10 | Standar |
| Jangkrik | 25 | Gigitan 30% lebih cepat |
| Pelet | 45 | +15% peluang Mid+ |
| Udang Kecil | 80 (Lv 6) | +10% peluang Late+ |
- **Pakai di Tas (K-55):** pancing dan umpan dipilih lewat "Pakai" di Tas. Mengganti D#42 / D#49 ("tanpa pemilihan umpan"). Umpan habis → pindah otomatis ke umpan berikutnya.


### 6.4 Ikan (20) — LOCKED

Ukuran diacak: Kecil ×0,8 (40%), Sedang ×1,0 (40%), Besar ×1,2 (15%), Jumbo ×1,5 (5%). Harga = Sedang. Peluang ini adalah basis tanpa bonus skill Ikan Besar (✔ K-46, dicek 1.000 sampel).

**Lokasi tambahan (✔ K-45):** ikan Mid **Mujair dan Nila** juga bisa didapat di **kolam** (aturan kolam Bab 7.2: ikan berasal dari stok pemain, bukan dari timer).

| # | Ikan | Tier | Lokasi | Waktu | Jual | XP | Lv |
|---|------|------|--------|-------|------|----|----|
| 1 | Wader Cakul | Early | Sungai Lahan | Kapan saja | 20 | 10 | 1 |
| 2 | Betok | Early | Sungai Lahan | Kapan saja | 26 | 12 | 1 |
| 3 | Sepat | Early | Sungai Lahan | Kapan saja | 30 | 14 | 2 |
| 4 | Lele | Early | Sungai Lahan | Malam | 45 | 18 | 2 |
| 5 | Mujair | Mid | Kanal Barat | Kapan saja | 70 | 26 | 5 |
| 6 | Nila | Mid | Kanal Barat | Kapan saja | 90 | 32 | 5 |
| 7 | Tawes | Mid | Kanal Barat | Siang | 110 | 38 | 6 |
| 8 | Gurame | Mid | Kanal Barat | Kapan saja | 160 | 50 | 8 |
| 9 | Patin | Mid | Kanal Barat | Kapan saja | 180 | 55 | 10 |
| 10 | Gabus | Mid | Kanal Barat | Hujan | 200 | 60 | 10 |
| 11 | Baung | Mid | Kanal Barat | Malam | 220 | 65 | 12 |
| 12 | Jelawat | Late | Kanal Timur | Kapan saja | 350 | 95 | 15 |
| 13 | Toman | Late | Kanal Timur | Sore/Malam | 420 | 110 | 18 |
| 14 | Tapah | Late | Kanal Timur | Malam | 600 | 150 | 18 |
| 15 | Sidat | Late | Kanal Timur | Malam + Hujan | 650 | 160 | 22 |
| 16 | Semah | Late | Kanal Timur | Pagi | 520 | 130 | 25 |
| 17 | Belida | Late | Kanal Timur | Kapan saja | 700 | 170 | 30 |
| 18 | Gurame Raja | Legenda | Kanal Timur | Pagi | 2.200 | 550 | 15 |
| 19 | Belut Emas | Legenda | Kanal Barat | Hujan Deres **atau** Petir ✔ K-07 | 2.000 | 500 | 20 |
| 20 | Ikan Dewa | Legenda | Kanal Timur | Malam | 2.500 | 600 | 30 |

### 6.5 Ikan Legenda — LOCKED

| Aturan | Detail |
|--------|--------|
| Peluang | 0,5% per lemparan bila spot + waktu/cuaca + level cocok. |
| Pity | Per pemain per jenis, naik hanya di kondisi cocok. Lemparan ke-200 dijamin (Firasat −10/lv, min 150). Reset setelah dapat. |
| Per pemain | Tidak ada batas per server. |
| Firasat | Pity ≥ 75% dan Kak Fajar dalam 25 stud: bubble `Airnya lagi tenang banget... firasatku bagus.` + gelembung emas. Tanpa angka pity di UI. |
| Pengumuman | Banner ke server 3 dtk + fanfare. |
| Batasan | Tidak bisa dibiakkan, dimasak, dijual di Warung, atau dihadiahkan. Bisa dipajang di Akuarium atau dijual ke NPC. |

### 6.6 Bubu (Overnight) — ada di kode (R2.1, R2.1b; K-66)

Dijual di Pak Udin (bagian Kebutuhan) dengan harga Koin saja. Pasang di sungai dekat titik mancing, ambil setelah 6 jam (wall clock; tidak bisa instant Bunga).

| Bubu | Harga (Koin, Pak Udin) | Ikan per panen | Rarity ikan (Config/Fish) |
|------|------------------------|----------------|---------------------------|
| Bambu | 400 | 3–4 | C (Early) |
| Kayu | 1.500 | 4–6 | C (Early) dan U (Mid) |
| Besi | 4.000 | 6–8 | U (Mid) dan R (Late) |

- **Pemetaan rarity (satu-satunya tempat):** C = Early, U = Mid, R = Late, L = Legenda. Bubu tidak pernah memberi L.
- **Bahan material ditunda (K-66):** 10 Bambu, 20 Kayu, serta 15 Batu + 10 Kayu tidak dipungut; harga cukup Koin.
- Maks 3 bubu total (semua tipe). Buka Lv 8 lewat M8.
- Besi: panen memilih tiap ikan dengan peluang sama dari semua ikan U dan R (K-67, keputusan owner). Aturan "5% 1 Late" dari tabel lama dihapus dan tidak berlaku.

---

## 7. TERNAK + KOLAM — Pasif

### 7.1 Ternak Darat — LOCKED

Loop: Beli hewan → Isi Tempat Pakan → Produksi (jalan offline) → Ambil → Jual / olah.

- Tidak ada daging. Hewan tidak mati/sakit.
- **Tempat Pakan:** maks 3 jatah per ekor (Tempat Pakan Besar Lv 3: 5). 1 siklus = 1 jatah. Jatah habis = idle lucu. Produk menumpuk maks 3 per ekor.

| Hewan | Lv | Harga | Maks (Kandang Lv1/Lv2) | Pakan/jatah | Produk | Cooldown | Jual | XP |
|-------|----|-------|------------------------|-------------|--------|----------|------|----|
| Ayam | 5 | 300 | 6 / 10 | 15 | Telur Ayam | 15 mnt | 40 | 10 |
| Bebek | 10 | 600 | 5 / 8 | 20 | Telur Bebek | 20 mnt | 55 | 13 |
| Sapi | 22 | 3.500 | 2 / 4 | 30 | Susu | 30 mnt | 160 | 28 |

| Kandang | Bangun | Upgrade ke Lv 2 |
|---------|--------|-----------------|
| Ayam (12×12) | 800 Koin + 15 Kayu | 3.000 + 20 Papan |
| Bebek (14×14) | 1.200 + 20 Kayu | 5.000 + 25 Papan + 10 Bata |
| Sapi (18×16) | 4.000 + 30 Kayu + 15 Bata | 10.000 + 30 Bata + 15 Semen |

- M5 memberi Ayam + Kandang Ayam Lv 1 gratis.
- Pakan Jagung: **1 Jagung → 6 jatah** Pakan Ayam (di Dapur) ✔ K-04.
- Mood Hujan: Bab 3.3. Tidak ada kasih minum.
- Tombol `Ambil Semua` & `Isi Pakan Semua` di kandang.

### 7.2 Kolam

| Tier | Lv | Harga | Breeding | Kapasitas stok |
|------|----|-------|----------|----------------|
| Tanah | **4** | 1.000 Koin + 20 Batu | 6 jam | 10 ikan |
| Semen | 15 | 3.000 + 20 Bata + 15 Semen | 5 jam | 20 ikan |
| Keramik | 30 | 6.000 + 30 Bata + 25 Semen | 4 jam | 30 ikan |

- Maks 4 kolam. **Kolam pertama = Kolam Kakek** (M3 / Bundel, Bab 14.6): tier Tanah, breeding 10% lebih cepat, bisa di-upgrade dengan harga normal. Kolam Tanah lain bisa dibeli setelah Kolam Kakek pulih.
- **Stok (kode B-3):** pemain menyetor ikan dari Tas ke kolam (`PondDeposit`) dan mengambilnya (`PondWithdraw`), maks sesuai kapasitas. Mancing di kolam mengambil ikan acak dari stok; ikan kembali ke stok bila lepas/batal.
- **Breeding:** 2 ikan sejenis non-Legenda + Pakan Ikan 20 Koin/siklus → 1 anak (dijual 100% harga Sedang). Instant Bunga: Bab 18.5. Mood Hujan −10% waktu.
- Timer "Ambil Ikan" **dihapus** ✔ K-10. Ikan di kolam hanya dari setoran pemain + anak hasil breeding; breeding memakai 2 ikan sejenis dari stok; mancing di kolam mengambil dari stok.
- Kolam = akuarium jalan, ikan terlihat oleh tamu.

---

## 8. NAMBANG + CRAFTING + HIAS

### 8.1 Nambang

- Hutan Nambang (Lv 4, M2). Node: Pohon (Kayu), Rumpun Bambu (Bambu), Batu Kali (Batu), Tebing Tanah (Tanah Liat), Pinggir Kali (Pasir), Pohon Aren (Ijuk, Lv 15).
- Node per pemain, respawn **4 menit**. 1 node = 4 pukulan.
- **Ritme Pukul:** lingkaran mengecil; pencet tepat di tanda = **Critical** (+2 bahan, suara crunchy, partikel besar); asal pencet = +1 bahan.
- 1 putaran (±5 menit) ≈ 30–45 bahan. Bonus per node: Bab 4.5.4.
- XP: ✔ K-08 (lihat Bab 4.2).

### 8.2 Bahan & Meja Crafting

| Mentah (7) | Olahan (craft gratis, instan, tombol ×1 / ×10) |
|------------|-----------------------------------------------|
| Kayu, Bambu, Batu, Tanah Liat, Pasir, Jerami, Ijuk | Papan (2 Kayu), Bata (2 Tanah Liat), Semen (2 Pasir + 1 Batu), Anyaman (3 Bambu), Atap Ijuk (3 Ijuk), Genteng (3 Tanah Liat), Kaca (3 Pasir, Lv 25) |

Tombol Craft muncul hanya ≤ 10 stud dari objek Workspace bernama **"Meja Crafting"** (wajib ada di Studio) dan setelah M2.

### 8.3 Hias — Loop

Kumpul bahan → Menu Hias → pilih piece → Warna (12) + Material (Kayu, Bambu, Batu, Cat) → ghost (hijau = bisa, merah muda = nabrak) → pasang (bahan terpotong) → putar / copy / undo 10 langkah.

- Katalog rilis **80 piece**: Struktur 25, Atap 10, Furniture 25, Dekor 20 (daftar usulan di `04_Asset_Bible.md` Bab 4.8). +±20 per update.
- Cap **800 piece per lahan**. Penuh → toast `Lahan sudah penuh hiasan`.
- Hanya di lahan sendiri; tidak saat memancing; tembus dinding sendiri saat mode Hias.
- Validasi lembut: tanpa pintu → toast `Belum ada pintu nih` 1x, tetap boleh.
- Hapus = refund 100%, bahan terbang ke Tas.
- **Warna dinding (K-61):** pemilih warna = R3.9 (lihat Roadmap). Belum dibuat. Palet "Dinding Spesial" = warna ke-13, dibuka title (✔ K-50).


### 8.4 Dekor Berkah — LOCKED

30 dari 80 piece = Dekor Berkah (ikon daun di katalog), 1 stat per jenis, duplikat tidak menumpuk. Contoh: `+3% Koin Nanem`, `+3% XP Mancing`, `+3% Bahan Nambang`, `+5% peluang Bagus`, `-3% Cooldown Ternak`. Dekor Bunga = Dekor Berkah 2 stat.

### 8.5 Set Dekor

| Set | Isi | Bonus lengkap |
|-----|-----|---------------|
| Kampung | Pagar Bambu, Bale-bale, Sumur Tua (hasil Bundel), Lampu Minyak, Lampion Bambu | +5% Koin Nanem |
| Sungai | Dermaga Kayu, Jembatan Bambu, Lampu Sungai, Perahu Mini, Bendera Kampung | +5% Koin Mancing |
| Kandang | Gerobak Jerami, Kincir Kecil, Papan Nama Kandang, Ember Seng, Lumbung Mini (dekor kecil, bukan Bundel Lumbung) | +5% Koin Ternak |
| Joglo (Lv 50) | Atap Joglo, Saka Guru, Lantai Tegel, Gebyok, + 1 Dekor Bunga bebas | +5% XP semua |

Panel Stats menampilkan `Set Kampung 3/5`.

### 8.6 Pajangan — ⚠ belum ada di kode (R2.7)

| Pajangan | Lv | Fungsi |
|----------|----|--------|
| Akuarium | 25 | Pajang 8 ikan (termasuk Legenda & Jumbo) |
| Bingkai Album | 15 | Tampilkan % Album di dinding |

### 8.7 Blueprint, Visit, Like, Galeri

- **Blueprint** (⚠ belum ada di kode, R2.6): simpan desain (3 slot gratis, slot ekstra pakai Bunga), bagikan ke pemain lain. Penerima tetap pakai bahan sendiri; ghost muncul dan bisa dipasang per bagian. **Bukan gating.** Cara berbagi: ✔ K-39.
- **Visit:** jalan, duduk, foto. Tidak bisa bangun/hapus/ambil.
- **Like:** `👍 Bagus!` 1x per lahan selamanya. Pemberi +20 Koin (maks 10 like berhadiah/hari). Masuk hitungan mingguan.
- **Galeri Kampung:** papan di alun-alun, 5 lahan dengan like mingguan terbanyak (global). Pencet = teleport ke server pemilik bila online. **Pemilik offline: tidak bisa dikunjungi** (tanpa toast, tanpa snapshot).
- **Lomba Hias Bulanan:** tema, juara dari like + kurasi tim. Hadiah Bunga + dekor eksklusif + title.

---

## 9. DAPUR & OLAHAN

- Inti Dapur (Tungku + Meja Olah) dicraft, ditaruh bebas di lahan (auto-place 2×2). Bangunan sekitarnya murni Hias.
- Olahan jalan walau offline. Tidak bisa gosong. **Tanpa antrean.**
- Dapur dibuka lewat Tombol Aksi dekat Tungku (✔ K-34).

| Tier | Lv | Craft Inti | Slot | Waktu olah |
|------|----|------------|------|------------|
| 1 Tungku | 6 | 10 Kayu + 8 Batu + 5 Tanah Liat | 1 | 100% |
| 2 Kampung | 15 | 15 Papan + 10 Bata | 2 | 85% |
| 3 Lengkap | 35 | 20 Papan + 15 Bata + 10 Semen | 3 | 70% |

Upgrade: craft Inti baru, yang lama refund 100%, olahan berjalan tidak hilang.

### 9.1 Kualitas Olahan — LOCKED

- Kualitas olahan = kualitas bahan tertinggi (ada 1 Prima → Prima; ada 1 Bagus → Bagus; selain itu Biasa).
- Harga = base × (1,0 / 1,1 / 1,25).
- Aturan harga: olahan ≈ 1,5–1,8× nilai bahan mentah. Resep bercabang: nilai olahan bahan + 1,6× nilai mentah tambahan.
- ✔ K-05 **Kualitas bahan tanpa kualitas:** Ikan: Kecil/Sedang = Biasa, Besar = Bagus, Jumbo = Prima. Telur & Susu: Bagus bila diambil saat Mood Hujan, selain itu Biasa. Garam & Daun Pisang netral. Rasa Prima = peluang naik 1 tingkat (+1%/lv), satu-satunya roll di Dapur.

### 9.2 Resep (24) — LOCKED

Bahan dari 18 tanaman, 17 ikan non-Legenda (kategori Early / Mid / Late), Telur Ayam, Telur Bebek, Susu, Garam (Pak Udin, 10 Koin), Daun Pisang.

✔ K-02 (bahan terbuka sebelum/bersamaan dengan resepnya) · ✔ K-03 (9 harga resep disetel ke ±1,6× bahan; kode saat ini masih angka lama → R1.1).

**Tier 1 — Lv 6**

| Resep | Bahan | Waktu | Jual | XP | Buff |
|-------|-------|-------|------|----|------|
| Pakan Jagung | 1 Jagung | 3 mnt | (6 jatah pakan Ayam) | 20 | — |
| Tumis Kangkung | 5 Kangkung + 1 Garam | 5 mnt | 220 | 40 | Tani |
| Tumis Bayam | 5 Bayam + 1 Garam | 5 mnt | 280 | 45 | Tani |
| Sambal Tomat | 4 Tomat + 2 Cabai | 6 mnt | 630 | 60 | Tani |
| Sup Ubi | 3 Ubi Jalar + 1 Jahe | 7 mnt | 400 | 55 | Tani |
| Jus Jagung | 3 Jagung + 1 Tebu | 8 mnt | 780 | 70 | Tukang |
| Keripik Singkong | 4 Singkong + 1 Garam | 8 mnt | 620 | 65 | Tukang |
| Ikan Early Goreng | 3 Ikan Early + 1 Garam | 6 mnt | 1,6× bahan (Wader 110, Lele 230) | 50 | Pancing |

**Tier 2 — Lv 15**

| Resep | Bahan | Waktu | Jual | XP | Buff |
|-------|-------|-------|------|----|------|
| Telur Asin | 4 Telur Bebek + 1 Garam | 20 mnt | 350 | 90 | Tebang |
| Selai Stroberi | 4 Stroberi + 2 Tebu | 30 mnt | 3.200 | 300 | Tukang |
| Pepes Ikan Mid | 2 Ikan Mid + 1 Jahe + 1 Daun Pisang | 25 mnt | 1,6× bahan (Nila 510) | 110 | Pancing |
| Nasi Goreng Spesial | 1 Sambal Tomat + 3 Padi + 1 Telur Ayam | 25 mnt | 2.600 | 200 | Tani |
| Es Tebu | 3 Tebu + 1 Melati | 20 mnt | 980 | 100 | Tukang |
| Gulai Telur | 3 Telur Ayam + 2 Cabai + 1 Jahe | 24 mnt | 820 | 115 | Tukang |
| Salad Sawi | 4 Sawi + 2 Tomat + 1 Garam | 20 mnt | 640 | 95 | Tani |
| Kue Pisang | 3 Pisang + 2 Tebu + 1 Telur Ayam | 30 mnt | 3.100 | 350 | Tukang |

**Tier 3 — Lv 35**

| Resep | Bahan | Waktu | Jual | XP | Buff |
|-------|-------|-------|------|----|------|
| Kopi Tubruk | 4 Kopi + 1 Tebu | 40 mnt | 4.400 | 380 | Tebang |
| Teh Melati | 3 Teh + 2 Melati | 45 mnt | 4.500 | 390 | Tebang |
| Es Krim Durian | 2 Durian + 3 Susu + 1 Tebu | 60 mnt | 5.200 | 520 | Tukang |
| Durian Goreng | 2 Durian + 1 Tebu + 1 Garam | 50 mnt | 4.400 | 500 | Tukang |
| Kopi Susu Gula Aren | 1 Kopi Tubruk + 2 Susu + 1 Tebu | 50 mnt | 5.200 | 480 | Tebang |
| Nasi Padang Mini | 1 Sambal Tomat + 1 Telur Asin + 3 Padi | 55 mnt | 2.900 | 220 | Tani |
| Ikan Late Bakar | 2 Ikan Late + 1 Cabai + 1 Jahe | 45 mnt | 1,6× bahan (Toman 1.770) | 250 | Pancing |
| Salad Buah | 2 Mangga + 2 Pisang + 2 Stroberi | 45 mnt | 6.500 | 450 | Tani |

### 9.3 Warung Pemain

- Buka **Lv 7** (M7). Bangunan di lahan sendiri, auto-place 2×2, **1 slot pajang** (1 jenis olahan + tumpukannya). Biaya bangun: Claude Code salin dari kode (Audit A-58).
- Pengunjung NPC datang tiap 5–10 menit, beli 1 olahan. Harga = base × kualitas. Tanpa Reputasi.
- Offline: maks 5 penjualan per login.
- Hanya olahan. Bukan pasar antar pemain.

### 9.4 Buff Olahan — LOCKED

- Olahan dijual **atau** dimakan. Maks 1 buff aktif; makan baru = ganti.
- Durasi: Biasa 10 / Bagus 12 / Prima 15 menit, real-time.
- Hanya kegiatan **aktif**. Tidak ada buff untuk ternak, kolam, dapur, bubu, warung, dekor.
- Pakan Jagung tidak memberi buff.

| Buff | Resep | Efek |
|------|-------|------|
| Tani | Tumis Kangkung, Tumis Bayam, Sambal Tomat, Sup Ubi, Salad Sawi, Nasi Goreng Spesial, Nasi Padang Mini, Salad Buah | +10% absolut ke peluang Bagus (tetap kena cap 50%) |
| Pancing | Ikan Early Goreng, Pepes Ikan Mid, Ikan Late Bakar | Gigitan 20% lebih cepat + kotak tarik +10% |
| Tukang | Jus Jagung, Keripik Singkong, Gulai Telur, Kue Pisang, Selai Stroberi, Es Tebu, Es Krim Durian, Durian Goreng | Jendela Critical +25% + 1 bahan saat Critical (Batu, Tanah Liat, Pasir, Bambu, Ijuk) |
| Tebang | Kopi Tubruk, Teh Melati, Kopi Susu Gula Aren, Telur Asin | Jendela Critical +25% + 1 Kayu saat Critical (Pohon saja) |

Buff aktif tampil sebagai chip berikon + timer dekat kartu pemain.

---

## 10. NPC & SISTEM JUAL

### 10.1 NPC — LOCKED

| NPC | Peran | Lokasi |
|-----|-------|--------|
| Pak Udin | Warung utama: jual bibit, pakan, hewan, garam, alat. Beli tanaman & produk ternak 100%. | Alun-alun |
| Kak Fajar | Joran & umpan, beli ikan 100%. Versi tutorial = salinan klien di Sungai Lahan pemain. | Lapak pinggir kanal alun-alun |
| Pak Amran | Tukang kayu: rangka rumah pertama (S4), alat Tukang, Blueprint (bukan gating). | Alun-alun |
| Mak Sari | Narator tutorial, beli olahan 100%. | Alun-alun |
| Nek Ani | Pos Ronda, Kerja Bakti, info tanda hujan. | Alun-alun |
| Bang Jali (×8) | Satu di depan tiap lahan, membelakangi warung mini. Beli semua barang yang punya harga 90%, tidak menjual. Jual dibuka S3. | Depan lahan |
| Pedagang Tamu | Rotasi 6 NPC malam (pak_kumis, nek_esih, bang_dodo, mpok_riah, kang_asep, yu_tum). Beli 1 jenis barang acak +50%, maks 10 per pemain per malam. | Alun-alun |
| Tamu Event | Pesanan Tamu event musiman. | Alun-alun |

Nama lama dilarang: Bu Wati, Mbak Arsi, Bang Tarno, Pak RT, Bu Sari, Mbah Karto, Mas Yudi, Dik Rara.

Aturan dialog: bicara dengan NPC, bubble, dan NPC menoleh = **sisi klien, hanya untuk pemain itu**. Hadiah & ekonomi selalu di server. Sapaan pertemuan pertama (`npc.<id>.meet`) hanya sekali per NPC (`guide.hasMet`).

### 10.2 Sistem Jual — LOCKED

| Penjual | Beli | Harga | Kuota |
|---------|------|-------|-------|
| Pak Udin | Tanaman, telur, susu (Audit A-83) | 100% | — |
| Kak Fajar | Ikan | 100% | — |
| Mak Sari | Olahan | 100% | — |
| Bang Jali | Semua yang punya harga | 90% | — |
| Warung Pemain | Olahan ke NPC | base × kualitas | 5 offline/login |
| Pedagang Tamu | 1 jenis acak | +50% | 10/malam |

Pasar Harian & Kualitas dikalikan di semua penjual.
- **Jual Semua (K-63):** hilang bersama pindahnya penjualan Pasar ke bubble lapak (E2).


### 10.3 Sumber Item — LOCKED

| Item | Sumber |
|------|--------|
| Bibit | Pak Udin; Bibit Varian dari Gerobak Kaget |
| Garam | Pak Udin, 10 Koin (sink) |
| Daun Pisang / Jerami | Bonus 2 per panen Pisang / Padi |
| Pakan | Pak Udin (Ayam 15, Bebek 20, Sapi 30, Ikan 20 per jatah) + Pakan Jagung |
| Umpan | Kak Fajar |
| Hewan | Pak Udin |
| Alat | Pak Udin, Pak Amran, Kak Fajar (Bab 17.5) |
| Bahan mentah | Hutan Nambang |
| Bahan olahan | Meja Crafting |
| Telur, Susu | Ternak |
| Ikan | Mancing, Bubu, Kolam |
| Olahan | Dapur |

---

## 11. ALBUM KAMPUNG (GUI)

Album = GUI kartu, dibuka dari HUD. Bukan item, bukan bangunan.

| Tab | Isi | Entri | Masuk total 214? |
|-----|-----|-------|------------------|
| Ladang | 18 tanaman × 3 kualitas | 54 | Ya |
| Sungai | 20 ikan × 4 ukuran | 80 | Ya ✔ K-06: tangkapan Legenda berikutnya selalu ukuran yang belum dimiliki (4 tangkapan = lengkap) |
| Dapur | 24 resep × 3 kualitas | 72 | Ya ✔ K-05 |
| Varian | 6 Bibit Varian + 2 Hewan Varian | 8 | Ya |
| Kandang | 3 hewan + 2 varian | 5 | Tidak (Pencapaian) |
| Rumah | piece pernah dipasang (kode: 33 entri, ✔ K-52; target konten 80 = R4.8) | 33 | Tidak (Pencapaian, title Juragan Pondok) |
| **Total GUI utama** | | **214** | |

- Entri baru: kartu kecil `ALBUM +1` 1 detik.
- Milestone (USULAN): 25% → 10 Bunga; 50% → 20 Bunga + Title Kolektor; 75% → 30 Bunga + Dekor Bingkai Emas; 100% → 50 Bunga + Title Legenda Kampung. Tiap milestone juga 1 Peti Bunga.
- Kartu Album: tombol `Bagikan` membuat gambar (nama, %, 3 entri terlangka).

---
- **Album dekor (K-59):** hanya entri yang sudah dibangun dihitung; piece yang belum ada disembunyikan. Isi 80 piece = R4.8.


## 12. SOSIAL

### 12.1 Prinsip

Sosial memberi, tidak pernah mengambil. Tidak ada pencurian, rebutan, transaksi antar pemain.

### 12.2 Bantu Tetangga (buka Lv 5, S6) — DISEMBUNYIKAN (K-73: `Config/Features.BANTU_ENABLED = false`)

Selama disembunyikan: tidak ada tombol, baris, atau remote Bantu; S6 dan Ringan Tangan tidak ditawarkan; Surat yang minta Bantu dibayar langsung. Kode tetap ada.

| Aturan | Detail |
|--------|--------|
| Batas | Per lahan per hari: 1 Siram + 1 Panen. Per pemain per hari: maks 5 lahan (+ Tetangga Baik). Reset 05:00 WIB. |
| Yang dibantu | Siram: tanaman jadi Basah. Panen: hasil masuk Tas pemilik + 1 bibit sejenis bonus untuk pemilik. Kualitas milik pemilik. |
| Pembantu | +40 Koin +10 XP per bantu. |
| Solo | **Dibatalkan (K-73).** Kebun Warga tidak dibangun. K-17 diganti K-73. |

### 12.3 Kirim Hadiah (Lv 20)

3 hadiah/hari, barang bernilai maks 500 Koin. Tidak bisa Legenda, Bunga, Robux. Pengirim +20 Koin +5 XP per hadiah.

### 12.4 Gestur

Lambai, Jempol, Tepuk Tangan, Ketawa. Cooldown 3 dtk. Tanpa hadiah. Tidak ada hug / joget / tunjuk. Chat `/e` diblok.

### 12.5 Chat

Per server, filter Roblox, tanpa DM, tidak bisa kirim link / kode / gambar.

### 12.6 RW — hanya cerita

RW bukan sistem; hanya muncul di dialog NPC.

---

## 13. EVENT BERULANG

### 13.1 Gerobak Kaget (buka M1)

- Restock tiap 15 menit, 3 slot: Bibit Varian (60%), Dekor / Bahan (35%), Hewan Varian / Dekor Langka (5%).
- Maks 3 beli per slot per restock, stok per pemain.
- Toast 1x saat ada Varian (bisa dimatikan).
- Bibit Varian (6): Jagung Ungu, Tomat Kuning, Semangka Kotak (tanaman baru, Late 3 jam), Cabai Pelangi, Stroberi Putih, Pisang Merah. Jual +50%, harga beli 2× (USULAN).
- Hewan Varian (2): Ayam Cemani, Bebek Belang (kosmetik + Album).

### 13.2 Pasar Malam (tiap Malam game, 9 menit)

Pedagang Tamu datang (Bab 10.1). Lempar Gelang: 3x gratis per malam, hadiah Koin kecil / bahan / tiket dekor (angka Gelang 60/30/10 di Config = USULAN, R0.4 menulis artinya di sini). Bukan pasar antar pemain.
- **Event tampil (K-57):** sebagai "Event" hanya saat event aktif. Pasar Malam adalah tempat di dunia dengan NPC Pak Kumis.


### 13.3 Event Musiman

Agustusan (10–24 Agu), Lebaran (ikut kalender), Tahun Baru (28 Des – 7 Jan), Hari Tani (20–30 Sep), Festival Panen. Hiasan alun-alun otomatis dari Config. Progres 100% pribadi. Pesanan Tamu: 3–5 barang → Koin + Bunga + dekor event. Event selesai (✔ K-19) = **semua Pesanan Tamu event itu sudah disetor** → 1 Peti Bunga, sekali per event per tahun.

### 13.4 Kerja Bakti Kilat — LOCKED

| Aturan | Detail |
|--------|--------|
| Pemicu | Setelah Hujan Deres / Petir. Prompt pungut terbuka setelah M1 (gerbang Gerobak). |
| Ketergantungan (K-79) | Pemain tidak bisa memicunya sendiri. Kerja Bakti mulai hanya saat hujan Deres atau Petir **berakhir** (`WorldService.RainEnded`). Tidak ada jadwal dan tidak ada tombol. Peluang per hujan: Deres 30%, Petir 15% (`Config/Weather` RAIN_ROLL). Quest Lv 1 Pekerja Bakti (side_kerjabakti) karena itu bisa menunggu cuaca. |
| Sampah | 10 + 6 × pemain di server (maks 58). |
| Hadiah | 15 Koin + 3 XP per poin, maks 20 poin per Kerja Bakti, maks 4 Kerja Bakti berhadiah per hari. |
| Bonus 100% | Semua dengan ≥ 1 poin: +150 Koin + Diskon Warga −10% (bibit & pakan di Pak Udin dan Kak Fajar, ✔ K-41) selama 30 menit nyata. |
| Solo | 1 pemain bisa 100%. |

---
- **Lempar Gelang (K-57):** memakai minigame (zona 60/30/10%). Tidak diubah oleh K-57 selain ini.


## 14. QUEST

Rantai Main / Side Quest (dulu Bab 14.2 & 14.4), feature gate, dan naskah ada di **`03_Quest_Naskah.md`** (satu-satunya sumber). Bab ini hanya sistem lain; nomor 14.2 dan 14.4 sengaja kosong.

### 14.1 Jenis

| Jenis | Ringkas |
|-------|---------|
| Main Quest | Membuka gameplay baru atau milestone cerita. Banner Dimulai/Selesai. Maks 1 aktif. |
| Side Quest | Lanjutan gameplay yang sudah terbuka. Tanpa banner. |
| Surat Kakek | 30 surat, 1 per hari login, kumulatif. |
| Agenda Harian | 3–5 tugas/hari, sesuai fitur yang terbuka (K-80). |
| Order Villager | Daily 3 + Weekly 1. |
| Quest Harian / Mingguan | 3 + 3 (USULAN, P2-7). |
| Bundel Kakek | 5 proyek pemulihan. |

Semua quest baru muncul setelah tutorial jual ikan (`t1b_kolam`) selesai.
- **Harian dan Mingguan (K-56):** hanya memilih templat yang fitur dan levelnya sudah terbuka. "Bantu lahan" pindah ke Season (500 Koin, tanpa Bunga, K-28). Quest yang sistemnya belum ada diblok.


### 14.3 Surat Kakek

30 surat, kumulatif (tidak reset). Isi: cerita + 1 tugas kecil + hadiah Koin/Bunga/bahan. Surat #1: `Nak, kalau hujan, jangan lari. Siram tanamanmu, biar Prima. — Kakek` Teks surat #2–#30 belum ditulis (Roadmap R8.3).
K-77: surat 6, 13, 20, 29 meminta Bantu. Selama Bantu disembunyikan, hadiahnya dibayar saat jatuh tempo, dengan toast "Surat Kakek #n: <teks alt, tanpa kata Bantu> Hadiah +X Koin" (K-83). Toast ini tampil walau fitur Surat belum terbuka. Teks asli dipakai saat flag hidup.

### 14.5 Agenda Harian — ada di kode (R2.2: tombol HUD "Papan", AgendaController)

Reset 05:00 WIB. Hadiah: Panen 200 / Pancing 250 / Masak 300 / Bantu 150 / Nambang 400 Koin (USULAN); Tanam 150 (K-73). Tanpa XP, tanpa Bunga. Hadiah otomatis saat tugas selesai.

**K-80 (jumlah tugas):** tugas yang muncul = tugas yang level dan fiturnya sudah terbuka, jadi **3–5 per hari**, bukan 5 sejak awal. Lv 1–3: Panen, Mancing, Tanam (3). Lv 4–5 (Hutan terbuka): + Nambang (4). Lv 6+ (Dapur terbuka): + Masak (5). Bantu menambah satu tugas saat flag hidup (K-73). Aturannya ada di `Config/Quests` (DAILY, `requires`).

K-73: selama Bantu disembunyikan, slot Bantu diganti **Tanam 5** (150 Koin + 25 XP, event `plant`). Dengan Tanam, pool Lv 6+ tetap 5 tugas.

### 14.6 Bundel Kakek

Kerangka kosong muncul di level bukanya. Setor bahan → bangunan pulih.

| Bundel | Lv | Ukuran | Setoran | Hadiah |
|--------|----|--------|---------|--------|
| Kolam Kakek | 4 (M3) | 6×6 | 10 Batu + 5 Kayu + 3 ikan Early | Kolam Tanah, breeding 10% lebih cepat |
| Sumur Tua | 8 (M9) | 4×4 | 10 Kayu + 5 Batu + 2 Olahan | Menyiram 1 petak otomatis per hari |
| Lumbung | 15 | 6×6 | 20 Papan + 10 Bata + 1 hasil Prima | Penyimpanan visual |
| Saung Kakek | 20 | 6×6 | 15 Anyaman + 10 Atap Ijuk + 3 olahan berbeda | Duduk 5 dtk → Istirahat Sejenak +5% XP 10 menit (⚠ belum di kode) |
| Empang & Dermaga Kakek | 30 | 10×10 | 30 Papan + 10 Semen + 10 ikan Mid + 1 ikan Jumbo | Spot mancing pribadi |

Bunga per bangunan pulih: **10 Bunga** ✔ K-31; menggantikan "5 Bunga" di M9 (tidak dobel).

### 14.7 Order Villager — LOCKED

- Permintaan NPC setor barang spesifik (contoh `Bawakan 5 Kangkung Bagus ke Pak Udin`). Beda dari Agenda.
- Daily 3 + Weekly 1, reset 05:00 WIB. Pemberi: Pak Udin, Kak Fajar, Pak Amran, Mak Sari, Nek Ani.
- Mingguan (v8.4, K-60): 4 jenis barang, jumlah ×3, hadiah ×3, XP ×0,5 (`Config/Orders`: WEEKLY_TYPES, WEEKLY_COUNT_MULT, WEEKLY_REWARD_MULT, WEEKLY_XP_MULT).
- Hadiah = nilai jual × 1,5 (Daily) / × 3 (Weekly), Koin + XP saja.
- Reroll 2 Bunga, maks 1x per order per hari, tier sama.
- Tidak selesai = hilang saat reset, tanpa hukuman.
- Dibuka: sama dengan Agenda (M1). Diblok selama tutorial.

---

## 15. HADIAH & PROGRESI

### 15.1 Login Mingguan — LOCKED

7 hari login per minggu, kumulatif (bolong tidak reset). **Diulang tiap minggu** (Senin 05:00 WIB). Hari 1: 100 Koin, 2: 150, 3: 200, 4: 2 Bunga, 5: 300, 6: 3 Bunga, 7: 500 Koin + 5 Bunga.

### 15.2 Hadiah Waktu Bermain — LOCKED

10 mnt 50 Koin, 20 mnt 100, 30 mnt 150, 45 mnt 200, 60 mnt 300. Setelah 60 menit tidak ada hadiah. Hanya Koin.

### 15.3 Peti Bunga

- 1 peti = **25 Bunga**.
- Sumber yang sudah di kode: tiap Title (sekali), tiap milestone Album (sekali), Season F2P hari 30 (sekali per season).
- Belum di kode: Event (✔ K-19), Pencapaian, Bundel, Robux.

### 15.4 Title

Dari pencapaian permanen, bukan dibeli. Tanpa stat (kecuali tercantum di 17.6). Tiap title = 1 Peti Bunga, kecuali title yang bergantung pemain lain (✔ K-28).

| Title | Syarat |
|-------|--------|
| Kolektor | Album 50% + klaim milestone `p50` |
| Legenda Kampung | Album 100% + klaim `p100` |
| Warga Kampoeng Tedoeh | MQ12 `mq12_warga` |
| Penakluk Legenda | MQ11 `mq11_legenda` (syarat ATAU ✔ K-13) |
| Dinding Spesial | `side_rumah_rapi` (20 piece) |
| Raja Jumbo | `side_jumbo` (1 ikan Jumbo) |
| Pekerja Bakti | `side_kerjabakti` (10 Kerja Bakti), mulai Lv 2 (K-81) |
| Juragan Pondok | Kategori Album Rumah lengkap + klaim |
| Kebun Favorit | 200 like; **tanpa Peti Bunga** ✔ K-28 |
| Penyayang Kucing | Side Kucing Alun-alun — **Update 1** (✔ K-16 b; tidak ada di rilis) |

---

## 16. TUTORIAL (FTUE) — LOCKED

### 16.1 Aturan

- State machine berbasis kondisi. **Tidak bisa di-skip** (tidak ada tombol Lewati di mana pun).
- Tutorial = dua bagian di kode: `t1_awal` (kebun + jual ke Pak Udin) dan `t1b_kolam` (Kak Fajar + mancing + jual ikan). **Berakhir di jual ikan ke Kak Fajar.**
- **Siram wajib** di tutorial (langkah siram hanya selesai dari menyiram). Di luar tutorial siram opsional.
- Tidak ada Kolam di tutorial (tidak ada langkah, coachmark, prompt, atau tombol Kolam).
- Naskah semua baris: `03_Quest_Naskah.md` Bab 4.

### 16.2 Langkah (sesuai `Config/Onboarding.luau`, B1/B2 K-54)

Dua tutorial: `t1_awal` (langkah 1–9) dan `t1b_kolam` (langkah 10–13). Id langkah = id di kode.

| # | Langkah (id) | Tempat | Selesai saat | Hadiah XP (kode) | Permukaan instruksi (aturan GUI 4.6) |
|---|--------------|--------|--------------|------------------|--------------------------------------|
| 1 | `sapa` | Lahan | Tombol Mulai (modal) | — | Modal sapaan (tanpa coachmark) |
| 2 | `cangkul` | Lahan | Petak dibuat / tanam / panen | 1 | Pertama: bubble coachmark + ring Garap |
| 3 | `tanam` | Lahan | Tanam 1 | 1 | Pertama: bubble coachmark + ring Tanam |
| 4 | `siram` | Lahan | Siram 1 (wajib, bukan panen) | 1 | Pertama: bubble coachmark + ring Siram |
| 5 | `panen_1` | Lahan | Panen 1 | — | Pertama: bubble coachmark + ring Panen |
| 6 | `garap_5` | Lahan | 6 petak total (1 lama + `MS_EXTRA_BEDS` = 5 baru). Bubble Mak Sari tahap 1 (sekali), lalu toast tersemat | — | Bubble Mak Sari tahap 1, lalu toast tersemat (ring Garap kuning, tanpa gelap) |
| 6b | `tanam_5` | Lahan | Tanam `MS_FREE_SEEDS` (6) bibit gratis lagi | — | Bubble Mak Sari tahap 2 (sekali), lalu toast tersemat |
| 8b | `tunggu_semua` | Lahan | Saat ada petak siap panen | — | Bubble Mak Sari tahap 3 (sekali) |
| 7 | `tanam_5` | Lahan | Tanam 5 lagi (bibit gratis di tas) | — | Pengulangan: toast saja |
| 8 | `tunggu_semua` | Lahan | Panen 6 bibit gratis (semua) | — | Toast saja (tanpa gelap) |
| 9 | `panen_jual` | Lahan → Pak Udin | Jual 1 ke Pak Udin | 20 | Toast saja |
| 10 | `warung` | Pak Udin | Ok (ack) | — | Dialog Pak Udin |
| 11 | `kak_fajar` | Sungai Lahan | Terima Hadiah (`rodgift`): Joran Bambu + Pelet x5 (kode, `TutorialService.FAJAR_BAIT`; K-21 menulis Cacing, lihat K-86) | — | Panah NPC + toast |
| 12 | `mancing` | Sungai Lahan | 3 ikan (B2 K-54) | 20 | Pertama: bubble coachmark + ring Aksi (Pancing); selama langkah: toast tersemat "Tangkap 3 ikan buat Kak Fajar: n/3" (K-85), tidak hilang sampai langkah selesai |
| 13 | `jual_ikan` | Sungai Lahan | Ok setelah jual ikan ke Kak Fajar | sampai Lv 2 (xpFill) | Dialog Kak Fajar |

- **XP tutorial:** reward eksplisit = 1 + 1 + 1 + 20 + 20 = **43 XP**. Langkah 13 (`xpFill`) menambal sisa sampai batas Lv 1→2 (230 XP), jadi tutorial selesai **tepat di Lv 2**. Sisa XP dari ikan tangkapan ikut dihitung sebelum langkah 13. Total akhir = 230 XP (bukan 158 seperti versi lama).
- **Perubahan klaim lama:** versi sebelumnya menulis "158 XP" dan "Lv 2 ±3 menit setelah tutorial". Kode sekarang menutup tutorial tepat di Lv 2 lewat `xpFill` (K-54 B2).
- Panjang tutorial: diukur owner 2026-11-24, **2 menit** dari PLAY sampai Lv 2 (perkiraan awal ±3–4 menit).
- Langkah lama (Bayam, Nambang, Hias, Surat #1, Agenda + Gerobak) sekarang quest S1, M2, M4, S2, M1.
- Kolom "Permukaan" dan gaya sorot: aturan dari GUI 4.6 (tabel klasifikasi per langkah: jenis target, spotlight atau outline, pertama kali atau ulang, bisa gerak). Spotlight hanya untuk `cangkul` (tombol Garap) dan `mancing` tangkapan pertama (tombol Aksi Pancing), diterapkan di kode F1a (`Config/Onboarding` `spotlight = true`). Verifikasi per langkah di Play belum dilakukan (lihat kolom Play di GUI 4.6).
- **Tanam cepat (K-71, owner 2026-11-24):** 6 tanam pertama save baru tumbuh 20 detik, tetapi timer **ditahan sampai bed disiram**. Siram pertama memulai timer 20 detik dikurangi 15%. Selama ditahan, pill hanya menampilkan "Siram" dan nama tanaman, tanpa hitung mundur. Langkah `siram` hanya selesai lewat siram, jadi pemain yang lambat tetap bisa menyelesaikannya.
- **Verifikasi owner (2026-11-24):** ke-15 langkah tutorial sudah diuji owner di Play dan centang di checklist (`09_Playtest_Checklist.md` B16).

### 16.3 Blok NPC selama tutorial — LOCKED

- Dari langkah 1 sampai 10, NPC di luar target langkah aktif menjawab satu baris `Selesaikan tutorial dulu` (toko, dialog, quest, order, hadiah, bantu ditolak server).
- Target langkah: Mak Sari (1–5), Pak Udin (6), Kak Fajar (7–10).
- Tanda `!` quest tidak muncul selama tutorial.
- Catatan: prompt NPC masih terlihat; yang diblok interaksinya.

### 16.4 Cutscene Jual Pertama — LOCKED

- Trigger **proximity** (`SALE_BEAT_RADIUS` 10 stud), dicek tiap frame di klien. Pemain dikunci. **Kamera (K-84, 2026-11-24):** shot lebar tetap di dekat pohon beringin, menghadap warung dan Pak Udin (kamera tidak boleh di dalam avatar atau prop; tanpa blur). Pemain berjalan ke titik berdiri (`MoveTo`) dan masuk frame; Pak Udin menoleh; baru bubble. Tanpa skip.
- Jual lewat pilihan **"Jual semua"** di bubble (tanpa GUI Jual). Harga tetap 100% Pak Udin. Ditolak → bubble diulang.
- Setelah jual: baris penutup + baris yang mengarahkan ke Kak Fajar → fade.

### 16.5 Kak Fajar Tutorial (sisi klien)

- Salinan Kak Fajar lokal muncul di spot Sungai Lahan milik pemain (dihitung server, `FishService.AssignedRiverSpot`, atribut `RiverSpot`). Kak Fajar asli disembunyikan untuk pemain itu saja.
- Model diambil dari `ReplicatedStorage.NpcTutorial.kak_fajar` (disalin dari `ServerStorage.NpcModels` saat server mulai).
- Jual ikan tutorial hanya diterima server saat langkah `jual_ikan` dan dalam 25 stud dari spot milik pemain (✔ K-27).
- Cutscene hadiah mulai di frame trigger (target < 0,3 dtk, log `[beat-timing]`).

### 16.6 Sorot tutorial: dua gaya, hanya pertama kali — LOCKED (2026-11-23, batch F1, menggantikan aturan "tanpa gelap" sebelumnya)
- **MS-2 (2026-11-23):** tiga tahap bubble Mak Sari (panen pertama, bibit ulang, panen semua), sekali per save; bubble di atas dock; ring Garap kuning; toast tersemat. Lihat docs/03 Bab 4.2c.
- **MS (2026-11-23):** setelah panen pertama (langkah `panen_1` selesai), Mak Sari meminta 5 petak lagi lewat bubble NPC (Next, sekali per save, `guide.mkSariHarvestSeen`). Bubble ini satu-satunya permukaan instruksi pertama kali untuk `garap_5`; pengingatnya toast. Tidak ada gelap, tidak ada ring, pemain tetap bisa jalan. Lihat docs/03 Bab 4.2b.

Aturan (owner, video PC dan rekaman HP):

1. **Dua gaya sorot, dipilih dari jenis target, hanya untuk pertama kali:**
   - **Tombol HUD tetap** (dock Garap, tombol Aksi Pancing): **spotlight** = satu overlay gelap dengan **satu lubang** di sekeliling tombol, supaya pemain tahu tombol mana yang ditekan. Hanya dua langkah yang memakainya: `cangkul` (Garap) dan `mancing` tangkapan pertama (Aksi).
   - **GUI mengambang atau objek dunia** (pill Tanam / Siram / Panen di atas petak, ghost dan kotak pilihan Garap, NPC, tanah, panah tanah): **tanpa gelap**. Hanya outline kuning yang sudah ada (ring) dan baris instruksi.
2. **Pengulangan** (langkah yang sudah pernah dilakukan sekali, misal `garap_5`, `tanam_5`, `tunggu_semua`, `panen_jual`, mancing tangkapan ke-2 dan ke-3): **toast saja**. Tanpa gelap, tanpa outline, tanpa bubble.
3. Spotlight adalah **satu bidang dengan lubang**, tidak pernah kotak gelap terpisah per elemen GUI. Piece overlay tidak menelan sentuhan, jadi joystick dan area sentuh kamera selalu bebas dan pemain tidak pernah terkunci. Spotlight lepas sendiri saat langkah berganti, saat langkah selesai, atau setelah 25 detik di langkah yang sama (timeout pengaman). Bubble dan outline tetap tampil.
4. **Satu permukaan instruksi per langkah:** pertama kali = bubble coachmark (+ sorot sesuai aturan 1); pengulangan = toast. Tidak pernah keduanya untuk teks yang sama.
5. Tabel klasifikasi per langkah (jenis target, gaya, pertama kali, permukaan, bisa gerak): **GUI 4.6**. Angka XP dan urutan langkah tetap di 16.2.

- Alasan: video owner (2026-11-23) menunjukkan kotak gelap menutupi HUD dan dock saat langkah Garap, dan di HP tahap `tunggu_semua` pemain terkunci karena gelap menutupi joystick. Dengan aturan ini, gelap hanya ada pada dua tombol HUD yang memang harus ditunjuk, dan hanya sekali.
- Cutscene yang menunggu pemain melepas kunci gerak setelah 60 detik (`Cutscene.UNTIMED_RELEASE_SECONDS`) tetap berlaku.
- Riwayat (sudah digantikan): aturan "tanpa gelap sama sekali" (2026-11-23 pagi, setelah HP owner terkunci) dan aturan "gelap hanya pada aksi pertama" (sebelumnya).

---

## 17. EKONOMI

### 17.1 Prinsip

1. Semua angka di Config, bukan hardcode.
2. Penghasilan dihitung bersih.
3. Tidak ada Robux → Koin.

### 17.2 Faucet per Jam (pemain inti, simulasi full-unlock) — perlu dihitung ulang (Super dihapus, R9.1)

| Fase | Nanem | Mancing | Ternak+Kolam+Bubu | Olahan+Warung | Agenda/Sosial/Event | Total |
|------|-------|---------|-------------------|---------------|---------------------|-------|
| Lv 1–20 | 700 | 600 | 150 | 100 | 450 | 2.000 |
| Lv 21–45 | 1.800 | 1.400 | 900 | 1.100 | 800 | 6.000 |
| Lv 46–60 | 3.300 | 2.600 | 2.000 | 3.000 | 1.100 | 12.000 |

Total sampai Lv 60 ≈ 14 × 2.000 + 29 × 6.000 + 20 × 12.000 = **442.000 Koin** (63 jam). Dengan Kualitas (×1,055 Nanem, ×1,05 Olahan) dan Mood Hujan (×1,0345 Ternak) ≈ 455.000. ✔ K-11: target jam di sini tetap acuan; angka ±1.500 XP/jam di Quest doc hanya untuk Lv 1–10. R9.1 menyetel XP per aksi bila simulasi menyimpang.

### 17.3 Porsi Target

Nanem 30% · Mancing 25% · Ternak+Kolam+Bubu 15% · Olahan 15% · Agenda/Sosial/Event 15%. Satu sistem > 40% → turunkan sistem itu.

### 17.4 Sink

| Sink | Koin |
|------|------|
| Petak 7–36 | 96.750 |
| Chunk (14) | 88.790 |
| Joran | 66.400 |
| Alat Bertani | 15.800 |
| Alat Tukang | 13.000 |
| Kandang + upgrade | 24.000 |
| Hewan (10 Ayam + 8 Bebek + 4 Sapi) | 21.800 |
| Kolam (3 Tanah baru + 4 Semen + 4 Keramik) | 39.000 |
| Bubu (3 sampai Besi) | 17.700 |
| Skill semua maks | 240.000 |
| **Total** | **623.240** |

Sampai Lv 60 skill paling banyak menyerap 177.000 → sink efektif ≈ **560.000**. Rasio 442.000 / 560.000 ≈ **79%** (≈ 81% dengan Kualitas + Mood Hujan) — mepet batas 80%. Sink kecil berulang (Garam, pakan, Gerobak, Warung) tidak dihitung.

### 17.5 Alat Koin — LOCKED ("Lv N" = Player Lv)

| Alat | Harga | Lv | Efek |
|------|-------|----|------|
| Gembor Plastik | Gratis | — | Siram 1 petak |
| Gembor Seng | 2.000 + 10 Kayu | 3 | Siram 2 petak (garis) |
| Gembor Kuningan | 8.000 + 20 Papan | 8 | Siram 3 petak |
| Sabit Kayu | Gratis | — | Panen 1 petak |
| Sabit Besi | 5.000 + 10 Batu | 5 | Panen 3 petak |
| Sepatu Bot | 800 + 5 Ijuk | 2 | Jalan +5% di lahan sendiri |
| Kapak Batu | Gratis | — | Normal |
| Kapak Besi | 3.000 + 15 Batu | 3 | +1 bahan/node |
| Kapak Baja | 10.000 + 20 Batu + 10 Semen | 7 | +2 bahan/node |

Catatan (Audit A-82): syarat level di atas bisa lebih rendah dari ketersediaan bahannya. Kayu/Bambu/Batu baru ada di Lv 4 (Hutan), Ijuk di Lv 15. Jadi Joran Kayu, Gembor Seng, Kapak Besi praktis Lv 4; Sepatu Bot dan Joran Pusaka praktis Lv 15. Toko menampilkan bahan yang kurang.

### 17.6 Cap Bonus — LOCKED

Dekor Berkah + Dekor Bunga + Set + Title dijumlah per jenis stat, maks **+25%**. Skill di luar cap (maks +10%). Panel Stats: `Koin Nanem +25% (MAX)` warna emas.

### 17.7 Harga Lain

Pasar Harian +30%. Kualitas Bagus +10%, Prima +25%. Contoh: Durian Prima = 1.625 Koin.

### 17.8 Validasi (wajib saat playtest)

| Cek | Target | Kalau meleset |
|-----|--------|---------------|
| Jam ke Lv 60 (inti) | 55–70 jam | Ubah XP aksi, bukan rumus level |
| % sink selesai di Lv 60 | 65–80% | Ubah harga skill dulu |
| Porsi Koin 1 sistem | ≤ 40% | Turunkan sistem dominan |
| Median saldo Lv 60 | ≤ 50.000 | Tambah sink kosmetik |
| Prima per pemain per minggu | Dari peluang Bab 5.4 | Ubah peluang di Config |

---

## 18. MONETISASI

### 18.1 Prinsip

Bunga = kenyamanan & gaya. Tidak ada Robux → Koin. Premium Roblox tidak memberi pengali. Tas tanpa batas slot (stack 99 per item).

### 18.2 Sumber Bunga F2P — ✔ K-31 (tabel dipisah: Rutin per bulan vs Sekali jalan; ditulis ulang di R2.12)

| Sumber | Bunga/bulan (catatan lama) |
|--------|----------------------------|
| Login Mingguan | 40 (10/minggu) |
| Pencapaian | 40 |
| Album | 30 |
| Season F2P | 30 |
| Event | 30 |
| Bundel Kakek | 10 |
| Peti Bunga | 60 |
| Total | ~240 |

### 18.3 Alat Bunga (QoL)

Gembor Bunga (siram 5 petak) 100 · Sabit Bunga (panen 5 petak) 100 · Kapak Bunga (+1 bahan/node, alternatif Kapak Besi, tidak menumpuk dengan kapak lain) 100 · Dekor Bunga (2 stat) 50–150.

### 18.4 Robux

- Pack Bunga: 50 / 120 / 300 / 700 Bunga (✔ K-44: 700 = `bunga_xl`, id 0, belum bisa dibeli; acuan Rp 15rb / 30rb / 60rb / 120rb; Robux ✔ K-32: **75 / 150 / 300 / 600 R$**).
- Season Premium: 150 Bunga.
- Tidak ada loot box, iklan, Robux → Koin.

### 18.5 Instant

Kolam: 1 Bunga per 10 menit sisa, maks 30. Bubu tidak bisa instant. Tidak ada instant panen / olahan.

---

## 19. SEASON PASS — "Musim Panen"

- 30 hari, 2 track. Mulai: ✔ K-29 **hari rilis** (kode saat ini 1 Des 2026 → R1.11). Reset 05:00 WIB, berikutnya otomatis.
- Hari yang lewat bisa diklaim sekali; hari belum tiba belum bisa.
- **F2P (USULAN):** hari 5 = 10 Bambu; 10 = 5 Bunga + 10 Kayu; 15 = 5 Batu; 20 = 10 Bunga + 5 Ijuk; 25 = 15 Bambu + 10 Kayu; 30 = 15 Bunga + 2 Atap Ijuk + 1 Dekor Rumpun Bambu + 1 Peti Bunga. Total 30 Bunga + 1 peti.
- **Premium:** "Segera hadir" (`Rewards.SEASON.PREMIUM_OPEN = false`) sampai kosmetik eksklusif ada ✔ K-30 (daftar di Penyempurnaan P-14 diterima; dibuka di Update 1). Angka usulan di kode: 40 Koin/hari + 60 Bunga ekstra.
- Kosmetik Premium tidak dijual lagi (satu-satunya barang terbatas, dan itu kosmetik).

---
- **Quest Season "Bantu 20 lahan" (K-58):** 500 Koin, tanpa Bunga; kartu di Hadiah > Musim; hanya setelah Bantu terbuka. **Belum ada di kode (K-78, R2.G4):** tidak dibangun. Aktif hanya saat `BANTU_ENABLED = true` dan kartunya sudah dibuat (RP2.S).



## 20–22. GAME FEEL, EFEK, ANIMASI

Daftar lengkap (VFX, SFX, musik, haptic, animasi, model 3D) ada di **`04_Asset_Bible.md`**. Aturan inti yang LOCKED:

- Panen Biasa: partikel daun kecil. Bagus: kilau lembut. Prima: partikel emas + `pop` + haptic kecil.
- Legenda: fanfare kecil + banner ke server.
- Hujan: partikel 30 (Gerimis), 60 (Deres), 90 + kilat (Petir). Tidak ada salju. Hujan masuk dan keluar pelan (3 dtk, tanpa muncul atau hilang mendadak). Kualitas gambar Rendah = tanpa hujan (R6.5).
- Firasat: gelembung emas di pelampung.
- Kerja Bakti: sampah visual di alun-alun, hilang saat dipungut.
- Banner server hanya: Legenda + Prima Late.
- Semua suara cozy, tanpa jumpscare. Haptic bisa dimatikan.
- Suara panen (`pop` pada panen Prima) dan gigitan ikan belum punya id audio, jadi diam sampai diisi (R7.3, Asset Bible 7). Satu suara per aksi, termasuk siram satu gerakan dan panen banyak.

---

## 23. GUI

Seluruh aturan GUI ada di **`05_GUI_Spec.md`**. Inti LOCKED: satu font (FredokaOne), satu sumber gaya (`UiKit`), mobile-first (812×375 landscape), yang terlihat = yang bisa dipakai, tidak ada GUI Papan Pamer / Rak Pajangan / Ramalan Cuaca / RW.

---

## 24. PERFORMA — HP 4GB

- Target FPS ≥ 30, 8 pemain, hujan + Kerja Bakti, di HP RAM 4GB.
- Cap: 8 pemain, 800 piece/lahan, 36 petak, 4 kolam, 3 bubu, 10 hewan/kandang.
- Bangunan alun-alun selalu render; lahan lain saat dekat (streaming).
- Anggaran triangle / tekstur / partikel: `04_Asset_Bible.md` Bab 2.

---

## 25. KPI & ANALYTICS

| KPI | Target |
|-----|--------|
| Retensi D1 / D7 / D30 | 35% / 15% / 6% |
| Konversi bayar | 3% |
| Sesi rata-rata | 20–40 menit |
| Jam ke Lv 60 | 55–70 jam |

Event wajib log (⚠ sebagian ada: funnel tutorial dan event ekonomi lewat AnalyticsHooks; daftar lengkap belum di kode, R2.10): Plant, Water, Harvest (Kualitas), Cast, Bite, PullSuccess, Fish (Tier, Size), Feed, Collect, Cook (Recipe, Kualitas), WarungSale, Bantu, KerjaBakti, Quest, Surat, Album, Login, Playtime, GerobakKaget, PasarMalam, **TutorialStep** (funnel FTUE), **FeatureOpen**.

---

## 26. LIVEOPS

- Update Besar tiap 2 bulan: +20 Level Cap (Lv 80 bulan ke-2, Lv 100 bulan ke-4), +20 piece hias, +3 resep, +2 ikan, +1 tanaman, +1 hewan (wol di Update 1).
- Event Musiman 5 per tahun, progres pribadi.
- Season 30 hari.
- Semua LiveOps bisa selesai solo.

---

## 27. SATU CORE LOOP

Tanam → Panen (Kualitas) → Olah (Kualitas Olahan) → Jual / Makan → Koin + XP → Beli petak / chunk / alat / skill / hias → Tanam lebih baik. Tidak ada MVP / fase: semua sistem bagian dari loop ini.

---

## 28. STRUKTUR DATA

PlayerData: Level, XP, SP, Koin, Bunga, Tas (item + kualitas), Lahan (petak + `paid`, chunk, bangunan, warung), Mancing (pity per Legenda, bubu), Ternak (kandang, pakan), Kolam (list + `stock`), Dapur (tier, slot), Album, Quest (main, side, surat, agenda, order), `features` (introduced / open), `guide` (`hasMet`, tutorial), Hadiah (login, peti, title, season), Sosial (bantu, hadiah, like), Settings.

- `PlayerData.version`: lihat `DataTemplate` di kode (terakhir 75). Game belum rilis: save lama boleh direset; **setelah rilis wajib ada migrasi** (Roadmap R10.2).

---

## 29. LARANGAN KERAS — build gagal jika dilanggar

Mutasi, Pelangi, Greenhouse, **Super Panen**, Rak Pajangan, Papan Pamer, RW sebagai sistem, Pasar antar pemain, Ramalan Cuaca, Antrean Dapur, Reputasi Warung, Kasih Minum Ternak, Pupuk, Hama, Stamina, Fail, Loot Box, Iklan, Robux → Koin, Premium → Koin, Bunga → Koin/XP/Level/Bahan Mentah/Hewan, Streak Reset, Hadiah > 60 Menit, Salju, Daging, Hewan Mati, Tanaman Mati, Bangunan Roboh, Quest Gagal karena Waktu, Nama NPC Lama, Gestur Joget/Tunjuk/Hug, Jual Legenda di Warung/Hadiah, Masak Legenda, Instant Bubu, Bunga dari Level-Up, **Bunga dari Like (termasuk lewat Title/Peti)**, Bibit Unggul, Backpack Pass, Blueprint gating, Buff Pasif, tombol Lewati di tutorial.

---
- **Akses DEV (K-64):** perintah `!` aktif untuk Studio dan akun owner (Config/DevAccess). Dimatikan sebelum rilis (R10.5).
- **Mode studioMock (K-65):** di Studio, profil yang gagal dimuat dibuat di memori; tidak disimpan.


## 30. PLAYTEST

Checklist lengkap ada di **`07_QA_Test_Plan.md`** Bab D.

---

## Lampiran A — Yang dihapus dan alasannya (ringkas)

| Dihapus | Alasan |
|---------|--------|
| Mutasi (Embun/Petir/Emas/Pelangi) | Judi/FOMO → diganti Kualitas |
| Super Panen | Pengali acak, diganti cap Kualitas |
| Pelangi, Greenhouse | Sisa Mutasi; Greenhouse merugikan saat hujan |
| Rak Pajangan, Papan Pamer | Pamer pindah ke Album + Like + Galeri |
| RW sistem, Pasar antar pemain | Belum terbukti ramai; diganti Warung NPC |
| Ramalan cuaca, Terik +10% | Tanpa FOMO, Terik netral |
| Antrean Dapur, Reputasi Warung | Karangan, tidak pernah dibahas |
| Bibit Unggul, Backpack Pass, Blueprint gating | Karangan, pasif / pay-to-not-annoying |
| Rumah snapshot Galeri | Pemilik offline = tidak bisa dikunjungi |
| Starter Quest Chain | Diganti rantai Main/Side Quest |
| Coachmark tarik, tombol Lewati | Keputusan owner |

## Lampiran C — Hitungan

**C.1 Kualitas.** Rata-rata (60/30/10): 0,6×1 + 0,3×1,1 + 0,1×1,25 = **1,055**. Jago (50/35/15): **1,0725**.

**C.2 Mood Hujan.** Siklus hujan rata-rata 14,5 menit (Terik 11,5 + Hujan 3). Mood 5 menit → cakupan 34,5% → ekspektasi +3,45% ke Ternak.

**C.3 Album 214** = Ladang 54 + Sungai 80 + Dapur 72 + Varian 8.

**C.4 XP total** Lv 1→60 = Σ(200 + 30n), n = 1..59 = 11.800 + 53.100 = **64.900**.

## Riwayat revisi

| Versi | Tanggal | K | Bab yang tersentuh |
|-------|---------|---|--------------------|
| v7.4–v7.7 | sebelum 2026-11 | K-01…K-42 (diputuskan, Audit 3.0) | 1–18 (isi dasar) |
| v8.1 | 2026-11-23 | K-01…K-42 diterapkan ke GDD | semua bab |
| v8.3 (Playtest 1) | 2026-11-23 | K-53…K-57 | 6.3, 5.5, 8.3, 10.2, 11, 13.2, 13.4, 14.1, 16.2 |
| v8.4 (Putaran 2) | 2026-11-23 | K-58…K-66 | 6.6 (Bubu), 8.3, 13.2, 14.5, 14.7, 16.2, 19, 25.2, 29 |
| v8.4 (koreksi D3) | 2026-11-23 | — | 6.6, 14.5, 16.2, 25.2 (ke nilai kode; lihat Audit) |
