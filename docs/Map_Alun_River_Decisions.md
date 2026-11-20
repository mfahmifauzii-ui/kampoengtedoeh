# Keputusan: gerbang ke alun-alun + sungai di jalan sumbu

**Tanggal:** 18 Nov 2026
**Branch:** `feature/alun-river-gates` (dari `feature/back-range-mountains`)
**Status:** kode sudah diubah dan lolos parse + `rojo build`. **Belum diterapkan ke place Studio** (terrain, `Workspace.Map`, dan Warung Mini masih versi lama). Belum dites di Play.

---

## Permintaan

1. Gerbang tiap lahan pindah dari sisi jalan ke **depan, menghadap alun-alun**.
2. Jalan pemisah antar lahan (jalan sumbu) jadi **sungai yang mengalir sampai air di alun-alun**.
3. Area pohon di depan lahan dihapus, atau lahan dimajukan.
4. Warung Mini digeser supaya tidak menabrak lahan.

## Keputusan

1. **Lahan maju ke depan, gerbang menghadap alun-alun** (`Config/Plots.luau`).
   - Jarak pusat lahan di sumbu: **300 → 265**. Sisi depan lahan sekarang 4 stud di luar tepi luar ring road (`Map.TOWN.RING_R = 165`).
   - Arah lahan (yaw) sekarang sejajar sumbu, dengan depan (+Z lokal) menuju pusat. Contoh: `south_left` yaw `pi` (gerbang menghadap utara).
   - Tidak bisa lebih maju: sudut depan lahan di x = 12 hampir menyentuh ring road.
2. **Pohon di depan lahan: dihapus, lalu diganti jalur tanah** (pilihan "hapus" dari dua pilihan yang Anda sebut).
   - Di antara gerbang dan ring road masih ada celah sekitar 45 stud. Celah ini jadi **jalur tanah** lebar 33,3 (sama dengan bukaan gerbang), dari gerbang ke ring road (`buildPaths`).
   - Area jalur dan sungai dijaga bebas pohon, semak, dan batu (`inRiverOrPath`, 24 stud dari tengah gerbang).
3. **Jalan sumbu jadi sungai.** Lebar **12 stud** (setengah lebar jalan lama), dari tepi kanal sampai tepi peta, di keempat sumbu (`buildTerrain`, fungsi `riverBlock`).
   - Level sama dengan kanal: udara di atas, air sampai `WATER_Y`, dasar pasir.
   - Jalan sumbu dan lampu sumbunya dihapus. Lampu di ring road tetap.
4. **Jembatan kecil di ring road** di tiap sumbu, supaya ring road tetap bisa dilewati (`buildBridge`, deck `RingDeck` 43 × 18 stud).
   - Akses lahan tidak butuh jembatan: gerbang langsung ke jalur tanah lalu ke ring road.
5. **Warung Mini digeser** ke ring road, 50 stud dari sumbu dan 139 stud dari pusat (radius ~148, di tengah band ring road). Posisi baru (pola simetri 90°):
   - Utara `(50, -139)`, Selatan `(-50, 139)`, Timur `(139, 50)`, Barat `(-139, -50)`.
   - Posisi lama `(21, -219)`, `(-21, 217)`, `(-217, -18)`, `(218, 21)` masuk ke area lahan baru.
   - Warung Mini ada di `Workspace` (hand-placed), bukan di kode. Pemindahannya dilakukan di Studio. Bang Tarno mengikuti posisi model.

## Dampak

- **Data pemain:** lahan dibangun dari data relatif ke slot (`Plots.LAYOUT`), jadi lahan ikut pindah ke posisi baru saat server dibuka. Belum dicek di Play dengan pemain yang sudah punya lahan.
- **Tidak diubah:** ukuran lahan (128 awal / 192 cadangan), chunk, harga, dan dinding peta.
- **Pegunungan:** tidak diubah di branch ini (ada di `feature/back-range-mountains`).

## Yang belum diterapkan ke place (perlu persetujuan)

Kode di repo sudah benar, tapi tiga hal di place masih versi lama:
1. **Terrain** (sungai, lahan baru). Dibangun ulang dengan `RebuildTerrain` sementara, sama seperti sebelumnya.
2. **`Workspace.Map`** (jalan, jembatan, pagar, pohon). Di-baked dari generator. Perlu dibangun ulang. Folder lama tidak akan hilang: sudah dibackup ke `ServerStorage.MapBackup`.
3. **Warung Mini** (4 model). Dipindah di Studio sesuai tabel di atas.

Backup versi sebelum perubahan ini: `ServerStorage.MapBackup` di place (dibuat 18 Nov) dan `_backup/map_2026-11-18/` di repo.

## Cara cek (setelah diterapkan)

- Gerbang tiap lahan menghadap alun-alun, dan jalur tanah sampai ring road.
- Sungai dari tepi peta sampai kanal, dengan jembatan di ring road tiap sumbu.
- Warung Mini tidak nabrak lahan, dan Bang Tarno berdiri di sisi jalan barunya.
- Lahan pemain yang sudah punya chunk tetap utuh dan pas di posisi baru.
- Waktu build terrain tetap wajar (sebelumnya sekitar 1–3 detik).

## Verifikasi

| Cek | Hasil |
|---|---|
| StyLua parse `MapService.luau` | Lolos (exit 0) |
| StyLua parse `Plots.luau` | Format tidak lolos, sama seperti sebelumnya (file repo tidak mengikuti StyLua). Bukan gerbang |
| `rojo build` | Lolos |
| Test di Studio | **Belum** |

## Status penerapan (18 Nov, Studio, Edit mode)

- **Bug ditemukan dan diperbaiki:** `Config/Map.luau` punya dua key `RING_R` (165 untuk ring road, 62 untuk radius toko). Lua memakai yang terakhir, jadi ring road batu tidak pernah dibangun. Sekarang radius toko `SHOP_R = 62`, dan `RING_R = 165` (commit `277babd`). Posisi toko dan warung tidak berubah. Efek lain: ring road batu terlihat, dan jarak bersih pohon dari ring road ikut sesuai desain (`RING_R + 10`).
- **Terrain** dibangun ulang (1,2 detik): sungai, ring road, lahan baru.
- **`Workspace.Map`** dibangun ulang dari generator (1,5 detik): jalan sumbu jadi sungai, jalur gerbang, jembatan ring road, pagar, pohon. `Workspace.Fishing` dikosongkan lalu diisi ulang.
- **Warung Mini** dipindah: utara `(50, -139)`, selatan `(-50, 139)`, timur `(139, 50)`, barat `(-139, -50)`. Rotasi tidak diubah.
- **Map lama** (versi sebelum ini) disimpan di `ServerStorage.MapBackup` sebagai `Map_prev`.
- **Belum disimpan** ke Roblox. Belum dites di Play.

Cek visual: dari atas, sungai dari kanal sampai tepi peta dan jembatan di ring road terlihat. Dari dekat, gerbang menghadap alun-alun dan jalur tanah sampai ke ring road.

## Revisi pagar (18 Nov)

- Jarak pagar dari tepi lahan yang sudah dimiliki: **4,45 → 2 stud** (`FENCE_OUT`).
- Di tepi kotak cadangan (batas maksimal lahan), pagar tetap di garis tepi (0 stud), supaya pagar tetangga tidak bersilangan.
- Belum diterapkan ke Studio. Pagar di place masih versi lama sampai dibangun ulang.

## Revisi pagar v3: sudut harus tertutup (18 Nov)

**Aturan dari Anda:** yang boleh terbuka hanya **gerbang**. Di setiap sudut lahan, pagar harus bertemu pagar (tidak ada celah).

**Penyebab celah (ditemukan di Studio):** di tiap sudut dua sisi pagar tegak lurus bertemu di satu titik. Kode lama membuang segmen ujung sisi kedua karena dianggap dobel (`placedSegments`, jarak < 3,2 stud). Akibatnya ada celah **3,5 stud** di setiap sudut (8 lahan x 4 sudut).

**Perbaikan (`buildPlotFence`):**
- Segmen di sudut tidak lagi dibuang karena tegak lurus. Dua sisi tegak lurus sama-sama memakai segmen ujungnya dan bertemu di tiang sudut.
- Yang dibuang hanya segmen yang sejajar dan menumpuk di tempat yang sama (dobel sungguhan, jarak < 1 stud).
- Gerbang tetap dibuka di tengah sisi depan (`GATE_HALF` 16,65).

**Hasil cek di Studio (titik ujung segmen, dibandingkan tiap lahan):**
- Sebelum: 10 ujung terbuka per lahan (8 di sudut, 2 di tepi gerbang).
- Sesudah: 2 ujung terbuka per lahan, keduanya tepi gerbang. Total 1056 segmen (8 x 132).

**Catatan terbuka (belum selesai):**
- Di sisi lahan yang menghadap jalan sumbu (x ±12 dari sumbu), ada celah 36 stud di tengah lahan. Celah ini juga terjadi di kode lama dan belum saya pastikan penyebabnya. Belum dipastikan apakah sisi itu memang harus dipagar; perlu dicek dulu.
- Tes beli lahan di Play dan screenshot belum dilakukan. Screen capture di Studio timeout beberapa kali.

**Catatan proses:** setiap `RebuildFence` memanggil `buildLandFences` yang membuat folder `LandFences` baru. Saat tes, ini membuat tiga folder duplikat di `Workspace.Map`. Sudah dibersihkan jadi satu folder. Export sementara `RebuildFencesTmp` sudah dihapus lagi dari kode.
