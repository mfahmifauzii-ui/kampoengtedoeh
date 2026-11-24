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
| COACHMARK | 50 / 60 | Ring + bubble. Spotlight (satu lubang, 60 % gelap) hanya untuk tombol HUD tetap pada langkah pertama (4.6). Angka 60 % dipakai bersama toast (A-72). |
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
│                                                    (≡ Kolam, Atur)   │
│                                                                       │
│ ░░░░░░░░░░░░            [chip umpan · status mancing]   [Aksi 84px]   │
│ ░ thumbstick ░  (Garap)(Hias)(Tas)(Quest)                        [Jump]│
└──────────────────────────────────────────────────────────────────────┘
```

| Zona | Isi | Ukuran / aturan (kode UI-B12) |
|------|-----|-------------------------------|
| Atas tengah | Koin, Bunga | Tetap |
| Atas tengah, di bawah mata uang | Toast stack | Lihat 4.2 |
| Kiri atas | Kartu pemain ringkas (foto + level + bar XP) + chip buff, lalu tracker | Kartu pindah dari kiri bawah ✔ K-34. Tracker lebar 200 px, mulai 118 px dari atas, tinggi maks min(200 px, 25% layar), maks 3 baris + "+N lainnya", teks krem outline gelap tanpa panel, baris membungkus teks |
| Kanan atas | Kolom menu bulat 50 px, ikon saja, bisa dilipat di HP | Urutan: Acara, Skill, Hadiah, Warga, Toko, **Kolam**, Atur. Kolam ada di sini sebagai ubin (K-104). Dapur **tidak** di sini (✔ K-34) |
| Bawah tengah | Dock 58 px, 10 px dari bawah, **maks 4 tombol** | Garap, Hias, Tas, **Quest** (ikon gulungan, K-109; dulu Pesanan; owner 2026-11-24) — hanya yang sudah terbuka. **Kolam tidak ada di dock** (K-104, ubin ≡ dan slot Aksi). **Dapur tidak ada di dock** (K-102). |
| Kanan bawah, slot Aksi | Satu tombol Aksi 104 px per objek; hanya satu yang tampil (aturan 4.7) | **Kolam** dekat kolam sendiri (membuka panel Kolam, K-104); **Masak** dekat Tungku sendiri (panel Dapur); **Pasang Tungku** saat Tier 1 belum berdiri dan Tungku ada di tas (K-102) |
| Zona konteks (di atas dock, tengah) | Status memancing + chip umpan | Satu tombol di atas dock; tombol Batal berlabel 64×32 px |
| Kanan bawah, di atas Jump | **Satu slot Tombol Aksi** | Mancing / Pukul / Bubu / Kelola Kandang / Kolam / Masak / Pasang Tungku — satu aksi, yang terdekat (4.7, K-104). Craft masih melayang di atas meja |
| Kiri bawah | Thumbstick | **Kosong** |

Margin layar 12, gap 8.

**Label tombol baru:** saat tombol HUD pertama kali muncul (dibuka quest), tombol memantul + label nama 4 detik. Tekan lama 0,5 dtk (HP) / hover (PC) = tooltip nama (`attachTip`, sekarang kosong → R3.1).

### 4.7 Slot Aksi: satu tombol, prioritas (K-104)

Satu slot Aksi di kanan bawah. Tiap objek yang bisa dipakai punya tombol Aksi sendiri (posisinya tetap), tetapi **hanya satu yang tampil**. Aturan (`src/client/AksiSlot.luau`):

1. Objek dalam jangkauan masing-masing mendaftar dengan jarak. Yang **terdekat** menang.
2. Jarak sama (selisih ≤ 1,5 studs): menang objek yang dipakai **quest yang dilacak** (langkah aktifnya menunjuk objek itu, mis. Tungku di M6).
3. Masih sama: prioritas tetap, angka kecil menang:

| Prioritas | Aksi | Objek | Tombol muncul saat |
|-----------|------|-------|---------------------|
| 1 | Pancing | spot ikan | pancing sudah diberi, tidak sedang memancing, ada spot dalam jangkauan |
| 2 | Pukul | node tambang | ada node dalam jangkauan (hitung mundur saat habis) |
| 3 | Bubu | sungai / bubu sendiri | Ambil bubu siap, atau Pasang di sungai |
| 4 | Kelola | kandang sendiri | dalam jangkauan kandang |
| 5 | Kolam | kolam sendiri | dalam jangkauan kolam (membuka panel Kolam) |
| 6 | Masak / Pasang Tungku | Tungku sendiri / lahan | dekat Tungku (12 studs), atau Tungku ada di tas dan belum ada dapur |

Craft Meja Crafting tetap melayang di atas meja (bukan slot ini).

### 4.1 Portrait (390×844)

Dock pindah ke kolom kanan. Toast turun di bawah tracker, lebar 200 px. Kolom menu dilipat default.

### 4.2 Toast — satu komponen, satu gaya, satu tempat (T0, aturan GUI TUNGGAL)

Ini satu-satunya aturan toast. Modul lain tidak boleh membuat label hint sendiri.

- **Satu anchor:** `UiKit.toastStack` (`ToastStack` di HUD). X tengah layar, Y = bawah CurrencyBar + 12 px (K-53). Tidak mengikuti bubble coachmark, tidak menutupi dock.
- **Satu gaya:** pill krem (`UiKit.toastChip`, parchmentBox). Tinggi dari teks terukur, min 40 px.
- **Lebar:** min(50% layar, ruang antara tracker kiri & kolom kanan); portrait sempit = lebar tracker.
- **Tiga jenis (kind):**
  1. **transient** — `HudController.Toast(text)`: hilang sendiri tiap 1,8 dtk, fade 0,25 dtk, maks 2 tampil (`UiKit.TOAST_MAX_VISIBLE`), sisanya antre (maks 5; yang paling lama dibuang).
  2. **pinned** — `HudController.SetPinned(key, template, n?, N?)`, `UpdatePinned(key, n, N)`, `ClearPinned(key)`. Tidak pernah dibuang, tidak hilang sendiri, tidak dihitung ke batas 2, selalu di atas transient. Hanya `ClearPinned` yang menghapus. Token `{n}` dan `{N}` di template diisi dari n dan N; tanpa nilai tampil `?` (tidak pernah teks mentah). Update sinkron pada event yang mengubah progres (tanpa polling); chip dirender ulang tanpa fade. `PinGuide`/`UnpinGuide` = pinned dengan key `"guide"`.
  3. **dismissible** — `HudController.ToastDismissible(key, text)`, `ClearDismissible(key)`. Gaya sama + tombol **Ok** = tombol UiKit standar dengan token `TOUCH` (32 px, 3.4; owner 2026-11-24, menggantikan "44 px"). Tinggi chip minimum = `TOUCH` + 2 × padding 8 px (48 px). Tetap sampai di-Ok atau dibersihkan kode.
  4. **Naik level (K-89, 2026-11-24):** "Naik ke Level n!" lalu satu baris "Terbuka: …" per buka kunci, berurutan, satu chip sekaligus di satu slot. Lama tampil per chip: 1,8 dtk + 0,05 dtk per karakter, maks 5 dtk. Banner "LEVEL n!" besar tetap terpisah.
- **Urutan:** pinned di atas; transient terbaru di atas di antara transient. Semua di satu stack.
- **Yang dilarang:** label hint kedua di modul mana pun. Teks instruksi/hint wajib lewat stack.
- **Bubble coachmark:** pil cokelat sudah dihapus (T0). Yang tersisa hanya panah kuning dan ring/outline. Teks langkah lewat pinned `coach`.
- **Peta permukaan teks (T0, hasil audit):**

| Permukaan | Sekarang | Alasan / status |
|---|---|---|
| GuideUI "Hint" (langkah tutorial dan first-loop) | pinned `guidehint` | rerouted |
| Coachmark pil cokelat | pinned `coach` (panah tetap) | rerouted |
| Tutorial garap_5 / tanam_5 | pinned `guide` | sudah (MS-2) |
| Garap mode line (`GarapUI/Hint`) | pinned `garapHint` | rerouted |
| Decor mode line (`DecorUI/Hint`) | pinned `decorHint` (saat DecorUI aktif) | rerouted |
| Tip kartu bibit (FarmController `popupTip`) | transient toast | rerouted (sebelumnya pil cokelat 1,6 dtk) |
| Bibit habis (`farm.no_seed`, HudController Notify) | dismissible `seed_out` (Ok) | T3 (K-72): tetap sampai Ok atau setelah `shop.bought_seed`; tidak ada gelap, tidak memblokir joystick |
| Status Memancing (`FishingController` statusFrame) | **slot tetap sendiri** di strip bawah, cream | bukan toast: status hidup ("Menunggu…", Cancel) selama mancing; tidak pernah di stack. Posisi = `stripPosition()` (strip bawah). Tidak menutupi dock/Aksi belum diverifikasi di Play (lihat 09 T0) |
| Banner bab (BannerController) | tetap | banner penuh, bukan instruksi |
| Tanda "!" pemberi quest (QuestOfferController) | tetap | marker dunia, bukan teks instruksi |
| Angka + floating (FeedbackController) dan KualitasBanner | tetap | umpan balik sesaat, bukan instruksi |
| Dialog NPC (T1Dialog) | tetap | dialog penuh |

- **Bubble Instruksi / coachmark:** hanya untuk langkah pertama. Tidak ada GuideUI "Hint" lagi; `TOAST_AVOID` kosong.
- Banner LEVEL n, reward popup, dan efek terbang **bukan** toast (K-38).

Status T0 (06 Bab 18): API pinned + dismissible dan hitungan garap_5 event-driven = DONE-CODE. Reroute GuideUI Hint, brown pill coachmark, dan statusFrame Memancing = TODO.

### 4.3 Bubble Dialog NPC (`T1Dialog`)

- **Menghadap saat bicara (K-106, owner 2026-11-24):** NPC menoleh ke pemain 0,35 dtk saat bicara dimulai, lalu kembali ke posisi dan arah semula saat bicara selesai (tutup, lepas, respawn, pemain keluar). Dilakukan server, jadi semua pemain melihat. Hanya rotasi, tidak pindah.
n- **MS-2 (2026-11-23):** bubble NPC tutorial (`T1Dialog`) berada di atas dock: `T1Dialog.DOCK_CLEAR` = 92 px dari bawah, tidak menutupi tombol Garap atau Aksi. Ring Garap kuning bulat (tanpa gelap) saat garap_5. Lihat docs/03 Bab 4.2c.

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

### 4.5 Kartu pemain dan marker "!"

- Kartu pemain: pill "Lv n" di sebelah nama. Slot buff kosong disembunyikan. (K-53)
- Marker "!" di atas setiap pemberi quest yang menawarkan quest Tersedia atau siap diserahkan. Terlihat dari jarak jauh (`MARKER_MAX_DISTANCE` 200 studs, sejak 2026-11-23). Satu marker per pemberi. (F6)
- Quest Main dan Side yang sudah selesai langkahnya menunggu penyerahan: "!" tetap di pemberi sampai pemain bicara dan hadiah dibayar (K-93).

### 4.6 Coachmark tutorial: dua gaya sorot, satu permukaan instruksi — LOCKED (2026-11-23, batch F1)

Aturan (owner, dari video dan rekaman HP):

1. **Dua gaya sorot, dipilih dari jenis target, HANYA untuk pertama kali:**
   a) Target = **tombol HUD tetap** (dock Garap, tombol Aksi Pancing): **spotlight** = satu overlay gelap dengan **satu lubang** di sekeliling tombol.
   b) Target = **GUI mengambang atau objek dunia** (pill Tanam / Siram / Panen di atas petak, ghost Garap, NPC, tanah): **tanpa gelap**. Yang dipakai hanya outline kuning yang sudah ada (ring) dan baris instruksi.
2. **Pengulangan** (langkah yang sudah pernah dilakukan sekali): **toast saja**. Tanpa gelap, tanpa outline, tanpa bubble.
3. Overlay = **satu bidang dengan lubang**, tidak pernah kotak gelap terpisah per elemen GUI. Piece overlay tidak menelan sentuhan (`Active = false`), jadi joystick dan area sentuh kamera selalu bebas. Overlay lepas sendiri saat langkah berganti, saat langkah selesai, atau setelah 25 detik (`CoachmarkController.SPOTLIGHT_TIMEOUT`).
4. **Satu permukaan instruksi per langkah:** pertama kali = bubble coachmark; pengulangan = toast. Tidak pernah keduanya untuk teks yang sama. Toast hilang saat langkah berganti atau selesai.
5. Tombol Aksi (Pancing, Tarik, Pasang, Ambil, Panen Semua) adalah satu komponen bulat (F3).

**Klasifikasi per langkah** (id langkah = `Config/Onboarding.luau`; kolom "Dibuat di kode" = aturan yang diterapkan di F1a; kolom "Play" diisi saat verifikasi):

| Langkah (id) | Target | Gaya sorot | Pertama kali? | Permukaan | Overlay gelap | Outline | Bisa gerak | Dibuat di kode | Play |
|---|---|---|---|---|---|---|---|---|---|
| `sapa` | modal sapaan | — | ya | modal (Mulai) | tidak | tidak | tidak (modal) | ya | belum |
| `cangkul` | tombol Garap (dock HUD) | spotlight | ya | bubble | ya, satu lubang | ya | ya | ya | belum |
| `tanam` | pill Tanam di atas petak / tanah kosong | outline | ya | bubble | tidak | ya | ya | ya | belum |
| `siram` | pill Siram di atas petak | outline | ya | bubble | tidak | ya | ya | ya | belum |
| `panen_1` | pill Panen di atas petak | outline | ya | bubble | tidak | ya | ya | ya | belum |
| `garap_5` | Garap (ghost di tanah) | — | tidak (ulang) | toast | tidak | tidak | ya | belum (F2) | belum |
| `tanam_5` | pill Tanam | — | tidak (ulang) | toast | tidak | tidak | ya | belum (F2) | belum |
| `tunggu_semua` | pill Panen | — | tidak (ulang) | toast | tidak | tidak | ya | belum (F2) | belum |
| `panen_jual` | Pak Udin (NPC) | panah NPC | tidak (ulang) | toast | tidak | tidak | ya | belum (F2) | belum |
| `warung` | Pak Udin | — | — | dialog | tidak | tidak | — | ya | belum |
| `kak_fajar` | Kak Fajar (NPC) | panah NPC | — | toast + panah | tidak | tidak | ya | ya | belum |
| `mancing` (tangkapan ke-1) | tombol Aksi Pancing (HUD) | spotlight | ya | bubble | ya, satu lubang | ya | ya | ya | belum |
| `mancing` (tangkapan ke-2 dan ke-3) | tombol Aksi Pancing | — | tidak (ulang) | toast | tidak | tidak | ya | belum (F2) | belum |
| `jual_ikan` | dialog Kak Fajar | — | — | dialog | tidak | tidak | — | ya | belum |

Catatan: "Dibuat di kode = belum (F2)" berarti langkah pengulangan masih menampilkan bubble coachmark di kode; F2 menggantinya dengan toast. Kolom Play tetap "belum" sampai langkah itu dijalankan di Play.

- Cutscene yang menunggu pemain melepas kunci gerak setelah 60 detik (`Cutscene.UNTIMED_RELEASE_SECONDS`) tetap berlaku.
- Lihat juga GDD Bab 16.6.

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

- 6 dahan berjajar (Bertani, Mancing, Ternak, Tukang, Masak, Sosial), scroll horizontal di HP. K-76: selama Bantu disembunyikan, dahan Sosial tidak tampil (5 dahan). Root bawah, Cabang tengah (Bertani & Mancing: A dan B berdampingan), Capstone atas, garis dahan menyala sampai node tertinggi yang dibeli.
- Node **40 px** (`TOUCH_CTA`), jarak tier 30 px, pil level `x/5`, badge `+` bila bisa naik, bingkai emas = maks. Label nama di node: ✔ K-35 (final: ikon unik per skill, nama di drawer).
- Header dahan: ikon cabang + nama + total (`Bertani 7/20`, tampilan saja).
- Chip **SP** dan **Koin** kanan atas.
- Tap node = Drawer Detail: nama, efek sekarang → berikutnya, biaya **1 SP + Koin** (GDD 4.5.1), prasyarat yang kurang, `Efek mulai Lv 3` untuk skill bertahap, tombol **Tingkatkan 40 px**. Alasan server (`locked / noSP / noKoin / max`) tampil di drawer. Tidak ada tombol beli di node.
**Bar bawah (K-56):**
- Tombol Beli selalu terlihat; panel muat tanpa scroll di 844×390.
- Saat node ditekan muncul bar bawah tetap: nama, efek, biaya (SP + Koin), prasyarat, tombol Beli.

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
**Acara & Pasar Malam (K-57):**
- Tombol **Event** hanya tampil saat event musiman aktif. Sheet: progres, Pesanan Tamu, hadiah, hitung mundur.
- Pasar Malam: tempat di dunia, buka sesuai jadwal. Pak Kumis = NPC; bubble "Jual semua" / "Jual 1", seperti Pak Udin.
- Lempar Gelang: bar bergerak, tap untuk berhenti; zona 60/30/10% (kecil/sedang/besar); 3 lemparan per malam.

### 6.7 Pesanan (Order Villager) — Sheet Grid (UI-6)

3 kartu Harian + 1 Mingguan (lebih lebar, bingkai emas). Kartu: foto NPC, barang `punya/butuh`, hadiah, `Setor` (aktif bila cukup), ikon `Ganti` (reroll 2 Bunga, dengan konfirmasi).

### 6.8 Quest Log — satu panel, tab Main · Side · Harian · Pesanan (K-56, F5; owner 2026-11-24 butir 2–3)

Satu panel (`QuestLog`). Dibuka dari tombol **Quest** di dock bawah (tempat tombol Pesanan dulu), dari tombol **Quest** kecil di kartu pemain (pojok kanan atas kartu), dan dari tap tracker. Tombol Pesanan yang terpisah dihapus; daftar order jadi tab **Pesanan** di log.

- Tab: **Main · Side · Harian · Pesanan**. Tab Harian memuat slot Harian dan Mingguan yang masih terbuka. Tab Pesanan memuat order Villager (`OrdersController.Fill`).
- Tiap baris quest: judul, sub (langkah, "Siap diserahkan ke <pemberi>", "Temui <pemberi>", "Selesai", atau "Lv n" untuk yang belum terbuka). Tombol **Track** (atau **Lepas** bila sudah dilacak), dan **Tunjukkan** bila quest punya tujuan.
- Maks **3** quest dilacak (K-94). Main selalu dilacak. Side dan slot Harian/Mingguan dilacak lewat Track; quest yang baru ditawarkan atau diambil masuk sendiri bila ada slot.
- Kerja Bakti hanya tampil di log saat acaranya jalan (K-96).
- Grup baris: **Aktif** (berjalan dan siap diserahkan) / **Tersedia** (ditawarkan) / **Selesai** (terlipat) / **Berikutnya** (Main yang belum terbuka: "???").

### 6.8b Tracker dan panah (owner 2026-11-24 butir 3, 5, 7)

- Tracker kiri berisi baris quest yang dilacak, urutan ikut urutan Track. Baris: langkah aktif, **Siap diserahkan ke <pemberi>**, atau **Temui <pemberi>**. Baris Surat (surat yang jatuh tempo) punya tombol **Baca**. Quest S2 (Surat Pertama) saat langkahnya baca juga punya **Baca** (K-95).
- **Panah:** satu target dalam satu waktu. Di luar layar: panah di tepi layar menunjuk ke target. Di layar: label nama di atas target. Target = pemberi (siap diserahkan atau ditawarkan), atau `target` langkah di `Config/Quests`.
- Tunjukkan di log menaruh panah ke target quest itu selama 6 dtk.

### 6.9 Papan Hari Ini (baru, ✔ K-34 / Penyempurnaan P-04)

Satu panel untuk hal harian: Agenda (3–5 tugas sesuai fitur, R2.2, K-80), Surat Kakek hari ini, ringkasan Order, Login hari ini, Album (%). Mengurangi jumlah tombol HUD.

R2.3 (K-74): baris Surat di tracker bisa di-tap = baca surat (event Quest S2); surat yang sama tampil lagi sebagai toast. Tombol Pesanan tampil hanya saat tutorial selesai dan fitur `agenda` terbuka (M1 mulai).

K-73: baris Bantu tidak tampil selama `Config/Features.BANTU_ENABLED = false`. K-75 (G1): selama flag mati, tombol Warga (Sosial) hanya tampil saat ada 2 pemain atau lebih di server (Mampir dan Suka butuh pemain lain). Solo tidak melihat tombol atau panel kosong. Saat flag hidup, Warga memakai gate fitur `bantu` (S6) seperti semula.

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

### 6.11 Tas: Pakai / Dipakai (K-55)

- Pancing dan umpan punya tombol **Pakai** di drawer; item terpasang diberi badge **Dipakai**.
- Chip umpan di HUD menampilkan umpan terpasang.

### 6.12 Aksi-slot: satu komponen bulat (K-55, F3)

Pancing, Tarik, Pasang (bubu), Ambil (bubu), dan Panen Semua memakai **satu komponen tombol bulat** di slot Aksi: plate 84 px dengan cincin bambu, sama seperti Pancing. Label teks ("Tarik", "Pasang", "Ambil", "Panen Semua") ada di tengah; ikon memakai plate kalau ada.

- Tarik dan Pancing tidak pernah satu tombol. Tarik hanya tampil saat ikan menarik.
- **Status:** Tarik sudah bulat (kode 0fb8032). Pasang (`BubuController`, `UiKit.button` persegi) dan Panen Semua (`FarmController`, `HarvestAllButton`, `UiKit.button` persegi) **belum** diseragamkan: tugas F3 di Roadmap.

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

Status per tugas ada di `06_Roadmap` (kolom Status). Tabel ini hanya ringkasan per tahap.

| Tahap / fitur | Isi | Status |
|---------------|-----|--------|
| UI-1 Fondasi | Token, touch tier, bubble 2 varian, layer | Selesai (belum playtest) |
| UI-2 HUD | Ikon Acara/Skill, kartu pemain, slot Aksi, label tombol | R3.1 |
| UI-3 Hadiah | 3 tab + track Season | Sebagian selesai, sisa R3.4 |
| UI-4 Skill | Pohon + drawer (ST-3) | Selesai; ikon & label R3.5 |
| UI-5 Stasiun | Dapur + Warung, Crafting, Kandang, Kolam | R3.2 |
| UI-6 Lainnya | Acara, Pesanan, Quest Log penuh, Papan Hari Ini | Papan R2.2 ada di kode; Quest Log penuh R3.3 |
| Batch F, UI-B1…B15 | Tas Umpan, toast, chip umpan, HUD map, bug | Selesai (belum playtest) |
| Papan Hari Ini (Agenda) | Tombol HUD Papan, 3–5 tugas sesuai fitur terbuka (K-80) | Kode selesai (R2.2); belum playtest |
| Bubu Pasang / Ambil | Tombol di slot Aksi, tiang di sungai | Kode selesai (R2.1b); cek HP owner pending |
| Tarik bulat | Plate 84 px di slot Aksi (6.12) | Kode selesai (0fb8032); cek HP pending (F3) |
| Sorot tutorial (4.6) | Spotlight satu lubang hanya tombol HUD tetap, pertama kali; overlay tidak menelan sentuhan | F1a kode (08d788e); Play belum (F1) |
| Pak Udin Jual / Beli (GDD 16) | Dialog pasca-tutorial | Kode selesai (5641d7a); cek HP pending (F7) |
| "!" jarak 200 studs (4.5) | Marker terlihat dari jauh | Kode selesai (43b4719); tabel per pemberi pending (F6) |
| Toast satu permukaan (9.7, F2) | Bubble atau toast per langkah | **Belum di kode** (F2) |
| Quest Log: bintang + tracker (6.8, F5) | Dua pintu masuk, badge | **Belum di kode** (F5) |
| Tracker tidak berkedip (F4) | Akar penyebab | Guard pcall saja (425d393); akar belum direproduksi |
| Pasang / Panen Semua bulat (6.12, F3) | Satu komponen Aksi | **Belum di kode** (F3) |

Mockup lama (canvas "Mockup Season Pass & Pohon Skill (HP)") tetap acuan bentuk, **bukan** angka: ukuran tombol ikut Bab 3.4, angka hadiah ikut `Config/Rewards`.

---

## 9. Pindahan (revisi Putaran 1 dan 2)

Isi bab ini sudah dipindah ke bab fitur (aturan tidak hilang). Nomor lama di sini hanya penunjuk, supaya komentar kode dan dokumen lama tetap bisa dicari.

| Nomor lama | Pindah ke | K |
|------------|-----------|---|
| 9.1 Quest Log | 6.8 | K-56 |
| 9.2 Pohon Skill: bar bawah | 6.2 | K-56 |
| 9.3 Tas: Pakai / Dipakai | 6.11 | K-55 |
| 9.4 Mancing: tombol Tarik | 6.12 (Aksi-slot) | K-55 |
| 9.5 Toast, kartu pemain, "!" | 4.2, 4.5 | K-53 |
| 9.6 Acara & Pasar Malam | 6.6 | K-57 |
| 9.7 Coachmark tutorial | 4.6 | LOCKED 2026-11-23 |

### 9.7 Aturan sorot tutorial (LOCKED, 2026-11-23 batch F1)

Rujukan utama: **4.6** (aturan dan tabel klasifikasi per langkah). Ringkasan:

- Tombol HUD tetap (Garap, Aksi Pancing) pada langkah pertama = spotlight: satu overlay gelap dengan satu lubang.
- GUI mengambang dan objek dunia (pill Tanam / Siram / Panen, ghost Garap, NPC) = outline kuning saja, tanpa gelap.
- Pill Siram di bed tanam cepat tutorial yang ditahan (K-71, atribut part `FastHold`): hanya menampilkan nama tanaman, tanpa hitung mundur. Hitung mundur mulai saat siram pertama.
- Pengulangan = toast saja, tanpa gelap dan tanpa bubble.
- Overlay tidak pernah menelan sentuhan (joystick dan kamera bebas) dan lepas sendiri setelah 25 detik di langkah yang sama.
- Satu permukaan instruksi per langkah.
