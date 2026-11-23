# KAMPOENG TEDOEH — Roadmap (sinkron GDD v8.4 + Audit K-01…K-66)

> Menggantikan `Roadmap.md`. Rencana kerja, **bukan** dokumen desain: angka ada di `01_GDD`, keputusan di `02_Audit_Perbaikan.md`.
> Ditulis untuk owner yang **tidak menulis kode**: semua pekerjaan dan semua keputusan dilakukan Claude / Claude Code. **Owner hanya playtest dan memberi masukan** (`09_Playtest_Checklist.md`). Tidak ada tugas yang menunggu persetujuan owner.
> ID tugas baru: `R<fase>.<nomor>` (unik, tidak dipakai ulang). ID lama (P2-x, Q-x, B-x, UI-Bx, F-x, ST-x, D-xx) hanya muncul di Bab 2 sebagai riwayat.

---

## 1. Cara Kerja

### 1.1 Aturan (LOCKED)

1. **Satu tugas = satu commit**, pesan `<jenis>(R<id>): <ringkas>` (contoh `feat(R2.1): sistem Bubu`).
2. Tiap tugas punya tiga baris verifikasi:
   - **Cek AI** — dibuktikan dari kode: `selene src`, `rojo build`, grep, file:baris.
   - **Tes AI** — Claude Code menjalankan Play di Studio lewat MCP (kalau tool Studio tersedia di sesi itu). Kalau tidak tersedia, tulis "Tes AI: tidak tersedia".
   - **Playtest USER** — yang hanya bisa dirasakan owner (alur, tampilan, tempo, multiplayer). Tetap `[ ]` sampai owner konfirmasi.
3. **Jangan karang angka secara liar.** Angka tidak ada di GDD → pilih nilai paling konservatif, catat `K-nn` baru (`DIPUTUSKAN (otomatis)`) di Audit Bab 3.6, **lanjut bekerja**, dan laporkan di akhir tugas.
4. **Semua K-01…K-66 sudah `DIPUTUSKAN`** (Audit Bab 3.0 dan 3.0b). Kerjakan sesuai tabel itu; GDD v8.4 sudah memuat hasilnya.
5. **Layout map tidak diubah.** Menambah prop (meja, papan, node, dekor) boleh.
6. Error selene tidak boleh bertambah (target 0 setelah R1.9). `rojo build` harus exit 0.
7. Dokumen ikut kode: tugas yang mengubah perilaku juga memperbarui bab GDD / GUI / Quest terkait **dalam commit yang sama**.
8. Kerjakan berurutan dalam satu jalur (Bab 3). Jalur Aset boleh paralel karena tidak menyentuh logika.

### 1.2 Template Prompt untuk Claude Code (English)

```
Task R<id> — <title>
Read first: docs/06_Roadmap.md (R<id>), docs/01_GDD_Kampoeng_Tedoeh_v8.4.md (Bab ...),
docs/02_Audit_Perbaikan.md (K-.. must be DIPUTUSKAN), docs/05_GUI_Spec.md / 04_Asset_Bible.md if relevant.
Goal: <one sentence>.
Done when: <copy "Selesai kalau" from the roadmap row>.
Rules: one commit "<type>(R<id>): ..."; no invented numbers (missing → add new K-xx to Audit Bab 3 and stop);
do not change map layout; selene error count must not increase; rojo build must pass;
update the related doc section in the same commit.
Report back: commit hash, Cek AI evidence (file:line / grep / command output), Tes AI result if Studio is available,
the exact Playtest USER checklist for me, and any new K-xx.
```

### 1.3 Peran Owner

| Kapan | Owner melakukan |
|-------|-----------------|
| — | Tidak ada keputusan yang dibutuhkan dari owner. |
| Akhir tiap fase | Jalankan bagian terkait di `09_Playtest_Checklist.md`, tulis hasil singkat (format di bab 0 checklist) |
| R4.1, R7.1 | Lihat contoh aset (checklist 09 bagian C) dan beri masukan. Produksi **tidak menunggu**; masukan masuk sebagai revisi batch berikutnya. |
| R8.1, R8.2 | Baca cerita yang terpasang di game saat playtest; masukan jadi revisi naskah. |
| Gate G1–G4 | Isi checklist gate di 09. Gate lulus bila **tidak ada temuan Blocker**; owner tidak perlu "tanda tangan". |

---

### 1.4 Status (kolom Status di setiap tabel)

| Status | Arti |
|--------|------|
| DONE-CODE | Ada commit (kolom Commit) atau ada di kode. Belum dijalankan di Play dengan cara yang tercatat. |
| VERIFIED | Dijalankan di Play atau di HP owner, dan caranya tertulis di body commit atau laporan. **Belum ada tugas yang berstatus ini.** |
| CEK | Mungkin sudah ada di kode, tetapi belum ada bukti commit. Perlu cek kode atau Play. |
| TODO | Belum dikerjakan (tidak ada bukti commit atau kode). |
| BLOCKED | Menunggu sesuatu di luar repo (mis. owner, aset, Studio). |

Sumber status: `git log` di `feat/v.7` (subject commit memuat ID) dan pemeriksaan kode. Tugas tanpa bukti = TODO atau CEK, tidak DONE.

---

## 2. Yang Sudah Selesai (riwayat, ringkas)

| Kelompok | Isi | Status |
|----------|-----|--------|
| P0, P1 | Larangan Bab 29 dibersihkan; 18 tanaman, 20 ikan, joran/umpan/alat, Album 214, playtime, cap hias 800, Agenda, XP ikan | Selesai |
| P2-1 … P2-7 | Nambang + craft, Ternak + Kolam + breeding, Dapur 24 resep + Warung + buff + Order, Skill + pity, Sosial, Gerobak / Pasar Malam / Kerja Bakti / event, Quest Harian/Mingguan + Surat + Bundel | Selesai (kode) |
| P2-8 | FTUE: no-skip, blok NPC, cutscene jual, kolam keluar dari tutorial | Selesai, diterima owner |
| P2-9 | Login Mingguan, Peti Bunga, Title, Season F2P | Selesai (belum playtest) |
| Task 1–7 | Sungai Lahan 32 spot, Super dihapus, mini-game, tracker, peti/title/season, Kak Fajar klien | Selesai |
| Q-1 … Q-5 | Data quest v0.3, feature gate, alur tawar-terima, tracker + Quest Log, layer | Selesai (belum playtest) |
| UI-1, UI-3 | Token UiKit, bubble 2 varian, Hadiah 3 tab | Selesai (belum playtest) |
| ST-1 … ST-3, D-38, D-39 | Skill Tree dokumen + kode + panel; Joran Kuat di server; gerbang Skill Lv 2 | Selesai (belum playtest) |
| F-1 … F-3, UI-B1 … UI-B15 | Tab Umpan, toast tunggal, chip umpan, HUD map, 15 bug UI | Selesai (belum playtest) |
| B-1 … B-5 | Timing cutscene, tombol ♥, kolam stok, kunci gerak saat mancing, mancing direplikasi + 6 animasi | Selesai (belum diuji Studio) |

| R1.1 … R1.11 | Angka & aturan GDD (Pakan Jagung, unlock bahan, hujan dan mancing, kualitas olahan, XP Nambang, kurva skill, Tas 8 tab, label lokasi, selene 0 error, Season) | DONE-CODE (commit per ID di Status tabel Fase 1) |
| R0.1, R0.4 | Install doc set (v8.1, sekarang v8.4); audit config vs GDD (`docs/reports/R0.4_config_audit.md`) | DONE-CODE |
| A1 … A7, B1, B2, C1, C2, E1 | Bug grup A (Garap, toast, "!", Joran, Bang Jali), tutorial (panen, mancing), Pakai di Tas, Tarik, tombol Event | DONE-CODE (commit di Bab 19) |
| R2.1, R2.1b, R2.2 | Bubu di sungai + dijual di Pak Udin; Papan Hari Ini (Agenda) | DONE-CODE (commit di Fase 2) |
| Tutorial fix 2026-11-23 | Tanpa gelap (F1), Pak Udin Jual/Beli (F7), tracker guard (F4 sebagian) | DONE-CODE (Bab 18) |

Semua "belum playtest" dikumpulkan di `07_QA_Test_Plan.md` Bab D.1 dan diuji di **R0.5**.

---

## 3. Peta Milestone & Jalur

```
G0 Dokumen rapi ──► G1 Vertical Slice (Lv 1–10 lengkap + art + audio) ──► G2 Konten lengkap Lv 1–60
                                                                         ──► G3 Release Candidate ──► G4 Rilis ──► G5 Update 1

Jalur Kode   : Fase 0 → 1 → 2 → 3 ─────────────► 9 → 10 → 11
Jalur Aset   :          4 (mulai setelah contoh R4.1 lolos pemeriksaan Claude Code) → 5 → 6 → 7   (paralel, tidak menyentuh logika)
Jalur Tulisan:          8 (mulai setelah R0.3)                          (paralel)
```

| Gate | Syarat lulus |
|------|--------------|
| **G0** | Dokumen baru terpasang, semua keputusan K sudah DIPUTUSKAN dan masuk dokumen (GDD v8.1), playtest backlog (09 bagian A) dicek. |
| **G1 Vertical Slice** | Pemain baru bisa main **2 jam pertama (Lv 1–10)** tanpa buntu, semua tugas ★ di Fase 1–7 selesai, FPS ≥ 30 di HP 4GB dengan 2 pemain. Checklist 09 bagian G1 tanpa temuan Blocker, dan 2 jam pertama tidak ada titik "terus ngapain?". |
| **G2 Konten lengkap** | Semua sistem GDD ada, Quest Lv 10–60 + Surat 30 tertulis dan terpasang, semua aset non-★ selesai. |
| **G3 Release Candidate** | Simulasi & playtest ekonomi lulus Bab 17.8, audit keamanan & data lulus, performa 8 pemain lulus, DEV ONLY dikunci. |
| **G4 Rilis** | Closed test selesai, halaman game siap, Season 1 mulai di hari rilis. |

Ukuran tugas: **S** ≤ 1 sesi Claude Code · **M** 2–3 sesi · **L** > 3 sesi (pecah jadi sub-commit).

---

## 4. Fase 0 — Dokumen & Keputusan (G0)

| ID | Tugas | Selesai kalau | Uk | Status | Commit |
|----|-------|---------------|----|---|---|
| R0.1 | Ganti 10 dokumen lama dengan set baru (`00_README` … `09_Playtest_Checklist`). Hapus file lama dari `docs/` (git menyimpan riwayat). | `docs/` hanya berisi 10 file baru (00–09); commit `docs(R0.1): v8.1 doc set`. | S | DONE-CODE | 1755c34 |
| R0.2 | ✔ SELESAI — Claude memutuskan K-01 … K-42 (Audit Bab 3.0). K-16 = ditunda ke Update 1. | Semua K berstatus DIPUTUSKAN. | — | CEK | — |
| R0.3 | ✔ SELESAI di set dokumen ini — keputusan sudah tertulis di GDD v8.1, Quest, GUI. Claude Code cukup memeriksa bahwa tidak ada `⚠ K-` tersisa (`grep`). | `grep "⚠ K-" docs/` kosong. | S | CEK | — |
| R0.4 | **Audit angka kode ↔ GDD** (QA Bab B-DOC): bandingkan setiap angka di `Config/*` dengan GDD, termasuk yang ditandai "dari kode" / "cek" (biteMult, biaya Warung, umpan hadiah, bibit gratis, sisa starter chain, id Warung Laris, lokasi lapak Kak Fajar, Joran Kuat poin/relatif). | Laporan tabel cocok/tidak cocok; yang tidak cocok jadi tugas R1.x baru atau K baru. Tidak ada perubahan kode. | M | DONE-CODE | 30eaa83 |
| R0.5 | Playtest backlog: owner menjalankan `09_Playtest_Checklist.md` bagian A (semua "belum playtest" dari riwayat). | Hasil tercatat; bug → R1.x. | M (owner) | TODO (Play) | — |

---

## 5. Fase 1 — Perbaikan Konsistensi Kode (★ semua)

Butuh: R0.3 selesai.

| ID | Tugas | Dasar | Selesai kalau | Uk | Status | Commit |
|----|-------|-------|---------------|----|---|---|
| R1.1 | Unlock bahan resep + harga resep + Pakan Jagung | K-02, K-03, K-04 | `Config/Crops` & `Config/Dapur` sama dengan GDD v8.1; kartu resep menampilkan bahan terkunci | S | DONE-CODE | a32917d, 8c172c7, 999dd55 |
| R1.2 | Hujan & mancing: efek hujan, kondisi Belut Emas, watchdog, biteMult | K-01, K-07, K-25, K-26 | `biteDelayFor` / jendela gigitan sesuai GDD; uji 1000 sampel (QA C-6) | S | DONE-CODE | 6f322d7 |
| R1.3 | Kualitas olahan dari ikan/telur/susu + Rasa Prima naik 1 tingkat | K-05 | Ikan Early Goreng Prima bisa dibuat dari ikan Jumbo; Album Dapur 72 bisa lengkap | M | DONE-CODE | 651ab8c, 0ed5c44 |
| R1.4 | Album Legenda (ukuran berikutnya yang belum dimiliki) | K-06 | 4 tangkapan Legenda = 4 ukuran | S | DONE-CODE | ca50a18 |
| R1.5 | Quest & hadiah: MQ11 ATAU, Warga Teladan dihapus, hadiah side (K-15), Kebun Favorit tanpa peti, naskah side baru ke Locale (K-14), 3 baris naskah usulan (M3, S4, S9) | K-13, K-14, K-15, K-18, K-28 | Locale berisi semua kunci `03_Quest_Naskah` Bab 6; side tanpa naskah = 0 | M | DONE-CODE | b9b8219, 01b520d |
| R1.6 | XP Nambang, aturan refund, hapus timer kolam | K-08, K-09, K-10 | XP per bahan tercatat; Kolam refund 100%; `collectPond` timer dihapus | S | DONE-CODE | c4d5ff0 |
| R1.7 | Tab Tas 8 tab, teks gerbang level & Kerja Bakti, Diskon Warga di Kak Fajar, bahan tak bisa dijual | K-33, K-37, K-41, K-42 | QA B-UI-6 lulus | S | DONE-CODE | 9153fbc |
| R1.8 | Kurva biaya skill 1.000 … 5.000 | K-12 | QA C-2 lulus (total 15.000 / 240.000) | S | DONE-CODE | 989e6b8, a7e2acb |
| R1.9 | Bersihkan error selene lama (FarmFloat ×2, SettingsService, MapService, FishSpotFx bila ada) | Audit A-11 | `selene src` = 0 error | S | DONE-CODE | 0953721 |
| R1.10 | Label pemain: "Kanal Barat / Kanal Timur / Sungai Lahan", hapus "Pro/Basic Mancing" & "Spot 4" dari Locale; Lv 18 jadi "Kanal Timur malam" | K-22, K-23 | grep Locale "Pro Mancing\|Spot 4\|Empang" hanya untuk Bundel | S | DONE-CODE | ad0050e |
| R1.11 | Season mulai di hari rilis (konstanta di Config, diisi di R11.3) | K-29 | `Rewards.SEASON.START` bisa diubah tanpa kode lain | S | DONE-CODE | 5386e5b |

---

## 6. Fase 2 — Sistem yang Belum Ada

| ID | Tugas | Dasar | Selesai kalau | ★ | Uk | Status | Commit |
|----|-------|-------|---------------|---|----|---|---|
| R2.1 | **Sistem Bubu** (pasang di air, 6 jam, isi per tipe, maks 3, tanpa instant) + buka M8 | GDD 6.6 | M8 tidak lagi `blocked`; panen bubu offline jalan | ★ | M | DONE-CODE | f877f4d |
| R2.1b | Bubu bisa dibeli di Pak Udin (Koin), dipasang dan diambil dari layar (GDD 6.6, K-66) | K-66 | Tombol Pasang / Ambil di slot Aksi; tiang di sungai; alur 6 jam | | M | DONE-CODE | fad0c1b |
| R2.2 | **Agenda UI** di Papan Hari Ini + langkah M1 "Buka Agenda" | GDD 14.5, GUI 6.9 | Agenda terlihat, 5 tugas, hadiah otomatis tercatat | ★ | M | DONE-CODE | be81d41 |
| R2.3 | Sisa tutorial/quest: event Surat #1 dibaca, Gerobak terbuka di M1 (bukan `starter_pagar`), hapus sisa starter chain | Audit A-28 | Feature gate Agenda/Gerobak/Order hanya dari M1 | ★ | S | TODO | — |
| R2.4 | Kucing Alun-alun + Joran Hilang: **belum di kode** (tidak ada di `Config/Quests`, tidak ada flag `released`). Ditunda ke R12.4 (K-16 b). Quest Log tidak menampilkannya karena tidak ada di data. | K-16 (b) | Tidak ada error; tidak tampil di Quest Log rilis; dibangun di R12.4 | | S | DITUNDA (R12.4) | — |
| R2.5 | Kebun Warga (4 petak NPC, Bantu solo) | K-17 | S6 bisa selesai sendirian di server kosong | ★ | S | TODO | — |
| R2.6 | Blueprint simpan (3 slot) + kirim ke pemain + kode di panel | GDD 8.7, K-39 | Simpan → pasang ulang di lahan sendiri pakai bahan sendiri | | L | TODO | — |
| R2.7 | Akuarium (8 ikan, Legenda/Jumbo) + Bingkai Album (%) | GDD 8.6 | Keduanya bisa dipasang dan berfungsi | | M | TODO | — |
| R2.8 | Buff Saung (duduk 5 dtk → +5% XP 10 menit) + cek 5 Bundel jalan semua | GDD 14.6 | Semua Bundel bisa dipulihkan | | S | TODO | — |
| R2.9 | Event selesai → Peti; Pesanan Tamu per event | K-19 | 1 event uji bisa selesai | | S | TODO | — |
| R2.10 | Analytics (GDD 25.2 + TutorialStep + FeatureOpen) lewat `AnalyticsService` | GDD 25 | Event muncul di dashboard Creator Hub saat playtest | ★ | M | TODO | — |
| R2.11 | Cek & lengkapi: toast sehat 120 menit, Settings (Mode Bantu, Efek rendah, Kurangi gerak, volume 4 grup, Haptic, Notif Gerobak) | GDD 2.3, GUI 6.10 | Semua setting tersimpan & berpengaruh | ★ | S | TODO | — |
| R2.12 | Tabel Bunga & sumber Peti sesuai K-31 (Bundel 10 Bunga, tanpa dobel) | K-31 | Angka di Config = GDD 18.2 baru | | S | TODO | — |

---

## 7. Fase 3 — GUI

| ID | Tugas | Dasar | ★ | Uk | Status | Commit |
|----|-------|-------|---|----|---|---|
| R3.1 | UI-2 HUD: kartu pemain kiri atas + chip buff, slot Tombol Aksi tunggal (`UiKit.actionButton`, termasuk Craft & Dapur), label tombol baru 4 dtk, `attachTip` (tekan lama / hover), hapus tombol HUD Dapur | GUI 4, K-34 | ★ | M | TODO | — |
| R3.2 | UI-5 Stasiun: Dapur + Warung, Meja Crafting, Kandang, Kolam (komponen `slotCard`, `timerRing`, `recipeCard`, `filterChips`) | GUI 6.3–6.5 | ★ | L | TODO | — |
| R3.3 | UI-6: Acara (Hari Ini / Kalender), Pesanan, Quest Log penuh, Papan Hari Ini | GUI 6.6–6.9 | ★ | L | TODO | — |
| R3.4 | Sisa Hadiah: kartu Login, bar Peti Main, kartu Peti Bunga, Klaim Semua (remote batch), Milestone Album hanya di Koleksi | K-36 | ★ | M | TODO | — |
| R3.5 | Pohon Skill: ikon per skill di node | K-35 | ★ | S | TODO | — |
| R3.6 | Tas (8 tab + Drawer + Makan), Album rapi, Atur lengkap, Menu awal & loading | GUI 6.10 | ★ | M | TODO | — |
| R3.7 | Pass layar & aksesibilitas: 4 resolusi, toast vs bubble (K-40), layer coachmark vs toast (A-72: tertutup 2026-11-23, overlay coachmark dihapus), kualitas pakai bentuk + warna, teks ≥ 12 | GUI 3, 4 | ★ | M | TODO | — |
| R3.8 | **Lempar Gelang minigame:** bar bergerak, tap berhenti; zona 60/30/10% (kecil/sedang/besar); 3 lemparan per malam; Pasar Malam jadi tempat di dunia (K-57) | K-57 | Hadiah sesuai zona; 3 lemparan per malam; tidak ada menu jual | | S | TODO | — |
| R3.9 | Hias GUI "Warna Dinding": 12 warna muted (Asset Bible Bab 1) + "Dinding Spesial" (K-61) | K-61 | Warna terpasang di dinding dekor dan tersimpan | | S | TODO | — |
| R3.10 | Pasang semua ikon dari R4.2 ke `Config/UiAssets`, hapus fallback pil teks | Asset Bible 10 | ★ | S | TODO | — |
| R3.11 | `UiKit.sheet` kind list/grid/wide menggantikan `panel` di semua controller; hapus `Instance.new` manual yang punya komponen | GUI 5, 7 | | M | TODO | — |

---

## 8. Fase 4 — Aset 2D & 3D (jalur paralel, `04_Asset_Bible.md`)

| ID | Tugas | ★ | Uk | Status | Commit |
|----|-------|---|----|---|---|
| R4.1 | **Contoh gaya**: 1 tanaman (4 tahap), 1 bangunan (Kandang Ayam), 1 piece hias, 3 ikon item, 1 NPC — screenshot disimpan di laporan; Claude Code memeriksanya terhadap Asset Bible Bab 1 (palet, outline, proporsi) lalu produksi massal lanjut. Owner memberi masukan lewat 09 bagian C. | ★ | M | TODO | — |
| R4.2 | Ikon: HUD (Acara, Skill, dll.), Tombol Aksi, item Lv 1–10, umpan ×4, skill ×16, kualitas, skin bambu tipis bubble | ★ | L | TODO | — |
| R4.3 | Objek fungsi wajib: **Meja Crafting**, 6 node Hutan (penuh + habis, part `Mining` + `NodeId`), Tungku T1, Warung, Kandang Ayam Lv1, Kolam Tanah, Bubu Bambu, Kebun Warga | ★ | L | TODO | — |
| R4.4 | NPC: cek 6 utama + Bang Jali (siluet, potret); buat 6 Pedagang Tamu, Tamu Event, 3 pengunjung Warung, kucing | ★ (utama) | L | TODO | — |
| R4.5 | Tanaman 18 × 3 tahap + 6 varian | ★ (9 pertama) | L | TODO | — |
| R4.6 | Hewan 3 + 2 varian, produk, ikan 20 | ★ (Ayam, ikan Early) | L | TODO | — |
| R4.7 | Bundel 5 (rusak + pulih), Akuarium, Bingkai, Tungku T2/T3, Kandang lain, Kolam Semen/Keramik, Bubu Kayu/Besi | ★ (Kolam & Sumur) | L | TODO | — |
| R4.8 | Katalog Hias 80 (nama di Asset Bible 4.8 dianggap final; key boleh disesuaikan dengan Config) + tandai 30 Dekor Berkah | ★ (Pagar Bambu + 10 piece dasar) | L | TODO | — |
| R4.9 | Alat dipegang (cangkul, gembor ×5, sabit ×3, kapak ×4, joran ×6) | ★ (versi gratis) | M | TODO | — |
| R4.10 | Props alun-alun & event (Gerobak, Pasar Malam, Lempar Gelang, sampah, Galeri, 5 set event) | ★ (Gerobak, sampah) | L | TODO | — |
| R4.11 | Hapus fallback node DEV (268,268) setelah node asli ada | ★ | S | TODO | — |

## 9. Fase 5 — Animasi

| ID | Tugas | ★ | Uk | Status | Commit |
|----|-------|---|----|---|---|
| R5.1 | Uji 6 animasi yang ada (FarmPlant, FarmWater, Fishing ×4) termasuk dilihat pemain kedua | ★ | S | TODO | — |
| R5.2 | Animasi aksi pemain: cangkul, panen, tebang, pukul, aduk, makan, pakan/ambil, pasang hias, serah barang | ★ | L | TODO | — |
| R5.3 | Gestur 4 (termasuk Jempol), sorak, pungut sampah, lempar gelang | | M | TODO | — |
| R5.4 | NPC: bicara loop, melambai, idle khas 6 NPC, pengunjung warung | ★ (bicara) | M | TODO | — |
| R5.5 | Hewan (ayam, bebek, sapi) + kucing; ikan berenang prosedural | ★ (ayam, ikan) | M | TODO | — |
| R5.6 | Token motion UI (`MOTION.*`) + setting Kurangi gerak | ★ | S | TODO | — |

## 10. Fase 6 — VFX

| ID | Tugas | ★ | Uk | Status | Commit |
|----|-------|---|----|---|---|
| R6.1 | `FxService` (pool, id efek, setting Efek rendah, batas partikel) | ★ | M | TODO | — |
| R6.2 | Kebun: till, plant, water, harvest ×3, ready, market | ★ | M | TODO | — |
| R6.3 | Mancing: cast, bite, catch, escape, firasat, legend | ★ (kecuali legend) | M | TODO | — |
| R6.4 | Hutan & craft & dapur: hit per bahan, crit, node gone/back, craft, cook, cook_done, buff | ★ | M | TODO | — |
| R6.5 | Cuaca & waktu: hujan ×3, tanda hujan, kabut, kunang | ★ (hujan) | S | TODO | — |
| R6.6 | Progres: fly Koin/Bunga/XP, levelup, album, banner, restore, set_done | ★ | M | TODO | — |
| R6.7 | Sosial & event: like, cart, trash, night market, firework | | S | TODO | — |

## 11. Fase 7 — Audio & Haptic

| ID | Tugas | ★ | Uk | Status | Commit |
|----|-------|---|----|---|---|
| R7.1 | Contoh suara: 5 SFX UI + 1 musik menu → diperiksa terhadap Asset Bible Bab 7–8 (tanpa menunggu owner) | ★ | S | TODO | — |
| R7.2 | `SoundService` 4 grup + volume Settings + `Config/Audio` | ★ | S | TODO | — |
| R7.3 | SFX UI & aksi (Asset Bible 7), ganti placeholder Critical | ★ | L | TODO | — |
| R7.4 | Ambience 4 fase + sungai + hutan; suara cuaca | ★ | M | TODO | — |
| R7.5 | Musik: menu + 1 lagu fase (★), lalu 3 lagu fase, hujan, pasar malam | ★ (2 lagu) | M | TODO | — |
| R7.6 | Haptic (cek dukungan perangkat) | | S | TODO | — |

## 12. Fase 8 — Konten & Tulisan (jalur paralel)

| ID | Tugas | Uk | Status | Commit |
|----|-------|----|---|---|
| R8.1 | Rancang **Babak 2** (Lv 10–30) dari `08_Penyempurnaan.md` P-03 → P-03 dianggap diterima → data quest + naskah + feature gate | L | TODO | — |
| R8.2 | Rancang **Babak 3** (Lv 30–60) + finale "Surat Terakhir Kakek" → P-03 dianggap diterima → pasang | L | TODO | — |
| R8.3 | Teks **Surat Kakek #2–#30** (tugas kecil + hadiah dari tabel yang sudah ada di Config) | M | TODO | — |
| R8.4 | Side quest lanjutan Lv 10+ (Quest doc Bab 7) | M | TODO | — |
| R8.5 | Pool teks Order Villager per NPC, sapaan harian NPC (3 variasi per NPC), baris Pedagang Tamu | M | TODO | — |
| R8.6 | 5 event musiman: Pesanan Tamu, hadiah, dekor, teks | L | TODO | — |

## 13. Fase 9 — Balancing

| ID | Tugas | Selesai kalau | Uk | Status | Commit |
|----|-------|---------------|----|---|---|
| R9.1 | **Simulasi pace & ekonomi** (skrip di luar game yang membaca angka Config): XP/jam per fase, jam ke Lv 10/20/60, faucet/sink, porsi per sistem, setelah Super dihapus & K-03/K-12 | Laporan dengan angka; target Bab 17.8 dicek; usulan setelan ditulis sebagai K baru | M | TODO | — |
| R9.2 | Protokol playtest 30 / 60 / 120 menit (akun baru) + catatan Koin, XP, level per 10 menit | Data 3 sesi | M (owner) | TODO | — |
| R9.3 | Setel angka (XP aksi dulu, harga skill kedua) sesuai hasil R9.1–R9.2 | Bab 17.8 lulus | S | TODO | — |

## 14. Fase 10 — Teknis Sebelum Rilis

| ID | Tugas | Selesai kalau | Uk | Status | Commit |
|----|-------|---------------|----|---|---|
| R10.1 | Audit keamanan remote (QA B-SRV): semua handler cek pemain, tipe, rentang, kepemilikan, jarak, cooldown | 0 handler yang percaya nilai klien | M | TODO | — |
| R10.2 | Data: session lock, `BindToClose`, retry, reconcile default, **migrasi versi** (wajib setelah rilis) | Rejoin/kill server tidak kehilangan data | M | TODO | — |
| R10.3 | Performa HP 4GB: 8 pemain, hujan + Kerja Bakti, 2 lahan penuh 800 piece; streaming, LOD, anggaran Asset Bible 2 | FPS ≥ 30, memori stabil 30 menit | L | TODO | — |
| R10.4 | Developer Product Pack Bunga (harga Robux sesuai K-32: 75 / 150 / 300 / 600 R$, disetel di Config), `ProcessReceipt` idempoten | Beli → Bunga masuk sekali, aman saat server mati | S | TODO | — |
| R10.5 | Kunci DEV ONLY: `!kakek`, `!sp`, `!cuaca`, `DevService`, fallback node → hanya di Studio | Tidak bisa dipanggil di server live | S | TODO | — |
| R10.6 | Teks user-generated (nama Blueprint, dsb.) lewat `TextService:FilterStringAsync` | Semua teks dari pemain difilter | S | TODO | — |

## 15. Fase 11 — Rilis

| ID | Tugas | Uk | Status | Commit |
|----|-------|----|---|---|
| R11.1 | Closed test 10–20 orang (teman/komunitas), 1 minggu; baca analytics funnel tutorial & D1 | M | TODO | — |
| R11.2 | Halaman game: ikon, 5 thumbnail, deskripsi (ID + EN), kuesioner maturity / compliance di Creator Hub (cek ulang klaim 16+, Audit A-80), genre & tag | S | TODO | — |
| R11.3 | Rilis publik; isi `Rewards.SEASON.START` = hari rilis 05:00 WIB | S | TODO | — |
| R11.4 | Pantau D1 / D7 / sesi / konversi 2 minggu; perbaikan cepat | M | TODO | — |

## 16. Fase 12 — Pasca Rilis (Update 1, ±2 bulan setelah rilis)

| ID | Isi | Status | Commit |
|----|-----|---|---|
| R12.1 | Level Cap 80, +20 piece hias, +3 resep, +2 ikan, +1 tanaman, +1 hewan penghasil wol (Domba) | TODO | — |
| R12.2 | Season Premium dibuka (daftar kosmetik P-14 diterima, K-30) | TODO | — |
| R12.3 | Bahasa Inggris (Penyempurnaan P-12) | TODO | — |
| R12.4 | Spot 4 sebagai prop baru (K-22 b) **dan** Kucing Alun-alun + Joran Hilang dibangun penuh (K-16 b) | TODO | — |
| R12.5 | Lomba Hias Bulanan pertama | TODO | — |

---

## 17. Utang & DEV ONLY (dipantau sampai sebelum rilis)

| Item | Ditutup oleh |
|------|--------------|
| Fallback node Nambang (268,268) | R4.11 |
| `!kakek`, `!sp`, `!cuaca`, `DevService` | R10.5 |
| Prompt NPC masih terlihat saat tutorial (yang diblok interaksinya) | R3.7 (opsional sembunyikan per pemain) |
| Placeholder suara Critical (`place_item` pitch-up) | R7.3 |
| Dekor event sementara (Part) | R4.10 |
| `ftue_super` di save (sengaja dipertahankan) | Hapus saat migrasi pertama R10.2 |
| Stylua belum dikonfigurasi di repo (`aftman.toml` tidak mendaftar stylua); format tidak diperiksa otomatis. Diterima owner 2026-11-23. | Tidak ditutup; tinjau saat R10.x |

**DEV ONLY (dari bab lama 21, digabung):**

| Item | Ditutup oleh |
|------|--------------|
| `DevService` perintah `!` (`!state`, `!give`, `!skenario`, ...) dan panel DEV | R10.5 (+ `Config/DevAccess.LIVE_ENABLED = false`, K-64) |
| `Config/DevAccess.UserIds` (akun owner) | R10.5 (hapus sebelum rilis atau pindahkan ke Config rilis) |
| `DataService` mode studioMock (profil di memori di Studio, K-65) | R10.5 (tetap aman: hanya di Studio) |
| Atribut Workspace `DevSaveSuffix` (kunci simpan Studio) | R10.5 |
| Gerbang G3 "perintah DEV dimatikan" | G3 (AUTO check) |


---

## 18. Batch perbaikan owner 2026-11-23 (F1–F8)

Sumber: video dan HP owner (playthrough 8:21 di PC + screenshot). Setiap F = satu atau lebih commit, dengan syarat yang sama dengan Bab 19. Status Play: lihat kolom Status; belum ada yang VERIFIED.

| ID | Perbaikan | Status | Commit | Catatan |
|----|-----------|--------|--------|---------|
| F1 | Sorot tutorial: satu lubang hanya tombol HUD tetap pertama kali; GUI mengambang tanpa gelap (GDD 16.6, GUI 4.6, 9.7) · F1c: Garap tutup = reset semua seleksi | F1a+F1b+F1c DONE-CODE (Play belum: input Studio timeout; sumber oranye belum direproduksi) | 00e8cdf, lalu commit feat(F1a) | Play belum diverifikasi: input Studio timeout di sesi ini. Cek HP: joystick dan HUD bisa dipakai (docs/09) |
| F2 | Satu permukaan instruksi per langkah: pertama = bubble, pengulangan = toast; toast hilang saat langkah berganti | TODO | — | Tabel per langkah ada di GUI 4.6 dan GDD 16.2; belum diterapkan di kode |
| F3 | Tombol Aksi bulat satu komponen: Tarik (done), Pasang, Ambil, Panen Semua (GUI 6.12) | DONE-CODE (Tarik) · TODO (Pasang, Panen Semua) | 0fb8032 | Pasang: `BubuController` ~106; Panen Semua: `FarmController` ~1165 |
| F4 | Tracker tidak berkedip; hilang hanya bila tidak ada quest dilacak | DONE-CODE (sebagian) | 425d393 | Guard pcall saja. Akar penyebab belum direproduksi di Play |
| F5 | Quest Log terbuka dari ikon bintang dan tap tracker di semua keadaan; badge; toast "Quest baru: <judul>" untuk quest pembelian (03 Bab 9) | TODO | — | Bintang belum ada di kolom kanan (`HudController`). Teks toast sekarang "Misi baru" |
| F6 | "!" di atas setiap pemberi quest (Tersedia atau siap), termasuk setelah quest pembelian dan rejoin | DONE-CODE (jarak) · CEK (per pemberi) | 43b4719 | Tabel per pemberi belum dibuat (Bab 21) |
| F7 | Pak Udin setelah tutorial: Jual / Beli + Sampai jumpa | DONE-CODE | 5641d7a | Cek HP pending |
| F8 | docs/09: cek HP per perbaikan F1–F7 | TODO | — | Dikerjakan di tugas D8 (lihat 09 bagian baru) |
| TB | Toast tepat di bawah bar Koin/Bunga, tidak ikut bubble coachmark atau dock; maks 2 chip, terbaru di atas; langkah pengulangan = toast saja (tanpa bubble, tanpa ring) | DONE-CODE (TB; kode dicek terhadap keempat poin owner) | d4c3e55 | Akar: `UiKit.TOAST_AVOID` mendorong stack ke bawah bubble coachmark (CoachTop) sampai menutupi dock. Dihapus. Garap_5 dan tanam_5 sekarang toast. Visual Play sebagian: posisi stack y=60 (UI tree), gambar belum |
| MS | Setelah panen pertama (panen_1 selesai), Mak Sari meminta {n}=5 petak lagi lewat bubble dialog (bukan toast). Next sekali per save (`guide.mkSariHarvestSeen`); pengingat sesudahnya toast; tidak ada gelap, pemain tetap bisa jalan | DONE-CODE (MS) | (lihat git log: feat(MS)) | Play sebagian: bubble tampil dengan dua baris benar ("5 petak"), Next dua kali, flag tersimpan di server (ms_seen). Toast pengingat setelah dismiss belum dilihat; uji ulang di save baru | 
| MS-2 | Bubble Mak Sari di atas dock (`T1Dialog.DOCK_CLEAR` 92 px); tiga tahap sekali per save (panen pertama, bibit ulang, panen semua); ring Garap kuning di garap_5; toast tersemat sampai N petak | DONE-CODE (MS-2) | (lihat git log: feat(MS-2)) | Play belum: uji ulang dari !reset sampai panen pertama. Config bibit = 6 (owner menulis 5), dicatat di 03 4.2c |

## 19. Putaran Playtest 1 (K-53…K-57): dikerjakan sebelum Fase 2

Urutan: A bug → B tutorial → C mancing UI → D quest → E event/pasar. Satu tugas = satu commit. Setiap tugas: Play test Studio dan "Tes AI:" di body commit. selene 0 error dan rojo build exit 0.

| ID | Tugas | Dasar | Selesai kalau | Uk | Status | Commit |
|----|-------|-------|---------------|----|---|---|
| RP1.A1 | Garap: tap = sorot, tap kedua = tanam, titik sama dengan ghost; outline hilang saat keluar mode (#15, #16) | K-53 | Sel tersorot = sel tertanam di 844×390, 667×375, 390×844 | S | DONE-CODE | 24387c5 |
| RP1.A2 | Toast di bawah HUD (12 px) dan di bawah Bubble; pill "Lv n"; buff kosong disembunyikan (#17, #18) | K-53 | Toast tidak menutupi HUD di 3 resolusi | S | DONE-CODE | e0da363, eb39486 |
| RP1.A3 | Marker "!" untuk semua pemberi quest; Bang Jali "Terbuka di Level n" / "Jual / Beli" (ganti 2026-11-23); cek rantai S3 (#6, #14) | K-53 | "!" tampil untuk Nek Ani; S3 bisa dimulai di level yang ditulis | S | DONE-CODE | 3efc8ff, fad8d0f |
| RP1.A4 | Joran di tab Alat; teks Acara tidak terpotong; glyph "A·" diganti (#7) | K-53 | Layout Acara bersih di 390×844 | S | DONE-CODE | 7fa99e3 |
| RP1.B1 | Tutorial panen: 5 Garap, 6 bibit Kangkung ulang, tunggu semua panen, lalu Pak Udin; XP tetap Lv 2 (#1) | K-54 | Alur 4 langkah berurutan, Locale lengkap | M | DONE-CODE | 5645398 |
| RP1.B2 | Tutorial mancing: 3 tangkapan, cutscene hanya di ke-3; umpan cukup 3 lemparan (#2) | K-54 | Tangkapan 1–2 tanpa cutscene | S | DONE-CODE | ece3ceb |
| RP1.C1 | Pakai di Tas, badge Dipakai, chip HUD, auto-ganti umpan + toast, `equippedRod`/`equippedBait` di save (#3) | K-55 | Server validasi; save lama terisi default | M | DONE-CODE | d22ba32 |
| RP1.C2 | Tombol Tarik di slot Tombol Aksi, terpisah dari Pancing (#4) | K-55 | Tarik bisa ditekan; Pancing tidak tertimpa | S | DONE-CODE | 9b998cb |
| RP1.D1 | Pool Harian/Mingguan dengan syarat; "Bantu lahan" pindah ke Season 500 Koin (#5) | K-56 | Tidak ada templat tak eligible; Bantu hanya di Season | M | CEK | — |
| RP1.D2 | Blokir quest yang sistemnya belum ada (M1 sampai R2.2); baris langkah pemain (#10) | K-56 | M1 tersembunyi; tiap langkah punya baris | M | CEK | — |
| RP1.D3 | Pohon Skill: bar bawah dengan Beli; tanpa scroll di 844×390 (#7) | K-56 | Tombol Beli selalu terlihat | S | CEK | — |
| RP1.D4 | Quest Log: tab Main/Side/Harian/Pesanan, dua panel, Tandai, tracker maks 3 (#8, #9, #11) | K-56 | Sesuai 05 Bab 6.8 | L | CEK · F5 | — |
| RP1.E1 | Tombol Event hanya saat event aktif (#12) | K-57 | Tidak tampil saat tidak ada event | S | DONE-CODE | 0368b15 |
| RP1.E2 | Pasar Malam tempat di dunia, Pak Kumis NPC, jual lewat bubble (#13) | K-57 | Tidak ada jual dari menu | M | CEK | — |
| RP1.E3 | Lempar Gelang minigame (= R3.8) | K-57 | Zona 60/30/10; 3 lemparan | M | → R3.8 | — |

---

---

## 20. Putaran Playtest 2 (K-58…K-63 + backlog Fase 2)

Urutan (satu tugas = satu commit, selene 0 error, rojo exit 0):

| ID | Tugas | Dasar | Selesai kalau | Status | Commit |
|----|-------|-------|---------------|---|---|
| RP2.V | Verifikasi putaran 1: Play D1/D2, warning selene, cek server | Hutang | Hasil Play dicatat per item | TODO | — |
| RP2.D2 | Jalan-jalan quest Main + Side, tiap langkah ada baris instruksi | 03 Langkah | Tabel per langkah di laporan | TODO | — |
| RP2.S | Season "Bantu 20 lahan" | K-58 | Progres tersimpan, hadiah 500 Koin | TODO | — |
| RP2.G | Gembor Emas (K-62) | K-62 | Pakai di Alat, side_prima memberi item | TODO | — |
| RP2.6–9, 12 | R2.6 Blueprint, R2.7 Akuarium, R2.8 Saung, R2.9 event, R2.12 Tabel Bunga | K-31 | Sesuai GDD, placeholder di Asset Bible 12 | TODO | — |

Tugas yang sama dengan Fase 2 dan 3 tidak dicatat dua kali (dihapus dari tabel ini): RP2.1 = R2.1; RP2.2 = R2.2; RP2.5 = R2.5; RP2.10 = R2.10; RP2.11 = R2.11; RP2.D4 = RP1.D4; RP2.E2 = RP1.E2; RP2.E3 = R3.8. Status ada di Fase 2/3 atau Bab 19.

ID bentrok di Fase 3 sudah diperbaiki: ikon UiAssets = R3.10, UiKit.sheet = R3.11 (2026-11-23).

---

---

## 21. Utang verifikasi (belum dijalankan)

Semua baris di sini berstatus TODO kecuali disebut lain. Tidak ada yang VERIFIED.

| Item | Cara cek | Status | Ditutup oleh |
|------|----------|--------|--------------|
| Tes gerbang hujan 1000 sampel (K-01, K-49) | Simulasi di Studio atau Lune | TODO | R10.3 |
| Siklus ukuran Legenda (K-06, K-47) | 100k sampel Studio | TODO | QA C-6 |
| Telur Mood Hujan (K-05 a, R1.3) | Play: hujan, telur Bagus | TODO | Play |
| Refund kolam 100% (K-09, R1.6) | Play: bongkar kolam, cek koin | TODO | Play |
| Reset Agenda 05:00 WIB (Bab 14.5) | Ubah jam server di Studio | TODO | Play |
| Pill tap pada layar sentuh (F-pill, c5ae313, f70a660) | HP owner atau emulator sentuh | TODO | docs/09 F-section |
| Tabel marker "!" per pemberi (F6) | Play: tiap pemberi, catat jumlah marker | TODO | Bab 21 baris ini |
| Tutorial penuh dari profil baru | Play: akun baru, 13 langkah GDD 16.2 | TODO | Play + HP |
| Jalan quest side (docs/03) | Play: tiap side, catat langkah | TODO | Play |

## 22. Risiko Utama

| Risiko | Penanganan |
|--------|------------|
| Pace terlalu cepat/lambat (A-19) | R9.1 sebelum konten Babak 2–3 dikunci |
| HP 4GB tidak kuat dengan 8 lahan penuh | Anggaran aset sejak R4.1, uji R10.3 lebih awal (setelah G1) |
| Aset AI tidak seragam gayanya | Gerbang R4.1 + satu atlas per kategori |
| Animasi/audio tidak bisa diputar karena kepemilikan | Publish atas nama pemilik game yang sama (Asset Bible 3) |
| Dokumen kembali berantakan | Aturan 1.1 #7 + README: satu file per topik, keputusan hanya di Audit Bab 3 |

---
