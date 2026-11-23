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
| A-28 | Sedang | Roadmap §9.1 vs Quest v0.3 | Agenda di kode dibuka oleh `starter_pagar` (starter chain lama), Quest v0.3 bilang dibuka oleh M1 (Lv 2). Belum jelas sisa starter chain sudah dibersihkan. | R0.4 (cek kode) |
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
| A-67 | Tinggi | Prinsip 16 vs Quest S6, Bab 14.4, Skill, 15.4 | **Game tidak bisa lengkap kalau main sendiri**: S6 "Bantu 1 lahan pemain lain" (pembuka fitur Bantu), side "Bantu 10 lahan", skill Tetangga Baik, title Kebun Favorit (200 like). | K-17, K-28 → R2.5 |
| A-68 | Sedang | Bab 8.7 vs 12.5 | "Bagikan kode Blueprint ke teman" vs "chat tidak bisa kirim kode". Tidak ada jalan berbagi. | K-39 → R2.6 |

### 2.9 GUI

| ID | Sev | Lokasi | Masalah | Beres di |
|----|-----|--------|---------|----------|
| A-69 | Tinggi | Bab 23 vs kode F-1, Test Plan B-UI-6 | Tab Tas: GDD (Tanaman / Ikan / Olahan / Bahan / Lainnya) vs kode (Semua / Bibit / Panen / Ikan / Alat / Umpan). **Olahan dan Bahan tidak punya tab**, padahal Makan olahan lewat Tas (GUI 6.3, 6.9). | K-33 → R1.7 |
| A-70 | Sedang | GUI 5.1 vs kode F-2/B-2 | Zona atas-tengah dipakai dua komponen: Bubble Instruksi dan toast stack. Bisa saling timpa. | K-40 |
| A-71 | Sedang | GUI 6.2 vs Bab 10 vs kode | Ukuran node skill: 64 px (GUI 6.2), 44 px mockup / 40 implementasi (GUI 10), kode 40. | GUI v1.0 (40) |
| A-72 | Rendah | GUI 4.5 vs Changelog 0.3.4 #7 | Coachmark 50/55 (GUI) vs 50/60 (kode); toast juga 60 → dua lapisan di angka sama. | GUI v1.0 (tabel ikut kode, catatan bentrok) + R3.7 |
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

## 3. Keputusan Desain K-01…K-42 (SEMUA DIPUTUSKAN)

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

**Alasan K-16 = (b):** game dibuat 100% lewat Claude Code, jadi scope rilis dijaga. Kucing Alun-alun dan Joran Hilang butuh sistem baru yang kecil tapi tidak dibutuhkan jalan cerita. Dampak: Title "Penyayang Kucing" ikut tertunda; kedua quest tidak muncul di Quest Log rilis; dikerjakan di Update 1 (R12.4b).

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

---

## 4. Keputusan Lama yang Sudah Final (dari Lampiran D v7.7 & Roadmap)

Sudah dimasukkan ke GDD v8.0. Dicatat di sini supaya riwayat tidak hilang saat file lama dihapus.

- **GDD v8.2 (2026-11-23):** K-45 (lokasi ikan Mid di kolam, Bab 6.4), K-46 (basis ukuran 40/40/15/5), K-47 (Legenda 0,5%), K-48 (angka awal Koin/Bunga dan hadiah Album ditulis di Bab 4.1). File dinamai ulang dari v8.1.

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
