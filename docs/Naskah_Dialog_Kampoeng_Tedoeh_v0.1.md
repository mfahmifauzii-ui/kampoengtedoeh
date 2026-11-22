# KAMPOENG TEDOEH — Naskah Dialog v0.1 (DRAFT)

> Naskah untuk Tutorial (T1 + T1b), Main Quest, dan Side Quest yang melibatkan NPC. Urutan quest mengikuti `docs/Quest_Kampoeng_Tedoeh_v0.3.md`.
> Status: Tutorial = **siap dipasang**. Main / Side Quest = draft, dipasang bersamaan dengan rantai quest v0.3.
> Semua teks masuk `Locale/id.luau`. Tidak ada teks dialog yang ditulis langsung di file kode.

---

## 0. Aturan Naskah

1. **Satu baris = satu kotak dialog.** Maksimal ±110 karakter (3 baris di kotak tanpa pilihan). Lebih panjang = pecah jadi 2 baris dengan Next.
2. **Satu ucapan selesai dulu, baru ucapan berikutnya** (antrean T1Dialog). Tidak ada dua baris yang saling timpa.
3. **"Ikuti panah" hanya dipakai kalau targetnya jauh.** NPC yang sudah berdiri di depan pemain tidak pernah bilang "ikuti panah".
4. **Setiap NPC menyebut lokasi yang benar.** Kak Fajar tutorial ada di sungai dekat lahan; Kak Fajar biasa ada di lapak pinggir kanal alun-alun.
5. **Kunci locale:**
   - Tutorial: `tut.<tutorial>.<step>.<n>` (contoh `tut.t1b.jual_ikan.1`).
   - Quest: `dlg.<questId>.start.<n>`, `dlg.<questId>.done.<n>`, langkah tracker `quest.<questId>.s<n>`.
   - `{name}` = nama pemain.
6. **Main Quest:** dialog Mulai (2–3 baris, Next) → banner `Dimulai` → langkah di tracker → banner `Selesai` → 1 baris penutup dari pemberi di kotak dialog (pakai foto NPC; NPC tidak perlu ada di dekat pemain).
7. **Side Quest:** tidak ada banner. Baris pembuka diucapkan saat pemain ngobrol dengan pemberi (tanda `!`) atau saat lewat di dekatnya. Selesai = toast kecil berisi 1 baris pendek dari pemberi.

### Suara tiap NPC

| NPC | Gaya bicara |
|-----|-------------|
| Mak Sari | Hangat, keibuan. Memanggil pemain "Nak", menyebut diri "Mak". |
| Pak Udin | Pedagang ramah, sedikit bangga dengan warungnya. Menyebut diri "Pak Udin". |
| Kak Fajar | Muda, santai. "Aku / kamu". |
| Pak Amran | Tukang kayu, tenang, praktis. "Saya / kamu". Sering menyebut Kakek. |
| Nek Ani | Sesepuh, penjaga pos ronda. Menyebut diri "Nenek", memanggil pemain "Cu". |
| Bang Jali | Santai, akrab. Menyebut diri "abang". |

---

## 1. Tutorial (T1 + T1b)

### 1.1 Intro — Mak Sari (cutscene setelah Play, Next tiap baris)

> Tidak ada toast / hint bar sebelum atau selama cutscene ini.

| Kunci | Teks |
|-------|------|
| `tut.t1.intro.1` | Nak... akhirnya kamu pulang juga. Mak kangen! |
| `tut.t1.intro.2` | Ini lahan peninggalan Kakek Daeng. Sudah lama nggak ada yang ngurus. |
| `tut.t1.intro.3` | Dulu kakekmu rajin sekali di sini. Sekarang giliranmu, ya? |
| `tut.t1.intro.4` | Tenang, Mak temenin. Kita mulai pelan-pelan aja. |

### 1.2 Langkah T1 — Mak Sari (di pinggir lahan)

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

### 1.3 Jual Pertama — Pak Udin (cutscene proximity)

| Urutan | Kunci | Teks | Tombol |
|--------|-------|------|--------|
| 1 | `tut.t1.jual.1` | Halo, {name}! Kamu cucunya Kakek Daeng, ya? Wah, sudah besar sekarang. | Next |
| 2 | `tut.t1.jual.2` | Itu Kangkung dari lahanmu? Sini, Pak Udin beli. | **Jual semua** |
| 3 | `tut.t1.jual.3` | Bagus panenmu! Kalau ada lagi, bawa ke sini. Bibit juga Pak Udin jual. | Next |
| 4 | `tut.t1.jual.4` | Oh iya, Kak Fajar lagi mancing di sungai dekat lahanmu. Samperin, katanya ada titipan buat kamu. | Next |

> Baris 4 satu-satunya tempat Pak Udin menyebut Kak Fajar. Sapaan (baris 1) tidak lagi menyebut Kak Fajar.

Baris langkah `kak_fajar` (sesudah cutscene, pemain jalan ke sungai):

| Kunci | Pembicara | Teks |
|-------|-----------|------|
| `tut.t1b.kak_fajar.1` | Pak Udin | Kak Fajar ada di sungai dekat lahanmu. Ikuti panah di tanah, ya. |

### 1.4 Hadiah Joran — Kak Fajar (di sungai, proximity)

| Urutan | Kunci | Teks | Tombol |
|--------|-------|------|--------|
| 1 | `tut.t1b.hadiah.1` | Halo, {name}! Aku Fajar. Kata Pak Udin kamu baru pulang, ya? | Next |
| 2 | `tut.t1b.hadiah.2` | Nih, joran bambu sama umpan buat kamu. Anggap aja hadiah selamat datang. | **Terima Hadiah** |

→ fade, lalu langkah mancing.

| Langkah | Kunci | Teks |
|---------|-------|------|
| mancing | `tut.t1b.mancing.1` | Coba lempar ke riak air itu. Ketuk tombol Mancing yang menyala. |

### 1.5 Ikan Pertama + Jual — Kak Fajar (satu rangkaian, tanpa jeda, tanpa baris lain yang menyela)

| Urutan | Kunci | Teks | Tombol |
|--------|-------|------|--------|
| 1 | `tut.t1b.jual_ikan.1` | Wah, dapat! Lumayan buat percobaan pertama. | Next |
| 2 | `tut.t1b.jual_ikan.2` | Mau dijual? Aku beli ikan di sini. | **Jual semua** |
| 3 | `tut.t1b.jual_ikan.3` | Sungai ini dekat lahanmu, jadi bisa mancing sambil nunggu panen. | Next |
| 4 | `tut.t1b.jual_ikan.4` | Aku balik ke lapak dulu. Butuh umpan atau mau jual ikan, cari aku di pinggir kanal alun-alun. | **Ok, Kak Fajar** |

→ fade → banner `Selesai` (tutorial). Tidak ada baris lain setelah ini.

**Dihapus:**
- "Ikannya bagus! Jual ke aku di sini, ikuti panah ya." (`STEP_LINES.jual_ikan` di T1Ghost)
- "Kamu juga bisa mancing di sungai sebelah lahanmu, biar tidak perlu jauh jalan ke alun-alun." (`tut.t1b.jual_done`)
- "Selamat, kamu berhasil dapat ikan! Ikan ini bisa kamu jual ke Pak Udin di warung." (`npc.kak_fajar.after_catch`, salah: ikan dijual ke Kak Fajar)
- Tabel `WARUNG` dan teks hardcoded lain di `T1Ghost.client.luau`, dipindah ke locale di atas.

---

## 2. Main Quest

### M1 Kampung Hari Ini — Nek Ani (Lv 2)

| Kunci | Teks |
|-------|------|
| `dlg.m1.start.1` | Kamu cucunya Daeng, kan? Nenek Ani, yang jaga pos ronda ini. |
| `dlg.m1.start.2` | Tiap hari di kampung ada saja yang bisa dikerjakan, Cu. Nenek tulis di Agenda. |
| `dlg.m1.start.3` | Oh, kalau ada gerobak lewat di alun-alun, mampir. Barangnya suka aneh-aneh. |
| `quest.m1.s1` | Buka Agenda |
| `quest.m1.s2` | Selesaikan 1 tugas Agenda |
| `quest.m1.s3` | Lihat Gerobak Kaget di alun-alun |
| `dlg.m1.done.1` | Rajin juga kamu, Cu. Mirip kakekmu. |

### M2 Ke Hutan — Pak Amran (Lv 4)

| Kunci | Teks |
|-------|------|
| `dlg.m2.start.1` | Sudah waktunya, {name}. Ayo ke Hutan. Kayu, batu, bambu, semua ada di sana. |
| `dlg.m2.start.2` | Pukul pas lingkarannya ketemu tanda. Hasilnya lebih banyak. |
| `dlg.m2.start.3` | Bawa pulang batu dan kayu, lalu ubah sebagian kayunya jadi papan di Meja Crafting. |
| `quest.m2.s1` | Pergi ke Hutan Nambang |
| `quest.m2.s2` | Kumpulkan 10 Batu dan 9 Kayu |
| `quest.m2.s3` | Craft 2 Papan di Meja Crafting |
| `dlg.m2.done.1` | Tangan kamu cocok jadi tukang. Sisa batu dan kayunya simpan, Kak Fajar lagi butuh. |

> 9 Kayu = 4 untuk 2 Papan + 5 untuk setoran M3. Quest doc v0.3 ikut diubah.

### M3 Kolam Kakek — Kak Fajar (Lv 4)

| Kunci | Teks |
|-------|------|
| `dlg.m3.start.1` | {name}! Kakekmu dulu punya kolam ikan di lahan itu. Mau kita bangun lagi? |
| `dlg.m3.start.2` | Bawa batu sama kayunya, plus 3 ikan dari sungai buat bibitnya. |
| `dlg.m3.start.3` | Tombol Kolam sudah ada di menu Garap. Bangun di mana saja di lahanmu. |
| `quest.m3.s1` | Bangun Kolam Kakek (10 Batu, 5 Kayu, 3 ikan Early) |
| `quest.m3.s2` | Tangkap 1 ikan di kolammu |
| `dlg.m3.done.1` | Kolam Kakek hidup lagi. Ikannya bakal beranak sendiri, rajin-rajin dicek ya. |

### M4 Pagar Pertama — Pak Amran (Lv 5)

| Kunci | Teks |
|-------|------|
| `dlg.m4.start.1` | Lahanmu masih polos. Pasang pagar bambu dulu, biar kelihatan ada yang punya. |
| `dlg.m4.start.2` | Buka menu Hias, pilih Pagar Bambu, taruh di mana kamu suka. |
| `quest.m4.s1` | Pasang 1 Pagar Bambu |
| `dlg.m4.done.1` | Nah, mulai kelihatan seperti rumah. |

### M5 Kokok Pertama — Pak Udin (Lv 5)

| Kunci | Teks |
|-------|------|
| `dlg.m5.start.1` | {name}, ayam Pak Udin lebih satu. Ambil saja, buat kamu. |
| `dlg.m5.start.2` | Kandangnya sudah Pak Udin pasang di lahanmu. Isi pakannya, nanti dia bertelur. |
| `quest.m5.s1` | Isi pakan ayam |
| `quest.m5.s2` | Ambil 1 telur |
| `dlg.m5.done.1` | Telur pertama! Jual ke Pak Udin atau simpan buat masak nanti. |

### M6 Dapur Pertama — Mak Sari (Lv 6)

| Kunci | Teks |
|-------|------|
| `dlg.m6.start.1` | Nak, hasil kebunmu enak kalau dimasak. Ayo bikin tungku. |
| `dlg.m6.start.2` | Kalau dimakan sendiri, badan jadi semangat. Kerja di kebun atau mancing jadi lebih lancar. |
| `quest.m6.s1` | Craft Tungku |
| `quest.m6.s2` | Masak 1 olahan |
| `quest.m6.s3` | Makan 1 olahan |
| `dlg.m6.done.1` | Masakanmu enak, Nak. Persis resep Mak. |

### M7 Warung Pertama — Mak Sari (Lv 7)

| Kunci | Teks |
|-------|------|
| `dlg.m7.start.1` | Sayang kalau masakanmu dimakan sendiri terus. Buka warung kecil di lahanmu, Nak. |
| `dlg.m7.start.2` | Taruh satu olahan di etalase. Nanti ada orang lewat yang beli. |
| `quest.m7.s1` | Pasang Warung |
| `quest.m7.s2` | Jual 1 olahan di Warung |
| `dlg.m7.done.1` | Laku! Mak bangga sama kamu. |

### M8 Jebakan Kak Fajar — Kak Fajar (Lv 8)

| Kunci | Teks |
|-------|------|
| `dlg.m8.start.1` | Mau dapat ikan tanpa nunggu di sungai? Pakai bubu. |
| `dlg.m8.start.2` | Pasang di air, tinggal pergi, nanti ambil isinya. Aku kasih satu buat kamu. |
| `quest.m8.s1` | Pasang 1 Bubu |
| `dlg.m8.done.1` | Sip. Bubu butuh 6 jam, jadi tinggal aja. Nanti balik ambil ikannya. |

> M8 selesai saat bubu terpasang, supaya Main Quest berikutnya tidak tertahan 6 jam. Quest doc v0.3 ikut diubah.

### M9 Sumur Tua — Nek Ani (Lv 8)

| Kunci | Teks |
|-------|------|
| `dlg.m9.start.1` | Kamu tahu sumur tua di lahanmu, Cu? Dulu satu kampung ambil air di situ. |
| `dlg.m9.start.2` | Kerangkanya masih ada. Pulihkan, ya. Kakekmu pasti senang. |
| `quest.m9.s1` | Pulihkan Sumur Tua (10 Kayu, 5 Batu, 2 olahan) |
| `dlg.m9.done.1` | Airnya jernih lagi. Mulai sekarang sumur ini menyiram satu petakmu tiap hari. |

### MQ11 Legenda Pertama — Kak Fajar (Lv 15, milestone cerita)

| Kunci | Teks |
|-------|------|
| `dlg.mq11.start.1` | Kakekmu dulu pernah cerita soal ikan yang cuma muncul sesekali. Orang sini bilang ikan legenda. |
| `dlg.mq11.start.2` | Atau kalau kamu lebih suka kebun, panen Prima dari tanaman yang lama tumbuhnya juga sama hebatnya. |
| `quest.mq11.s1` | Dapat 1 Ikan Legenda **atau** panen 1 Prima tanaman Late |
| `dlg.mq11.done.1` | Seluruh kampung sudah dengar. Kakekmu pasti bangga. |

### MQ12 Warga Kampoeng Tedoeh — Mak Sari (milestone cerita)

| Kunci | Teks |
|-------|------|
| `dlg.mq12.start.1` | Nak, Mak lihat lahan Kakek sekarang ramai lagi. Kebun, kolam, warung... |
| `dlg.mq12.start.2` | Isi Album Kampung sampai setengah, ya. Biar semua orang tahu kamu sudah jadi warga sini. |
| `quest.mq12.s1` | Selesaikan Album Kampung 50% |
| `dlg.mq12.done.1` | Selamat datang di rumah, {name}. Kamu warga Kampoeng Tedoeh sekarang. |

---

## 3. Side Quest

Pembuka diucapkan saat pemain ngobrol dengan pemberi. Selesai = toast `Nama NPC: teks`.

| # | Pemberi | Kunci | Teks |
|---|---------|-------|------|
| S1 Bibit Kedua | Pak Udin | `dlg.s1.start.1` | Bibitnya habis? Coba Bayam, {name}. Agak lama dari Kangkung, tapi harganya lebih bagus. |
| | | `quest.s1.s1` / `s2` | Beli 2 Bibit Bayam / Tanam 2 Bayam |
| | | `dlg.s1.done.1` | Nah, ladangmu mulai ramai! |
| S2 Surat Pertama | Mak Sari | `dlg.s2.start.1` | Nak, Mak nemu surat di rumah Kakek. Kayaknya buat kamu. |
| | | `quest.s2.s1` | Baca Surat Kakek #1 |
| | | `dlg.s2.done.1` | Kakekmu memang begitu, sukanya nulis surat. |
| S3 Tetangga di Depan | Bang Jali | `dlg.s3.start.1` | Eh, tetangga baru! Bang Jali, warung kecil depan lahanmu. Malas ke alun-alun? Jual ke abang aja. |
| | | `dlg.s3.start.2` | Harganya beda dikit dari Pak Udin, tapi abang beli apa saja. |
| | | `quest.s3.s1` | Jual 1 barang ke Bang Jali |
| | | `dlg.s3.done.1` | Makasih! Mampir lagi, ya. |
| S4 Rumah dari Kakek | Pak Amran | `dlg.s4.start.1` | Saya Amran, tukang kayu. Dulu saya yang bantu kakekmu bangun rumahnya. |
| | | `dlg.s4.start.2` | Rangkanya masih kokoh. Nanti kalau sudah ada bahan, kita rapikan sama-sama. |
| | | `quest.s4.s1` | Ngobrol dengan Pak Amran |
| | | `dlg.s4.done.1` | Hutan di belakang kampung banyak bahannya. Nanti saya ajak ke sana. |
| S5 Ikan Kanal | Kak Fajar | `dlg.s5.start.1` | Ikan sungai lahan sudah hafal? Di kanal alun-alun ikannya lebih besar. Coba deh. |
| | | `quest.s5.s1` | Tangkap 1 ikan Mid di dermaga Kanal |
| | | `dlg.s5.done.1` | Mantap, sudah naik kelas! |
| S6 Tetangga Baik | Nek Ani | `dlg.s6.start.1` | Di kampung kita biasa saling bantu, Cu. Lihat tanaman tetangga kehausan, siramkan ya. |
| | | `quest.s6.s1` | Bantu 1 lahan pemain lain |
| | | `dlg.s6.done.1` | Kampung jadi hangat kalau begini. |
| S7 Sawah | Pak Udin | `dlg.s7.start.1` | Sudah coba padi? Lama tumbuhnya, tapi jeraminya berguna buat tukang. |
| | | `quest.s7.s1` / `s2` | Tanam 1 Padi / Panen 1 Padi |
| | | `dlg.s7.done.1` | Petani sejati! |
| S8 Kandang Bebek | Pak Udin | `dlg.s8.start.1` | Sekarang ada bebek di warung. Telurnya lebih mahal dari telur ayam, lho. |
| | | `quest.s8.s1` / `s2` | Bangun Kandang Bebek / Beli 1 Bebek |
| | | `dlg.s8.done.1` | Kweek! Ramai juga lahanmu sekarang. |
| S9 Empang | Kak Fajar | `dlg.s9.start.1` | Sisi timur kanal itu Empang. Ikannya galak-galak, jorannya harus kuat. |
| | | `quest.s9.s1` | Tangkap 1 ikan di Empang |
| | | `dlg.s9.done.1` | Wah, kamu sudah jago! |

Side Quest Bab 14.4 gameplay (Kucing Alun-alun, Joran Hilang, Rumah Rapi, dll.) disusun di v0.2.
