# Technical Summary: Petak Garap, Kolam, Hias, dan Sistem Grid

Ringkasan teknis bagaimana game membuat dan memvalidasi lahan pemain. Semua angka diambil dari kode (`src/shared/Config`, `src/shared/Modules`, `src/server/Services`, `src/client/Controllers`).

---

## 1. Gambaran Umum

Setiap pemain punya **satu plot** (kebun). Plot dibagi jadi beberapa lapisan grid, masing-masing untuk fitur berbeda:

| Lapisan | Ukuran sel | Dipakai untuk | Sumber |
|---|---|---|---|
| Terrain voxel | 4 stud | Tanah (Ground/Mud/Sand/Water), dicat ulang oleh MapService / FarmService / PondService | Roblox Terrain |
| Chunk (lahan) | 32 stud | Unit pembelian lahan | `Plots.CHUNK.SIZE` |
| Petak garap (tile/bed) | 8 stud (`Land.TILE` = `Land.PITCH`) | Bed tanam, kolam (kelipatan 8) | `Land.lua` |
| Decor cell | 2 stud (`Decor.CELL`) | Footprint barang hias | `Decor.lua`, `DecorGrid.lua` |

Semua koordinat berada dalam **plot-local studs**: origin di tengah reserved square, +Z menghadap jalan (depan), +X ke kanan. Semua koordinat plot dibuat kelipatan 4 agar selaras dengan sel terrain.

---

## 2. Plot dan Lahan (`Config/Plots.luau`, `Modules/Land.luau`)

### 2.1 Layout plot
- `COUNT = 8` plot, diletakkan melingkar di sekitar alun-alun (`LAYOUT`, dengan `x`, `z`, `yaw` per slot).
- Setiap plot punya **reserved square 192 x 192 stud** (`SIZE = REGION = 192`). Ini batas maksimum tanah yang bisa dimiliki.
- Plot center berjarak `DEPTH = 300` dari pusat map. Kode memberi komentar jangan dimajukan ke 265: reserved square dua plot di sudut tetangga akan overlap.
- **Start land** = 128 x 128 (`START_SIZE = 128`), x -64..64, z -32..96, menempel di sisi jalan.
- **Front yard**: sisi reserved square yang menghadap town (`INWARD(plotIndex)` = +1 atau -1) tidak pernah bisa dibeli.

### 2.2 Chunk (unit pembelian lahan)
- Reserved square dibagi menjadi chunk **32 x 32** (`CHUNK.SIZE = 32`), grid 6 x 6.
- Chunk index: `ix`, `iz` dari -3..2 (`CHUNK_MIN` .. `CHUNK_MAX`).
- Start land = chunk ix -2..1, iz -1..2 (4 x 4 = 16 chunk), sudah dimiliki sejak awal.
- Chunk yang dimiliki pemain disimpan sebagai set key string `"ix,iz"` di `data.land.chunks`.
- **Aturan beli** (`Land.canBuyChunk`):
  1. Chunk ada di dalam reserved square.
  2. Belum dimiliki.
  3. Bukan kolom chunk di sisi `inward` (front yard).
  4. Bersisian (4 arah) dengan chunk yang sudah dimiliki.
- **Harga**: `PRICE_BASE * PRICE_GROWTH ^ n` dibulatkan ke kelipatan 10, dengan minimum 10. `PRICE_BASE = 1500`, `PRICE_GROWTH = 1.2`. Game pass "plots" memberi diskon 20 % (`PASS_DISCOUNT`).
- **Server** (`LandService.onBuy`): cek `canBuyChunk`, potong Koin, simpan ke data, lalu panggil `MapService.SetChunkOwned` dan `MapService.RebuildFence`.
- Pada `MapService`, chunk yang dibeli dicat rumput cerah (LeafyGrass), pohon hutan di chunk itu disembunyikan (dipindah ke `ServerStorage > ForestHidden`), dan pagar dibangun ulang.

Blok yang berlaku sekarang adalah **32 x 32** (`CHUNK.SIZE = 32`). Migrasi save v11 -> v12 (`Migrations.luau`) mengubah 16 x 16 menjadi 32 x 32. Dari 20 blok di luar lahan awal, 6 blok di kolom depan (menghadap town, `INWARD`) tidak bisa dibeli, jadi **14 blok** bisa dibeli (`Land.EXTRA_CHUNKS = 36 - 16 - 6 = 14`). Harga 14 blok pertama sekitar 89.000 Koin.

---

## 3. Petak Garap / Bed Tanam (`Config/Farm.luau`, `Modules/Land.luau`, `Services/FarmService.luau`)

### 3.1 Grid petak garap
- **Ukuran sel = `TILE` = 8 stud**, **pitch = 8 stud** (`PITCH`, tanpa jarak).
- Koordinat sel `(cx, cz)` dihitung dari **pusat plot**. Rect sel: `minX = cx * 8`, `minZ = cz * 8`, `maxX = minX + 8`.
- Pusat bed: `Land.tileCenter(cx, cz)` = `cx * 8 + 4`, `cz * 8 + 4`.
- Dari sel ke titik: `Land.cellOfPoint(x, z)` = `floor(x / 8)`, `floor(z / 8)`.
- Karena `192 / 8 = 24`, grid petak menutup seluruh reserved square secara tepat. Start land (x -64..64, z -32..96) setara dengan `cx` -8..7 dan `cz` -4..11.

### 3.2 Visual bed
- Bed bukan Part besar. Tanahnya dicat sebagai terrain voxel dengan `WriteVoxels`:
  - `"none"` = LeafyGrass (rumput), occupancy 0.5
  - `"dry"` = Ground (tanah kering, warna `SOIL_DRY`), occupancy `Farm.BED_OCCUPANCY` = 0.5 (sama dengan rumput, jadi tanah tetap rata)
  - `"wet"` = Mud (tanah basah, `SOIL_WET`)
- Bed terlihat tinggi karena **slab Part** setebal `TILE_HEIGHT = 0.6` stud (`BED_RAISE = 0.6`), bukan karena terrain. Terrain di bawahnya tetap rata. Versi lama memakai occupancy 0.85 untuk gundukan lembut, tetapi nilai itu sudah tidak dipakai.
- Setiap tile juga punya **Part klik tak terlihat** (`makeTilePart`) yang membawa atribut `Cx`, `Cz`, `Index` (uid), `Owner`, `Crop`, `PlantedAt`, `ReadyAt`, `Watered`. Client memakai part ini untuk prompt interaksi.
- Slab tanah visual tipis: `BED_SIZE = 7`, `TILE_HEIGHT = 0.6`, sehingga ada celah 1 stud antar bed.

### 3.3 Aturan garap (`FarmService.onTill`)
1. Nilai `cx`, `cz` harus integer dan `|value| <= MAX_CELL`.
2. Jumlah tile belum melebihi `Farm.MAX_TILES = 100` (hanya safety valve).
3. Jarak pemain ke pusat sel `<= TILL_DISTANCE = 60` stud (dicek server).
4. `Land.canTill` lolos:
   - Rect sel ada di dalam chunk yang dimiliki (`rectInside`).
   - Tidak overlap dengan `Land.fixed` (sekarang kosong).
   - Sel belum ada tile lain di posisi itu.
   - Tidak overlap dengan **rect decor** (`DecorGrid.entryRect`) dan **rect kolam** (`Land.pondRects`).
5. Simpan ke `data.farm.tiles` dengan `uid` stabil, lalu bangun part dan cat terrain.

Tile diidentifikasi dengan `uid` (`data.farm.nextUid`), bukan indeks array.

---

## 4. Kolam (`Services/PondService.luau`, `Config/Fishing.luau`)

### 4.1 Ukuran dan grid
- Kolam **16 x 16 stud** (`Fishing.POND.SIZE = 16`), sama dengan **2 x 2 sel petak garap**, jadi kolam selaras dengan grid 8 stud.
- `POND_TILES = SIZE // TILE = 2`. `Land.pondRect(cx, cz)` memakai sel 8-stud yang sama dengan petak garap.
- Maksimum 4 kolam (`MAX_PONDS`). Harga kolam ke-n: `PRICES = {0, 400, 900, 1600}` koin. Hapus kolam mengembalikan 50 % (`REFUND_RATE = 0.5`).
- Data disimpan di `data.pond.list` sebagai `{ uid, cx, cz, paid, lastCollect }`.

### 4.2 Cara membangun kolam (`onBuild`)
Urutan validasi:
1. Kolam harus sudah terbuka (`guide.kolamUnlocked`) dan level pemain >= `Fishing.LOCATIONS.kolam.unlockLevel`.
2. Jumlah kolam di bawah `MAX_PONDS`.
3. Jarak pemain ke pusat kolam `<= TILL_DISTANCE + SIZE`.
4. `Land.canPond(cx, cz, tiles, ponds, decorRects, chunks)`:
   - Rect kolam ada di dalam chunk yang dimiliki.
   - Tidak overlap dengan tile garap, kolam lain, atau rect decor.
5. Bayar harga, tambah entry, lalu `buildOne`.

### 4.3 Terrain kolam
- Air dan dasar berupa terrain, bukan Part. Dibuat dengan `FillCylinder` agar kolam berbentuk bulat, sedangkan kotak 16 x 16 tetap dipakai sebagai aturan penempatan.
  - Lubang kedalaman `DEPTH = 8`, isi `Water` sampai `Map.RIVER.WATER_Y` (-1), dasar `Sand` 4 stud.
- Semua blok diturunkan `Land.SURFACE_OFFSET = 2` stud (karena permukaan terrain terlihat 2 stud di atas blok).
- Saat kolam dihapus (`fillPond`), tanah dikembalikan ke level tanah sekitar. Level diambil dari 8 raycast di ring luar, lalu median. Setelah itu dilakukan flatten 16 x 16.

### 4.4 Visual dan spot memancing
- Bagian visual per tier kapasitas (`Upgrades.tier(data, "pond")`):
  - Tier apa pun: 22 batu flat dari `Workspace.Map.Nature` ("Batu") melingkar, plus 2 daun teratai.
  - Tier 2: 4 tiang lampu di pojok, dengan `PointLight` yang diaktifkan saat malam lewat tag `DecorLight`.
- Spot tak terlihat `Pond{uid}` (16 x 16, transparan) membawa atribut `Cx`, `Cz`. Itu dipakai `FishService.SetupPond` untuk prompt memancing dan panen.

### 4.5 Ketika pemain keluar atau mendapat plot baru
- `PlotService.Assigned` memanggil `clearPlot` lalu `buildAll`, yaitu membangun ulang semua kolam dari data.
- `PlotService.Released` mengembalikan terrain kolam ke tanah.

---

## 5. Hias / Decor (`Config/Decor.luau`, `Modules/DecorGrid.luau`, `Services/DecorService.luau`)

### 5.1 Item
- Definisi item di `Decor.list`, dikunci via `byId`. Setiap item punya `id`, `set` (kategori buku koleksi), `w` dan `d` (footprint dalam sel), `currency` (`"koin"` atau `"bunga"`), `price`, serta `parts` (placeholder bentuk).
- Opsional: `blueprint`, `unlockLevel`, `waters` (sprinkler), `event`.
- Model asli bisa ditaruh di `ReplicatedStorage > DecorModels` dengan nama sama dengan `id`. Itu menggantikan placeholder otomatis.

### 5.2 Grid hias
- **Sel = `Decor.CELL` = 2 stud.** Ukuran area: `192 / 2 = 96` sel per sisi.
- Sel `(0, 0)` berada di pojok plot-local `(-96, -96)`.
- Rotasi `r` = 0..3 (kelipatan 90 derajat). Pada rotasi ganjil, `w` dan `d` ditukar (`DecorGrid.footprint`).
- Setiap entry disimpan sebagai `{ uid, id, x, z, r }`, dengan `x`, `z` adalah sel pojok minimum.
- `entryRect` mengubah entry jadi rect dalam studs.

### 5.3 Validasi (`DecorGrid.isValid`)
1. Footprint berada di dalam `[X_MIN, X_MAX) x [Z_MIN, Z_MAX)`.
2. Footprint berada di dalam chunk yang dimiliki (`Land.rectInside`).
3. Tidak menyentuh `blocked` (daftar `BLOCKED_EXTRA`, saat ini kosong).
4. Setiap sel footprint kosong di `occupancy`, kecuali oleh item itu sendiri saat dipindah (`ignoreUid`).

`occupancy(entries, tiles, rects)` menandai sel dengan uid entry, dan sel yang terpakai petak garap atau kolam diberi `-1`. Jadi hias tidak bisa menimpa tanah garap maupun air.

### 5.4 Batas dan aksi
- Maksimum `MAX_PLACED = 150` (+ `Monetization.DECOR_BONUS` dengan game pass).
- `DecorService.onPlace` cek data stock dulu, lalu blueprint, level, event, dan harga. Item yang sudah ada di stok tidak perlu blueprint lagi.
- `onMove` cek validasi dengan `ignoreUid`, lalu update entry dan `PivotTo`.
- `onStore` (Hapus) memindahkan item kembali ke stok tanpa refund, sehingga bisa dipasang ulang gratis.
- Saat plot di-assign, `rebuild` membuang entry yang sudah tidak valid (misal sel yang kini bertabrakan dengan kolam atau petak garap) dan memasukkannya kembali ke stok.

---

## 6. Mode Garap dan Grid Visual (Client)

### 6.1 `GarapController.luau`
- Grid tipis putih di atas lahan yang dimiliki saat mode Garap atau Pindah aktif:
  - Garis tipis setiap 2 stud (transparansi 0.8).
  - Garis tebal setiap 8 stud, yaitu satu petak garap (transparansi 0.55).
- Grid hanya dibangun untuk chunk yang dimiliki. Dibangun ulang saat lahan bertambah.
- Mode Hias meminta grid yang sama lewat `GarapController.HoldGrid(true)`, jadi hanya ada satu grid.

### 6.2 `DecorController.luau` (preview hias)
- Ghost model mengikuti `cellFromLocal` (sel terdekat dari titik sentuh, dijepit ke plot).
- `state.valid` dihitung dengan `DecorGrid.isValid` memakai data occupancy dan `snapshot.landChunks`. Client dan server memakai fungsi yang sama, jadi preview sesuai aturan server.

---

## 7. Hubungan Antar Grid (Ringkas)

```
Plot (192 x 192, origin di tengah)
 ├─ Chunk 32 x 32 (6 x 6)            -> beli lahan, 16 awal + 14 bisa dibeli
 │    └─ Petak garap 8 x 8 (24 x 24)   -> tanam; kolam 2 x 2 petak (16 x 16)
 └─ Decor sel 2 x 2 (96 x 96)         -> hias; blok jika bertabrakan dengan petak/kolam
Terrain voxel 4 x 4                   -> semua di atas dicat ke sel ini
```

Karena 8, 16, 32, dan 192 semuanya kelipatan 4 dan 2, semua grid saling selaras. Itu yang membuat petak, kolam, dan hias tidak bisa saling tumpang tindih.

---

## 8. Hal yang Perlu Diperhatikan

1. **`Land.fixedRects()` kosong.** Mekanisme "rumah tetap" sudah dihapus, tetapi pengecekan `fixed` masih dipanggil di `canTill` dan `canPond`. Itu aman (loop kosong), tapi bisa dibersihkan.
3. **`BLOCKED_EXTRA` di Decor kosong.** Area tanpa bangun hanya dikelola lewat rect kolam dan petak garap.
4. **Duplikasi perhitungan rect decor.** `decorRects` ada di `FarmService`, `PondService`, dan `DecorService` (dan `rebuild`). Bisa dipindahkan ke satu helper.
5. **Kolam dan petak memakai sumber sel yang sama (`TILE`)**, jadi mengubah `Land.TILE` akan memengaruhi keduanya sekaligus.

---

## 9. Referensi File

- `src/shared/Config/Plots.luau`: layout plot, ukuran chunk, harga lahan
- `src/shared/Modules/Land.luau`: rumus chunk, petak garap, kolam, validasi garap
- `src/shared/Config/Farm.luau`: konstanta bed, jarak garap
- `src/shared/Config/Fishing.luau`: konfigurasi kolam (`POND`)
- `src/shared/Config/Decor.luau`: definisi item hias, `CELL`, `MAX_PLACED`
- `src/shared/Modules/DecorGrid.luau`: grid hias, footprint, validasi
- `src/server/Services/PlotService.luau`: assign plot, spawn, papan nama
- `src/server/Services/LandService.luau`: beli chunk
- `src/server/Services/FarmService.luau`: garap, cat soil terrain, tile part
- `src/server/Services/PondService.luau`: bangun, hapus, tampilan kolam
- `src/server/Services/DecorService.luau`: place, move, store, rebuild
- `src/server/Services/MapService.luau`: cat terrain plot, pagar, pohon di chunk
- `src/client/Controllers/GarapController.luau`: grid visual
- `src/client/Controllers/DecorController.luau`: preview hias
