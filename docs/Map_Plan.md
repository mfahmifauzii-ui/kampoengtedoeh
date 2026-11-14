# Map — peta cincin (8 lahan identik)

**Status:** R2 (peta cincin) dan **R2b (beli chunk)** **selesai dan dites di Studio (14 Nov 2026)**. Peta ini mengikuti konsep gambar di `references/` (3 gambar buatan Gemini/Meta).

Screenshot: [tampak atas](screenshots/R2_ring_map_topdown.jpg) · [pulau kota](screenshots/R2_town_island.jpg) · [lahan + hutan perluasan](screenshots/R2_plot_with_forest.jpg)

---

## 1. Layout

```
        ┌──────── jalan utara ────────┐
        │  [N-kiri]    │    [N-kanan] │
   hutan│              │              │hutan
        │──────────────┼──────────────│
 [W-atas]  ╭─── cincin jalan batu ───╮  [E-atas]
 ──────────│ kanal ─ pulau kota ─ …  │──────────
 [W-bawah] ╰─────────────────────────╯  [E-bawah]
        │──────────────┼──────────────│
        │  [S-kiri]    │    [S-kanan] │
        └──────── jalan selatan ──────┘
```

- **Pusat:** pulau kota bundar (radius 90) dengan pohon beringin besar, warung Pak Darmo di sisi selatan pohon, dan **8 ruko** melingkar (6 dipakai NPC/hiasan lama, 2 hiasan: Warung Jamu, Toko Kelontong). Pulau dikelilingi **kanal bundar** (radius 90–130, lebar 40) dengan **4 jembatan kayu** di utara, selatan, timur, dan barat.
- **Cincin jalan batu** mengelilingi kanal (radius 130–165). Dari tiap jembatan, **jalan tanah 24 stud** lurus ke tepi peta (4 jalan silang: N, S, E, W), berlampu.
- **8 lahan**, 2 di tiap jalan, satu di kiri dan satu di kanan jalan, **semuanya menghadap jalan**. Urutan nomor (spread keliling): Plot1 selatan-kiri, Plot2 utara-kanan, Plot3 timur-atas, Plot4 barat-bawah, lalu Plot5–8 sisanya.
- **Empat pojok** peta (antara dua jalan) berupa hutan lebat (teras sawah bisa menyusul).
- **Dermaga:** 16 dermaga di kedua tepi kanal (sisi cincin jalan dan sisi pulau). Setengah barat kanal = **Sungai** (Lv 1), setengah timur = **Empang** (Lv 4).
- **Peta 792 × 792**, dinding tak terlihat di tepi, pegunungan dan hutan di luar. Air bunyi dari 8 titik di kanal.

### Kenapa adil
Delapan lahan sama bentuk, sama ukuran, dan setara lewat rotasi + cermin: jarak ke kota, jarak ke air, dan arah semuanya sama. Tidak ada lahan "dekat sungai" atau "di ujung". Itu yang tidak bisa dicapai di peta X sebelumnya (3/3/2/2 lahan, sungai miring lewat dekat sebagian saja).

---

## 2. Lahan: awal 128, cadangan 192

Setiap lahan punya **kotak cadangan 192 × 192** miliknya sendiri. Pemain mulai dengan **lahan 128 × 128** di dalamnya, **menempel ke jalan**; sisanya (belakang dan samping) dibeli chunk demi chunk (✅ R2b) sampai 192 × 192. Karena tiap pemain punya kotak cadangan yang sama, awal dan akhir lahan **sama persis** untuk semua pemain.

```
 plot-lokal (+Z = ke arah jalan, +X = kanan, titik 0 = pusat kotak cadangan)
 kotak cadangan : x, z  -96 .. 96   (192 × 192)
 lahan awal     : x -64 .. 64, z -32 .. 96   (128 × 128, menempel ke jalan di z = 96)
 area perluasan : 192² − 128² = 20.480 stud² (belakang 64, samping 32 di tiap sisi)
```

- **Area perluasan diisi hutan** (pohon, semak, batu di atas lantai rumput hijau tua), jadi tidak terlihat kosong. Tiap model hutan diberi atribut `ExpansionOf = <nomor plot>` supaya `MapService` bisa menyembunyikannya (dipindah ke `ServerStorage > ForestHidden`) saat chunk itu dibeli, dan mengembalikannya saat lahan dikembalikan ke lahan awal.
- Lahan awal tampak terang (rumput cerah, berpagar bambu) dan jelas berbeda dari hutan di sekitarnya.
- **Rumah panggung** berada di plot-lokal (30, 56), di dalam lahan awal. Titik muncul pemain (0, 4, 70).
- Semua koordinat kelipatan 4 (sel Terrain), lahan sejajar sumbu (yaw kelipatan 90°) supaya cat tanah garap tetap rapi.

### Pindah server dan slot
- Tiap server dunia terpisah; **posisi karakter tidak ikut**, data lahan ikut (ProfileStore). Saat masuk, pemain dapat slot kosong pertama menurut urutan di atas dan lahannya dibangun ulang dari data.
- ✅ (R2b) `plotSlot` terakhir disimpan di data dan dicoba dipakai lagi; kalau sudah terisi, slot kosong pertama.

---

## 3. Angka dan konfigurasi

| Apa | Nilai | Di mana |
|---|---|---|
| Ukuran peta | 792 × 792 | `Config/Map` `SIZE` |
| Pulau / kanal / cincin jalan | radius 90 / 130 / 165 | `Config/Map` `TOWN` |
| Jalan silang | lebar 24 (`ROAD.HALF` = 12) | `Config/Map` |
| Kotak cadangan / lahan awal | 192 / 128 | `Config/Plots` `SIZE`, `START_SIZE` |
| Pusat lahan dari tengah | (±108, ±300) dan (±300, ±108) | `Config/Plots` `LAYOUT` |
| Lahan (batas validasi) | `Modules/Land` | x ±64, z −32..96 |
| Max Players | **8** | Game Settings, sama dengan `Plots.COUNT` |

Posisi toko dan NPC dihitung dari `Config/Map` `SHOPS` (8 slot, sudut 22,5° + 45° × k, radius 56); NPC berdiri di radius 44 menghadap pusat.

---

## 4. Yang berubah di kode

- `Config/Map`, `Config/Plots`, `Modules/Land`: ditulis ulang untuk peta cincin dan lahan 128 dalam kotak 192.
- `MapService`: kanal/cincin dengan Terrain (`FillCylinder`), jalan, jembatan, pulau kota (beringin prosedural), dermaga, lantai hutan dan hutan perluasan, semak/batu tepi kanal. `MapService.TownCFrame` menggantikan `BridgeCFrame`.
- `Config/Npcs` + `NpcService`: posisi NPC (`stand` = x, z, yaw) mengikuti slot ruko.
- **Migrasi data v9 → v10:** petak, kolam, dan hiasan digeser 32 stud di sumbu z (dan 24 sel x untuk hiasan) supaya tetap di tempatnya pada kerangka koordinat baru. Dites dengan save buatan.
- Beberapa tes memakai kerangka lama: `docs/_archive/` menyimpan dokumen peta X.

---

## 5. Daftar uji (Studio → Play)

1. Spawn di pulau kota (selatan warung), lalu dipindah ke lahan sendiri (Plot1, selatan-kiri), menghadap jalan.
2. Jalan melintasi jembatan dan cincin jalan ke jalan silang dan ke lahan sendiri.
3. Ngobrol dengan tiap NPC; jauh (>25 stud) ditolak server.
4. **Garap:** semua sudut lahan 128 bisa digarap; di luar batas dan di atas rumah ditolak.
5. Dermaga di kanal: Sungai di sisi barat, Empang di sisi timur; mancing jalan.
6. Malam (`!time malam`): lampu jalan, cincin, dan pulau menyala.
7. **Test → 2–8 pemain:** tiap pemain dapat lahan beda; Mampir dan Suka antar lahan.

**Teruji (14 Nov 2026, 1 pemain):** server start tanpa error; 8 Plot; geometri; semua ruko, jembatan, kanal, dermaga, pohon beringin terbentuk; garap di dalam/di sudut/di luar batas; NPC jual-beli di posisi baru, penolakan jarak, arah hadap NPC; migrasi v9 → v10; tangkapan layar tampak atas, pulau kota, lahan.
**Belum teruji:** 2+ pemain, HP asli dan performa (3.590 model alam + 728 bagian pagar), memancing dari dermaga baru, Mampir/Suka, malam hari, dan save v9 asli.

### Catatan jujur
- **Performa:** hutan perluasan dan pojok menambah banyak model (±3.600 objek alam). Streaming sudah aktif, tapi perlu dicek di HP asli; kalau berat, kurangi kerapatan di `buildNature`.
- **Ruko dan rumah** masih placeholder kotak; model ForgeGUI (`assets/models`) dipakai otomatis kalau sudah diimpor ke `ServerStorage > MapModels`.
- Lapangan pasir di antara cincin jalan dan lahan masih polos; itu ruang untuk taman publik, bangku, atau pasar nanti.
- Teras sawah di pojok (seperti di konsep) belum dibuat; sekarang pojok berupa hutan.

---

## 6. Model ForgeGUI (sudah dibuat)

File di `assets/models/` (±4,5 ribu segitiga, 1 mesh, tekstur PBR): `Warung.glb` (tinggi 11), `TokoKota.glb` (8 ruko, tinggi 14), `RumahPanggung.glb` (rumah tiap lahan, tinggi 13), plus model tanaman di `assets/models/crops/`.

**Impor (sekali, di Studio):**
1. Asset Manager → Bulk Import → Import 3D, pilih file `.glb`.
2. Di **ServerStorage** buat Folder `MapModels`; pindahkan hasil impor dan beri nama persis **`Warung`**, **`TokoKota`**, **`RumahPanggung`**.
3. Tekan Play; placeholder diganti otomatis (skala ke tinggi di atas).
4. Salah arah? Tambah atribut angka **`FrontYaw`** (90 / 180 / 270) pada model di `MapModels`.

## 7. Fakta Terrain (diukur di Studio, tertanam di `Modules/Land` dan `MapService`)

- Permukaan Terrain terlihat **2 stud di atas** puncak blok terisi; `MapService` menurunkan tiap blok 2 stud agar tanah di **y = 0**. Air: permukaan tepat di puncak blok.
- Sel Terrain **4 stud**, tepi di kelipatan 4. Blok mengecat material sel bila **pusat sel** ada di dalam blok, jadi blok cat 0,5 lebih kecil dari sel yang diisi.
- "Bed" tipis di atas tanah tidak terlihat; mengecat ulang material sel atas yang terlihat, jadi tanah garap adalah cat rata.
- `Terrain:FillCylinder` dipakai untuk kanal, pulau, dan cincin jalan; hasilnya bundar tapi bertangga per sel 4 stud.
- Tekstur "CobbleStylized" terlalu gelap untuk cincin jalan, jadi jalan batu memakai Cobblestone polos berwarna abu-abu.
- Outline kuning di sekitar lahan adalah seleksi Studio, bukan kode game.
