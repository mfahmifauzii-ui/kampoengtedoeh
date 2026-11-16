# Overnight Job (16 Nov 2026)

Urutan: 10 stage, otomatis, tanpa tunggu "lanjut". Jangan commit. Jangan tanya user.
Stage gagal 2x: catat di `docs/OVERNIGHT_LOG.md`, lanjut.
Di akhir: laporan lengkap di `docs/OVERNIGHT_LOG.md`, lalu berhenti.

Aturan umum:
- Jangan ubah yang sudah bagus: grid 2 stud, proximity 4 stud, bulatan bambu 64 px, slot putih, badge bulat kanan atas, respawn di depan gerbang, plang gerbang, lampu gerbang (sudah dihapus, jangan tambah), player card 220x70, toast di atas.
- Tiap stage: ubah kode -> sync -> Play di Studio -> screenshot -> tulis hasil di log.
- Play error: perbaiki 1x, tes lagi. Masih error: log, lanjut.
- Cozy: no fail state, no stamina, no loot box, no paid popup, no streak. Semua beli pakai Koin, bukan Robux.

## Stage 1 - Panen semua, jual semua, drag siram
- Tombol "Panen Semua" di atas lahan: 1 tap panen semua petak matang, tiap hasil terbang ke Tas (0,6 dtk, antre).
- "Jual Semua" di Pak Darmo: 1 tap jual semua hasil di Tas, koin terbang + count-up 0,8 dtk.
- Drag siram: geser di banyak petak kering, semua tersiram.
- Cara manual tetap ada.
- Tes: 8 petak matang -> Panen Semua 1 tap -> semua masuk Tas. Jual Semua 1 tap -> koin naik.

## Stage 2 - Alat siram progres, bukan Robux
- Gembor Bambu: buka Lv 4, harga Koin 300. 1 tap siram 3x3, area 3x3 tampil saat dipilih.
- Sprinkler Bambu: buka Lv 7, harga Koin 800. Hiasan di lahan, siram sendiri 3x3 sekelilingnya tiap 60 dtk.
- Tidak mengotomatisasi tanam dan panen, hanya siram.
- Tes: Lv 4 beli Gembor, 1 tap siram 3x3. Lv 7 taruh Sprinkler, tunggu 60 dtk, petak sekeliling basah.

## Stage 3 - Nerf pesanan + balancing ekonomi
- T1 max 3 Kangkung, reward 30 Koin sekali. Pesanan harian setelah T1: 5-8 item.
- Kangkung jual 8 Koin, bibit 3 Koin. Cabai jual 15 Koin, bibit 6 Koin. Margin 2x-2,5x.
- Tes: akun baru, selesaikan T1, total Koin <= 100.

## Stage 4 - Bukti T1 save-new + Playtest #1
- Save baru: spawn depan gerbang, kamera belakang. T1 5 langkah (Mbok Minah -> Garap -> Tanam proximity 4 stud -> Siram -> Panen -> Jual). 30 Koin sekali.
- Save, tutup, buka lagi: T1 tidak ulang, Koin dan petak tetap. Replay T1: tidak dapat 30 Koin lagi.
- Checklist Playtest #1 di `docs/Playtest_Plan.md`.

## Stage 5 - Mancing cozy, no fail
- Kolam di pinggir lahan, papan "Kolam Mancing". Area kolam tidak bisa digarap.
- Dekat kolam 4 stud -> tombol "Mancing". Tap: lempar kail, pelampung + riak.
- 3-5 dtk random, ikan gigit: pelampung goyang + "!" + suara kecil. Tap / "Tarik" -> ikan.
- Tidak ditarik: ikan tetap menunggu. NO FAIL.
- Ikan terbang ke Tas (0,6 dtk), Tas pulse. Tanpa toast "+1 Ikan".
- Ikan: Lv 1 Mujaer 10 Koin, Lele 12. Lv 5+ Mas 20, Gurame 25.
- Pancing Kayu Lv 5, Koin 500, tunggu 2-4 dtk.

## Stage 6 - Hias kebun, grid yang sama
- Toko Hias 6 item: Pagar Bambu, Jalan Batu, Bunga Kamboja, Lampu Taman (2x2, di sudut), Kursi Kayu (4x4), Pohon Pisang Hias (4x4).
- Ghost di grid 2 stud, garis 8 stud, merah jika tidak boleh.
- Tap hiasan di mode Hias: Pindah (hijau) / Hapus (merah bata) / Putar (krem, 90 derajat).
- Pindah: preview transparan 50% ikut kursor. Hapus: kembali 50% harga.
- Hiasan tidak menghalangi jalan.

## Stage 7 - NPC + quest minimal
- Main Quest (3 langkah setelah T1): Tanam 3 Kangkung, Mancing 1 Ikan, Taruh 1 Hiasan. Reward 50 Koin + 1 Pagar Bambu.
- Daily Quest: 1 per hari (reset 05:00), random dari Tanam 5 / Panen 5 / Mancing 2. Reward 40 Koin + 10 XP. Progress "2/5".
- Tidak ada Weekly / Event. Tidak ada quest yang hangus.

## Stage 8 - Toko, Tas, Ensiklopedia
- Toko 3 tab: Bibit, Hias, Alat. Terkunci: "Buka di Lv X" + gembok.
- Tas: 50 item (100 di Lv 10). "Jual Semua". Penuh: "Tas penuh, jual dulu" (info, bukan gagal).
- Ensiklopedia di Panduan: tab Tanaman dan Ikan. Yang sudah didapat terang; belum: siluet + "???".

## Stage 9 - Suara, musik, SFX, visual polish
- Atur: Musik 0,3, Suara Alam 0,4, Efek Suara 0,5.
- SFX pendek: Tanam, Siram, Panen, Lempar, Dapat ikan, Koin (pitch naik), Pindah, Hapus, Buka Toko.
- Partikel: air saat siram, daun saat panen, riak mancing, sparkle koin.
- Ducking: musik turun 20% selama 0,5 dtk saat SFX.

## Stage 10 - Performance, save, HP, playtest #2, launch checklist
- Performance: gabung part sama, hapus part bawah tanah, partikel max 50, shadow kecil dimatikan. Target 60 FPS Studio, 30 FPS HP.
- Save DataStore: Koin, XP, Level, petak, hiasan, Tas, quest, T1. Save-new + rejoin 3x tanpa hilang.
- HP: cek 844x390 dan 1280x720. Dock 44-48 px.
- Playtest #2 15 menit di `docs/Playtest_Plan.md`.
- Launch checklist: `docs/Launch_Checklist.md`, status jujur (beres / belum / belum dites).

## Laporan akhir
Di `docs/OVERNIGHT_LOG.md`: beres/gagal per stage, file diubah, screenshot, hasil tes, yang belum dites (HP asli, 2+ pemain, DataStore asli). Lalu berhenti.

## Keputusan FINAL (16 Nov, perintah user)
- START_KOIN = 100, FINAL. Tidak diubah lagi.
- Hapus hias = kembali ke Tas, tanpa refund Koin. Jual hias (jika ada) = refund 50%.
- Ikan: tanpa timeout. Ikan menunggu sampai ditarik.
- Prompt kolam = 4 stud, sama seperti proximity petak.
- Quest tanpa panah dianggap belum selesai (tutorial arah wajib).

## STATUS AKHIR (16 Nov, sesi perintah baru) — [x] hanya bila ada screenshot + hasil tes

- [x] 1. START_KOIN = 100, FINAL (Economy.luau). Akun baru: Koin awal 100 + kunjungan harian hari 1 (+50) = 150 saat join.
- [GAGAL] 2. Shop recolor: `ApplyShopPalette` ditulis (`src/shared/Modules/ApplyShopPalette.luau`). Tes server: 30 MeshPart di Shop8 berubah ke warna palette, wood jadi merah di Play, lalu dikembalikan (143,101,63). Visual merah belum tertangkap di screenshot (bagian kayu tidak terlihat jelas). Versi rc_* TIDAK dipasang: harus diupload dulu, tidak dilakukan tanpa persetujuan. Shop8 di peta sudah punya MeshPart bernama slot palette (196 part).
- [GAGAL] 3. VFX duplikat: di Studio tiap nama (Vfx, Sfx, SoundBank, FarmFx, RodAnimController) hanya 1 instance (dicek). Tes suara mancing 1x dan kilau panen BELUM dites (perlu dengar + tanam siap panen).
- [GAGAL] 4. Mancing: 16/16 FishPrompt di Studio = 4 stud (dicek properti). REEL_WINDOW dihapus, tanpa timeout (komentar di FishService). Tes berjalan dekat dermaga dan lihat prompt muncul/hilang di luar 4 stud BELUM dilakukan.
- [GAGAL] 5. Hias: Hapus = balik ke stok/Tas tanpa refund (DecorService). Menu Pindah (hijau) / Hapus (merah bata) / Putar (krem) dan ghost 50% ditulis (DecorController). Tes Pindah + preview transparan ikut kursor BELUM dilakukan di Play.
- [GAGAL] 6. Quest panah: panah BillboardGui ke target Misi Utama dan Daily ada di Play (screenshot `OVN_tracker_arrow_test.jpg`, QuestArrow = 1). Tes selesai quest + reward BELUM (step 1 sudah jalan: 3 kangkung tanam → Misi Utama step 2 "Mancing 1 ikan").
- [GAGAL] 7. Stage 4, akun baru (DevSaveSuffix = s4a, dihapus setelah tes):
  - Spawn depan gerbang: ya (x -8, z 300, Plot1).
  - T1 5 langkah: sapa (klik Mulai), cangkul (Garap + tap), tanam (bibit, proximity), siram (tap Siram), panen (tap), jual (Pak Darmo, E + Jual/Beli + Jual) — screenshot tersedia.
  - Koin setelah T1 = **188**, bukan 130. Selisih: kunjungan harian hari 1 (+50) dan kangkung terjual (+8). Target 130 tidak tercapai.
  - Rejoin 3x: T1 tetap selesai (`t1_awal`), Koin 188 tetap, 1 petak tetap. ✅ (log di konsol Studio)
  - Replay: GuideEvent replay dikirim, Koin tidak berubah. Replay 5 langkah penuh BELUM dijalankan.
  - Catatan: karakter dipindah dengan CFrame (bukan jalan kaki) untuk mendekat ke petak dan Pak Darmo.
- [GAGAL] 8. Sprinkler: dibuat (decor `sprinkler_bambu`, Lv 7, 800 Koin, siram 3x3 tiap 60 dtk). Tes: dipasang di lahan (ya). Konsol Studio: `[Sprinkler] RafikoFauzo: 1 petak tersiram` setelah tick 60 dtk. Screenshot petak basah di sekitarnya BELUM diambil.
- [x] 8b. Gembor tanpa !tool: beli di Pak Darmo lewat Net ShopBuy dari klien (Koin 5764 -> 5464, tombol Gembor muncul). 1 aksi siram 3x3 (FarmWaterArea): petak tengah dan petak bersisian basah, petak berjarak 2 sel tidak. Screenshot `OVN_gembor_3x3_tracker.jpg`. Catatan: pembelian dikirim lewat remote, bukan klik toko.
- [GAGAL] 9. Panen Semua rate: jeda 0,25 dtk antar petak = 4 kirim/detik, di bawah RATE 8/dtk (hitungan, belum dites >12 petak di Play). Tidak ada perubahan kode di sesi ini.

Stage 4-7 yang masih [GAGAL] berarti belum ada tes penuh dengan screenshot. Lihat `docs/Overnight_Log.md` bagian "Perintah baru 16 Nov".

## STATUS (16 Nov, perbaikan bug dari screenshot S4)
- [0] Plang Kebun: tidak diubah.
- [x] 1. Koin sync HUD: bar atas = footer = 138 (`OVN_fix_s4c_sold_synced_138.jpg`, `OVN_fix_s4d_sold_hud_138.jpg`).
- [x] 2. Start 100 (screenshot akun baru s4c/s4d = 100). Kunjungan Harian +50 tidak lagi otomatis: setelah T1 jadi `visitPending` dan tombol "Ambil hadiah harian" di Panduan. Akun setelah T1 + jual 1 Kangkung = 138. Klaim tombol belum diklik di Play (lewat remote belum dites).
- [x] 3. Arrow T1: arah ke petak sesuai fase (tanam = petak kosong, siram = petak kering, tunggu = petak tumbuh, panen = petak matang). Pak Darmo hanya saat sudah ada Kangkung di Tas. Arrow T1 kemudian DIHAPUS atas perintah user (tidak perlu). Arrow Misi Utama disembunyikan selama T1 berjalan.
- [x] 4. Copy: fase tunggu teks "Tunggu tanamannya matang" dan coachmark "Tunggu matang" (`OVN_fix_s4d_a_tunggu_timer.jpg`). Teks "Tap Panen" hanya saat fase panen (`OVN_fix_s4d_harvest_phase.jpg`).
- [GAGAL] 5. Shop recolor: belum diuji ulang dari depan dengan kontras (tidak dikerjakan di sesi ini).
- Catatan: BillboardGui tidak tampil di Studio ini, jadi panah memakai ScreenGui (`src/client/WorldArrow.luau`). Panah quest Misi masih ada (berwarna cokelat, sama seperti panah T1 yang sudah dihapus). Tombol Panen Semua dan Gembor dipindah ke bawah hint agar tidak menutupi teks.
- Rejoin 3x dan replay T1 untuk akun baru belum dites ulang di sesi ini.
