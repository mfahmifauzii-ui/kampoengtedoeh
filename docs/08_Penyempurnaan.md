# KAMPOENG TEDOEH — Penyempurnaan Game v1.1 (Diterima)

> Rencana penyempurnaan agar game lebih enak, lebih jelas, dan lebih siap rilis. **Semua item berprioritas Wajib dan Disarankan dianggap DITERIMA** (diputuskan Claude atas mandat owner); item "Nanti" masuk Update 1. Angka yang menyangkut gameplay tetap hanya sah bila ada di `01_GDD`.
> Prioritas: **Wajib** = sebelum rilis · **Disarankan** = sebelum rilis bila waktu cukup · **Nanti** = Update 1+.
> Kolom "Terkait" merujuk keputusan (`02_Audit_Perbaikan.md` Bab 3) atau tugas (`06_Roadmap.md`).

---

## 1. Ringkasan Prioritas

| ID | Usulan | Prioritas | Terkait |
|----|--------|-----------|---------|
| P-01 | Hujan = momen bagus untuk semua kegiatan | Wajib | K-01, R1.2 |
| P-02 | Kurva biaya skill naik (skill pertama terasa) | Wajib | K-12, R1.8 |
| P-03 | Cerita Babak 2 & 3 (Lv 10–60) | Wajib | R8.1, R8.2 |
| P-04 | Papan Hari Ini (Agenda + Surat + Order + Login) | Wajib | K-34, R2.2, R3.3 |
| P-05 | Kualitas olahan dari ukuran ikan & Mood Hujan | Wajib | K-05, R1.3 |
| P-06 | Album benar-benar bisa 100% | Wajib | K-06, K-07, R1.4 |
| P-07 | Main sendiri tetap lengkap (Kebun Warga) | Wajib | K-17, R2.5 |
| P-08 | Ekonomi resep sehat | Wajib | K-02, K-03, K-04, R1.1 |
| P-09 | "Momen pertama" yang dirayakan | Disarankan | R6.6 |
| P-10 | Standar juice per aksi | Wajib | Asset Bible 11, Fase 5–7 |
| P-11 | Aksesibilitas | Wajib | R3.7, R2.11 |
| P-12 | Bahasa Inggris | Nanti | R12.3 |
| P-13 | Performa terukur sejak awal | Wajib | R10.3 |
| P-14 | Monetisasi kosmetik yang jelas | Disarankan | K-30, K-32 |
| P-15 | Retensi: Surat Kakek sebagai tulang cerita | Disarankan | R8.3 |
| P-16 | Sosial ringan tanpa kewajiban | Nanti | — |
| P-17 | Rumah 2 Lantai | Nanti | — |
| P-18 | Anti-bingung | Wajib | R3.3 |
| P-19 | Analytics funnel | Wajib | R2.10, R11.1 |
| P-20 | Simulasi pace sebelum konten dikunci | Wajib | R9.1 |
| P-21 | Endgame Lv 50–60 | Disarankan | R8.2 |
| P-22 | Aturan dokumen supaya tidak berantakan lagi | Wajib | README |

---

## 2. Detail

### P-01 Hujan = momen bagus

Masalah: efek hujan ke mancing sekarang menghukum (Audit A-43), padahal tagline menjual hujan.

Usulan:
- Mancing saat hujan: waktu tunggu normal, **jendela gigitan 2x** (1,5 → 3 dtk). Ikan "khusus hujan" (Gabus, Sidat, Belut Emas) diberi badge kecil 🌧 di kartu ikan & Album.
- Hujan pertama setelah tutorial: toast 1x `Hujan! Tanaman tumbuh 2x lebih cepat dan ikan lebih gampang ditarik.` (Prinsip 14: sekali saja).
- Ikon cuaca di HUD saat hujan berdenyut pelan 3 detik pertama.

### P-02 Kurva biaya skill

Skill per level 1.000 / 2.000 / 3.000 / 4.000 / 5.000 Koin. Total per skill tetap 15.000, total semua tetap 240.000 → sink tidak berubah, tapi SP pertama di Lv 2 langsung bisa dipakai (sekarang 3.000 Koin di saat yang sama pemain butuh 1.050 untuk petak).

### P-03 Cerita Babak 2 & 3 (rancangan awal)

Babak 1 "Pulang" (Lv 1–10) sudah ada: M1–M9. Babak berikutnya memakai fitur yang **sudah ada di GDD** (tidak menambah sistem), dengan Bundel Kakek dan Surat Kakek sebagai benang merah. Hadiah ditentukan di R8.1 (ikut aturan XP quest ≤ 25% per rentang level).

**Babak 2 — "Menghidupkan Lahan Kakek" (Lv 10–30)**

| # | Lv | Judul | Pemberi | Membuka / isi |
|---|----|-------|---------|---------------|
| M10 | 12 | Rancangan Kakek | Pak Amran | Blueprint: simpan desain pertama. Cerita: Pak Amran menemukan sketsa rumah Kakek. |
| M11 | 15 | Lumbung Kakek | Nek Ani | Bundel Lumbung. Cerita: panen raya kampung zaman dulu. |
| MQ11 | 15 | Legenda Pertama | Kak Fajar | (sudah ada) |
| M12 | 18 | Malam di Kanal | Kak Fajar | Kanal Timur malam, Firasat dijelaskan lewat dialog (bukan angka). |
| M13 | 20 | Saung Kakek | Mak Sari | Bundel Saung + buff Istirahat Sejenak. Surat Kakek tentang tempat ia biasa istirahat. |
| M14 | 20 | Titip Salam | Nek Ani | Kirim Hadiah. **Supaya bisa solo:** quest boleh diselesaikan dengan mengirim ke NPC (Nek Ani) satu kali. |
| M15 | 25 | Akuarium | Kak Fajar | Akuarium: pajang 1 ikan. |
| MQ12 | – | Warga Kampoeng Tedoeh | Mak Sari | (sudah ada, Album 50%) |

**Babak 3 — "Warisan" (Lv 30–60)**

| # | Lv | Judul | Pemberi | Membuka / isi |
|---|----|-------|---------|---------------|
| M16 | 30 | Empang & Dermaga Kakek | Kak Fajar | Bundel Empang (spot pribadi). |
| M17 | 35 | Dapur Lengkap | Mak Sari | Dapur Tier 3. Cerita: resep pesta Kakek. |
| M18 | 40 | Pesta Panen | Nek Ani | Setor olahan untuk pesta pribadi di lahan (dekor pesta sebagai hadiah). |
| M19 | 45 | Durian Kakek | Pak Udin | Tanam & panen Durian pertama (Late 8 jam; quest tidak menahan Main lain sampai panen). |
| M20 | 50 | Rumah Joglo | Pak Amran | Set Joglo lengkap. |
| M21 | 60 | Surat Terakhir | Mak Sari | Surat Kakek #30 + cutscene lahan dari atas + Title. Penutup cerita rilis. |

Di Quest Log, Main berikutnya tampil `???` sampai levelnya (sudah ada).

### P-04 Papan Hari Ini

Satu panel (tombol HUD tunggal) untuk semua hal harian: 5 tugas Agenda, Surat Kakek hari ini, 3+1 Order, hari Login, % Album. Menyelesaikan masalah Agenda tanpa UI (A-27) dan tombol Album/Surat yang tidak punya tempat (A-76), sekaligus mengurangi tombol di layar HP.

### P-05 Kualitas olahan yang masuk akal

- Ikan: Kecil/Sedang = Biasa, Besar = Bagus, Jumbo = Prima → skill Ikan Besar ikut berguna di Dapur.
- Telur & Susu: Bagus bila diambil saat Mood Hujan → hujan punya arti untuk peternak tanpa buff pasif.
- Rasa Prima: satu-satunya roll di Dapur, +1%/lv naik satu tingkat.

### P-06 Album benar-benar bisa 100%

- Legenda: tangkapan berikutnya selalu ukuran yang belum dimiliki (total tetap 214).
- Belut Emas: Hujan Deres **atau** Petir.
- Album Dapur: lihat P-05.
- Hasilnya target "Kolektor ~3 bulan" (GDD 11) realistis.

### P-07 Main sendiri tetap lengkap

**Kebun Warga**: 4 petak NPC di alun-alun, bisa disiram & dipanen 1x/hari, dihitung sebagai Bantu (hadiah sama). Hasil panen masuk ke "lumbung kampung" (tidak ke pemain). Membuat S6, side Ringan Tangan, dan skill Tetangga Baik berguna di server sepi. Title berbasis like (Kebun Favorit) tetap ada tapi tidak memberi Bunga.

### P-08 Ekonomi resep sehat

- Bahan terbuka sebelum / bersamaan dengan resepnya (Jahe Lv 6, Tebu Lv 8, Melati Lv 15).
- Semua resep ≥ 1,5× nilai bahan (angka di Audit K-03).
- Pakan Jagung 1 Jagung → 6 jatah.
- Kartu resep di Dapur menampilkan "Butuh Durian (Lv 45)" untuk resep yang bahannya belum terbuka.

### P-09 Momen pertama yang dirayakan

Tiap "pertama kali" mendapat efek sedikit lebih besar + toast 1x (lalu diam, Prinsip 14):

| Momen | Perayaan |
|-------|----------|
| Panen Prima pertama | Partikel emas lebih besar + toast "Panen Prima pertama!" |
| Ikan Jumbo pertama | Kartu ikan dengan bingkai emas |
| Level 5 / 10 / 20 | Banner LEVEL lebih panjang + daftar yang terbuka |
| Bundel pertama pulih | Kamera menyorot bangunan 2 dtk |
| Legenda pertama | Banner server + fanfare (sudah ada) |
| Album 25/50/75/100% | Kartu Album otomatis ditawarkan untuk `Bagikan` |

### P-10 Standar juice

Setiap aksi wajib paket lengkap: animasi + VFX + SFX + umpan balik UI (+ haptic untuk momen besar). Tabel di `04_Asset_Bible.md` Bab 11. Aksi tanpa paket ini dianggap "belum selesai" di Gate G1.

### P-11 Aksesibilitas

- Kualitas & status pakai **bentuk + warna** (titik / daun / bintang), bukan warna saja.
- Teks ≥ 12 px, kontras teks di atas parchment ≥ 4,5:1.
- Setting: Mode Bantu (sudah), Efek rendah, Kurangi gerak, volume per grup, Haptic.
- Semua aksi bisa dengan satu jari (tanpa gesture rumit).

### P-12 Bahasa Inggris

Sistem Locale sudah ada (`Locale/id.luau`). Tambah `en.luau` di Update 1 → pasar lebih luas tanpa mengubah gameplay. Nama tempat (Kampoeng Tedoeh, Kanal, Saung) tetap bahasa Indonesia sebagai ciri khas.

### P-13 Performa terukur sejak awal

- Anggaran aset (Asset Bible 2) dipakai dari contoh pertama (R4.1).
- Uji FPS di HP 4GB **setiap gate**, bukan hanya sebelum rilis.
- Lahan pemain lain di-stream; dekor lahan jauh boleh disederhanakan.
- Setting "Efek rendah" otomatis aktif bila FPS < 25 selama 10 detik (dengan toast 1x).

### P-14 Monetisasi kosmetik yang jelas

Tetap patuh Prinsip 12 & 13. Ide isi **Season Premium** (kosmetik eksklusif, tidak dijual lagi):
- Topi caping motif musim, skin joran ukir, skin gembor musim, Perahu Mini lampion (dekor tanpa stat), warna dinding musim, bingkai kartu Album musim, efek jejak kaki daun saat jalan di lahan sendiri.

Lain-lain:
- Harga Pack Bunga dalam Robux = K-32 (75 / 150 / 300 / 600 R$); tampilkan jumlah Bunga jelas, tanpa "bonus" palsu.
- Tidak ada penawaran yang muncul sendiri. Toko hanya dibuka pemain.

### P-15 Surat Kakek sebagai tulang cerita

30 surat = 30 hari pertama. Tiap surat: 2–3 kalimat cerita + 1 tugas kecil yang mengajarkan hal yang sering terlewat (siram saat hujan, Mood Hujan, Firasat, Set dekor, Pasar Harian). Surat #30 = finale emosional yang mengarah ke M21. Ditulis di R8.3.

Opsional (cek ketersediaan API Roblox saat itu): notifikasi opt-in untuk "tanaman Late matang" dan "bubu siap".

### P-16 Sosial ringan tanpa kewajiban

- Mancing di spot berdekatan: pelampung saling memberi gelembung kecil (kosmetik, tanpa stat).
- Kunjungi lahan teman dari daftar teman Roblox (selain Galeri).
- Gestur kontekstual: tombol Lambai muncul sebentar saat pemain lain lewat dekat.

### P-17 Rumah 2 Lantai

Disebut di Quest v0.3 (Lv 40) tapi tidak ada di GDD. Butuh: piece tangga & lantai atas, aturan snap vertikal, batas tinggi, kamera dalam ruangan. Cocok untuk Update 2 sebagai fitur Dekorator.

### P-18 Anti-bingung

- Setiap langkah quest wajib punya target `Tunjukkan` (panah dunia).
- Quest Log punya baris petunjuk khusus untuk langkah yang bergantung kondisi (Kerja Bakti, Legenda, ikan malam/hujan).
- Bila pemain tidak punya quest aktif dan tidak ada `!` di mana pun, Papan Hari Ini menyorot 1 tugas Agenda.

### P-19 Analytics funnel

Log `TutorialStep` di tiap langkah tutorial dan `QuestStep` di Lv 1–10. Saat closed test (R11.1) lihat di Creator Hub: langkah mana yang paling banyak ditinggal. Itu daftar perbaikan pertama setelah rilis.

### P-20 Simulasi pace

Sebelum menulis Babak 2–3, jalankan simulasi R9.1 (XP & Koin per jam per fase). Hasilnya menentukan apakah Lv 60 tercapai di 55–70 jam dan apakah sink 65–80%. Tanpa ini, angka GDD 17.2 dan Quest doc terus bertabrakan (A-19).

### P-21 Endgame Lv 50–60

Set Joglo (Lv 50), Album 100%, 3 Legenda × 4 ukuran, Lomba Hias Bulanan, Galeri, Season. Tambahan murah: **Papan Kebanggaan** pribadi di lahan (bingkai yang menampilkan Title, % Album, Legenda terbesar) — dekor tanpa stat.

### P-22 Aturan dokumen

- Satu topik = satu file (README). Keputusan hanya di Audit Bab 3. Riwayat di git, bukan di dokumen.
- Setiap tugas kode memperbarui dokumen terkait di commit yang sama (Roadmap 1.1 #7).
- ID tidak pernah dipakai ulang (`A-`, `K-`, `P-`, `R`).
