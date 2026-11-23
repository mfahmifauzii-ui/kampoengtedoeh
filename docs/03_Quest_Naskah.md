# KAMPOENG TEDOEH — Quest & Naskah v1.0

> Menggantikan `Quest_Kampoeng_Tedoeh_v0.3.md` dan `Naskah_Dialog_Kampoeng_Tedoeh_v0.1.md`.
> Status: rantai Lv 1–10 **disetujui owner** (2026-11-22) dan sudah di kode (Q-1…Q-5). Baris bertanda **[USULAN]** adalah teks baru dari audit, belum di kode, menunggu K-xx (`02_Audit_Perbaikan.md`).
> Angka gameplay (harga, XP, level) ada di `01_GDD_Kampoeng_Tedoeh_v8.3.md`. File ini hanya urutan quest, feature gate, dan teks.
> Semua teks masuk `Locale/id.luau`. Tidak ada teks dialog di file kode.

---

## 1. Tujuan

Setelah tutorial selesai (jual ikan ke Kak Fajar), pemain selalu tahu langkah berikutnya. Setiap fitur dikenalkan oleh quest pada saat dibutuhkan, bukan muncul sendiri di HUD.

| | Main Quest | Side Quest |
|---|---|---|
| Isi | Membuka **gameplay baru** atau **milestone cerita** (MQ11, MQ12) | Lanjutan gameplay yang sudah terbuka (bibit, lokasi, hewan, cara jual) |
| Banner Dimulai / Selesai | Ya (`BannerController`, pemain dikunci ±3 dtk, GUI lain disembunyikan) | Tidak. Toast 1 baris dari pemberi saat selesai |
| Tracker | Selalu paling atas, tombol `Tunjukkan` | Di bawah Main. Bila tidak ada Main, Side teratas dapat `Tunjukkan` |
| Aktif | Maks 1 | Boleh beberapa (tracker maks 3 baris + "+N lainnya") |
| Mulai | Ditawarkan (`!` di pemberi) → dialog Mulai → `QuestAccept` | Sama; semua side punya naskah (✔ K-14) |
| Menahan jalur | Ya (Main berikutnya menunggu) | Tidak pernah |

Tanda `!` tidak muncul selama tutorial. Semua quest baru muncul setelah `t1b_kolam` selesai.

---

## 2. Feature Gate ("Buka Lewat Quest") — LOCKED

| State | Kondisi | Yang dilihat pemain |
|-------|---------|---------------------|
| Terkunci | Level belum cukup | Tidak ada apa-apa. Tidak ada tombol abu-abu. |
| Siap | Level cukup, langkah quest belum sampai | Quest di tracker / `!` di pemberi. Tombol fitur masih tersembunyi. |
| Dikenalkan | Langkah yang menyuruh pakai fitur aktif | Tombol / prompt muncul, disorot (glow + panah), 1 baris instruksi. |
| Terbuka | Langkah itu selesai sekali | Terbuka permanen (`PlayerData.features.open`). |

Aturan:
1. **Level = syarat, Quest = pintu.** Naik level hanya memunculkan quest.
2. Level buka fitur = level quest pengenalnya (GDD Bab 4.4).
3. **Tidak ada jalan buntu.** Langkah yang menyuruh pakai fitur harus bisa dikerjakan saat itu (bahan / Koin / item disediakan atau pasti dimiliki).
4. Quest pengenal muncul berurutan, tidak sekaligus, walau pemain loncat level.
5. Agenda, Order, Harian, Mingguan, Side hanya memakai fitur yang sudah **Terbuka**.
6. Tidak gagal karena waktu.
7. **Klien untuk kesan, server untuk hasil.** Dialog, `!`, sorotan, panah, NPC menoleh = klien. Progres, hadiah, status Terbuka = server. Remote fitur tertutup ditolak server dengan toast (`feature.locked`, ✔ K-37).
8. Kepadatan: maks 1 quest di Lv 1, maks 3 (Main + Side) per level setelahnya. Tiap quest 1–3 langkah, ±2–5 menit.
9. XP quest kecil: total XP quest Lv 1–10 ≤ 25% dari 3.150 XP.
10. Pengecualian gerbang level (bukan quest): Pohon Skill (Player Lv 2).

### 2.1 Fitur yang Disembunyikan Sampai Quest

| Fitur / UI | Lv | Muncul di |
|------------|----|-----------|
| Tab Beli Pak Udin | 1 | Akhir tutorial |
| Pohon Skill | 2 | Level (bukan quest) |
| Tombol Surat | 2 | S2 |
| Agenda, Gerobak Kaget, Order (Pesanan), prompt Kerja Bakti | 2 | M1 |
| Jual ke Bang Jali (bicara tidak digerbang) | 3 | S3 |
| Rangka rumah | 3 | S4 |
| Hutan Nambang, Tombol Craft | 4 | M2 |
| Tombol Kolam | 4 | M3 langkah 2 |
| Tombol Hias | 5 | M4 |
| Kandang Ayam, Ambil Semua | 5 | M5 |
| Mancing Kanal Barat | 5 | S5 |
| Prompt Bantu | 5 | S6 |
| Dapur (Tombol Aksi dekat Tungku), Makan, ikon buff | 6 | M6 |
| Warung Pemain | 7 | M7 |
| Bubu | 8 | M8 (⚠ sistem belum ada) |
| Bundel Kakek | 8 | M9 |
| Kandang Bebek | 10 | S8 |
| Mancing Kanal Timur | 10 | S9 |

Tidak digerbang quest: bibit/ikan/joran/umpan baru, Login, Peti, Season, Album, Settings, petak 13+.

---

## 3. Pace (Lv 1–10)

✔ K-11: angka di bawah memakai ±1.500 XP/jam (campur nanem + mancing). GDD Bab 17.2 memakai pace lebih lambat untuk Lv 1–20. Simulasi R9.1 menentukan. Menit sudah digeser −6 dari v0.3 karena tutorial sekarang ±4 menit (bukan 10).

| Lv | Menit dari awal (perkiraan) | Lama di level | Main | Side |
|----|------------------------------|---------------|------|------|
| 1 | 4 (setelah tutorial) | ±3 | – | S1 |
| 2 | 7 | ±10 | M1 | S2 |
| 3 | 17 | ±12 | – | S3, S4 |
| 4 | 29 | ±13 | M2 → M3 | – |
| 5 | 42 | ±14 | M4 → M5 | S5, S6 |
| 6 | 56 | ±15 | M6 | – |
| 7 | 71 | ±16 | M7 | – |
| 8 | 87 | ±18 | M8 → M9 | – |
| 9 | 105 | ±19 | – | S7 |
| 10 | 124 | – | – | S8, S9 |

Sesi pertama (±30–40 menit) berakhir sekitar Lv 4: pemain masuk Hutan dan dapat Kolam Kakek (hadiah besar sesi pertama).

---

## 4. Naskah Tutorial (sudah di kode)

### 4.0 Aturan Naskah

1. Satu baris = satu kotak dialog, maks ±110 karakter. Lebih panjang = pecah dengan Next.
2. Satu ucapan selesai dulu, baru berikutnya (antrean T1Dialog).
3. "Ikuti panah" hanya kalau targetnya jauh.
4. NPC menyebut lokasi yang benar. Kak Fajar tutorial = sungai dekat lahan; Kak Fajar biasa = lapak pinggir kanal alun-alun.
5. Kunci locale: tutorial `tut.<tutorial>.<step>.<n>`; quest `dlg.<id>.start.<n>`, `dlg.<id>.done.<n>`, tracker `quest.<id>.s<n>`; `{name}` = nama pemain.
6. Main: dialog Mulai (2–3 baris) → banner Dimulai → langkah di tracker → banner Selesai → 1 baris penutup pemberi (foto NPC, NPC tidak perlu dekat).
7. Side: dialog Mulai saat bicara dengan pemberi → toast 1 baris pemberi saat selesai.

**Suara NPC**

| NPC | Gaya |
|-----|------|
| Mak Sari | Hangat, keibuan. "Nak", menyebut diri "Mak". |
| Pak Udin | Pedagang ramah, bangga warungnya. Menyebut diri "Pak Udin". |
| Kak Fajar | Muda, santai. "Aku / kamu". |
| Pak Amran | Tukang kayu, tenang, praktis. "Saya / kamu". Sering menyebut Kakek. |
| Nek Ani | Sesepuh pos ronda. "Nenek", memanggil "Cu". |
| Bang Jali | Santai, akrab. "Abang". |

### 4.1 Intro — Mak Sari (cutscene, Next tiap baris, tanpa toast)

| Kunci | Teks |
|-------|------|
| `tut.t1.intro.1` | Nak... akhirnya kamu pulang juga. Mak kangen! |
| `tut.t1.intro.2` | Ini lahan peninggalan Kakek Daeng. Sudah lama nggak ada yang ngurus. |
| `tut.t1.intro.3` | Dulu kakekmu rajin sekali di sini. Sekarang giliranmu, ya? |
| `tut.t1.intro.4` | Tenang, Mak temenin. Kita mulai pelan-pelan aja. |

### 4.2 Langkah T1 — Mak Sari (Bubble Instruksi)

| Langkah | Kunci | Teks |
|---------|-------|------|
| cangkul | `tut.t1.cangkul.1` | Garap tanahnya dulu, Nak. Ketuk tombol Cangkul yang menyala. |
| cangkul (mode Garap) | `tut.t1.cangkul_ground.1` | Nah, ketuk rumput yang menyala buat bikin petak. |
| tanam | `tut.t1.tanam.1` | Sekarang tanam Kangkungnya. Dekati petaknya, lalu ketuk Tanam. |
| tanam (lama) | `tut.t1.tanam_stuck.1` | Bibit awal ini cepat tumbuhnya, Nak. Ditunggu sebentar ya. |
| siram | `tut.t1.siram.1` | Tanamannya haus. Ketuk petaknya, lalu ketuk Siram. |
| panen (menunggu) | `tut.t1.panen_wait.1` | Sabar ya, Kangkung ini cepat kok matangnya. |
| panen (matang) | `tut.t1.panen_harvest.1` | Sudah matang! Ketuk Panen. |
| jual | `tut.t1.panen_sell.1` | Bawa hasil panenmu ke Pak Udin di warung alun-alun. Ikuti panah di tanah, ya. |

### 4.3 Jual Pertama — Pak Udin (cutscene proximity)

| # | Kunci | Teks | Tombol |
|---|-------|------|--------|
| 1 | `tut.t1.jual.1` | Halo, {name}! Kamu cucunya Kakek Daeng, ya? Wah, sudah besar sekarang. | Next |
| 2 | `tut.t1.jual.2` | Itu Kangkung dari lahanmu? Sini, Pak Udin beli. | **Jual semua** |
| 3 | `tut.t1.jual.3` | Bagus panenmu! Kalau ada lagi, bawa ke sini. Bibit juga Pak Udin jual. | Next |
| 4 | `tut.t1.jual.4` | Oh iya, Kak Fajar lagi mancing di sungai dekat lahanmu. Samperin, katanya ada titipan buat kamu. | Next |

Langkah `kak_fajar`: `tut.t1b.kak_fajar.1` (Pak Udin) — Kak Fajar ada di sungai dekat lahanmu. Ikuti panah di tanah, ya.

### 4.4 Hadiah Joran — Kak Fajar (sungai lahan, proximity)

| # | Kunci | Teks | Tombol |
|---|-------|------|--------|
| 1 | `tut.t1b.hadiah.1` | Halo, {name}! Aku Fajar. Kata Pak Udin kamu baru pulang, ya? | Next |
| 2 | `tut.t1b.hadiah.2` | Nih, joran bambu sama umpan buat kamu. Anggap aja hadiah selamat datang. | **Terima Hadiah** |

→ fade → `tut.t1b.mancing.1`: Coba lempar ke riak air itu. Ketuk tombol Mancing yang menyala.

### 4.5 Ikan Pertama + Jual — Kak Fajar (satu rangkaian, tanpa sela)

| # | Kunci | Teks | Tombol |
|---|-------|------|--------|
| 1 | `tut.t1b.jual_ikan.1` | Wah, dapat! Lumayan buat percobaan pertama. | Next |
| 2 | `tut.t1b.jual_ikan.2` | Mau dijual? Aku beli ikan di sini. | **Jual semua** |
| 3 | `tut.t1b.jual_ikan.3` | Sungai ini dekat lahanmu, jadi bisa mancing sambil nunggu panen. | Next |
| 4 | `tut.t1b.jual_ikan.4` | Aku balik ke lapak dulu. Butuh umpan atau mau jual ikan, cari aku di pinggir kanal alun-alun. | **Ok, Kak Fajar** |

→ fade → banner `Selesai` (tutorial). Tidak ada baris lain.

---

## 5. Quest Lv 1–10

### 5.1 Main Quest

| # | Lv | Judul | Pemberi | Membuka | Langkah | Hadiah | Status kode |
|---|----|-------|---------|---------|---------|--------|-------------|
| M1 | 2 | Kampung Hari Ini | Nek Ani | Agenda, Gerobak Kaget, Order, Kerja Bakti | Buka Agenda → Selesaikan 1 tugas Agenda → Lihat Gerobak Kaget | 100 Koin | Ada; ⚠ Agenda belum punya UI (R2.2) |
| M2 | 4 | Ke Hutan | Pak Amran | Nambang, Crafting | Pergi ke Hutan → Kumpulkan 10 Batu + 9 Kayu → Craft 2 Papan | 20 XP + 50 Koin [USULAN] | Ada; butuh objek "Meja Crafting" di Studio |
| M3 | 4 | Kolam Kakek | Kak Fajar | Kolam | Bangun Kolam Kakek (setor 10 Batu + 5 Kayu + 3 ikan Early; tombol Kolam muncul di langkah ini) → Tangkap 1 ikan di kolam | Kolam Kakek + 300 Koin + 60 XP | Ada |
| M4 | 5 | Pagar Pertama | Pak Amran | Hias | Pasang 1 Pagar Bambu | – | Ada |
| M5 | 5 | Kokok Pertama | Pak Udin | Ternak | Terima Ayam → Isi pakan → Ambil 1 telur | Ayam + Kandang Ayam Lv 1 | Ada |
| M6 | 6 | Dapur Pertama | Mak Sari | Dapur + Buff | Craft Tungku → Masak 1 olahan → Makan 1 olahan | 200 Koin | Ada |
| M7 | 7 | Warung Pertama | Mak Sari | Warung | Pasang Warung → Jual 1 olahan di Warung | 200 Koin | Ada |
| M8 | 8 | Jebakan Kak Fajar | Kak Fajar | Bubu | Pasang 1 Bubu (selesai saat terpasang, panen 6 jam tidak ditunggu) | 1 Bubu Bambu | **Diblok** — sistem Bubu belum ada (R2.1) |
| M9 | 8 | Sumur Tua | Nek Ani | Bundel Kakek | Pulihkan Sumur Tua (10 Kayu + 5 Batu + 2 olahan) | 300 Koin + 5 Bunga (✔ K-31) | Ada |
| MQ11 | 15 | Legenda Pertama | Kak Fajar | (cerita) | Dapat 1 Ikan Legenda **atau** panen 1 Prima tanaman Late (✔ K-13) | 500 Koin + Title Penakluk Legenda | Ada (`mq11_legenda`) |
| MQ12 | – | Warga Kampoeng Tedoeh | Mak Sari | (cerita) | Semua Main selesai + Album 50% | Title Warga Kampoeng Tedoeh + 10 Bunga | Ada (`mq12_warga`, auto) |

- M2 minta 10 Batu + 9 Kayu: 4 Kayu jadi 2 Papan, sisa 10 Batu + 5 Kayu pas untuk M3. M3 muncul setelah M2 selesai.
- 3 ikan Early M3 biasanya sudah dimiliki dari Sungai Lahan; kalau belum, `Tunjukkan` menunjuk sungai terdekat dulu.

### 5.2 Side Quest

| # | Lv | Judul | Pemberi | Langkah | Membuka | Hadiah |
|---|----|-------|---------|---------|---------|--------|
| S1 | 1 | Bibit Kedua | Pak Udin | Beli 2 Bibit Bayam → Tanam 2 Bayam | – | 50 Koin [USULAN] |
| S2 | 2 | Surat Pertama | Mak Sari | Baca Surat Kakek #1 | Tombol Surat | Hadiah Surat #1 |
| S3 | 3 | Tetangga di Depan | Bang Jali | Jual 1 barang ke Bang Jali | Jual Bang Jali | – |
| S4 | 3 | Rumah dari Kakek | Pak Amran | Ngobrol dengan Pak Amran | Rangka rumah | – |
| S5 | 5 | Ikan Kanal | Kak Fajar | Tangkap 1 ikan Mid di Kanal Barat | Kanal Barat | 100 Koin [USULAN] |
| S6 | 5 | Kenalan Tetangga *(dulu "Tetangga Baik (kenalan)")* | Nek Ani | Bantu 1 lahan (pemain lain **atau Kebun Warga**, ✔ K-17) | Bantu | +40 Koin +10 XP (dari Bantu) |
| S7 | 9 | Sawah | Pak Udin | Tanam 1 Padi → Panen Padi (dapat Jerami). *Langkah 2 makan 2 jam; Side tidak menahan apa pun.* | – | 100 Koin [USULAN] |
| S8 | 10 | Kandang Bebek | Pak Udin | Bangun Kandang Bebek → Beli 1 Bebek | Kandang Bebek | 200 Koin [USULAN] |
| S9 | 10 | Kanal Timur *(dulu "Empang", ✔ K-23)* | Kak Fajar | Tangkap 1 ikan di Kanal Timur | Kanal Timur | 200 Koin [USULAN] |

### 5.3 Side Quest Lama (GDD v7.x Bab 14.4) — tanpa banner

| Judul | Id kode | Pemberi | Syarat | Hadiah | Status |
|-------|---------|---------|--------|--------|--------|
| Kucing Alun-alun | (belum ada) | Pak Udin | Kasih makan kucing 3 hari berbeda | Title Penyayang Kucing + pet kucing kampung (kosmetik) | **Update 1** (✔ K-16 b): tidak muncul di Quest Log rilis, data disimpan dengan `released=false` |
| Joran Hilang | (belum ada) | Kak Fajar | Cari 3 joran hilang di pinggir air | Joran Kayu + 200 Koin | **Update 1** (✔ K-16 b): tidak muncul di Quest Log rilis, data disimpan dengan `released=false` |
| Rumah Rapi | `side_rumah_rapi` | Pak Amran | Pasang 20 piece | Title Dinding Spesial + warna dinding spesial ✔ K-15 | Ada, tanpa naskah |
| Ringan Tangan *(dulu "Tetangga Baik")* | `side_tetangga` | Nek Ani | Bantu 10 lahan | 300 Koin ✔ K-15 | Ada, tanpa naskah |
| Resep Mak | `side_resep` | Mak Sari | Masak 3 resep berbeda | 200 Koin [USULAN] ✔ K-15 | Ada, tanpa naskah |
| Panen Prima | `side_prima` | Mak Sari | Panen 5 Prima | Skin Gembor Emas ✔ K-15 | Ada, tanpa naskah |
| Ikan Jumbo | `side_jumbo` | Kak Fajar | Dapat 1 ikan Jumbo | 200 Koin + Title Raja Jumbo | Ada, tanpa naskah |
| Kolektor Album | `side_kolektor` | Nek Ani | Album 25% | 10 Bunga | Ada, auto |
| Kerja Bakti 10x | `side_kerjabakti` | Nek Ani | Ikut 10 Kerja Bakti | 500 Koin + Title Pekerja Bakti | Ada; naskah tidak ada di v0.1 (cek kode R0.4) |
| Warung Laris | (cek kode, naskah pakai `side_warung`) | Mak Sari | Jual 10 olahan di Warung | 300 Koin | Cek kode (R0.4) |

---

## 6. Naskah Quest

### 6.1 Main

**M1 Kampung Hari Ini — Nek Ani** (baris 1 versi tanpa perkenalan, ✔ K-20)

| Kunci | Teks |
|-------|------|
| `dlg.m1.start.1` | Kamu cucunya Daeng, kan? |
| `dlg.m1.start.2` | Tiap hari di kampung ada saja yang bisa dikerjakan, Cu. Nenek tulis di Agenda. |
| `dlg.m1.start.3` | Oh, kalau ada gerobak lewat di alun-alun, mampir. Barangnya suka aneh-aneh. |
| `quest.m1.s1` / `s2` / `s3` | Buka Agenda / Selesaikan 1 tugas Agenda / Lihat Gerobak Kaget di alun-alun |
| `dlg.m1.done.1` | Rajin juga kamu, Cu. Mirip kakekmu. |

**M2 Ke Hutan — Pak Amran**

| Kunci | Teks |
|-------|------|
| `dlg.m2.start.1` | Sudah waktunya, {name}. Ayo ke Hutan. Kayu, batu, bambu, semua ada di sana. |
| `dlg.m2.start.2` | Pukul pas lingkarannya ketemu tanda. Hasilnya lebih banyak. |
| `dlg.m2.start.3` | Bawa pulang batu dan kayu, lalu ubah sebagian kayunya jadi papan di Meja Crafting. |
| `quest.m2.s1` / `s2` / `s3` | Pergi ke Hutan Nambang / Kumpulkan 10 Batu dan 9 Kayu / Craft 2 Papan di Meja Crafting |
| `dlg.m2.done.1` | Tangan kamu cocok jadi tukang. Sisa batu dan kayunya simpan, Kak Fajar lagi butuh. |

**M3 Kolam Kakek — Kak Fajar**

| Kunci | Teks |
|-------|------|
| `dlg.m3.start.1` | {name}! Kakekmu dulu punya kolam ikan di lahan itu. Mau kita bangun lagi? |
| `dlg.m3.start.2` | Bawa batu sama kayunya, plus 3 ikan dari sungai buat bibitnya. |
| `dlg.m3.start.3` | **[FINAL, ganti dari "…di menu Garap"]** Tombol Kolam sudah muncul di bawah. Bangun di mana saja di lahanmu. |
| `quest.m3.s1` / `s2` | Bangun Kolam Kakek (10 Batu, 5 Kayu, 3 ikan Early) / Tangkap 1 ikan di kolammu |
| `dlg.m3.done.1` | Kolam Kakek hidup lagi. Ikannya bakal beranak sendiri, rajin-rajin dicek ya. |

**M4 Pagar Pertama — Pak Amran**

| Kunci | Teks |
|-------|------|
| `dlg.m4.start.1` | Lahanmu masih polos. Pasang pagar bambu dulu, biar kelihatan ada yang punya. |
| `dlg.m4.start.2` | Buka menu Hias, pilih Pagar Bambu, taruh di mana kamu suka. |
| `quest.m4.s1` | Pasang 1 Pagar Bambu |
| `dlg.m4.done.1` | Nah, mulai kelihatan seperti rumah. |

**M5 Kokok Pertama — Pak Udin**

| Kunci | Teks |
|-------|------|
| `dlg.m5.start.1` | {name}, ayam Pak Udin lebih satu. Ambil saja, buat kamu. |
| `dlg.m5.start.2` | Kandangnya sudah Pak Udin pasang di lahanmu. Isi pakannya, nanti dia bertelur. |
| `quest.m5.s1` / `s2` | Isi pakan ayam / Ambil 1 telur |
| `dlg.m5.done.1` | Telur pertama! Jual ke Pak Udin atau simpan buat masak nanti. |

**M6 Dapur Pertama — Mak Sari**

| Kunci | Teks |
|-------|------|
| `dlg.m6.start.1` | Nak, hasil kebunmu enak kalau dimasak. Ayo bikin tungku. |
| `dlg.m6.start.2` | Kalau dimakan sendiri, badan jadi semangat. Kerja di kebun atau mancing jadi lebih lancar. |
| `quest.m6.s1` / `s2` / `s3` | Craft Tungku / Masak 1 olahan / Makan 1 olahan |
| `dlg.m6.done.1` | Masakanmu enak, Nak. Persis resep Mak. |

**M7 Warung Pertama — Mak Sari**

| Kunci | Teks |
|-------|------|
| `dlg.m7.start.1` | Sayang kalau masakanmu dimakan sendiri terus. Buka warung kecil di lahanmu, Nak. |
| `dlg.m7.start.2` | Taruh satu olahan di etalase. Nanti ada orang lewat yang beli. |
| `quest.m7.s1` / `s2` | Pasang Warung / Jual 1 olahan di Warung |
| `dlg.m7.done.1` | Laku! Mak bangga sama kamu. |

**M8 Jebakan Kak Fajar — Kak Fajar**

| Kunci | Teks |
|-------|------|
| `dlg.m8.start.1` | Mau dapat ikan tanpa nunggu di sungai? Pakai bubu. |
| `dlg.m8.start.2` | Pasang di air, tinggal pergi, nanti ambil isinya. Aku kasih satu buat kamu. |
| `quest.m8.s1` | Pasang 1 Bubu |
| `dlg.m8.done.1` | Sip. Bubu butuh 6 jam, jadi tinggal aja. Nanti balik ambil ikannya. |

**M9 Sumur Tua — Nek Ani**

| Kunci | Teks |
|-------|------|
| `dlg.m9.start.1` | Kamu tahu sumur tua di lahanmu, Cu? Dulu satu kampung ambil air di situ. |
| `dlg.m9.start.2` | Kerangkanya masih ada. Pulihkan, ya. Kakekmu pasti senang. |
| `quest.m9.s1` | Pulihkan Sumur Tua (10 Kayu, 5 Batu, 2 olahan) |
| `dlg.m9.done.1` | Airnya jernih lagi. Mulai sekarang sumur ini menyiram satu petakmu tiap hari. |

**MQ11 Legenda Pertama — Kak Fajar**

| Kunci | Teks |
|-------|------|
| `dlg.mq11.start.1` | Kakekmu dulu pernah cerita soal ikan yang cuma muncul sesekali. Orang sini bilang ikan legenda. |
| `dlg.mq11.start.2` | Atau kalau kamu lebih suka kebun, panen Prima dari tanaman yang lama tumbuhnya juga sama hebatnya. |
| `quest.mq11.s1` | Dapat 1 Ikan Legenda **atau** panen 1 Prima tanaman Late |
| `dlg.mq11.done.1` | Seluruh kampung sudah dengar. Kakekmu pasti bangga. |

**MQ12 Warga Kampoeng Tedoeh — Mak Sari**

| Kunci | Teks |
|-------|------|
| `dlg.mq12.start.1` | Nak, Mak lihat lahan Kakek sekarang ramai lagi. Kebun, kolam, warung... |
| `dlg.mq12.start.2` | Isi Album Kampung sampai setengah, ya. Biar semua orang tahu kamu sudah jadi warga sini. |
| `quest.mq12.s1` | Selesaikan Album Kampung 50% |
| `dlg.mq12.done.1` | Selamat datang di rumah, {name}. Kamu warga Kampoeng Tedoeh sekarang. |

### 6.2 Side S1–S9

| # | Kunci | Teks |
|---|-------|------|
| S1 | `dlg.s1.start.1` | Bibitnya habis? Coba Bayam, {name}. Agak lama dari Kangkung, tapi harganya lebih bagus. |
| | `quest.s1.s1` / `s2` | Beli 2 Bibit Bayam / Tanam 2 Bayam |
| | `dlg.s1.done.1` | Nah, ladangmu mulai ramai! |
| S2 | `dlg.s2.start.1` | Nak, Mak nemu surat di rumah Kakek. Kayaknya buat kamu. |
| | `quest.s2.s1` | Baca Surat Kakek #1 |
| | `dlg.s2.done.1` | Kakekmu memang begitu, sukanya nulis surat. |
| S3 | `dlg.s3.start.1` | Eh, tetangga baru! Malas ke alun-alun? Jual ke abang aja. *(versi tanpa perkenalan, ✔ K-20)* |
| | `dlg.s3.start.2` | Harganya beda dikit dari Pak Udin, tapi abang beli apa saja. |
| | `quest.s3.s1` | Jual 1 barang ke Bang Jali |
| | `dlg.s3.done.1` | Makasih! Mampir lagi, ya. |
| S4 | `dlg.s4.start.1` | Dulu saya yang bantu kakekmu bangun rumahnya. *(versi tanpa perkenalan, ✔ K-20)* |
| | `dlg.s4.start.2` | **[FINAL, ganti dari "Rangkanya masih kokoh…"]** Rangka rumahnya saya simpan baik-baik. Hari ini saya pasang lagi di lahanmu. |
| | `quest.s4.s1` | Ngobrol dengan Pak Amran |
| | `dlg.s4.done.1` | Hutan di belakang kampung banyak bahannya. Nanti saya ajak ke sana. |
| S5 | `dlg.s5.start.1` | Ikan sungai lahan sudah hafal? Di kanal alun-alun ikannya lebih besar. Coba deh. |
| | `quest.s5.s1` | Tangkap 1 ikan Mid di Kanal Barat |
| | `dlg.s5.done.1` | Mantap, sudah naik kelas! |
| S6 | `dlg.s6.start.1` | Di kampung kita biasa saling bantu, Cu. Lihat tanaman tetangga kehausan, siramkan ya. |
| | `dlg.s6.start.2` | **[FINAL, ✔ K-17]** Kalau kampung lagi sepi, Kebun Warga di alun-alun juga butuh disiram. |
| | `quest.s6.s1` | Bantu 1 lahan |
| | `dlg.s6.done.1` | Kampung jadi hangat kalau begini. |
| S7 | `dlg.s7.start.1` | Sudah coba padi? Lama tumbuhnya, tapi jeraminya berguna buat tukang. |
| | `quest.s7.s1` / `s2` | Tanam 1 Padi / Panen 1 Padi |
| | `dlg.s7.done.1` | Petani sejati! |
| S8 | `dlg.s8.start.1` | Sekarang ada bebek di warung. Telurnya lebih mahal dari telur ayam, lho. |
| | `quest.s8.s1` / `s2` | Bangun Kandang Bebek / Beli 1 Bebek |
| | `dlg.s8.done.1` | Kweek! Ramai juga lahanmu sekarang. |
| S9 | `dlg.s9.start.1` | **[FINAL, ganti dari "Sisi timur kanal itu Empang…", ✔ K-23]** Sisi timur kanal itu ikannya galak-galak, jorannya harus kuat. |
| | `quest.s9.s1` | Tangkap 1 ikan di Kanal Timur |
| | `dlg.s9.done.1` | Wah, kamu sudah jago! |

### 6.3 Side Lama — Naskah [FINAL, ✔ K-14]

| Quest | Kunci | Teks |
|-------|-------|------|
| Kucing Alun-alun (Pak Udin) | `dlg.side_kucing.start.1` | Ada kucing oren suka mampir ke warung Pak Udin. Kurus, kasihan. Bantu kasih makan, ya? |
| | `dlg.side_kucing.start.2` | Sehari sekali cukup. Ikan kecil juga dia doyan. |
| | `quest.side_kucing.s1` | Kasih makan kucing (0/3 hari) |
| | `dlg.side_kucing.done.1` | Lihat, dia sudah nempel sama kamu. Bawa pulang saja, {name}. |
| Joran Hilang (Kak Fajar) | `dlg.side_joran.start.1` | Kemarin air naik, tiga joran lamaku hanyut. Kalau lihat di pinggir air, ambilin ya. |
| | `quest.side_joran.s1` | Cari joran hilang di pinggir air (0/3) |
| | `dlg.side_joran.done.1` | Ketemu semua! Yang ini buat kamu, lebih enak dari joran bambu. |
| Rumah Rapi (Pak Amran) | `dlg.side_rumah_rapi.start.1` | Rumah itu dimulai dari satu papan, {name}. Pasang dua puluh bagian, biar mulai berbentuk. |
| | `quest.side_rumah_rapi.s1` | Pasang 20 piece Hias (0/20) |
| | `dlg.side_rumah_rapi.done.1` | Rapi. Kakekmu dulu juga suka warna dinding begini. |
| Ringan Tangan (Nek Ani) | `dlg.side_tetangga.start.1` | Cu, tiap kebun yang kamu bantu bikin kampung makin hangat. Sepuluh, ya. Nenek hitungkan. |
| | `quest.side_tetangga.s1` | Bantu 10 lahan (0/10) |
| | `dlg.side_tetangga.done.1` | Ringan tangan, persis kakekmu. |
| Resep Mak (Mak Sari) | `dlg.side_resep.start.1` | Nak, coba masak tiga resep berbeda. Lidah itu perlu dikenalkan banyak rasa. |
| | `quest.side_resep.s1` | Masak 3 resep berbeda (0/3) |
| | `dlg.side_resep.done.1` | Enak semua. Mak sampai lupa ini masakan siapa. |
| Panen Prima (Mak Sari) | `dlg.side_prima.start.1` | Siram dulu, panen pas matang. Lima panen Prima, nanti Mak kasih gembor kesayangan Kakek. |
| | `quest.side_prima.s1` | Panen 5 Kualitas Prima (0/5) |
| | `dlg.side_prima.done.1` | Ini gembor Kakek. Dicat emas waktu panen raya dulu. |
| Ikan Jumbo (Kak Fajar) | `dlg.side_jumbo.start.1` | Pernah dapat ikan yang badannya lebih panjang dari lenganmu? Itu baru Jumbo. Coba deh. |
| | `quest.side_jumbo.s1` | Dapat 1 ikan ukuran Jumbo |
| | `dlg.side_jumbo.done.1` | Besar banget! Mulai sekarang kupanggil kamu Raja Jumbo. |
| Kolektor Album (Nek Ani) | `dlg.side_kolektor.start.1` | Album Kampung itu ingatan kampung ini, Cu. Isi seperempatnya dulu, ya. |
| | `quest.side_kolektor.s1` | Isi Album Kampung 25% |
| | `dlg.side_kolektor.done.1` | Seperempat sudah. Nenek senang lihatnya. |
| Kerja Bakti 10x (Nek Ani) | `dlg.side_kerjabakti.start.1` | Habis hujan deras, alun-alun pasti kotor. Ikut pungut sampahnya ya, Cu. Sepuluh kali. |
| | `quest.side_kerjabakti.s1` | Ikut 10 Kerja Bakti (0/10) |
| | `dlg.side_kerjabakti.done.1` | Sepuluh kali! Nenek kasih gelar Pekerja Bakti buatmu. |
| Warung Laris (Mak Sari) | `dlg.side_warung.start.1` | Warungmu sudah jalan, Nak? Jual sepuluh olahan, biar orang kampung kenal masakanmu. |
| | `quest.side_warung.s1` | Jual 10 olahan di Warung (0/10) |
| | `dlg.side_warung.done.1` | Laris manis! Mak ikut bangga. |

Petunjuk Quest Log Kerja Bakti (✔ K-37): `Setelah hujan deres atau petir: pungut sampah di alun-alun. +15 Koin +3 XP per poin.`

### 6.4 Baris yang Dihapus (jangan dipakai lagi)

- "Ikannya bagus! Jual ke aku di sini, ikuti panah ya." (`STEP_LINES.jual_ikan` T1Ghost)
- "Kamu juga bisa mancing di sungai sebelah lahanmu, biar tidak perlu jauh jalan ke alun-alun." (`tut.t1b.jual_done`)
- "Selamat, kamu berhasil dapat ikan! Ikan ini bisa kamu jual ke Pak Udin di warung." (`npc.kak_fajar.after_catch` — salah, ikan dijual ke Kak Fajar)
- Perkenalan di m1/s3/s4 versi lama ("Nenek Ani, yang jaga pos ronda ini", "Bang Jali, warung kecil depan lahanmu", "Saya Amran, tukang kayu").

---

## 7. Setelah Lv 10

Sudah pasti (dari GDD): MQ11 Legenda Pertama (Lv 15), MQ12 Warga Kampoeng Tedoeh (Album 50%).

Fitur Lv 10+ yang perlu quest pengenal (Main = gameplay baru, Side = lanjutan):

| Lv | Fitur | Jenis usulan |
|----|-------|--------------|
| 12 | Stroberi, Baung | Side |
| 15 | Dapur Kampung (Tier 2), Kolam Semen, Pohon Aren (Ijuk), Bingkai Album, Bundel Lumbung | Side (Lumbung = Main cerita) |
| 18 | Kanal Timur malam (Tapah) | Side |
| 20 | Kirim Hadiah; Bundel Saung Kakek | Main; Main cerita |
| 22 | Sapi | Side |
| 25 | Akuarium, Kaca, Kopi & Teh | Main (Akuarium); Side |
| 30 | Kolam Keramik; Bundel Empang & Dermaga Kakek | Side; Main cerita |
| 35 | Dapur Lengkap (Tier 3), Mangga | Side |
| 45 | Durian | Side |
| 50 | Set Joglo | Main cerita |

Struktur cerita "Babak 2 & 3" dan rancangan quest-nya: `08_Penyempurnaan.md` P-03. Ditulis lengkap di Roadmap R8.1–R8.2 (P-03 dianggap diterima; masukan owner datang dari playtest).

---

## 8. Revisi Playtest Putaran 1 (v8.3, K-54 / K-56)

- **Bantu lahan** dihapus dari pool Harian dan Mingguan. Quest Season baru: "Bantu 20 lahan (Season)", 500 Koin, tanpa Bunga, muncul setelah Bantu terbuka.
- **Quest diblok** bila sistemnya belum ada: M1 "Kampung Hari Ini" tetap tersembunyi sampai Agenda UI (R2.2) berjalan.
- **Baris langkah pemain** = kolom Langkah di bab ini, dipakai di tracker dan log (contoh: "Buka Agenda (1/3)", "Tanam 6 bibit Kangkung (3/6)"). Side quest juga menampilkan apa yang harus dilakukan dan di mana.
- **Tutorial:** naskah Mak Sari dan Kak Fajar mengikuti K-54 (Bab 4 di atas).
