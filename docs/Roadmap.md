# Roadmap

Tanpa tanggal. Aturan kerja: **satu tahap satu waktu, tunggu "lanjut"**. Tiap tahap: kode, tes di Studio (screenshot), update docs, baru dianggap selesai. Migrasi data wajib uji pakai save lama. Tahap besar dipecah dan dites bertahap.

Desain lengkap di `00_Design_Doc.md`, peta di `Map_Plan.md`.

---

## Sudah selesai (menurut dokumen terakhir)

| Fase | Isi |
|---|---|
| 1–11 | Fondasi, bertani, memancing, tas/toko, hias, pesanan + Buku + level, siang-malam + hujan + audio, monetisasi + analitik, sosial ringan (Mampir, Suka), playtest plan, live-ops plan |
| 12 | Lahan & **Garap** (tanah Terrain, simpan, migrasi) |
| 13 | NPC & dialog (Pak Darmo, Bu Wati, Mas Joko, Mbok Minah); bibit jadi item |
| 14 | Bang Tarno + tawar + kedekatan + skill ⛔ *(dibatalkan; kode dihapus di R1, Bang Tarno tetap sebagai penadah)* |
| 15 | Mbak Arsi + blueprint (**belum dites di Studio**) |
| 16 | Model tanaman + kit GUI ForgeGUI, HUD baru |
| 17 (sebagian) | Bar stamina di HUD ⛔ *(hanya tampilan, tidak ada sistem; dihapus di R1)* |
| R1 | Kuota warung + penadah + pembersihan ✅ dikodekan dan dites di Studio |
| – | Repo git `kampoengtedoeh` (privat), docs dirapikan |

**Dibatalkan:** stamina, istirahat, bonus bangku, tawar-menawar, kedekatan NPC, skill Tawar.
**Ditunda sampai setelah playtest:** peternakan, rumah, mode foto, tujuan bersama, warung pemain/masak, hias v2.

---

## R1 — Pembersihan & kuota warung ✅ selesai dan dites di Studio (14 Nov 2026)

Mengubah desain NPC jual-beli dan membuang kode yang dibatalkan.

**Teruji di Studio (1 pemain, Play):** server start tanpa error baru; save masuk sebagai v8 dengan `npc`/`skills` nil; jual 20 kangkung ke Pak Darmo (+180), sisa ditolak dengan toast; jual sisa ke Bang Tarno 0,7× (+72); panel Pak Darmo dan Bang Tarno tampil benar (sisa kuota, tanpa tombol Tawar); upgrade Kapasitas Warung (kuota 20 → 25); harga beli di Mas Joko, Mbok Minah, Bu Wati, Mbak Arsi tanpa diskon; migrasi v7 → v8 dari save buatan dan pergantian hari pada kuota diuji lewat skrip.
**Belum teruji:** 2+ pemain, HP asli, pergantian hari WIB sungguhan (hanya lewat skrip), save v7 asli dari DataStore, dan penolakan "terlalu jauh" dari NPC.
Perintah dev baru: `!give <item> <n>`, `!sales`, `!quota reset`.

Hasil simulasi (`balance_sim.py`, setelah R1): hari ke-42 Koin tertimbun ±162 ribu (sebelumnya ±205 ribu). **Kuota menurunkan pemasukan sekitar 20–25%, tapi tidak menyelesaikan penimbunan Koin.** Sink sebenarnya tetap harus datang dari chunk lahan (R2), upgrade, dan konten berikutnya.

- Hapus: `AffinityService`, `SkillService`, `Config/Skills`, tawar di `NpcService`/`ShopService`, sapaan berdasar kedekatan, diskon kedekatan, perintah dev `!affinity`, `!skill`, `!skillxp`, tampilan kedekatan di dialog, bar stamina di `HudController` dan atribut `Stamina`.
- Migrasi data: buang `skills` dan data kedekatan (bumpkan versi; uji save lama).
- Tambah: **kuota harian Pak Darmo** per jenis tanaman (20, *asumsi*), `data.sales`; **Bang Tarno** jadi penadah 0,7× tanpa tawar; tampil sisa kuota di panel; upgrade **Kapasitas Warung** (+5/tingkat, *asumsi*) lewat Koin.
- Perbarui `tools/balance_sim.py`: tambah kuota dan penadah.
- Selesai bila: jual sampai kuota habis, lalu jual ke Bang Tarno 0,7×; reset 00:00 WIB; save lama masuk tanpa error.

## R2 — Peta cincin + lahan chunk

Perubahan terbesar. Detail di `Map_Plan.md`. Dipecah: **R2 (peta + lahan awal 128, ✅)** dan **R2b (beli chunk)**.

### R2 — peta cincin ✅ selesai dan dites di Studio (14 Nov 2026)
Versi pertama (R2a: 10 lahan 96×96 dalam cincin persegi dengan sungai X) **digantikan** setelah kamu menilai tidak adil dan terlalu kecil. Sekarang mengikuti konsep gambarmu: kanal bundar + pulau kota + cincin jalan batu + 4 jalan silang, **8 lahan identik**, awal **128×128** dalam kotak cadangan **192×192** berisi hutan perluasan. Migrasi v8 → v9 (lahan 96) dan v9 → v10 (kerangka koordinat baru). Detail dan screenshot di `Map_Plan.md`. Belum teruji: 2+ pemain, HP asli dan performa, memancing dari dermaga baru.

### R2b — beli chunk ✅ selesai dan dites di Studio (14 Nov 2026)
- Lahan tumbuh dari 128×128 ke 192×192 dengan membeli **blok 32×32** (20 blok) yang **menempel** pada lahan milik (tombol **+** melayang di atas tiap blok yang bisa dibeli, popup beli; lihat perombakan UI di bawah). `Modules/Land` memakai daftar blok milik pemain; garap, kolam, dan hias memakai daftar yang sama. *(Awalnya chunk 16×16 × 80; diperbesar setelah kamu menilai terlalu kecil dan pagarnya bergerigi: migrasi v11 → v12.)*
- Membeli blok: hutan `ExpansionOf` di blok itu disembunyikan, tanah dicat rumput terang, pagar bergeser keluar; data `land.chunks`. Harga `1.500 × 1,2ⁿ` (20 blok ±280.000 Koin).
- Batas jumlah petak tanam dihapus (katup pengaman 100); upgrade "Perluas Kebun" dihapus (refund lewat migrasi v10 → v11). Pass "Petak Ekstra" jadi **"Diskon Lahan"** (−20% harga chunk, ukuran akhir tetap sama untuk semua).
- `plotSlot` tersimpan dan dicoba dipakai lagi saat masuk.
- `LandService` baru; `MapService.SetChunkOwned` / `RebuildFence`.

**Teruji (Studio, 1 pemain):** harga dan urutan 2.590 → 3.110 → 3.730 → 4.480 (blok ke-4 sampai ke-7); beli ditolak untuk blok milik dan yang tidak menempel; Koin kurang ditolak; tanah jadi rumput terang, pohon di blok disembunyikan, pagar mengikuti tepi blok dengan rapi (bentuk L bersih); garap dan hias hanya di blok milik; blok, petak, dan hutan kembali benar setelah rejoin; UI popup menampilkan harga; migrasi v10 → v11 (refund) dan v11 → v12 (6 chunk lama jadi 3 blok).
**Belum teruji:** reset lahan saat pemain keluar lalu pemain lain masuk (butuh 2 pemain), `plotSlot` dengan 2 pemain, klik langsung di dunia untuk membeli (jalur beli diuji lewat remote yang sama), HP asli, dan performa saat banyak chunk dibeli.
### Perombakan UI sebelum playtest ✅ dikodekan dan dites di Studio (14 Nov 2026)
Detail dan screenshot di `GUI_Design.md`. Ringkas: menu kanan atas jadi kolom vertikal yang menciut di HP (animasi), uang di tengah atas, semua tombol bulat **tanpa caption** (tooltip hover), kartu pemain dengan bar XP ramping + **3 slot buff** (Segar Bertani, Umpan Wangi, Kenyang; efeknya belum dikodekan), menu Garap bambu gelap dengan badge tutup dan nama baru (**Cangkul, Hijaukan, Gali Kolam, Urug Kolam**), dan beli lahan dipindah ke tombol **+** melayang + popup. Harga chunk dinaikkan ke `250 × 1,06ⁿ`.
**Belum teruji:** HP asli (menu menciut disimulasikan di PC dengan `CompactHud`), ketukan jari pada tombol **+** dan popup, dan tombol Menu bersama joystick/tombol lompat.

**Risiko ekonomi:** tanpa batas petak, simulasi (dengan asumsi +4 petak per blok) mencapai Lv 30 di hari ke-23 (dulu hari 31), dan 15 dari 20 blok terbeli di hari 42, jadi blok efektif menyerap Koin. Perlu data playtest, bukan tebakan.

### Perbaikan dari playtest AI persona putaran 1 ✅ dites di Studio (14 Nov 2026)
Temuan di `Playtest_AI_Persona_1.md`. Diperbaiki: Garap tidak lagi menelan ketukan petak; tanaman bisa diketuk langsung; **panduan pemain baru + jalur panah di tanah ke Pak Darmo** untuk 3 perjalanan jual pertama (`Config/Onboarding`, `data.guide.sells`, tanpa migrasi karena kunci baru ditambah Reconcile); toko NPC bertab Beli/Jual dengan number picker, total merah, slot gambar placeholder; modal konfirmasi standar (Batal kiri merah, Setuju kanan) untuk beli, Jual Semua, dan beli lahan; server menerima jumlah bebas 1–99 untuk beli dan jual (`Sell(npc, item, amount?)`, `Shop.MAX_AMOUNT` menggantikan `PACKS`).
**Belum teruji:** HP asli (picker, tahan tombol, panah di tepi layar dengan joystick), 2+ pemain, toko NPC selain Pak Darmo (Bu Wati, Mas Joko, Mbok Minah, Mbak Arsi memakai kode yang sama tetapi belum dibuka satu per satu), tombol Jual satu item untuk NPC non-kuota. Temuan 6–9 di dokumen persona masih terbuka.

### Poles malam 15 Nov 2026 (kerja otomatis, detail di `Overnight_Log.md`)
Toko kota versi bisa diwarnai di Roblox (`Config/ShopPalette`, belum di-upload); VFX hadiah + ambient (`AmbientFx`, kilau tanaman siap panen); model tanaman dari Part (`Shared/CropBuilder`); seed picker bergaya UiKit; temuan persona 6–9 ditutup; duplikat skrip di Studio dihapus.
**Belum teruji:** tampilan di layar (screenshot Studio timeout), mancing penuh dari dermaga baru, HP asli.

### P1 — Mesin tutorial ✅ dikodekan dan dites di Studio (15 Nov 2026)
Detail teknis: `Tutorial_Engine.md`. `data.guide` bertambah `step{id,n}`, `done`, `skipped`, `fastLeft` (lewat Reconcile, tanpa migrasi); `TutorialService` (server) menyimpan langkah, membayar hadiah, mencatat analytics, dan menjalankan bibit cepat (6 penanaman pertama save baru tumbuh 20 d, 16 d bila disiram); `GuideController` menjalankan banyak tutorial dari `Config/Onboarding.TUTORIALS` (satu aktif, antrean jeda 120 d, simpan dan lanjut per langkah, tombol Lewati, cincin berdenyut di tombol HUD, deteksi macet 45/90 d); Atur > Panduan untuk mengulang tanpa hadiah. **Isi T1 belum ada** (P2); hanya tutorial tes khusus Studio (`TEST_TUTORIAL`, `auto = false`). Sprint dibatalkan.
**Belum teruji:** lihat bagian "Belum teruji" di `Tutorial_Engine.md`.

### P1b — Penyederhanaan Garap + penunjuk tombol ✅ dikodekan, dites sebagian di Studio (15 Nov 2026)
Menu popup Garap (Cangkul / Hijaukan / Gali Kolam / Urug Kolam) **dibuang**. Dua tombol dock: **Garap (Cangkul)** dan **Kolam** (ikon `kolam` yang sudah ada). Alat membaca isi bawah penunjuk: rumput → petak, petak kosong → hijaukan otomatis, petak bertanaman → siram/panen; kolam kosong → gali, kolam ada → urug (dengan konfirmasi). Kotak hijau/oranye + label kecil menunjukkan aksi. Penunjuk tutorial kini menjangkau tombol mana pun (cincin + panah melambung). Detail di `GUI_Design.md`; penilaian gameplay di `Gameplay_Review.md`.
**Belum teruji:** HP asli (dock 5 tombol di antara joystick dan lompat, tap di dunia vs tombol dock), konfirmasi urug kolam, hijaukan lewat tap sungguhan di HP.

## Gerbang: Playtest #1

Jangan tambah fitur baru sebelum ini. Isi: `Playtest_Plan.md`.
- **Playtest AI persona** (jalan lewat alur dari sudut pandang pemain baru) untuk menemukan kebingungan dan bug. Bukan pengganti uji orang asli (AI tidak bisa menilai "seru").
- **3–5 orang asli** dari target (perempuan 16+), tanpa dijelaskan.
- Keluar dari gerbang dengan daftar perbaikan, bukan daftar fitur.

## R3 — Hadiah, Upgrade, Toko (dari rencana Fase 17 yang masih dipakai)

**Status: semua tahap dikodekan (17.0, 17.3, 17.4, 17.7, 17.5, 17.6). Belum dites di HP asli, 2+ pemain, atau dengan save v12 asli.** Diuji di Studio: server start tanpa error, panel Hadiah / Koleksi / Toko tampil dengan data sungguhan, migrasi v12 → v13 (uji lewat skrip), kompilasi semua modul.
- **Keputusan sementara (asumsi, perlu playtest):** peti main 5 / 10 / 20 / 30 / 45 / 60 menit (koin 50, 75, pelet 5, bunga 1, koin 150, bunga 2); aktif = karakter bergerak ≥ 1 stud tiap 10 detik.
- **Lahan tidak dibuat sebagai upgrade tingkat.** Lahan dibeli per blok (R2b); upgrade yang ada: Tas, Kolam, Kapasitas Warung.
- **Toko:** tab Paket (Tas Ekstra, Kolam 2×, Diskon Lahan), Koin, Bunga, Hias (Hias Lebih Banyak + Langsung Panen).
- **Koleksi:** hadiah kategori dan milestone sekarang diklaim manual (`BookClaim`). Tidak perlu migrasi: klaim lama sudah tercatat `claimed`.
- **Migrasi v13:** `backpackTier`, `pond.tier`, `sales.tier` pindah ke `upgrades{backpack,pond,warung}`; `playtime` baru.

Urutan: 17.0 → 17.3 → 17.4 → 17.7 → 17.5 → 17.6.
- **17.0 Fondasi GUI:** `UiKit.tabs`, `productCard`, `progressDots`, `notifyDot`, `rewardPopup`; aset ForgeGUI (hemat kredit, cek `assets/gui` dulu): ikon hadiah, kalender, upgrade, titik notifikasi, kartu produk, tab.
- **17.3 Hadiah harian:** kalender 7 kartu di atas Kunjungan Harian yang sudah ada (kumulatif, tanpa hukuman).
- **17.4 Hadiah playtime:** 6 peti/hari, gratis, hitung di server, anti-AFK sederhana.
- **17.7 Upgrade:** `UpgradeService` umum (Tas, Kolam, Lahan, Kapasitas Warung); data `upgrades[id] = tier`; pindahkan logika dari `ShopService`; migrasi dari `backpackTier`, `pond.tier`, `farm.expansions`. Simulasi harga di `balance_sim.py`.
- **17.5 Koleksi:** grid kategori, milestone diklaim manual; migrasi: milestone yang sudah tercapai ditandai "sudah diklaim".
- **17.6 Toko:** satu panel dengan tab samping dan kartu produk (Paket, Koin, Bunga, Hias); ID masih 0 → "Belum tersedia". Tidak ada boost baru tanpa `Monetization_Review.md`.
- Catatan teknis dari fase GUI: skin gambar di atas latar tapi di bawah teks (`ZIndexBehavior = Sibling`, skin `ZIndex = 0`); pakai cache preload agar tombol tidak berkedip; panel dibangun ulang tiap perubahan data, jadi komponen harus murah; HUD memakai `IgnoreGuiInset = true` + `ScreenInsets = DeviceSafeInsets`; cek `Source` di Studio setelah edit karena sinkronisasi file tidak selalu otomatis.

## R4 — QA & poles

Tes di HP asli (sentuhan, joystick vs kartu status, notch, rotasi); semua string lewat `Locale/id.luau`; hook analitik (klaim harian, klaim playtime, upgrade); perbarui docs.

## Playtest #2

Ulangi playtest dengan build R3–R4.

## Setelah playtest (urutan ditentukan oleh data)

Kandidat, bukan komitmen: **mode foto**, **tujuan bersama kampung**, **peternakan ayam**, **warung pemain + masak + buff**, **hadiah teman**, **kucing**, **rumah Tahap A lalu B**, **hias v2** (grid + highlight dulu, undo/redo dan tampak atas belakangan), **tinggal bareng**.

---

### Playtest menyeluruh 1 (15 Nov 2026) ✅ sebagian
`Playtest_Menyeluruh_1.md`: teks dipangkas, outline teks diperbaiki, 7 role suara baru dan efek suara bisa dimatikan, kamera ngobrol NPC, banner naik level, pisang diperbaiki harganya. Temuan terbuka: pesanan mingguan Lv 1 terlalu besar, XP pesanan awal, NPC yatim, aset 203785492. **Viewport 3D hitam saat capture, jadi visual 3D tidak dilihat ulang.**

### L1a — Bertani bertahap: GUI melayang + animasi + model tanaman ✅ dikodekan, dites di Studio sebagian (15 Nov 2026)
Pil melayang di atas petak sendiri (`client/FarmFloat`): Kosong → ketuk menanam; Siram + sisa waktu; Panen!; bibit/ketuk hanya muncul untuk petak dekat, maksimal 3, tidak menumpuk. Pemilih bibit = panel bambu standar dengan **model 3D tiap tanaman di kartu** (ViewportFrame, model sama dengan di petak). Animasi: menanam (gali, **VFX di petak**), menyiram (karakter memegang kaleng siram, air mengalir ke petak, percik di petak), panen (kilau di petak). Delapan model tanaman dan dua ikon dari ForgeGUI sudah di-upload dan dipasang (`Aset_Roblox.md`). NPC `bang_tarno` yatim dihapus. Pak Darmo punya model baru (`ServerStorage.NpcModels`).
**Belum:** model NPC lain (Bu Wati, Mas Joko, Mbok Minah, Mbak Arsi, Bang Tarno) dan penilaian visual model Pak Darmo/tanaman di kamera game; tekstur tanaman tampak pucat di petak (diperiksa: tekstur hijau benar, kemungkinan pencahayaan/Overlay alpha); kamera ngobrol Pak Darmo dari depan stall belum dites ulang setelah tabrakan kamera ditambah; tombol Siram untuk ikon baru belum dilihat di layar (ikon fallback `kolam` tampil sampai gambar termuat).

### L1b — Perbaikan umpan balik (15 Nov 2026)
Tanaman abu-abu: penyebabnya **normal map** hasil ForgeGUI yang terlalu kuat di cahaya game (bukan warna); NormalMap, MetalnessMap, RoughnessMap dikosongkan di `CropModels`. Ukuran tanaman diperbesar (kangkung 2,2 → 4 stud, jagung 5 → 8, pisang 6 → 9, dst.). Kaleng siram dibenarkan arahnya (tanpa rotasi ekstra; moncong ke depan). Pil melayang dikecilkan (132×38), label Garap (92×22), papan titik pancing (124×36, jarak 45 stud). GUI mancing dibangun ulang bergaya bambu (kartu Status + Reel dengan jalur air, zona hijau, ikon ikan, tombol Tarik! UiKit). Dites: kangkung hijau dan besar, kaleng di tangan menuang ke petak, kartu Reel tampil.
**Belum:** cabai masih tampak gelap keabuan di petak (kemungkinan tekstur/UV, tertutup pil saat dicek); papan titik pancing dan kartu Status belum dilihat; model NPC lain (lihat `Aset_Roblox.md`).

### Perombakan daftar GUI (15 Nov 2026)
`UIUX_Spec.md`: alasan UX, warna per kategori, komponen baru, hasil. Tas, Koleksi, Atur, Toko NPC sudah dipadatkan; Pesanan, Hadiah, Warga, Toko Robux masih gaya lama.

## Penilaian gameplay (15 Nov 2026)
`Gameplay_Review.md`: loop inti tidak busuk tapi terlalu banyak ketukan dan sedikit keputusan; usulan L1 (tanam/panen/siram sekali ketuk), L2 (variasi waktu tumbuh), L3 (sink Koin), L4 (alasan ke alun-alun). Menunggu persetujuan urutan.

## Keputusan terbuka

1. ~~Sungai di peta cincin~~ — selesai di R2: kanal bundar mengelilingi pulau kota, tidak ada lahan yang tersilang air.
2. **Kuota Pak Darmo:** 20 per jenis cocok? Apakah kuota naik juga per level? (R1, simulasikan)
3. **Harga blok lahan:** kurva `1.500 × 1,2ⁿ` sudah dikunci sementara; cocok atau terlalu murah/mahal? Ukuran blok 32 bisa diganti (mis. 64) di `Config/Plots` `CHUNK.SIZE`. (data playtest)
8. **Buff:** efek tiga buff (tumbuh 10%, gigit 25%, XP +10%) dan sumbernya (makanan dari warung pemain, hadiah) belum dikodekan; ikon ForgeGUI (kosong + penuh) menunggu daftar buff final.
4. **Kecepatan progres tanpa batas petak:** perlu dijinakkan (kuota, harga bibit, kurva XP) bila playtest menunjukkan terlalu cepat.
5. **Kartu status vs joystick di HP:** pakai thumbstick Dynamic atau geser kartu ke kanan? (R4, tes di HP)
6. **Peta cincin:** apakah 8 slot cukup, atau perlu 12 (3 per jalan)? (setelah Playtest #1 melihat jumlah pemain sebenarnya)
7. **Teras sawah di pojok peta** (ada di konsep): dibuat sekarang atau nanti? Pojok saat ini berupa hutan.
