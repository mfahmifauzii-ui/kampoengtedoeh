# Map — desa cincin (8–10 pemain)

**Status:** rencana v4. Peta yang ada di kode masih **v3: desa bentuk X untuk 4 pemain** (lihat bagian "Kondisi sekarang"). Perubahan ke v4 dikerjakan di `Roadmap.md` tahap R2. Semua angka v4 adalah *asumsi* sampai dites di Studio.

---

## 1. Rencana v4: desa cincin

**Tujuan:** 8–10 slot lahan identik, tertata rapi, tidak terasa kosong walau server belum penuh.

```
                  [Lahan 1] [Lahan 2] [Lahan 3]
              [Lahan 10]   ╭──────────────╮   [Lahan 4]
        sungai ═══════════ │ PLAZA + KOTA │ ═══════════ sungai
              [Lahan 9]    ╰──────────────╯    [Lahan 5]
                  [Lahan 8] [Lahan 7] [Lahan 6]
                        (jalan cincin mengelilingi plaza)
```

- **Pusat:** plaza dan kota (jembatan, warung, toko NPC, dermaga). Sungai tetap melintasi pusat.
- **Jalan cincin** mengelilingi pusat; lahan tersusun di luar cincin dan **semua menghadap jalan**. Tiap slot identik, jadi tidak ada yang untung atau rugi posisi.
- **Ukuran lahan:** maksimal 96×96, dibeli per chunk 16×16 mulai 3×3 (lihat `00_Design_Doc.md` §4). Peta mereservasi area maksimum tiap slot.
- **Ukuran peta:** perkiraan 500–600 stud persegi (10 lahan × 96 stud butuh keliling ±1.000 di radius depan lahan ≥ ±160, lalu 96 stud kedalaman). **Lebih kecil dari v3 (720)** karena lahan dikecilkan. Hitung ulang saat membangun.
- **Sungai membelah cincin:** pilihan terbuka: (a) dua jembatan kecil di titik jalan cincin memotong sungai, atau (b) lahan dibagi 5 di tiap sisi sungai. Putuskan saat R2.
- **Slot kosong:** ditampilkan sebagai padang rumput dengan papan "Lahan kosong", bukan hilang. Server setengah penuh tetap terlihat hidup.
- **Dermaga:** tetap 12 dermaga (6 Sungai, 6 Empang) di dua lengan sungai; jumlah bisa disesuaikan dengan jumlah pemain.

### Pindah server dan slot
- Tiap server adalah dunia terpisah; **posisi karakter tidak ikut**. Yang ikut adalah **data lahan** (di DataStore, lewat ProfileStore).
- Data menyimpan `plotSlot` terakhir. Saat masuk, server mencoba menempatkan pemain di slot yang sama; kalau sudah terisi, ke slot kosong pertama. Lahan dibangun ulang dari data (tanah, tanaman, hiasan, kolam, chunk), jadi isinya selalu sama walau slotnya berbeda.
- Tidak ada Mampir lintas-server (tidak direncanakan sekarang).

### Syarat teknis R2
- `Config/Map`, `Config/Plots`, `MapService`, `PlotService`, `Modules/Land` ditulis ulang untuk N slot (konfigurasi, bukan angka mati 4).
- Lahan dari chunk: bentuk kotak, bukan baji. `Land` dan batas validasi garap, hias, dan kolam memakai daftar chunk milik pemain.
- Streaming dan jumlah Part dicek di HP asli (10 lahan sekaligus).
- `Max Players` di Game Settings diubah sesuai jumlah slot.

---

## 2. Kondisi sekarang (v3, di kode)

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
