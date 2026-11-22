# KAMPOENG TEDOEH — Aturan & Arahan GUI v0.1 (DRAFT)

> Dasar: audit kode `src/client` (UiKit.luau + 27 controller) per 2026-11-22, dokumen gameplay v7.5, `Quest_Kampoeng_Tedoeh_v0.3.md`.
> Prinsip revisi: **yang sudah bagus dipertahankan**, yang diubah hanya yang perlu di-improve.
> **Mobile-first.** Semua layout dirancang untuk HP landscape lebih dulu, lalu diperluas ke tablet / PC.
> Catatan: komentar kode merujuk `docs/UIUX_Spec.md`, tapi file itu tidak ada di repo. Dokumen ini menggantikannya.

---

## 1. Prinsip

1. **Bentuk GUI mengikuti konteks fiturnya.** Daftar (list) hanya untuk data yang memang daftar. Progres berhari-hari = lintasan ke samping. Skill = pohon. Stasiun kerja (Dapur, Kandang, Kolam) = slot kerja + pilihan resep.
2. **Satu sumber gaya: `UiKit`.** Warna, ukuran teks, radius, jarak, dan layer hanya diambil dari token UiKit. Controller tidak menulis `Color3.fromRGB` atau angka `TextSize` sendiri.
3. **Mobile-first.** Baseline layar **812 × 375 pt (HP landscape)**. Jempol kiri = thumbstick, jempol kanan = tombol lompat dan aksi. Zona itu tidak boleh tertutup GUI.
4. **Yang terlihat = yang bisa dipakai.** Tombol fitur yang belum terbuka lewat quest tidak tampil (Quest doc Bab 2).
5. **Cozy, bukan ramai.** Satu fokus per layar. Tidak ada popup yang muncul sendiri kecuali hasil aksi pemain.

---

## 2. Audit — Yang Tidak Konsisten Sekarang

| # | Temuan | Bukti di kode | Dampak |
|---|--------|---------------|--------|
| A1 | **Semua panel = satu bentuk:** `UiKit.panel` adalah sheet dengan satu `ScrollingFrame` vertikal (maks 600 × 400). Skill, Hadiah, Season, Dapur, Kandang, Kolam, Acara semuanya diisi `UiKit.header` + `UiKit.row`. | SkillController (16 row), RewardsController (Peti + Login + Season 30 hari × 2 track + Title dalam satu list), DapurController 8 row, RepeatController 12 row | GUI terasa seperti spreadsheet. Season 30 hari bisa jadi 60+ baris ke bawah. |
| A2 | **Tombol HUD campur bentuk:** Acara, Skill, Dapur tampil sebagai pil teks krem; tombol lain bulat berikon. | `UiKit.menuItem`: `MENU_ICON` tidak punya entri `AcaraButton`, `SkillButton`, `DapurButton` → jatuh ke fallback teks | Kolom kanan tidak seragam (terlihat di screenshot playtest). |
| A3 | **Warna di luar palet.** 13× `Color3.fromRGB(255, 226, 120)` (emas) dan ±40 warna lain ditulis langsung di controller. | FarmController 18, FishingController 13, HudController 9, MenuFlow 7, GarapController 7, T1Dialog 6 | Warna emas / gelap / krem beda tipis di tiap layar. |
| A4 | **Ukuran teks liar:** 20 nilai berbeda (9, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 24, 26, 28, 30, 36, 44). Ada teks **9 px** (label XP, FarmFloat) dan **11 px** (sub-teks kartu, tombol batal mancing). | `xpBarLabel.TextSize = 9` (HudController:180), `sub.TextSize = 9` (FarmFloat:155), `cancel.TextSize = 11` (FishingController:105) | Tidak terbaca di HP. Aturan UiKit sendiri bilang minimal 13. |
| A5 | **Radius sudut 11 nilai** (4, 5, 7, 8, 10, 12, 14, 16, 18, 20, bulat). | grep `CornerRadius` | Kartu dan tombol tidak terasa satu keluarga. |
| A6 | **Target sentuh tidak konsisten.** `UiKit.TOUCH = 50` dipakai sebagai patokan, padahal di HP ukuran itu memakan layar. Di sisi lain tombol `Tunjukkan` di quest tracker cuma 74 × **18** (di bawah batas bisa dipencet). | UiKit.luau:45, QuestController:320 | Elemen besar menutupi dunia; elemen terlalu kecil susah dipencet. |
| A7 | **Layer (DisplayOrder) acak.** Panel dari `UiKit.panel` tidak punya DisplayOrder (0), sedangkan HUD = 20, jadi **HUD tampil di atas panel yang terbuka**. Banner (50) di bawah Feedback (70). HUD dan Decor sama-sama 20. | lihat tabel Bab 4.5 | Tombol HUD bisa dipencet tembus panel; urutan tumpuk tidak bisa ditebak. |
| A8 | **Tombol aksi kontekstual beda tempat.** Mancing di skala (0,8 ; 0,67), Pukul "tepi kanan", Craft melayang di atas meja, Kelola / Breeding "dekat kandang / kolam". | FishingController:424, MiningController, RanchController, PondController | Jempol harus mencari tombol yang sama di tempat berbeda. |
| A9 | **Kartu pemain di kiri bawah** (250 × 100 di HP) berada di zona thumbstick Roblox. | HudController:258 | Tertutup / ketekan saat jalan. |
| A10 | **Tombol HUD tanpa nama sama sekali.** Tombol HUD sengaja tanpa caption dan nama dititipkan ke tooltip, tapi `attachTip` sekarang fungsi kosong: tooltip tidak pernah muncul, di HP maupun PC. | UiKit.luau:1563 | Pemain tidak tahu arti ikon baru. |
| A11 | **Banyak elemen dibangun manual** (`Instance.new` Frame / TextLabel) di luar UiKit: QuestController (6 Frame, 9 TextLabel), FishingController (10 Frame), FarmController (6 + 7), MenuFlow (11 Frame), HudController (8 + 5). | tabel audit | Gaya tidak ikut berubah saat UiKit diubah. |

---

## 3. Yang Sudah Bagus — Dipertahankan

| Bagian | Kenapa dipertahankan |
|--------|----------------------|
| Palet bambu + parchment + daun (UiKit Palette), font FredokaOne | Cocok dengan map dan tema kampung. |
| Skin ForgeGUI 9-slice (panel, ribbon judul, plate bulat, close merah) dengan fallback flat | Konsisten dan aman saat gambar belum termuat. |
| `UiKit.autoScale` + `DeviceSafeInsets` | Dasar responsif yang benar, tidak mengecilkan di bawah ukuran HP. |
| Dock bawah tengah (Garap, Kolam, Hias, Tas, Pesanan) dengan plate 58 px, pindah ke kolom kanan saat portrait | Pola mobile yang benar. |
| Tap backdrop untuk menutup panel, panel slide dari bawah | Mudah satu tangan. |
| Kotak dialog `T1Dialog` (foto NPC, nama, Next, pilihan bernomor, antrean bicara) | Sudah jadi standar semua percakapan NPC. |
| `UiKit.confirm` (Batal kiri merah, Setuju kanan hijau) dan `priceChip` merah saat koin kurang | Pola transaksi sudah jelas. |
| `UiKit.tabs`, `UiKit.grid` + `UiKit.cell` (Tas, Album), `UiKit.tradeRow` (Toko NPC), `UiKit.productCard` (Toko Robux) | Bentuknya sudah sesuai kontennya. |
| Mini-game tarik (panel reel bambu), tombol Mancing bulat | Baru di-tune dan disetujui owner. |
| Banner Dimulai / Selesai (bar hitam, judul emas) | Disetujui; hanya layernya yang dirapikan. |

---

## 4. Fondasi (Token UiKit)

### 4.1 Warna

Pertahankan semua warna palet yang ada. Tambahkan token untuk warna yang sekarang ditulis langsung:

| Token baru | Nilai | Menggantikan |
|------------|-------|--------------|
| `UiKit.GOLD` | (255, 226, 120) | 13 tulisan langsung (ring tutorial, highlight, siap klaim) |
| `UiKit.GOLD_DEEP` | (240, 196, 92) | = `CAT.gold`, angka Koin |
| `UiKit.SHADE` | (30, 20, 10) | backdrop panel, bayangan |
| `UiKit.INK_DARK` | (48, 32, 20) | teks di atas krem terang |
| `UiKit.LOCKED` | (150, 150, 150) | node / slot terkunci |
| `UiKit.WATER` | (46, 104, 128) | elemen mancing / kolam |

Aturan: **tidak ada `Color3.fromRGB` di luar UiKit dan Config/UiAssets.** Selene / grep jadi cara cek.

Arti warna (sudah dipakai, dikunci):
- Hijau daun `BUTTON` = aksi utama. Tan `BUTTON_MUTED` = sekunder / tidak aktif. Merah `RED` = batal / kurang koin.
- `GOLD` = siap diklaim, highlight tutorial, hadiah.
- Warna kategori `CAT` hanya untuk stripe kartu dan badge (tanaman hijau, ikan biru, alat terakota, dekor ungu, uang emas).

### 4.2 Tipografi (satu font: FredokaOne)

| Token | Ukuran | Dipakai untuk |
|-------|--------|---------------|
| `TEXT_DISPLAY` | 36 | Judul banner, angka besar (level up) |
| `TEXT_TITLE` | 21 | Judul ribbon panel (sudah) |
| `TEXT_HEADING` | 18 | Judul seksi, nama kartu besar |
| `TEXT_BODY` | 16 | Baris list, tombol (sudah) |
| `TEXT_SMALL` | 14 | Teks dialog, deskripsi |
| `TEXT_CAPTION` | 12 | Sub-teks, label kecil. **Batas bawah.** |

Ukuran 9 dan 11 dilarang. Nilai 13, 15, 17, 19, 20, 22 dipetakan ke token terdekat.

### 4.3 Jarak & Radius

- Jarak: **4 / 8 / 12 / 16 / 24 px** saja.
- Radius: `R_SM = 8` (chip, badge), `R_MD = 14` (tombol, kartu, sel grid), `R_LG = 20` (panel flat, kotak besar), `R_ROUND` (bulat penuh: plate, avatar, node).

### 4.4 Target Sentuh

Keputusan owner 2026-11-22: **jangan terpaku 44 px.** Di HP elemen 44–50 px menutupi dunia. Target sentuh dibuat sekecil yang masih nyaman dipencet:

| Token | Ukuran | Dipakai untuk |
|-------|--------|---------------|
| `UiKit.TOUCH_MIN` | **24 px** | Batas bawah mutlak: ikon tutup kecil, link `Tunjukkan`, ikon info, chip filter kecil |
| `UiKit.TOUCH` | **32 px** | Standar semua tombol: tombol di baris / kartu, Next, pilihan dialog, tab, stepper (sekarang `TOUCH = 50` → 32) |
| `UiKit.TOUCH_CTA` | **40 px** | Satu aksi utama per layar: Tingkatkan, Klaim Semua, Masak, Ambil Semua |

- Tombol HUD yang sudah ada **tetap** (dock 58 px, kolom menu 50 px, Tombol Aksi 84 px): itu bukan tombol di dalam panel, dan ukurannya sudah disetujui.
- Elemen yang terlihat kecil boleh punya area tap sedikit lebih besar dari gambarnya (padding transparan), tapi tidak lebih dari 32 px.
- Jarak antar target sentuh ≥ 6 px.

### 4.5 Layer (DisplayOrder) — satu tabel untuk semua

| Layer | DisplayOrder | Isi |
|-------|--------------|-----|
| Dunia | −2 … −1 | Float di atas petak, marka lahan, label world |
| Aksi | 10 | Tombol aksi kontekstual (Mancing, Pukul, Kelola, Breeding), ring ritme |
| HUD | 20 | Mata uang, kartu pemain, dock, kolom menu, quest tracker |
| Panduan | 30 | Panah dunia, hint bar |
| Panel | 40 | Semua `UiKit.panel` / sheet (sekarang 0, **di bawah HUD**) |
| Coachmark | 50 / 55 | Overlay gelap / ring + bubble (harus di atas panel) |
| Toast & hadiah | 60 | `rewardPopup`, toast Side Quest, feedback |
| Banner | 80 | Dimulai / Selesai |
| Modal | 100 | `UiKit.confirm` |
| Dialog NPC | 120 | T1Dialog |
| Fade | 150 | FadeManager |
| Menu awal | 200+ | MenuFlow, loading |

Semua angka ini jadi konstanta di UiKit (`UiKit.LAYER.PANEL`, dst.). Tidak ada angka DisplayOrder di controller.

### 4.6 Ikon

- **Setiap tombol HUD wajib punya ikon.** Ikon baru yang dibutuhkan: `acara` (kalender + lampion), `skill` (daun / pohon), `dapur` (tungku), `season` (padi + matahari), `quest` (gulungan + tanda seru). Dibuat dengan gaya ForgeGUI yang sama (256 × 256, transparan).
- Fallback pil teks hanya boleh muncul saat gambar belum termuat, bukan sebagai desain.

---

## 5. HUD (mobile landscape)

```
┌─────────────────────────────────────────────────────────────────────┐
│ [Roblox]      [● Koin 150] [✿ Bunga 10]                  (Acara)   │
│ Quest tracker                                              (Skill)   │
│  ★ Main: Kolam Kakek                                       (Hadiah)  │
│   · Bangun kolam  [Tunjukkan]                              (Warga)   │
│  · Side: Bibit Kedua                                       (Toko)    │
│                                                            (≡ Atur)  │
│                                                                      │
│ ░░░░░░░░░░░░                                         [Aksi 84px]     │
│ ░ thumbstick ░          (Garap)(Kolam)(Hias)(Tas)(Pesanan)   [Jump] │
└─────────────────────────────────────────────────────────────────────┘
```

| Zona | Isi | Aturan |
|------|-----|--------|
| Atas tengah | Koin, Bunga | Tetap seperti sekarang. |
| Kiri atas | Quest tracker | Main paling atas (ikon ★, warna emas), lalu Side. Maks 3 baris + `+N lainnya` (sudah). Satu baris = satu area tap (tinggi baris, ±32 px) yang membuka Quest Log; `Tunjukkan` jadi tombol ikon panah 24 × 24 di ujung baris Main. |
| Kanan atas | Kolom menu bulat 50 px | Hanya ikon. Di HP kolom bisa dilipat (sudah). Urutan tetap: Acara, Skill, Hadiah, Warga, Toko, Atur. Dapur **dipindah** dari kolom (lihat Bab 6.6). |
| Bawah tengah | Dock 58 px | Tetap. Hanya tombol yang sudah terbuka lewat quest yang tampil. |
| Kanan bawah, di atas Jump | **Satu slot Tombol Aksi** 84 px | Semua aksi kontekstual (Mancing, Pukul, Kelola Kandang, Breeding, Craft) memakai slot yang sama, ikon berganti sesuai konteks. Satu aksi saja pada satu waktu (yang terdekat). |
| Kiri bawah | Thumbstick | **Kosong.** Kartu pemain (foto, nama, XP, buff) pindah ke **kiri atas di atas tracker** dalam versi ringkas (foto + level + bar XP), buff jadi chip kecil di sampingnya. Kartu penuh dibuka dengan tap. |

**Label tombol baru (pengganti hover di HP):** saat tombol HUD pertama kali muncul (dibuka quest), tombol itu memantul dan menampilkan label nama selama 4 detik. Tekan lama (0,5 detik) di HP = tooltip nama, hover di PC = tooltip nama (`attachTip` diisi lagi).

### 5.1 Bubble Dialog NPC (T1Dialog) — dibuat lebih ringkas

Sekarang (T1Dialog.luau): tinggi tetap **112 px**, lebar 92% layar sampai 520 px, foto 50 px dengan ring ±72 px, bingkai bambu memakan ±34 px di kiri dan kanan, tombol Next 92 × 34, tombol pilihan 40 px, jarak dari bawah 16 px. Di HP landscape (375 px tinggi) kotak ini memakan hampir sepertiga layar dan menutupi karakter / petak yang sedang diajarkan.

**Dua varian, satu komponen:**

| | **Bubble Instruksi** (langkah tutorial / quest) | **Bubble Percakapan** (beat NPC, Next / pilihan) |
|---|---|---|
| Kapan | Baris yang menjelaskan apa yang harus dilakukan; berganti otomatis (animasi minimize lalu muncul lagi) saat langkah berubah | Ngobrol dengan NPC, cutscene jual, hadiah, Mulai / Selesai quest |
| Tinggi | Otomatis, **min 48 – maks 72 px** (1–2 baris) | Otomatis, **min 64 – maks 96 px** (maks 3 baris) |
| Lebar | maks **400 px** / 55% layar | maks **440 px** / 60% layar |
| Foto NPC | 32 px (ring 40) | 40 px (ring 48) |
| Nama | 12 px, satu baris dengan teks | 13 px di atas teks |
| Teks | 14 px | 14 px |
| Tombol | Next 64 × 32 = **menutup** bubble. Tidak wajib untuk lanjut ke langkah berikutnya | Next 64 × 32 di kanan bawah; pilihan bernomor 32 px tinggi |
| Bingkai | Skin bambu tipis (`SliceScale` ±0,5, inset 12 px) | Skin bambu tipis (inset 14 px) |
| Posisi | Atas tengah, di bawah mata uang (tidak menutupi petak / karakter di tengah bawah) | Bawah tengah, **di atas dock** (dock 58 + 8 px), tidak menutupi Tombol Aksi |
| Teks panjang | Lebih dari 2 baris = pecah jadi 2 baris instruksi (aturan Naskah ≤ 110 karakter tetap) | Lebih dari 3 baris = pecah dengan Next |

Aturan tambahan:
- **Bubble Instruksi tidak pernah hilang sendiri** (keputusan owner 2026-11-22). Saat langkah berubah, bubble lama **menutup dengan animasi minimize** (seperti jendela aplikasi di-minimize: mengecil + memudar ke arah foto NPC, ±0,18 detik), lalu bubble baru **membesar dari titik yang sama** (±0,22 detik, sedikit memantul). Tidak ada jeda kosong di antaranya. Progres tutorial tidak menunggu Next.
- **Hanya Next yang menutupnya.** Setelah ditutup, bubble muncul lagi saat langkah berikutnya mulai, dengan teks langkah itu.
- Setiap langkah tutorial wajib punya baris instruksi (Naskah Bab 1), supaya teks di bubble selalu sesuai langkah yang sedang berjalan.
- Saat Bubble Percakapan tampil, Bubble Instruksi disembunyikan dan kembali setelahnya kalau langkahnya masih sama.
- Selama mancing (`FishingActive`) keduanya tersembunyi (sudah).
- Layer tetap 120 (Bab 4.5). Antrean bicara T1Dialog tetap (satu baris pada satu waktu).

---

## 6. Pola Layout per Konteks

Empat bentuk sheet di UiKit, dipilih sesuai konten:

| Bentuk | Kapan | Ukuran HP | Ukuran PC |
|--------|-------|-----------|-----------|
| **Sheet List** (`UiKit.panel` sekarang) | Data yang memang daftar: transaksi, pengaturan, daftar pemain | 88% × 86%, maks 600 × 400 (sudah) | sama |
| **Sheet Grid** | Koleksi barang: Tas, Album, katalog Hias | sama | sama |
| **Sheet Lebar** (baru) | Konten yang butuh ruang horizontal: lintasan Season, pohon Skill, stasiun kerja | penuh layar di dalam safe area, ribbon + close tetap | maks 1000 × 560 |
| **Drawer Detail** (baru) | Detail 1 benda (skill, resep, item, hewan) di atas sheet | dari bawah, tinggi 45% | dari kanan, lebar 320 |

### 6.1 Hadiah (tombol ★) — sekarang 1 list panjang → 3 tab

Tab di atas: **Harian · Musim · Koleksi**. Sheet Lebar.

**Tab Harian**
- *Login Mingguan:* 7 kartu ke samping (hari 7 lebih lebar dengan Bunga). Kartu yang sudah diambil diberi stempel "Diambil"; hari ini menyala emas dan bisa ditap.
- *Peti Main:* satu bar waktu horizontal 0–60 menit dengan 5 peti di titik 10 / 20 / 30 / 45 / 60. Isi bar = menit main hari ini. Peti yang sudah tercapai bergoyang dan bisa ditap.

```
 Login Minggu Ini
 [H1 ✓][H2 ✓][H3 ●][H4  ][H5  ][H6  ][   H7  ✿   ]
 Main Hari Ini  ━━━━━━━━━━━●───────────────────────
               10🎁    20🎁    30🎁      45🎁      60🎁
```

**Tab Musim (Season Pass) — lintasan ke samping** (mockup: Bab 10)
- Header: nama musim, sisa hari, status Premium.
- Dua jalur horizontal: **Gratis** (atas) dan **Premium** (bawah, bergembok sampai dibeli). Kolom = hari 1–30.
- Garis progres melewati semua node; node hari ini ditandai dan **auto-scroll ke hari ini** saat dibuka.
- Node 64 × 64: ikon hadiah + angka. Status: terkunci (abu), siap (emas berdenyut), diambil (centang). Hari milestone (7, 14, 21, 30) node lebih besar.
- Tap node siap = klaim. Tombol `Klaim Semua` di kanan bawah saat ada ≥ 2 siap.
- Scroll horizontal dengan jempol; jalur tetap dua baris di HP landscape maupun portrait.

```
 Musim Panen S1 · sisa 18 hari                         [Premium 150✿]
        1     2     3  …   7      …  12(hari ini) …          30
 Gratis (✓)━━(✓)━━(●)━━ … [✿✿] ━━ … ━(●)━ ───────────── [🎁 BESAR]
 Premium (🔒)  (🔒)  (🔒)   [🔒]       (🔒)                  [🔒]
                                                       [Klaim Semua]
```

**Tab Koleksi**
- *Title:* grid kartu badge (sudah / belum, syarat di bawah). Tap = drawer detail + "Pakai Title".
- *Peti Bunga:* satu kartu besar peti dengan jumlah, tombol Buka (animasi peti terbuka, hadiah masuk ke counter Bunga).
- *Milestone Album* (25 / 50 / 75 / 100%) pindah dari tab Album ke sini sebagai lintasan horizontal pendek.

### 6.2 Skill — sekarang list → Pohon Skill

Mockup: Bab 10. Konsep visual: **pohon beringin kampung** (ikon alun-alun). Batang di bawah, 6 dahan = 6 cabang (Bertani, Mancing, Ternak, Tukang, Masak, Sosial), skill = node di sepanjang dahan.

- Sheet Lebar. Kanan atas: chip **SP tersedia**.
- **HP landscape:** 6 dahan berjajar ke samping (bisa di-scroll horizontal), tiap dahan vertikal dengan node dari bawah ke atas sesuai urutan di Config/Skills. Garis dahan menyala sampai node tertinggi yang sudah dibeli.
- Node bulat 64 px: ikon skill + 5 titik level di bawahnya. Status: belum (krem pudar), bisa naik (ring emas berdenyut bila SP ≥ 1), maks (bingkai emas penuh).
- Tap node = **Drawer Detail**: nama, efek sekarang → efek level berikutnya (contoh "Tumbuh +4% → +6%"), biaya 1 SP, tombol **Tingkatkan** (40 px, `TOUCH_CTA`). Tidak ada tombol beli di node langsung (hindari salah pencet).
- Header tiap dahan: ikon cabang + nama + total level (contoh "Bertani 7/20").

```
                         Pohon Skill                          [SP 3]
   Bertani    Mancing    Ternak    Tukang    Masak    Sosial
     (◉)        (○)        (○)                             
     (◉)        (◉)        (○)       (○)       (○)            
     (◉)        (◉)        (◉)       (◉)       (◉)       (○)
     (◉)        (◉)        (◉)       (◉)       (◉)       (◉)
      ┃          ┃          ┃         ┃         ┃         ┃
      ┗━━━━━━━━━━┻━━━━━━━━━━┻━━━━ batang ━━━━━━━┻━━━━━━━━━┛
```

> Data skill sekarang tidak punya prasyarat (semua bisa dibeli bebas). Garis dahan di sini **visual saja**. Lihat Bab 9 #1.

### 6.3 Dapur + Warung + Makan — stasiun kerja

Sheet Lebar dengan tab **Masak · Warung**.

**Tab Masak**
- Strip atas: **kartu slot** (1–3 sesuai Tier). Isi: foto olahan, kualitas, timer melingkar, tombol `Ambil` saat selesai. Slot terkunci = kartu gembok "Tier 2".
- Bawah: **grid resep** (kartu 96 × 112): foto olahan, ikon buff (Tani / Pancing / Tukang / Tebang), bahan sebagai ikon kecil dengan `punya/butuh` (merah kalau kurang). Filter chip di atas grid: Semua / per buff.
- Tap resep = Drawer Detail: bahan, waktu, perkiraan kualitas, tombol **Masak** (masuk slot kosong).

**Tab Warung**
- Kartu etalase (slot Warung) besar dengan olahan yang dipajang + harga.
- Pilih olahan dari Tas (grid kecil olahan saja).
- Riwayat penjualan terakhir (3 baris) di bawah.

**Makan:** dari Tas (drawer item olahan → tombol `Makan`) dan dari Drawer Detail resep. Buff aktif tampil sebagai chip berikon + timer di samping kartu pemain (HUD).

**Tombol HUD Dapur dihapus** dari kolom kanan: Dapur dibuka dari Tombol Aksi saat dekat Tungku (sama seperti Kandang / Kolam / Meja Crafting). Supaya pemain tidak bingung, lihat Bab 9 #3.

### 6.4 Meja Crafting

Sheet Lebar. Grid kartu resep bahan olahan dalam bentuk **rumus visual**: `[2 Kayu] → [1 Papan]`, jumlah yang dimiliki di bawah tiap bahan. Tombol `×1` dan `×10` di kartu (32 px). Kartu yang bahannya kurang = pudar, angka merah.

### 6.5 Kandang (Ternak) dan Kolam

**Kandang** — Sheet Lebar.
- Atas: kartu kandang (jenis, level, kapasitas `6/10`, tombol `Upgrade`).
- Tengah: **grid kartu hewan** (foto hewan, 3–5 titik jatah pakan, jumlah produk menumpuk, timer siklus melingkar, badge Mood Hujan).
- Bawah: dua tombol 40 px (`TOUCH_CTA`): **Isi Pakan Semua** dan **Ambil Semua**. Beli hewan = kartu `+` terakhir di grid.

**Kolam** — Sheet Lebar.
- Kiri: kartu kolam (tier, kapasitas `7/10`, upgrade, instant Bunga).
- Kanan atas: **slot breeding** = 2 lubang indukan + 1 anak, timer di tengah. Tap lubang = pilih ikan sejenis dari grid.
- Kanan bawah: grid ikan di kolam (foto + ukuran).

### 6.6 Acara (Repeat)

Sheet Lebar, tab **Hari Ini · Kalender**.
- **Hari Ini:** 3 kartu Gerobak Kaget (slot Bibit / Dekor / Langka) dengan countdown restock di header; kartu status Pasar Malam (buka / tutup + sisa waktu); kartu Kerja Bakti (progres kampung % + poin pribadi `x/20`).
- **Kalender:** strip bulan horizontal, 5 event sebagai pita warna; event aktif menyala dengan sisa hari; tap = drawer detail (Pesanan Tamu, hadiah).

### 6.7 Pesanan (Order Villager)

Sheet Grid. 3 kartu Harian + 1 kartu Mingguan (lebih lebar, bingkai emas). Kartu: foto NPC peminta, barang yang diminta sebagai ikon `punya/butuh`, hadiah, tombol `Setor` (aktif bila cukup) dan ikon `Ganti` (reroll 2 Bunga, dengan konfirmasi).

### 6.8 Quest Log (baru)

Dibuka dari tap tracker. Sheet List dengan tab **Main · Side**.
- **Main:** kartu besar quest aktif (pemberi + foto, langkah dengan centang, hadiah, `Tunjukkan`). Di bawahnya lintasan kecil horizontal Main Quest yang sudah selesai / berikutnya (judul berikutnya disamarkan "???" sampai levelnya).
- **Side:** list baris biasa (cocok sebagai list).

### 6.9 Yang tetap memakai bentuk sekarang

| Panel | Bentuk | Perubahan kecil saja |
|-------|--------|----------------------|
| Tas (Inventory) | Sheet Grid + tab | Tap item = Drawer Detail (info, `Makan` untuk olahan). |
| Album (Book) | Sheet Grid + tab | Tab Hadiah pindah ke Hadiah > Koleksi. Header + bar % Album. |
| Toko NPC (Shop) | Sheet List + tradeRow | Foto NPC kecil di ribbon. Tombol row 32 px. |
| Toko Robux (Store) | productCard + tab samping | Tidak berubah. |
| Warga (Social) | Sheet List | Baris pemain dapat foto headshot; Gestur jadi 4 tombol ikon bulat di atas list. |
| Atur (Settings) | Sheet List + switch | Tidak berubah. |
| Hias (Decor) | Mode bangun | Tidak berubah di versi ini. |
| Mancing | Panel reel | Tidak berubah (baru disetujui). |

---

## 7. Komponen UiKit yang Perlu Ditambah

| Komponen | Untuk |
|----------|-------|
| `UiKit.sheet(name, title, kind, onClose)` dengan `kind = "list" | "grid" | "wide"` | Menggantikan `UiKit.panel` secara bertahap (`panel` tetap ada = `sheet(..., "list")`). Set DisplayOrder `LAYER.PANEL`. |
| `UiKit.drawer(parent, onClose)` | Drawer Detail (bawah di HP, kanan di PC). |
| `UiKit.track(parent, columns, lanes)` + `UiKit.trackNode(...)` | Season, Login, Peti Main, Milestone Album, lintasan Main Quest. Auto-scroll ke kolom aktif. |
| `UiKit.treeBranch(parent, header)` + `UiKit.treeNode(...)` | Pohon Skill (node + titik level + garis). |
| `UiKit.slotCard(parent, def)` | Slot Dapur, Breeding, etalase Warung, Gerobak Kaget (foto, timer melingkar, tombol). |
| `UiKit.timerRing(parent, size)` | Timer melingkar di slot / hewan. |
| `UiKit.recipeCard(parent, def)` | Resep Dapur, Crafting (rumus visual, `punya/butuh`). |
| `UiKit.filterChips(parent, defs, onSelect)` | Filter di atas grid. |
| `UiKit.actionButton(iconKey, onPress)` | Satu slot Tombol Aksi kontekstual (Bab 5). |
| `UiKit.LAYER`, `UiKit.TEXT_*`, `UiKit.R_*`, token warna baru | Bab 4. |

---

## 8. Urutan Kerja (usulan)

| Tahap | Isi | Risiko ke yang sudah bagus |
|-------|-----|----------------------------|
| UI-1 Fondasi | Token warna / teks / radius / layer di UiKit; ganti angka liar di controller; target sentuh 24 / 32 / 40 (Bab 4.4); tracker tap area; bubble dialog ringkas (Bab 5.1); layer panel di atas HUD | Tidak ada perubahan bentuk, hanya konsistensi |
| UI-2 HUD | Ikon Acara / Skill / Hadiah; kartu pemain keluar dari zona thumbstick; satu slot Tombol Aksi; label tombol baru + tekan lama | Dock dan kolom tetap |
| UI-3 Hadiah | Tab Harian / Musim / Koleksi, lintasan Season | Logika server tidak berubah |
| UI-4 Skill | Pohon Skill + drawer | – |
| UI-5 Stasiun | Dapur + Warung, Crafting, Kandang, Kolam | – |
| UI-6 Lainnya | Acara, Pesanan, Quest Log | – |

Setiap tahap: screenshot HP landscape (812 × 375) dan PC (1920 × 1080) sebagai "Playtest USER".

---

## 9. BUTUH KEPUTUSAN OWNER

1. ~~**Prasyarat skill.** Mau ditambah syarat, atau garis pohon cuma visual?~~ **DIJAWAB (Skill Tree Bab 2): ada prasyarat nyata.** Player Lv, skill tertentu di Lv tertentu, OR di Capstone, dan total level di Tetangga Baik. Garis dahan menyala sampai node tertinggi yang dibeli.
2. **Kartu pemain pindah ke kiri atas** (keluar dari zona thumbstick). Setuju?
3. **Tombol Dapur di HUD dihapus**, Dapur dibuka lewat Tombol Aksi dekat Tungku (seperti Kandang / Kolam / Meja Crafting). Setuju, atau tetap ada tombol HUD setelah M6?
4. **Aset ikon baru** (acara, skill, dapur, season, quest) dibuat di ForgeGUI dengan gaya yang sama. Setuju?
5. **Satu slot Tombol Aksi** untuk Mancing / Pukul / Kelola / Breeding. Craft tetap melayang di atas meja (keputusan owner sebelumnya), atau ikut slot yang sama?

---

## 10. Mockup (acuan visual)

Canvas: **Kampoeng Tedoeh — Mockup Season Pass & Pohon Skill (HP)**
https://claude.ai/artifact/UuRgfWQfZCVCxA2iUQDZhf

| Artboard | Isi | Status |
|----------|-----|--------|
| Hadiah › Musim (Season Pass), 812 × 375 | Tab Harian / Musim / Koleksi; dua jalur horizontal Gratis + Premium (bergembok); kolom per hari, hari ini disorot; node emas = siap klaim, centang = diambil, label BESAR = milestone; `Klaim Semua` kanan bawah; tombol Premium 150 Bunga di header | Disetujui owner 2026-11-22 sebagai acuan Bab 6.1 |
| Pohon Skill, 812 × 375 (interaktif) | 6 dahan dari batang bawah, node 44 px (implementasi: node 40, tombol sesuai Bab 4.4) dengan pil level `x/5`, badge `+` bila bisa naik, bingkai emas = maks; dahan menyala hijau sampai node tertinggi yang dibeli; chip SP kanan atas; tap node = drawer detail (efek sekarang → berikutnya, Biaya 1 SP, Tingkatkan 50 px) | Disetujui owner 2026-11-22 sebagai acuan Bab 6.2 |

Aturan pakai mockup:
- Angka di mockup mengikuti config saat ini (Season: 50 Koin/hari, Bunga hari 7/14/21/30; Premium 40 Koin/hari, Bunga hari 10/20/30. Efek skill: Bab 4.5 gameplay). Kalau angka di config berubah, GUI ikut config, bukan mockup.
- Ukuran tombol di mockup (44 / 50 px) dibuat sebelum keputusan target sentuh. Implementasi ikut Bab 4.4: 24 / 32 / 40 px.
- Font di mockup = Fredoka (Google Fonts) sebagai pengganti FredokaOne; di Roblox tetap `UiKit.FONT`.
- Garis dahan Pohon Skill masih visual saja sampai keputusan prasyarat (Bab 9 #1).
- Implementasi memakai komponen Bab 7 (`UiKit.track` / `trackNode`, `UiKit.treeBranch` / `treeNode`, `UiKit.drawer`) dan token Bab 4, bukan menyalin HTML mockup.
