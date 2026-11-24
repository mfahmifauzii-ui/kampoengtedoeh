# KAMPOENG TEDOEH — Playtest Checklist (sinkron GDD v8.4, 2026-11-23)

> Satu-satunya tugas owner: **main, rasakan, tulis masukan**. Semua keputusan desain sudah diambil (`02_Audit_Perbaikan.md` Bab 3.0). Claude Code tidak menunggu hasil checklist ini untuk lanjut kerja; masukan Anda masuk sebagai perbaikan di putaran berikutnya.
> Cara pakai: ambil **hanya bagian yang Claude Code bilang sudah selesai** (dia menyebut nomor bagian di laporannya). Tidak perlu mengisi semuanya sekaligus.

---

## 0. Persiapan & Format Masukan

**Perangkat uji**
- Studio Play (1 pemain), lalu **Play Solo → Start Server + 2 Player** untuk bagian multiplayer.
- 4 ukuran layar (Studio → Device emulator): **1920×1080, 844×390, 667×375, 390×844**. Minimal cek HUD di tiga yang terakhir.
- Kalau punya HP asli (RAM 4GB): cek bagian P (performa) di HP itu.
- **Akun baru** untuk alur pertama (hapus data lewat perintah DEV yang dicatat Claude Code, atau pakai akun uji kedua). **Akun lama** untuk cek data tidak hilang.

**Tanda di tiap baris:** `[ ]` belum · `[v]` lulus · `[x]` gagal (tulis catatan) · `[?]` bingung / tidak yakin

**Tingkat temuan**
| Tingkat | Arti | Contoh |
|---------|------|--------|
| **Blocker** | Tidak bisa lanjut / data hilang / error merah | Quest macet, tombol tidak bisa ditekan, Koin hilang |
| **Mengganggu** | Bisa lanjut tapi bikin kesal / bingung | Teks terpotong, tidak tahu harus ngapain, suara terlalu keras |
| **Saran** | Enak kalau diubah, bukan masalah | Warna kurang pas, ingin animasi lebih lambat |

**Format laporan (salin ke chat, satu baris per temuan)**
```
[Bagian-Nomor] [Tingkat] Apa yang terjadi → apa yang diharapkan. (layar: 844×390 / HP / PC) (screenshot kalau ada)
Contoh: [A-9] [Mengganggu] Tombol Batal tertutup tracker → harusnya terlihat. (844×390)
```
Tempel juga **teks merah/kuning dari panel Output** bila ada. Tidak perlu menebak penyebabnya.

**Tiga pertanyaan "rasa" yang dijawab di akhir tiap sesi (satu kalimat tiap pertanyaan)**
1. Di titik mana kamu **bingung harus ngapain**?
2. Di titik mana kamu **bosan / ingin skip**?
3. Satu momen yang **terasa enak** (supaya tidak dihapus tidak sengaja).

---

## A. Backlog lama "Belum Playtest" (Roadmap R0.5)

> Sebagian sudah dicek di putaran 1–3 (B9–B11). Item yang masih berlaku ditandai di Roadmap R0.5; sisanya tidak dipakai lagi.

> Semua yang selesai di kode tapi belum pernah dirasakan. Lakukan **sebelum** Fase 1 dikerjakan. **Jangan uji** (belum ada di kode): Bubu, Agenda UI, Blueprint, Pajangan, Kebun Warga, Kucing/Joran Hilang. Perilaku hujan saat mancing masih versi lama sampai R1.2.

**A1. Tutorial akun baru**
1. [ ] Tidak ada tombol Lewati.
2. [ ] Siram wajib dilakukan sebelum bisa lanjut.
3. [ ] Panen pertama kualitas Bagus.
4. [ ] Pak Udin muncul dekat; jual lewat bubble "Jual semua" (tanpa GUI jual).
5. [ ] Kak Fajar muncul di sungai dekat lahan; cutscene singkat (< 0,3 dtk jeda), tidak terasa nyangkut.
6. [ ] Menerima Joran + umpan; ikan pertama didapat; jual ikan ke Kak Fajar; banner **Selesai** muncul.
7. [ ] Total XP tutorial 230 (tepat Lv 2, GDD 16.2). Lama: 158.
8. [ ] Selama tutorial, Nek Ani / Pak Amran hanya bilang "Selesaikan tutorial dulu".

**A2. Quest & gerbang fitur**
9. [ ] Akun baru: tidak ada tombol fitur yang belum waktunya.
10. [ ] `!` muncul di Nek Ani (M1, Lv 2) dan Pak Udin (S1); dialog dulu, lalu banner untuk Main.
11. [ ] Quest Side tidak pakai banner (hanya toast).
12. [ ] Tracker Main di atas; tombol `Tunjukkan` menunjuk arah benar; tap baris membuka Quest Log.
13. [ ] Tidak ada sisa layar / overlay setelah menutup dialog atau Quest Log.
14. [ ] Toko Bang Jali hanya menyapa sebelum S3.

**A3. Tampilan & kenyamanan (ulangi di 3 ukuran layar)**
15. [ ] Tombol 32 px nyaman ditekan di HP; **Panen Semua** 40 px.
16. [ ] Bubble instruksi & percakapan tidak memotong teks; minimize / restore jalan.
17. [ ] Toast di tengah bawah bar Koin, tidak menimpa tracker / kolom kanan, maks 3 sekaligus.
18. [ ] Tracker tidak menutup kartu XP atau tombol Craft di layar pendek.
19. [ ] Tombol ♥ hanya muncul dekat papan kebun orang lain; lencana Hadiah tidak terpotong.
20. [ ] Toko: tab sisi tidak bertumpuk; isi terlihat.

**A4. Hadiah (UI-3) & Skill (ST-3)**
21. [ ] Hadiah: 3 tab; klaim Peti Main, Login, Peti Bunga, Title, Milestone berfungsi.
22. [ ] Season digeser jempol, terbuka di hari ini; Premium terkunci.
23. [ ] Tombol Skill **tidak ada** di Lv 1, muncul di Lv 2; 6 dahan.
24. [ ] Node terkunci menampilkan prasyarat; beli memotong SP + Koin; alasan gagal terbaca benar.
25. [ ] "Efek mulai Lv 3" tampil; Tempat Pakan Besar Lv 1–2 tidak mengubah jatah pakan.

**A5. Mancing, Tas, Kolam**
26. [ ] Dengan umpan tunggu ±3–6 dtk. Kolam tanpa umpan ±6–12 dtk. Sungai atau empang tanpa umpan: tidak bisa melempar (K-86).
27. [ ] Chip umpan: nama + jumlah, berkurang 1 tiap lempar; "Umpan habis" muncul.
28. [ ] Tombol Batal terbaca; pemain **tidak bisa jalan** saat memancing; menjauh > 24 stud membatalkan dan umpan kembali.
29. [ ] **Akun kedua melihat** joran, tali, pelampung, dan animasi pemain pertama.
30. [ ] Animasi tampil: FarmPlant, FarmWater, FishingIdle / Cast / Reel / Catch.
31. [ ] Tas: semua tab utuh; Umpan hanya di tab Umpan & Semua.
32. [ ] Kolam: setor 3 ikan, ambil 1, mancing sampai "Kolam masih kosong"; kolam penuh menolak setoran.

**A6. Data & Output**
33. [ ] Keluar-masuk game: Koin, SP, skill, umpan, quest, kolam tetap.
34. [ ] Sesi penuh tanpa error / warning di Output (tempel bila ada).

---

## B. Per Fase (diaktifkan saat Claude Code melapor fase selesai)

### B1. Fase 1 — Perbaikan Konsistensi (R1.1 – R1.11)
1. [ ] **Hujan & mancing (K-01):** saat hujan, waktu tunggu gigitan **sama** seperti cerah, tapi jendela tarik terasa lebih longgar. Mancing 10 kali cerah vs 10 kali hujan, mana lebih santai?
2. [ ] **Belut Emas (K-07):** muncul saat Hujan Deres atau Petir, bukan hanya Petir.
3. [ ] **Resep (K-02/K-03):** di Lv 6 kamu bisa masak lebih dari 4 resep; bahan Jahe (Lv 6), Tebu (Lv 8), Melati (Lv 15) bisa ditanam sesuai level; kartu resep yang bahannya belum terbuka menulis "Butuh … (Lv n)".
4. [ ] **Harga olahan:** Sambal Tomat tidak lagi rugi saat dijual (jual > ongkos bahan).
5. [ ] **Pakan Jagung (K-04):** 1 Jagung jadi 6 jatah.
6. [ ] **Kualitas olahan (K-05):** Ikan Goreng dari ikan Jumbo bisa Prima; Telur/Susu dari Mood Hujan lebih bagus.
7. [ ] **Album (K-06):** menangkap Legenda 4 kali = 4 ukuran berbeda terisi.
8. [ ] **Quest (K-13/K-14/K-15):** semua side quest punya dialog; hadiah side sesuai (Gembor Emas skin, 300 Koin Ringan Tangan, dst.); Title Warga Teladan **tidak ada**.
9. [ ] **Nambang (K-08):** dapat XP dari bahan yang diambil.
10. [ ] **Refund (K-09):** hapus bangunan/dekor = 100% balik; hapus petak = 50%. **Kolam:** tidak ada tombol "Ambil Ikan" timer.
11. [ ] **Tas (K-33):** tab `Semua · Bibit · Panen · Ikan · Olahan · Bahan · Umpan · Alat`; teks gerbang "Terbuka di Level n"; Bahan tidak bisa dijual.
12. [ ] **Skill (K-12):** biaya naik 1.000 → 5.000 per level; skill pertama terasa murah.
13. [ ] **Nama lokasi (K-22/K-23):** tidak ada kata "Spot 4", "Pro/Basic Mancing", "Empang" (kecuali Bundel). Lv 18 menyebut "Kanal Timur malam".

### B2. Fase 2 — Sistem Baru (R2.1 – R2.12)
1. [ ] **Bubu (M8):** pasang malam, ambil pagi, hasil masuk Tas.
2. [ ] **Agenda Harian (M1):** UI terbuka, semua tugas yang sudah terbuka terlihat (Lv 2–3: 3 tugas; Lv 6+: 5; K-80), klaim hadiah jalan; **Papan Hari Ini** menampung Agenda + Surat + Order.
3. [x] **Bantu disembunyikan (K-73, diganti Kebun Warga yang dibatalkan):** lihat B21. Tidak lagi diuji di sini.
4. [ ] **Blueprint:** simpan desain, pasang ulang di lahan sendiri dengan bahan sendiri; **Kirim ke pemain** ke akun kedua; kode tidak bisa dikirim lewat chat.
5. [ ] **Pajangan:** pasang ikan/hasil di pajangan, terlihat oleh pemain lain.
6. [ ] **Event:** event uji bisa selesai → 1 Peti Bunga; tidak bisa diklaim dua kali.
7. [ ] Kucing Alun-alun & Joran Hilang **tidak muncul** (ditunda, K-16).
8. [ ] Tidak ada tombol yang mati / abu-abu.

### B3. Fase 3 — GUI (R3.1 – R3.8)
1. [ ] Kartu pemain di kiri bawah (K-114, bukan kiri atas); tombol Dapur tidak ada di HUD; Dapur dibuka dari Tombol Aksi dekat Tungku.
2. [ ] Satu **Tombol Aksi** (84 px) berubah sesuai yang terdekat: Mancing / Pukul / Tebang / Kandang / Craft / Masak.
3. [ ] Hadiah: kartu Login 7 hari, bar Peti Main, Peti Bunga besar, **Klaim Semua** berfungsi.
4. [ ] Pohon Skill: tiap skill punya ikon sendiri, nama di drawer, pil level `x/5`.
5. [ ] Bubble Instruksi tampil → toast turun di bawahnya, tidak bertabrakan.
6. [ ] Semua teks ≥ 12 px terbaca di 390×844; kualitas (Biasa/Bagus/Prima) terbedakan **tanpa mengandalkan warna saja**.
7. [ ] Pakai satu tangan di HP: semua tombol utama terjangkau jempol.
8. [ ] **Quest Log (K-56):** tombol scroll di dock membuka Quest Log; tab Main · Side · Harian · Pesanan; landscape dua panel (Berjalan / Tersedia / Berikutnya / Selesai); tombol Tandai/Lepas dan Tunjukkan berfungsi; tracker hanya quest bertanda, maks 3.
9. [ ] **Pohon Skill (K-56):** tombol Beli selalu terlihat; bar bawah muncul saat node ditekan (efek, biaya SP + Koin, prasyarat).
10. [ ] **Event (K-57):** tombol "Event" hanya ada saat event aktif; Pasar Malam ada di dunia; Lempar Gelang lewat minigame bar (3 lemparan).

### B4. Fase 4–7 — Aset, Animasi, VFX, Audio
> Yang bisa dinilai hanya owner: **apakah terasa satu gaya & cozy.** Beri masukan untuk contoh pertama (R4.1, R7.1) **sebelum** batch massal bila bisa, tapi Claude Code tidak menunggu.

**Visual (R4.x)**
1. [ ] Contoh gaya (1 tanaman 4 tahap, Kandang Ayam, 1 piece hias, 3 ikon, 1 NPC) terasa satu keluarga dengan palet muted desa.
2. [ ] Tanaman 4 tahap jelas beda dari jauh; siap panen terlihat.
3. [ ] Tiap NPC bisa dibedakan dari siluet.
4. [ ] Ikon item terbaca kecil (44 px) di Tas.
5. [ ] Tidak ada tekstur gelap/silau; hujan dan malam tetap enak dilihat.

**Animasi (R5.x)** — tiap aksi punya gerak:
6. [ ] Tanam, siram, panen, memberi pakan, ambil telur/susu, mancing (lempar-tunggu-tarik-dapat), nambang, tebang, masak, duduk. Gerak tidak terasa kaku/terlalu cepat.
7. [ ] Akun kedua melihat semua animasi pemain pertama.

**VFX (R6.x)**
8. [ ] Panen (beda per kualitas), ikan dapat, critical, masak selesai, level naik, hujan, kunang-kunang malam, Legenda. Tidak mengganggu pandangan; tidak lag.
9. [ ] Momen pertama (panen pertama, ikan pertama, Prima pertama) terasa **dirayakan**.

**Audio (R7.x)**
10. [ ] Setiap aksi di tabel "Juice per Momen" (Asset Bible Bab 11) punya suara; tidak ada yang hening.
11. [ ] Volume: SFX tidak mengalahkan musik; musik tidak melelahkan setelah 30 menit; ada tombol atur volume.
12. [ ] Haptic (HP): ringan, tidak getar berlebihan.
13. [ ] Hujan terdengar menenangkan, bukan berisik.

### B5. Fase 8 — Cerita & Konten
1. [ ] Babak 2 & 3 terasa nyambung dari Babak 1; Surat Kakek (Lv 30) menyentuh, tidak bertele-tele.
2. [ ] Dialog sesuai karakter masing-masing NPC (nada Nek Ani, Pak Udin, Kak Fajar, dst.). **Tulis baris yang terasa janggal.**
3. [ ] Tidak ada quest yang meminta barang yang belum bisa didapat pada level itu.
4. [ ] Hadiah level tinggi terasa pantas.

### B6. Fase 9 — Balancing (R9.1 – R9.2)
> Main 30, 60, dan 120 menit pakai akun baru. Catat tiap 10 menit: **Level, Koin, XP**. Tulis ke tabel ini.

| Menit | Level | Koin | Yang sedang dikerjakan |
|-------|-------|------|------------------------|
| 10 | | | |
| 30 | | | |
| 60 | | | |
| 120 | | | |

1. [ ] Naik level di 10 menit pertama terasa cepat tapi tidak instan.
2. [ ] Di jam ke-2 masih ada tujuan jelas (tidak buntu uang atau buntu level).
3. [ ] Tidak ada satu aktivitas yang jelas "terlalu untung" (semua orang pasti memilihnya).
4. [ ] Beli skill / petak / bangunan terasa terjangkau tapi bermakna.

### B7. Fase 10 — Teknis (R10.x)
1. [ ] **8 pemain** di server uji, hujan + Kerja Bakti: FPS tidak turun di bawah ±30 di HP 4GB, 30 menit tanpa crash.
2. [ ] Lahan dengan banyak dekor (±800 piece) tetap lancar saat dibuka dan ditinggal.
3. [ ] **Kill server** saat main → data (Koin, tanaman, quest) tidak hilang.
4. [ ] Beli Pack Bunga (Developer Product, server uji) → Bunga masuk **sekali**; coba keluar tepat saat membeli.
5. [ ] Perintah DEV **tidak jalan** di server publik.
6. [ ] Loading pertama < ±20 detik di jaringan biasa.

### B8. Fase 11 — Rilis
1. [ ] Halaman game: ikon, thumbnail, deskripsi, rating usia sesuai.
2. [ ] Alur main dari tombol Play sampai Lv 10 mulus untuk pemain baru (minta 1–2 teman mencoba **tanpa dibantu**, catat tempat mereka bingung).
3. [ ] Tidak ada teks Inggris/placeholder tersisa.

---

### B9. Putaran 1 (K-53 … K-57)
1. [ ] **Garap (K-53):** ketuk sekali = sorot; ketuk lagi = tanam; yang tertanam sama dengan sel yang disorot; outline hilang saat keluar mode.
2. [ ] **Toast (K-53):** di bawah Koin/Bunga, tidak menutupi HUD; di bawah Bubble Instruksi bila tampil.
3. [ ] **Kartu pemain (K-53):** pill "Lv n" terlihat; slot buff kosong tidak tampil.
4. [ ] **"!" quest (K-53):** muncul di atas Nek Ani dan pemberi quest lain yang menawarkan quest.
5. [ ] **Bang Jali (K-53):** sebelum S3 "Terbuka di Level n"; sesudah "Jual / Beli" (sejak 2026-11-23; "Jual semua panen" hanya tutorial).
6. [ ] **Tutorial panen (K-54):** setelah panen pertama, 5 Garap lagi, 6 bibit Kangkung gratis, tunggu semua panen, baru Pak Udin.
7. [ ] **Tutorial mancing (K-54):** tangkapan 1–2 hanya bubble Instruksi; tangkapan ke-3 cutscene Kak Fajar, lalu jual.
8. [ ] **Pakai di Tas (K-55):** Pancing dan umpan bisa dipakai; badge Dipakai; umpan habis pindah ke umpan lain + toast; setelah rejoin tetap terpasang.
9. [ ] **Tarik (K-55):** tombol Tarik di slot Tombol Aksi; Pancing dan Tarik tidak tertimpa.
10. [ ] **Harian & Mingguan (K-56):** tidak ada templat yang belum terbuka; "Bantu lahan" tidak ada di sana, tetapi ada di Season (500 Koin).
11. [ ] **Event (K-57):** tombol "Event" hanya saat event aktif.

### B10. Putaran 2 (K-58 … K-65): owner cek di HP
Tes AI sudah dijalankan di Studio untuk yang disebut "terverifikasi". Sisanya harus dicek di HP.
1. [ ] **Papan (R2.2):** tombol "Papan" di HUD muncul setelah quest "Kampung Hari Ini" mulai; isi: tugas hari ini dengan progres x/n, Selesai bila tuntas.
2. [ ] **Garap (K-53):** ketuk sekali sorot, ketuk lagi tanam; di 844x390, 667x375, 390x844.
3. [ ] **Toast (K-53):** di bawah Koin/Bunga, tidak menutupi HUD.
4. [ ] **Bang Jali (K-53):** di Lv 3 kepalanya ada "!" (terverifikasi di Studio); bubble "Terbuka di Level 3 ..." / "Jual 1 barang ke saya dulu ..." terbaca.
5. [ ] **Pakai di Tas (K-55):** pancing dan umpan bisa dipakai; badge Dipakai.
6. [ ] **Tarik (K-55):** tombol Tarik di slot Tombol Aksi saat ikan menarik.
7. [ ] **Skill (K-56):** tombol Tingkatkan terlihat saat node ditekan (bar bawah).
8. [ ] **Quest (K-56):** Harian dan Mingguan hanya memuat quest yang bisa dikerjakan.
9. [ ] **DEV (K-64):** akun owner bisa memakai `!state`, `!skenario`, `!skip tutorial` di game terbit. Sebelum rilis: `LIVE_ENABLED = false`.
10. [ ] **"!" (fix):** tanda "!" di atas setiap pemberi quest yang punya quest Tersedia, terlihat dari jarak jauh (sampai 200 studs), satu per pemberi, tidak tampak di layar judul. Studio: 0 sebelum main.
11. [ ] **Bubu (R2.1b), alur lengkap:** beli Bubu Bambu di Pak Udin (400 Koin, bagian Kebutuhan) → berdiri di sungai dekat titik mancing → tombol **Pasang** muncul di kiri Pancing → pasang → tiang di sungai "belum siap" → tunggu 6 jam (atau `!tumbuh` di DEV) → label **SIAP!** dan tombol berubah **Ambil** → tap Ambil → ikan masuk tas, tiang hilang. Maks 3 bubu. Tidak bisa Ambil sebelum siap.
12. [ ] **Panel DEV:** tab "DEV" bisa dibuka dan tombolnya berfungsi (Studio tidak bisa menekan tombol; cek di HP).
13. [ ] **Ambil dengan tap sungguhan (R2.1b, belum terbukti):** tekan tombol **Ambil** di HP saat bubu siap (Studio hanya memicu remote yang sama; tombol fisik belum diklik). Ambil harus memberi ikan dan tiang hilang.
14. [ ] **Tracker Quest (D4, temuan Task 4):** di HP, tracker kanan atas hanya menampilkan sekitar 6 baris lalu "+N lainnya". Quest yang aktif tidak bisa dibaca semua; cek apakah ini membingungkan. Ditangani di Task 6 (Quest Log).

### B11. Putaran 3 (2026-11-23, video dan HP): F1–F8

Cek ini untuk perbaikan dari video playthrough. Satu tugas F = satu centang. Tes Studio tidak menggantikan cek HP.
1. [ ] **F1 Sorot tutorial (GUI 4.6):** di langkah Garap (pertama) dan Aksi Pancing (tangkapan pertama) ada gelap dengan **satu lubang** di tombol itu saja. Di langkah Tanam, Siram, Panen (pill di atas petak), dan Jual tidak ada gelap, hanya outline kuning. Joystick, kamera, dan semua tombol bisa ditekan di setiap langkah. *Kode F1a selesai; cek HP belum.*
2. [ ] **F2 Satu permukaan instruksi (GUI 4.6):** di langkah pertama (aksi pertama) hanya bubble coachmark; di pengulangan hanya toast. Tidak pernah dua-duanya untuk teks yang sama. *Belum di kode: cek setelah F2 selesai.*
3. [ ] **F3 Aksi bulat (GUI 6.12):** Tarik sudah bulat sama dengan Pancing. Cek juga **Pasang**, **Ambil**, dan **Panen Semua**: semuanya bulat dengan ukuran dan cincin yang sama. *Pasang dan Panen Semua belum di kode.*
4. [ ] **F4 Tracker stabil:** beli Bayam di Pak Udin → quest "Bibit Kedua" mulai → tracker tetap tampil dan memuat langkahnya. Tanam 2 Bayam → quest selesai → tracker berubah dan tidak hilang tanpa alasan.
5. [ ] **F5 Quest Log dari dua pintu (GUI 6.8):** di tiga keadaan (ada quest aktif, baru selesai, tidak ada quest aktif), tap ikon bintang di kolom kanan dan tap tracker: Quest Log terbuka dua-duanya. Bintang punya badge untuk quest baru. Quest yang mulai otomatis dari pembelian muncul toast "Quest baru: <judul>".
6. [ ] **F6 "!" pemberi:** "!" tampil di atas Mak Sari dan Nek Ani saat quest mereka Tersedia (Quest Log menulisnya). Cek juga setelah quest side dari pembelian mulai dan setelah keluar-masuk game.
7. [ ] **F7 Pak Udin setelah tutorial:** dialog menawarkan **Jual / Beli** (membuka panel toko) dan **Sampai jumpa**. "Jual semua panen (N%)" tidak muncul di luar langkah jual tutorial.
8. [ ] **F8 Pill normal tap:** di HP, satu ketukan biasa pada pill Tanam, Siram, atau Panen langsung menjalankan aksi (pada petak kosong, siap panen, dan kering). Tahan setengah detik membuka menu hanya untuk petak kosong. Ulangi 5 kali.
9. [ ] **Bubu fisik:** di HP, tap tombol **Ambil** saat bubu siap (bukan lewat remote Studio). Ikan masuk, tiang hilang.

**Tutorial penuh di HP (dulu B12, BLOCKER 2026-11-23):** gelap hanya satu lubang di tombol Garap dan Aksi Pancing, pertama kali (F1). Joystick selalu bisa dipakai.
T1. [ ] **Akun baru**, mulai tutorial dari awal (Mak Sari). Setiap langkah ada satu kalimat yang terlihat (toast atau bubble) dan satu target (panah atau tombol berkedip).
T2. [ ] **Tunggu semua tumbuh:** tidak ada gelap (langkah pengulangan = toast), joystick bisa dipakai, pill Panen bisa diketuk, panen semua selesai, lalu langkah lanjut ke Jual.
T3. [ ] **Jual ke Pak Udin:** panah di tanah terlihat, joystick bisa dipakai saat berjalan.
T4. [ ] **Mancing:** tangkapan pertama lewat bubble coachmark; tangkapan ke-2 dan ke-3 hanya toast.
T5. [ ] **Tidak pernah terkunci:** tidak ada langkah di mana karakter tidak bisa jalan. Bila itu terjadi, catat langkahnya dan kirim screenshot.
T6. [ ] **Cutscene Jual Pertama:** setelah sekitar 1 menit tanpa menjual, gerak kembali sendiri.

## G. Gate Checklist

### G1 — Vertical Slice (Lv 1–10 lengkap + aset + audio)
- [ ] Akun baru main **2 jam** (Lv 1 → 10) tanpa buntu dan tanpa "terus ngapain?".
- [ ] Semua aksi Lv 1–10 punya animasi + VFX + SFX.
- [ ] 2 pemain di server: FPS ≥ 30 di HP 4GB.
- [ ] Menit tiap naik level dicatat (untuk R9.1).
- [ ] Tidak ada temuan **Blocker** terbuka.
- Jawab satu kalimat: *"Ini sudah terasa seperti game jadi?"* Ya / Belum, karena …

### G3 — Release Candidate
- [ ] 8 pemain, hujan + Kerja Bakti, 30 menit tanpa crash, FPS ≥ 30.
- [ ] Ekonomi 30 & 60 menit sesuai rencana (B6).
- [ ] Pack Bunga aman; kill server aman; DEV mati di server publik.
- [ ] Tidak ada **Blocker**, dan **Mengganggu** tersisa ≤ 5.

---

## H. Riwayat Putaran Playtest

| Putaran | Tanggal | Bagian diuji | Ringkasan temuan (jumlah B / M / S) | Keputusan revisi tercatat (K-nn rev.) |
|---------|---------|--------------|-------------------------------------|----------------------------------------|
| 1 | 2026-11-23 | Owner, HP (844×390, 667×375, 390×844) | 18 temuan (#1–#18): A bug, B tutorial, C mancing UI, D quest, E event | K-53 … K-57 |
| 2 | 2026-11-23 | Owner (lanjutan putaran 1), HP | Lanjutan: R2.x, Quest Log, Season, E2/E3, Gembor (lihat Roadmap Bab 20) | K-58 … K-63 |
| 3 | 2026-11-23 | Owner, video PC 8:21 + HP | F1–F8 (sorot satu lubang pertama kali, satu permukaan instruksi, Aksi bulat, tracker, Quest Log, "!", Pak Udin, pill) | K-66 (auto), GUI 4.6, 6.12 |

> Masukan yang mengubah **aturan desain** (bukan bug) dicatat Claude sebagai `K-nn rev.` di `02_Audit_Perbaikan.md` Bab 3.6, lalu GDD naik versi (v8.2, …). Bug cukup jadi tugas `R…` baru.

---

## DEV (cara pakai untuk owner)

Perintah ini hanya untuk akun owner (dan Studio). Diisi di chat game, diawali `!`.

- Panel DEV: tombol di layar (hanya untuk akun owner). Isinya sama dengan perintah di bawah.
- `!state`: cetak level, Koin, fitur terbuka, quest aktif, dan barang terpasang.
- `!skenario <nama>`: isi cepat, contoh `pasca_tutorial`, `lv6_dapur`, `lv10_penuh`, `mancing`, `kandang`, `hujan_deres`, `event_agustusan`, `pasar_malam`, `solo_server`.
- Panel DEV di layar: tab kecil "DEV" di tepi kiri (hanya untuk akun owner dan Studio). Ketuk untuk membuka daftar: Status, Lewati tutorial, Level +1, Koin +1000, Buka semua fitur, Cuaca (ganti), Waktu (ganti), Tumbuh, Hari +1, Teleport ke NPC, Skenario, dan Reset (ketuk dua kali).
- `!bubu pasang <bambu|kayu|besi>` (berdiri di sungai dekat titik mancing, punya item bubu), `!bubu ambil <nomor>`. `!tumbuh` juga memajukan bubu ke siap.
- `!teleport <npc>`, `!hari +N` (roll ulang pool harian, mingguan, agenda, dan order), `!buka semua`, `!quest mulai <id>`, `!quest selesai <id>`, `!lapor <event> [n]`.
- `!reset`, `!level N`, `!xp N`, `!koin N`, `!bunga N`, `!sp N`, `!buka <fitur|semua>`, `!quest <id> [langkah]`, `!quest selesai <id>`, `!give <item> [n]`, `!equip <item>`, `!cuaca <cerah|gerimis|deres|petir>`, `!waktu <pagi|siang|sore|malam>`, `!tumbuh`, `!hari +N`, `!event <nama|off>`, `!pasar on|off`, `!teleport <npc|lokasi>`.

Catatan: di Studio, profil yang gagal dimuat dipakai dari memori (tidak tersimpan).


### B12. Toast dan langkah pengulangan (TB, 2026-11-23)

1. [ ] **Posisi toast:** toast muncul tepat di bawah bar Koin/Bunga di atas, bukan di atas dock. Dua chip paling banyak, yang terbaru di atas, tidak saling tumpang tindih.
2. [ ] **Tidak menutupi dock:** saat langkah Garap dan Tanam aktif (ada bubble coachmark), toast tidak menutupi tombol Garap, Tas, atau Aksi.
3. [ ] **Pengulangan = toast saja:** di langkah garap_5 dan tanam_5 tidak ada bubble coachmark dan tidak ada ring di tombol Garap. Hanya toast.
4. [ ] **Hint sesuai aksi:** setelah panen pertama dan ada petak kosong dengan bibit di tas, hint berisi Tanam (bukan "Tap Garap dulu") selama popup Tanam dibuka.
5. [ ] **Teks tidak terpotong:** toast dengan kalimat panjang terbaca penuh (dua baris paling banyak), tidak "...ga jual naik".

### B13. Mak Sari setelah panen pertama (MS, 2026-11-23)

1. [ ] **Bubble muncul sekali:** setelah panen pertama, Mak Sari berbicara lewat bubble bawah (wajah, nama, teks, tombol Next), bukan toast. Teks: "Wah, panen pertamamu berhasil, Nak!" lalu "Sekarang bikin 5 petak lagi...".
2. [ ] **Bisa jalan:** saat bubble tampil, joystick dan tombol dock tetap bisa dipakai; layar tidak gelap.
3. [ ] **Tutup dan simpan:** tekan Next sampai habis. Keluar lalu masuk lagi: bubble tidak muncul lagi.
4. [ ] **Pengingat toast:** setelah bubble, pengingat berupa toast "Tap Garap, lalu Cangkul: n/5 petak baru" di bawah bar Koin, tanpa bubble dan tanpa ring di tombol Garap.

### B14. Mak Sari tiga tahap dan pengingat (MS-2, 2026-11-23)

1. [ ] **Posisi bubble:** bubble Mak Sari (ketiga tahap) berada di atas baris dock. Tombol Garap, Tas, dan Aksi tetap terlihat dan bisa ditekan, di 844×390, 667×375, dan 390×844.
2. [ ] **Ring Garap:** saat tahap garap_5 aktif, tombol Garap punya satu lingkaran kuning bulat, tanpa gelap. Ring hilang saat mode Garap dibuka.
3. [ ] **Toast tersemat:** "Tap Garap, lalu Cangkul: n/5 petak baru" tetap terlihat sampai 5 petak baru ada. Toast lain tidak menimpanya.
4. [ ] **Tahap 2:** saat 5 petak baru selesai, bubble "Nah, coba tanam lagi 6 bibit dari Mak." muncul sekali.
5. [ ] **Tahap 3:** saat ada tanaman siap panen, bubble "Jangan lupa panen semuanya ya, Nak." muncul sekali.
6. [ ] **Bisa jalan:** saat bubble tampil, joystick dan Garap tetap bisa dipakai. Layar tidak gelap.
7. [ ] **Keluar-masuk:** setelah tahap ditutup lalu game dimasuki lagi, tahap itu tidak muncul lagi.

### B16. Tutorial 15 langkah (GDD 16.2): verified by owner (2026-11-24)

Claude tidak menjalankan Play lagi untuk bagian ini. Owner yang tes dan menandai tiap langkah dengan **verified by owner** (`[x]`). Dari fresh save (`!reset`), mulai dari PLAY.

Status 2026-11-24: **semua 15 langkah sudah verified by owner** (centang di halaman checklist, tersimpan di db artifact `A6NTqsiwqJZVHRYCZJFetx`). Waktu dari PLAY sampai Lv 2 menurut owner: **2 menit** (catatan langkah 15).

1. [x] **PLAY:** tombol PLAY di layar judul bisa ditekan dan masuk ke game. *Verified by owner.*
2. [x] **sapa:** dialog Mak Sari di awal sampai "Garap tanahnya dulu" (intro). *Verified by owner.*
3. [x] **cangkul:** tombol Garap, ketuk rumput, petak pertama terbentuk. *Verified by owner.*
4. [x] **tanam:** ketuk petak, pilih Kangkung di cincin Tanam. *Verified by owner.*
5. [x] **siram:** siram petak. Tanpa tanda hitung mundur saat ditahan (K-71). Setelah siram, timer jalan dan petak jadi "Panen!". *Verified by owner.*
6. [x] **panen_1:** panen petak pertama. *Verified by owner.*
7. [x] **garap_5:** buat 5 petak baru. *Verified by owner.* (Claude macet di 4/5 saat tes remote; owner lulus.)
8. [x] **tanam_5:** tanam 6 bibit gratis. *Verified by owner.* Masih perlu dicek apakah bed yang ditahan sampai disiram (K-71) memang diinginkan.
9. [x] **tunggu_semua:** tunggu sampai semua siap panen, lalu panen semua. *Verified by owner.*
10. [x] **panen_jual:** jual 1 ke Pak Udin. *Verified by owner.*
11. [x] **warung:** Ok di dialog Pak Udin. *Verified by owner.*
12. [x] **kak_fajar:** terima hadiah Joran Bambu dan umpan Cacing di sungai. *Verified by owner.*
13. [x] **mancing:** 3 ikan tertangkap (tangkapan ke-2 dan ke-3 hanya toast). *Verified by owner.*
14. [x] **jual_ikan:** jual ikan ke Kak Fajar, Ok, dan naik ke Lv 2 (230 XP). *Verified by owner.*
15. [x] **Waktu:** 2 menit dari PLAY sampai Lv 2 (catatan owner). *Verified by owner.*

### B17. SFX pertama: panen, siram, gigitan (R7.3, 2026-11-24): dengar di HP

Owner cek dengan telinga. Suara panen (`farm_harvest` = "cartoon pluck", 0.267 s) dan gigitan (`fish_bite` = "cartoon plop sound", 0.540 s) sudah berisi id dari toolbox, belum pernah dimainkan di Play. Owner cek volume dan karakternya.

1. [x] **Siram:** satu suara air saat siram satu petak, tidak keras (di HP dengan volume sedang). Drag siram di banyak petak sekaligus terdengar **satu** suara, tidak bertumpuk.
2. [x] **Panen:** satu suara pluck saat panen satu petak. Panen banyak (jika dibuka) juga satu suara, tidak bertumpuk.
3. [x] **Gigitan:** satu suara plop saat ikan menggigit, sebelum mini-game tarik. Tidak keras dan tidak menimpa suara reel.

### B18. Hujan visual (R6.5, 2026-11-24): cek di HP

Partikel hujan dibuat Claude di kode (client, satu emitter), belum pernah dimainkan di Play. Owner cek di HP dengan Pengaturan > Kualitas gambar.

1. [ ] **Lembut, tidak keras:** hujan terlihat tipis dan tidak menutupi layar, di Sedang dan Tinggi.
2. [ ] **FPS tidak turun saat hujan:** main satu hujan penuh (3 menit) tanpa patah-patah yang terasa. Coba juga saat Deres atau Petir.
3. [ ] **Berhenti rapi:** saat hujan selesai, partikel memudar sekitar 3 detik lalu hilang, tanpa muncul atau hilang mendadak. Kualitas Rendah: tidak ada hujan sama sekali.

### B19. Bibit habis (T3, K-72, 2026-11-24): cek di HP

Toast Ok untuk bibit habis. Belum pernah dimainkan di Play. Butir 5 di B15 (Ok menutup) dicek di sini juga.

1. [ ] **Muncul:** tanam di petak saat bibit tanaman itu habis: muncul satu toast "Bibit ... habis. Beli di Pak Udin" di bawah bar Koin/Bunga, dengan tombol Ok.
2. [ ] **Tidak hilang sendiri:** toast tetap ada sampai ditekan Ok (lebih dari 10 detik).
3. [ ] **Ok menutup:** tekan Ok, toast hilang. Joystick dan tombol lain tetap bisa dipakai selama toast ada (tidak ada gelap di layar).
4. [ ] **Beli bibit menutup:** dengan toast masih ada, beli bibit di Pak Udin. Toast hilang tanpa perlu Ok.

### B20. Surat, Gerobak, Pesanan dibuka dari M1 (R2.3, K-74): cek di HP

Belum pernah dimainkan di Play. Pakai akun baru atau save Lv 2 tanpa M1.

1. [ ] **Surat #1 (S2):** setelah Lv 2 dan tutorial selesai, baris "Surat Kakek #1" muncul di tracker. Tap baris itu: surat tampil sebagai toast, dan Quest "Surat Pertama" selesai (hadiah Surat #1).
2. [ ] **Gerobak (M1):** Lihat Gerobak Kaget = buka panel Acara lalu tab Gerobak. M1 selesai setelah itu; tab Gerobak tidak tampil sebelumnya.
3. [ ] **Pesanan:** tombol Pesanan tidak tampil sampai M1 mulai (Agenda terbuka). Sesudah itu tampil.
4. [ ] **Tutorial tidak berubah:** 15 langkah tetap sama (sudah diverifikasi owner di B16).

### B21. Bantu disembunyikan (R2.5, K-73): cek di HP

Belum pernah dimainkan di Play. Pakai akun yang sudah Lv 6 dengan Hutan dan Dapur terbuka, supaya Agenda penuh.

1. [ ] **Bantu tidak ada di mana pun:** tidak ada tombol Warga di HUD, tidak ada baris "Bantu Tetangga" saat berdiri di lahan orang lain, tidak ada quest "Tetangga Baik" di tracker.
2. [ ] **Agenda 5 tugas tanpa Bantu:** Papan Hari Ini menampilkan Panen, Mancing, Tanam 5, Masak 1, Nambang 10. Tidak ada "Bantu 1".
3. [ ] **Surat tetap jalan:** surat 6 (dan 13, 20, 29) tidak berhenti. Surat berikutnya bisa dicapai; toast hadiah surat (K-83) tampil untuk surat yang minta Bantu, dengan kalimat tanpa kata "Bantu".

### B22. Gerbang Lv 0–10 (R2.G1–G3, K-75–K-77): cek di HP

Belum pernah dimainkan di Play.

1. [ ] **Warga solo:** akun sendirian di server. Tombol Warga tidak tampil (bukan tombol kosong).
2. [ ] **Warga dua pemain:** saat akun kedua masuk, tombol Warga muncul di akun pertama; saat akun kedua keluar, tombol hilang lagi.
3. [ ] **Skill Tetangga Baik tidak ada:** di Pohon Skill (Sosial) tidak ada skill Tetangga Baik. Skill lain tetap bisa dibeli.
4. [ ] **Surat tanpa Bantu:** surat 6, 13, 20, 29 tidak menyebut Bantu. Jika toast surat muncul di layar, kalimatnya wajar tanpa kata "Bantu".
5. [ ] **Kerja Bakti bukan langkah tes solo (K-79):** tidak ada langkah di B22 yang menunggu Kerja Bakti. Ia hanya muncul setelah hujan Deres atau Petir berakhir dan setelah M1 langkah 3. Quest "Pekerja Bakti" (Lv 2, K-81) boleh menunggu cuaca; jangan dihitung sebagai gagal.
7. [ ] **Toast hadiah surat (K-83):** saat surat 6 jatuh tempo (login ke-6, atau setelah ada kejadian kebun), muncul satu toast "Surat Kakek #6: ... Hadiah +80 Koin." Koin benar-benar bertambah, walau Surat belum dibuka di Lv 1. Surat 13, 20, 29 sama (20 dan 29 juga menyebut Bunga).
6. [ ] **Pekerja Bakti mulai di Lv 2 (K-81):** di Lv 1 Nek Ani belum menawarkan "Kerja Bakti 10x". Di Lv 2 (setelah M1 mulai) tawaran muncul di daftar quest.

### B23. Putaran 4 (owner playtest 2026-11-24, K-84–K-89): cek di HP dan PC

Belum pernah dimainkan di Play. Claude tidak menandai apa pun VERIFIED.

1. [ ] **Jual Pertama, kamera (K-84):** saat Pak Udin mulai bicara, kamera lebar tampak dari dekat pohon. Pak Udin, warungnya, dan bangunan di sekitar terlihat. Rambut dan badan avatar tidak menutupi layar. Pemain berjalan masuk ke frame, Pak Udin menoleh, lalu dialog mulai. Tidak ada tombol skip.
2. [ ] **Umpan wajib di sungai (K-86):** habiskan semua umpan, lalu coba lempar di sungai. Tombol Pancing mati, chip berkata "Umpan habis, beli di Kak Fajar". Di kolam sendiri lemparan tetap bisa tanpa umpan.
3. [ ] **Mancing, toast tersemat (K-85):** di langkah "Tangkap 3 ikan" ada toast "Tangkap 3 ikan buat Kak Fajar: 0/3". Tiap ikan menaikkan hitungan (1/3, 2/3, 3/3). Toast tidak hilang sendiri. Setelah ikan ke-3, toast hilang bersama langkah.
4. [ ] **Pak Kumis, teks (K-87):** saat Pasar Malam tampil Pak Kumis, bubble menampilkan kalimat sapaan (bukan `npc.pak_kumis.greet`). Portret masih kosong: ini sengaja, menunggu gambar dari owner.
5. [ ] **Ok toast, bibit habis (K-88):** tanam tanpa bibit sampai toast "Bibit habis" muncul. Tombol Ok sama gayanya dengan tombol lain di panel (bukan kotak lain), tingginya sama dengan tombol panel, dan tidak terpotong. Ketuk Ok: toast hilang.
6. [ ] **Naik level, toast berurutan (K-89):** saat naik level yang membuka sesuatu, banner LEVEL muncul. Toast "Naik ke Level n!" tampil dulu, lalu "Terbuka: …" satu per satu. Tidak ada dua toast naik level yang tampil bersamaan dan keduanya tidak hilang bersama.

### B15. Satu toast (T0, 2026-11-23): owner cek di HP dan PC

Aturan: GUI 4.2. Satu tempat (di bawah Koin/Bunga), satu gaya krem.

1. [ ] **Tidak tumpang tindih (844×390):** saat ada dua toast + toast tersemat, tidak ada yang menutupi bar Koin/Bunga, dock, atau tombol Aksi bulat.
2. [ ] **Tidak tumpang tindih (667×375):** sama seperti 1.
3. [ ] **Tidak tumpang tindih (390×844, portrait):** sama seperti 1.
4. [ ] **Tersemat tidak tertutup:** saat tanam_5 / garap_5 aktif dan toast lain muncul (mis. "Bibit ditanam"), toast tersemat tetap terlihat di atas.
5. [ ] **Ok menutup:** toast dengan tombol Ok (mis. "Bibit habis", bila sudah ada) menutup saat Ok ditekan, dan tidak hilang sendiri.
6. [ ] **Hitungan garap_5:** "Tap Garap, lalu Cangkul: n/5" naik langsung setiap petak selesai digali; tidak pernah 4/5 saat sudah 5 petak.
7. [ ] **Tidak ada dua instruksi:** satu langkah tutorial hanya menampilkan satu teks (bubble atau toast, bukan keduanya). Pil cokelat coachmark tidak ada lagi.
8. [ ] **Mancing:** status "Menunggu…" di strip bawah berwarna krem dan tidak menutupi dock atau tombol Aksi.

### B24. Putaran 5 quest (owner playtest 2026-11-24, K-92…): cek di HP

Belum pernah dimainkan di Play. Claude tidak menandai apa pun VERIFIED.

1. [ ] **Tracker tetap tampil saat bicara (K-92):** ambil quest dari NPC. Tracker di kiri tidak hilang selama dialog dan setelahnya.
2. [ ] **Turn-in (K-93):** selesaikan satu Side dari NPC (mis. Pak Udin). Quest jadi "Siap diserahkan" di tracker, ada "!" di atas pemberinya. Hadiah belum masuk. Bicara dengan pemberi: dialog penutup, lalu Koin/XP bertambah.
3. [ ] **Track (K-94):** di Quest Log, Track dan Lepas bekerja. Ada 3 slot. Tombol Track ke-4 memberi toast "maks 3 quest dilacak".
4. [ ] **Kanal Barat (K-97):** saat naik ke Lv 5, banner Level lalu baris "Terbuka: Kanal Barat (temui Kak Fajar)". "!" di atas Kak Fajar dan panah ke dia.
5. [ ] **Quest Log satu panel (butir 2):** dock bawah punya tombol Quest (bukan Pesanan), dan kartu pemain punya tombol Quest kecil. Keduanya membuka panel yang sama dengan 4 tab: Main, Side, Harian, Pesanan. Tab Pesanan berisi order Villager. Tidak ada panel Pesanan terpisah.
6. [ ] **Track / Lepas (butir 3):** tiap baris quest punya Track atau Lepas. Quest yang dilacak muncul di tracker kiri, dengan panah ke pemberi atau tujuannya di tepi layar. Tombol Tunjukkan menaruh panah ke target selama beberapa detik.
7. [ ] **Surat Kakek S2 (butir 5):** ambil "Surat Pertama" dari Mak Sari. Baris Surat #1 di tracker punya tombol Baca dan baris S2 juga. Ketuk Baca: surat tampil. Setelah itu quest "Siap diserahkan ke Mak Sari", "!" di atas Mak Sari, lalu bicara dengan Mak Sari untuk menyerahkan.
8. [ ] **Kerja Bakti (butir 6):** di Acara dan Quest Log tidak ada baris "Tidak ada Kerja Bakti sekarang". Kerja Bakti hanya muncul saat acaranya jalan.
9. [ ] **M6 Dapur (butir 8):** langkah "Pasang Tungku di lahanmu lewat panel Dapur" ada di tracker tanpa panah (sengaja, R5.8a dan R5.8b). Setelah Tungku berdiri, "Masak 1 olahan" dan "Makan 1 olahan" menunjuk ke Tungku. Owner cek: apakah langkah pertama sudah cukup jelas di HP.
10. [ ] **Serah-terima jauh (K-100):** dengan quest siap diserahkan, jauh dari pemberi lalu tekan Ngobrol dari dekat. Hadiah dibayar hanya saat dekat. Toast "Dekati … dulu" muncul bila remote ditolak.
11. [ ] **Tungku, craft (R5.8a, K-101):** di Meja Crafting, Lv 6, craft "Tungku" (10 Kayu, 8 Batu, 5 Tanah Liat). Tidak ada x10. Tungku kedua tidak bisa dibuat selama punya satu.
12. [ ] **Tungku, pasang (K-102):** dengan Tungku di tas dan belum punya dapur, tombol Aksi berlabel "Pasang Tungku" muncul. Ketuk: Tungku berdiri di lahan (2×2).
13. [ ] **Masak di Tungku (K-102):** dekat Tungku sendiri, tombol Aksi berlabel "Masak" muncul dan membuka panel Dapur. Menjauh, tombol hilang.
14. [ ] **Tidak ada tombol Dapur di dock:** dock bawah hanya Garap, Kolam, Hias, Tas, Quest. Tidak ada tombol Dapur.
15. [ ] **M6, jalan lengkap (K-103):** Craft Tungku (panah ke Meja Crafting), lalu "Pasang Tungku di lahanmu" (panah ke lahanmu, tombol Aksi "Pasang Tungku"), lalu "Masak 1 olahan di Tungku" (panah ke Tungku, tombol Aksi "Masak"), lalu "Makan 1 olahan" (panah ke Tungku).
16. [ ] **Dock 4 tombol (K-104):** dock bawah hanya Garap, Hias, Tas, Quest. Tidak ada Kolam di dock.
17. [ ] **Kolam dari ≡ dan Aksi (K-104):** Kolam ada sebagai ubin di menu ≡ (mode Garap kolam). Dekat kolam sendiri, tombol Aksi "Kolam" muncul dan membuka panel Kolam.
18. [ ] **Prioritas slot Aksi (K-104):** berdiri di antara kolam dan node tambang. Tombol yang tampil adalah yang lebih dekat. Jarak sama: tombol untuk quest yang dilacak yang tampil. Tidak ada dua tombol Aksi bersamaan.

### B25. Putaran 6 (owner playtest 2026-11-24, kamera, NPC, memancing, quest): cek di HP

Belum pernah dimainkan di Play. Claude tidak menandai apa pun VERIFIED.

1. [ ] **Jual Pertama, kamera (K-105):** saat mendekati Pak Udin, layar jadi hitam, lalu fade masuk di shot dekat (wajah Pak Udin dan avatar terlihat, seperti adegan Mak Sari). Tidak ada jalan masuk frame.
2. [ ] **NPC menoleh (K-106):** tekan Ngobrol ke Pak Udin (atau NPC lain). Dia menoleh ke kamu dalam sekitar 0,35 dtk. Tutup dialog: dia kembali ke arah semula. Cek di HP kedua (pemain lain) juga melihat dia menoleh.
3. [ ] **Kamera setelah "3 ikan" (K-107):** selesaikan langkah tangkap 3 ikan dan jual. Kamera tetap di belakang avatar, tidak kembali ke shot Pak Udin. Bicara dengan NPC lalu tutup: kamera kembali ke pemain.
4. [ ] **Pelampung di air (K-108):** lempar di sungai atau kolam. Pelampung mendarat di permukaan air, tidak di pasir atau tepi. Lintasan terlihat terbang dari ujung joran, lalu cipratan, lalu mengambang. Saat gigitan, pelampung turun sebentar. Pemain lain melihat hal yang sama. Setelah tarik atau batal, pelampung hilang. Bila ada spot tanpa air, log output menulis `[Bobber]`: kirim nama spotnya.
5. [ ] **Ikon Quest (K-109):** tombol Quest di dock memakai ikon gulungan (seperti Pesanan dulu). Bintang di kolom kanan (Hadiah) tetap bintang. Keduanya tampak berbeda.
6. [ ] **Lepas bersih (K-110):** lacak quest yang punya tujuan NPC lalu Lepas. Panah dan "!" di NPC hilang, dan tidak ada label nama yang tersisa. Panah di layar tampil di atas kepala, di luar layar di tepi.
7. [ ] **Tracker terlihat di kiri (K-111):** di Lv 2 dengan quest aktif, tracker tampil di kiri, tepat di atas kartu pemain (yang tetap di kiri bawah), dengan baris quest Main. Kalau tidak, kirim screenshot dan nama quest yang aktif. Catatan: kartu pemain di kode masih kiri bawah (lihat K-111).
8. [ ] **Tidak ada tombol Quest di kartu (K-112):** kartu pemain di kiri hanya foto, level, nama, bar XP, dan buff. Tidak ada tombol Quest. Quest Log dibuka dari dock.
9. [ ] **Cari (K-113):** di Quest Log, tombol Cari (dulu Tunjukkan) ada di baris yang punya tujuan. Ketuk: log menutup, dan satu "!" muncul di atas target. Ia naik-turun 3 kali lalu pudar. Tidak ada panah yang tertinggal dan tracker tidak berubah. Track / Lepas tetap bekerja seperti biasa.
10. [ ] **Tracker di atas kartu (K-114):** tracker berdiri tepat di atas kartu pemain, tepi kirinya sama dengan kartu. Kartu tetap di kiri bawah dan tidak pindah. Di HP landscape dan portrait, tracker tidak menimpa bar atas, bar mata uang, kolom ≡, tombol Aksi, dan dock. Quest bisa dilacak dan dibuka dengan mengetuk tracker.
11. [ ] **Jari di sisi kiri (K-114):** dengan satu jari di kiri layar (joystick), gerak tetap jalan. Tracker tidak menahan sentuhan di luar barisnya.
12. [ ] **Pintu masuk kolam satu (K-115):** ubin Kolam di menu ≡ dan tombol Aksi Kolam dekat kolam sendiri membuka panel yang sama (Breeding Kolam). Di atas panel ada "Bangun Kolam" bila kamu boleh membangun lagi. Tap: mode gali kolam aktif dan panel tertutup. Tidak ada tombol Kolam di Garap.
13. [ ] **Satu tempat Aksi (K-116):** Pancing, Pukul, Bubu, Kelola, Kolam, dan Masak muncul di tempat yang sama: kanan bawah, di atas tombol Jump, 84 px. Tarik muncul di tempat Pancing. Tidak ada tombol Aksi yang muncul di tengah layar atau di kiri.
14. [ ] **Tidak menumpuk (K-116):** di HP portrait dan landscape, slot Aksi tidak menimpa Jump, joystick, tracker, toast, dock, atau kolom ≡ (kolom ≡ dilipat). Di landscape dengan kolom ≡ terbuka, slot bisa menumpuk bagian bawah kolom: catat jika terjadi.

### B26. Putaran 7 (owner playtest 2026-11-24, Kerja Bakti dan Gerobak): cek di HP

Belum pernah dimainkan di Play. Claude tidak menandai apa pun VERIFIED.

1. [ ] **Kerja Bakti tersebar (K-117):** saat event jalan, sampah tersebar di seluruh alun-alun, tidak menumpuk di pohon. Tidak ada dua sampah yang berdempet.
2. [ ] **Sampah sendiri (K-117):** di HP kedua (pemain lain), sampah yang kamu lihat tidak sama dengan milik orang lain. Pungutanmu tidak menghapus sampah di layar mereka.
3. [ ] **Pungut (K-117):** dekat sampah, prompt "Pungut" muncul. Tekan: badan membungkuk, sampah hilang, +15 Koin +3 XP. Dari jauh (lebih dari 16 studs) tidak ada yang terjadi.
4. [ ] **Bonus 100% (K-117):** pungut semua sampahmu dan semua peserta lain. Bonus +150 Koin dan Diskon Warga muncul seperti sebelumnya.
5. [ ] **Gerobak terlihat (K-118):** ada gerobak kayu placeholder di alun-alun, dekat sisi barat daya pohon.
6. [ ] **Lihat Gerobak (K-118):** dekat gerobak, tombol "Lihat Gerobak" di kanan bawah (satu slot Aksi). Tekan: panel Acara terbuka di tab Gerobak. M1 langkah 3 selesai.
7. [ ] **Lewat tab Acara (K-118):** tanpa ke gerobak, buka Acara lalu tab Gerobak. M1 langkah 3 tetap selesai.

### B27. Putaran 7 UI (owner playtest 2026-11-24): cek di HP dan landscape

Belum pernah dimainkan di Play. Claude tidak menandai apa pun VERIFIED.

1. [ ] **Kartu bibit 2 x 4 (K-120):** tap petak kosong di dekat petak. Kartu menampilkan 8 bibit: 2 baris, 4 kolom. Bibit yang punya stok ada di depan; x0 redup dan di belakang.
2. [ ] **Halaman (K-120):** dengan lebih dari 8 bibit, chevron ‹ › dan teks "1/2" tampil. › pindah ke halaman 2; ‹ mati di halaman 1. Chevron 32 px mudah ditekan jempol.
3. [ ] **Tanam dari halaman 2 (K-120):** tanam bibit di halaman 2 berhasil dan kartu tutup seperti biasa.
4. [ ] **Umpan XP (K-121):** panen atau jual sesuatu. "+N XP" naik dari bar XP di kartu pemain dan hilang dalam 1 dtk; bar bergeser dan berkilat sekali.
5. [ ] **Naik level (K-121):** saat naik Lv, bar mulai dari awal tanpa geser panjang; "+N XP" tetap muncul.
6. [ ] **Kurangi gerak (K-121):** Atur, nyalakan "Kurangi gerak". Ulangi butir 4: angka diam, bar langsung terisi, tanpa kilat. Matikan lagi untuk kembali.
