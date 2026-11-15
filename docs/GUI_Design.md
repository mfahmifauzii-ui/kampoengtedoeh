# GUI: konsep, aturan mobile, dan kit ForgeGUI

**Status (setelah Fase 16 + perombakan GUI):** kit bambu ForgeGUI terpasang dan **terlihat di game** (dites di Studio, viewport mirip HP landscape). Rencana GUI berikutnya ada di `Roadmap.md` (tahap R3). **Belum dites:** HP asli, joystick vs kartu status, dan apakah gambar milik akun pribadi (id 9416491408, bukan grup) tampil di game milik grup untuk pemain lain.

## Konsep
Mengikuti peta: hangat, jenuh, kampung tropis. Bahan visual **bambu, anyaman rotan, perkamen, daun**. Warna: perkamen krem (panel), bambu emas (bingkai, tombol), terakota (bahaya), hijau daun (pita judul, bar XP), tinta cokelat tua (teks). Font judul/angka/tombol **FredokaOne**; teks isi **GothamMedium**. Game dimainkan di **HP landscape**.

## Tata letak HUD (landscape) — diperbarui setelah perombakan UI 14 Nov 2026
Screenshot: [HUD default](screenshots/UI_hud_default.jpg) · [menu Garap + tooltip buff](screenshots/UI_garap_menu_buff_tooltip.jpg) · [popup beli lahan](screenshots/UI_popup_beli_lahan.jpg) · [menu HP terbuka](screenshots/UI_menu_hp_terbuka.jpg)

- **Atas tengah:** chip **Koin** dan **Bunga** berdampingan (hanya angka, ikon menjelaskan).
- **Kanan atas:** kolom **vertikal** tombol bulat Warga, Toko, Atur, Koleksi. **Tanpa caption**: nama muncul sebagai tooltip saat mouse di atasnya (di HP tidak ada tooltip, ikon harus cukup jelas).
  - **Di HP (layar sentuh):** kolom menciut di balik satu tombol bulat **Menu** (hamburger). Ketuk → item meluncur turun dengan animasi (±0,28 d) dan hamburger berputar seperempat; setelah memilih sesuatu menu menutup lagi. Di PC kolom selalu terbuka. Uji di PC: `player:SetAttribute("CompactHud", true)`.
- **Bawah tengah (dock):** **Garap (Cangkul), Kolam**, Hias, Tas, Pesanan; bulat, **tanpa caption**; tombol Garap atau Kolam diberi cincin hijau saat modenya aktif. Ketuk lagi untuk selesai.
- **Kiri bawah:** kartu pemain (232×92) = foto + bintang level + nama + **bar XP ramping** (12 px, angka di dalamnya) dan di bawahnya **3 slot buff** kecil (23 px, ikon 16 px). Bingkai bambu kartu tebal, jadi **semua isi (foto, bar XP, buff) menjaga jarak ≥ 14 px dari tepi kartu** dan tidak ada yang menyentuh bingkai.
  - Slot buff: ikon **kosong** (siluet gelap) bila tidak aktif; bila aktif, ikon **penuh** yang **terkuras dari atas ke bawah** seiring waktu, dengan cincin hijau. Hover (mouse) atau ketuk (HP) menampilkan nama, sisa waktu, dan efeknya. Tiga slot = satu per jenis (`Config/Buffs`): **Segar Bertani** (tanaman baru tumbuh 10% lebih cepat), **Umpan Wangi** (ikan menggigit 25% lebih cepat), **Kenyang** (XP +10%). **Efeknya belum dikodekan**; tampilan sudah (uji: ketik `!buff tani 60` di chat Studio). Ikon sementara memakai ikon yang ada (bibit, pancing, bintang) sampai ikon ForgeGUI (kosong + penuh) dibuat.
- Pandangan tengah dibiarkan kosong. Tidak ada chip "tujuan" lagi.
- HUD memakai `IgnoreGuiInset = true` + `ScreenInsets = DeviceSafeInsets`: bebas dari top bar Roblox, tetap menghindari notch.

## Menu melayang (bukan panel besar)
- **Aturan panjang teks (15 Nov 2026):** petunjuk dan toast **maksimal ±45 karakter / 6–8 kata, satu baris**. Bila perlu penjelasan, taruh di tempat yang diminta pemain (panel, tooltip, modal), bukan di toast. Sapaan NPC satu kalimat (±60 karakter). Toast beruntun tidak boleh tertinggal dari aksi (0,9 d bila antrean ≥ 2).
- **Banner naik level:** "LEVEL n!" besar di atas tengah, pop-in 0,4 d, tahan 2 d, memudar; daftar yang terbuka tetap di toast.
- **Dialog NPC:** kotak kecil (maks 330 × 176) di dasar layar, pilihan **vertikal** ("Jual / Beli" lalu "Sampai jumpa"), teks 14–18 px. **Semua layar lain disembunyikan** selama bicara (HUD, pil, petunjuk, bilah) dan dikembalikan saat selesai; hanya NPC, kamera, dan kotak dialog yang terlihat.
- **Kamera ngobrol NPC:** bidikan dekat dari samping saat dialog terbuka (lihat `Playtest_Menyeluruh_1.md`).
- **Aturan keterbacaan teks (15 Nov 2026):** teks krem di atas kotak bambu gelap **tanpa outline teks**. `UIStroke` pada `TextLabel` yang tidak diberi `ApplyStrokeMode = Border` (bawaannya Contextual) menggaris **hurufnya** dengan warna emas dan membuat teks keruh; setiap kotak gelap memakai `Border` (garis hanya di tepi kotak). Petunjuk memakai GothamBold 15–16. Outline teks hanya untuk teks di atas gambar/dunia tanpa latar (stroke gelap tipis), bukan di atas kotak gelap.
- **Warna: bambu gelap** (`UiKit.DARK`, cokelat tua) dengan teks krem dan garis bambu emas, **bukan putih**. Dipakai untuk bar Garap, petunjuk di atas ("toast" Garap), tooltip, dan popup beli lahan.
- **Tidak ada lagi menu/popup Garap** (dibuang 15 Nov 2026). Dua alat = dua tombol dock, dan alatnya pintar membaca apa yang ada di bawah penunjuk: **Cangkul** di rumput = petak baru (kotak hijau); di petak kosong = **Hapus Petak** (kotak oranye); di petak yang ada tanamannya = diteruskan ke siram/panen. **Kolam** di lahan kosong = gali kolam 16×16 (hijau, harga di petunjuk); di atas kolam = **urug** (oranye, minta konfirmasi dulu karena ikan hilang). Label kecil di atas kotak menyebut aksinya ("Cangkul", "Hapus Petak", "Gali kolam", "Urug kolam"). Menanam petak kosong dilakukan **di luar** mode Garap. **Beli Lahan tidak ada di sini.**
- **Penunjuk tombol (tutorial):** tombol yang harus ditekan diberi cincin berdenyut + panah melambung di sisi yang lega (atas/bawah/kiri); berlaku untuk tombol apa pun di layar yang terbuka (`step.highlight` = nama tombol).
- **Beli lahan:** tombol bulat **+** dengan harga melayang di atas tiap blok lahan (32×32) yang bisa dibeli. Hanya muncul saat karakter dekat (≤ 50 stud, seperti proximity prompt), **maksimal 3 sekaligus (yang terdekat)** supaya layar tidak penuh, dan tersembunyi saat mode Garap terbuka. Ketuk → **modal konfirmasi standar** ("Beli lahan ini?", info, total, Batal kiri merah / Beli kanan); harga merah dan Beli nonaktif bila Koin tidak cukup. Dibangun dari Frame ScreenGui yang mengikuti titik 3D tiap frame (billboard biasa di PlayerGui tidak bisa diuji di Studio dan kurang andal).
- Nama kecil yang tampil saat hover sekarang tooltip, bukan caption tetap, supaya HP tidak penuh.

## Panel (semua lewat `UiKit.panel`)
- Modal di tengah (96% × 92%, maks 620 × 700) dengan **bingkai bambu** (9-slice), **pita judul hijau** di atas, **badge tutup** merah di pojok, baris berupa **kartu**, tombol plank bambu. Muncul meluncur dari bawah; mengetuk area gelap di luar menutupnya.
- Tombol: plank bambu emas, teks krem berkontur gelap lewat label overlay (skin menutupi teks tombol aslinya). Tombol nonaktif: plank 45% transparan, teks ikut pudar.
- Target sentuh minimal 50 px, baris 82 px, teks minimal 13 px (HUD kecil memakai 10–15 px khusus bar/chip).
- `UiKit.autoScale()`: `UIScale` = tinggi layar / 560, dijepit **1–1,35** (HP tidak pernah diperkecil).

## Toko NPC bertab dan modal konfirmasi (14 Nov 2026)
- **Tab Beli / Jual** (`UiKit.tabs`) di atas daftar; tab terpilih plank terang, yang lain gelap dan pudar. NPC yang hanya menjual atau hanya membeli tidak menampilkan tab. Toko dibuka di tab Jual bila ada yang bisa dijual ke NPC itu.
- **Baris dagang** (`UiKit.tradeRow`, tinggi 108): slot gambar kiri, nama + detail (harga satuan, jumlah yang dimiliki, sisa kuota), **number picker** `− 3 +` (tahan tombol untuk mengulang; maks 99, atau sisa kuota / jumlah di tas saat menjual), **total**, tombol Beli/Jual. Total **merah** dan tombol abu-abu bila Koin tidak cukup. Barang sekali beli (joran, upgrade, blueprint) tanpa picker. Jual satu item langsung jalan; **Beli** dan **Jual Semua** selalu lewat modal.
- **Slot gambar** (`UiKit.thumb`): memakai bingkai kartu yang ada; gambar di dalamnya PNG berlatar transparan. Sampai model ada, tampil ikon placeholder yang dipudarkan. **Mengganti nanti: isi id di `UiAssets.THUMBS[itemId]`** (kunci: id item seperti `kangkung`, `seed_kangkung`, `nila@S`, id joran, `upgrade_<id>`, `blueprint_<id>`); semua baris item itu ikut berganti. PNG `assets/models/crops/*_thumb.png` belum diunggah.
- **Modal konfirmasi standar** (`UiKit.confirm`, ScreenGui `ConfirmModal`, DisplayOrder 100): judul, teks, total, dua tombol. **Batal di kiri, warna merah (`UiKit.RED`); Setuju di kanan.** Mengetuk latar gelap = Batal. Berlaku untuk semua modal: beli di toko, Jual Semua, dan beli lahan (popup lama dihapus). Modal baru wajib lewat fungsi ini. *(Bar Pasang/Batal saat menghias bukan modal; tidak diubah.)*
- Petunjuk pemain baru: lihat `Playtest_AI_Persona_1.md` (`GuideController`, ScreenGui `GuideUI`, di bawah HUD).

## Kit (assets/gui; versi siap upload di assets/gui/ready)
| File | Isi | Dipakai sebagai |
|---|---|---|
| `panel_v1.png` | bingkai bambu + sudut rotan + tengah perkamen | `UiAssets.PANEL` (9-slice) |
| `button_v1.png` | plank bambu emas | `UiAssets.BUTTON` (9-slice, diberi tint) |
| `ribbon_v1.png` | pita judul hijau | `UiAssets.RIBBON` |
| `close_v1.png` | badge tutup bulat merah | `UiAssets.CLOSE` |
| `card_v1.png` | kartu baris daftar | `UiAssets.CARD` |
| `chip_v1.png` | kapsul HUD | `UiAssets.CHIP` (juga latar kartu status) |
| `plate_v1.png` | cincin bambu bulat | `UiAssets.PLATE` (tombol menu, cincin foto) |
| `icon_*.png` | koin, bunga, tas, toko, pesanan, koleksi, hias, garap, warga, atur, ikan, pancing, bibit, kolam, bintang, hati | `UiAssets.ICONS` |

Ikon Tas dan Hias punya serpihan sprite tetangga di tepi kanan: sudah dibersihkan di file lokal dan dipotong lewat kode (`ICON_CROP`) karena id Roblox lama belum diganti.

## Memasang gambar baru
1. Potong ruang transparan dan perkecil (`assets/gui/ready`), lalu unggah (Studio `upload_image` lewat server HTTP lokal, atau Asset Manager).
2. Isi id dan `slice` di `src/shared/Config/UiAssets.luau`. Id kosong = gaya flat yang sama (cadangan).
3. Uji di Play: skin harus tampil tanpa kedip saat panel dibangun ulang (lihat catatan teknis di `Roadmap.md`, bagian R3).
