# KAMPOENG TEDOEH — Peta Dokumen (baca ini dulu)

> Versi sekarang: **GDD v8.4 + Audit K-01…K-66** (diperbarui 2026-11-23). Semua dokumen di `docs/` mengacu ke versi ini.
> Game ini dibuat 100% lewat Claude Code. Dokumen ini ditulis supaya Claude Code tidak menebak. **Owner hanya playtest dan memberi masukan**; tidak ada dokumen yang menunggu jawaban owner.

## 1. Daftar File

`docs/` berisi tepat 00–09, folder `references/` (gambar konsep), dan folder `reports/` (laporan audit/tes yang sudah jadi).

| File | Isi | Siapa yang paling sering pakai |
|------|-----|-------------------------------|
| `00_README_Docs.md` | Peta dokumen, aturan, cara kerja sekarang | Semua |
| `01_GDD_Kampoeng_Tedoeh_v8.4.md` | **Sumber kebenaran gameplay**: semua angka, aturan, sistem, Skill Tree | Claude Code |
| `02_Audit_Perbaikan.md` | Temuan A-nn + **Keputusan K-01…K-66** (Bab 3) + riwayat keputusan final (Bab 4) | Claude Code |
| `03_Quest_Naskah.md` | Feature gate, rantai Main/Side Quest, semua teks dialog | Claude Code |
| `04_Asset_Bible.md` | Arah gaya, anggaran performa, daftar 3D, animasi, VFX, SFX, musik, ikon | Claude Code (jalur aset) |
| `05_GUI_Spec.md` | Aturan & layout GUI mobile-first, token UiKit, status implementasi | Claude Code |
| `06_Roadmap.md` | **Satu-satunya sumber status kerja** (kolom Status per tugas), urutan kerja, ID `R…`, `RP…`, `F…` | Owner & Claude Code |
| `07_QA_Test_Plan.md` | Cara tes otomatis & audit untuk Claude Code (lapis A–C) | Claude Code |
| `08_Penyempurnaan.md` | Penyempurnaan P-01…P-22 (prioritas Wajib/Disarankan/Nanti sudah dianggap diterima) | Claude Code |
| `09_Playtest_Checklist.md` | **Checklist testing untuk owner** + format masukan | Owner |

Laporan: `docs/reports/` (contoh: `R0.4_config_audit.md`, `Docs_Audit_2026-11-23.md`). Laporan itu snapshot pada tanggalnya; bukan sumber kebenaran.

## 2. File Lama → File Baru

| File lama | Sekarang di |
|-----------|-------------|
| `Kampoeng_Tedoeh_v7.4.md`, `v7.5.md`, `v7.6.md`, `v7.7.md` | `01_GDD` (isi terbaru), `02_Audit` Bab 4 (riwayat keputusan). Changelog lama tetap ada di git. |
| `Skill_Tree_Kampoeng_Tedoeh_v7.7.md` | `01_GDD` Bab 4.5 |
| `Quest_Kampoeng_Tedoeh_v0.3.md` + `Naskah_Dialog_Kampoeng_Tedoeh_v0.1.md` | `03_Quest_Naskah` |
| `GUI_Kampoeng_Tedoeh_v0.1.md` | `05_GUI_Spec` |
| `Roadmap.md` | `06_Roadmap` (riwayat selesai di Bab 2) |
| `Test_Plan_Kampoeng_Tedoeh_v0.1.md` | `07_QA_Test_Plan` |
| Lampiran D (v7.5–v7.7) | Yang final → `02_Audit` Bab 4; yang terbuka → `02_Audit` Bab 3 (K) |
| (baru) | `04_Asset_Bible`, `08_Penyempurnaan`, `09_Playtest_Checklist` |

## 3. Urutan Kebenaran (kalau ada beda)

1. **Kode yang sudah diputuskan owner** (tercatat di Audit Bab 4).
2. `01_GDD` — angka & aturan.
3. `03_Quest_Naskah` — urutan quest & teks.
4. `05_GUI_Spec` — tampilan.
5. `04_Asset_Bible` — aset.
6. `06_Roadmap` — urutan kerja dan status (tidak pernah jadi sumber angka).
7. `08_Penyempurnaan` — rencana tambahan; GDD menang bila beda.

Beda antara dokumen dan kode yang **belum** tercatat = temuan baru → Claude Code memutuskan sendiri (nilai konservatif), tulis sebagai K baru di Audit Bab 3, lanjut kerja.

## 4. Aturan LOCKED dari playtest (ringkas)

Detail ada di bab yang ditunjuk; kalau ringkasan ini beda dengan bab tersebut, bab itu yang menang.

- **Sorot tutorial: dua gaya, hanya pertama kali.** Tombol HUD tetap (Garap, Aksi Pancing) = satu lubang gelap; objek atau GUI mengambang = outline saja, tanpa gelap; pengulangan = toast saja. Overlay tidak pernah menelan sentuhan. → GDD 16.6, GUI 4.6.
- **Satu permukaan instruksi per langkah.** Langkah pertama (aksi pertama) = bubble coachmark saja; pengulangan / langkah berikutnya = toast saja. → GUI 4.6, GDD 16.6.
- **Tombol Aksi bulat dan satu komponen** (Pancing, Tarik, Pasang, Ambil, Panen Semua). → GUI 6.12 dan Aksi-slot.
- **Tanda "!" di atas setiap pemberi quest** yang punya quest Tersedia atau siap diserahkan. → GUI 4.5, 6.8, Quest 03.
- **Pak Udin / pemberi shop setelah tutorial**: Jual / Beli + Sampai jumpa. "Jual semua panen (N%)" hanya untuk langkah jual tutorial. → GUI 4.5, 6.8, GDD 16.

Tanda lain di tiap dokumen: lihat bagian 6.

## 5. Tanda di Dokumen

| Tanda | Arti |
|-------|------|
| LOCKED | Final. Ubah hanya lewat revisi dari playtest (Audit 3.6) + versi baru. |
| USULAN | Sudah di kode, angka belum dikunci; boleh disetel saat balancing. |
| ✔ K-xx | Sudah diputuskan (Audit 3.0). Teks di baris itu = aturan final. |
| ⚠ | Belum ada di kode (diverifikasi dengan grep di `src/`). Wajib ada ID Roadmap di sebelahnya. |
| ★ | Dibutuhkan untuk Vertical Slice Lv 1–10. |

## 6. ID (tidak pernah dipakai ulang)

| Awalan | Arti | Tempat |
|--------|------|--------|
| `A-nn` | Temuan audit | `02_Audit` Bab 2 |
| `K-nn` | Keputusan desain (sudah diputuskan; K baru = otomatis, Audit 3.6) | `02_Audit` Bab 3 |
| `P-nn` | Usulan penyempurnaan | `08_Penyempurnaan` |
| `R<fase>.<n>` | Tugas kerja | `06_Roadmap` |
| `RP1.*`, `RP2.*` | Tugas Bab 19/20; hanya menunjuk ke `R…` kanonik | `06_Roadmap` |
| `F1`…`F8` | Perbaikan dari video/HP owner 2026-11-23 | `06_Roadmap` (Bab F), `09` |
| `M<n>`, `S<n>`, `MQ11`, `MQ12`, `side_*` | Quest | `03_Quest_Naskah` |

## 7. Aturan Revisi & Cara Kerja Sekarang

- Angka berubah → versi GDD naik (v8.5, …) dan satu baris di Audit Bab 4 serta satu baris di "Riwayat revisi" GDD.
- Satu topik = satu file. Jangan buat file `v7.8`, `v0.4`, dll. di samping file ini; ubah file yang ada, riwayat ada di git.
- Tiap commit kode yang mengubah perilaku juga memperbarui dokumen terkait di commit yang sama.

**Cara kerja sekarang:**
1. Buka `06_Roadmap`, baca kolom **Status** (TODO / DONE-CODE / VERIFIED / BLOCKED).
2. Kerjakan dari atas ke bawah. Ambil tugas pertama yang belum VERIFIED dan tidak BLOCKED.
3. Update status di `06_Roadmap` dan dokumen terkait di commit yang sama.
4. Checklist untuk owner ada di `09_Playtest_Checklist`; tambahkan di sana bila tugas mengubah perilaku yang bisa dicek di HP.

## 8. Laporan

- Laporan audit dan tes disimpan di `docs/reports/`. Namanya memuat tanggal atau ID tugas.
- Laporan lama di root `docs/` sudah dipindahkan ke `reports/` dan diberi banner "snapshot, bukan sumber kebenaran".
