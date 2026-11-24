# KAMPOENG TEDOEH — Audit & Daftar Perbaikan v1.0

> Dibuat 2026-11-23 dari 10 dokumen lama: `Kampoeng_Tedoeh_v7.4/v7.5/v7.6/v7.7.md`, `GUI_Kampoeng_Tedoeh_v0.1.md`, `Naskah_Dialog_Kampoeng_Tedoeh_v0.1.md`, `Quest_Kampoeng_Tedoeh_v0.3.md`, `Roadmap.md`, `Skill_Tree_Kampoeng_Tedoeh_v7.7.md`, `Test_Plan_Kampoeng_Tedoeh_v0.1.md`.
> Audit ini **hanya berdasarkan isi dokumen**, bukan kode. Kalau dokumen menyebut "kode sekarang X", angka itu dipakai apa adanya.
> Fungsi file ini: (1) daftar semua kontradiksi / inkonsistensi / gap (Bab 2), (2) **Paket Keputusan Owner** K-01 … K-42 (Bab 3), (3) riwayat keputusan lama yang sudah final (Bab 4).

---

## 1. Cara Pakai

1. **Owner** cukup baca Bab 3. Tiap keputusan punya pilihan dan **Default (rekomendasi)**. Jawab ke Claude Code, misalnya: `Setuju semua default kecuali K-07 pilih (a) dan K-22 pilih (b).`
2. **Claude Code** lalu menjalankan Roadmap R0.3: menulis keputusan ke GDD / Quest / GUI, mengubah status di Bab 3 jadi `DIPUTUSKAN <tanggal>`, baru setelah itu mengerjakan kode (Roadmap Fase 1).
3. Kolom **"Beres di"** pada Bab 2:
   - `GDD v8.0` = sudah dirapikan langsung di dokumen baru (kesalahan tulis / basi, tidak mengubah desain).
   - `K-xx` = butuh keputusan owner (Bab 3).
   - `R-x.y` = butuh pekerjaan kode / aset (lihat `06_Roadmap.md`).
4. Severity: **Tinggi** = salah desain / bikin pemain buntu / melanggar Prinsip; **Sedang** = membingungkan Claude Code atau pemain; **Rendah** = kerapian.

---

## 2. Temuan

Ringkasan: **83 temuan** — 14 Tinggi, 37 Sedang, 32 Rendah.

### 2.1 Struktur & versi dokumen

| ID | Sev | Lokasi | Masalah | Beres di |
|----|-----|--------|---------|----------|
| A-01 | Tinggi | v7.7 Bab 4.4 | 15 baris Lampiran D (#36–#49, #45 dobel) **tertempel di dalam tabel Unlock** (di antara Lv 35 dan Lv 45). Lampiran D sendiri berhenti di #35. Claude Code bisa salah baca tabel unlock. | GDD v8.0 (tabel bersih), isi #36–#49 masuk K di Bab 3 |
| A-02 | Sedang | v7.7 Bab 4.4 | Urutan Lv 5 sebelum Lv 4; Lv 8 dua baris; fitur hasil Quest v0.3 (Hutan, Meja Crafting, Hias, Skill, Kandang, Bantu, Kanal) tidak tercantum. | GDD v8.0 Bab 4.4 |
| A-03 | Sedang | v7.7 Bab 4.4 vs 6.4 | Tabel Unlock beda dengan tabel ikan (LOCKED): Sepat hilang (ikan Lv 2), Tawes tidak ada (Lv 6), **Patin** Lv 8 vs Lv 10, **Baung** Lv 10 vs Lv 12, 3 Legenda tidak tercantum. | GDD v8.0 (ikut tabel ikan 6.4) |
| A-04 | Sedang | v7.4–v7.7 | 4 file gameplay hidup bersamaan, isi ±90% sama. v7.4 berjudul "v7.3". Changelog urut 0.3 → 0.3.4 → 0.3.3 → 0.3.2 → 0.3.1; catatan "0.3 sampai 0.3.7" padahal cuma sampai 0.3.4. | GDD v8.0 (satu file, riwayat di git + Bab 4 file ini) |
| A-05 | Rendah | v7.7 Penutup, header | Penutup masih "Single Source of Truth v7.3"; header "menggantikan v1.0 sampai v7.2". | GDD v8.0 |
| A-06 | Sedang | v7.7 Bab 14.8, 16.6, 0.3.2 #12 | Status basi: 14.8 Starter Chain "USULAN, belum dikerjakan" padahal sudah diganti rantai Quest v0.3; 16.6 "BELUM DIKERJAKAN" padahal selesai (Roadmap §9.1); changelog #12 superseded tapi masih tertulis. | GDD v8.0 |
| A-07 | Rendah | v7.7 Bab 28 | `PlayerData.version = 72`, Roadmap menyebut kode sudah 74 → 75. | GDD v8.0 (rujuk kode) |
| A-08 | Sedang | Roadmap, Lampiran D, Test Plan | ID tugas dipakai ulang: `B-1` = cutscene Kak Fajar (Roadmap §12) **dan** waktu gigitan (Lampiran D #47); `B-2` = tombol ♥ **dan** toast. UI-4 sudah dikerjakan sebagai ST-3 tapi UI-4 masih `[ ]`. | Roadmap v8.0 (ID baru `R<fase>.<n>`, unik) |
| A-09 | Rendah | Roadmap | Sub-bab 12.1, 12.2, 12.4, 12.3 tidak urut; §2 "Jangan ubah v7.4.md"; §1.1 / P2-8d masih "MQ4 Lv 3". | Roadmap v8.0 |
| A-10 | Rendah | Roadmap §5 | Butir basi: #6 "FeedMax 3→5 di Skill Lv ≥ 1" (sekarang Lv 3), #8 "biaya Koin skill tidak di-charge" (sekarang 3.000/level, ST-2). | Roadmap v8.0 |
| A-11 | Rendah | Roadmap P2-10 vs §9, Test Plan A-1 | Error selene lama disebut 5 (termasuk FishSpotFx) dan 4. | Roadmap R1.9 (bersihkan semua) |
| A-12 | Rendah | Quest v0.3 header, Bab 6 | Header "DRAFT, belum SSOT" padahal sudah disetujui; judul Bab 6 "kalau v0.2 disetujui". | Quest & Naskah v1.0 |
| A-13 | Rendah | GUI v0.1 header, 6.2, Bab 10 | Merujuk `docs/UIUX_Spec.md` yang tidak ada; 6.2 dan Bab 10 masih "garis dahan visual saja" padahal prasyarat skill sudah nyata; 6.2 "biaya 1 SP" (harusnya 1 SP + 3.000 Koin). | GUI v1.0 |
| A-14 | Rendah | Test Plan B-DOC-10 | Rujuk "Bab 16.5" untuk langkah FTUE (seharusnya 16.2). | QA v1.0 |
| A-15 | Rendah | v7.7 Bab 7.2, 11, 21 | 7.2 "Bundel Kakek, Bab 14.5" (14.5 = Agenda, harusnya 14.6). Baris Varian Bab 11 berisi teks coretan ("sudah dihitung...? Tidak... Koreksi:"). Bab 21 Banner masih menyebut Pelangi. | GDD v8.0 |

### 2.2 Level, unlock & pace

| ID | Sev | Lokasi | Masalah | Beres di |
|----|-----|--------|---------|----------|
| A-16 | Tinggi | Bab 9.2 vs 4.4 | **Resep terbuka sebelum bahannya ada.** Tier 1 (Lv 6): Sup Ubi butuh Jahe (Lv 22), Jus Jagung butuh Tebu (Lv 15), Sambal Tomat butuh Cabai (Lv 8). Tier 2 (Lv 15): Es Tebu butuh Melati (Lv 30); Gulai Telur & Pepes butuh Jahe (Lv 22). Tier 3 (Lv 35): Es Krim Durian & Durian Goreng butuh Durian (Lv 45). Di Lv 6 cuma 4 resep yang bisa dimasak. | K-02 → R1.1 |
| A-17 | Tinggi | Bab 7.2, 16.5, 30.1 | Tabel Kolam: Tanah **Lv 3**, padahal Bab 4.4 dan keputusan #30 **Lv 4**. Checklist 30.1 masih "MQ4 / Bundel Kakek Lv 3". | GDD v8.0 |
| A-18 | Sedang | Bab 4.2 | Contoh "Lv 59→60: 2.170 XP" salah. Rumus `200 + 30 × 59` = **1.970**. (Total 64.900 benar.) | GDD v8.0 |
| A-19 | Sedang | Bab 0.2, 17.2 vs Quest v0.3 §3, Lampiran D #11 | **Pace XP bertabrakan.** Bab 17.2: Lv 1–20 = 14 jam → 9.500 XP ≈ 680 XP/jam. Bab 0.2: santai Lv 26 di hari 30 (22,5 jam) ≈ 655 XP/jam. Quest v0.3: ±1.500 XP/jam (Lv 10 di menit 130). Lampiran D #11: ±972 XP/jam. Kalau 1.500 benar, Lv 20 tercapai ±6,3 jam, bukan 14. | K-11 → R9.1 |
| A-20 | Sedang | Bab 16.2, 14.2 MQ1 vs Lampiran D #11 | Bibit gratis FTUE: "4 Bibit" vs "6 bibit gratis" (dipakai menghitung Lv 2 = 230 XP). | GDD v8.0 (6, ikut hitungan kode) — Claude Code cek di R0.4 |
| A-21 | Sedang | Bab 4.2 vs Roadmap §5 #5 | Bab 4.2 menyebut XP dari Nambang, kode memberi 0 XP per pukulan. Nambang jadi satu-satunya kegiatan aktif tanpa XP. | K-08 → R1.6 |
| A-22 | Sedang | Skill Tree Bab 1, Bab 5.2 | Skill pertama (Player Lv 2) butuh 3.000 Koin, padahal di Lv 2 pemain juga butuh 1.050 Koin untuk petak ke-7. SP awal menganggur lama, pohon skill terasa "terkunci". | K-12 → R1.8 |
| A-23 | Sedang | Bab 0.2, 17.4 vs Skill Tree Bab 4 | Rasio faucet/sink Lv 60: 71–73% (GDD) vs 79–81% (Skill Tree, mepet batas 80%). Faucet belum dihitung ulang setelah **Super dihapus** (pendapatan Nanem turun ±5–10%). | R9.1 (simulasi) |

### 2.3 Quest & FTUE

| ID | Sev | Lokasi | Masalah | Beres di |
|----|-----|--------|---------|----------|
| A-24 | Tinggi | Bab 14.2 vs Quest v0.3 | **Dua sistem nomor quest.** Bab 14.2 MQ1–MQ12 (lama) vs Quest v0.3 M1–M9 + MQ11/MQ12. MQ1–3 sudah jadi FTUE; M1, M2, M4 tidak ada di 14.2. Pemberi beda (MQ4 "Mak Sari datang" vs M3 Kak Fajar). Hadiah beda (MQ4 "Kolam Kakek (Blueprint)" vs M3 "+300 Koin +60 XP"; MQ7 "1 Tungku" vs M6 "200 Koin"; MQ9 "200 Koin + Slot Warung" vs M7 "200 Koin"). | GDD v8.0 (tabel lama dihapus, Quest v1.0 satu-satunya sumber) |
| A-25 | Tinggi | Bab 14.2, Naskah vs Bab 15.4 | MQ11: dokumen dan Naskah "Legenda **ATAU** Prima Late"; syarat title Penakluk Legenda (diambil dari kode) "Legenda **DAN** Prima Late". | K-13 → R1.5 |
| A-26 | Tinggi | Bab 6.6, 0.1, 2.2, 17.4 vs Roadmap Q-1 | **Sistem Bubu belum ada di kode** (M8 `blocked`). Padahal Bubu = hook retensi utama (Bab 0.1), ada di sesi contoh, dan masuk sink 17.700 Koin. | R2.1 |
| A-27 | Tinggi | Quest v0.3 M1 vs Roadmap Q-2 | **Agenda tidak punya UI klien**, tapi M1 langkah 1 "Buka Agenda" dan Quest v0.3 §5 "Tombol Agenda muncul di M1". | R2.2 |
| A-28 | Sedang | Roadmap §9.1 vs Quest v0.3 | Agenda di kode dibuka oleh `starter_pagar` (starter chain lama), Quest v0.3 bilang dibuka oleh M1 (Lv 2). Belum jelas sisa starter chain sudah dibersihkan. | R0.4 (cek kode); ditutup R2.3 (K-74: tidak ada sisa di `src/`) |
| A-29 | Tinggi | Bab 16.4 (LOCKED) vs Naskah 1.3 + Roadmap playtest 2 | Bab 16.4: "GUI Jual tetap dibuka, cutscene tidak boleh jual tanpa GUI". Kode & Naskah: jual lewat pilihan "Jual semua" di bubble, **tanpa GUI**. Perubahan ini dari playtest owner. | GDD v8.0 (ikut kode, sudah dites owner) |
| A-30 | Sedang | Bab 16.1 vs Roadmap playtest 2 | 16.1 "Siram opsional (siram ATAU panen)"; kode: langkah siram hanya selesai dari menyiram. | GDD v8.0 (wajib di tutorial, opsional di luar) |
| A-31 | Sedang | Bab 16.2 vs Naskah, kode | Urutan tabel FTUE (Mancing 2:00 sebelum Jual Pak Udin 3:00; Panen sebelum Siram) beda dengan Naskah dan kode (Cangkul → Tanam → Siram → Panen → Jual ke Pak Udin → Kak Fajar → Mancing → Jual ikan). Tabel punya 4 baris kosong; judul "10 Menit" padahal ±3,5 menit. | GDD v8.0 |
| A-32 | Sedang | Bab 16.2 | Catatan "Tombol Mancing muncul saat dekat **dermaga**" padahal mancing FTUE di sungai lahan. | GDD v8.0 |
| A-33 | Rendah | Naskah 1.4, Test Plan D-1, Bab 16.2 | Hadiah Kak Fajar: Naskah "joran bambu sama umpan", Test Plan "Joran Bambu + Pelet", GDD hanya Joran. Pelet (+15% Mid) tidak berguna di sungai lahan (Early saja). | K-21 |
| A-34 | Sedang | Bab 14.4 | Hadiah side quest tidak terdefinisi / bentrok: "Bubble Cepat ekstra" (tidak ada sistemnya), "Gembor (kosmetik)" (tidak ada sistem kosmetik alat), "Warna dinding spesial" (kode jadi Title "Dinding Spesial"), "Resep Pepes Ikan Mid" (resep tidak dikunci per quest, sudah terbuka di Tier 2). | K-15 → R1.5 |
| A-35 | Sedang | Bab 14.4 | Kucing Alun-alun & Joran Hilang belum punya sistem (Roadmap P2-10). | K-16 → R2.4 |
| A-36 | Sedang | Lampiran D #27 | 5 side quest + Kolektor tidak punya Naskah, jadi mulai otomatis tanpa dialog (beda dari aturan "dialog dulu, baru mulai"). | K-14 (Quest v1.0 berisi naskah usulan) |
| A-37 | Sedang | Quest v0.3 §4.4 vs GDD | Lumbung Lv 12 (Quest) vs Lv 15 (Bab 14.6); "Rumah 2 Lantai (Lv 40)" tidak ada di GDD; "Bubu Besi Lv 40" tidak ada di tabel Bubu. | Quest v1.0 (ikut GDD, Rumah 2 Lantai dipindah ke Penyempurnaan P-17) |
| A-38 | Rendah | Quest v0.3 S7 | S7 Sawah: tanam + panen Padi (2 jam) melanggar aturan "tiap quest ±2–5 menit". Side tidak menahan apa pun, jadi dibiarkan tapi ditandai. | Quest v1.0 |
| A-39 | Rendah | Naskah M3 vs GUI §5 | Naskah "Tombol Kolam sudah ada di menu Garap", GUI: Kolam = tombol dock sendiri. | Quest v1.0 (teks ikut GUI: "Tombol Kolam sudah muncul di bawah") |
| A-40 | Rendah | Naskah S4 vs Bab 3.1, 10.1 | Naskah "Rangkanya masih kokoh" (rumah Kakek sudah ada) vs "lahan awal bersih, tanpa bangunan rusak" dan "Pak Amran hadiah rangka rumah pertama". | GDD v8.0 (rangka rumah = pengecualian tertulis) |
| A-41 | Rendah | Skill, Bab 14.4, Quest S6 | Nama "Tetangga Baik" dipakai 3x: skill, side quest Bantu 10 lahan, S6 "Tetangga Baik (kenalan)". | Quest v1.0 (side jadi "Ringan Tangan", S6 jadi "Kenalan Tetangga") |
| A-42 | Rendah | Roadmap Q-2d | Prompt Kerja Bakti digerbang fitur Gerobak (terbuka di M1, Lv 2). Tidak tertulis di GDD. | GDD v8.0 Bab 13.4 |

### 2.4 Mancing & dunia

| ID | Sev | Lokasi | Masalah | Beres di |
|----|-----|--------|---------|----------|
| A-43 | Tinggi | Bab 3.3, 6.1 vs 2.2 | **Hujan menghukum pemancing.** "Gigitan 2x lebih lama" diterapkan sebagai waktu tunggu 2x (3–6 → 6–12 dtk). Bertentangan dengan Bab 2.2 ("Mancing sering pas hujan"), Bab 3.3 ("hujan bantu sedikit") dan tagline. Kemungkinan maksud asli: jendela gigitan lebih panjang. | K-01 → R1.2 |
| A-44 | Sedang | Bab 3.1, 4.4, 6.4, Roadmap §6 | Danau & Spot 4 tidak ada di map, tapi masih disebut (Lv 18 "Spot 4", tabel ikan "(Spot 4 belum ada)", Roadmap "4 spot"). Aturan "jangan ubah map" bikin buntu. | K-22 |
| A-45 | Sedang | Quest S9, Bab 14.6, Roadmap §5 #12 | "Empang" punya 3 arti: Kanal Timur publik (S9, id kode `empang`), Bundel "Empang & Dermaga Kakek" (spot pribadi Lv 30), "Empang = 1 token kolam gratis". Id kode juga membingungkan: kanal barat = `sungai`, sungai lahan = `sungai_lahan`. | K-23 + tabel alias di GDD Bab 3.1 |
| A-46 | Sedang | Bab 6.1 vs Lampiran D #26 | "Jalan menjauh >8 stud = pancingan ketarik" vs kode: pemain dikunci saat memancing + watchdog server 24 stud. | K-25 |
| A-47 | Rendah | Bab 3.1, 4.4 | Istilah "Pro Mancing / Basic Mancing" masih dipakai padahal prompt itu dihapus v7.5. | GDD v8.0 |
| A-48 | Rendah | Bab 10.1 | Lapak Kak Fajar "Pinggir Kanal" — kanal barat atau timur tidak disebut. Naskah: "pinggir kanal alun-alun". | GDD v8.0 (alun-alun, dekat Kanal Barat) — cek di Studio R0.4 |
| A-49 | Sedang | Bab 6.4, 6.5, 3.3 | Belut Emas hanya saat Hujan Petir. Petir 15% × hujan 20,7% waktu ≈ **1,9 menit per jam**. Dengan pity 200 lemparan, 1 ekor butuh puluhan jam online. | K-07 |
| A-50 | Rendah | Skill Joran Kuat, Bab 9.4 | "Kotak tarik +2%/lv" dan buff "+10% lebih lebar": tidak jelas poin persen (30% → 32%) atau relatif (30% × 1,02). | GDD v8.0 (Claude Code tulis dari kode di R0.4) |

### 2.5 Ekonomi, resep, kolam

| ID | Sev | Lokasi | Masalah | Beres di |
|----|-----|--------|---------|----------|
| A-51 | Tinggi | Bab 9.2 | **Sambal Tomat rugi**: bahan 394 Koin (4 Tomat + 2 Cabai), jual 320. Lima resep lain di bawah aturan 1,5–1,8x (Bab 9.1): Tumis Kangkung 1,19x; Selai Stroberi 1,10x; Kopi Tubruk 1,09x; Teh Melati 1,07x; Es Krim Durian 1,30x. Pemain lebih untung jual mentah. (Total 6 resep di bawah aturan pada temuan ini; K-03 kemudian menyetel 9 harga, termasuk 3 turunan.) | K-03 → R1.1 |
| A-52 | Sedang | Bab 7.1, 9.2 | Pakan Jagung: 5 Jagung (550 Koin) → 6 jatah pakan (nilai 90 Koin). Disebut "alternatif gratis", nyatanya rugi ±6x. | K-04 |
| A-53 | Tinggi | Bab 9.1 vs Skill Rasa Prima, Bab 11 | Kualitas olahan = kualitas bahan tertinggi (pasti, tanpa roll). Ikan Early Goreng (ikan + Garam) dan Telur Asin (telur + Garam) **tidak punya bahan berkualitas** → hanya bisa Biasa → **4 entri Album Dapur mustahil**. Skill Rasa Prima "peluang Olahan Prima" bertentangan dengan aturan tanpa roll. | K-05 → R1.3 |
| A-54 | Sedang | Prinsip 1 vs Bab 5.2, Lampiran D #14 | Prinsip 1 "hapus bangunan refund 100%" vs petak 50% dan Kolam memakai `REFUND_RATE` (bukan 100%). | K-09 |
| A-55 | Sedang | Bab 7.2 vs Roadmap B-3, 12.3 | Kolam punya dua model: breeding (GDD) vs stok setor / ambil / mancing (kode B-3) + timer "Ambil Ikan" lama yang belum diputuskan. | K-10 |
| A-56 | Rendah | Bab 13.4 | Diskon Warga "bibit, umpan, pakan di Toko Pak Udin" — umpan dijual Kak Fajar. | K-41 |
| A-57 | Rendah | Bab 10.1 vs 4.1 | Bang Jali "beli semua barang 90%" vs Bahan tidak punya harga jual. | K-42 |
| A-58 | Rendah | Bab 9.3, 14.2 | Biaya bangun Warung tidak ditulis; jumlah slot (1) vs hadiah "Slot Warung" MQ9. | GDD v8.0 (1 slot, hadiah slot dihapus sesuai kode) + R0.4 cek biaya |
| A-59 | Rendah | Bab 4.1, 10.3 | Sumber Koin tidak menyebut Order, Login, Hadiah Main, Season, Like, Bantu. | GDD v8.0 |
| A-82 | Rendah | Bab 6.3, 17.5 vs 8.1 | Syarat level alat lebih rendah dari bahannya: Joran Kayu (Lv 2, butuh Bambu), Gembor Seng & Kapak Besi (Lv 3, butuh Kayu/Batu) baru bisa di Lv 4 (Hutan); Sepatu Bot (Lv 2) & Joran Pusaka (Lv 10) butuh Ijuk (Lv 15). Pemain bisa bingung "kok tidak bisa beli". | GDD v8.0 (catatan) + GUI toko tampilkan bahan kurang |
| A-83 | Rendah | Bab 10.2 vs Naskah M5 | Pak Udin hanya membeli "hasil mentah (tanaman)", tapi Naskah M5 menyuruh jual telur ke Pak Udin. Penjual produk ternak (telur, susu) tidak tertulis. | GDD v8.0 (Pak Udin beli telur & susu, ikut Naskah) + R0.4 cek kode |

### 2.6 Kualitas & Album

| ID | Sev | Lokasi | Masalah | Beres di |
|----|-----|--------|---------|----------|
| A-60 | Sedang | Bab 11 | Album Sungai menghitung 3 Legenda × 4 ukuran (Jumbo 5%), padahal tiap Legenda butuh sampai 200 lemparan di kondisi tertentu. Album 100% praktis mustahil. | K-06 |
| A-61 | Rendah | Bab 8.5 | Set Kampung memuat "Sumur Tua", Set Kandang memuat "Lumbung Mini" — sama atau beda dengan Bundel Sumur Tua / Lumbung? | GDD v8.0 (Sumur Tua set = hasil Bundel; Lumbung Mini = dekor kecil terpisah) |

### 2.7 Hadiah, Bunga, monetisasi

| ID | Sev | Lokasi | Masalah | Beres di |
|----|-----|--------|---------|----------|
| A-62 | Tinggi | Bab 15.4 vs 29 | Title Kebun Favorit (200 like) memberi Peti Bunga (25 Bunga) → **Bunga dari Like**, dilarang Bab 29. | K-28 → R1.5 |
| A-63 | Sedang | Bab 18.2, 15.3, 14.6 | Tabel Bunga (~240/bulan) mencampur sumber rutin dan sekali-jalan (Title, milestone Album, Pencapaian). Baris Peti 60 menumpang sumber yang juga dihitung di baris Album / Season / Pencapaian (dobel). Bundel: "10 Bunga tiap bangunan" vs M9 "300 Koin + 5 Bunga". | K-31 |
| A-64 | Sedang | Bab 19 | Season 1 mulai **1 Desember 2026** (8 hari dari audit) padahal game belum rilis. | K-29 |
| A-65 | Rendah | Bab 18.4 | Harga Pack Bunga ditulis dalam Rupiah; Roblox menjual Developer Product dalam Robux. | K-32 |
| A-66 | Rendah | GUI Bab 10 | Mockup Season masih angka lama (50 Koin/hari, Bunga hari 7/14/21/30, tombol Premium 150 aktif) vs v7.6 (hadiah tiap 5 hari, Premium "Segera hadir"). | GUI v1.0 (catatan) |

### 2.8 Prinsip & sosial

| ID | Sev | Lokasi | Masalah | Beres di |
|----|-----|--------|---------|----------|
| A-67 | Tinggi | Prinsip 16 vs Quest S6, Bab 14.4, Skill, 15.4 | **Game tidak bisa lengkap kalau main sendiri**: S6 "Bantu 1 lahan pemain lain" (pembuka fitur Bantu), side "Bantu 10 lahan", skill Tetangga Baik, title Kebun Favorit (200 like). | K-17 → K-73 (Bantu disembunyikan, Kebun Warga dibatalkan); K-28; R2.5 |
| A-68 | Sedang | Bab 8.7 vs 12.5 | "Bagikan kode Blueprint ke teman" vs "chat tidak bisa kirim kode". Tidak ada jalan berbagi. | K-39 → R2.6 |

### 2.9 GUI

| ID | Sev | Lokasi | Masalah | Beres di |
|----|-----|--------|---------|----------|
| A-69 | Tinggi | Bab 23 vs kode F-1, Test Plan B-UI-6 | Tab Tas: GDD (Tanaman / Ikan / Olahan / Bahan / Lainnya) vs kode (Semua / Bibit / Panen / Ikan / Alat / Umpan). **Olahan dan Bahan tidak punya tab**, padahal Makan olahan lewat Tas (GUI 6.3, 6.9). | K-33 → R1.7 |
| A-70 | Sedang | GUI 5.1 vs kode F-2/B-2 | Zona atas-tengah dipakai dua komponen: Bubble Instruksi dan toast stack. Bisa saling timpa. | K-40 |
| A-71 | Sedang | GUI 6.2 vs Bab 10 vs kode | Ukuran node skill: 64 px (GUI 6.2), 44 px mockup / 40 implementasi (GUI 10), kode 40. | GUI v1.0 (40) |
| A-72 | Rendah | GUI 4.5 vs Changelog 0.3.4 #7 | Coachmark 50/55 (GUI) vs 50/60 (kode); toast juga 60 → dua lapisan di angka sama. | GUI v1.0 (tabel ikut kode, catatan bentrok) + R3.7 | **Status 2026-11-23: tertutup.** Overlay coachmark dihapus (GUI 4.6); tidak ada lagi lapisan gelap yang bertabrakan dengan toast.
| A-73 | Rendah | GUI 5.1 vs UI-B1 | Tinggi maks bubble 72 / 96 px sudah dihapus di kode (tinggi ikut teks). Dokumen belum diubah. | GUI v1.0 |
| A-74 | Sedang | GUI 6.3, §9 vs Q-2 | GUI: tombol HUD Dapur dihapus; kode Q-2 masih menggerbang "tombol HUD Dapur". Keputusan GUI §9 #2–#5 belum ada. | K-34 |
| A-75 | Rendah | Lampiran D #39, #43 | Ikon Acara, Skill, umpan belum ada (placeholder teks / ikon "tas"). | R4.2 |
| A-76 | Rendah | GUI §5, Bab 11 | Kolom menu tidak memuat Album dan Surat; Bab 11 bilang "Album dibuka dari HUD". Letak tombol Album / Surat tidak tertulis. | GUI v1.0 (diusulkan masuk tab Warga & Papan Hari Ini) → K-34 |

### 2.10 Proses & cakupan

| ID | Sev | Lokasi | Masalah | Beres di |
|----|-----|--------|---------|----------|
| A-77 | Sedang | Roadmap | Banyak hal "belum diuji di Studio" tersebar (6 animasi, timing B-1, HUD 4 resolusi, Q-1…Q-4, UI-1, UI-3, ST-3). Tidak ada satu daftar playtest terkumpul. | QA v1.0 Bab D |
| A-78 | Sedang | Roadmap §6, §7 | Tidak ada daftar aset konkret (3D, animasi, VFX, SFX, musik, ikon). Hanya "worker 3d-meshes / animation / vfx / sfx". | `04_Asset_Bible.md` + Roadmap Fase 4–7 |
| A-79 | Sedang | Quest v0.3 §4.4, Bab 14.3 | Tidak ada konten Main Quest Lv 10–60 ("detail di v0.4"), teks Surat Kakek 30 belum ada, tidak ada rencana rilis. | Penyempurnaan P-03, Roadmap Fase 8 & 11 |
| A-80 | Rendah | Changelog v7.2 #1 | Klaim "Roblox mewajibkan game baru 16+" tidak bisa diverifikasi dari dokumen. | Roadmap R11.2 (cek saat isi kuesioner maturity) |
| A-81 | Sedang | Bab 8.3, 24 | Tidak ada anggaran part / triangle. 8 lahan × 800 piece = 6.400 piece hias + tanaman + 32 spot di server 8 orang, target HP 4GB. | Asset Bible Bab 2 + R10.3 |

---

## 3. Keputusan Desain K-01…K-83 (K-01…K-66 SEMUA DIPUTUSKAN; K-67…K-83 di 3.6)

**Status: semua `DIPUTUSKAN`.** Owner tidak punya pekerjaan di bab ini. Keputusan diambil oleh Claude (atas mandat owner: "putuskan semuanya"), memakai **Default** tiap butir, dengan **satu pengecualian: K-16 = (b)**. Claude Code langsung menerapkan; tidak perlu menunggu jawaban.

Cara owner memberi masukan: lewat playtest (`09_Playtest_Checklist.md`). Masukan yang mengubah keputusan dicatat sebagai **K-nn rev.** di bab ini (tanggal + alasan), bukan dengan menulis ulang dokumen lain secara diam-diam.

### 3.0 Tabel Keputusan Final

| K | Keputusan final | K | Keputusan final |
|---|-----------------|---|-----------------|
| K-01 | (b) jendela gigitan 2x saat hujan | K-22 | (a) hapus Danau/Spot 4; Lv 18 = Kanal Timur malam |
| K-02 | (a) Jahe Lv 6, Tebu Lv 8, Melati Lv 15 | K-23 | Kanal Barat / Kanal Timur / Sungai Lahan |
| K-03 | (a) harga resep baru | K-24 | Ikan Late hanya di Kanal Timur |
| K-04 | (a) 1 Jagung → 6 jatah | K-25 | pemain dikunci saat mancing + watchdog 24 stud |
| K-05 | (a) kualitas dari ukuran/Mood Hujan | K-26 | terima `biteMult` dari kode |
| K-06 | (b) Legenda: ukuran yang belum dimiliki | K-27 | jual tutorial dalam 25 stud |
| K-07 | (b) Hujan Deres atau Petir | K-28 | Kebun Favorit tanpa Peti Bunga |
| K-08 | (b) Nambang 2 XP/bahan (disetel di R9.1) | K-29 | Season 1 mulai hari rilis |
| K-09 | (a) bangunan 100%, petak 50% | K-30 | Premium "Segera hadir" |
| K-10 | (a) hapus timer kolam | K-31 | Tabel Bunga: Rutin vs Sekali jalan |
| K-11 | (a) target 55–70 jam tetap acuan | K-32 | Robux: **75 / 150 / 300 / 600** (lihat bawah) |
| K-12 | (a) biaya skill 1.000…5.000 | K-33 | 8 tab Tas |
| K-13 | (a) ATAU | K-34 | HUD baru (semua poin) |
| K-14 | (a) pakai naskah usulan | K-35 | ikon per skill di node |
| K-15 | semua seperti usulan | K-36 | Hadiah UI sisa (semua poin) |
| **K-16** | **(b) TUNDA ke Update 1; quest disembunyikan** | K-37 | teks gerbang & Kerja Bakti |
| K-17 | (a) Kebun Warga | K-38 | terima semua deviasi kecil |
| K-18 | hapus Warga Teladan | K-39 | Blueprint: kirim ke pemain |
| K-19 | event selesai = semua Pesanan Tamu disetor | K-40 | toast turun di bawah bubble |
| K-20 | terima 3 baris perkenalan | K-41 | Diskon Warga: Pak Udin + Kak Fajar |
| K-21 | (a) hadiah tutorial = Cacing | K-42 | bahan tidak bisa dijual |

### 3.0b Tabel Keputusan K-43…K-66 (ditambahkan 2026-11-23)

Keputusan Putaran 2 dan keputusan otomatis (detail lengkap di 3.6). Kolom "Diterapkan di" = bab dokumen yang memuatnya.

| K | Hasil (ringkas) | Diterapkan di |
|---|-----------------|---------------|
| K-43 | Kolam Tanah dibuka Lv 4 (kode Lv 3 → Lv 4) | GDD 6 (lokasi "Kolam pemain Lv 4"); `Config/Ranch` |
| K-44 | Pack Bunga 700 = `bunga_xl` (id 0, belum bisa dibeli) | GDD 18.4 |
| K-45 | Mujair dan Nila juga bisa di kolam | GDD 6.4 (Lokasi tambahan) |
| K-46 | Basis ukuran ikan 40 / 40 / 15 / 5 | GDD 6.4 |
| K-47 | Legenda 0,5% per lemparan | GDD 6.5 |
| K-48 | Koin awal 100, Bunga awal 10; Album ladang & sungai 300 Koin | GDD 4.1 |
| K-49 | Hujan tidak menggandakan waktu tunggu; tidak ada batas waktu gigitan | Audit 3.6; GDD 6 (lihat koreksi D3) |
| K-50 | Dinding Spesial = warna ke-13 (title) | GDD 8 (tabel title) |
| K-51 | Dialog side quest memakai id penuh (bug) | 03 Bab 6.3 |
| K-52 | Album Rumah = 33 entri di kode; 47 piece = konten | GDD 11 (lihat koreksi D3) |
| K-53 | Garap: sorot dan tanam pada titik yang sama (bug) | Audit 3.6 (perilaku, tidak mengubah angka GDD) |
| K-54 | Tutorial: 5 Garap lagi, 6 bibit gratis, tunggu semua, baru Pak Udin | GDD 16.2 |
| K-55 | Pancing dan umpan lewat Pakai di Tas; umpan habis → pindah | GDD 6.3 |
| K-56 | Harian/Mingguan: templat eligible saja; Bantu lahan → Season | GDD 14.1 |
| K-57 | Event hanya saat aktif; Pasar Malam tempat dunia; Lempar Gelang minigame | GDD 13.2, 13.4 |
| K-58 | Quest Season "Bantu 20 lahan" 500 Koin | GDD 19 |
| K-59 | Album dekor hanya entri yang sudah dibangun | GDD 11 |
| K-60 | Order mingguan 4 jenis, ×3, XP ×0,5 | GDD 14.7 |
| K-61 | Pemilih warna dinding = R3.9 | GDD 8.3 |
| K-62 | Gembor Emas kosmetik di tab Alat | GDD 5.5 |
| K-63 | Jual Semua hilang bersama E2 | GDD 10.2 |
| K-64 | Akses DEV: Studio atau UserId owner | GDD 29 |
| K-65 | Studio: profil gagal dimuat dibuat di memori | GDD 29 |
| K-66 | Bubu dijual Koin saja; bahan ditunda | GDD 6.6 |

**Alasan K-16 = (b):** game dibuat 100% lewat Claude Code, jadi scope rilis dijaga. Kucing Alun-alun dan Joran Hilang butuh sistem baru yang kecil tapi tidak dibutuhkan jalan cerita. Dampak: Title "Penyayang Kucing" ikut tertunda; kedua quest tidak muncul di Quest Log rilis; dikerjakan di Update 1 (R12.4).

**K-32 Robux (Pack Bunga):** 50 Bunga = 75 R$ · 120 = 150 R$ · 300 = 300 R$ · 700 = 600 R$ (≈ acuan Rp 15rb / 30rb / 60rb / 120rb). Nilai ini ada di `Config` dan boleh disetel saat R10.4 setelah melihat tabel harga Roblox saat itu; tidak perlu persetujuan owner.

**Kebijakan "belum ada di dokumen":** kalau Claude Code menemukan angka yang tidak ada di GDD, ia **memutuskan sendiri dengan angka paling konservatif**, mencatat `K-nn` baru berstatus `DIPUTUSKAN (otomatis)` di Bab 3.6, lalu lanjut. Tidak berhenti menunggu owner.

### 3.1 Angka & gameplay

**K-01 Hujan saat mancing** (A-43)
- (a) Tetap: waktu tunggu gigitan 2x saat hujan.
- (b) Waktu tunggu normal; **jendela gigitan** 2x lebih panjang (1,5 → 3 dtk), jadi hujan = lebih gampang tarik.
- **Default: (b).** Hujan jadi momen bagus, sesuai tagline.

**K-02 Bahan resep terbuka lebih lambat dari resepnya** (A-16)
- (a) Majukan unlock bahan: **Jahe Lv 6, Tebu Lv 8, Melati Lv 15**. Durian tetap Lv 45; kartu resep Tier 3 yang butuh Durian tampil "Butuh Durian (Lv 45)".
- (b) Biarkan; kartu resep tampil terkunci dengan alasan.
- **Default: (a).** Buff Tukang dan resep energi jadi terpakai sejak awal.

**K-03 Harga 9 resep (6 resep biasa + 3 turunan) di bawah aturan 1,5–1,8x** (A-51) — usulan angka (1,6x bahan, dibulatkan):

| Resep | Bahan | Jual lama | Jual baru |
|-------|-------|-----------|-----------|
| Tumis Kangkung | 135 | 160 | 220 |
| Sambal Tomat | 394 | 320 | 630 |
| Selai Stroberi | 2.000 | 2.200 | 3.200 |
| Kopi Tubruk | 2.760 | 3.000 | 4.400 |
| Teh Melati | 2.810 | 3.000 | 4.500 |
| Es Krim Durian | 3.240 | 4.200 | 5.200 |
| *Turunan (aturan branching):* Nasi Goreng Spesial | Sambal + 1.240 | 2.300 | 2.600 |
| *Turunan:* Nasi Padang Mini | Sambal + Telur Asin + 1.200 | 2.600 | 2.900 |
| *Turunan:* Kopi Susu Gula Aren | Kopi Tubruk + 480 | 3.800 | 5.200 |

- (a) Pakai angka baru. (b) Biarkan.
- **Default: (a).** Dampak faucet kecil (Olahan ±15% porsi), dicek di R9.1.

**K-04 Pakan Jagung rugi 6x** (A-52)
- (a) **1 Jagung → 6 jatah** (110 Koin bahan vs 90 Koin nilai pakan, hampir impas).
- (b) Biarkan 5 Jagung → 6 jatah.
- **Default: (a).**

**K-05 Kualitas olahan untuk bahan tanpa kualitas** (A-53)
- (a) Ikan: ukuran jadi kualitas (Kecil/Sedang = Biasa, Besar = Bagus, Jumbo = Prima). Telur & Susu: Bagus bila diambil saat Mood Hujan, selain itu Biasa. Garam & Daun Pisang netral. Rasa Prima = peluang **naik 1 tingkat** (+1%/lv), satu-satunya roll di Dapur.
- (b) Hapus entri Biasa-only dari Album (Album turun 4 entri) dan Rasa Prima diganti efek lain.
- **Default: (a).** Album tetap bisa 100%, Mood Hujan dapat arti baru tanpa buff pasif.

**K-06 Album Sungai: Legenda × 4 ukuran** (A-60)
- (a) Legenda dihitung 1 entri per jenis (Sungai 71, total Album **205**).
- (b) Total tetap 214; tangkapan Legenda berikutnya **selalu ukuran yang belum dimiliki** (4 tangkapan per Legenda = lengkap).
- **Default: (b).** Angka 214 yang sudah disepakati tidak berubah.

**K-07 Kondisi Belut Emas** (A-49)
- (a) Tetap Hujan Petir saja (±1,9 menit/jam).
- (b) **Hujan Deres atau Petir** (±5,6 menit/jam).
- **Default: (b).**

**K-08 XP Nambang** (A-21)
- (a) Tetap 0 XP (hapus Nambang dari daftar XP Bab 4.2).
- (b) **2 XP per bahan** yang didapat (1 putaran ±30–45 bahan = 60–90 XP). USULAN.
- **Default: (b).**

**K-09 Refund** (A-54)
- (a) Prinsip 1 diperjelas: **bangunan & dekor refund 100%** (termasuk Kolam, Kandang, Dapur, Warung). **Petak bukan bangunan**, refund 50% harga yang dibayar.
- (b) Semua 100% termasuk petak.
- **Default: (a).** Kolam `REFUND_RATE` jadi 1,0.

**K-10 Kolam: stok vs timer "Ambil Ikan"** (A-55)
- (a) **Hapus timer.** Ikan di kolam hanya dari setoran pemain + anak hasil breeding. Breeding memakai 2 ikan sejenis dari stok. Mancing di kolam mengambil dari stok.
- (b) Timer tetap sebagai bonus.
- **Default: (a).**

**K-11 Model pace XP yang jadi acuan** (A-19)
- (a) **Target jam Bab 17.8 (55–70 jam ke Lv 60) tetap acuan.** Angka Quest doc (±1.500 XP/jam) hanya untuk Lv 1–10. Simulasi R9.1 menentukan apakah XP per aksi perlu disetel.
- (b) Pakai 1.500 XP/jam untuk semua level, target jam diturunkan.
- **Default: (a).**

**K-12 Kurva biaya skill** (A-22)
- (a) Biaya per level skill **naik: Lv 1 = 1.000, Lv 2 = 2.000, Lv 3 = 3.000, Lv 4 = 4.000, Lv 5 = 5.000 Koin**. Total per skill tetap 15.000, total semua tetap 240.000.
- (b) Tetap 3.000 rata.
- **Default: (a).** Skill pertama terasa di Lv 2 tanpa mengubah total sink.

### 3.2 Quest & FTUE

**K-13 Syarat MQ11 Legenda Pertama** (A-25) — (a) **ATAU** (Legenda atau Prima Late), (b) DAN. **Default: (a)** (sesuai Naskah dan desain awal). Title Penakluk Legenda ikut syarat yang sama.

**K-14 Naskah untuk side quest tanpa dialog** (A-36) — (a) Pakai **naskah usulan** di `03_Quest_Naskah.md` Bab 5.3 (dialog dulu, baru mulai). (b) Biarkan mulai otomatis. **Default: (a).**

**K-15 Hadiah side yang tidak jelas** (A-34)
- Rumah Rapi → Title "Dinding Spesial" **+ 1 warna dinding spesial** (pilihan warna ke-13 di palet Hias).
- Tetangga Baik (Bantu 10 lahan) → 300 Koin saja ("Bubble Cepat" dihapus).
- Resep Mak → **200 Koin** (USULAN; resep Pepes sudah terbuka di Tier 2).
- Panen Prima → **skin Gembor Emas** (visual saja, tanpa stat).
- **Default: semua seperti di atas.**

**K-16 Kucing Alun-alun & Joran Hilang** (A-35) — (a) Bangun sebelum rilis. (b) Tunda ke Update 1 dan sembunyikan quest-nya. **FINAL: (b)** (menggantikan default (a), alasan di 3.0).

**K-17 Main sendiri tetap lengkap** (A-67)
- (a) Tambah **Kebun Warga**: 4 petak milik NPC di alun-alun, bisa disiram/dipanen 1x per hari dan **dihitung sebagai Bantu**. S6, side Bantu 10 lahan, dan skill Tetangga Baik jadi bisa solo. Hadiah Bantu di Kebun Warga sama.
- (b) S6 dan side Bantu jadi opsional, tidak dihitung ke apa pun.
- **Default: (a).**

**K-18 Title Warga Teladan** (D#22) — **Default: hapus** dari dokumen (tidak ada sumbernya).

**K-19 Definisi "event musiman selesai"** (D#21) — **Default: semua Pesanan Tamu event itu sudah disetor** → 1 Peti Bunga, sekali per event per tahun.

**K-20 NPC yang dikenal lewat tutorial & 3 baris perkenalan** (D#35, D#41) — **Default: terima** (Mak Sari, Pak Udin, Kak Fajar dikenal lewat tutorial; baris m1/s3/s4 versi tanpa perkenalan; pemberi quest yang belum pernah bicara tetap dapat sapaan pertama saat dialog Mulai).

**K-21 Umpan hadiah Kak Fajar di tutorial** (A-33) — (a) **Cacing** (cocok untuk sungai lahan), jumlah tetap seperti kode. (b) Tetap Pelet. **Default: (a).**

### 3.3 Mancing & dunia

**K-22 Danau & Spot 4** (A-44)
- (a) **Hapus dari desain.** Ikan tetap di lokasi kode (Kanal Barat / Kanal Timur). Unlock Lv 18 "Spot 4" jadi **"Kanal Timur malam"** (Tapah, Sidat, Belida, Ikan Dewa).
- (b) Tambah Spot 4 sebagai **prop saja** (dermaga kecil di ujung kanal timur), tanpa mengubah layout map.
- **Default: (a)** untuk rilis, (b) boleh di Update 1.

**K-23 Nama "Empang"** (A-45) — **Default:** nama pemain = **Kanal Barat** (id `sungai`), **Kanal Timur** (id `empang`), **Sungai Lahan** (id `sungai_lahan`). Kata "Empang" hanya untuk Bundel **"Empang & Dermaga Kakek"**. S9 diganti judul "Kanal Timur". Id kode **tidak** diganti (tabel alias di GDD Bab 3.1).

**K-24 Ikan Late hanya di Kanal Timur** (D#24) — **Default: ya.**

**K-25 Gerak saat memancing** (A-46, D#26) — **Default:** pemain dikunci selama memancing; watchdog server 24 stud sebagai pengaman; kalimat "8 stud" dihapus.

**K-26 `rod.biteMult` & kolam tanpa umpan** (D#47) — **Default: terima.** Claude Code menyalin angka `biteMult` per joran dari kode ke tabel Joran GDD 6.3. Kolam = aturan tanpa umpan (6–12 dtk).

**K-27 Jarak jual ke Kak Fajar tutorial 25 stud** (D#25) — **Default: terima.**

### 3.4 Hadiah, Bunga, monetisasi

**K-28 Title dari like** (A-62) — **Default:** Kebun Favorit tetap ada sebagai Title, **tanpa Peti Bunga**. Aturan umum: Title yang syaratnya bergantung pemain lain tidak memberi Bunga.

**K-29 Season** (D#20, A-64) — **Default:** daftar hadiah F2P tiap 5 hari (GDD Bab 19) diterima; **Season 1 mulai di hari rilis** (bukan 1 Des 2026), reset 05:00 WIB.

**K-30 Season Premium** — **Default:** tetap "Segera hadir" saat rilis; dibuka setelah owner menyetujui daftar kosmetik eksklusif (usulan di Penyempurnaan P-14).

**K-31 Tabel Bunga** (A-63) — **Default:** tabel 18.2 ditulis ulang jadi 2 bagian: **Rutin per bulan** (Login, Season F2P + peti hari 30, Event) dan **Sekali jalan** (Title, milestone Album, Pencapaian, Bundel, quest). Bundel: 10 Bunga per bangunan pulih **menggantikan** "5 Bunga" M9 (tidak dobel).

**K-32 Harga Robux** (A-65) — **Default:** owner menetapkan harga Robux per paket di R10.4; angka Rupiah jadi acuan saja.

### 3.5 GUI & teks

**K-33 Tab Tas** (A-69) — **Default:** `Semua · Bibit · Panen · Ikan · Olahan · Bahan · Umpan · Alat` (baris tab bisa digeser). Panen memuat tanaman + telur + susu.

**K-34 HUD** (GUI v0.1 §9 #2–#5, A-74, A-76) — **Default: ya semua:** kartu pemain pindah kiri atas; tombol HUD Dapur dihapus (Dapur dibuka Tombol Aksi dekat Tungku); ikon baru dibuat dengan ForgeGUI; Craft ikut satu slot Tombol Aksi. Album dan Surat masuk **Papan Hari Ini** (Penyempurnaan P-04).

**K-35 Label node skill** (D#40) — **Default:** nama di drawer; node pakai **ikon unik per skill** (16 ikon) + pil level `x/5`.

**K-36 Hadiah UI sisa** (D#34) — **Default:** node milestone 80 px; **Klaim Semua** lewat remote batch baru di server; Milestone Album hanya di Hadiah › Koleksi (dihapus dari tab Album); Login jadi 7 kartu, Peti Main jadi bar 0–60 menit, Peti Bunga jadi kartu besar (sesuai GUI 6.1).

**K-37 Teks** (D#37, D#46) — **Default:**
- Gerbang level: `Terbuka di Level {n}`. Gerbang quest tetap `Belum terbuka. Ikuti quest dulu.`
- Kerja Bakti: `Setelah hujan deres atau petir: pungut sampah di alun-alun. +15 Koin +3 XP per poin.`

**K-38 Deviasi kecil yang sudah jalan di kode** — **Default: terima semua:** panel Toko ukuran standar + gulir (D#36); label Quest Log "Tersedia" / "Berikutnya" (D#28); toast fade 0,25 dtk, reward popup & banner level bukan toast (D#44, D#48); Gembor 32 px, pil HUD 50 px (D#32); bubble: nama di atas teks, nama percakapan 14 px, inset 34 px sampai skin tipis ada (D#33).

**K-39 Berbagi Blueprint** (A-68) — **Default:** kode Blueprint hanya diketik di panel Blueprint (bukan chat); tambah tombol **"Kirim ke pemain"** untuk pemain di server yang sama. Chat tetap melarang kode.

**K-40 Bubble Instruksi vs toast** (A-70) — **Default:** Bubble Instruksi tetap atas-tengah; saat bubble tampil, toast stack turun tepat di bawah bubble (`UiKit.toastStack` membaca tinggi bubble).

**K-41 Diskon Warga** (A-56) — **Default:** berlaku di Pak Udin (bibit, pakan) **dan** Kak Fajar (umpan).

**K-42 Bahan bisa dijual?** (A-57) — **Default: tidak.** Bahan tidak punya harga jual di mana pun; Bang Jali membeli semua barang yang punya harga jual.

### 3.6 Log Keputusan Otomatis & Revisi dari Playtest

| ID | Tanggal | Isi | Alasan |
|----|---------|-----|--------|
| K-43 | 2026-11-23 | Kolam Tanah dibuka **Lv 4** (kode Lv 3). Diubah di `Config/Ranch` (R0.4). | GDD 7.2 = target; kode yang berubah |
| K-44 | 2026-11-23 | Pack Bunga 700 (GDD 18.4) ditambahkan sebagai `bunga_xl`, `id = 0` (Belum tersedia). `priceDraft` 459 = USULAN, hanya label cadangan. | Angka GDD; tanpa id tidak ada pembelian |
| K-45 | 2026-11-23 | **DIPUTUSKAN.** Ikan Mid **Mujair dan Nila** di kode juga bisa di `kolam` (Fish.locations). Kode dipertahankan; GDD 6.4 v8.2 menulis lokasi ini. Kolam memakai stok (B-3, K-26). | Mengubah lokasi bisa memutus stok kolam |
| K-46 | 2026-11-23 | **DIPUTUSKAN.** Basis ukuran (skill 0) sekarang = GDD 40/40/15/5. Sebelum: ambang Sedang 0,5 → 50/30/15/5 (simulasi 1.000 skor merata: S 501 / M 298 / L 154 / Jumbo 47). Sesudah: ambang Sedang 0,4 → S 402 / M 393 / L 156 / Jumbo 49. Modifier skill Ikan Besar tetap di atas. | Dicek simulasi Studio (Play, server) |
| K-47 | 2026-11-23 | **DIPUTUSKAN.** Bobot Legenda L = 0,5 (dari 1). Peluang per lemparan = 0,5% (basis 100k sampel: sebelum 1,019%, sesudah 0,479%; teoretis 0,5025%). GDD 6.5 tetap. | QA C-6 (sampel Studio) |
| K-49 | 2026-11-23 | K-01 "jendela gigitan 2x": tidak ada batas waktu sejak keputusan owner 16 Nov (ikan menunggu di kail), jadi jendela itu sudah terpenuhi. Hujan **hanya** tidak lagi menggandakan waktu tunggu (`BITE_RAIN_MULT` dihapus). Tidak ada mekanik baru. | Tidak ada tombol tarik dengan batas waktu untuk diperlebar |
| K-48 | 2026-11-23 | **DIPUTUSKAN.** Dokumen mengikuti kode: Koin awal 100, Bunga awal 10 (`Config/Economy`); hadiah kategori Album ladang & sungai 300 Koin (`Config/Book`). Ditulis di GDD v8.2 Bab 4.1. | Tidak ada angka desain lain |
| K-50 | 2026-11-23 | Palet dinding Hias: satu warna ke-13 (`Config/Decor` WALL_PALETTE_EXTRA, muted hangat) dibuka Title "Dinding Spesial". Tidak ada palet 12 warna di kode dan tidak ada pemilih warna di UI. Pemilih warna = tugas terpisah (belum ada R). | Kode tidak punya palet Hias |
| K-51 | 2026-11-23 | Dialog side quest: `prefixOf` memotong `side_*` menjadi `side` sehingga semua dialog side hilang. Sekarang id penuh. Naskah sesuai 03 Bab 6.3 (FINAL K-14). | Bug, bukan keputusan desain |
| K-52 | 2026-11-23 | Album Rumah: GDD 11 "80 piece", kode 33 entri. **Default: album pakai 33 entri.** 47 piece baru = konten (Fase 4 / Asset Bible), bukan angka yang bisa disetel. Kategori "Rumah lengkap" (title Juragan Pondok) mengikuti jumlah entri kode. | Konten belum ada |
| K-53 | 2026-11-23 | **DIPUTUSKAN (grup A, bug).** Garap: titik sinar ke lantai dibulatkan ke pusat sel terdekat; sorot dan tanam memakai titik yang sama (ketuk 1 = sorot, ketuk 2 = tanam). Keluar mode Garap menghapus outline kuning. Toast di bawah HUD Koin/Bunga (padding 12 px) dan di bawah Bubble Instruksi (K-40). Kartu pemain: pill "Lv n"; slot buff kosong disembunyikan. "!" di atas semua pemberi quest. Bang Jali sebelum S3: "Terbuka di Level {n}" (K-37); sesudah: "Jual semua panen (90%)". Joran pindah ke tab Alat. Sheet Acara tanpa teks terpotong. | Bug dari playtest owner putaran 1 (#6, #14–#18) |
| K-54 | 2026-11-23 | **DIPUTUSKAN (grup B, tutorial).** Setelah panen pertama: 5 Garap lagi, tanam ulang 6 bibit Kangkung gratis, tunggu SEMUA tumbuh dan panen, baru ke Pak Udin. Mancing (Kak Fajar): tangkapan 1–2 hanya bubble Instruksi "Coba lagi, ..."; tangkapan ke-3 cutscene "Kamu jago juga mancingnya, sini ikannya aku beli." lalu jual. Umpan hadiah cukup 3 lemparan. Total XP tutorial disesuaikan agar akhir tetap Lv 2. | Playtest putaran 1 (#1, #2) |
| K-55 | 2026-11-23 | **DIPUTUSKAN (grup C, UI mancing).** Pancing dan umpan punya tombol "Pakai" di drawer Tas; badge "Dipakai"; chip umpan HUD menampilkan umpan terpasang; habis → otomatis ke umpan berikutnya + toast. Default: pancing terbaik dan umpan pertama. `equippedRod` / `equippedBait` di PlayerData (versi naik, default untuk save lama); server memvalidasi. Tombol **Tarik** memakai slot Tombol Aksi yang sama dengan Pancing, label teks dulu (ikon Fase 4). **Mengganti D#42 / D#49 ("tanpa pemilihan umpan").** | Playtest putaran 1 (#3, #4) |
| K-56 | 2026-11-23 | **DIPUTUSKAN (grup D, quest & UI).** Pool Harian/Mingguan: tiap templat punya syarat fitur + level; templat yang tidak bisa dikerjakan tidak dipilih; kurang dari 3 eligible → tampil kurang. "Bantu lahan" dihapus dari Harian/Mingguan, jadi quest Season "Bantu 20 lahan (Season)" 500 Koin tanpa Bunga, di Hadiah > Musim, setelah Bantu terbuka. Tugas Agenda "Bantu" disembunyikan sampai Kebun Warga (R2.5). Quest yang sistemnya belum ada diblok (M1 sampai R2.2). Tiap langkah punya baris pemain dari kolom Langkah 03. Pohon Skill: tombol Beli selalu terlihat; bar bawah saat node ditekan. Quest Log: tab Main · Side · Harian · Pesanan; landscape dua panel; tracker maks 3; Main aktif ditandai otomatis; Side/Harian lewat "Tandai". | Playtest putaran 1 (#5, #7–#11) |
| K-57 | 2026-11-23 | **DIPUTUSKAN (grup E, event).** Tombol "Acara" menjadi "Event", hanya tampil saat event musiman aktif; sheet: progres, Pesanan Tamu, hadiah, hitung mundur. Pasar Malam menjadi tempat di dunia (buka sesuai jadwal); Pak Kumis NPC, jual lewat bubble seperti Pak Udin ("Jual semua" / "Jual 1"). Lempar Gelang: minigame bar bergerak, tap berhenti; zona 60/30/10% untuk hadiah kecil/sedang/besar; 3 lemparan per malam (R3.8). | Playtest putaran 1 (#12, #13) |
| K-58 | 2026-11-23 | **DIPUTUSKAN (Putaran 2, Season).** Quest Season "Bantu 20 lahan": versi minimal. Progres di PlayerData (`season.bantu`), kartu di Hadiah > Musim dengan progress bar dan hadiah 500 Koin (tanpa Bunga, K-28). Hanya tampil setelah Bantu terbuka. | Keputusan owner putaran 2 |
| K-59 | 2026-11-23 | **DIPUTUSKAN (Putaran 2, K-52 final).** Album dekor hanya menghitung entri yang sudah dibangun; piece yang belum dibuat disembunyikan, sehingga 100% bisa tercapai. Isi 80 piece = R4.8 (konten, bukan angka yang disetel). | Mengganti default K-52 (33 entri) |
| K-60 | 2026-11-23 | **DIPUTUSKAN (Putaran 2, dokumen mengikuti kode).** Order Villager mingguan: 4 jenis (`Orders.WEEKLY_TYPES`), jumlah ×3, hadiah ×3, XP ×0,5. Ditulis di GDD 14.7. | Dokumen belum memuat angka ini |
| K-61 | 2026-11-23 | **DIPUTUSKAN (Putaran 2).** Pemilih warna dinding belum dibuat sekarang. Tugas baru R3.9: Hias GUI "Warna Dinding" dengan 12 warna muted dari Asset Bible Bab 1 + "Dinding Spesial". | Keputusan owner |
| K-62 | 2026-11-23 | **DIPUTUSKAN (Putaran 2, Gembor Emas).** Item `gembor_emas` di tab Alat: kosmetik saja (tint emas), statistik identik, penyiraman mengabaikannya. Dipasang dengan tombol "Pakai" (K-55). Quest side_prima memberi item ini, bukan 200 Koin. PLACEHOLDER di Asset Bible bagian 12. | Keputusan owner |
| K-63 | 2026-11-23 | **DIPUTUSKAN (Putaran 2, A7).** "Jual Semua" yang terpotong hilang bersama E2 (penjualan pindah ke bubble lapak Pak Kumis). Tidak diperbaiki terpisah. | Keputusan owner |
| K-64 | 2026-11-23 | **DIPUTUSKAN (Putaran 2, DEV).** Akses perintah DEV: `DevService.IsAllowed(player)` = `RunService:IsStudio()` ATAU UserId ada di `Config/DevAccess.UserIds` (akun owner). Satu fungsi dipakai semua perintah dan remote DEV. `Config/DevAccess.LIVE_ENABLED = true` sekarang; R10.5 dan gerbang G3 mewajibkan `false` plus cek otomatis (AUTO) sebelum rilis publik. Semua item DEV ONLY dicatat di Roadmap Bab 17. | Owner mengetes game terbit dengan akunnya sendiri |
| K-65 | 2026-11-23 | **DIPUTUSKAN (Putaran 2, Studio).** Bila di Studio profil tidak bisa dimuat (kunci sesi karena owner memainkan akun yang sama, atau API off), dibuat profil dari DataTemplate di memori dengan `studioMock = true`. Profil ini tidak pernah disimpan. Satu baris log. Di server live tidak berlaku (tetap kick). | Tes Play di Studio tidak boleh mati karena data |
| K-66 | 2026-11-23 | **DIPUTUSKAN (otomatis, R2.1b).** Bubu dijual di Pak Udin (bagian Kebutuhan) dengan harga Koin saja: Bambu 400, Kayu 1.500, Besi 4.000 (Config/Bubu TYPES). GDD 6.6 juga menyebut bahan (10 Bambu, 20 Kayu, 15 Batu + 10 Kayu) yang belum ada di kode; bahan belum dipungut. Pasang memakai bubu pertama yang dimiliki (tanpa pilih manual). Ambil hanya muncul di dekat tiang bubu. Tiang di sungai dan label "belum siap"/"SIAP!" dibuat server. | Keputusan Claude; owner cek di HP |
| K-67 | 2026-11-23 | **DIPUTUSKAN (owner).** Bubu Besi tetap memakai perilaku kode: panen mengambil ikan merata dari semua ikan U dan R. Aturan "5% 1 Late" dihapus dari desain (GDD 6.6). | Owner; GDD 6.6 diperbarui |
| K-68 | 2026-11-23 | **DIPUTUSKAN (owner).** Bahan Bubu tetap ditunda (K-66). Harga Bubu hanya Koin. | Owner; GDD 6.6 tetap |
| K-69 | 2026-11-23 | **DIPUTUSKAN (owner).** Toast saat quest mulai: `Quest baru: <judul>` (menggantikan "Misi baru" di mana pun). | Owner; Locale `quest.new`, 03 Bab 9 |
| K-70 | 2026-11-24 | **DITUTUP (owner 2026-11-24: PLAY lulus di tes owner).** Penyebab miss di tes Claude (remote path) tidak dibuktikan; tidak ada perbaikan kode. Catatan awal: **TERBUKA (DEV, MS-2).** Klik mouse di Studio tidak mengenai PLAY di `KTMenu`. Kode tidak menemukan penutup: `KTMenu` DisplayOrder 200, layar lain di bawahnya dimatikan saat menu, `COVER` 250 baru ada setelah PLAY. Dugaan: koordinat klik MCP tidak sama dengan viewport Studio (belum diukur). Jalur DEV `!masuk` / `DevService.Enter` dibuat sebagai gantinya (R10.5). | Tidak ada perbaikan kode sekarang; penyebab belum dibuktikan |
| K-71 | 2026-11-24 | **DIPUTUSKAN (owner 2026-11-24, opsi a: timer tanam cepat ditahan sampai siram pertama).** Masalah asli: tanam pertama di save baru tumbuh 20 s (`Onboarding.FAST_GROW_SECONDS`, `fastLeft` 6). Siram (`watered`, langkah `siram` di `Onboarding.luau`) hanya bisa sebelum `readyAt` (`FarmService.waterTile` menolak bila `now >= readyAt`). Setelah 20 s petak `Panen!` dan tombol Siram hilang, sedangkan langkah `siram` hanya selesai lewat Siram. Akibat: pemain yang lambat (dialog Mak Sari di antara) tidak bisa menyelesaikan `siram`. Diuji 2026-11-24 (remote path): tanam jam T, petak Panen! sebelum tombol Siram sempat ditekan. Pilihan: (a) timer fast berhenti sampai disiram, (b) siram masih boleh setelah ripe (tanpa bonus), (c) langkah `siram` juga selesai dengan panen pertama. Rekomendasi Claude: (a). | Diputuskan (a). Kode: `Types.FarmTile.fastHold`; tanam tutorial memberi `readyAt` jauh di depan dan `fastHold = true`; siram pertama memulai timer 20 s × (1 − 15 %) dan mematikan hold (`FarmService.waterTile`). Pill tanpa hitung mundur saat ditahan (atribut `FastHold`, `FarmFloat`). Commit: `ddc0230`, `b78b635`. Aturan: GDD 16.2 (Tanam cepat). Owner 2026-11-24: "semua sudah oke", termasuk bed tanam cepat yang ditahan sampai disiram. Selene 0/86, rojo 0. Verifikasi Play: Roadmap Handoff. |
| K-72 | 2026-11-24 | **DIPUTUSKAN (Claude, konservatif; owner belum meninjau).** Seed-out (T3): pesan "Bibit habis" (`farm.no_seed`) memakai toast dismissible dengan tombol Ok (`seed_out`), bukan toast 1,8 dtk. Tetap sampai Ok, atau hilang saat `shop.bought_seed`. Tidak ada gelap, tidak memblokir joystick. Tidak ada tombol beli di dalam toast. | GUI 4.2 (dismissible), GDD 5 (Bibit habis), 09 B19 |
| K-73 | 2026-11-24 | **DIPUTUSKAN (owner 2026-11-24; menggantikan K-17).** Bantu Tetangga disembunyikan sampai DAU stabil: satu flag `Config/Features.BANTU_ENABLED = false` (`src/shared/Config/Features.luau`). Selama false: tidak ada tombol Warga atau baris Bantu di UI; server menolak `SocialBantu`; S6 dan side_tetangga `blocked` (tidak pernah mulai); Agenda tanpa tugas Bantu; Surat 6/13/20/29 (minta Bantu) dibayar langsung tanpa toast, supaya surat berikutnya tidak macet. **Kebun Warga dibatalkan**: tidak dibangun, dihapus dari GDD 12.2 dan Prinsip 16. Kode Bantu tetap, tidak dihapus. **Pengganti slot Bantu di Agenda (pilihan konservatif Claude):** Tanam 5 (event `plant`, 150 Koin + 25 XP, nilai sama dengan Bantu). Dampak: Warga (Mampir, Suka, hadiah) ikut tersembunyi karena tombolnya memakai gate `bantu`; skill Tetangga Baik masih bisa dibeli tapi tanpa efek; teks surat 6/13/20/29 masih menyebut Bantu. Ketiganya masuk gap list (R2.G). | Keputusan owner; GDD 12.2, 14.5, Prinsip 16 |
| K-74 | 2026-11-24 | **DIPUTUSKAN (Claude, konservatif; owner belum meninjau).** R2.3: (1) Surat #1 "dibaca" = tap baris Surat di tracker; server menampilkan surat itu lagi dan mencatat `surat_read` (Quest S2). Tidak ada cara lain di kode untuk membaca surat. (2) "Lihat Gerobak Kaget" (M1 langkah 3) = membuka panel Acara dengan tab Gerobak; tidak ada objek gerobak di dunia yang dilihat. (3) Pesanan dibuka dengan fitur `agenda` (M1 mulai), klien dan server, sesuai GDD 14.7 "sama dengan Agenda (M1)". (4) Sisa starter chain tidak ditemukan di `src/`. | GDD 14.7; Quest 03 Bab 5 |
| K-75 | 2026-11-24 | **DIPUTUSKAN (Claude, konservatif; menutup walk G1).** Tombol Warga (HUD `SocialButton`) selama Bantu mati tampil hanya saat ada 2 pemain atau lebih di server (`FeatureClient.GateHud` dengan aturan sendiri). Solo tidak melihat tombol kosong. Saat `BANTU_ENABLED = true`, gate tetap fitur `bantu` (S6). Cek dependensi: tidak ada quest, unlock, atau title solo yang butuh Warga. Satu-satunya: title Kebun Favorit (Like 200, `Config/Social`), yang memang bergantung pemain lain (aturan K-28). | Walk G1; K-28 |
| K-76 | 2026-11-24 | **DIPUTUSKAN (Claude, konservatif; menutup walk G2).** Skill Tetangga Baik disembunyikan selama `BANTU_ENABLED = false`: tidak tampil di Pohon Skill, cabang Sosial tidak tampil, dan `SkillService.buy` menolak dengan "locked". Data skill tetap. Semua skill yang bisa dibeli = 75 SP + 225.000 Koin (15 skill). Tidak ada skill lain yang prasyaratnya memakai Tetangga Baik. | Walk G2; K-73; GDD 4.5 |
| K-77 | 2026-11-24 | **DIPUTUSKAN (Claude, konservatif; menutup walk G3).** Surat 6, 13, 20, 29 meminta Bantu. Selama Bantu mati: `SuratService.TextKey(n)` memilih teks alt (`surat.<n>.alt`, Locale, nada dan gaya sama, tanpa kata Bantu), dan toast memakai teks itu saat surat dibayar (K-73) bila fitur Surat terbuka. Flag hidup = teks asli (`surat.<n>.text`). Tidak ada lore baru: hanya kalimat yang sudah ada diganti. | Walk G3; K-73; Quest 03 |
| K-78 | 2026-11-24 | **DIPUTUSKAN (Claude, konservatif; menutup walk G4).** Quest Season "Bantu 20 lahan" (K-58) tidak dibangun (tidak ada kartu di Hadiah > Musim, tidak ada `season.bantu`). Dokumen GDD 19 dan Quest 03 diberi catatan: aktif hanya saat `BANTU_ENABLED = true` dan kartu dibuat (RP2.S). Tidak ada kode baru. | Walk G4; K-58; K-73 |
| K-79 | 2026-11-24 | **DIPUTUSKAN (Claude, dokumen mengikuti kode; menutup walk G5).** Kerja Bakti tidak diubah: pemicu tetap hujan Deres/Petir yang berakhir (`kbStart`), prompt pungut tetap gerbang Gerobak (M1 langkah 3). Dokumen (GDD 13.4, Quest 03 `side_kerjabakti`) menulis ketergantungan cuaca. Checklist B22 butir 5: tidak ada tes solo yang menunggu Kerja Bakti. | Walk G5; GDD 13.4; `Config/Weather` RAIN_ROLL |
| K-80 | 2026-11-24 | **DIPUTUSKAN (Claude, dokumen mengikuti kode; menutup walk G6).** Agenda tidak diubah: pool `Config/Quests` DAILY dengan syarat level dan fitur (K-56). Jumlah tugas yang muncul = yang syaratnya terpenuhi: **3** di Lv 1–3, **4** di Lv 4–5 (Hutan), **5** di Lv 6+ (Dapur). GDD 14.5, GUI 6.9 (sebut 3–5), Checklist B2 butir 2 dan B21 diperbarui. Bantu menambah satu saat flag hidup. | Walk G6; K-56; GDD 14.5 |
| K-81 | 2026-11-24 | **DIPUTUSKAN (Claude, konservatif; menutup walk N1 / R2.G7).** Quest `side_kerjabakti` (Pekerja Bakti, Nek Ani) `unlockLevel` 1 → **2**, sama dengan gerbang prompt pungut (Gerobak, M1 langkah 3). Gerbang Gerobak dan M1 tidak diubah. Ini mengganti bagian "Lv 1" di K-79. GDD 13.4, Quest 03 dan Checklist B22 butir 5–6 diperbarui. | Walk N1; K-79; GDD 13.4 |
| K-82 | 2026-11-24 | **DIPUTUSKAN (Claude, diterima; menutup walk N2 / R2.G8).** Solo tidak punya konten sosial selama Bantu disembunyikan (Warga hanya tampil di 2+ pemain, K-75). Tidak ada konten pengganti dibuat. Gap ini diterima dan terikat ke `Config/Features.BANTU_ENABLED`: sosial kembali bersama flag. Tidak ada quest yang macet karenanya. | Walk N2; K-75; K-73 |
| K-83 | 2026-11-24 | **DIPUTUSKAN (Claude, konservatif; menutup walk N3 / R2.G9).** Surat 6, 13, 20, 29 yang dibayar otomatis (K-73) sekarang selalu menampilkan toast hadiah lewat sistem toast yang sudah ada (Notify → HudController), tidak bergantung gerbang Surat. Isi toast: teks surat (alt, K-77) + hadiah yang diterima. Pembayaran tidak ditunda. Ini mengganti "tanpa toast" di K-73. Catatan: toast di login (`Init`) bisa lewat sebelum klien siap, sama seperti toast login surat lain; event pertama setelahnya tidak terpengaruh. | Walk N3; K-73; K-77 |
| K-84 | 2026-11-24 | **DIPUTUSKAN (Claude, konservatif; dari owner playtest 2026-11-24, butir 1).** Jual Pertama (GDD 16.4) dibangun ulang: kamera lebar tetap di dekat pohon beringin (`Cutscene.Begin(..., wide)`, `NpcCamera.Wide`, FOV 60, tanpa blur) supaya Pak Udin, warung, dan bangunan terlihat. Kamera dipotong, tidak meluncur dari kamera avatar (luncuran melewati rambut). Pemain berjalan ke titik berdiri (`MoveTo`, maks 4 dtk) sementara kamera sudah di shot; Pak Udin menoleh, baru dialog. Kamera di `PreRender`, satu pemilik (token), kamera dipulihkan, beat berakhir saat `CharacterRemoving`. WalkSpeed/JumpPower tetap di PlayerLock (snapshot di sana). Tanpa skip. Shot lama (`NpcCamera.Shot`) tetap dipakai untuk bicara biasa dan beat hadiah Kak Fajar. | Owner 2026-11-24 butir 1; GDD 16.4; Checklist B23 |
| K-85 | 2026-11-24 | **DIPUTUSKAN (Claude, konservatif; owner playtest 2026-11-24, butir 2).** Langkah tutorial `mancing` ("3 ikan"): satu toast tersemat (`HudController.SetPinned`, key `mancing`) dengan hitungan `{n}/{N}` (1/3, 2/3, 3/3), dihitung dari Tas di tiap refresh. Hilang saat langkah selesai (langkah berikutnya memanggil ClearPinned) dan saat tutorial berakhir (`endTutorial`). Toast "Coba lagi" untuk tangkapan 2 dan 3 dihapus; tangkapan 1–2 tidak punya toast lain. Bubble pertama (spotlight Aksi) tidak berubah. GDD 16 tabel langkah 12, Quest 03 Mancing, Checklist B23 butir 2. | Owner 2026-11-24 butir 2; K-54; GUI 4.2 |
| K-86 | 2026-11-24 | **DIPUTUSKAN (Claude, konservatif; owner playtest 2026-11-24, butir 3).** Sungai dan empang wajib umpan. Server (`FishService.startCast`) menolak lemparan tanpa umpan; klien mematikan tombol Pancing (`FishingController`, `aksiButton.Active`) dan chip berkata "Umpan habis, beli di Kak Fajar". Aturan "tanpa umpan 6–12 dtk" dipindah ke kolam saja (`Fishing.POND_BITE_*`, kolam tetap aturannya sendiri). Hadiah tutorial: Cacing ×5 (K-21, dikembalikan di K-90). Harga/XP (tidak diubah): Cacing 10 Koin per lemparan, ikan Lv 1–2 10–18 XP (~0,6–1,0 Koin/XP); Pelet 45 Koin, ikan Lv 5 26–32 XP (~1,4–1,7 Koin/XP). Umpan hilang saat lemparan gagal (GDD 6.2). | Owner 2026-11-24 butir 3; K-21; K-16; GDD 6.1, 16 langkah 11 |
| K-87 | 2026-11-24 | **DIPUTUSKAN (Claude, konservatif; owner playtest 2026-11-24, butir 4). Sebagian: teks sudah, portret belum.** Kunci mentah `npc.pak_kumis.greet` diisi: Pak Kumis (Pedagang Pasar Malam, Bab 13.2) membeli barang pilihan dengan harga lebih mahal; pemain mengetuk Jual 1 atau Jual Semua di bubble. Pedagang rotasi lain yang juga kehilangan kunci greet (`nek_esih`, `bang_dodo`, `mpok_riah`, `kang_asep`, `yu_tum`) diisi dengan teks yang sama. **Portret belum:** tidak ada gambar Pak Kumis di `assets/portraits` atau di `UiAssets.PORTRAIT_IMAGES`, dan Asset Bible 04 mencatat potret Pedagang Tamu "Belum". Tidak dibuat gambar baru. Butuh gambar dari owner (lalu tambah `PORTRAIT_IMAGES.pak_kumis` seperti NPC lain). Kunci yang masih mentah tapi tidak tampil sekarang: `npc.pedagang_tamu.greet` dan `npc.tamu_event.greet` (keduanya hidden; Tamu Event menunggu K-57), serta `.role` / `.locked` untuk beberapa NPC (hanya dipakai saat terkunci atau di panel). | Owner 2026-11-24 butir 4; Asset Bible 04; K-57 |
| K-88 | 2026-11-24 | **DIPUTUSKAN (Claude, konservatif; owner playtest 2026-11-24, butir 5).** Tombol Ok toast dismissible (`UiKit.toastChip`, "Bibit habis") memakai tombol UiKit standar (`UiKit.button`, gaya dan suara sama) dengan tinggi token `TOUCH` 32 px (GUI 3.4). Tinggi chip minimum = `TOUCH` + 2×8 px. GUI 4.2 "tinggi 44 px" diganti ke token `TOUCH`, sesuai keputusan 3.4. Lebar Ok tetap 56 px (`TOAST_OK_W`, lebar layout toast, bukan ukuran tombol). | Owner 2026-11-24 butir 5; K-38; K-72; GUI 3.4, 4.2 |
| K-89 | 2026-11-24 | **DIPUTUSKAN (Claude, konservatif; owner playtest 2026-11-24, butir 6).** Toast naik level dan toast "Terbuka" jadi satu urutan (`HudController`, `levelLines`): "Naik ke Level n!" dulu, lalu satu baris "Terbuka: {nama}" per buka kunci (kunci dari `unlocks` server, `level.unlock_line`). Satu chip sekaligus di satu slot; tidak ada dua yang tampil bersamaan. Lama tampil per chip = clamp(1,8 + 0,05 × karakter, 1,8, 5) dtk. Banner "LEVEL n!" besar tetap. Aturan lama ini hanya untuk urutan naik level; toast biasa tetap 1,8 dtk (perlu keputusan owner kalau mau berlaku ke semua toast). GUI 4.2 butir 4. | Owner 2026-11-24 butir 6; GUI 4.2; K-53 |
| K-90 | 2026-11-24 | **DIPUTUSKAN (owner, 2026-11-24, follow-up butir 3).** Hadiah tutorial langkah 11 (`rodgift`) kembali ke **Cacing ×5** sesuai K-21 (a). Pelet (45 Koin) adalah umpan yang lebih mahal, bukan umpan tutorial. Jumlah tetap 5. Kode: `TutorialService.FAJAR_BAIT`. GDD baris langkah 11 diperbarui. | Owner follow-up 2026-11-24; K-21; K-86 |
| K-91 | 2026-11-24 | **DIPUTUSKAN (owner, follow-up butir 4; tidak ada perubahan kode).** Potret Pak Kumis tetap kosong. Tidak ada silhouette atau potret generik yang punya ID aset: 6 file di `assets/portraits` (bang_tarno, bu_wati, mas_joko, mbak_arsi, mbok_minah, pak_darmo) adalah potret NPC bernama lain dan belum diunggah, dan semua ID di `UiAssets.PORTRAIT_IMAGES` milik NPC lain. Pak Kumis tidak dipasangi wajah NPC lain. Aset dibuat/diunggah owner, lalu Roadmap R4.5 ditutup. | Owner follow-up 2026-11-24; K-87; Roadmap R4.5 |
| K-92 | 2026-11-24 | **DIPUTUSKAN (Claude, konservatif; owner playtest 2026-11-24, quest butir 1; belum dicek di Play).** Tracker quest hilang saat pemain mengambil quest dari NPC. Penyebab (dibaca dari kode, belum direproduksi): saat bicara, `DialogueController.hideOtherGuis` mematikan semua ScreenGui termasuk `QuestUI`, dan baru dihidupkan lagi saat talk ditutup. Perbaikan: `QuestUI` masuk `KEEP_VISIBLE`, jadi tracker tetap tampil selama bicara. Quest UI tidak boleh berkedip (GUI 05 4.5 / Quest 03 bab 9). | Owner playtest 2026-11-24 butir 1; GUI 05 4.5; Quest 03 bab 9 |
| K-93 | 2026-11-24 | **DIPUTUSKAN (Claude, konservatif; owner playtest 2026-11-24, quest butir 4; belum dicek di Play).** Turn-in: Main dan Side dengan pemberi NPC berhenti di status *siap diserahkan* (`quests.ready`) saat semua langkah selesai, bukan langsung selesai. Hadiah dibayar lewat remote `QuestTurnIn` saat pemain bicara dengan pemberi (dialog baris `dlg.<prefix>.done`, lalu bayar). Pemberi tidak diberi `!` lagi setelah quest selesai. Quest auto (MQ12) dan quest tanpa pemberi NPC (`Npcs.byId` nil, mis. Surat) tetap selesai langsung. Harian dan Agenda tidak berubah. Celah jarak ditutup oleh K-100. | Owner playtest 2026-11-24 butir 4; Quest 03 bab 9; GDD 14.1 |
| K-94 | 2026-11-24 | **DIPUTUSKAN (Claude, konservatif; owner playtest 2026-11-24, quest butir 3 dan 7; belum dicek di Play).** Track: maks 3 (`QuestService.TRACK_MAX`), disimpan di `quests.tracked` (id quest, `h:<kind>`, `w:<kind>`). Main selalu masuk tracker; kalau penuh, Main menggeser satu Side/slot. Side, Harian, Mingguan masuk hanya lewat tombol Track, kecuali quest yang baru ditawarkan atau diambil, yang otomatis masuk bila ada slot (supaya "!" pemberi dan panahnya terlihat). Lepas boleh di baris mana pun. Baris Harian/Mingguan tidak ada lagi tanpa tracking. | Owner playtest 2026-11-24 butir 3, 7; GUI 05 6.8 |
| K-95 | 2026-11-24 | **DIPUTUSKAN (Claude, konservatif; owner playtest 2026-11-24, quest butir 5 dan 8; belum dicek di Play).** S2 (Surat Pertama): baca surat adalah aksi HUD, jadi pointer-nya tombol **Baca** di baris Surat tracker dan di baris S2 (bukan panah dunia). Tidak ada `target` untuk S2. Teks langkah M6 s1 dibetulkan jadi "Pasang Tungku di lahanmu lewat panel Dapur" (teks lama "Craft Tungku" tidak sesuai aksi `dapur_built`). M6 s2 dan s3 punya target `Tungku`. Dua hal M6 belum ada di kode dan TIDAK dibangun di batch ini: (a) craft Tungku di Meja Crafting (Tier 1 dibangun dari bahan di panel Dapur), (b) tombol Aksi dapur dekat Tungku (dapur dibuka dari tombol dock). Dicatat sebagai R5.8a dan R5.8b, menunggu keputusan owner. | Owner playtest 2026-11-24 butir 5, 8; K-94; Quest 03 bab 9 |
| K-96 | 2026-11-24 | **DIPUTUSKAN (owner playtest 2026-11-24, butir 6; kode).** Baris "Tidak ada Kerja Bakti sekarang" (Acara, `kb.none`) dihapus. Bagian Kerja Bakti di Acara hanya tampil saat `KBActive`. Quest Log menampilkan `side_kerjabakti` hanya saat acaranya jalan. | Owner playtest 2026-11-24 butir 6 |
| K-105 | 2026-11-24 | **DIPUTUSKAN (owner 2026-11-24 kamera, butir 1; menggantikan K-84).** Jual Pertama: layar hitam, pemain dipindah ke titik 4,5 stud di depan Pak Udin menghadap dia, fade masuk di shot bicara dekat (`NpcCamera.Shot`: BACK 2,4, SIDE 2,4, RISE 1,7, FOV 34, sama dengan shot Mak Sari). Tidak ada jalan masuk frame (`MoveTo`). Shot lebar `SALE_WIDE_SHOT` dihapus dari T1Ghost; `NpcCamera.Wide` tinggal sebagai kode tak terpakai. | Owner 2026-11-24 kamera; GDD 16.4; K-84 |
| K-103 | 2026-11-24 | **DIPUTUSKAN (Claude, owner 2026-11-24 butir 8 lanjutan).** M6 jadi empat langkah dengan panah di tiap langkah: craft `craft_tungku` (panah ke Meja Crafting), pasang `dapur_built` (panah ke `lahan` = Origin plot sendiri), masak `cook` (panah ke Tungku), makan `eat` (panah ke Tungku). Target `lahan` dibaca dari atribut `PlotName`. Teks langkah diganti sesuai aksi. | Owner 2026-11-24 butir 8; K-95; K-101; K-102 |
| K-125 | 2026-11-24 | **DIPUTUSKAN (owner 2026-11-24: "kamu yang putuskan"; remap disetujui; Claude menetapkan tempat).** Sembilan ubin tetap di ≡: Warga, Buku, dan Kolam tidak dibuang dan tidak pindah, ikut kisi (gerbang masing-masing tetap). ≡ terbuka jadi **kisi** (`UiKit.menuItem` → `Items` ScrollingFrame, kisi `UIGridLayout`), bukan kolom: landscape 5 kolom, 2 baris terlihat, di kiri toggle; portrait 3 kolom, 2 baris terlihat, baris ketiga dengan gulir, di bawah toggle (`MENU_PORTRAIT_TOP` 62). Ubin tetap 50 px (37,5 px di layar, `KT_Scale` 0.75 ≥ TOUCH 32). Dock tetap 4 tombol. Diukur di Studio: landscape HP 843×370 (9 ubin, ujung kisi ≈107 px), tablet landscape 1364×1004. **Portrait belum diukur** (simulator tidak memutar viewport di Studio ini). GUI 05 §4.0. |
| K-127 | 2026-11-24 | **DIPUTUSKAN (Claude, Studio-only, uji saja; tidak ada UI baru).** Kait uji Studio: `src/server/Services/TestHookService.luau` dan `src/client/Controllers/TestHookController.luau`. Keduanya tidak berbuat apa-apa di luar Studio (`RunService:IsStudio()`), dan sisi server tidak mendaftar handler `TestHook` di build terbit. Harness mengirim permintaan lewat atribut `KTTestRequest`: `skipTutorial` (semua tutorial di `Onboarding.TUTORIALS` ditandai selesai, intro tidak main), `grant` (benih kangkung x5 dan tomat x0, item panen, ikan, umpan, XP +60, timeline peti 600 dtk dengan peti 1 sudah diambil, Login hari 3 tercapai, belum diambil), `open:<layar>` (membuka layar lewat tombol HUD-nya; ≡ dibuka dulu bila tombolnya ada di dalamnya). Perintah DEV chat (`DevService`) tidak dipakai karena dikunci `IsAllowed` dan tidak punya perintah tutorial-selesai. **Akar masalah klik Hadiah (dari tes):** dua sebab, bukan bug UI. (a) HUD disembunyikan selama intro (`HIDE_DURING_INTRO`), jadi klik tidak mencapai tombol. (b) Hadiah ada di kolom ≡ yang tertutup di HP sentuh, sehingga `Activate()` pada tombol tersembunyi tidak membuka apa pun. Pemain nyata membuka ≡ dulu. Tombol "Next" intro juga tidak maju lewat `Activate()` pada percobaan itu; penyebabnya belum diketahui. **Koreksi (smoke test, 2026-11-24):** `GuiButton:Activate()` tidak ada di build Studio ini ("not a valid member"), jadi kait tidak bisa menekan tombol. Kait sekarang hanya menyiapkan layar (`KTTestTarget`), dan ≡ dibuka dengan menampilkan kolomnya. Tap nyata lewat `user_mouse_input` tidak sampai ke tombol GUI di lingkungan ini (diuji: Play, Tas dock, dan Hadiah). Uji yang memerlukan tap wajib ditandai "remote path, not UI" dan tetap NOT verified. Smoke test: `skipTutorial` berhasil (intro tidak main, HUD tampil), `grant` berhasil (XP 61/230, timeline peti 600 dtk), `open:hadiah` menyiapkan target tetapi tidak membuka panel (tidak ada tap). |
| K-126 | 2026-11-24 | **DIPERBAIKI (bug, ditemukan saat tes Play).** `init.client.luau` memanggil `script.Parent:WaitForChild("AksiSlot")`, padahal modul ada di bawah LocalScript `Client` (`script`). Akibatnya `AksiSlot.Start()` tidak pernah jalan sejak K-104, dan visibilitas semua tombol Aksi tidak pernah diatur di Play. Sekarang `script:WaitForChild("AksiSlot")`. Belum diuji tombol Aksi nyata (tidak ada objek dekat saat tes). |
| K-124 | 2026-11-24 | **DITETAPKAN (owner 2026-11-24, peta HUD; dokumen saja, remap belum dikerjakan).** Peta target: dock 4 (Garap, Hias, Tas, Quest), 1 slot Aksi, 1 ≡ dengan 6 ubin (Papan Hari Ini, Skill, Hadiah, Acara, Toko, Atur), titik merah. Info pasif di kiri (kartu pemain, tracker, umpan XP). Hitungan: ≡ dari 10 tombol ke 7. Dihitung (belum diukur): landscape 844×390 ≡ terbuka 406 px (melebihi 390) dan menutupi slot Aksi; portrait 390×844 ≡ terbuka menutupi 3 dari 4 tombol dock. Ubin Warga, Buku, Kolam belum punya tempat di peta target: pertanyaan ke owner. GUI 05 4.0. |
| K-123 | 2026-11-24 | **DIPUTUSKAN (Claude, konservatif; owner playtest 2026-11-24, UI butir 4; belum dicek di Play).** Hadiah dipecah jadi empat layar (tab): Login Harian (7 kartu hari, satu tombol Klaim untuk hari tercapai pertama yang belum diambil), Peti Main (garis waktu dengan hitung mundur, satu tombol Buka), Musim, dan Koleksi (tidak berubah). **Jumlah peti: 5, bukan 4** seperti catatan owner. Config/Progression dan GDD 15.2 menyebut 5; empat akan membuang satu hadiah. **Keputusan owner (final): tetap 5; catatan "4" dicabut.** `rewards.tab_daily` tidak dipakai lagi. GUI 05 6.1. |
| K-122 | 2026-11-24 | **DIPUTUSKAN (Claude, konservatif; owner playtest 2026-11-24, UI butir 3; belum dicek di Play).** Gambar item di Tas dan token terbang: `UiKit.itemPicture` memakai urutan THUMBS (gambar item), ikon kategori, model 3D, huruf pertama (cadangan terakhir). Sel Tas memakai `thumbKey`; sel lain (Buku) tidak berubah. Token panen memakai ikon panen; token koin memakai ikon koin (sebelumnya "$"). Rak Toko (`UiKit.thumb`) tidak diubah. Item tanpa gambar sendiri tercantum di Roadmap "Needs asset". Tidak ada id aset yang dibuat. GUI 05 4.12. |
| K-121 | 2026-11-24 | **DIPUTUSKAN (Claude, konservatif; owner playtest 2026-11-24, UI butir 2; belum dicek di Play).** Umpan XP: "+N XP" dari bar XP di kartu pemain, geser bar 0,35 dtk, kilat 0,5 dtk; naik level tanpa geser. "Kurangi gerak" belum ada di kode atau dokumen sebelumnya, jadi dibuat sebagai pengaturan `settings.reduceMotion` (default off, baris di Atur, `SWITCH_KEYS`). Saat on: tanpa geser, naik, atau kilat. GUI 05 4.11. |
| K-120 | 2026-11-24 | **DIPUTUSKAN (Claude, konservatif; owner playtest 2026-11-24, UI butir 1; belum dicek di Play).** Kartu bibit (kartu di atas petak, bukan panel): 8 per halaman (2 x 4), chevron ‹ › di kiri dan kanan kisi (`UiKit.TOUCH`), bibit yang dimiliki dulu, x0 redup dan terakhir. Ukuran lingkaran `slotPx()` tidak berubah. Panel `buildPicker` di FarmController (tanpa pemanggil) tidak diubah. GUI 05 4.10. |
| K-119 | 2026-11-24 | **DIPUTUSKAN (owner 2026-11-24, butir 3 Prompt C: opsi b).** Peti Bunga tetap klaim di panel Hadiah (GDD 15.3, GUI 6.1 tab Koleksi). Peti dunia di lahan + gali 20 dtk **tidak dibangun**: tidak ada di GDD/GUI dan tidak ada sumber spawn yang didefinisikan. Tinjau ulang setelah playtest end-to-end pertama. |
| K-118 | 2026-11-24 | **DIPUTUSKAN (Claude, konservatif; owner playtest 2026-11-24, butir 2; belum dicek di Play).** Gerobak Kaget tidak punya wujud di alun-alun. Ditambah **gerobak placeholder** (part sederhana, `GerobakCart`, di (-18, 14) pada plaza, tidak di jalan jembatan). Tombol Aksi "Lihat Gerobak" muncul dalam jangkauan 10 studs saat gerbang gerobak terbuka; tekan = buka panel Acara tab Gerobak. Langkah M1 3 "Lihat Gerobak Kaget" (`gerobak_view`) selesai dari gerobak atau dari tab Acara, dan sekarang menunjuk gerobak (`target`). Prioritas Aksi 7 (K-104). **Art placeholder: R4.10 mengganti.** Tidak ada perubahan hadiah atau gerbang. |
| K-117 | 2026-11-24 | **DIPUTUSKAN (Claude, konservatif; owner playtest 2026-11-24, butir 1; belum dicek di Play).** Sampah Kerja Bakti per pemain. (a) Tiap pemain dapat **16** sampah sendiri (`Repeat.KERJA.PIECES_EACH`; = total solo lama; tidak lagi dibagi antar pemain). Hadiah per poin, maks 20 poin, maks 4 event per hari, dan bonus 100% tidak berubah (bonus tetap saat semua sampah peserta habis). (b) Sampah hanya digambar di klien pemain itu (`src/client/Controllers/KerjaBaktiController.luau`, folder `KBLitter`). Server menyimpan posisi dan mengirim `KBPieces`. (c) Sebaran: acak merata di piringan r 44 dari pusat cincin toko, jarak minimum 7 studs antar sampah pemain yang sama, minimal 6 studs dari batang pohon. Lama: lingkaran berjari-jari 10–25 dari titik (0,0), yang jatuh ke pohon. (d) Pungut: klien kirim `KBPick(id)`; server cek event aktif, gerbang gerobak, id milik pemain dan belum dipungut, dan jarak HRP ≤ 16 studs. Lalu `KBPicked(id)`. (e) Animasi pungut memakai klip "plant" yang sudah ada (`FarmFx.pickUp`), tanpa animasi baru. Pemain yang masuk saat event berjalan tidak dapat sampah. **Art placeholder: kotak coklat, R4.10 mengganti.** |
| K-116 | 2026-11-24 | **DIPUTUSKAN (owner 2026-11-24 lanjutan; Claude menetapkan angka).** Satu tempat untuk semua tombol Aksi: `UiKit.placeAksi` (84×84 px, kanan bawah, 24 px dari kanan, 200 px dari bawah, di atas Jump; sama dengan tempat Pukul dan Masak dulu). Berlaku untuk Pancing, Tarik (di tempat Pancing), Bubu, Pukul, Kelola, Kolam, dan Masak / Pasang Tungku. Posisi lama (skala 0,8/0,67 Pancing dan 0,68/0,67 Bubu, serta -316 Kelola, -392 Kolam) dihapus. Hasil cek tumpang tindih di GUI 05 4.9 (dihitung, belum diukur di perangkat). Satu kasus: kolom ≡ terbuka di landscape HP bisa menumpuk bagian bawahnya; dilipat secara default di HP. | Owner 2026-11-24 lanjutan; GUI 4; K-34; K-104 |
| K-115 | 2026-11-24 | **DIPUTUSKAN (owner 2026-11-24 lanjutan; Claude menetapkan detail).** Satu pintu masuk kolam: ubin "Kolam" di menu ≡ SEKARANG membuka panel Kolam (Breeding Kolam), sama dengan tombol Aksi Kolam dekat kolam sendiri. Ubin itu dulu memicu mode Garap kolam (K-104 lama) dan sudah dicabut dari Garap. "Bangun Kolam" menjadi baris paling atas panel (harga dari `GarapController.PondPriceText`, teks "Tap lahan kosong untuk gali kolam"), tampil bila kolam sudah terbuka dan pemain punya kurang dari `Fishing.POND.MAX_PONDS`. Tap = `GarapController.StartPond` (mode gali kolam), panel tertutup. Tampil atau tidaknya ubin: kolam terbuka (pondKakek) dan fitur kolam terbuka, seperti dulu. | Owner 2026-11-24 lanjutan; K-104 |
| K-114 | 2026-11-24 | **DIPUTUSKAN (owner 2026-11-24, koreksi; menggantikan tulisan "kartu kiri atas" di K-34 dan K-111).** Kartu pemain TETAP di kiri bawah (layout owner; tidak dipindah). Tracker ditumpuk tepat di atas kartu: tepi kiri sama, tepi bawah 8 px di atas kartu, lebar 200 px, maks 3 baris + "+N lagi" (tap membuka Quest Log). Posisinya diukur dari `AbsolutePosition` kartu (gui tracker memakai `IgnoreGuiInset`, sama dengan HUD), bukan angka tetap, dan diukur ulang saat kartu atau viewport berubah. Tinggi maks dibatasi `TRACKER_TOP` (118 px dari atas) dan 25% layar. Cek tumpang tindih dengan bar atas, mata uang, ≡, Aksi, dan dock: GUI 05 4.8 (hitungan, belum diukur di perangkat). | Owner 2026-11-24 koreksi; K-34; K-111 |
| K-113 | 2026-11-24 | **DIPUTUSKAN (owner 2026-11-24 butir 9; Claude menetapkan detail).** "Tunjukkan" diganti "Cari". Cari tidak lagi memasang panah 6 dtk: ia menutup log dan memunculkan "!" emas di atas target (billboard di jangkar tak terlihat di posisi target), naik-turun 3 kali (0,25 dtk per gerak), lalu pudar 0,5 dtk. Tidak mengubah tracker. Jangkar diberi lifetime (Debris). | Owner 2026-11-24 butir 9; K-110 |
| K-112 | 2026-11-24 | **DIPUTUSKAN (owner 2026-11-24 butir 8).** Tombol Quest di kartu pemain dihapus (menimpa bar XP). Tombol dock Quest satu-satunya pintu masuk Quest Log, bersama tap tracker. | Owner 2026-11-24 butir 8 |
| K-111 | 2026-11-24 | **DIPUTUSKAN (Claude, dari baca kode; owner 2026-11-24 butir 7; belum direproduksi di Play).** Tracker kosong walau quest aktif. Penyebab yang terbaca: `quests.tracked` hanya terisi saat quest mulai atau ditawarkan. Quest yang sudah jalan sebelum daftar itu ada (save lama) tidak punya entri, jadi tracker tidak menampilkan apa pun. Perbaikan: (a) server, sekali per save (`quests.trackInit`), quest Main dan Side yang sedang jalan dilacak (Main dulu); (b) klien selalu menampilkan quest Main yang sedang jalan, walau daftar tracked kehilangannya. Catatan: kartu pemain di kode ada di kiri BAWAH (`StatusCard`, anchor bawah), sedangkan GUI 05 4 (K-34) menulis kartu di kiri atas dan tracker di bawahnya. Penempatan itu belum diubah (keputusan owner). | Owner 2026-11-24 butir 7; K-34; GUI 05 4 |
| K-110 | 2026-11-24 | **DIPUTUSKAN (owner 2026-11-24 butir 6; Claude menetapkan detail).** Melacak = panah arah saja. Label nama gelap yang tertinggal setelah Lepas dihapus: penyebabnya `placeArrow` yang berhenti tanpa menyembunyikan GUI panah saat tidak ada target. Sekarang GUI disembunyikan. Panah di layar: panah lurus di atas kepala pemain, menunjuk ke target; di luar layar: panah di tepi layar; tanpa label nama. NPC yang menjadi target langkah aktif quest yang dilacak diberi "!" emas (billboard `TrackBang`, 200 stud) dan disinkronkan tiap 0,5 dtk (NPC bisa baru muncul). Pemberi tawaran dan quest siap diserahkan sudah punya "!" dari QuestOfferController, jadi tidak diberi dua kali. Lepas, selesai, dan hapus quest menghilangkan semuanya lewat refresh. Jalur tanah (path trail) dicatat sebagai peningkatan nanti (tidak dibuat). | Owner 2026-11-24 butir 6; roblox-camera |
| K-109 | 2026-11-24 | **DIPUTUSKAN (owner 2026-11-24 butir 5).** Tombol Quest di dock memakai ikon gulungan (aset `pesanan`, ikon lama Pesanan). Bintang tetap untuk Hadiah di kolom kanan. | Owner 2026-11-24 butir 5 |
| K-108 | 2026-11-24 | **DIPUTUSKAN (owner 2026-11-24 butir 4; Claude menetapkan detail).** Pelampung mendarat di permukaan air, tidak di tepi. Titik dari `Bobber.landing(spot)`: sinar dari 30 stud di atas spot dengan `IgnoreWater = false`; hit `Material = Water` dipakai. Bila tidak ada air, atribut `WaterY` spot; bila tak ada keduanya, puncak spot dipakai dan log `[Bobber]` muncul (spot tanpa air harus diberi `WaterY` di Studio, belum ada di map). Server membuat model (joran, tali, pelampung berjangkar dan tidak bertabrakan) dan menyimpan `From`, `Land`, `CastAt`, `BiteAt`. Tiap klien (`BobberVisuals`) menganimasikan pelampungnya sendiri: parabola 0,5 dtk, cipratan (bagian sendiri, hilang 1 dtk), mengambang dengan goyangan, celup 0,4 stud saat gigitan. Tidak ada Touched dan tidak ada fisika. Model punya lifetime 120 dtk (Debris) selain akhir sesi. Tutorial lokal memakai titik yang sama. | Owner 2026-11-24 butir 4; roblox-physics |
| K-107 | 2026-11-24 | **DIPUTUSKAN (owner 2026-11-24 kamera, butir 3; Claude menetapkan detail).** Kamera setelah "3 ikan" kembali ke shot Pak Udin karena snapshot basi: `Cutscene.Begin` menyimpan tipe kamera dan FOV, dan `Cutscene.End` mengembalikannya (tipe Scriptable tersimpan membuat kamera diam di shot terakhir). `DialogueController.releaseCamera` juga tween kembali ke CFrame tersimpan saat bicara dimulai (sisa shot Pak Udin). Perbaikan: satu jalur `NpcCamera.ReturnToPlayer()` (Custom, CameraSubject = Humanoid sekarang, FOV 70, tanpa blur), dipakai oleh Cutscene.End, DialogueController (release dan reset respawn), dan intro Mak Sari di T1Ghost. Tidak ada snapshot yang disimpan lagi. Jalur fishing tidak menulis kamera (dicek: grep). | Owner 2026-11-24 butir 3; roblox-camera |
| K-106 | 2026-11-24 | **DIPUTUSKAN (owner 2026-11-24 kamera/NPC, butir 2; Claude menetapkan detail).** NPC menghadap pemain saat bicara dimulai dan kembali saat selesai. Server (`NpcService.Face`) memutar rotasi saja selama 0,35 dtk, karena NPC berjangkar dan server yang menggerakkannya, jadi replikasi ke semua pemain. Posisi asal tidak disimpan sebagai CFrame penuh; yang disimpan rotasi asal dan posisi diambil saat balik (NPC tidak pindah). Pemicu: prompt Ngobrol (server), `NpcFace` dari klien saat dialog dibuka, `NpcFace` off saat dialog ditutup dan saat beat selesai. Respawn dan keluar pemain mengembalikan seketika (`ReleaseFace`). Satu pembicara per NPC. Turn lokal di `DialogueController` dan di beat T1Ghost dihapus. | Owner 2026-11-24 butir 2; K-105 |
| K-104 | 2026-11-24 | **DIPUTUSKAN (owner 2026-11-24, lanjutan; Claude menetapkan detail).** (a) Dock hanya 4 tombol: Garap, Hias, Tas, Quest. Kolam keluar dari dock: ubin Kolam di menu ≡ (mode Garap kolam, seperti dulu) dan tombol Aksi "Kolam" dekat kolam sendiri yang membuka panel Kolam (pola sama dengan Tungku, K-102). (b) Satu slot Aksi: tiap objek mendaftar ke `src/client/AksiSlot.luau` dengan jarak dan prioritas, hanya pemenang yang tampil. Terdekat menang. Jarak sama (selisih ≤ 1,5 studs): menang objek yang dipakai quest yang dilacak. Masih sama: prioritas 1 Pancing, 2 Pukul, 3 Bubu, 4 Kelola, 5 Kolam, 6 Masak / Pasang Tungku, 7 Lihat Gerobak (K-118). Posisi tombol tidak berubah. Belum diuji di Play. | Owner 2026-11-24 (dock dan Kolam); K-34; K-102 |
| K-102 | 2026-11-24 | **DIPUTUSKAN (Claude, konservatif; owner 2026-11-24 butir 8 lanjutan, R5.8b).** Dapur tidak punya tombol di dock. Dapur dibuka dari satu tombol Aksi (slot Aksi, 104 px, sama dengan Pukul dan Pancing): **Masak** saat pemain dalam 12 studs (`Dapur.KITCHEN_REACH`) dari Tungku sendiri, membuka panel Dapur dengan Warung; **Pasang Tungku** saat Tier 1 belum berdiri dan Tungku ada di tas (`DapurBuild`, server cek jarak ke lahan 60 studs seperti dulu). Tombol Aksi bisa bertabrakan dengan Aksi Pukul bila keduanya dekat; belum diuji di Play. Warung dan upgrade tetap di panel Dapur. | Owner 2026-11-24 butir 8; K-34; GDD 9 |
| K-101 | 2026-11-24 | **DIPUTUSKAN (Claude, konservatif; owner 2026-11-24 butir 8 lanjutan, R5.8a).** Tungku (Inti Dapur Tier 1) dicraft di Meja Crafting sebagai resep `tungku` (Config/Mining): 10 Kayu + 8 Batu + 5 Tanah Liat, sama dengan GDD 9, Lv 6. Semua bahan dari Hutan Nambang (Lv 4), tidak perlu pengganti. Resep satu per craft (`once`), tidak bisa x10, dan hanya saat belum punya dapur dan belum ada Tungku di tas. Tier 1 tidak lagi dibangun dari bahan di panel Dapur: `DapurBuild` memakai 1 Tungku dari tas lalu memasangnya di lahan lewat auto-place 2×2 yang sudah ada. Tidak ada migrasi (Kampoeng belum rilis). Upgrade Tier 2 dan 3 tetap pakai bahan di panel (belum disentuh). | Owner 2026-11-24 butir 8; GDD 9; K-34 |
| K-100 | 2026-11-24 | **DIPUTUSKAN (Claude, konservatif; owner 2026-11-24 permintaan lanjutan).** Remote `QuestTurnIn` di server menolak bila quest tidak dalam status siap diserahkan, dan bila pemain lebih jauh dari pemberi daripada `Npcs.TALK_DISTANCE` (16 studs, jarak prompt Ngobrol). Penolakan jarak memberi toast "Dekati <pemberi> dulu". Pengecekan memakai posisi NPC dari `NpcService.Position` (require lazy, karena NpcService memakai QuestService). | Owner lanjutan 2026-11-24; K-93; K-34 |
| K-97 | 2026-11-24 | **DIPUTUSKAN (Claude; owner playtest 2026-11-24, quest butir 7; belum dicek di Play).** Saat Lv 5 membuka Kanal Barat, baris level-up menyebut pemberinya: `location.sungai_meet` = "Kanal Barat (temui Kak Fajar)". Baris ini masuk antrean level-up setelah banner Level (K-89). Quest `s5_ikan_kanal` (dialog sudah ada) memberi "!" di Kak Fajar dan masuk tracker lewat aturan K-94, dengan panah ke Kak Fajar. | Owner playtest 2026-11-24 butir 7; K-89; K-94 |

---

## 4. Keputusan Lama yang Sudah Final (dari Lampiran D v7.7 & Roadmap)

Sudah dimasukkan ke GDD v8.0. Dicatat di sini supaya riwayat tidak hilang saat file lama dihapus.

- **GDD v8.2 (2026-11-23):** K-45 (lokasi ikan Mid di kolam, Bab 6.4), K-46 (basis ukuran 40/40/15/5), K-47 (Legenda 0,5%), K-48 (angka awal Koin/Bunga dan hadiah Album ditulis di Bab 4.1). File dinamai ulang dari v8.1.
- **GDD v8.3 (2026-11-23):** Revisi Playtest Putaran 1 (K-53…K-57): tutorial, mancing (Pakai/Tarik), quest pool & Quest Log, Event & Pasar Malam, bug grup A. Lihat GDD "Revisi Playtest Putaran 1" dan Roadmap Bab 19.
- **GDD v8.4 (2026-11-23):** Revisi Putaran 2 (K-58…K-63): Season Bantu, album dekor, Order mingguan, warna dinding (R3.9), Gembor Emas, Jual Semua. Lihat GDD "Revisi Putaran 2" dan Roadmap Bab 20.

| Asal | Keputusan final |
|------|-----------------|
| D#1, D#24 (sebagian) | 32 spot Sungai Lahan (8 per sungai sumbu), Early saja, Lv 1. Kanal Barat Lv 5 (Mid + Belut Emas). Kanal Timur Lv 10 (Late + Legenda). |
| D#2, D#3 | Mini-game tarik: `FILL_GAIN 0.28`, `FILL_DRAIN 0.06`, `ZONE_SPEED 0.9`, `ZONE_SPEED_LEFT 0.55`. Coachmark tarik tidak dipakai. |
| D#8, D#49 | Tracker quest: tinggi maks min(200 px, 25% layar), maks 3 baris + "+N lainnya". |
| D#11 | XP top-up 115 di langkah `jual_ikan`; tutorial selesai di 158 XP. |
| D#12 | Semua quest menunggu tutorial jual ikan (`t1b_kolam`) selesai. |
| D#13, D#30 | Kolam Tanah Lv 4, lewat Kolam Kakek (M3). `Fishing.POND.UNLOCK_LEVEL = 4`. |
| D#14 | Hapus petak berbayar = refund 50% (status prinsip: lihat K-09). |
| D#15 | Login Mingguan berulang tiap minggu (Senin 05:00 WIB), 10 Bunga/minggu. |
| D#16, D#17 | Peti Bunga = 25 Bunga. Sumber peti di kode: tiap Title, tiap milestone Album, Season F2P hari 30. |
| D#19 | Galeri: pemilik offline = lahan kosong, tanpa toast, tanpa rumah snapshot. |
| D#29 | Semua `DisplayOrder` memakai `UiKit.LAYER`. |
| D#31 | Bicara Bang Jali tidak digerbang (S3 mulai dari sana); jual digerbang server. KBPungut digerbang Gerobak. |
| D#38 | Lebar kotak tarik dihitung server (`FishService.zoneWidthFor`). |
| D#39 | Skill dibuka Player Lv 2 (`FeatureGate.LEVEL_GATES`). |
| D#42, D#49 | Tidak ada pilih umpan; dipakai umpan pertama menurut urutan `Fishing.BAITS`. |
| Roadmap §5 #1 | FTUE berakhir di jual ikan ke Kak Fajar. |
| Roadmap §5 #2 | Super dihapus. Kualitas cap Bagus 50%, Prima 20%. Buff Tani +10% absolut ke Bagus. |
| Roadmap §10 | Rantai quest v0.3 disetujui apa adanya (Warung Lv 7, Bubu Lv 8, Hias Lv 5, Bang Jali Lv 3, Kolam lewat Kolam Kakek Lv 4). |
| Skill Tree Bab 6 | Kapak + Tukang Cepat menumpuk, maks +4 bahan/node (dasar 4 → 8). Kapak Bunga = alternatif Kapak Besi (+1). Buff Tukang/Tebang hanya +1 saat Critical. |
| Roadmap playtest 2 | Jual pertama ke Pak Udin lewat bubble "Jual semua" (tanpa GUI Jual). Siram wajib di tutorial. |

Usulan interim lama yang **tetap berjalan di kode** dan dianggap final kecuali owner membuka lagi (Roadmap §5 #3–#12): milestone Album 25/50/75/100%; split hadiah Agenda (Panen 200 / Pancing 250 / Masak 300 / Bantu 150 / Nambang 400); feeder per ekor; Warung 1 slot = 1 jenis + tumpukan; Dapur/Warung auto-place 2x2; Firasat bubble ≤ 25 stud; chat `/e` diblok; angka P2-6 (harga varian 2x, Gelang 60/30/10, dst.); angka P2-7 (Quest Harian 3 + Mingguan 3, harga Toko Bunga, hadiah Surat). Nilai persisnya ada di `Config/*` dan wajib disalin ke GDD saat R0.4.
