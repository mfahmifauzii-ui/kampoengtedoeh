# KAMPOENG TEDOEH — Peta Dokumen (baca ini dulu)

> Set dokumen v8.1, dibuat 2026-11-23 (semua keputusan K-01…K-42 sudah diputuskan). Menggantikan 10 file lama di `docs/`.
> Game ini dibuat 100% lewat Claude Code. Dokumen ini ditulis supaya Claude Code tidak menebak. **Owner hanya playtest dan memberi masukan**; tidak ada dokumen yang menunggu jawaban owner.

## 1. Daftar File

| File | Isi | Siapa yang paling sering pakai |
|------|-----|-------------------------------|
| `00_README_Docs.md` | Peta dokumen, aturan, cara pakai | Semua |
| `01_GDD_Kampoeng_Tedoeh_v8.2.md` | **Sumber kebenaran gameplay**: semua angka, aturan, sistem, Skill Tree | Claude Code |
| `02_Audit_Perbaikan.md` | 83 temuan kontradiksi/gap + **Keputusan K-01…K-42 (semua DIPUTUSKAN)** + riwayat keputusan final | Claude Code |
| `03_Quest_Naskah.md` | Feature gate, rantai Main/Side Quest, semua teks dialog | Claude Code |
| `04_Asset_Bible.md` | Arah gaya, anggaran performa, daftar 3D, animasi, VFX, SFX, musik, ikon | Claude Code (jalur aset) |
| `05_GUI_Spec.md` | Aturan & layout GUI mobile-first, token UiKit, status implementasi | Claude Code |
| `06_Roadmap.md` | Rencana kerja final sampai rilis + Update 1, ID tugas `R…` | Owner & Claude Code |
| `07_QA_Test_Plan.md` | Cara tes otomatis & audit untuk Claude Code (lapis A–C) | Claude Code |
| `09_Playtest_Checklist.md` | **Checklist testing untuk owner** + format masukan | Owner |
| `08_Penyempurnaan.md` | Penyempurnaan P-01…P-22 (prioritas Wajib/Disarankan/Nanti sudah dianggap diterima) | Claude Code |

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
6. `06_Roadmap` — urutan kerja (tidak pernah jadi sumber angka).
7. `08_Penyempurnaan` — rencana tambahan; GDD menang bila beda.

Beda antara dokumen dan kode yang **belum** tercatat = temuan baru → Claude Code memutuskan sendiri (nilai konservatif), tulis sebagai K baru di Audit Bab 3.6, lanjut kerja.

## 4. Tanda di Dokumen

| Tanda | Arti |
|-------|------|
| LOCKED | Final. Ubah hanya lewat revisi dari playtest (Audit 3.6) + versi baru. |
| USULAN | Sudah di kode, angka belum dikunci; boleh disetel saat balancing. |
| ✔ K-xx | Sudah diputuskan (Audit 3.0). Teks di baris itu = aturan final. |
| ★ | Dibutuhkan untuk Vertical Slice Lv 1–10. |

## 5. ID (tidak pernah dipakai ulang)

| Awalan | Arti | Tempat |
|--------|------|--------|
| `A-nn` | Temuan audit | `02_Audit` Bab 2 |
| `K-nn` | Keputusan desain (sudah diputuskan; K baru = otomatis, Audit 3.6) | `02_Audit` Bab 3 |
| `P-nn` | Usulan penyempurnaan | `08_Penyempurnaan` |
| `R<fase>.<n>` | Tugas kerja | `06_Roadmap` |
| `M<n>`, `S<n>`, `MQ11`, `MQ12`, `side_*` | Quest | `03_Quest_Naskah` |

## 6. Aturan Revisi

- Angka berubah → versi GDD naik (v8.1, v8.2 …) dan satu baris di Audit Bab 4.
- Satu topik = satu file. Jangan buat file `v7.8`, `v0.4`, dll. di samping file ini; ubah file yang ada, riwayat ada di git.
- Tiap commit kode yang mengubah perilaku juga memperbarui dokumen terkait di commit yang sama.

## 7. Langkah Pertama (Roadmap R0.1, R0.3, R0.4)

1. Owner menaruh 10 file ini (00–09) di folder `docs/` dan menghapus 10 file lama.
2. Owner memberi prompt ini ke Claude Code. **Tidak ada keputusan yang perlu diisi.**

```
Task R0.1 + R0.3 + R0.4 — install the v8.1 doc set and audit code against it.
1. docs/ now contains 00_README_Docs.md … 09_Playtest_Checklist.md. Delete the 10 old docs if they are still there
   (Kampoeng_Tedoeh_v7.4/v7.5/v7.6/v7.7, GUI v0.1, Naskah v0.1, Quest v0.3, Roadmap.md, Skill_Tree v7.7, Test_Plan v0.1).
   Update any code comments that point to the old file names. Commit "docs(R0.1): v8.1 doc set".
2. All K-01..K-42 are already DIPUTUSKAN in docs/02_Audit_Perbaikan.md Bab 3.0 and applied in 01_GDD v8.1.
   Verify: grep "⚠ K-" docs/ must return nothing. Do not ask me anything about the decisions.
3. Run R0.4 from docs/06_Roadmap.md (config vs GDD number audit, report only, no code changes).
   Every mismatch becomes an R1.x task or an automatic K entry in Audit Bab 3.6, with the conservative value chosen.
4. Then start R1.1. Follow docs/06_Roadmap.md Bab 1.1 rules, and give me the Playtest USER checklist
   from docs/09_Playtest_Checklist.md for whatever you finished.
```
