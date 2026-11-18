# Keputusan: pegunungan belakang (back range)

**Tanggal:** 18 Nov 2026
**Status:** kode sudah diubah dan lolos parse (StyLua). **Belum dites di Studio.** Perlu Rojo sync, lalu cek di Play.

---

## Permintaan

- Backup map yang sekarang di dalam kode.
- Generate ulang **hanya** pegunungan bagian belakang, dengan gaya pegunungan dari referensi yang dikirim (low-poly, saturasi tinggi, puncak bersalju).

## Keputusan

1. **"Belakang" = baris ketiga (tall back range), di keempat sisi peta.**
   Generator `buildMountains` punya tiga baris ridge: kaki bukit, pegunungan, dan baris belakang. Yang diganti hanya baris ketiga. Tidak ada keputusan lain soal sisi. Kalau yang dimaksud hanya satu sisi (misalnya sisi utara), bilang saja dan saya persempit.
2. **Dua baris depan tidak berubah.** Kaki bukit dan pegunungan tengah tetap sama, termasuk bentuk dan seed-nya. Baris belakang sekarang pakai seed sendiri (`7741`), jadi urutan random baris depan tidak bergeser.
3. **Jarak baris belakang tetap** (`INNER + 230`, sama seperti sebelumnya). Hutan, dinding, dan sudut pandang kamera tidak ikut bergeser.
4. **Gaya baru: tiga lapisan per puncak.**
   - Dasar hijau (`LeafyGrass`) di seluruh lereng.
   - Batu (`Rock`) dari 50% tinggi puncak ke atas.
   - Salju (`Snow`) dari 78% tinggi ke puncak.
   Lereng dibuat curam (`halfBase = tinggi × 0.8–1.0`) supaya puncaknya tajam dan bersudut seperti referensi.
5. **Puncak dipadatkan.** Jarak antar puncak lebih rapat (spasi 190 × 0.55–1.0), dan 60% puncak punya ridge silang yang lebih tinggi. Hasilnya satu punggungan yang bergerigi, tidak bukit-bukit terpisah.
6. **Warna salju di-set di `buildTerrain`:** `RGB(236, 242, 248)`, sedikit abu-abu supaya tidak putih polos (sama seperti pertimbangan warna batu sebelumnya).

## Yang sengaja TIDAK diubah

- **Kabut dan pencahayaan** (`src/shared/Config/World.luau`, `atmosphereDensity = 0.3`). Kabut masih menutupi pegunungan jauh, jadi di game bisa terasa lebih pudar daripada referensi. Kalau mau lebih cerah, itu keputusan terpisah: turunkan kabut atau ubah warna langit.
- **Dinding, margin, dan ukuran peta** (`Config/Map.luau`). Tidak disentuh.
- **Tidak ada commit git.** Perubahan masih di working tree.

## Backup

Isi `_backup/map_2026-11-18/`:

- `MapService.luau`: versi sebelum perubahan.
- `Map.luau`: config peta.
- `COMMIT.txt`: hash commit saat backup dibuat.

Untuk kembali: salin dua file itu kembali ke `src/server/Services/` dan `src/shared/Config/`. Folder `_backup/` belum di-ignore git.

## Verifikasi

| Cek | Hasil |
|---|---|
| StyLua parse (exit 0) | Lolos, sintaks valid |
| Selene | **Panic** di lexer full_moon. File asli juga panic (pre-existing), jadi bukan dari perubahan ini |
| Format StyLua (`--check`) | Beda di file asli dan baru (format repo tidak mengikuti StyLua). Bukan gerbang |
| Test di Studio (18 Nov, sesi Play) | **Lolos.** `mountains built in 2.32s` (target < 3 detik). Visual: puncak bersalju bergerigi di baris belakang, batu di tengah lereng, baris depan tidak berubah |

**Catatan tes:** place tersimpan punya `Workspace.Map` (baked), jadi `MapService` tidak generate ulang saat Play. Tes dilakukan dengan menghapus `Workspace.Map` dan terrain di server **hanya di sesi Play**, lalu memanggil `MapService.Init()`. Setelah Stop, place kembali seperti semula (`Map` masih 7 anak). Lapisan hijau di lereng bawah tertutup baris kaki bukit dari sudut pandang foto, jadi belum terlihat jelas.

## Yang perlu dicek di Studio

- Waktu build pegunungan. Baris belakang sekarang lebih padat, jadi mungkin lebih lama dari ~1 detik sebelumnya. Target: tetap di bawah ~3 detik.
- Puncak tidak menembus dinding atau masuk ke hutan.
- Warna salju dan batu terbaca di kabut.

## Terkait

- [[Map_Plan]] (peta cincin, bagian pegunungan di luar dinding)
- Generator: `src/server/Services/MapService.luau` → `backRange`, `buildMountains`, `buildTerrain`
