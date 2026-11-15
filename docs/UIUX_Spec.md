# UI/UX Spec: daftar, kartu, warna (15 Nov 2026)

Alasan sebelum kode. Target utama **HP landscape** (±800×360 poin), mouse hanya tamu.

## Temuan dari tangkapan layar (Tas, Toko, Atur, Koleksi, Hias, Pak Darmo)
1. **Lembar terlalu besar.** Panel memakai 96% × 92% layar. Di HP 360 poin tingginya, isi yang terlihat hanya 2–3 baris; sisanya menggulir.
2. **Satu kolom, baris 82–108 px, setengah kosong.** Teks kecil di pojok kiri-atas, tombol jauh di kanan: mata harus menyeberangi 600 px untuk menyambungkan nama dengan tombolnya (Tas: "Cabai ×1" dan "20 Koin" dipisah ruang kosong; Atur: nama di kiri, "Nyala" di kanan).
3. **Monoton.** Semua krem + emas yang sama: tanaman, ikan, alat, hiasan, uang, tombol aktif/nonaktif hampir tidak dibedakan. Pemain harus membaca tiap kata.
4. **Tombol "Nyala/Mati" untuk pengaturan** adalah kata yang harus dibaca ulang tiap kali ("Nyala" = sedang nyala atau tekan untuk menyalakan?). Saklar hijau/abu dengan titik geser sudah dikenal semua orang.
5. **Pemilih jumlah dan harga** memakan 2 baris per item (stepper di atas, total + tombol di bawah) sehingga satu baris Toko 108 px.
6. **Gambar tidak dipakai.** Tas dan Toko memuat nama saja, padahal tanaman sudah punya model 3D, ikan dan alat punya ikon. Gambar dikenali ~3× lebih cepat daripada kata.

## Prinsip
- **Padat tapi tetap bisa ditekan:** target sentuh ≥ 40 px (tombol/stepper); area baris boleh lebih rendah selama tombolnya ≥ 40 px (tombol aksi dibuat 34–36 + padding hitbox 44 lewat baris yang ikut bisa diketuk).
- **Satu mata, satu garis baca:** gambar | nama + info | harga | aksi, dalam satu baris tinggi ±54 px. Kolom selalu di tempat yang sama pada tiap baris (seperti tabel), jadi mata menurun lurus.
- **Grid untuk barang, tabel untuk transaksi.** Barang yang cukup dikenali dari gambar (Tas, Koleksi) = grid 5 kolom. Transaksi dengan jumlah dan harga (Toko NPC) = tabel baris padat. Pengaturan = dua kolom saklar.
- **Warna punya arti, bukan hiasan:**
  | Arti | Warna | Dipakai |
  |---|---|---|
  | Tanaman / bibit | hijau daun `#609646` | garis kiri kartu, tab, lencana |
  | Ikan / air | biru air `#3C8CB0` | idem |
  | Alat / upgrade | terakota `#C4643C` | idem |
  | Hiasan / blueprint | plum `#9E5C78` | idem |
  | Uang | emas `#F0C45C` di atas cokelat gelap (chip harga, sama dengan HUD Koin) | semua harga |
  | Aksi utama | hijau tombol (Beli) / kuning-jingga (Jual) | tombol |
  | Tidak bisa | krem pudar + gembok + "Lv N" merah-cokelat | kartu terkunci |
  | Kurang uang | angka harga merah `#C42C24` | chip harga |
  Latar tetap krem hangat (sudah jadi identitas), tapi dibedakan zebra (dua krem selang-seling) agar baris tidak menyatu.
- **Harga selalu berbentuk chip yang sama** (cokelat gelap, ikon koin, angka emas). Pemain belajar sekali.
- **Kata hanya bila perlu:** status dipasang pada ikon/warna (saklar, gembok, lencana jumlah), bukan kalimat.
- **Teks:** nama 15 px (Fredoka), info 11–12 px, tombol 14 px. Minimum 11 px (di HP ±3,5 mm; di bawah itu tidak terbaca). Kontras teks cokelat tua di atas krem ≥ 7:1.
- **Satu lembar, satu tujuan.** Lembar maksimal 600×400 (HP: ±86% layar), pita judul 44 px, tombol tutup 44 px (area sentuh penuh).

## Pola komponen (UiKit)
| Komponen | Isi | Ukuran |
|---|---|---|
| `UiKit.cell` (grid) | gambar 44, nama 12, lencana jumlah (pojok), chip harga | 96×92 |
| `UiKit.row` / `tradeRow` | garis aksen 5 px, gambar 40, nama 15 + info 11, [stepper 84×30] [chip harga] [tombol 70×34] | tinggi 54–58 |
| `UiKit.switch` | saklar 52×26: hijau + titik kanan = nyala | Atur: 2 kolom |
| `UiKit.priceChip` | koin + angka | tinggi 24 |

## Yang diuji dan belum
Layar dites di Studio (1335×630), bukan HP. Ukuran target sentuh dan keterbacaan 11 px di HP asli **belum diuji**; periksa di playtest HP.

## Hasil (15 Nov 2026, dites di Studio 1335×630)
Dikerjakan: panel 88%×86% maks 600×400, pita judul 44, tombol tutup 44; `UiKit.row/tradeRow/productCard` jadi baris padat 54–64 dengan garis kategori di kiri, zebra krem, gambar 44, chip harga emas, stepper 92×32; komponen baru `UiKit.cell/grid/priceChip/switch/accentStripe/modelView`. Tas = grid 5 kolom dengan model 3D tanaman, ikon ikan, lencana jumlah, chip nilai; Koleksi = grid 5 kolom (terkunci = bayangan "???"); Atur = 2 kolom dengan saklar; Toko NPC = tabel padat (Toko Pak Darmo: 3,5 baris terlihat, dulu 1,5).
Belum: Pesanan, Hadiah, Warga, Toko Robux, Panduan, Pemilih bibit memakai komponen lama/campuran; panel tidak menyusut mengikuti isi (Atur menyisakan ruang kosong); target sentuh dan keterbacaan 11 px di HP asli belum diuji.
