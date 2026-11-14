# GUI: konsep, aturan mobile, dan kit ForgeGUI

**Status (setelah Fase 16 + perombakan GUI):** kit bambu ForgeGUI terpasang dan **terlihat di game** (dites di Studio, viewport mirip HP landscape). Rencana GUI berikutnya ada di `Roadmap.md` (tahap R3). **Belum dites:** HP asli, joystick vs kartu status, dan apakah gambar milik akun pribadi (id 9416491408, bukan grup) tampil di game milik grup untuk pemain lain.

## Konsep
Mengikuti peta: hangat, jenuh, kampung tropis. Bahan visual **bambu, anyaman rotan, perkamen, daun**. Warna: perkamen krem (panel), bambu emas (bingkai, tombol), terakota (bahaya), hijau daun (pita judul, bar XP), tinta cokelat tua (teks). Font judul/angka/tombol **FredokaOne**; teks isi **GothamMedium**. Game dimainkan di **HP landscape**.

## Tata letak HUD (landscape) — diperbarui setelah perombakan UI 14 Nov 2026
Screenshot: [HUD default](screenshots/UI_hud_default.jpg) · [menu Garap + tooltip buff](screenshots/UI_garap_menu_buff_tooltip.jpg) · [popup beli lahan](screenshots/UI_popup_beli_lahan.jpg) · [menu HP terbuka](screenshots/UI_menu_hp_terbuka.jpg)

- **Atas tengah:** chip **Koin** dan **Bunga** berdampingan (hanya angka, ikon menjelaskan).
- **Kanan atas:** kolom **vertikal** tombol bulat Warga, Toko, Atur, Koleksi. **Tanpa caption**: nama muncul sebagai tooltip saat mouse di atasnya (di HP tidak ada tooltip, ikon harus cukup jelas).
  - **Di HP (layar sentuh):** kolom menciut di balik satu tombol bulat **Menu** (hamburger). Ketuk → item meluncur turun dengan animasi (±0,28 d) dan hamburger berputar seperempat; setelah memilih sesuatu menu menutup lagi. Di PC kolom selalu terbuka. Uji di PC: `player:SetAttribute("CompactHud", true)`.
- **Bawah tengah (dock):** Garap, Hias, Tas, Pesanan; bulat, **tanpa caption**, tombol Garap diberi cincin hijau saat mode Garap aktif.
- **Kiri bawah:** kartu pemain (232×92) = foto + bintang level + nama + **bar XP ramping** (12 px, angka di dalamnya) dan di bawahnya **3 slot buff** kecil (23 px, ikon 16 px). Bingkai bambu kartu tebal, jadi **semua isi (foto, bar XP, buff) menjaga jarak ≥ 14 px dari tepi kartu** dan tidak ada yang menyentuh bingkai.
  - Slot buff: ikon **kosong** (siluet gelap) bila tidak aktif; bila aktif, ikon **penuh** yang **terkuras dari atas ke bawah** seiring waktu, dengan cincin hijau. Hover (mouse) atau ketuk (HP) menampilkan nama, sisa waktu, dan efeknya. Tiga slot = satu per jenis (`Config/Buffs`): **Segar Bertani** (tanaman baru tumbuh 10% lebih cepat), **Umpan Wangi** (ikan menggigit 25% lebih cepat), **Kenyang** (XP +10%). **Efeknya belum dikodekan**; tampilan sudah (uji: ketik `!buff tani 60` di chat Studio). Ikon sementara memakai ikon yang ada (bibit, pancing, bintang) sampai ikon ForgeGUI (kosong + penuh) dibuat.
- Pandangan tengah dibiarkan kosong. Tidak ada chip "tujuan" lagi.
- HUD memakai `IgnoreGuiInset = true` + `ScreenInsets = DeviceSafeInsets`: bebas dari top bar Roblox, tetap menghindari notch.

## Menu melayang (bukan panel besar)
- **Warna: bambu gelap** (`UiKit.DARK`, cokelat tua) dengan teks krem dan garis bambu emas, **bukan putih**. Dipakai untuk bar Garap, petunjuk di atas ("toast" Garap), tooltip, dan popup beli lahan.
- **Menu Garap** (di atas dock): jumlah petak, 4 alat dalam grid 2×2, dan **badge tutup (X)** di pojok. Nama alat: **Cangkul** (jadikan tanah), **Hijaukan** (kembalikan jadi rumput), **Gali Kolam**, **Urug Kolam** (menggantikan "Garap / Ratakan / Kolam / Hapus Kolam"). **Beli Lahan tidak ada di sini lagi.**
- **Beli lahan:** tombol bulat **+** dengan harga melayang di atas tiap chunk yang bisa dibeli. Hanya muncul saat karakter dekat (≤ 50 stud, seperti proximity prompt), **maksimal 3 sekaligus (yang terdekat)** supaya layar tidak penuh, dan tersembunyi saat mode Garap terbuka. Ketuk → **popup kecil** ("Beli lahan ini?", info, harga, Beli / Batal, X); tombol Beli jadi "Koin kurang" bila Koin tidak cukup. Dibangun dari Frame ScreenGui yang mengikuti titik 3D tiap frame (billboard biasa di PlayerGui tidak bisa diuji di Studio dan kurang andal).
- Nama kecil yang tampil saat hover sekarang tooltip, bukan caption tetap, supaya HP tidak penuh.

## Panel (semua lewat `UiKit.panel`)
- Modal di tengah (96% × 92%, maks 620 × 700) dengan **bingkai bambu** (9-slice), **pita judul hijau** di atas, **badge tutup** merah di pojok, baris berupa **kartu**, tombol plank bambu. Muncul meluncur dari bawah; mengetuk area gelap di luar menutupnya.
- Tombol: plank bambu emas, teks krem berkontur gelap lewat label overlay (skin menutupi teks tombol aslinya). Tombol nonaktif: plank 45% transparan, teks ikut pudar.
- Target sentuh minimal 50 px, baris 82 px, teks minimal 13 px (HUD kecil memakai 10–15 px khusus bar/chip).
- `UiKit.autoScale()`: `UIScale` = tinggi layar / 560, dijepit **1–1,35** (HP tidak pernah diperkecil).

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
