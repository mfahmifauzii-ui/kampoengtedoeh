# KAMPOENG TEDOEH — Skill Tree (Dokumen Terpisah)

> Single Source of Truth untuk Skill Tree: dokumen ini. Bab 4.5 dokumen gameplay hanya boleh berisi rujukan ke sini, bukan salinan tabel (Prinsip #15, 1 aturan 1 tempat).
> Versi: v7.7 — Skill Tree. Induk: `Kampoeng_Tedoeh_v7.7.md` Bab 4.3 + 4.5. Pengganti v7.5 Skill Tree.
> Prinsip: Skill tidak mengunci core loop. Semua bisa dimainkan tanpa skill apa pun.
> Revisi berikutnya wajib nomor baru + isi changelog.

---

## 0. Changelog v7.5 → v7.7

| # | Perubahan | Alasan |
|---|-----------|--------|
| 1 | Prasyarat Capstone Bertani dan Mancing diberi kurung: `(A Lv 3 ATAU B Lv 3) + Player Lv 10`. | v7.5 ambigu (bisa terbaca "Lv 3 ATAU Lv 3 + Player Lv 10"). |
| 2 | Bab 1 dan Bab 4 menghitung belanja skill sampai Lv 60 (maks 59 SP, 177.000 Koin) dan dampaknya ke sink Bab 17.4. | v7.5 menulis "ekonomi tidak berubah", benar hanya bila semua skill maxed. |
| 3 | Bab 1.1 (baru): efek bertahap Lv 1-2 tanpa efek, dan tulisan di drawer. | Skill bertahap sebelumnya tidak punya aturan tampilan. |
| 4 | Layout Bab 3: 6 dahan berjajar (mockup GUI Bab 10, disetujui owner), bukan 6 tab. | Mockup GUI sudah disetujui, dan tiap cabang paling tinggi 3 tier. |
| 5 | Bab 5 (baru): hubungan dengan dokumen lain, termasuk arti "Bertani / Mancing / Tukang Lv N" di tabel alat. | Sisa istilah Level Cabang lama (dihapus P2-4) masih tertulis di Bab 6.3 dan 17.5. |
| 6 | Bab 6 (baru): keputusan owner yang sudah ditetapkan (stacking Kapak dan Tukang Cepat, Kapak Bunga). | Stacking sebelumnya belum diputuskan, dan v7.5 menulis "+5" yang salah (maks +4). |
| 7 | Penomoran mengikuti dokumen induk (v7.7). | v7.5 menyebut induk v7.5 dan Bab 4.5 "v7.4 ke bawah". |

---

## 1. Aturan Beli (LOCKED)

- Setiap 1 level skill = **1 SP + 3.000 Koin**.
- Max 1 skill = 5 level = **5 SP + 15.000 Koin**.
- Total max semua skill = 16 skill x 5 lv = **80 SP + 240.000 Koin**. Angka 240.000 adalah jumlah penuh, yang dipakai di tabel sink Bab 17.4 (lihat Bab 4 di bawah untuk nilai pada Lv 60).
- **SP:** 1 SP per Level Player (naik ke Lv 2 dapat SP pertama). SP pada Lv n = n − 1. Total SP sampai Lv 60 = **59 SP**, jadi sampai Lv 60 player **tidak bisa max semua skill**, harus memilih cabang. Pada cap Lv 80 SP = 79, masih kurang 1. Semua skill baru bisa maxed di Lv 81, yaitu setelah cap naik ke Lv 100.
- **Tidak ada reset skill di rilis.** Pilihan permanen. Mau ganti gaya main, ambil cabang lain dengan SP berikutnya.
- Skill tidak bisa dibeli pakai Bunga / Robux.
- Skill hanya bisa dibeli kalau **Player Lv** cukup DAN **prasyarat skill** terpenuhi. Prasyarat dihitung dari Lv skill, bukan dari efeknya.
- **"Player Lv"** = level player (Bab 4.2). **Tidak ada level cabang** (Level Cabang lama dihapus di P2-4).
- **"N SP di mana pun"** (dipakai Tetangga Baik) = jumlah level semua skill ≥ N. Karena 1 SP per level, ini turunan dari data skill yang sudah ada, tidak butuh data baru.
- Skill di luar cap Dekor (max +10% per jenis, Bab 17.6).

### 1.1 Skill bertahap (breakpoint)

Tiga skill baru terasa di breakpoint tertentu: Tempat Pakan Besar (Lv 3), Tukang Cepat (Lv 3 dan Lv 5), Tetangga Baik (Lv 3 dan Lv 5).

- Untuk prasyarat dan biaya, mereka tetap dihitung per Lv skill. Lv 1-2 adalah investasi untuk membuka breakpoint dan **tidak punya efek**.
- Drawer detail wajib menulis jelas **"Efek mulai Lv 3"** pada Lv 1-2, supaya player tidak mengira skillnya rusak.
- Skill lain (efek %) memberi efek sejak Lv 1.

---

## 2. Pohon — 16 Skill, 6 Cabang

### 2.1 Bertani — Cabang Nanem (Root Lv 2)

| Tier | Skill | Efek per Lv (max Lv 5) | Prasyarat |
|------|-------|------------------------|-----------|
| Root | Tangan Hijau | Tumbuh +2%/lv | Player Lv 2. Tidak ada prasyarat skill. |
| Cabang A | Bibit Hemat | 4%/lv bibit kembali saat panen | Tangan Hijau Lv 2 + Player Lv 4 |
| Cabang B | Mata Kualitas | Peluang Bagus +2%/lv, Prima +0,5%/lv | Tangan Hijau Lv 2 + Player Lv 6 |
| Capstone | Panen Raya | +2% Koin Nanem/lv (di luar cap Dekor) | (Bibit Hemat Lv 3 **ATAU** Mata Kualitas Lv 3) **DAN** Player Lv 10 |

Logika: Belajar nanem lebih cepat dulu (Tangan Hijau) baru bisa hemat bibit / baca kualitas. Panen Raya adalah hadiah buat yang sudah dalem di salah satu cabang, tidak harus ambil dua-duanya.

```
        [Panen Raya]
              ↑
   salah satu Lv 3 + Player Lv 10
   ┌──────────┴──────────┐
[Bibit Hemat]     [Mata Kualitas]
   └──────────┬──────────┘
         [Tangan Hijau]
```

---

### 2.2 Mancing — Cabang Ikan (Root Lv 2)

| Tier | Skill | Efek per Lv (max Lv 5) | Prasyarat |
|------|-------|------------------------|-----------|
| Root | Joran Kuat | Kotak tarik +2%/lv | Player Lv 2. Tidak ada prasyarat skill. |
| Cabang A | Umpan Hemat | 5%/lv umpan kembali saat lepas | Joran Kuat Lv 2 + Player Lv 4 |
| Cabang B | Firasat | Pity -10/lv (min 150) | Joran Kuat Lv 2 + Player Lv 6 |
| Capstone | Ikan Besar | Peluang Besar/Jumbo +2%/lv | (Umpan Hemat Lv 3 **ATAU** Firasat Lv 3) **DAN** Player Lv 10 |

Logika: Kuatin tarikan dulu baru bisa hemat umpan / baca firasat. Firasat dibuka lebih lambat karena efeknya ngaruh ke Legenda (pity).

```
         [Ikan Besar]
              ↑
   salah satu Lv 3 + Player Lv 10
   ┌──────────┴──────────┐
[Umpan Hemat]      [Firasat]
   └──────────┬──────────┘
          [Joran Kuat]
```

---

### 2.3 Ternak — Cabang Kandang (Root Lv 5)

| Tier | Skill | Efek per Lv (max Lv 5) | Prasyarat |
|------|-------|------------------------|-----------|
| Root | Tempat Pakan Besar | Max jatah 3 → 5 (efek mulai Lv 3) | Player Lv 5. Tidak ada prasyarat skill. |
| Cabang | Telur Cepat | Cooldown -2%/lv | Tempat Pakan Besar Lv 2 + Player Lv 8 |
| Capstone | Susu Melimpah | +2% Koin Ternak/lv | Telur Cepat Lv 3 + Player Lv 12 |

Logika: Urus pakan dulu (biar produksi tidak berhenti) baru bisa ngebut telur / susu. Linear 3 skill karena cabangnya kecil.

```
[Susu Melimpah]
       ↑
[Telur Cepat]
       ↑
[Tempat Pakan Besar]
```

---

### 2.4 Tukang — Cabang Nambang (Root Lv 4)

| Tier | Skill | Efek per Lv (max Lv 5) | Prasyarat |
|------|-------|------------------------|-----------|
| Root | Kayu Kuat | +2% bahan Nambang/lv | Player Lv 4. Tidak ada prasyarat skill. |
| Capstone | Tukang Cepat | +1 bahan per node di Lv 3, +2 di Lv 5 (efek mulai Lv 3) | Kayu Kuat Lv 3 + Player Lv 8 |

Logika: Nambang lebih banyak bahan dulu baru bisa mukul lebih cepat / lebih banyak per node. Tukang Cepat sengaja jadi capstone karena efeknya paling kerasa di putaran Hutan.

```
[Tukang Cepat]
       ↑
  [Kayu Kuat]
```

---

### 2.5 Masak — Cabang Dapur (Root Lv 6)

| Tier | Skill | Efek per Lv (max Lv 5) | Prasyarat |
|------|-------|------------------------|-----------|
| Root | Koki Cepat | Waktu olah -3%/lv | Player Lv 6. Tidak ada prasyarat skill. |
| Capstone | Rasa Prima | Peluang Olahan Prima +1%/lv | Koki Cepat Lv 3 + Player Lv 10 |

Logika: Masak lebih cepat dulu baru bisa konsisten bikin Prima. Rasa Prima dibuka setelah Dapur Tier 1 kebuka (Lv 6) dan player sudah masak beberapa kali.

```
[Rasa Prima]
       ↑
 [Koki Cepat]
```

---

### 2.6 Sosial — Cabang Bantu (1 skill, lintas cabang)

| Tier | Skill | Efek | Prasyarat |
|------|-------|------|------------|
| Tunggal | Tetangga Baik | +1 lahan Bantu/hari di Lv 3, +2 lahan di Lv 5 (efek mulai Lv 3) | Total level semua skill ≥ 5 (setara 5 SP terpakai di cabang mana pun) + Player Lv 10. Tidak ada prasyarat skill spesifik. |

Logika: Sosial tidak nempel di satu cabang. Player harus sudah buktiin main dulu (5 SP di mana pun) baru bisa bantu lebih banyak lahan. Lv 5 = +2 biar Lv 4-5 tidak mati.

```
[Tetangga Baik]
  Butuh: 5 SP di mana pun + Player Lv 10
```

---

## 3. Tampilan Tree (UI)

Layout dan ukuran mengikuti `GUI_Kampoeng_Tedoeh_v0.1.md` (Bab 4.4, 6.2, 7, dan mockup Bab 10). Dokumen ini hanya menetapkan isi dan status node.

- **Sheet Lebar.** 6 dahan berjajar (Bertani, Mancing, Ternak, Tukang, Masak, Sosial), bisa di-scroll horizontal di HP. Tiap dahan vertikal: Root di bawah, Cabang di tengah, Capstone di atas, dihubungkan garis. Bertani dan Mancing menggambar Cabang A dan B sebagai dua node kiri-kanan. Chip **SP tersedia** dan chip **Koin** di kanan atas.
- Header tiap dahan: nama cabang + total level (contoh `Bertani 7/20`). Ini hanya tampilan, bukan level cabang.
- Tap node membuka **drawer detail**: nama, efek sekarang → efek level berikutnya, biaya `1 SP + 3.000 Koin`, tombol **Tingkatkan**. Tidak ada tombol beli langsung di node (hindari salah pencet).
- Status node:
  - **Terkunci:** abu-abu + tulisan prasyarat (contoh `Butuh Tangan Hijau Lv 2`, `Butuh Player Lv 6`).
  - **Bisa dibeli:** nyala, tombol aktif.
  - **Kurang SP atau Koin:** tombol nonaktif + tulisan yang kurang (`SP belum cukup` / `Koin belum cukup`).
  - **Maks:** bingkai emas.
- Skill bertahap: pada Lv 1-2 drawer menulis `Efek mulai Lv 3` (Bab 1.1).
- Tidak ada popup penawaran di dalam Tree. Tidak ada tombol beli pakai Bunga / Robux.
- Garis dahan menyala sampai node tertinggi yang sudah dibeli.

---

## 4. Ringkasan Biaya dan Dampak Ekonomi

| Item | Angka |
|------|-------|
| Per level | 1 SP + 3.000 Koin |
| Per skill max (5 lv) | 5 SP + 15.000 Koin |
| Semua skill max (16 skill) | 80 SP + 240.000 Koin (tercapai di Lv 81) |
| SP sampai Lv 60 | 59 SP |
| Belanja skill maksimal sampai Lv 60 | 59 level = **177.000 Koin** |

Dampak ke Bab 17.4 dan 17.8:

- Sink Bab 17.4 menghitung skill 240.000 Koin (total ~623.000). Pada Lv 60 skill baru bisa menyerap paling banyak 177.000 Koin, jadi sink efektif saat Lv 60 ≈ **560.000**.
- Faucet Lv 60 ≈ 442.000 Koin (≈ 455.000 dengan Kualitas + Mood Hujan). Rasio ≈ **79%** (≈ **81%** dengan Kualitas + Mood Hujan), mepet batas atas validasi 65-80% (Bab 17.8).
- Karena itu harga skill tetap menjadi tuas pertama kalau playtest meleset (Bab 17.8: "Ubah harga Skill dulu"). Jangan mengubah harga ini tanpa membaca Bab 17.8.
- Bab 17.4 harus mencatat dua angka: 240.000 (semua skill maxed) dan 177.000 (batas sampai Lv 60).

---

## 5. Hubungan dengan Dokumen Lain

- **Bab 4.3 / 4.5 dokumen gameplay:** hanya rujukan ke dokumen ini.
- **Tabel Joran, Umpan, dan Alat (Bab 6.3, 17.5):** tulisan "Mancing Lv N", "Bertani Lv N", "Tukang Lv N" berarti **Player Lv N**. Itu bukan level cabang dan bukan level skill. Di kode syarat ini sudah memakai level player.
- **Bab 4.4 (Unlock):** root tiap cabang sejajar dengan konten pembukanya: Ternak Lv 5 (Ayam), Tukang Lv 4 (Hutan Nambang), Masak Lv 6 (Dapur Tier 1).
- **GUI doc Bab 6.2 / 9:** pertanyaan "prasyarat skill atau visual saja" dijawab di sini: **ada prasyarat nyata** (Bab 2). Garis dahan bukan lagi visual saja.

---

## 6. Keputusan Owner

| # | Keputusan | Alasan |
|---|-----------|--------|
| 1 | **Kapak + Tukang Cepat menumpuk.** Hanya kapak terbaik yang dihitung (Besi +1, Baja +2; kapak tidak menumpuk antar kapak). Bonus kapak dijumlah dengan Tukang Cepat (+1 di Lv 3, +2 di Lv 5). **Maksimal +4 bahan per node** (dasar 4 bahan, jadi 8). | Bahan tidak bisa dijual, jadi tidak menambah Koin. Dampak hanya mempercepat Hias, craft, dan kandang. Investasinya besar (Kayu Kuat Lv 3 + Tukang Cepat Lv 5 = 8 SP + 24.000 Koin, plus Kapak Baja). |
| 2 | **Kapak Bunga (+1, Bab 18.3) tetap +1.** Statusnya jalur alternatif setara Kapak Besi (bayar Bunga, bukan Koin), bukan tier di atas Baja. Tidak ditumpuk dengan kapak lain. | Hanya kapak terbaik dihitung, jadi tidak ada dampak ekonomi. Pemain yang punya Bunga berlebih punya jalan ke tier +1 tanpa Koin. |
| 3 | **Buff Tukang/Tebang tidak menumpuk dengan bonus per node.** Buff hanya +1 saat Critical. | Menjaga batas +4 per node. |

---

---

Dokumen ini v7.7 Skill Tree only. Revisi berikutnya wajib nomor baru + isi changelog.
