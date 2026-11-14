# Live-Ops — cara operasi setelah rilis

Tanpa kalender dan tanpa rencana event. Pekerjaan solo, jadi ritme sengaja ringan.
**Aturan: setiap update dirilis dengan tenang.** Tidak ada hitung mundur, tidak ada "kesempatan terakhir", dan tidak ada tekanan streak.

---

## 1. Ritme mingguan

| Kapan | Kerja |
|---|---|
| Awal minggu | **Tinjau metrik** (§4): tulis 3 baris di `docs/liveops_log.md`: apa yang berubah, kenapa, rencana. Baca komentar grup, tandai bug. |
| Tengah minggu | Satu item konten atau perbaikan (config, model, UI). |
| Akhir minggu | Tes di Studio (2+ pemain), `Monetization_Review.md` bila ada yang dijual, lalu rilis. |
| Cadangan | Perbaikan darurat atau istirahat. |

**Hari rilis:** sore WIB sebelum akhir pekan, jangan tepat sebelum kamu tidak bisa dihubungi.
**Aturan hotfix:** bug data atau pembelian diperbaiki hari itu juga; sisanya menunggu jadwal rilis.
Batas jam kerja per minggu adalah batas atas, bukan target. Kalau satu minggu hilang, rencana geser.

---

## 2. Arah konten

Urutan bukan komitmen; datanya yang menentukan (lihat `Roadmap.md` bagian "Setelah playtest").
Kandidat: mode foto, tujuan bersama kampung, peternakan (ayam dulu), warung pemain + masak, set hiasan baru, tanaman/ikan baru, rumah Tahap A/B.
Event musiman **tidak** direncanakan sekarang. Kerangka `Config/Events` tetap di kode dan tidak dipakai.

---

## 3. Pipeline konten (yang cukup config)

| Tambah | File | Kode? |
|---|---|---|
| Hiasan / set | `Config/Decor.luau` + locale `decor.<id>` (+ model di `ReplicatedStorage/DecorModels`) | tidak. Set baru masuk Buku hanya bila `set`-nya ditambahkan ke filter di `Config/Book.luau` |
| Tanaman / ikan | `Config/Crops` atau `Config/Fish` + locale | tidak (pesanan, Buku, dan unlock otomatis ikut) |
| NPC pesanan | `Config/Orders.NPCS` + locale | tidak |
| Hadiah level | `Progression.LEVEL_MILESTONES` | tidak |
| Blueprint | `Config/Blueprints` | tidak |
| Loop baru (ternak, masak) | service + remote + field data | **ya**: field data baru ke template; perubahan struktur butuh migrasi |

**Sebelum tiap rilis:**
- `py -3 tools/balance_sim.py` bila harga, XP, atau kuota berubah.
- `docs/Monetization_Review.md` bila ada yang dijual.
- Perubahan template data: hanya tambahan, atau tambah migrasi + bump `version` + uji dengan save lama.

---

## 4. Metrik mingguan (Creator Dashboard)

| Metrik | Sehat | Bila di bawah |
|---|---|---|
| Funnel 1→4 (tanam → jual) | ≥ 75% | Cek langkah yang putus; perbaiki teks tujuan atau petunjuk pertama |
| Funnel 4→7 (tangkap → pesanan → hias) | ≥ 40% | Permudah pesanan pertama; beri satu hiasan gratis di pesanan pertama |
| Retensi D1 | ≥ 25% | Pengait hari ke-2: hadiah kunjungan lebih terasa, tanaman siap "besok pagi" |
| Retensi D7 | ≥ 8% | Pesanan mingguan lebih terlihat; tambah tujuan menengah |
| Rata-rata sesi | ≥ 15 menit | Tanaman awal lebih pendek; ikan lebih beragam |
| Sink / sumber Koin | ≥ 40% | Percepat sink berikutnya (warung pemain + masak, set hiasan, kapasitas warung) |
| Bunga gratis / hari | 1–3 | <1: +1 Bunga bila ketiga pesanan harian selesai |
| Konversi pembayar | 0,5–2% | Rendah: cek harga tampil dan Toko mudah ditemukan. **Jangan pernah** tambah popup |
| Error Report | 0 error data/pembelian baru | Hotfix hari itu |

Bandingkan **minggu ke minggu**, bukan dengan game lain. Satu minggu buruk tidak berarti; bertindaklah pada tren 3 minggu.

---

## 5. Monetisasi

- Hiasan terbatas: utamanya **Koin**, paling banyak 1–2 item Bunga. Tidak pernah hanya-Robux, tidak pernah acak.
- Pass baru hanya untuk kenyamanan yang sudah adil tanpa pass. Kandidat: Auto-Collect, VIP Warung.
- Harga: turun boleh; **jangan naikkan** harga sesuatu yang sudah dianggap normal oleh pemain.
- Jalankan `Monetization_Review.md` tiap update yang menjual sesuatu.

---

## 6. Komunitas (ringan)

- **Grup Roblox "Kampung Teduh":** catatan update (2–3 baris), laporan bug di wall.
- Deskripsi game: satu baris "Update terbaru" di paling atas.
- Bahasa untuk pemain 16+: ramah, singkat, Indonesia dulu.
- Jangan janji tanggal yang mungkin meleset; tulis "segera" sampai update sudah dites di Studio.

---

## 7. Risiko

1. **Burnout solo:** ritme adalah batas atas; hari yang hilang tidak dikejar.
2. **Data:** perubahan skema setelah rilis = migrasi + uji dengan save nyata (salin satu dari store playtest).
3. **Perubahan kebijakan Roblox** (rating, monetisasi): cek pengumuman DevForum tiap bulan.
4. **Inflasi Koin:** bila sink baru terlambat, tambah sink sementara (set hiasan mahal, upgrade Kapasitas Warung) supaya pemain akhir tetap punya tujuan.
