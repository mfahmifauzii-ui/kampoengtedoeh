# KAMPOENG TEDOEH — QA & Test Plan v1.0

> Menggantikan `Test_Plan_Kampoeng_Tedoeh_v0.1.md`. Dipakai di **akhir tiap fase Roadmap** dan di R0.4 / R0.5.
> Claude Code tidak bisa merasakan game. Karena itu ada 4 lapis: (A) gerbang otomatis, (B) audit statis, (C) cek logika, (D) checklist Studio untuk owner (**isinya sekarang di `09_Playtest_Checklist.md`**). Claude Code **menyiapkan** D tapi tidak pernah menandainya lulus.

## 0. Aturan

- Tugas tes **tidak mengubah perilaku game**. Hanya menambah file tes dan laporan. Temuan dicatat, tidak diam-diam diperbaiki (kecuali salah ketik di dokumen).
- Tiap temuan: ID, yang dicek, harapan, kenyataan, file:baris, severity (blocker / major / minor).
- Bug nyata → tugas baru `R1.x` di Roadmap. Celah dokumen → `K-xx` baru di Audit Bab 3. Jangan karang angka.
- Sumber kebenaran: `01_GDD` (angka), `03_Quest_Naskah` (quest & teks), `05_GUI_Spec` (UI), `04_Asset_Bible` (aset).
- Hasil: `docs/reports/Test_Report_<tanggal>.md` + file spec di `tests/`. Satu commit `test(R<id>): regression <tanggal>`.

## A. Gerbang Otomatis

| ID | Cek | Lulus |
|----|-----|-------|
| AUTO-1 | `selene src` | Sebelum R1.9: hanya error lama (daftar per file). Setelah R1.9: 0. |
| AUTO-2 | `rojo build -o /tmp/test.rbxlx` | Exit 0 |
| AUTO-3 | `luau-analyze` / `luau-lsp` bila tersedia | Tidak ada error baru. Tool tidak ada → "tidak tersedia", jangan pasang tool berat. |
| AUTO-4 | `git log` sejak tes terakhir | Tiap commit punya ID `R…` dan baris di Roadmap |

## B. Audit Statis

### B-UI
| ID | Cek | Harapan |
|----|-----|---------|
| B-UI-1 | Angka `DisplayOrder` / `ZIndex` mentah di luar `UiKit.LAYER` | 0 |
| B-UI-2 | Frame/label `Visible=false` / transparan yang tidak pernah tampil atau tampil kosong | 0 (GUI Spec prinsip 6) |
| B-UI-3 | Toast di luar `UiKit.toastStack` | 0; cek anchor tengah, Y di bawah CurrencyBar + 8, maks 3, fade 0,25 |
| B-UI-4 | Posisi HUD tidak dari `UiKit.HUD` | 0 |
| B-UI-5 | Frame HUD yang bisa tampil tanpa isi (status mancing, chip umpan) | 0 |
| B-UI-6 | Tab Tas sesuai K-33 | 8 tab (default) atau sesuai keputusan; Umpan hanya di Umpan & Semua; Olahan bisa dimakan dari Drawer |
| B-UI-7 | Pohon Skill: 6 dahan, 5 status node, drawer, "Efek mulai Lv 3", ikon (K-35) | Sesuai GDD 4.5 & GUI 6.2 |
| B-UI-8 | `Color3.fromRGB` / `TextSize` angka di controller | 0 (kecuali Config/UiAssets) |
| B-UI-9 | Touch: tombol di panel ≥ `TOUCH` 32, CTA 40, ikon kecil ≥ 24 | Sesuai GUI 3.4 |

### B-SRV (keamanan & otoritas server)
| ID | Cek | Harapan |
|----|-----|---------|
| B-SRV-1 | Tiap `RemoteEvent` / `RemoteFunction`: validasi pemain, tipe arg, rentang, kepemilikan, jarak, cooldown | Daftar handler yang percaya klien = 0 |
| B-SRV-2 | `SkillService.buy`: cek maks, prasyarat, SP, Koin sebelum potong; alasan `ok/max/locked/noSP/noKoin`; biaya sesuai GDD 4.5.1; atomik | Lulus |
| B-SRV-3 | Mancing: delay gigitan & lebar kotak dihitung server; skor reel divalidasi (waktu, rentang); umpan dipotong server; jumlah umpan dikirim ke klien | Lulus |
| B-SRV-4 | Tidak ada pemberian Koin/Bunga/XP/item dari klien | 0 |
| B-SRV-5 | `guide.hasMet` tersimpan, default untuk save lama, ditulis dari semua sumber dialog | Lulus |
| B-SRV-6 | FeatureGate: id sama di server & klien; Skill = Player Lv 2; remote fitur tertutup ditolak | Lulus |
| B-SRV-7 | `ProcessReceipt` idempoten (R10.4) | Lulus |
| B-SRV-8 | Command DEV hanya di Studio (R10.5) | Lulus |

### B-DOC (angka dokumen ↔ kode) — tabel: harapan (bab) vs kode (file:baris)
| ID | Item | Sumber |
|----|------|--------|
| B-DOC-1 | Gigitan 3–6 / 6–12 dtk, urutan pengali, hujan (K-01), Jangkrik ×0,7, Buff ×0,8, `biteMult` per joran | GDD 3.3, 6.1, 6.3 |
| B-DOC-2 | Jendela 1,5 dtk, `FILL_GAIN 0.28`, `FILL_DRAIN 0.06`, `ZONE_SPEED 0.9 / 0.55`, mulai 30% | GDD 6.2 |
| B-DOC-3 | 16 skill, prasyarat, grup ATAU, Tetangga Baik (total ≥ 5 + Lv 10), biaya per level | GDD 4.5 |
| B-DOC-4 | Skill bertahap tanpa efek di Lv 1–2 | GDD 4.5.2 |
| B-DOC-5 | Kapak terbaik saja, + Tukang Cepat, maks +4/node, buff hanya saat Critical | GDD 4.5.4 |
| B-DOC-6 | Syarat joran & alat = Player Lv | GDD 6.3, 17.5 |
| B-DOC-7 | Kurva XP & daftar unlock untuk toast "Level N! Terbuka: …" sama dengan GDD 4.4 | GDD 4.2, 4.4 |
| B-DOC-8 | Harga umpan, bibit, jual tanaman/ikan/olahan, hewan, pakan | GDD 5.3, 6.3, 6.4, 7.1, 9.2 |
| B-DOC-9 | Konstanta faucet/sink Bab 17 | GDD 17 |
| B-DOC-10 | Langkah & XP tutorial (total 158), umpan hadiah, ikan pertama Wader Cakul | GDD 16.2 |
| B-DOC-11 | Level buka fitur dan pintu quest | GDD 4.4, Quest 2.1 |
| B-DOC-12 | Kualitas: tabel peluang, cap 50/20, Buff Tani +10 | GDD 5.4 |

### B-STORY
| ID | Cek | Harapan |
|----|-----|---------|
| B-STORY-1 | Baris perkenalan NPC | Tiap NPC 1 perkenalan, hanya saat belum pernah bertemu |
| B-STORY-2 | Rantai quest: tiap langkah bisa dikerjakan saat muncul (tidak ada item/fitur yang terbuka belakangan) | Tulis fitur pembuka tiap langkah |
| B-STORY-3 | Semua kunci `dlg.*` / `quest.*` di Quest doc ada di Locale | 0 hilang |
| B-STORY-4 | Toko Bang Jali tidak terbuka sebelum S3 | Lulus |
| B-STORY-5 | Teks Kerja Bakti sesuai K-37 | Lulus |
| B-STORY-6 | Banner menyembunyikan & mengembalikan GUI | Lulus |
| B-STORY-7 | Solo: S6 & semua quest bisa selesai di server 1 orang | Lulus (setelah R2.5) |

## C. Cek Logika (headless)

Cari `lune` / `luau` / TestEZ / Jest di toolchain (`aftman.toml`, `wally.toml`, `foreman.toml`). Ada → spec murni untuk modul **Config bersama** saja (tanpa Instance). Tidak ada → jangan pasang framework; tulis kasus di laporan sebagai "belum diverifikasi, butuh runner".

1. Prasyarat skill: Lv 0 + Player Lv kurang = locked; grup ATAU lulus dengan salah satu induk Lv 3; Tetangga Baik gagal di total 4, lulus di 5 (Player Lv 10).
2. Biaya skill: 1 skill Lv 1–5 = 5 SP + 15.000 Koin; 16 skill = 80 SP + 240.000 (berlaku juga untuk kurva K-12).
3. SP: SP = level − 1; Lv 60 = 59 SP, belanja maks 177.000 (dengan kurva K-12 hitung ulang dan laporkan).
4. Bertahap: Lv 1–2 tanpa efek; Lv 3 & 5 sesuai GDD.
5. Nambang: kapak terbaik saja; Besi +1, Baja +2, + Tukang Cepat; clamp +4; dasar 4 → maks 8.
6. Delay gigitan: sampel 1.000 kali, dengan umpan ∈ [3,6], tanpa ∈ [6,12], hujan sesuai K-01.
7. Kurva level: XP naik monoton; Lv 59→60 = 1.970; total 64.900; daftar unlock tanpa lubang.
8. Resep: tiap resep ≥ 1,5× nilai bahan (setelah K-03); tiap bahan terbuka ≤ level tier resepnya (setelah K-02) — kecuali yang dicatat.
9. Kualitas: setelah semua bonus, Bagus ≤ 50%, Prima ≤ 20%.
10. Album: 214 entri bisa didapat semua (tidak ada entri mustahil, setelah K-05/K-06).

## D. Checklist Studio (diisi owner) — dipindah ke `09_Playtest_Checklist.md`

Bagian D di bawah dipertahankan sebagai referensi lengkap D.1; **sumber utama untuk owner adalah file 09**. Kalau keduanya beda, 09 menang.

Uji dengan **akun baru dan akun lama**, di 1920×1080, 844×390, 667×375, 390×844. Isi tiap baris: `[ ] Lulus / Gagal — catatan`.

### D.1 Backlog "belum playtest" (R0.5)

1. **Tutorial** dari awal: tanpa tombol Lewati; siram wajib; panen pertama Bagus; cutscene Pak Udin dekat (trigger cepat, jual lewat bubble); Kak Fajar muncul di sungai dekat lahan, cutscene < 0,3 dtk (log `[beat-timing]`); Joran + umpan diterima; ikan pertama; jual ikan; banner Selesai; total XP 158.
2. **NPC diblok** saat tutorial: Nek Ani / Pak Amran hanya "Selesaikan tutorial dulu".
3. **Quest Q-1…Q-4**: `!` di Nek Ani (M1, Lv 2) dan Pak Udin (S1); dialog dulu lalu banner untuk Main; Side tanpa banner + toast; tracker Main di atas, baris 32 px, `Tunjukkan` jalan; tap baris buka Quest Log; tidak ada sisa layar saat tutup.
4. **Feature gate**: akun baru tanpa tombol bergerbang; tiap tombol muncul di langkah quest yang benar.
5. **UI-1**: tombol 32 px nyaman di HP; Panen Semua 40; bubble instruksi & percakapan kompak, teks tidak terpotong; minimize/restore bubble jalan; kiri bawah kosong.
6. **UI-3 Hadiah**: 3 tab; klaim Peti Main, Login, Peti Bunga, Title, Milestone; Season digeser jempol, terbuka di hari ini; Premium terkunci.
7. **Skill (ST-3)**: tombol Skill tidak ada di Lv 1, muncul Lv 2; 6 dahan; node terkunci menampilkan prasyarat; beli potong SP + Koin; alasan gagal benar; "Efek mulai Lv 3"; Tempat Pakan Besar Lv 1–2 tidak mengubah jatah.
8. **Tas**: semua tab utuh; Umpan hanya di Umpan & Semua.
9. **Mancing**: dengan umpan ±3–6 dtk; tanpa ±6–12; chip umpan nama + jumlah, turun 1 per lempar, "Umpan habis"; status selalu ada teks; tombol Batal terbaca; tidak bisa jalan saat memancing; menjauh 24 stud batal + umpan kembali; hujan sesuai K-01; **akun kedua melihat joran, tali, pelampung, animasi**.
10. **Animasi**: FarmPlant, FarmWater, FishingIdle/Cast/Reel/Catch diputar.
11. **Kolam (B-3)**: setor 3 ikan, ambil 1, mancing sampai "Kolam masih kosong", kolam penuh menolak setoran.
12. **Toast**: tengah, di bawah bar Koin, tidak menimpa tracker / kolom kanan, maks 3, portrait turun di bawah tracker.
13. **HUD**: tracker tidak menutupi kartu XP / Craft di layar pendek; tombol ♥ hanya dekat papan kebun orang; lencana Hadiah tidak terpotong; tidak ada bar kosong di atas dock.
14. **Toko**: tab sisi tidak menumpuk; isi terlihat; Bang Jali hanya menyapa sebelum S3.
15. **Persistensi**: keluar-masuk; Koin, SP, skill, umpan, `hasMet`, quest, kolam tetap.
16. **Output**: tidak ada error/warning selama satu sesi penuh (tempel bila ada).

### D.2 Per fase (ditambah Claude Code saat fase selesai)

Format tiap fase: daftar perilaku baru dari tugas `R…` yang selesai, satu baris per hal yang bisa dilihat. Wajib ada untuk Fase 1, 2, 3, 5, 6, 7.

### D.3 Gate G1 — Vertical Slice

1. Akun baru main 2 jam (Lv 1 → 10) tanpa buntu dan tanpa bertanya "terus ngapain?".
2. Semua aksi Lv 1–10 punya animasi + VFX + SFX (Asset Bible Bab 11).
3. 2 pemain di server: FPS ≥ 30 di HP 4GB.
4. Catat menit tiap naik level (untuk R9.1).

### D.4 Gate G3 — Release Candidate

1. 8 pemain, hujan + Kerja Bakti, FPS ≥ 30 di HP 4GB, 30 menit tanpa crash.
2. Ekonomi: 30 & 60 menit rute normal, catat Koin masuk/keluar, bandingkan Bab 17.
3. Beli Pack Bunga di server test (Developer Product) → Bunga masuk sekali.
4. Kill server saat main → data tidak hilang.
5. Command DEV tidak jalan di server live.

## E. Format Laporan

1. Ringkasan: lapis A–D × lulus / gagal / tidak tersedia / menunggu owner.
2. Temuan urut severity: ID, file:baris, harapan vs kenyataan, saran 1 baris.
3. Tabel B-DOC.
4. Checklist D kosong untuk owner.
5. Tugas `R` baru dan `K` baru yang dibuat.
6. Yang tidak bisa dites dan alasannya.

Ringkasan di chat ke owner: hash commit, jumlah per severity, 5 temuan teratas, dan kalimat "Checklist Studio ada di laporan, bagian D".
