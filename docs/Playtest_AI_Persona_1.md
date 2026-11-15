# Playtest #1 — AI persona, putaran 1 (14 Nov 2026)

Pemain baru (save kosong: Lv 1, 150 Koin, 10 Bunga, 6 bibit kangkung), Studio Play, tanpa penjelasan.
Alur yang dijalankan: buka Garap → cangkul → tanam → siram → panen → jual ke Pak Darmo → buka Pesanan.
**Belum dijalankan:** memancing, menghias, Mampir, HP asli, 2+ pemain. AI tidak bisa menilai "seru" — hanya kebingungan dan bug.

Save persona memakai store sementara `KampungTeduh_Studio_Persona1` (nama store sudah dikembalikan; save tes asli tidak tersentuh).

## Berhasil
- Funnel tercatat (event onboarding saat join, tanam, panen). Tanam, siram (timer 0:59 → 0:41), panen (+1 Kangkung, XP 2/20), jual (150 → 159 Koin) berjalan tanpa error.
- Dialog Pak Darmo, panel toko, dan panel Pesanan memakai skin bambu dan jelas dibaca.
- Hint di menu Garap ("Ketuk rumput hijau untuk dicangkul jadi tanah") membantu langkah pertama.

## Temuan (urut dampak)

| # | Temuan | Dampak |
|---|---|---|
| 1 | **Tidak ada onboarding / tujuan awal.** Layar bersih tanpa panah atau misi; empat tombol dock tanpa caption. Pemain baru tidak tahu urutan: cangkul → tanam → siram → panen → jual. | Tinggi (menyentuh funnel 1→4) |
| 2 | **Mode Garap menelan ketukan petak.** Setelah mencangkul, menu Garap tetap terbuka dan hint tidak berganti; mengetuk petak tidak menghasilkan apa pun, tanpa pesan. Pemain harus menutup menu (X) dulu. | Tinggi |
| 3 | **Tanaman siap panen tidak bisa diketuk.** Bola/model tanaman `CanQuery = false`; yang bisa diketuk hanya tile datar di bawahnya. Mengetuk tanaman yang terlihat tidak memanen. | Tinggi (terutama di HP) |
| 4 | **Tidak ada penanda arah ke NPC.** Pak Darmo 275 stud, NPC lain 260–316 stud, titik mancing ≥ 192 stud dari lahan awal (±17 detik jalan). Tidak ada petunjuk ke mana harus pergi. | Sedang–tinggi |
| 5 | **"Jual Semua" menjual bahan pesanan.** Persona menjual satu-satunya kangkung, lalu pesanan harian minta Kangkung 0/6 dan Wader 0/4 (Wader butuh memancing, belum ada petunjuk). | Sedang |
| 6 | **Tidak ada umpan balik saat menyiram/menanam** (tanpa toast; hanya timer dan warna tanah berubah). | Rendah–sedang |
| 7 | **Seed picker masih placeholder** (gelap polos, bukan skin bambu) dan menutup tombol dock. | Rendah (poles) |
| 8 | **Tanaman masih bola hijau polos**: folder `ReplicatedStorage.CropModels` kosong di Play, jadi model tanaman Fase 16 tidak terpakai. Perlu dicek apakah modelnya memang belum dimasukkan ke place. | Sedang (visual; art direction) |
| 9 | **Log: `rbxassetid://203785492` gagal dimuat** ("Asset type does not match requested type"), 6 kali saat start. Sumber belum dilacak. | Rendah |

## Status perbaikan (14 Nov 2026, dites ulang di Studio dengan save kosong)

| # | Status |
|---|---|
| 1 Onboarding | ✅ `GuideController`: petunjuk satu baris per langkah (cangkul, tanam, siram, tunggu, panen, jual, beli bibit) + **jalur panah di tanah** ke Pak Darmo (chevron emas berkontur cokelat tua yang mengalir dari pemain, mengikuti rute jalan sungguhan lewat pathfinding sehingga melewati jembatan, memudar ke ujung). Aktif untuk **3 perjalanan jual pertama** (`Config/Onboarding.TRIES`, dihitung server di `data.guide.sells`), lalu berhenti. Terbukti berhenti setelah penjualan ke-3. |
| 2 Garap menelan ketukan | ✅ Di mode Cangkul, ketukan pada petak diteruskan ke petak (tanam/siram/panen). Hint Garap berganti setelah ada petak. |
| 3 Tanaman tidak bisa diketuk | ✅ Visual tanaman kini punya ClickDetector sendiri; mengetuk bola/model memanen. |
| 4 NPC jauh tanpa penanda | ✅ lewat jalur panah di tanah di #1 (juga untuk "bibit habis, beli lagi"). |
| 5 "Jual Semua" menjual bahan pesanan | ✅ modal konfirmasi memuat total dan peringatan "pesananmu masih butuh …". |
| 6 Umpan balik tanam/siram | ✅ (15 Nov) animasi + suara + partikel tanam/siram (`FarmFx`, commit 254cfa1), plus kilau lembut pada tanaman siap panen (`Vfx.loop("ready")`, terbukti di Play). Ditemukan dan dihapus duplikat skrip di Studio (`RodAnimController`, `FarmFx`, `Sfx`, `SoundBank`, `Vfx` lama) yang membuat efek mancing jalan dua kali. |
| 7 Seed picker placeholder | ✅ dikodekan (15 Nov): kartu perkamen di tengah layar (tidak lagi menutup dock), tombol bambu `UiKit.button` dalam grid 2 kolom, judul "Pilih Bibit", badge tutup standar; tanaman tanpa bibit/terkunci memakai warna tombol nonaktif. **Belum dilihat di layar** (screenshot Studio timeout malam itu); komponennya diuji jalan tanpa error. |
| 8 Model tanaman | ✅ (15 Nov) `Shared/CropBuilder` membangun 8 tanaman dari Part (daun elipsoid, batang, buah) tanpa upload; dipakai bila `CropModels` tidak punya model. Terbukti di Play: kangkung tampil sebagai model tegak 10 part, tinggi 2,2. **Tampilan belum dinilai lewat screenshot.** |
| 9 aset 203785492 | ⬜ **belum selesai**: error masih muncul (2x saat start, dicek 15 Nov sore); sumbernya belum ketemu, tidak ada referensi di repo. |

**Perubahan GUI yang ikut** (permintaan): toko memakai tab **Beli / Jual**, number picker (− jumlah +, tahan untuk mengulang), total yang merah bila uang kurang, modal konfirmasi di Beli dan Jual Semua, slot gambar item (placeholder sampai ada gambar model, `UiAssets.THUMBS`). Lihat `GUI_Design.md`.

## Usulan perbaikan (daftar perbaikan, bukan fitur baru)
1. Quest pembuka 3–4 langkah dengan petunjuk di layar (memakai hint bar yang sudah ada) — atau minimal hint yang berganti mengikuti langkah.
2. Ketuk petak saat Garap aktif: tampilkan toast "Tutup menu Garap untuk menanam", atau tutup Garap otomatis setelah satu petak jadi.
3. Perbesar target ketuk: `CanQuery = true` pada tanaman dan arahkan ke ClickDetector tile, atau tambah ClickDetector pada visual tanaman.
4. Penanda NPC: panah/ikon di HUD ke Pak Darmo saat pemain baru, atau jalur batu yang jelas.
5. "Jual Semua" menyisakan jumlah yang dibutuhkan pesanan aktif, atau beri peringatan.
6. Toast/efek ringan untuk tanam dan siram.

## Berikutnya
Ulangi persona untuk memancing dan menghias, lalu uji di HP asli dan dengan 2+ pemain, baru 3–5 orang asli.

---

# Putaran 2 — AI persona (15 Nov 2026, sebagian)

Pemain baru (save kosong: Lv 1, 10 Bunga, Koin 340 saat join), Studio Play, store sementara `KampungTeduh_Studio_Persona2` (sudah dikembalikan). Syarat baru: **Basic Mancing (sungai) dan kolam Lv 2, Pro Mancing (empang) Lv 10**.

**Berhasil dijalankan:** Garap → Cangkul (1 petak) → Tanam (Kangkung, timer 0:59) → Siram (0:42) → Panen (+1 Kangkung, XP 2 → 4/20, siklus tumbuh ±50 detik) → Pak Darmo: dialog dan panel Jual (Kangkung 9 Koin, sisa kuota 19/20). Papan Basic Mancing tampil dengan gembok di dermaga sungai.

**Belum dijalankan:** memancing (perlu Lv 2; chat `!level` tidak bisa dikirim dari skrip, dan XP harian belum cukup), kolam, Pro Mancing (Lv 10), menghias, Pesanan (tombol dok tidak merespons klik), HP asli, 2+ pemain.

**Temuan baru (round 2):**
| # | Temuan | Dampak |
|---|---|---|
| A | Pemain baru Lv 1 tidak bisa memancing sama sekali sampai Lv 2. Dermaga terdekat (sungai) berjarak ±190 stud dari lahan awal, dan tidak ada petunjuk ke sana. | Sedang–tinggi (funnel "first_catch" ≥ 65%) |
| B | Papan "Basic Mancing · Butuh Lv 2" tertutup kepala karakter saat berdiri di dermaga. | Rendah |
| C | Jarak lahan awal → Pak Darmo ±290 stud; jalur panah ada, tetapi tidak ada petunjuk ke dermaga. | Sedang (temuan 4 putaran 1 belum tertutup penuh) |
| D | Tombol dok Pesanan tidak membuka panel pada percobaan klik (belum dicek ulang). | Perlu cek |
| E | Hint bar Garap ("Ketuk petak tanah untuk menanam…") tampil dan berganti. | Berjalan |

**Catatan teknis:** GUI `Freecam` bawaan Studio sempat aktif dan membuat layar hitam serta memblokir klik. Saat tes ini dimatikan di sisi klien; jika terulang, stop/start Play.
