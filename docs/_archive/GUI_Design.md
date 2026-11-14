# GUI: konsep, aturan mobile, dan kit ForgeGUI

**Status (setelah Fase 16 + perombakan GUI):** kit bambu ForgeGUI terpasang dan **terlihat di game** (dites di Studio, viewport mirip HP landscape). Rencana GUI berikutnya ada di `Phase17_Status_Istirahat_Hadiah_Plan.md`. **Belum dites:** HP asli, joystick vs kartu status, dan apakah gambar milik akun pribadi (id 9416491408, bukan grup) tampil di game milik grup untuk pemain lain.

## Konsep
Mengikuti peta: hangat, jenuh, kampung tropis. Bahan visual **bambu, anyaman rotan, perkamen, daun**. Warna: perkamen krem (panel), bambu emas (bingkai, tombol), terakota (bahaya), hijau daun (pita judul, bar XP), oranye (stamina), tinta cokelat tua (teks). Font judul/angka/tombol **FredokaOne**; teks isi **GothamMedium**. Game dimainkan di **HP landscape**.

## Tata letak HUD (landscape)
- **Atas**, di kanan menu Roblox: chip **Koin** dan **Bunga** (hanya angka, ikon menjelaskan).
- **Kanan atas**: tombol bulat Warga, Toko, Atur, Koleksi (+ caption kecil).
- **Bawah tengah** (dock): Garap, Hias, Tas, Pesanan.
- **Kiri bawah**: kartu status pemain = foto avatar + bintang level + nama + bar XP + bar stamina (stamina membaca atribut `Stamina` / `StaminaMax`; sistemnya belum ada).
- Pandangan tengah dibiarkan kosong. Tidak ada chip "tujuan" lagi (dibuang karena memakan tempat).
- HUD memakai `IgnoreGuiInset = true` + `ScreenInsets = DeviceSafeInsets`: bebas dari top bar Roblox, tetap menghindari notch.
- Di layar portrait (tidak dipakai game, tapi ada cadangan) menu menjadi grid 2 kolom dan dock berupa kolom di kanan.

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
3. Uji di Play: skin harus tampil tanpa kedip saat panel dibangun ulang (lihat catatan teknis di dokumen Fase 17).
