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
| 6 Umpan balik tanam/siram | ⬜ belum |
| 7 Seed picker placeholder | ⬜ belum (kini tumpang tindih dengan bar Garap, perlu dibuat bergaya bambu) |
| 8 Model tanaman, 9 aset 203785492 | ⬜ belum |

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
