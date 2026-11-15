# Penilaian Gameplay (15 Nov 2026)

Penilaian jujur dari pembangun, berdasarkan kode, dokumen, dan hasil uji Studio sampai hari ini. **Belum ada uji pemain nyata dan belum ada uji di HP**, jadi semua angka di bawah adalah hipotesis yang harus dibuktikan di Playtest #1.

## Vonis singkat
**Tidak busuk, tapi loop intinya belum enak.** Fondasinya benar (tumbuh saat offline, tanam dulu baru jalan, pesanan tanpa hukuman, mancing sebagai variasi). Masalahnya ada di tiga tempat: (1) terlalu banyak ketukan per hasil, (2) hampir tidak ada keputusan, (3) Koin menumpuk tanpa tujuan. Semuanya bisa diperbaiki tanpa membongkar sistem.

## Temuan, urut dari yang paling merusak

### 1. Terlalu banyak ketukan untuk satu panen (tinggi)
Satu petak = ketuk petak → pilih bibit di modal → ketuk lagi untuk menyiram → ketuk lagi untuk panen. Tiga sampai empat aksi per petak, per siklus 1 menit. Dengan 6–12 petak itu 20–40 ketukan per menit untuk hasil yang sama setiap kali. Di HP ini menjadi pekerjaan, bukan permainan. Perubahan Garap hari ini juga menambah satu langkah (keluar Garap dulu sebelum menanam).
**Perbaikan (urut):**
1. **Tanam sekali ketuk**: ketuk petak kosong langsung menanam bibit terakhir yang dipakai (modal hanya muncul bila belum pernah memilih atau bibit habis; tekan-tahan untuk ganti).
2. **Panen dan siram area**: satu ketukan memanen/menyiram semua petak matang/kering dalam radius ±12 stud (server tetap memeriksa jarak dan kepemilikan petak satu per satu). Hasilnya animasi beruntun, bukan ketukan beruntun.
3. **Geser untuk menanam** (seret jari melintasi petak kosong), setelah 1 dan 2 terbukti.
4. Garap keluar otomatis setelah petak ketiga selesai dicangkul atau 8 detik tanpa aksi (ukur dulu apakah perlu).
**Ukur:** ketukan per Koin, dan berapa persen pemain berhenti sebelum menit ke-5.

### 2. Hampir tidak ada keputusan (tinggi)
Semua tanaman hanya berbeda harga dan waktu; strategi terbaik selalu "tanam yang tertinggi yang terbuka". Pesanan memberi sedikit variasi, tetapi tidak memaksa pilihan. Loop yang tidak punya pilihan terasa seperti antrean.
**Perbaikan (kecil dulu):**
- **Waktu tumbuh berjarak lebar** (1 menit, 5 menit, 20 menit, 2 jam) dengan Koin per menit yang sengaja tidak seragam: tanaman cepat butuh perhatian, tanaman lambat cocok sebelum keluar. Pemain memilih sesuai gaya bermainnya malam itu.
- **Kebutuhan pesanan sebagai pemaksa pilihan**: pesanan harian (§5 rencana) meminta campuran sehingga pemain harus menanam hal yang tidak paling mahal.
- **Tautan antar sistem**: tanaman tertentu jadi umpan (Kangkung → Pelet murah), ikan jadi bahan pesanan, hasil kolam jadi bahan pesanan. Dua kegiatan yang saling memberi makan lebih menarik daripada dua kegiatan yang terpisah.
- Bonus tetangga sederhana (petak sejenis berdekatan, atau dekat hiasan tertentu +5% cepat). Hanya bila 1 dan 2 tidak cukup.

### 3. Koin menumpuk, tidak ada tujuan (sedang, tapi merusak jangka menengah)
Simulasi lama: ±162 ribu Koin di hari 42, dan Warung Mini 0,9× tanpa batas mempercepatnya. Sink yang ada (blok lahan 1.500 × 1,2ⁿ, hiasan, upgrade) kemungkinan habis dalam 1–2 minggu; setelah itu Koin tidak berarti dan loop kehilangan alasan.
**Perbaikan:** (a) simulasi P8 wajib sebelum menambah apa pun; (b) sink yang terlihat: katalog hiasan yang luas dan berjenjang harga, perbaikan kosmetik rumah/dermaga, blok lahan lanjut dengan kurva lebih curam; (c) Bunga hanya dari kegiatan (bukan Koin) supaya tidak ikut inflasi. Jangan menambah hadiah Koin baru sebelum (a).

### 4. Alasan ke alun-alun mengecil (sedang)
Dengan Warung Mini 0,9× tanpa kuota, ke alun-alun hanya demi bibit dan pesanan; selisih 10% tidak cukup membuat orang berjalan jauh (perhatikan juga Sprint dibatalkan, jalan 16 stud/detik). Ini baik untuk kenyamanan, buruk untuk kehidupan kampung dan interaksi pemain.
**Perbaikan:** bukan memperberat jual, tetapi menambah alasan positif di alun-alun: stok bibit **langka harian** yang tidak ada di tempat lain, pesanan hanya disetor di sana (sudah), papan pesanan komunitas, dan NPC yang berubah per hari. Ukur `sold_mini` vs `sold_town` (sudah di rencana) sebelum mengubah apa pun.

### 5. Waktu tunggu terasa kosong (sedang)
Tanaman 1 menit membuat pemain menunggu kecuali ada pekerjaan paralel. Mancing sudah menjadi pekerjaan paralel, tetapi jaraknya (dermaga) jauh dari lahan, jadi pemain memilih salah satu. Kolam penangkaran di lahan (ditunda) adalah jawabannya; naikkan prioritasnya setelah playtest bila data menunjukkan pemain diam menunggu.

### 6. Hal yang sudah benar (jangan dirusak)
Tumbuh saat offline; tanam dulu baru jalan; pesanan tanpa hukuman dan tanpa streak; bibit tutorial cepat; panah di tanah; hadiah kecil dan gratis; sorot tombol yang tidak memblokir; tanpa popup jualan.

## Perubahan hari ini yang memengaruhi loop
- Garap jadi dua tombol dock (Cangkul, Kolam), tanpa menu; hijaukan/urug otomatis menurut isi di bawah penunjuk (lihat `GUI_Design.md`).
- **Harga:** menanam kini harus keluar dari mode Garap (ketuk tombol lagi). Ini sengaja (agar ketuk petak kosong aman = menghijaukan) tetapi menambah satu ketukan; perbaikan 1 dan 4 di atas menutupnya. Wajib dilihat di playtest HP.
- Dock bertambah satu tombol (5): periksa tidak menutupi joystick/lompat di HP landscape.

## Urutan kerja yang saya usulkan (setelah P2–P8, atau di depan bila Anda setuju)
1. **L1 — Sekali ketuk**: tanam bibit terakhir, panen/siram area (server memvalidasi per petak). Selesai bila 10 petak dipanen dan ditanam ulang dengan ≤ 6 ketukan dan tidak ada celah curang (jarak, kepemilikan, laju).
2. **L2 — Variasi waktu tumbuh + tautan tanaman→umpan** (data `Config/Crops` dan `Config/Fishing`; lewat simulasi P8).
3. **L3 — Sink Koin** setelah simulasi P8.
4. **L4 — Alasan ke alun-alun** (bibit langka harian) hanya bila `sold_town` terlalu kecil.
Tiap tahap tetap satu per satu, menunggu "lanjut".

## Yang belum bisa saya nilai
Seru atau tidaknya (butuh orang), kenyamanan di HP asli, perilaku dengan 2+ pemain, dan ritme hari ke-10 ke atas.
