# KAMPOENG TEDOEH — GUI Spec v1.0

> Menggantikan `GUI_Kampoeng_Tedoeh_v0.1.md`. Isi = v0.1 + yang sudah dikerjakan di kode (UI-1, UI-3, ST-3, F-1…F-3, UI-B1…UI-B15) + keputusan final K-xx (`02_Audit_Perbaikan.md` Bab 3.0).
> **Mobile-first.** Baseline **812 × 375 pt (HP landscape)**, lalu tablet / PC. Layar uji wajib: 844×390, 667×375, 390×844 (portrait), 1920×1080.
> Ikon, animasi UI, suara UI: `04_Asset_Bible.md`.

---

## 1. Prinsip — LOCKED

1. **Bentuk GUI ikut konteks.** List hanya untuk data yang memang daftar. Progres berhari-hari = lintasan ke samping. Skill = pohon. Stasiun kerja = slot + pilihan resep.
2. **Satu sumber gaya: `UiKit`.** Warna, ukuran teks, radius, jarak, layer, target sentuh hanya dari token UiKit. Tidak ada `Color3.fromRGB` / angka `TextSize` / angka `DisplayOrder` di controller.
3. **Mobile-first.** Jempol kiri = thumbstick (kiri bawah **kosong**), jempol kanan = Jump + Tombol Aksi.
4. **Yang terlihat = yang bisa dipakai.** Tombol fitur yang belum terbuka tidak tampil (feature gate). Tidak ada tombol abu-abu.
5. **Cozy, bukan ramai.** Satu fokus per layar. Tidak ada popup yang muncul sendiri kecuali hasil aksi pemain.
6. **Bersih.** Panel dibangun saat dibuka dan dihancurkan saat ditutup (`UiKit.closePanel`). Tidak ada frame tersembunyi yang kosong.

---

## 2. Yang Dipertahankan

Palet bambu + parchment + daun · font **FredokaOne** (satu-satunya) · skin ForgeGUI 9-slice dengan fallback flat · `UiKit.autoScale` + `DeviceSafeInsets` · dock bawah tengah 58 px (pindah ke kanan saat portrait) · tap backdrop untuk menutup · panel slide dari bawah · `T1Dialog` · `UiKit.confirm` (Batal kiri merah, Setuju kanan hijau) · `priceChip` merah saat Koin kurang · `UiKit.tabs` / `grid` / `cell` / `tradeRow` / `productCard` · panel reel mancing 260×108 · tombol Mancing bulat 84 px · banner Dimulai / Selesai (bar hitam, judul emas).

---

## 3. Token UiKit (sudah di kode, UI-1)

### 3.1 Warna

Semua warna palet lama tetap. Tambahan: `GOLD (255,226,120)` siap klaim / highlight / hadiah · `GOLD_DEEP (240,196,92)` angka Koin · `SHADE (30,20,10)` backdrop · `INK_DARK (48,32,20)` teks di krem · `LOCKED (150,150,150)` · `WATER (46,104,128)`.

Arti warna: hijau daun `BUTTON` = aksi utama · tan `BUTTON_MUTED` = sekunder · `RED` = batal / kurang Koin · `GOLD` = siap / hadiah · `CAT` (tanaman hijau, ikan biru, alat terakota, dekor ungu, uang emas) hanya untuk stripe kartu & badge.

### 3.2 Teks

| Token | px | Untuk |
|-------|----|-------|
| `TEXT_DISPLAY` | 36 | Banner, angka besar |
| `TEXT_TITLE` | 21 | Ribbon panel |
| `TEXT_HEADING` | 18 | Judul seksi |
| `TEXT_BODY` | 16 | Baris, tombol |
| `TEXT_SMALL` | 14 | Dialog, deskripsi |
| `TEXT_CAPTION` | 12 | **Batas bawah** |

Ukuran 9 dan 11 dilarang.

### 3.3 Jarak & Radius

Jarak 4 / 8 / 12 / 16 / 24. Radius `R_SM 8` (chip), `R_MD 14` (tombol, kartu), `R_LG 20` (panel flat), `R_ROUND` (plate, avatar, node).

### 3.4 Target Sentuh (keputusan owner 2026-11-22)

| Token | px | Untuk |
|-------|----|-------|
| `TOUCH_MIN` | 24 | Ikon tutup kecil, `Tunjukkan`, ikon info (area tap boleh lebih besar, maks 32) |
| `TOUCH` | 32 | Standar semua tombol di panel, Next, pilihan dialog, tab, Gembor |
| `TOUCH_ROW` | 32 | Baris tracker |
| `TOUCH_CTA` | 40 | Satu aksi utama per layar (Tingkatkan, Klaim Semua, Masak, Panen Semua) |
| `TOUCH_HUD` | 50 | Pil kolom menu HUD |

Tombol HUD lain tetap: dock 58, Tombol Aksi 84. Jarak antar target ≥ 6 px. (Gembor 32 & pil 50: K-38.)

### 3.5 Layer (`UiKit.LAYER`, sudah di kode)

| Layer | DisplayOrder | Isi |
|-------|--------------|-----|
| WORLD_BACK / dunia | −2 … −1 | Float di atas petak, marka lahan |
| ACTION | 10 | Tombol aksi kontekstual, ring ritme, tombol ♥ like |
| HUD | 20 | Mata uang, kartu pemain, dock, kolom menu, tracker |
| GUIDE | 30 | Panah dunia, hint |
| PANEL | 40 | Semua sheet |
| COACHMARK | 50 / 60 | Overlay / ring + bubble ⚠ bentrok angka dengan toast (Audit A-72, R3.7) |
| TOAST | 60 | Toast, reward popup |
| BANNER | 80 | Dimulai / Selesai |
| MODAL | 100 | `UiKit.confirm` |
| CUTSCENE | 110 | Tutorial ghost |
| DIALOG | 120 | T1Dialog |
| FADE | 150 | FadeManager |
| MENU / MENU_PANEL / COVER | 200 / 210 / 250 | Menu awal, loading |

---

## 4. HUD (landscape) — peta di `UiKit.HUD`

```
┌──────────────────────────────────────────────────────────────────────┐
│ [Roblox] [Foto Lv ▬XP] [buff]   [● Koin] [✿ Bunga]          (Acara)  │
│ Quest tracker                     ┌ toast stack ┐            (Skill)  │
│  ★ Main: Kolam Kakek       [→]    └─────────────┘            (Hadiah) │
│   · Bangun kolam                                             (Warga)  │
│  · Side: Bibit Kedua                                         (Toko)   │
│                                                              (≡ Atur) │
│                                                                       │
│ ░░░░░░░░░░░░            [chip umpan · status mancing]   [Aksi 84px]   │
│ ░ thumbstick ░  (Garap)(Kolam)(Hias)(Tas)(Pesanan)               [Jump]│
└──────────────────────────────────────────────────────────────────────┘
```

| Zona | Isi | Ukuran / aturan (kode UI-B12) |
|------|-----|-------------------------------|
| Atas tengah | Koin, Bunga | Tetap |
| Atas tengah, di bawah mata uang | Toast stack | Lihat 4.2 |
| Kiri atas | Kartu pemain ringkas (foto + level + bar XP) + chip buff, lalu tracker | Kartu pindah dari kiri bawah ✔ K-34. Tracker lebar 200 px, mulai 118 px dari atas, tinggi maks min(200 px, 25% layar), maks 3 baris + "+N lainnya", teks krem outline gelap tanpa panel, baris membungkus teks |
| Kanan atas | Kolom menu bulat 50 px, ikon saja, bisa dilipat di HP | Urutan: Acara, Skill, Hadiah, Warga, Toko, Atur. Dapur **tidak** di sini (✔ K-34) |
| Bawah tengah | Dock 58 px, 10 px dari bawah | Garap, Kolam, Hias, Tas, Pesanan — hanya yang sudah terbuka |
| Zona konteks (di atas dock, tengah) | Status memancing + chip umpan | Satu tombol di atas dock; tombol Batal berlabel 64×32 px |
| Kanan bawah, di atas Jump | **Satu slot Tombol Aksi 84 px** | Mancing / Pukul / Tebang / Kelola Kandang / Breeding / Craft / Masak — satu aksi, yang terdekat (✔ K-34, sekarang Craft masih melayang di atas meja) |
| Kiri bawah | Thumbstick | **Kosong** |

Margin layar 12, gap 8.

**Label tombol baru:** saat tombol HUD pertama kali muncul (dibuka quest), tombol memantul + label nama 4 detik. Tekan lama 0,5 dtk (HP) / hover (PC) = tooltip nama (`attachTip`, sekarang kosong → R3.1).

### 4.1 Portrait (390×844)

Dock pindah ke kolom kanan. Toast turun di bawah tracker, lebar 200 px. Kolom menu dilipat default.

### 4.2 Toast — satu komponen (`UiKit.toastStack`, kode B-2/F-2)

- X tengah layar, Y = bawah CurrencyBar + 8 px.
- Lebar = min(50% layar, ruang antara tracker kiri & kolom kanan). Hasil hitung: 844×390 → 404 px · 667×375 → 227 px · 1920×1080 → 960 px · portrait → di bawah tracker, 200 px.
- Tinggi dari teks terukur, min 40 px. Maks 3 tampil, sisanya antre, tiap 1,8 dtk, fade 0,25 dtk.
- Banner LEVEL n, reward popup, dan efek terbang **bukan** toast (K-38).
- Saat Bubble Instruksi tampil, toast stack turun di bawah bubble (✔ K-40).

### 4.3 Bubble Dialog NPC (`T1Dialog`)

| | Bubble Instruksi (langkah tutorial / quest) | Bubble Percakapan (NPC, Next / pilihan) |
|---|---|---|
| Tinggi | Ikut teks, min 48 (tanpa batas maks, UI-B1) | Ikut teks, min 64 |
| Lebar | maks 400 px / 55% layar | maks 440 px / 60% layar |
| Foto NPC | 32 (ring 40) | 40 (ring 48) |
| Nama | Di atas teks (deviasi dari "satu baris", K-38) | 14 px di atas teks |
| Teks | 14 px | 14 px |
| Tombol | Next 64×32 = **menutup** bubble (progres tidak menunggu Next) | Next 64×32 kanan bawah; pilihan 32 px |
| Bingkai | Inset 34 px (skin tebal) sampai skin bambu tipis ada (Asset Bible Bab 10) | sama |
| Posisi | Atas tengah, di bawah mata uang | Bawah tengah, di atas dock (58 + 8 px), tidak menutupi Tombol Aksi |

- Bubble Instruksi **tidak pernah hilang sendiri**. Saat langkah berubah: bubble lama **minimize** ke arah foto (0,18 dtk), bubble baru **membesar** dari titik yang sama (0,22 dtk, sedikit memantul). Hanya Next yang menutup; muncul lagi di langkah berikutnya.
- Saat Bubble Percakapan tampil, Bubble Instruksi sembunyi dan kembali bila langkah masih sama.
- Selama memancing (`FishingActive`) keduanya tersembunyi.
- Antrean bicara: satu baris pada satu waktu.

### 4.4 Banner Dimulai / Selesai

`UiKit.hideOthers` / `restoreOthers`: HUD dan tracker disembunyikan selama banner, dikembalikan persis seperti sebelumnya. Pemain dikunci ±3 dtk.

---

## 5. Bentuk Sheet

| Bentuk | Kapan | HP | PC |
|--------|-------|----|----|
| **Sheet List** (`UiKit.panel` sekarang) | Data daftar: toko, pengaturan, pemain | 88% × 86%, maks 600 × 400 | sama |
| **Sheet Grid** | Koleksi: Tas, Album, katalog Hias | sama | sama |
| **Sheet Lebar** (baru) | Lintasan Season, Pohon Skill, stasiun kerja | Penuh di dalam safe area, ribbon + close tetap | maks 1000 × 560 |
| **Drawer Detail** (baru) | Detail 1 benda di atas sheet | Dari bawah, tinggi 45% | Dari kanan, lebar 320 |

Komponen (Bab 7) dipakai ulang; tidak ada `Instance.new("Frame")` manual di controller untuk elemen yang ada komponennya.

---

## 6. Layout per Fitur

### 6.1 Hadiah (tombol ★) — tab **Harian · Musim · Koleksi**, Sheet Lebar

Status kode (UI-3): 3 tab ada; Musim = 2 track horizontal (node 64 px, milestone 80 px); Premium terkunci (`PREMIUM_OPEN = false`). Belum (✔ K-36): kartu Login, bar Peti Main, kartu besar Peti Bunga, Klaim Semua, Milestone Album hanya di Koleksi.

- **Harian:** Login Mingguan = 7 kartu ke samping (hari 7 lebih lebar; hari Bunga diberi ikon ✿); diambil = stempel "Diambil"; hari ini menyala emas. Peti Main = 1 bar 0–60 menit dengan 5 peti di 10/20/30/45/60; peti tercapai bergoyang.
- **Musim:** header nama musim + sisa hari + status Premium. Dua jalur: Gratis (atas), Premium (bawah, bergembok). Kolom = hari 1–30, garis progres, **auto-scroll ke hari ini**. Node terkunci (abu), siap (emas berdenyut), diambil (centang). Hari bernilai Bunga / peti = node besar. `Klaim Semua` kanan bawah saat ≥ 2 siap. Angka hadiah dari `Config/Rewards`, bukan dari mockup.
- **Koleksi:** Title (grid kartu badge + syarat; tap = drawer + "Pakai Title"), Peti Bunga (kartu besar, tombol Buka + animasi), Milestone Album (lintasan pendek 25/50/75/100%).

### 6.2 Pohon Skill — Sheet Lebar (kode ST-3)

- 6 dahan berjajar (Bertani, Mancing, Ternak, Tukang, Masak, Sosial), scroll horizontal di HP. Root bawah, Cabang tengah (Bertani & Mancing: A dan B berdampingan), Capstone atas, garis dahan menyala sampai node tertinggi yang dibeli.
- Node **40 px** (`TOUCH_CTA`), jarak tier 30 px, pil level `x/5`, badge `+` bila bisa naik, bingkai emas = maks. Label nama di node: ✔ K-35 (final: ikon unik per skill, nama di drawer).
- Header dahan: ikon cabang + nama + total (`Bertani 7/20`, tampilan saja).
- Chip **SP** dan **Koin** kanan atas.
- Tap node = Drawer Detail: nama, efek sekarang → berikutnya, biaya **1 SP + Koin** (GDD 4.5.1), prasyarat yang kurang, `Efek mulai Lv 3` untuk skill bertahap, tombol **Tingkatkan 40 px**. Alasan server (`locked / noSP / noKoin / max`) tampil di drawer. Tidak ada tombol beli di node.

### 6.3 Dapur + Warung — Sheet Lebar, tab **Masak · Warung** (UI-5)

Dibuka lewat Tombol Aksi dekat Tungku (✔ K-34).
- **Masak:** strip atas = kartu slot (1–3 sesuai tier: foto olahan, kualitas, timer melingkar, `Ambil` saat selesai; slot terkunci = gembok "Tier 2"). Bawah = grid resep 96×112 (foto, ikon buff, bahan `punya/butuh` merah bila kurang, gembok + "Butuh Jahe (Lv 22)" bila bahan belum terbuka). Filter chip: Semua / per buff. Tap = drawer (bahan, waktu, perkiraan kualitas, tombol **Masak**).
- **Warung:** kartu etalase (olahan + harga), pilih olahan dari grid kecil, riwayat 3 penjualan terakhir.
- **Makan:** dari Drawer Tas (olahan) dan drawer resep. Buff aktif = chip ikon + timer di samping kartu pemain.

### 6.4 Meja Crafting — Sheet Lebar (UI-5)

Grid kartu rumus visual `[2 Kayu] → [1 Papan]`, jumlah dimiliki di bawah tiap bahan, tombol `×1` dan `×10` (32 px). Bahan kurang = pudar + angka merah.

### 6.5 Kandang & Kolam — Sheet Lebar (UI-5)

- **Kandang:** atas = kartu kandang (jenis, level, kapasitas `6/10`, `Upgrade`). Tengah = grid hewan (foto, 3–5 titik jatah pakan, produk menumpuk, timer siklus, badge Mood Hujan). Bawah = `Isi Pakan Semua` dan `Ambil Semua` (40 px). Beli hewan = kartu `+` terakhir.
- **Kolam:** kiri = kartu kolam (tier, stok `7/10`, upgrade, instant Bunga). Kanan atas = slot breeding (2 lubang indukan + 1 anak, timer). Kanan bawah = grid stok ikan (foto + ukuran) dengan tombol Setor / Ambil (kode B-3 sudah punya sheet "Kolam", rapikan ke bentuk ini).

### 6.6 Acara — Sheet Lebar, tab **Hari Ini · Kalender** (UI-6)

- **Hari Ini:** 3 kartu Gerobak Kaget (Bibit / Dekor / Langka) + countdown restock; kartu Pasar Malam (buka / tutup + sisa waktu); kartu Kerja Bakti (progres kampung % + poin pribadi `x/20`).
- **Kalender:** strip bulan horizontal, 5 event sebagai pita; event aktif menyala; tap = drawer (Pesanan Tamu, hadiah).

### 6.7 Pesanan (Order Villager) — Sheet Grid (UI-6)

3 kartu Harian + 1 Mingguan (lebih lebar, bingkai emas). Kartu: foto NPC, barang `punya/butuh`, hadiah, `Setor` (aktif bila cukup), ikon `Ganti` (reroll 2 Bunga, dengan konfirmasi).

### 6.8 Quest Log — Sheet List, tab **Main · Side** (kode Q-4)

Dibuka dari tap baris tracker. Tab kosong tidak digambar. Bagian: **Aktif / Tersedia / Selesai / Berikutnya** (`???` sampai level). Kartu Main aktif: pemberi + foto, langkah bercentang, hadiah, `Tunjukkan`. Baris petunjuk khusus (Kerja Bakti: K-37).

### 6.9 Papan Hari Ini (baru, ✔ K-34 / Penyempurnaan P-04)

Satu panel untuk hal harian: Agenda (5 tugas, R2.2), Surat Kakek hari ini, ringkasan Order, Login hari ini, Album (%). Mengurangi jumlah tombol HUD.

### 6.10 Yang Tetap Bentuknya

| Panel | Bentuk | Perubahan kecil |
|-------|--------|-----------------|
| Tas | Sheet Grid + tab | Tab ✔ K-33 (`Semua · Bibit · Panen · Ikan · Olahan · Bahan · Umpan · Alat`, baris tab bisa digeser). Tap item = Drawer (info, kualitas, `Makan` untuk olahan). |
| Album | Sheet Grid + tab | Tab Hadiah pindah ke Hadiah › Koleksi. Header + bar %. |
| Toko NPC | Sheet List + tradeRow | Panel ukuran standar + gulir (K-38). Foto NPC di ribbon. Bahan yang kurang ditampilkan. |
| Toko Robux | productCard + tab samping | Tab sisi 32 px, aktif = hijau + teks krem. |
| Warga (Sosial) | Sheet List | Baris pemain + headshot; Gestur = 4 tombol ikon bulat di atas list; Visit & Like. |
| Atur | Sheet List + switch | Tambah: Efek rendah, Kurangi gerak, volume Musik/SFX/Ambience/UI, Haptic, Notifikasi Gerobak, Bahasa. |
| Hias | Mode bangun | Tetap. |
| Mancing | Panel reel | Tetap (disetujui). |

---

## 7. Komponen UiKit

| Komponen | Untuk | Status |
|----------|-------|--------|
| Token warna / teks / radius / layer / touch | Bab 3 | Ada |
| `toastStack`, `toastChip`, `toastFadeOut`, `toastWidth` | Toast | Ada |
| `hideOthers` / `restoreOthers` | Banner | Ada |
| `HUD`, `hudStripBottomGap` | Peta HUD | Ada |
| `tabs` (frame 32 px), `notifyDot` (di dalam tombol) | | Ada |
| `sheet(name, title, kind, onClose)` kind = list / grid / wide | Ganti `panel` bertahap | Belum |
| `drawer(parent, onClose)` | Drawer Detail | Sebagian (Skill) |
| `track(parent, columns, lanes)` + `trackNode` | Season, Login, Peti Main, Milestone, lintasan Main | Sebagian (Season) |
| `treeBranch` + `treeNode` | Pohon Skill | Sebagian (SkillController) |
| `slotCard`, `timerRing` | Dapur, Breeding, Warung, Gerobak | Belum |
| `recipeCard` | Dapur, Crafting | Belum |
| `filterChips` | Filter grid | Belum |
| `actionButton(iconKey, onPress)` | Satu slot Tombol Aksi | Belum (Mancing pakai `AksiButton` sendiri) |
| `attachTip` (tekan lama / hover) | Label tombol | Kosong → R3.1 |

---

## 8. Status Implementasi GUI

| Tahap | Isi | Status |
|-------|-----|--------|
| UI-1 Fondasi | Token, touch tier, bubble 2 varian, layer | Selesai (belum playtest) |
| UI-2 HUD | Ikon Acara/Skill, kartu pemain kiri atas, slot Aksi, label tombol + tekan lama | **R3.1** |
| UI-3 Hadiah | 3 tab + track Season | Sebagian selesai → sisa **R3.4** |
| UI-4 Skill | Pohon + drawer (dikerjakan sebagai ST-3) | Selesai → ikon & label **R3.5** |
| UI-5 Stasiun | Dapur + Warung, Crafting, Kandang, Kolam | **R3.2** |
| UI-6 Lainnya | Acara, Pesanan, Quest Log penuh, Papan Hari Ini | **R3.3** |
| Batch F, UI-B1…B15 | Tas Umpan, toast, chip umpan, HUD map, perbaikan bug | Selesai (belum playtest) |

Mockup lama (canvas "Mockup Season Pass & Pohon Skill (HP)", https://claude.ai/artifact/UuRgfWQfZCVCxA2iUQDZhf) tetap acuan bentuk, **bukan** angka: ukuran tombol ikut Bab 3.4, angka hadiah ikut `Config/Rewards`, Premium ikut status "Segera hadir".
