# UI/UX Spec: daftar, kartu, warna (15 Nov 2026)

Alasan sebelum kode. Target utama **HP landscape** (±800×360 poin), mouse hanya tamu.

## Temuan dari tangkapan layar (Tas, Toko, Atur, Koleksi, Hias, Pak Darmo)
1. **Lembar terlalu besar.** Panel memakai 96% × 92% layar. Di HP 360 poin tingginya, isi yang terlihat hanya 2–3 baris; sisanya menggulir.
2. **Satu kolom, baris 82–108 px, setengah kosong.** Teks kecil di pojok kiri-atas, tombol jauh di kanan: mata harus menyeberangi 600 px untuk menyambungkan nama dengan tombolnya (Tas: "Cabai ×1" dan "20 Koin" dipisah ruang kosong; Atur: nama di kiri, "Nyala" di kanan).
3. **Monoton.** Semua krem + emas yang sama: tanaman, ikan, alat, hiasan, uang, tombol aktif/nonaktif hampir tidak dibedakan. Pemain harus membaca tiap kata.
4. **Tombol "Nyala/Mati" untuk pengaturan** adalah kata yang harus dibaca ulang tiap kali ("Nyala" = sedang nyala atau tap untuk menyalakan?). Saklar hijau/abu dengan titik geser sudah dikenal semua orang.
5. **Pemilih jumlah dan harga** memakan 2 baris per item (stepper di atas, total + tombol di bawah) sehingga satu baris Toko 108 px.
6. **Gambar tidak dipakai.** Tas dan Toko memuat nama saja, padahal tanaman sudah punya model 3D, ikan dan alat punya ikon. Gambar dikenali ~3× lebih cepat daripada kata.

## Prinsip
- **Padat tapi tetap bisa ditap:** target sentuh ≥ 40 px (tombol/stepper); area baris boleh lebih rendah selama tombolnya ≥ 40 px (tombol aksi dibuat 34–36 + padding hitbox 44 lewat baris yang ikut bisa ditap).
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
| `UiKit.confirm` (modal) | judul 26, isi 16, tombol kiri (merah, `cancelText`) dan kanan (`confirmText`) | lebar 400, maks 86% lebar × 86% tinggi layar, tombol 56 tinggi (hitbox ≥ 44) |
| `CoachmarkController` (T1) | overlay hitam 60 %, lubang di sekitar tombol target (4 frame), ring emas berdenyut, bubble + panah, Lewati kanan atas | ring = target + 10 px; hitbox Lewati 88×44; bubble tinggi 40 |

## Kopi dan tombol (berlaku di seluruh game)
- **Kata: "Tap", bukan "Tap" atau "Tap"** untuk aksi di layar. Sisanya Bahasa Indonesia. "Hapus Petak" dan "Pindah" adalah nama aksi; "Hijaukan" sudah dihapus dari game dan docs.
- **Hierarki tombol**: satu aksi utama, solid (hijau daun `#609646`, atau emas untuk aksi biasa). Aksi sekunder: krem muda dengan outline abu, lebih kecil. Destruktif (Hapus Petak, Urug kolam) minta konfirmasi dulu.
- **Penalti tidak boleh**, buff boleh: nama aksi harus konstruktif. Aksi yang menghapus tidak diberi nama yang terdengar membangun.
- **Satu instruksi per waktu**: saat coachmark, modal, atau panel terbuka, hint bar lama disembunyikan. Coachmark berhenti sementara saat pemilih bibit / Atur / modal terbuka, dan kembali sendiri saat panel tutup.

## Plang, kolam bulat, dan sisa rumah awal (terbaru)
- **Plang pemilik** di tengah bukaan gerbang, di garis pagar (x pagar), menghadap ke jalan. Dari spawn (4 stud di luar gerbang, menghadap lahan) plang persis di depan. **Status**: `PLANG AFTER Sign @ -11.7, 4, 300 (Plot1)`, diuji di Studio.
- **Kolam bulat**: air, galian, dan dasar pasir berbentuk silinder (`Terrain:FillCylinder`). Pinggiran berisi batu yang di-clone dari asset `Workspace.Map.Nature.Batu` (16 batu, ukuran 1,4–2,6 stud, rotasi acak). Dua teratai, ukuran 2,2 dan 3,4 stud. Kotak 16×16 tetap jadi aturan penempatan dan data.
- **Kolam merah (penyebab)**: `Land.fixedRects` masih memasukkan kotak rumah awal (`Map.HOUSE`), jadi area di sekitarnya dianggap terblokir. Rumahnya sudah dihapus, tapi kotak tak-terlihat itu masih ada. Sekarang dihapus: `Land.fixedRects` kosong, `MapService.AddHouse` (tidak dipanggil) dihapus, `Map.HOUSE` dihapus.
- **Status kolam**: kode sudah ada dan tidak ada error saat Play. Preview kolam dan tampilan batu/teratai belum dilihat di layar.
- **Batu melayang (diperbaiki)**: `placeRock` punya dua bug (membaca `.Y` dari `CFrame` dan operasi `CFrame - Vector3`) dan posisi batu tidak diukur dari dasar. Sekarang batu diskalakan ke lebar, dipipihkan (tinggi 35%), diputar ke yaw, lalu diturunkan sampai dasarnya tepat di tanah. **Status**: dibangun 4 kolam di Studio, 44 batu diukur: semua menempel tanah (selisih < 0,5 stud). Screenshot kamera atas: batu rapat, tidak ada yang melayang.
- **Urug**: tinggi tanah diukur dari sekitar kolam (raycast), bukan dari level 0.
- **Label**: "Urug kolam" / "Urug" diganti "Hapus kolam" / "Hapus" (konfirmasi dan tooltip).
- **Urug, dua langkah (seperti Terrain Flatten)**: (1) isi ulang lingkaran galian dengan pasir dan rumput, (2) flatten persegi 16×16 ke level tanah sekitar: rumput sampai level, udara di atas level. Level diukur dari raycast di sekeliling kolam. Potongan udara dimulai tepat di batas voxel (4 stud).
- **Penyebab kubah (ketemu)**: permukaan yang terlihat selalu `SURFACE_OFFSET` (2 stud) di atas voxel. Flatten harus bekerja di level voxel `level - SURFACE_OFFSET`. Sebelumnya level terlihat dipakai untuk voxel, jadi tengah naik 2 stud dan grid garap ikut tertimbun.
- **Status**: diuji di Studio: setelah hapus, raycast di seluruh baris tengah kolam = 0,0 (sama dengan tanah sekitar). Screenshot: tanah rata.
- **Feedback toast dan info tutorial = PARCHMENT** (`UiKit.parchmentBox`): krem `UiKit.BG`, border bambu 3 px, teks cokelat tua `UiKit.TEXT`, GothamBold 14, 40% lebar, 36 px tinggi, di Y 12% layar. Saat alert tutorial tampil, toast turun 8 px di bawahnya. Keputusan pemilik: parchment, bukan gelap.

## Picker: asset bulatan bambu (versi terbaru)
- Bulatan bambu = image `rbxassetid://86005759010163` (`BAMBOO_RING_IMAGE`), 64 px. Tanpa latar putih, tanpa stroke emas, tanpa latar hitam. Bibit 40 px di tengah.
- Badge stok = teks putih di pojok kanan atas (tanpa lingkaran gelap). Stok 0: bibit tetap, badge `x0`. Tanpa overlay kotak.
- Kartu picker transparan. Panah putih ▼ tetap.
- **Stok 0 = disabled**: ring transparan 50 % dan abu-abu, bibit diabu-abukan (pencahayaan viewport abu-abu), badge `x0`. Tap menjelaskan "Bibit habis, beli di Toko".
- **Card HP (250 × 84)**: bingkai bambu lebih besar, avatar 48 di dalam ring 60, nama 14 px, bar XP 8 px, tiga ikon buff 28 px berjarak merata (space between, seperti PC).
- Ikon berupa `ImageButton` agar bisa di-tap (tanam / tip).
- **Plang pemilik**: **sejajar dengan garis pagar**, di samping bukaan gerbang (tidak di tengah bukaan, tidak menutup jalan masuk). Jarak 22 stud sepanjang pagar dari tengah gerbang, 1,5 stud dari tepi bukaan. Dua tiang di garis pagar. **Status**: `PLANG AFTER Sign @ -11.7, 4, 278 (Plot1)`, diuji di Studio.
- **Kartu picker**: tanpa stroke emas. **Thumbnail bibit** 52 px (dulu 40), supaya jenis bibit terlihat.

## Putaran terakhir: trigger 4 stud, bulatan 64 px, card 220×70, feedback, lampu
- **Trigger picker**: jarak tepi ≤ **4 stud** memunculkan picker, > 4 stud menyembunyikannya (`FarmController.PROXIMITY = 4`). Di HP joystick sulit pas 1 stud. **Status**: 3 stud = muncul, 5 stud = hilang (diuji di Studio).
- **Bulatan bambu**: 64 px, ring bambu coklat, disk krem 48 px di tengah, bibit 38 px di tengah. Badge bulat gelap, teks putih, pojok kanan atas, 4 px dari tepi, `ClipsDescendants = false`, ZIndex teratas. Padding panel 8 px, jarak antar bulatan 10 px.
- **Player card (HP)**: 220 × 70 px, padding 8 px. Avatar 48 px, nama 14 px, bar XP 8 px. Tiga ikon buff 28 px dengan jarak 4 px, selalu terlihat (bukan disembunyikan).
- **Plang**: di samping bukaan gerbang, 1–2 stud dari tepi bukaan, menghadap ke jalan. Posisi dicatat saat dibuat: `PLANG AFTER Sign @ -8, 4, 278` untuk Plot1 (lihat Output Studio).
- **Feedback yang dihapus**: toast "Tanah dicangkul", "Petak dipindah", teks "+N Koin", dan "+N hasil panen". Yang dipertahankan: koin dan hasil panen / ikan **terbang** ke counter atau Tas; count-up koin 0,8 detik statis.
- **Lampu gerbang**: 16 bagian dihapus **langsung di Workspace** (Edit): 8 lampu bola dan 8 tiang. Tidak ada kode yang menyembunyikan atau memindahkan lampu. Daftar nama dan posisi ada di laporan.

## Skala GUI di HP (UIScale 0,75x untuk layar kecil)
- **Aturan**: jika lebar layar < 900 atau tinggi < 450 px (HP landscape, mis. 844×390), setiap ScreenGui yang memakai UIScale diskalakan **0,75x** (`UiKit.currentScale`). Desktop dan tablet tetap aturan lama (tinggi / 560, 1–1,35).
- **Akibat**: dock 58 → ~44 px, bar koin 42 → ~32 px, tombol kanan atas 50 → ~38 px, gap dock 6 px.
- **Safe area**: setiap ScreenGui memakai `ScreenInsets = DeviceSafeInsets` (notch, sudut membulat), jadi tidak ada yang tertutup cut-out.
- **Status**: dites di Studio pada viewport 749×389: skala 0,75 aktif, card dan dock kecil, lahan tetap terlihat. Belum dites di HP fisik atau layar notch lain.

## Toast tutorial di atas (kecil, tembus pandang sedikit)
- Posisi **Y 0,12** dari atas layar (di bawah bar koin), bukan di tengah lahan.
- Lebar max **40 %** layar, tinggi **36 px**, font **14 px** (hint Garap, hint tutorial, dan toast umum 15 px).
- Latar sedikit tembus pandang (`darkBox`), agar lahan di belakangnya masih terlihat.
- **Status**: dites di Studio: toast di atas, lahan di tengah terlihat.

## Player card compact (HP)
- Di HP (lebar < 900 atau tinggi < 450): card **180 × 60 px** di kiri bawah dengan margin 12 px dari tepi (safe area).
- Avatar **36 px**, lingkaran cincin 40 px, nama 14 px, bar XP **8 px** (teks XP tetap terbaca).
- **Ikon buff** (tiga slot) dan **ikon bintang** disembunyikan di HP, tampil di desktop.
- **Status**: dites di Studio pada 749×389: card kecil, "Piko 4/20 XP" terbaca.

## Icon bibit: bulatan bambu (ganti slot putih kotak)
- **Luar**: lingkaran bambu coklat dengan tepi coklat tua, 56 px (52–56 sesuai spek). Gap grid 8 px.
- **Dalam**: disk krem `(252,242,214)` di tengah, sebagai latar PNG bibit.
- **Bibit**: 70 % dari disk krem, di tengah.
- **Badge jumlah**: lingkaran gelap (warna pill), teks putih, di pojok kanan atas, 4 px masuk dari tepi (tidak terpotong: `ClipsDescendants = false`, ZIndex paling atas).
- Stok 0: disk redup 50 %, badge `x0` tetap tampil. Bibit terkunci tetap disembunyikan. Tanpa tulisan Lv.
- **Status**: dites di Studio (screenshot): ring bambu, bibit di disk krem, badge bulat `x2`/`x0` utuh.

## Feedback: terbang ke Tas dan koin (FeedbackController)
- **Toast "Tanah dicangkul" dihapus** (tidak penting, menutupi layar).
- **Panen → Tas**: token warna tanaman terbang dari petak ke tombol Tas, 0,6 detik, OutQuad, mengecil dan memudar; lalu tombol Tas berdenyut 0,2 detik.
- **Ikan → Tas**: saat `fish.caught`, token biru terbang dari area air ke Tas (sama).
- **Koin → counter**: token koin terbang dari titik sumber ke counter, lalu angka naik.
- **Count-up koin**: durasi **tetap 0,8 detik** untuk jumlah berapa pun (10 atau 1000). Angka diinterpolasi dari nilai lama ke baru berdasarkan waktu nyata, bukan per koin. Tag `+N` melayang di samping counter.
- **Antrean**: hadiah berurutan, tidak saling menumpuk. Setiap hadiah menyimpan total sebelum dirinya.
- **Status**: count-up 1000 koin dites di Studio: angka mulai naik 0,7 s, selesai 1,5 s (≈0,8 s). Terbang ke Tas dan ikan belum dites di layar.

## Plang dan lampu gerbang (revisi)
- Lampu di **dalam bukaan gerbang** atau dalam **5 stud** dari bukaan **dihapus** (`MapService.removeGateLamps`, saat runtime). Tidak dipindah, tidak ada lampu baru. Total 16 bagian dihapus (8 lampu + 8 tiang).
- Plang tetap di **samping bukaan**, 1–2 stud dari tepi bukaan, menghadap ke jalan.

## Pindah: petak yang bergerak (bukan hanya highlight)
- Saat Pindah aktif, **petak asal transparan 50 %** (diangkat).
- **Preview petak** (salinan petak 8×8 termasuk tanaman dan visual pertumbuhannya, transparan) mengikuti kursor di kotak tujuan.
- Outline **hijau** tipis jika valid (semua Leafy Grass di lahan sendiri), **merah** jika tidak valid. Highlight hijau polos dihapus.
- Dikonfirmasi: petak pindah, opacity kembali 100 %. Dibatalkan: petak asal kembali 100 %, preview hilang.
- Timer tanaman tidak di-reset.
- **Status**: kode ada. Belum dites di layar (lihat laporan).

## Respawn di depan gerbang sendiri
- Setiap spawn (join pertama, respawn setelah mati, rejoin, awal T1) di **depan gerbang lahan sendiri**, 4 stud di luar pagar, menghadap ke dalam lahan (`Plots.GATE_SPAWN`).
- Kamera di **belakang karakter**, menghadap ke dalam lahan (`CoachmarkController.gateCamera`, dipanggil tiap spawn).
- **Status**: spawn dan kamera dites di Studio (`-8, 300`, menghadap ke dalam); plang "Lahan Kosong" terlihat di samping.

## Jarak proximity = jarak ke tepi petak
- Jarak picker dihitung dari posisi pemain ke **titik terdekat di kotak petak** (clamp), bukan ke tengah. Petak 8×8 punya tepi 4 stud dari pusat; memakai pusat membuat picker tidak pernah muncul saat pemain menempel.
- Picker muncul jika jarak tepi ≤ 1 stud, hilang jika > 1 stud.
- **Status**: dites di Studio: 0,3 stud dan 1,0 stud muncul; 1,5 stud dan 3,5 stud hilang.

## Float GUI picker (desain)
- **Pill gelap** transparan, di atas petak, panah ▼ ke tengah petak.
- **Slot putih** bulat per bibit, 52 px, gap 8 px. Background putih diperlukan supaya bibit (PNG) terbaca. Bibit di tengah slot.
- **Badge bulat** gelap di pojok kanan atas slot (bukan di bawah), teks putih `xN`. Stok 0: slot tetap putih, bibit redup 50 %, badge `x0` tetap tampil.
- **Terkunci**: disembunyikan total, tanpa "Lv".
- **Status**: slot putih dan badge bulat dites di Studio (screenshot).

## Garap: tap petak yang sudah jadi = Pindah / Hapus
- Di mode Garap, **tap petak yang sudah jadi** langsung membuka menu Pindah / Hapus untuk petak itu (tanpa keluar Garap, tanpa long-press pill).
- Petak yang sudah jadi **tidak** menampilkan ghost taruh. Gantinya: **outline emas** (Highlight) di sekeliling petak dan hint "Tap untuk atur petak: Pindah / Hapus".
- Garap **dijeda** (ghost disembunyikan) selama menu terbuka, dan kembali aktif setelah menu ditutup, Pindah, atau Hapus.
- Prioritas: di Garap, tap petak jadi = menu, bukan seed-picker. Seed-picker hanya saat tidak di Garap.
- Pindah dari Garap memakai validasi rumput yang sama. Hapus memakai modal yang sama (merah bata, Batal abu).
- **Status**: outline, hint, dan menu dari Garap dites di Studio. Hapus dari Garap belum terbukti bersih (lihat laporan).

## Validasi area Garap (dan Pindah)
- Satu petak 8×8 hanya bisa ditaruh kalau **semua titik sampel di atas Leafy Grass**: 5×5 titik (offset 0, 2, 4, 6, 7.9 stud), jadi petak setengah di jalan juga ditolak.
- Cek: raycast turun dari atas tiap titik. Hit di Terrain harus `LeafyGrass`; hit di part apa pun (jalan, bangunan, pagar) atau tidak ada hit = bukan rumput.
- Hasil di-cache 0,5 detik (dipakai tiap frame oleh ghost).
- **Ghost merah** (`196,72,60`) + arrow merah bila ditolak; **ghost hijau terang** (`104,214,84`) + arrow hijau bila valid.
- Hint berubah ke "Tidak bisa digarap di sini" saat ditolak, kembali ke hint Garap saat valid.
- Pindah memakai aturan yang sama: tidak bisa pindah ke jalan, bangunan, atau tanah kosong.
- **Status**: dites di Studio: merah di jalan dan di tepi jalan, hijau di rumput tengah.

## Grid dua stud (Garap dan Hias, satu grid)
- **Satu grid visual** untuk Garap dan Hias: garis tipis tiap **2 stud** (`Decor.CELL`) untuk hiasan, dan garis lebih tebal tiap **8 stud** (`Land.TILE`) untuk batas petak garap.
- **Data petak tetap di grid 8 stud** (tidak ada migrasi). Yang berubah hanya visual dan snap: Garap nge-snap ke garis tebal (tiap 8 stud), Hias nge-snap ke garis tipis (tiap 2 stud).
- **Ghost Garap** = tepat satu kotak 8×8 stud, pas ke garis tebal, tanpa celah dan tanpa skala pengecilan.
- **Hias** membuka grid yang sama lewat `GarapController.HoldGrid` (bukan grid kedua).
- **Status**: visual dan snap sudah dites di Studio. Snap Hias ke 2 stud belum dites karena menu Hias tidak dibuka di tes ini.

## Proximity seed-popup (tanam tanpa picker modal)
- **Tanpa hover, tanpa picker modal di tengah layar.** Tap petak kosong tidak membuka apa-apa. Popup muncul sendiri saat pemain **dalam jarak 1 stud** dari tepi petak kosong.
- **Hanya satu popup**: petak terdekat dalam jarak. Pindah ke petak lain, popup pindah. Menjauh, popup hilang.
- **Satu baris 4 ikon** (36 px, gap 6). Bibit 8 jadi 2 baris, 12 jadi 3 baris. Popup di atas petak dengan panah ▼ ke petak; di bawah petak kalau tidak ada tempat di atas; dijepit ke dalam layar.
- **Ring putus-putus** 12 titik putih mengelilingi petak, berjarak 1 stud dari tepi (ini batas proximity).
- **Ikon** (hanya yang sudah dibuka):
  - Punya bibit: terang, full color, badge `xN`, tap = tanam.
  - Sudah dibuka, stok 0: redup 50 %, badge `x0`, tap = tip "Bibit habis, beli di Toko".
  - **Bibit terkunci disembunyikan total** dari picker: tanpa gembok, tanpa "Lv". Di Lv 1 picker hanya 1 baris 1-2 ikon. Info level tetap ada di Toko ("Buka di Lv X" sebagai target progres).
  - Tanpa nama di ikon. Panel mengecil mengikuti jumlah ikon (tidak dipaksa lebar).
- **Gaya panel**: pill gelap transparan (`38,46,34`, transparansi 0.12), padding cukup, panah ▼ ke tengah petak. Bukan kartu krem.
- **Pill "Kosong" disembunyikan** untuk petak kosong: popup menggantikannya. Kartu popup dinamai `TanamButton` agar sorotan tutorial Tanam tetap bisa.
- **Tahan** ikon 0,3 detik = tip kecil "nama · xN" di atas kartu.
- **Animasi**: scale 0 → 1 dengan bounce; ikon muncul bertahap 0,05 detik dari depan ke belakang.
- **Status**: proximity, popup, tap tanam, dan petak berisi bibit sudah dites di Studio. Tahan 0,3 detik dan animasi stagger belum dites.

## Menu petak (tahan pill petak)
- **Tap** pill petak = popup proximity (tanam) bila kosong, atau siram/panen sesuai keadaan.
- **Tahan** (±0,45 detik) = menu di atas petak:
  - Petak **kosong**: **Pindah** (hijau solid) dan **Hapus Petak** (merah bata lembut `#B05C42`, konfirmasi dulu dengan Batal abu outline).
  - Petak **ditanami** (termasuk yang sudah matang): **Pindah tetap aktif** (tanaman, timer, dan siram ikut pindah). **Hapus Petak terkunci** (abu pudar). Teks: "Lagi ditanami, bisa dipindah, tidak bisa dihapus".
- **Merah hanya untuk Hapus**: tidak ada hijau untuk aksi destruktif.

## Plang gerbang
- Setiap lahan punya **plang kayu** di **samping gerbang** (di luar pagar, sisi kanan bukaan), menghadap jalan (dua tiang kayu, papan 9×4 stud), bukan label melayang. Hanya satu plang per lahan.
- **Tidak ada objek di tengah bukaan gerbang.** Lampu tiang (Map.Lamps) yang sebelumnya berdiri di tengah bukaan dipindah ke sisi pagar di luar bukaan (`MapService.relocateGateLamps`, saat runtime, tanpa mengubah file place). Lampu di tempat lain tidak diubah.
- **Status**: lampu dipindah (8 lampu + 8 tiang, satu pasang per lahan); tes jalan masuk lewat gerbang dari jalan (x=10 ke x=−30 di z=300) berhasil. Screenshot gagal karena viewport 3D hitam (ScreenGui "Freecam" dari tooling Studio aktif saat play), jadi bukti visual belum ada.
- Isi: **"Kebun [Nama]"** kalau ada pemilik, **"Lahan Kosong"** kalau kosong. Tanpa angka tambahan.
- Plang ada di luar bukaan gerbang (x = 22, gerbang 32 stud di tengah) supaya tidak menghalangi jalan masuk.

## Atur 1×4
- Satu kolom, full lebar, empat baris: Musik, Suara alam, Efek suara (toggle di kanan), lalu Panduan (tombol Buka di kanan).
- Panel menyusut sesuai isi; scrollbar disembunyikan. **Status**: sudah dites di Studio (screenshot).

## Modal konfirmasi
- **Mulai**: hijau solid (utama). **Lewati**: krem muda, outline abu, lebih kecil (sekunder), tanpa skin emas, teks utuh.
- **Hapus Petak**: merah bata lembut (`#B05C42`), **Batal** abu outline.
- Status Lewati setelah putaran ini: screenshot ada, tapi tes Lewati dan Ulang dari klik belum terverifikasi (klik di Atur tidak selalu membuka panel di tes ini).

## Grid Garap dan Pindah
- **Grid** muncul hanya saat mode Garap (atau Pindah) aktif, dan hanya di **lahan sendiri** (chunk yang dimiliki, tidak di jalan, di luar pagar, atau lahan orang lain). Garis putih tipis, opacity sekitar 38 % (transparansi 0.62), rumput tetap terlihat. Grid hilang saat mode mati.
- **Ukuran kotak grid** = satu petak (`Land.TILE` = 8 stud). Petak selalu nge-snap ke grid ini. Catatan: hiasan terkecil 2×2 stud (`Decor.CELL` = 2) memakai grid sendiri; grid petak tidak dipecah jadi 2 stud (lihat keputusan di Tutorial_Engine).
- **Ghost + arrow**: ghost petak 7×7 stud di kotak grid yang ditunjuk pointer atau jari, dan mengikuti gerak. Di atasnya ada arrow `▼` yang mantul ke bawah (menandakan "tap di sini").
  - Kotak valid (dalam lahan sendiri, kosong): ghost hijau transparan + arrow hijau.
  - Kotak tidak valid (jalan, luar pagar, numpuk petak lain): ghost abu + arrow abu ("tidak di sini").
- **Pindah** memakai grid dan ghost yang sama persis: tahan petak kosong (lihat di bawah) → pilih Pindah → grid muncul → ghost ikut jari → tap untuk taruh. Tidak ada sistem kedua.

## Menu petak (tahan pill petak)
- **Tap** pill petak kosong = pilih bibit (tanam, seperti biasa).
- **Tahan** (±0,45 detik) pill petak = menu kecil di atas petak:
  - Petak **kosong**: **Pindah** (hijau solid, utama) dan **Hapus Petak** (sekunder). Hapus Petak minta konfirmasi ("Petak kembali jadi rumput. Tidak ada yang hilang.").
  - Petak **ditanami** (termasuk yang sudah matang): kedua tombol abu-abu pudar, dan teks "Lagi ditanami, tidak bisa dipindah". Tidak ada tap berulang tanpa penjelasan.
- Pindah tidak masuk T1. T1 tetap: Garap → Tanam → Siram → Panen → Jual.

## Coachmark (T1, tuntunan langkah)
- **Overlay**: 60 % hitam (transparansi 0.4) hanya saat T1 berjalan. Lubang dibuat dari **4 frame gelap** (atas, bawah, kiri, kanan) di sekeliling target, jadi target tampil terang seperti lubang. Frame gelap itu `Active`: semua tap di luar lubang ditelan, termasuk tombol lain, panel, dan dunia.
- **Dua jenis**:
  - *Fokus tombol* (Garap, Tanam, Siram, Panen): lubang di sekitar tombol (pad 8 px). Ring emas di tombol, bubble di atas dengan panah ke bawah (di bawah bila tidak ada tempat di atas).
  - *Fokus tanah* (sub-langkah setelah Garap, sampai petak pertama jadi): **dunia 3D tidak digelapkan**. Hanya panel UI (chip atas, kolom menu kanan, dock, kartu pemain) yang digelapkan dan diblokir, satu frame per panel HUD. Target-nya adalah **ghost + arrow Garap** (lihat "Grid Garap dan Pindah"), jadi tidak ada ring di sini. Bubble di tengah atas: "Tap rumput yang nyala".
  - *Arrow Pak Darmo* (langkah Panen/Jual, tanpa blok): melayang pelan naik-turun di atas kepala NPC, bukan mantul ke bawah. Kalau NPC di luar layar, arrow menempel di tepi layar ke arah NPC (◀ / ▶).
- **Ring dan lubang**: bentuk highlight mengikuti target. Tombol dock bulat → ring bulat. Pill (kotak melengkung) → kotak melengkung, padding 8 px. Satu highlight saja per langkah.
- **Gelap seragam**: overlay 60 % (transparansi 0.4) di semua langkah yang menggelapkan. Empat frame overlay berbatas piksel utuh dan tidak tumpang tindih, supaya tidak ada garis tipis.
- **Bubble**: pendek, satu kalimat. Teks: "Tap Garap dulu", "Tap petak kosong buat tanam", "Tap Siram di petak ini", "Tap Panen, lalu jual ke Pak Darmo", "Tap rumput yang nyala".
- **Lewati** selalu di kanan atas, di atas overlay, hitbox 44 px.
- **Hint bar lama** disembunyikan saat coachmark aktif. Modal Mbok Minah (langkah 0) tetap dipakai dan tidak diganti coachmark.
- **Langkah tanpa blok** (`block = false`, dipakai untuk Panen/Jual): ring dan bubble saja, tanpa overlay, karena pemain harus ke Pak Darmo di luar lubang.
- **Garap ditutup otomatis** setelah langkah tanah selesai, karena mode Garap yang terbuka menyembunyikan pill Tanam/Siram/Panen.
- **Koordinat layar**: `AbsolutePosition` tidak memasukkan inset bar atas (`GuiService:GetGuiInset().Y`, 58 px di Studio). Posisi overlay harus ditambah inset itu. ScreenGui coachmark memakai atribut `NoScale` agar UiKit tidak memberi `UIScale`.

## Yang diuji dan belum
Layar dites di Studio (1335×630), bukan HP. Ukuran target sentuh dan keterbacaan 11 px di HP asli **belum diuji**; periksa di playtest HP.

## Hasil (15 Nov 2026, dites di Studio 1335×630)
Dikerjakan: panel 88%×86% maks 600×400, pita judul 44, tombol tutup 44; `UiKit.row/tradeRow/productCard` jadi baris padat 54–64 dengan garis kategori di kiri, zebra krem, gambar 44, chip harga emas, stepper 92×32; komponen baru `UiKit.cell/grid/priceChip/switch/accentStripe/modelView`. Tas = grid 5 kolom dengan model 3D tanaman, ikon ikan, lencana jumlah, chip nilai; Koleksi = grid 5 kolom (terkunci = bayangan "???"); Atur = 2 kolom dengan saklar; Toko NPC = tabel padat (Toko Pak Darmo: 3,5 baris terlihat, dulu 1,5).
Belum: Pesanan, Hadiah, Warga, Toko Robux, Panduan, Pemilih bibit memakai komponen lama/campuran; panel tidak menyusut mengikuti isi (Atur menyisakan ruang kosong); target sentuh dan keterbacaan 11 px di HP asli belum diuji.
