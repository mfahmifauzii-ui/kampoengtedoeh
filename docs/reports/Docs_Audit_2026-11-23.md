# Laporan audit dokumen — 2026-11-23

> Snapshot satu kali. Tugas: sinkronkan `docs/` dengan kode dan keputusan owner. `src/` tidak diubah.
> Branch `feat/v.7`. Satu perbaikan = satu commit `docs(<id>): ...`.

## 1. Fixed

| ID | Isi perbaikan | Commit |
|----|---------------|--------|
| D1 | README: versi GDD v8.4 + K-01…K-66; file, cara kerja, aturan LOCKED; Langkah Pertama dihapus | 9669b5b |
| D2 | Test_Report pindah ke `docs/reports/` (git mv), rujuk 07, banner snapshot | 96d455b |
| D3 | GDD: 6.6 Bubu ke nilai kode (K-66); 14.5 Agenda ada di kode; 25.2 sebagian; 16.2 langkah dari Onboarding (XP total 230, bukan 158); revisi v8.3/v8.4 dilipat ke bab; header v8.4; tabel riwayat | 5a9dc67, edf4082, a84130c, 7399fb2, 7adccd9 |
| D4 | Audit Bab 3 jadi K-01…K-66; tabel 3.0b untuk K-43…K-66 dengan tempat diterapkan | 9ff3861 |
| D5 | Naskah 03: status Bubu/Agenda; 28 quest aktif + 2 ditunda (Kucing, Joran); Bang Jali Jual/Beli; syarat permukaan quest (Bab 9) | 7548ab9 |
| D6 | GUI 05: baris COACHMARK tanpa overlay; Bab 9 dilipat ke 4.2, 4.5, 4.6, 6.2, 6.6, 6.8, 6.11, 6.12; status tabel 8; A-72 tertutup | 79baf58 |
| D7 | Roadmap 06: kolom Status + Commit; R3.8/R3.9 ganda jadi R3.10/R3.11; RP2 duplikat dihapus; Bab 17+DEV digabung; Bab 18 F1–F8; Bab 21 utang verifikasi; Risiko jadi Bab 22; R2.1b ditambahkan | 7ea8376 |
| D8 | Checklist 09: Putaran 1/2/3 berurutan; B11 = F1–F8 + tutorial no-dim; alur Bubu lengkap; backlog A ditandai | 1a114ae |
| D9 | Lintas dokumen: 9.x GUI lama diganti; K-43/44/50/51 ditandai; R12.4b → R12.4 | 5f2e0b3, 19c805d |

Koreksi dalam pekerjaan ini sendiri (sudah di commit): ID warna dinding R3.9 (bukan R3.10); deskripsi pemilihan ikan Bubu (merata per rarity, bukan bobot).

## 2. Found but needs owner or Play (not decided)

- **Besi "5% 1 Late"** (GDD lama 6.6): tidak ada di kode. Kode memilih merata dari ikan U + R. Perlu keputusan owner: pertahankan kode, atau tambah aturan 5%.
- **Bahan Bubu** (10 Bambu, 20 Kayu, 15 Batu + 10 Kayu): ditunda (K-66). Perlu keputusan owner kapan dipungut.
- **Tutorial XP 230**: hasil dari `xpFill` di `jual_ikan`. Sisa XP ikan ikut dihitung. Perlu cek di Play bahwa Lv 2 tercapai tepat di akhir.
- **Surface per langkah** (GUI 9.7 / GDD 16.2): aturan saja. Belum diverifikasi terhadap `GuideController`.
- **Teks toast quest**: kode `Misi baru: {title}`, owner minta "Quest baru: <judul>" (F5). Perlu keputusan wording.
- **Pajangan (8.6), Blueprint (8.7), buff Saung (14.6)**: ⚠ dipertahankan. Dicek dengan grep: tidak ada logika di `src/`.
- **Analytics 25.2**: hanya sebagian (funnel tutorial dan event ekonomi). Daftar lengkap R2.10 belum ada.
- **Buka Lv 8 (Bubu)**: ditulis di GDD 6.6, belum dicek di `Config/Shop` (tidak diubah).
- **Pack Bunga 700 (K-44)**: id `bunga_xl` ada di kode dengan id 0. Belum dicek apakah sudah masuk `Config/Economy` (tidak diubah).

## 3. Stale code comments (src/ tidak diubah)

- `src/shared/Config/Bubu.luau` baris 4 ("Buying a Bubu is not wired yet") dan baris 13 ("not wired yet"): salah. Pembelian sudah ada di `Config/Shop` (Pak Udin) dan `ShopService`.
- `src/client/Controllers/CoachmarkController.luau` header baris 5, 9–16, 36–40, 68: masih menjelaskan overlay dan dim, dan BLOCK_TIMEOUT. Sudah tidak berlaku (no-dim).
- `src/client/Controllers/GuideController.luau` baris 850 dan 1032: "the dim is for the first time only" / "mancing dims". Salah sejak no-dim.
- `src/shared/Config/Onboarding.luau` komentar `block = false` merujuk "docs/05 Bab 9" (sekarang pointer; aturan di 4.6).
- `src/server/Services/DataService.luau` baris 21: `DATA_STAGE = "v72"` dengan komentar "bumped for v7.3 (Bab 28)".
- Referensi "v7.3 / v7.4 Bab .." di `Config/Onboarding.luau`, `Config/Quests.luau`, `Config/Shop.luau`, `Config/Ranch.luau`, `Config/Mining.luau` (14 baris total). Nomor bab memang sama dengan GDD, tetapi versinya lama.
- `src/server/Services/FishService.luau` baris 100–101, 503: rujukan "Bab 6.3/6.4/7.2" benar. Tidak perlu diubah.
- `src/shared/Locale/id.luau` baris 98: `quest.new = "Misi baru: {title}"`. Bukan komentar, tetapi wording belum sesuai permintaan owner (lihat bagian 2).

## 4. Tidak diverifikasi

- Tidak ada Play atau Studio run. Semua status "DONE-CODE" berarti ada commit atau kode, bukan hasil Play.
- Tidak ada tugas yang berstatus VERIFIED di Roadmap.
- `selene`/`rojo` tidak dijalankan ulang karena tidak ada perubahan `src/`.
