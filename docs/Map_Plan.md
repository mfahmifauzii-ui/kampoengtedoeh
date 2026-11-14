# Map — cincin persegi (10 pemain)

**Status:** **R2a selesai dan dites di Studio (14 Nov 2026).** Peta di kode sekarang adalah v4 di bawah. Lahan masih **persegi 96×96 penuh**; pembelian chunk (mulai 3×3) menyusul di R2b. Bagian "Kondisi sebelum R2a" di bawah hanya catatan sejarah.

Screenshot: [tampak atas](screenshots/R2a_map_topdown.jpg) · [deretan lahan selatan](screenshots/R2a_south_row_of_plots.jpg) · [kota, jembatan, sungai](screenshots/R2a_town_bridge_river.jpg)

---

## 1. Peta sekarang (v4, R2a)

```
                [N1 mid] [N2 kiri] [N3 kanan]          (utara: 3 lahan)
       sungai \                                  / jalan
              \                                 /
   [W: 2 lahan]        KOTA + JEMBATAN        [E: 2 lahan]
              /                                 \
       jalan /                                   \ sungai
                [S1 mid] [S2 kiri] [S3 kanan]          (selatan: 3 lahan)
```

- **Bentuknya cincin persegi, bukan lingkaran.** Alasan teknis: tanah garap dicat per sel Terrain 4 stud, dan itu hanya rapi kalau lahan sejajar sumbu (yaw kelipatan 90°). Lahan di sudut sembarang akan merusak penyelarasan itu, jadi lahan berderet di empat sisi peta, semuanya menghadap kota.
- **Pusat:** kota di atas jembatan (6 ruko, warung, NPC) tidak diubah. Sungai NW→SE dan jalan SW→NE tetap menyilang dan membagi cincin jadi empat sektor. Pertanyaan "dua jembatan atau 5 + 5" **tidak perlu**: lahan sudah tersusun di dalam sektor, tidak ada yang tersilang sungai.
- **10 slot:** selatan 3, utara 3, barat 2, timur 2. Jumlah per sisi diatur di `SIDES` pada `Config/Plots`; kalau mau 8 pemain, ubah jadi 2 per sisi (peta tetap jalan). Atur juga **Max Players** di Game Settings sama dengan jumlah slot (10).
- **Ukuran lahan:** 96×96, pusat 240 dari tengah peta, jarak antar-pusat 104 (celah 8 stud). Semua koordinat kelipatan 4. Sudut lahan paling dekat 28,28 stud dari sumbu sungai/jalan (diverifikasi dengan skrip).
- **Ukuran peta:** **608 × 608** (sebelumnya 720). Lahan berakhir 16 stud di dalam dinding.
- **Urutan slot:** pemain pertama di selatan-tengah (Plot1), berikutnya utara-tengah, barat, timur, lalu lahan samping, jadi server yang belum penuh tersebar rata.
- **Slot kosong:** tampil sebagai lahan rumput dengan papan **"Lahan kosong"**, rumah tetap ada. Server setengah penuh tetap terlihat hidup.
- **Dermaga:** 10 dermaga (5 Sungai di lengan NW, 5 Empang di lengan SE), di kedua tepi sungai; posisinya digeser masuk karena peta mengecil.
- **Catatan jujur dari screenshot:** bagian tengah antara kota dan lahan adalah pasir kosong yang luas. Peta terasa lapang; isi (pohon, bangku, taman publik) itu pekerjaan seni/UI-mu atau tahap konten nanti.

### Pindah server dan slot
- Tiap server adalah dunia terpisah; **posisi karakter tidak ikut**. Yang ikut adalah **data lahan** (di DataStore, lewat ProfileStore).
- 🗓 (R2b) Data akan menyimpan `plotSlot` terakhir. Saat masuk, server mencoba menempatkan pemain di slot yang sama; kalau sudah terisi, ke slot kosong pertama. **Sekarang** (R2a) pemain selalu dapat slot kosong pertama menurut urutan di atas. Lahan dibangun ulang dari data, jadi isinya sama walau slotnya berbeda.
- Tidak ada Mampir lintas-server (tidak direncanakan sekarang).

### Yang berubah di kode (R2a)
- `Config/Plots`: `LAYOUT` dihasilkan dari `SIDES` (posisi dunia langsung); `COUNT` otomatis. `Config/Map`: `SIZE` 608, `LAND` dihapus, dermaga digeser.
- `Modules/Land`: baji diganti persegi 96×96 dengan API yang sama (`contains`, `rectInside`, `canTill`, `canPond`...), jadi garap, hias, kolam, dan sosial tetap jalan tanpa diubah.
- `MapService`: cat tanah, pagar, semak, dan penempatan lahan dibuat ulang untuk persegi; lampu jalan hanya di dalam dinding. `PlotService`: label "Lahan kosong".
- **Migrasi data v8 → v9:** petak garap dan kolam di luar lahan 96×96 baru dibuang (kolam dikembalikan 50% harganya); hiasan di luar lahan dikembalikan ke stok saat masuk. Dites dengan save buatan.

### Teruji di Studio (R2a, 1 pemain)
Server start tanpa error; 10 Plot terbentuk; pemain masuk Plot1; label kosong/terisi benar; geometri (tanpa tumpang tindih, di dalam dinding, ≥ 28 stud dari sumbu); garap diterima di dalam dan di sudut lahan, ditolak di luar batas dan di atas rumah; validasi hias benar di semua sudut dan di luar batas; migrasi v8 → v9 benar.
**Belum teruji:** 2+ pemain sekaligus (penugasan slot dan Mampir antar lahan), HP asli dan performa 10 lahan terisi, memancing dari dermaga baru, dan save v8 asli dari DataStore dengan petak di luar batas.

---

## 2. Kondisi sebelum R2a (v3, hanya sejarah)

Dibangun oleh `MapService` dari `Config/Map` + `Config/Plots` tiap server mulai. Studio → **Play** (tampilan edit kosong).

| Bagian | Cara | Ukuran |
|---|---|---|
| Area bermain | persegi, dinding tak terlihat, pohon di luar | **720 × 720** stud |
| Tanah + sungai | **Terrain**: slab rumput datar, sungai NW→SE (bisa direnangi, 1 stud di bawah tepi) | sungai lebar 48, dalam 8 |
| Jalan | aspal SW→NE, garis putus-putus, lampu menyala malam | lebar 28 |
| Jembatan | dek papan di atas sungai, 2 pangkal batu + 2 tiang, ramp, pagar | 72 × 64, dek 5 stud |
| Kota | 6 ruko dengan papan (4 di sisi +Z, 2 di −Z) + **Warung** di tengah sisi −Z | di atas dek |
| NPC | `Workspace.Npcs` (`NpcService`, posisi di `Config/Npcs`): Pak Darmo (Warung), Bu Wati (Toko Bibit), Mas Joko (Toko Pancing), Mbok Minah (Pasar Ikan), Bang Tarno (Lapak Tarno), Mbak Arsi (blueprint). Satu prompt "Ngobrol" → dialog → toko | – |
| Memancing | 12 dermaga; **lengan NW → `sungai`** (6), **lengan SE → `empang`** (6) | – |
| Lahan pemain | 4 **baji hijau** (1 = S, 2 = W, 3 = N, 4 = E), ≥ 28 stud dari sumbu sungai dan jalan, dipagari bambu rendah, masing-masing punya **rumah panggung** | sekitar 228 dalam × hingga ~600 lebar |
| Tanah garap | **Terrain** (bukan Part): petak 8×8 dicat rata | – |
| Spawn | `TownSpawn` di jembatan; `PlotService` memindahkan pemain ke lahannya | – |

Lahan v3 jauh lebih besar dari 96×96 yang direncanakan awal; itu yang diperbaiki di v4.

### Model dari ForgeGUI
File di `assets/models/` (±4,5 ribu segitiga, 1 mesh, tekstur PBR): `Warung.glb` (tinggi 11), `TokoKota.glb` (6 ruko, tinggi 14), `RumahPanggung.glb` (rumah tiap lahan, tinggi 13). Plus model tanaman di `assets/models/crops/`.

**Impor (sekali, di Studio):**
1. Asset Manager → Bulk Import → Import 3D, pilih file `.glb`.
2. Di **ServerStorage** buat Folder `MapModels`; pindahkan hasil impor dan beri nama persis **`Warung`**, **`TokoKota`**, **`RumahPanggung`**.
3. Tekan Play; placeholder diganti otomatis (skala ke tinggi di atas).
4. Salah arah? Tambah atribut angka **`FrontYaw`** (90 / 180 / 270) pada model di `MapModels`.

### Fakta Terrain (diukur di Studio, tertanam di `Modules/Land` dan `MapService`)
- Permukaan Terrain terlihat **2 stud di atas** puncak blok terisi; `MapService` menurunkan tiap blok 2 stud agar tanah di **y = 0**. Air: permukaan tepat di puncak blok.
- Sel Terrain **4 stud**, tepi di kelipatan 4. Blok mengecat material sel bila **pusat sel** ada di dalam blok, jadi blok cat 0,5 lebih kecil dari sel yang diisi.
- "Bed" tipis di atas tanah tidak terlihat; mengecat ulang material sel atas yang terlihat, jadi tanah garap adalah cat rata.
- Outline kuning di sekitar lahan adalah seleksi Studio, bukan kode game.

### Daftar uji (Studio → Play)
0. **Garap:** tekan Garap → arahkan mouse ke lahan hijau: kotak hijau mengikuti grid (merah = tidak boleh: di atas rumah, kolam, hiasan, di luar hijau). Ketuk → petak jadi tanah. Ratakan mengembalikan petak kosong. Ketuk tanah → pilih bibit → tanam → siram → panen. Rejoin: tanah dan tanaman tetap.
1. Spawn di jembatan, lalu dipindahkan ke lahan sendiri.
2. Jalan ke jembatan: ramp mulus, tanpa celah.
3. Ngobrol dengan tiap NPC: dialog 2 pilihan; jauh dari NPC dagang ditolak server (>25 stud).
4. Dermaga NW → Mancing; dermaga SE (Empang, Lv 4) → ikan empang.
5. Lompat ke sungai: berenang dan bisa naik; tidak bisa keluar peta.
6. Malam (`!time malam`): lampu jalan, jembatan, dan lentera Warung menyala.
7. **Test → 2–4 pemain (kelak 8–10):** tiap pemain dapat lahan beda; Mampir dan Suka jalan antar lahan.

**Teruji (Play, 14 Nov 2026):** lahan hijau di keempat plot, tanah publik pasir, jalan menyambung, sungai y = −1 dan tepi 0, preview Garap, tilling, tanam, siram (tanah jadi Mud), panen, hiasan ditolak di atas tanah dan diterima di rumput bebas, stop/start menjaga semua petak. **Belum teruji:** 2+ pemain, sentuhan HP, panel NPC Warung, memancing dari dermaga baru.

### Knob (di `Config/Map` / `Config/Plots`)
Lebar/kedalaman sungai, lebar jalan, ukuran jembatan, posisi dermaga (`RIVER_DOCKS`), posisi rumah (`HOUSE`), bentuk lahan (`LAND.SETBACK`, `LAND.BACK_DISTANCE`), jangkar lahan (`Plots.DISTANCE`, `Plots.FRONT_Z`). `DISTANCE`, `FRONT_Z`, dan `DISTANCE − BACK_DISTANCE` harus kelipatan 4 (sel Terrain). Seluruhnya akan diganti di R2.
