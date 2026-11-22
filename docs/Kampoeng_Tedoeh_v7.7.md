# KAMPOENG TEDOEH — Dokumen Gameplay v7.7
## Single Source of Truth (revisi konsistensi)

> v7.7 = v7.6 + Changelog 0.3.4 (Q-1 sampai Q-5: rantai quest v0.3 Bab 6, feature gate, alur quest, Quest Log, layer). v7.6 tetap disimpan sebagai arsip (docs/Kampoeng_Tedoeh_v7.6.md), v7.5 sebagai arsip (docs/Kampoeng_Tedoeh_v7.5.md). Lampiran D = daftar keputusan yang masih terbuka.

> Dokumen ini menggantikan SEMUA versi sebelumnya (v1.0 sampai v7.2), termasuk `00_Design_Doc.md` (v0.3) dan `Audit_v6.1.md`. `Roadmap.md`, `TODO.md`, dan dokumen teknis hanya catatan status dan tidak boleh mengubah angka di sini. Daftar status dokumen dan konflik yang sudah diselesaikan ada di Lampiran A dan B.
> Aturan revisi: setiap aturan hanya ditulis di SATU bab. Bab lain cukup merujuk (`lihat Bab X`). Tidak ada lagi aturan yang ditulis ulang di 3 tempat dengan angka beda.
> Revisi berikutnya wajib nomor baru (v7.8) + isi Changelog di Bab 0.3.
> v7.5 = v7.4 + catatan perubahan kode yang sudah dikerjakan (Bab 0.3.2) dan daftar deviasi kode vs dokumen yang belum diputuskan (Lampiran D). Angka desain di bab 1-30 TIDAK diubah di v7.5; deviasi tetap berlaku di kode sampai owner memutuskan.
> Format dokumen ini mengikuti v6.2.3. Format file829 (Blueprint map, Build order Fase, Authority / Scripts / Remotes) TIDAK dipakai.

---

## 0. Ringkasan

### 0.1 Ringkasan 1 Paragraf

Kampoeng Tedoeh adalah game Roblox cozy farming + fishing + ranching + cooking + building berlatar kampung Indonesia, untuk 16+, netral gender. Player adalah cucu Kakek Daeng yang pulang mengurus lahan warisan dan menemukan surat-surat yang ditinggalkan kakeknya. Tidak ada fail, tidak ada stamina, tidak ada hukuman. Tanaman, hewan, dan bangunan tidak pernah mati atau rusak. Sesi ideal 20-40 menit. Yang bikin player cerita ke temannya: **panen Prima saat hujan, Ikan Legenda yang diumumkan ke satu server, Gerobak Kaget yang restock tiap 15 menit, dan Olahan yang dimakan sendiri jadi buff untuk kegiatan aktif.** Yang bikin player balik besok: **bubu, kolam, Surat Kakek harian, Order Villager harian, Bundel Kakek (memulihkan bangunan peninggalan Kakek), dan Kerja Bakti Kilat setiap habis hujan deres / petir.** Tidak ada satu pun sistem yang butuh banyak player supaya bisa selesai.

Tagline tim: `Kampung lo, rumah lo, panen lo — tiap hujan bisa jadi panen Prima.`

### 0.2 Target Desain (Angka yang Dikunci)

| Target | Angka | Bab Rujukan |
|--------|-------|-------------|
| Sesi ideal | 20-40 menit | Bab 2 |
| Player inti (2 jam/hari) capai Level Cap rilis (Lv 60) | ~32 hari | Bab 4, 17 |
| Player santai (45 menit/hari) di hari ke-30 | ~Lv 26 | Bab 4 |
| Konten rilis selesai saat Lv 60 | ~71-72% | Bab 17 |
| Level Cap naik | +20 tiap Update Besar (Lv 80 bulan ke-2, Lv 100 bulan ke-4) | Bab 26 |
| Retensi D1 / D7 / D30 | 35% / 15% / 6% | Bab 25 |
| Konversi bayar | 3% | Bab 18 |

> Bagian 0.3 sampai 0.3.7 adalah sejarah keputusan. Aturan aktif ada di bab masing-masing dan di Lampiran B.

### 0.3 Changelog v7.2 → v7.3 (Keputusan Owner — LOCKED)

| # | Perubahan | Alasan / Angka |
|---|-----------|--------|
| 1 | **Order Villager TAMBAH (Bab 14.7)** | Bukan karangan. Sistem yang kelewat di v7.2, masih perlu. Daily 3 + Weekly 1, reward nilai jual x1,5 (daily) / x3 (weekly), reroll 2 Bunga. Beda dari Agenda (Agenda = tugas sistem, Order = permintaan NPC spesifik setor barang). |
| 2 | **Buff Olahan TAMBAH (Bab 9.4)** | Olahan bisa dijual ATAU dimakan sendiri. Dimakan = buff 10 / 12 / 15 menit (Biasa / Bagus / Prima) untuk kegiatan AKTIF saja: Nanem, Mancing, Nambang, Nebang Pohon. Tidak ada buff pasif (Ternak, Kolam, Dapur, Bubu, Warung). |
| 3 | **Bibit Unggul DIHAPUS total** | Angka +10% tumbuh, x1,5 harga adalah karangan di kode. Pasif, nabrak Skill Tangan Hijau + Buff Tani, ekonomi jelek (hemat 3 menit untuk tanaman 30 menit tapi harga x1,5). Pak Udin hanya jual Bibit biasa. |
| 4 | **Backpack Pass DIHAPUS total** | Karangan di kode (+40 slot). Tas di v7.2 / v7.3 tanpa cap slot (stack 99). Pass menyelesaikan masalah yang tidak ada, dan jadi pay-to-not-annoying, tidak cozy. |
| 5 | **Blueprint gating DIHAPUS total** | Blueprint BUKAN gating. Dekor bisa langsung di-craft pakai bahan tanpa beli Blueprint. Blueprint hanya simpan desain (3 slot gratis) + bagikan kode. Lihat Bab 8.7. |
| 6 | **Yang tidak dibahas = LOCKED** | Semua angka yang tidak dibahas di revisi ini tetap sama seperti v7.2, tidak diubah. |

### 0.3.4 Changelog v7.6 → v7.7 (Q-1 sampai Q-5, Quest v0.3 Bab 6)

Angka yang berubah di bawah ini sudah disetujui owner di Quest v0.3 Bab 6 (lihat Roadmap §10 "Keputusan owner 2026-11-22: rantai quest v0.3 disetujui apa adanya"). Tidak ada angka baru yang ditambahkan. Yang belum disepakati ada di Lampiran D.

| # | Perubahan | Bab Terkait | Status |
|---|-----------|-------------|--------|
| 1 | **Q-1 Data quest.** M1 sampai M9, MQ11, MQ12, S1 sampai S9, dan Side Bab 14.4 di `Config/Quests`. MQ5 dan MQ8 digabung jadi M8. Kolam Kakek jadi M3 (Lv 4). Event Report ditambah. (`0c087b9`, `456b3e6`) | 14.1, 14.2, 14.4 | Kode jadi |
| 2 | **Level buka fitur (Bab 6).** Bang Jali Lv 2 → **Lv 3**. Warung Lv 6 → **Lv 7**. Bubu Lv 6 → **Lv 8**. Sumur Tua Lv 6 → **Lv 8**. Hias Lv 5 (tidak berubah). Kolam Kakek Lv 3 → **Lv 4** (M3). Kolam Tanah tambahan dibeli setelah M3. `Fishing.POND.UNLOCK_LEVEL` 2 → 4 (keputusan owner, Lampiran D #30). | 4.4, 7.2, 9.3, 6.6, 14.6 | Kode jadi (Q-2) |
| 3 | **Feature gate (Q-2).** `PlayerData.features` (introduced / open). Tombol HUD, prompt, dan remote fitur tertutup tidak ada di klien dan ditolak server dengan toast "Belum terbuka". Kunci fitur: Dapur, Hias, Bantu, Kolam, Craft, Hutan, Kandang, Warung, Gerobak, Bang Jali, Kanal barat, Empang, Surat, Sumur Tua, Agenda, Bubu. Server-only: Agenda, Sumur Tua (bundel), Bubu (tidak ada tombol). KBPungut digerbang Gerobak (Q-2d, `918d07d`). Surat digerbang server (Q-2d). (`494f65f`, `28b056a`, `b0f8241`, `918d07d`) | 5, 9.3, 14.5, 14.6 | Kode jadi |
| 4 | **Koreksi gerbang Bang Jali (Q-3).** Prompt bicara Bang Jali tidak lagi digerbang. Quest S3 mulai dari bicara dengan Bang Jali; gerbang `jual_bang_jali` terbuka setelah S3 mulai. Jual tetap digerbang di server (`ShopService`). (`0e9d488`) | 10.1, 14.4 | Kode jadi (Lampiran D #31) |
| 5 | **Alur quest (Q-3).** Quest dengan dialog Naskah ditawarkan (tanda `!` di pemberi), bukan mulai otomatis. Dialog mulai dari Naskah, lalu quest mulai (`QuestAccept`). Main: banner Dimulai dan Selesai, dialog penutup dari pemberi. Side: dialog mulai, dan toast satu baris saat selesai. Tanda `!` tidak muncul selama Tutorial 1. Quest tanpa baris Naskah tetap mulai otomatis (Lampiran D #27). (`0e9d488`) | 14.1, 16.2 | Kode jadi, belum playtest |
| 6 | **Quest tracker dan Quest Log (Q-4).** Tracker: Main di atas, baris 32 px, Tunjukkan 24 px, maks 3 baris + "+N lainnya", tinggi maks min(200 px, 25% layar). Tap baris membuka Quest Log (tab Main / Side, bagian Aktif, Tersedia, Selesai, Berikutnya dengan `???`). Label baru "Tersedia" dan "Berikutnya" (Lampiran D #28). (`460c204`) | 14, 23 | Kode jadi, belum playtest |
| 7 | **Layer UI (Q-4 closure).** Semua `DisplayOrder` memakai `UiKit.LAYER`: HUD 20, aksi 10, panduan 30, panel 40, coachmark 50 dan 60, banner 80, modal 100, dialog 120, fade 150, menu awal 200+. Lapisan tambahan: dunia -2 dan -1, cutscene 110. (`460c204`, `8ed8b0a`, Lampiran D #29) | 23 | Kode jadi |
| 8 | **Dokumen Quest v0.3 Bab 6 diterapkan** ke Bab 4.4 (tabel buka), 6.6, 9.3, 14.2, 14.6 di dokumen ini. Quest Harian, Mingguan, dan Surat tidak diubah. | 4.4, 6.6, 9.3, 14.2, 14.6 | Dokumen (Q-5) |
| 9 | **Kolam Tanah Lv 4 (keputusan owner, Lampiran D #30).** Teks Bab 16.5 dan Lampiran D #13 diubah dari Lv 2 ke Lv 4. Kode tidak berubah (`Fishing.POND.UNLOCK_LEVEL` sudah 4). | 16.5, 4.4, Lampiran D #13 | Keputusan (Q-5 docs) |

### 0.3.3 Changelog v7.5 → v7.6 (Keputusan owner 2026-11-22, Task 1–7)

Revisi ini mengikuti aturan "angka baru wajib nomor baru". Setiap perubahan di bawah ada di kode (commit `feat/v.7`), kecuali yang ditandai BELUM.

| # | Perubahan | Bab Terkait | Status |
|---|-----------|-------------|--------|
| 1 | **FTUE berakhir di jual ikan ke Kak Fajar** (`jual_ikan`). Tidak ada langkah FTUE baru. Langkah lama (Bayam, Nambang, Hias, Surat #1, Agenda + Gerobak) jadi Starter Quest Chain. | 16.2, 14.8 | BELUM (chain dan Kak Fajar klien). Lampiran D #23 |
| 2 | **Sungai lahan** (32 spot, Early saja, Lv 1). **Kanal barat** (dermaga) Lv 5: Mid + Belut Emas. **Kanal timur** (dermaga) Lv 10 tetap. Late dipindah dari kanal barat ke kanal timur. | 3.1, 4.4, 6.4 | Kode jadi (Task 2). Lampiran D #24 |
| 3 | **Super dihapus.** Kualitas: **Bagus max 50%, Prima max 20%**, Biasa sisanya, setelah semua bonus. Buff Tani = +10% absolut ke Bagus. Panen pertama FTUE = Bagus. | 5.4, 9.4 | Kode jadi (Task 3) |
| 4 | **Nilai mini-game tarik** ditulis di Bab 6.2 (`FILL_GAIN 0.28`, `FILL_DRAIN 0.06`, `ZONE_SPEED 0.9`, `ZONE_SPEED_LEFT 0.55`). Coachmark tarik tetap dihapus. | 6.2, 16.2 | Dokumen (Task 4) |
| 5 | **Quest tracker**: tinggi maks min(200 px, 25% tinggi layar), maks 3 baris + "+N lainnya". | 14, 23 | Kode jadi, cek kartu XP di Studio (Task 5) |
| 6 | **Peti Bunga 25 Bunga** dari Title, Album milestone p25/50/75/100, Season F2P hari 30. Event belum (Lampiran D #21). **Login 10 Bunga/minggu** (Bab 18.2 = ~40/bulan, total ~240). **Season F2P** pakai hadiah tiap 5 hari (USULAN, #20). **Season Premium Segera hadir.** | 15.3, 15.4, 18.2, 19 | Kode jadi (Task 6), USULAN ditandai |
| 7 | **Galeri**: pemilik offline = lahan kosong, tanpa toast, tanpa snapshot. | 8.7, 12.7 | Kode jadi (v7.5) |
| 8 | **Kolam bisa dibangun di Lv 2** (`Fishing.POND.UNLOCK_LEVEL`). | 16.5, 14.1 | Kode jadi (v7.5) |
| 9 | **ID animasi permanen dimasukkan** (commit `1ce551c`): memancing di `Config/Fishing.ANIMS` (FishingIdle, FishingCast, FishingReel, FishingCatch) dan tanam/siram di `Config/Farm.ANIMS` (FarmPlant, FarmWater, baru). `FarmFx` dan `RodAnimController` memakai ID ini dulu dan kembali ke sequence `CustomAnims` hanya bila ID kosong. | 30.7, 6.1 | Kode jadi (`1ce551c`), **belum diuji di Studio** |

### 0.3.2 Changelog v7.4 → v7.5 (Perubahan Kode & GUI, 2026-11-22)

Isi di bawah adalah perubahan yang sudah ada di kode (`feat/v.7`) dan disetujui owner di sesi playtest. **Bukan** perubahan angka desain. Yang bertentangan dengan bab lain dicatat di Lampiran D dan menunggu keputusan owner.

| # | Perubahan | Bab Terkait | Status |
|---|-----------|-------------|--------|
| 1 | **Spot mancing sungai**: 8 spot di tiap sungai sumbu antara lahan pemain (4 per tepi, saling berhadapan), 4 sungai = 32 spot, Lv 2 (Basic Mancing). Tanpa platform/dermaga; penanda = riak ikan di air. | 4 (Perairan), 6.1 | Disetujui owner. Bertentangan dengan Bab 4 → Lampiran D #1 |
| 2 | **Prompt "Basic/Pro Mancing" di dermaga dihapus.** Dermaga sungai/empang hanya lewat tombol Mancing. Prompt kolam pemain tetap. | 6.1, 16.2 | Disetujui owner |
| 3 | **Tombol Mancing** jadi bulat dengan ikon joran, posisi kanan bawah (0,8 ; 0,67 layar). | 23 (HUD) | Disetujui owner |
| 4 | **Panel reel dikecilkan** (260×108), frame "Tahan Tarik! Jaga ikan…" dan teks "Tahan Tarik! agar ikan…" dihapus. Track memakai bingkai bambu Loading; zona hijau dan progress glossy. | 6.2 | Disetujui owner. Coachmark tarik dihapus → Lampiran D #3 |
| 5 | **Quest tracker tanpa panel**: lebar 200 px, teks krem dengan outline gelap, baris lebih kecil. Batas tinggi 200 px tetap. | 14, 23 | Disetujui owner. Batas tinggi tidak dihitung dari layar → Lampiran D #8 |
| 6 | **Font semua GUI = FredokaOne** (sebelumnya campuran Gotham / GothamBold / GothamMedium / GothamBlack). | 23 | Disetujui owner. Dokumen belum mengatur font → Lampiran D #9 |
| 7 | **Tombol Craft** hanya muncul setelah Meja Crafting terbuka (Lv 4) dan pemain dalam 10 stud dari meja; melayang di atas meja. | 8.2, 4.4 (Unlock Lv 4) | Disetujui owner. Butuh objek "Meja Crafting" di Studio → Lampiran D #7 |
| 8 | **Bang Jali (warung mini)** menghadap ke arah lain: membelakangi warung (diputar 180°). | 10.1 | Disetujui owner |
| 9 | **Bubble dialog NPC hilang setelah tutorial** (bug): kotak dialog tidak lagi ditutup oleh polling tutorial saat percakapan NPC aktif. | 16.3 | Perbaikan bug, tanpa perubahan desain |
| 10 | **XP top-up di langkah Jual Ikan (`t1b_kolam` / `jual_ikan`) +115 XP**: tutorial sekarang selesai di 158 XP (sebelumnya 43). Dengan 6 bibit gratis (kangkung 12 XP) yang habis dipanen, total 230 XP = Lv 2. | 16.2, 4.3 | Kode jadi, belum playtest. Angka 115 tidak ada di tabel 16.2 → Lampiran D #11 |
| 11 | **Quest tidak muncul sebelum tutorial jual ikan selesai.** `startAvailable` menunggu `guide.done.t1b_kolam` (atau skipped). Saat tutorial selesai, quest langsung dievaluasi (`TutorialService.Finished`). | 14, 16.3 | Kode jadi, belum playtest → Lampiran D #12 |
| 12 | **Quest Kolam (`kolam_pertama`) tidak lagi memakai syarat `requireKakek`.** Quest mulai di Lv 2. Langkah "bangun kolam" tetap terkunci sampai Kolam Kakek pulih (Lv 3), karena `PondBuild` masih memeriksa `kakekUnlocked`. | 14.2, 16.5 | Kode jadi → Lampiran D #13 **SUPERSEDED (Q-1):** `kolam_pertama` sudah dihapus dari `Config/Quests`. Langkah kolam sekarang M3 Kolam Kakek (Lv 4). Teks di atas dibiarkan sebagai riwayat; lihat Lampiran D #13. |
| 13 | **Petak garap berbayar**: Cangkul petak ke-7 dan seterusnya membuka modal konfirmasi berisi harga. Jika koin kurang, harga merah, tombol dikunci, dan modal menulis "Koin kamu belum cukup". Petak gratis (6 pertama) tetap langsung. | 5.2 | Kode jadi, belum playtest |
| 14 | **Hapus Petak mengembalikan 50% harga, hanya untuk petak yang dibeli** (`paid` disimpan per petak; petak gratis tidak ada refund). Modal Hapus Petak menampilkan jumlah koin yang kembali. Mengikuti aturan refund Kolam (`Fishing.POND.REFUND_RATE`). | 5.2 | Kode jadi → Lampiran D #14 |
| 15 | **Galeri: pemilik offline = lahan kosong.** Toast "pemilik offline" dan rumah snapshot dihapus (Lampiran D #19). | 8.7, 12.7 | Kode jadi |
| 16 | **Kolam bisa dibangun mulai Lv 2** (`Fishing.POND.UNLOCK_LEVEL`); Kolam Kakek tetap jalur lain. Kolam Quest bisa dibangun di Lv 2. | 16.5, 14.1 | Kode jadi → Lampiran D #13 |
| 17 | **P2-9 Hadiah mingguan (Config/Rewards, RewardsService, panel Hadiah):** Login Mingguan diulang tiap minggu; Peti Bunga 25 Bunga (dari Title baru); Title 10 item (Album 50/100 otomatis); Season 30 hari F2P + Premium 150 Bunga. | 15.1, 15.3, 15.4, 19 | Kode jadi, angka usulan → Lampiran D #15–#18 |

### 0.3.1 Changelog v6.2.3 → v7.2 (Riwayat, tetap LOCKED)

| # | Perubahan | Alasan / Angka |
|---|-----------|--------|
| 1 | Target umur 9-16 → **16+** | Roblox mewajibkan game baru untuk 16+. Desain cozy tetap, tapi tanpa desain anak (tanpa loot box anak, tanpa hadiah main lama untuk anak). |
| 2 | **Mutasi Panen DIHAPUS total** (Embun x1,5 / Petir x3 / Emas x5 / Pelangi x10) | Mutasi adalah gimmick judi / FOMO. Hanya ~15% player 16+ cozy yang tertarik. Diganti Kualitas Panen yang terkontrol. |
| 3 | **Kualitas Panen baru: Biasa / Bagus / Prima** | Nama ke arah kualitas, bukan rasa. Enak / Istimewa dihapus karena itu rasa, bukan kualitas. Biasa x1,0 / Bagus +10% / Prima +25%. Lihat Bab 5.4 untuk hitungan ekonomi. |
| 4 | **Kualitas Olahan baru: Biasa / Bagus / Prima** | Sama seperti Panen, +10% / +25%. Ditentukan dari Kualitas bahan tertinggi. Tidak double-count dengan Kualitas Panen. |
| 5 | **Pelangi sebagai SISTEM DIHAPUS total** | Pelangi adalah sisa Mutasi yang dibungkus ulang (bonus +15% Koin + naik tier Kualitas di v7.1). Dihapus. Tidak ada Pelangi di game. |
| 6 | **Greenhouse DIHAPUS total** | Greenhouse merugikan player saat hujan (tidak kena hujan = tidak dapat bonus hujan). Semua tanaman kena hujan sama rata. |
| 7 | **Rak Pajangan DIHAPUS total** | Tidak ada lagi pajang hasil Mutasi / Prima. Fungsi pamer pindah ke Album GUI + Like / Visit. |
| 8 | **Papan Pamer DIHAPUS total** | Karangan, tidak pernah disepakati. Sosial kembali ke Bantu, Hadiah, Gestur, Visit / Like / Galeri, Blueprint, Kerja Bakti. |
| 9 | **RW sebagai SISTEM DIHAPUS. RW hanya Cerita / NPC quest script** | Game belum terbukti ramai. RW tidak jadi sistem. RW hanya muncul sebagai cerita di Quest NPC. |
| 10 | **Pasar / Lapak antar-player DIHAPUS** | Gameplay sudah padat. Tawar-menawar tanpa efek ke player adalah mati. Player bisa buat sendiri, kenapa beli dari player lain? Diganti Warung Player (jual ke NPC pengunjung, bukan ke player). |
| 11 | **Cuaca: Tanpa Ramalan** | Hanya tanda 10 detik sebelum hujan. Tidak ada forecast, tidak ada FOMO. |
| 12 | **Cuaca: Hujan 3 menit** — siram otomatis 1x (potong sisa 15%) + selama hujan tumbuh 2x lebih cepat (hanya tanaman luar) + gigitan mancing 2x lebih lama + Mood Hujan 5 menit +10% Koin | Hujan bantu sedikit, tidak mengontrol gameplay. Contoh LOCKED: tanaman 30 menit, siram hemat 4,5 menit, sisa 25,5 menit, hujan 3 menit motong 6 menit, sisa setelah hujan 19,5 menit, total 22,5 menit. |
| 13 | **Terik netral** | Terik +10% bahan Nambang di v6 DIHAPUS. Terik tidak memberi bonus apa pun. |
| 14 | **Kasih minum ternak TIDAK PERNAH DITAMBAH** | Chore tambahan. Diganti Mood Hujan pasif. |
| 15 | **Mood Hujan: 5 menit setelah hujan, +10% Koin** | Bukan 1 siklus penuh. 1 siklus (15-30 menit) > interval hujan (14,5 menit) = buff jadi permanen ~100%. Dengan 5 menit, coverage 34,5%, expected +3,45% ke Ternak. Lihat Bab 7.1 dan Lampiran C. |
| 16 | **Dapur 9 → 24 resep** | Semua resep bahannya bisa dilacak ke list Tanaman (18) / Ikan (20) / Ternak (3 produk). Ikan pakai kategori Early / Mid / Late agar semua 17 ikan non-Legenda bisa dipakai. Legenda tidak bisa dimasak. Lihat Bab 9. |
| 17 | **Warung Player baru** | Jual olahan ke NPC pengunjung, bukan ke player. Tanpa Reputasi Warung (angka Reputasi adalah karangan, tidak pernah dibahas, dihapus). Harga = base x Kualitas Olahan. |
| 18 | **Album dibangun ulang tanpa Mutasi: 214 entri, GUI** | Ladang 54 (18 x 3 Kualitas) + Ikan 80 (20 x 4 ukuran) + Dapur 72 (24 x 3 Kualitas) + Varian 8 (6 Bibit Varian + 2 Hewan Varian) = 214. Album adalah GUI, bukan item fisik. |
| 19 | **Antrean Dapur DIHAPUS** | Tidak ada di v6, tidak pernah dibahas. Dapur tetap Slot 1 / 2 / 3, 1 resep per slot, tidak ada antrean. |
| 20 | **MVP / Fase Launch DIHAPUS** | Semua jadi SATU CORE LOOP. Tidak ada MVP, tidak ada fase. Semua gameplay adalah core loop. |
| 21 | **Map TIDAK DIBAHAS di dokumen ini** | Map sudah ada di Roblox Studio (alun-alun di tengah, 8 lahan simetris 2 lahan per sumbu). Dokumen ini tidak membahas layout map. |
| 22 | **Yang tidak dibahas = LOCKED** | Semua angka yang tidak dibahas di revisi ini tetap sama seperti v6.2.3, tidak diubah. |

---

## 1. Prinsip Desain — LOCKED

| # | Prinsip | Artinya di Kode |
|---|---------|-----------------|
| 1 | Cozy, tanpa fail | Tanaman tidak mati/layu. Hewan tidak mati/sakit/kabur. Bangunan tidak roboh. Quest tidak gagal karena waktu. Hapus bangunan refund 100%. |
| 2 | Tanpa stamina | Tidak ada energi. Batas main hanya dari waktu tumbuh, bukan dari bar energi. |
| 3 | Siram itu bonus | Tanaman tumbuh tanpa siram. Siram mempercepat + menandai Basah (dibutuhkan Kualitas Bagus / Prima). |
| 4 | Tanpa pupuk, tanpa hama | Tidak ada item pupuk. Tidak ada hama. Tidak ada efek "tahan hama". |
| 5 | Langka itu momen, bukan rebutan | Semua kelangkaan dihitung per-player (pity), tidak ada barang langka yang "habis" karena player lain. |
| 6 | Hias karena suka | Hanya Dekor Berkah yang punya stat. Mayoritas dekor murni visual. |
| 7 | Hias per-satuan | Tidak ada rumah jadi. Tidak ada Robux / Bunga untuk beli rumah jadi atau skip bangun. |
| 8 | Lahan 100% bebas | Tidak ada zona dikunci di dalam lahan. Ghost merah muda hanya jika nabrak / di luar lahan. |
| 9 | Waktu itu server | Hari game, cuaca, reset harian diatur server. Tidak ada furniture yang memajukan waktu. |
| 10 | HP 4GB adalah target | RAM 4GB, Helio G99 / Unisoc T7250. Semua cap & render untuk HP ini. |
| 11 | Dua ekonomi terpisah | Koin (main) dan Bunga (premium) tidak bisa ditukar dua arah. |
| 12 | Bunga = kenyamanan & gaya, bukan kekuatan | Bunga membeli QoL, kosmetik, waktu. Tidak membeli Koin, XP, level, bahan mentah, hewan. Semua konten bisa dicapai F2P. |
| 13 | Sehat untuk 16+ | Tidak ada hadiah untuk main >60 menit non-stop. Tidak ada streak yang reset. Tidak ada loot box. Tidak ada iklan. Tidak ada desain judi / FOMO. |
| 14 | Jangan terlalu diinfokan | UI tampilkan angka & ikon. Tidak ada paragraf penjelasan. Info pertama kali = toast 1x, lalu diam. |
| 15 | 1 aturan, 1 tempat | Kode & dokumen: setiap angka hanya didefinisikan di 1 Config. |
| 16 | Tidak bergantung jumlah player | Tidak ada target / progres yang butuh banyak player atau lintas server untuk selesai. Target bersama selalu dihitung dari player di server saat itu. Semua progres jangka panjang bersifat pribadi. Game harus tetap lengkap dimainkan walau server cuma berisi 1 orang. |
| 17 | Kualitas, bukan lotre | Kualitas didapat dari timing + siram, bukan dari roll lotre / jendela acak. Tidak ada Mutasi, tidak ada Pelangi, tidak ada Greenhouse yang memisahkan tanaman dari hujan. |

---

**Gating — Definisi (LOCKED v7.3):** Gating = syarat yang harus dipenuhi dulu baru konten kebuka. Gating yang BOLEH: Level gating (Dapur Tier 2 Lv 15), Koin gating (Petak n x 150, Chunk 1.500 x 1,2^n), Quest gating (Kolam Kakek setelah MQ4). Gating yang DILARANG: Blueprint gating (dekor terkunci di balik beli Blueprint), Backpack gating (Tas terkunci di balik Pass), Bibit Unggul gating (tumbuh cepat terkunci di balik harga x1,5). Blueprint hanya simpan / share desain, bukan gating.

## 2. Target Pemain & Bentuk Sesi

### 2.1 Persona (16+)

| Persona | Umur | Main | Yang Dicari | Ditangkap Oleh |
|---------|------|------|-------------|----------------|
| **Player Santai** | 16-18 | 30-45 menit/hari, HP sendiri | Cozy, gampang, cerita | Tutorial cepat, hewan, Kualitas, Gestur |
| **Player Dekorator** | 16-20 | 1-2 jam/hari | Rumah cantik, foto, like | Hias, Blueprint, Galeri Kampung |
| **Player Kolektor** | 16+ | 2+ jam/hari | Lengkap 100%, langka | Album 214, Ikan Legenda, Kualitas Prima, Level Cap |
| **Player Roblox Umum** | 16+ | Coba 5 menit dulu | Ada yang seru di menit pertama | FTUE Bab 16, panen pertama dijamin Bagus |

### 2.2 Bentuk Sesi 30 Menit (Contoh, Bukan Paksaan)

| Menit | Aktivitas | Sistem |
|-------|-----------|--------|
| 0-3 | Login, ambil bubu + telur + anak kolam, buka Surat Kakek | Bab 7, 14.2 |
| 3-10 | Panen + tanam ulang, cek Gerobak Kaget | Bab 5, 13.1 |
| 10-20 | Mancing (sering pas hujan) | Bab 6 |
| 20-25 | Nambang 1 putaran | Bab 8 |
| 25-30 | Hias 1-2 piece / Warung / bantu tetangga, tanam Late sebelum logout | Bab 8, 12 |

### 2.3 Batas Sehat (LOCKED)

- Hadiah Waktu Bermain hanya sampai 60 menit (Bab 15.2). Setelah 60 menit tidak ada hadiah tambahan.
- Setelah 120 menit main dalam 1 hari WIB, muncul toast lembut 1x: `Udah 2 jam nih. Jangan lupa minum & istirahat ya!` Tidak mengunci, tidak menghukum.
- Tidak ada streak yang reset. Semua login reward kumulatif.

---

## 3. Dunia, Lahan, Server, Waktu & Cuaca

> Map sudah ada di Roblox Studio. Dokumen ini tidak membahas layout map.

### 3.1 Dunia, Lahan, Server

| Item | Spesifikasi |
|------|-------------|
| Server | Max 8 player. StreamingEnabled ON. |
| Lahan Awal | 128x128 stud. Kotak cadangan maksimal 192x192 stud (6x6 chunk). |
| Beli Chunk | Lahan bertambah per chunk 32x32 stud, dari dalam lahan yang sudah dimiliki. Harga chunk ke-n (n mulai 0): `1.500 x 1,2^n` Koin, dibulatkan 10. Tanpa syarat level. 14 chunk bisa dibeli. Total 88.790 Koin. Lihat Bab 17.4. |
| Grid | Petak tanam 8x8 stud (`Land.TILE`). Hias: struktur snap 2 stud, furniture & dekor snap 1 stud. Rotasi 0/90/180/270. |
| Lahan Awal | BERSIH sepenuhnya. Tidak ada ilalang, semak, batu kecil, tunggul, atau bangunan rusak. Chunk yang dibeli juga bersih. |
| Hutan Nambang | Area bersama (bukan map terpisah), node bahan per-player (tidak rebutan). |
| Perairan | **Sungai Lahan** (32 spot di 4 sungai sumbu, Early saja, Lv 1), **Kanal Barat** (dermaga, Lv 5: Mid + Belut Emas), **Kanal Timur** (dermaga, Pro Mancing, Lv 10: Late + Legenda). Danau dan Spot 4 belum ada di Studio (Lampiran D). (Update owner 2026-11-22, Task 2.) |

### 3.2 Hari Game (LOCKED)

1 hari game = **30 menit nyata**, berjalan terus selama server hidup.

| Fase | Durasi Nyata | Visual | Gameplay |
|------|--------------|--------|----------|
| Pagi | 3 menit | Kabut tipis, ayam berkokok | Gurame Raja hanya Pagi (Bab 6.4) |
| Siang | 15 menit | Cerah warm | Normal |
| Sore | 3 menit | Oranye lembut, jangkrik mulai | Normal |
| Malam | 9 menit | Biru gelap, lampu warm otomatis, kunang-kunang | Ikan malam, Pasar Malam (Bab 13.2) |

- Reset harian (Agenda, Login, Bantu, batas hadiah Kerja Bakti Kilat) tetap **05:00 WIB** kalender nyata.
- HUD menampilkan ikon fase, bukan jam digital.

### 3.3 Cuaca (LOCKED — Satu-satunya Definisi Cuaca)

| Aturan | Detail |
|--------|--------|
| Siklus | Terik **8-15 menit** (random per siklus) → Hujan **3 menit** → Terik 8-15 menit → dst. Tidak pernah hujan 2x berturut-turut. |
| Jenis hujan | Gerimis 55%, Deres 30%, Petir 15%. Di-roll saat Terik habis. |
| Tidak ada salju | Tidak ada salju / es / musim dingin. |
| Tidak mengunci | Semua aktivitas tetap bisa saat hujan. Kecepatan jalan tidak berubah. |
| Tanda hujan | 10 detik sebelum hujan, muncul tanda: awan gelap + suara + ikon hujan di HUD. Tidak ada ramalan cuaca / forecast. |
| Terik | Netral. Tidak ada bonus apa pun. |

**Efek Hujan (LOCKED):**
- Semua tanaman luar tersiram 1x (potong sisa 15%). Selama hujan, tanaman luar tumbuh **2x lebih cepat**.
- Mancing: gigitan **2x lebih lama**. Pakai umpan 3-6 detik jadi 6-12 detik, tanpa umpan 6-12 detik jadi 12-24 detik.
- Ternak: **Mood Hujan** — 5 menit setelah hujan selesai, produk ternak yang diambil dapat **+10% Koin**. Breeding Kolam yang dimulai di window 5 menit itu dapat **-10% waktu**. Lihat Bab 7.1 dan Lampiran C untuk hitungan.
- Kerja Bakti Kilat dipicu setelah Hujan Deres / Petir (lihat Bab 13.4).

---

## 4. Mata Uang & Level

### 4.1 Mata Uang

| Mata Uang | Dapat Dari | Dipakai Untuk | Tidak Bisa |
|-----------|------------|---------------|------------|
| **Koin** | Jual hasil, Agenda, Bantu, Kerja Bakti, Warung | Bibit, umpan, pakan, hewan, alat, petak, ekspansi, skill | Tidak ke Bunga |
| **Bunga** | Login Mingguan, Peti, Pencapaian, Album, Season, Event, Bundel | Alat Bunga (QoL), kosmetik, dekor, instant Kolam, slot Blueprint ekstra | Tidak ke Koin, XP, level, bahan mentah, hewan |
| **Bahan** | Nambang, panen tertentu (Padi → Jerami, Pisang → Daun Pisang) | Craft piece hias, alat, kandang | Tidak dijual di toko mana pun |

Bunga F2P ~240/bulan (Login 40, Pencapaian 40, Album 30, Season 30, Event 30, Bundel 10, Peti 60; Update owner 2026-11-22). Lihat Bab 18 untuk rincian.

### 4.2 Level Player

- Level Cap rilis **Lv 60**. Naik +20 tiap Update Besar.
- XP per aksi: Panen, Mancing, Ternak, Masak, Nambang, Bantu, Kerja Bakti, Quest. Lihat tabel di Bab 5, 6, 7, 9.
- Rumus XP naik level: `200 + 30 x n` untuk Lv n → n+1. Contoh Lv 59→60: 2.170 XP. Total Lv 1→60: 64.900 XP.
- Tidak ada Bunga dari level-up. Tidak ada Bunga dari milestone level.

### 4.3 SP (Skill Point)

- 1 SP per Level Player. Dipakai untuk beli Skill Cabang (Bab 4.5).
- Skill tidak bisa dibeli pakai Bunga / Robux.

### 4.4 Unlock

| Lv | Buka |
|----|------|
| 1 | Kangkung, Bayam, Wader, Betok, Joran Bambu, Sungai Lahan (spot Early) |
| 2 | Tomat, Sawi, Lele |
| 3 | Jagung, Ubi Jalar, Pakan Jagung, Bang Jali (NPC) |
| 5 | Ayam, Mujair, Nila, Kanal Barat (Mid + Belut Emas) |
| 4 | Kolam Tanah (dibeli setelah M3 Kolam Kakek) |
| 6 | Singkong, Dapur Tier 1 |
| 7 | Warung |
| 8 | Bubu Bambu, Bundel Sumur Tua |
| 8 | Cabai, Padi, Gurame, Patin |
| 10 | Bebek, Gabus, Baung, Kanal Timur (Pro Mancing) |
| 12 | Stroberi |
| 15 | Pisang, Tebu, Dapur Tier 2, Jelawat, Kolam Semen |
| 18 | Toman, Tapah, Spot 4 |
| 22 | Jahe, Sapi, Sidat |
| 25 | Kopi, Teh, Semah |
| 30 | Melati, Belida, Kolam Keramik |
| 35 | Mangga, Dapur Tier 3 |
| 36 | 6.x (Toko, Robux) | Toko: panel menyesuaikan isi ("sized to content"). | Bug UI 5: fit-to-content mengukur daftar sebelum tata letak selesai, lalu memperkecil panel (sekitar 100 px). Isi tidak terlihat. Sekarang panel memakai ukuran sheet UiKit standar (88 % x 86 %, maks 600 x 400), daftar bisa digulir. Tab sisi memakai tier 32 px dan teks terbaca di kedua keadaan. | BUTUH KEPUTUSAN OWNER: setujui panel ukuran standar dengan daftar bergulir, atau minta ukuran sesuai isi dengan batas bawah yang disetujui. |
| 37 | 13.4 / 14.4 (Kerja Bakti, quest Side Kerja Bakti 10x) | Quest "Ikut 10 Kerja Bakti" perlu petunjuk: di mana, apa, dan kapan aktif. | Bug UI 6: baris petunjuk di Quest Log memakai teks yang sudah ada (`kb.active` / `kb.none`, `kb.how` "Hujan reda: pungut sampah di plaza, +15 Koin +3 XP/poin"). "Tunjukkan" menunjuk sampah terdekat dengan panah (`WorldArrow`) selama Kerja Bakti aktif. Belum ada di Naskah / Locale: syarat muncul yang sama dengan Bab 13.4 ("setelah Hujan Deres / Petir"), karena kb.how memakai "Hujan reda". | BUTUH KEPUTUSAN OWNER: teks syarat muncul (Bab 13.4: hujan deres atau petir) dan apakah teks "Hujan reda" tetap. Tidak ditulis baru. |
| 38 | Skill Tree Bab 2.2 / 6 (Skill) | Joran Kuat: kotak tarik +2%/lv. Skill Tree Bab 2 mengatur prasyarat dan efek, tidak menyebut tempat validasi. | Bug efek: efek Joran Kuat hanya ada di klien (`FishingController` lebar kotak tarik). Server tidak memvalidasi lebar. Perlu validasi di server (fishing reel) atau dibiarkan sebagai efek visual, keputusan owner. Efek lain (Kayu Kuat, Umpan Hemat, Firasat, Ikan Besar) ada di server. | BUTUH KEPUTUSAN OWNER / kode: validasi Joran Kuat di server, atau turunkan ke klien saja dan catat. |
| 39 | GUI doc 4.6 (Ikon) / Skill Tree Bab 3 | Ikon tombol Acara dan Skill, dan gerbang panel Skill. | UI-4: tidak ada `asset id` ikon untuk Acara (`AcaraButton`) dan Skill (`SkillButton`) di `UiAssets.ICONS`. Tombol memakai pil teks (tanpa ikon) sampai ada aset. Panel Skill tidak punya gerbang fitur: tidak ada `feature id` skill di Quest v0.3 atau di FeatureGate, jadi tidak dibuat (tidak ada yang dikarang). | BUTUH KEPUTUSAN OWNER: (a) aset ikon acara dan skill (ForgeGUI), (b) apakah Skill Tree perlu gerbang fitur (dan id-nya), atau terbuka dari awal. |
| 40 | Skill Tree Bab 3 (Tampilan) | Node dengan label nama dan garis dahan. | UI-4: node hanya menampilkan level (x/5), nama dan efek ada di drawer (tap node). Label nama di bawah node tidak dipasang karena garis dahan melewati label. Ukuran node 40 px (UiKit.TOUCH_CTA) dan jarak tier 30 px adalah layout, bukan angka desain. | BUTUH KEPUTUSAN OWNER: nama di node (ikon atau singkatan, perlu teks baru) atau tetap di drawer. |
| 41 | 14.1 / 16.2 (Sapaan NPC, audit) | Perkenalan NPC diulang setelah quest atau bicara lain. Audit semua baris: `npc.<id>.meet`, baris pembuka quest `dlg.*.start`, tutorial, dan toko. | Hasil audit: (1) `npc.<id>.meet` (sapaan pertemuan pertama, memuat nama dan peran): mak_sari, nek_ani, pak_udin, kak_fajar, bang_jali, pak_amran, dan NPC malam (pedagang_tamu, pak_kumis, nek_esih, bang_dodo, mpok_riah, kang_asep, yu_tum, tamu_event). Tetap, hanya saat pertemuan pertama (`HasMet`). (2) Baris quest yang memperkenalkan: `dlg.m1.start.1` ("Nenek Ani, yang jaga pos ronda ini") -> "Kamu cucunya Daeng, kan?"; `dlg.s3.start.1` ("Bang Jali, warung kecil depan lahanmu") -> dihapus bagian perkenalan; `dlg.s4.start.1` ("Saya Amran, tukang kayu.") -> dihapus bagian perkenalan. (3) Tutorial `tut.t1b.hadiah.1` ("Aku Fajar") tetap: pertemuan pertama di tutorial. (4) `npc.kak_fajar.gift` tanpa perkenalan, dipakai saat sudah bertemu. (5) `npc.<id>.role` hanya label, tidak diucapkan. Sumber pertemuan: `guide.hasMet` (sudah ada di DataTemplate, default {} untuk save lama lewat reconcile profil) ditulis dari HasMet, penerimaan dan penyelesaian quest (pemberi), beli / jual toko, MeetFajar, dan tutorial. | BUTUH KEPUTUSAN OWNER: (a) setujui penulisan ulang 3 baris (teks lama di atas), (b) apakah pemberi quest yang belum pernah bicara tetap dapat sapaan pertama saat quest selesai. |
| 42 | 6.3 (Umpan) / F-3 | Pilih umpan aktif (ganti umpan) saat memancing. | Tidak ada sistem pilih umpan di kode. Server memakai umpan pertama yang dimiliki menurut urutan `Fishing.BAITS` (cacing, jangkrik, pelet, udang kecil). Chip umpan hanya menampilkan umpan yang sedang dipakai itu. Tidak ada sistem baru (sesuai brief). | BUTUH KEPUTUSAN OWNER: apakah pemain perlu memilih umpan (ubah urutan atau tombol pilih). |
| 43 | Ikon (F-1 / F-3) | Ikon umpan di Tas dan chip memancing. | Ikon umpan belum ada. `UiAssets.ICONS` tidak punya kunci umpan (cacing, jangkrik, pelet, udang kecil). Tas dan chip memakai ikon placeholder "tas". Log: bait icons missing. | BUTUH ASET: ikon umpan (ForgeGUI) untuk empat umpan. |
| 44 | 4.5 (Layer) / toast | Toast: satu tempat untuk semua toast. | F-2: `UiKit.toastStack` adalah satu jangkar (tengah atas, di bawah CurrencyBar dengan jarak 8 px, lebar maks 50 % layar, di antara tracker kiri dan kolom menu kanan). `UiKit.toastChip` memakai teks terbungkus. Antrean di `HudController`: tampil maks 3 sekaligus, tiap 1,8 dtk (TOAST_SECONDS). Posisi toast tutorial (ikut bawah GuideUI Hint) dihapus. Belum diubah: reward popup dan efek terbang (FeedbackController, UiKit RewardPopups) tetap karena bentuknya lain (tidak teks toast); banner level (LevelUpUI) juga tidak diubah. Konstanta tracker (220) dan kolom menu (70) adalah ukuran tata letak yang sudah ada. | BUTUH KEPUTUSAN OWNER: setujui bahwa reward popup dan efek terbang bukan toast, atau minta digabung ke jangkar yang sama. |
| 45 | 4.5 / HUD (zona layar) | Tata letak HUD: zona atas tengah, kiri, kanan, bawah, dan zona konteks di atas tombol bawah. | Perbaikan HUD: peta tata letak satu tempat (`UiKit.HUD`, `UiKit.hudStripBottomGap`). Zona konteks (status memancing dan chip umpan) di tengah, satu tombol di atas dock (jarak 58 px). Tombol Batal diganti tombol berlabel 64 x 32 px (sebelumnya ikon X 26 px terpotong). Baris tracker membungkus teks dan tumbuh (tidak terpotong). Ukuran dihitung dari kode, belum diuji di Studio. Hasil hitung: phone landscape 844x390 dan 667x375 aman; phone portrait 390x844: lebar toast hanya 100 px (tracker kiri 220 px + kolom menu kanan 70 px menyisakan 100 px), terlalu sempit untuk teks panjang. Tinggi tracker dibatasi (min 200 px dan 25 % layar), baris di luar batas terpotong oleh batas itu. | BUTUH KEPUTUSAN OWNER: (a) toast di portrait: pindah ke bawah tracker atau turunkan batas tracker, (b) batas tinggi tracker di layar pendek, (c) tes Studio di 844x390, 667x375, 390x844, 1920x1080. |
| 45 | Durian |

### 4.5 Skills (16 skills)

Daftar 16 skill, cabang, efek, prasyarat, dan biaya dipindah ke dokumen terpisah: **`docs/Skill_Tree_Kampoeng_Tedoeh_v7.7.md`** (Bab 2 pohon dan prasyarat, Bab 1 aturan beli, Bab 6 keputusan owner). Bab ini tidak lagi menyalin tabelnya (aturan 1 aturan 1 tempat).

Skill di luar cap Dekor (max +10% per jenis). Lihat Bab 17.6.

---

## 5. NANEM — Semi-Pasif, Core

### 5.1 Loop

Pilih petak kosong → Tanam bibit (bayar bibit) → Tumbuh (jalan walau offline) → Siram opsional → Panen (Koin + XP + tentukan Kualitas (Biasa / Bagus / Prima)) → Petak kosong, tanam lagi.

- Satu aksi tanam / panen ≈ 1 detik aktif per petak. 12 petak ≈ 30 detik.
- **Siram:** mengurangi sisa waktu tumbuh 15% (sekali per fase tumbuh, max 1x per tanaman per siklus) + menandai tanaman `Basah` (dibutuhkan Kualitas Bagus / Prima, Bab 5.4). Hujan otomatis menyiram semua tanaman luar 1x.
- **Telat panen:** tanaman jadi sedikit lebih besar (scale 1,1), tidak layu, tidak hilang. Ambang 10 menit setelah matang.

### 5.2 Petak

| Item | Aturan |
|------|--------|
| Petak awal | 6 |
| Max rilis | 36 |
| Buka petak ke-n | `n x 150` Koin (petak 7 = 1.050, petak 36 = 5.400). Total petak 7-36 = 96.750 Koin. Syarat: petak 7-12 tanpa level, petak 13-24 butuh Lv 10, petak 25-36 butuh Lv 25. |
| Hapus petak (refund) | Garap > Hapus Petak mengembalikan **50%** harga petak yang DIBELI (contoh petak 7 = 525 Koin). Petak gratis (6 pertama) tidak ada refund. Harga tiap petak dicatat saat dibeli. Owner setuju 2026-11-22 (Lampiran D #14). |
| Konfirmasi beli petak | Petak 7 dan seterusnya membuka modal konfirmasi berisi harga. Jika Koin kurang: harga merah, tombol Cangkul dikunci, dan modal menulis "Koin kamu belum cukup". |
| Ukuran petak | 8x8 stud (`Land.TILE`). Garap (bajak) bebas di mana saja di lahan sendiri; jumlah petak yang dibajak dibatasi baris di atas. |

### 5.3 Tanaman Rilis (18) — LOCKED

Aturan harga: Bibit ≈ 30% harga jual. Late harus 30-50x Early karena waktu tunggunya 60-120x dan cocok untuk offline.

| # | Tanaman | Tier | Waktu | Bibit | Jual | XP | Buka Lv |
|---|---------|------|-------|-------|------|----|---------|
| 1 | Kangkung | Early | 3 mnt | 8 | 25 | 12 | 1 |
| 2 | Bayam | Early | 5 mnt | 10 | 32 | 15 | 1 |
| 3 | Tomat | Early | 6 mnt | 12 | 36 | 16 | 2 |
| 4 | Sawi | Mid | 20 mnt | 25 | 80 | 35 | 2 |
| 5 | Jagung | Mid | 30 mnt | 35 | 110 | 45 | 3 |
| 6 | Ubi Jalar | Early | 7 mnt | 12 | 38 | 18 | 3 |
| 7 | Singkong | Mid | 25 mnt | 30 | 95 | 40 | 6 |
| 8 | Cabai | Mid | 30 mnt | 40 | 125 | 50 | 8 |
| 9 | Padi | Late | 2 jam | 120 | 400 | 140 | 8 |
| 10 | Stroberi | Late | 2 jam | 130 | 420 | 150 | 12 |
| 11 | Pisang | Late | 3 jam | 160 | 520 | 180 | 15 |
| 12 | Tebu | Mid | 40 mnt | 50 | 160 | 60 | 15 |
| 13 | Jahe | Mid | 35 mnt | 45 | 140 | 55 | 22 |
| 14 | Kopi | Late | 4 jam | 200 | 650 | 220 | 25 |
| 15 | Teh | Late | 6 jam | 260 | 850 | 280 | 25 |
| 16 | Melati | Mid | 30 mnt | 40 | 130 | 50 | 30 |
| 17 | Mangga | Late | 8 jam | 320 | 1.100 | 360 | 35 |
| 18 | Durian | Late |8 jam| 380 | 1.300 | 400 | 45 |

- Padi juga memberi 2 Jerami per panen (bahan). Pisang juga memberi 2 Daun Pisang per panen (bahan Dapur, hanya untuk Pepes). Jagung bisa jadi pakan ayam di Dapur (Bab 9).
- **Super DIHAPUS (Update owner 2026-11-22):** tidak ada lagi Super, tidak ada pengali Koin / XP tambahan. Yang ada hanya Kualitas (Bab 5.4): Bagus dan Prima, dengan batas akhir **Bagus max 50%, Prima max 20%**, Biasa sisanya. Batas dihitung setelah semua bonus (Mata Kualitas, Buff Tani).

### 5.4 Kualitas Panen (Pengganti Mutasi) — LOCKED

Mutasi DIHAPUS. Tidak ada Embun, Petir, Emas, Pelangi sebagai Mutasi. Penggantinya Kualitas Panen yang cozy dan terkontrol.

- Kualitas ditentukan saat panen, dari timing + siram. Tidak ada roll lotre acak, tidak ada jendela 60 detik.
- Hasil panen masuk tas dengan kualitasnya. Kualitas dipakai Dapur untuk tentukan Kualitas Olahan dan Album.

| Kualitas | Syarat Peluang | Harga Jual | Visual |
|----------|---------------|------------|--------|
| **Biasa** | Base | x1,0 | Normal |
| **Bagus** | Panen tepat waktu + Basah menaikkan peluang | x1,1 (+10%) | Daun lebih segar, kilau lembut |
| **Prima** | Panen tepat waktu + Basah menaikkan peluang (lebih kecil dari Bagus) | x1,25 (+25%) | Kilau emas lembut, partikel kecil |

**Batas peluang (Update owner 2026-11-22, Task 3):** dihitung SETELAH semua bonus (Skill Mata Kualitas + Buff Tani). **Bagus maksimal 50%, Prima maksimal 20%.** Biasa mengambil sisanya. Buff Tani = +10% absolut ke peluang Bagus (`Dapur.BUFF_TANI_BAGUS`). Panen pertama FTUE selalu Bagus (Bab 16.2). Super DIHAPUS: tidak ada lagi item atau pengali Super.

Distribusi peluang (LOCKED):

| Kondisi Panen | Biasa | Bagus | Prima |
|---------------|-------|-------|-------|
| Tepat waktu (<=5 menit setelah matang) + Basah | 50% | 35% | 15% |
| Hanya salah satu | 65% | 25% | 10% |
| Telat + tidak Basah | 85% | 12% | 3% |

- Skill Mata Kualitas menambah peluang absolut (+2%/lv Bagus, +0,5%/lv Prima, max +10% Bagus, +2,5% Prima).
- **Pengumuman server:** Panen Prima pada tanaman Late → banner kecil ke semua player di server: `Raka panen DURIAN PRIMA!` (3 detik, atas tengah, tidak mengunci).
- Album Kampung mencatat setiap kombinasi Tanaman x Kualitas pertama kali: 18 tanaman x 3 Kualitas = 54 entri (Bab 11).
- Hitungan ekonomi: lihat Bab 17.7 dan Lampiran C. Expected multiplier rata-rata player x1,055 (Nanem 3.300 → 3.482, total 12.000 → 12.182, sink 71% → 72,0%). Aman, tidak merusak ekonomi.

### 5.5 Fitur Nanem Lain

| Fitur | Aturan |
|-------|--------|
| Pasar Harian | 2 tanaman +30% per hari WIB (1 Early, 1 Mid/Late). Berlaku di semua penjual. Ikon koin kecil di atas petak yang laku. |
| Rotasi | Tanam beda dari siklus lalu di petak yang sama: +5% XP. Tidak ada hukuman jika sama. |
| Orang-orangan Sawah | Dekor Berkah, +3% peluang Bagus radius 5 petak. |
| Bantu Tetangga | Siram & panen di lahan teman, lihat Bab 12.2. |

---

## 6. MANCING — Aktif, Fokus Pendek

### 6.1 Loop

Pergi ke spot → Pilih umpan → Lempar (0,6 detik) → Tunggu gigitan (3-6 detik pakai umpan, 6-12 detik tanpa umpan) → Gigitan: jendela 1,5 detik untuk mulai tarik → Tarik (mini-game) → Dapat ikan (kartu ikan) → Ulangi.

- Satu siklus 10-25 detik.
- Umpan dan jual ikan bisa dilakukan di **Lapak Kak Fajar** di pinggir Kanal (beli umpan, jual ikan 100%) — player tidak perlu bolak-balik ke Alun-alun.
- Jalan menjauh >8 stud dari spot = pancingan ketarik otomatis, umpan kembali (tidak hilang).
- **Hujan:** gigitan 2x lebih lama (pakai umpan 6-12 detik, tanpa umpan 12-24 detik). Lihat Bab 3.3.

### 6.2 Mini-game Tarik

- Bar horizontal, ikon ikan gerak kiri-kanan, kotak player digeser (Tahan = kanan, Lepas = kiri).
- Progress mulai 30%. Ikan di kotak **+28%/detik** (`FILL_GAIN = 0.28`), di luar kotak **-6%/detik** (`FILL_DRAIN = 0.06`). 100% = dapat. 0% = lepas, umpan hilang, tidak ada hukuman lain.
- **Kecepatan zona (nilai diterima owner 2026-11-22, Lampiran D #2 ditutup):** saat Tahan (kanan) `ZONE_SPEED = 0.9` lebar bar per detik; saat Lepas (kiri) `ZONE_SPEED_LEFT = 0.55` lebar bar per detik. Sumber: `src/client/Controllers/FishingController.luau`.
- **Coachmark tarik tidak dipakai lagi** (keputusan owner 2026-11-22, Lampiran D #3 ditutup).
- Perilaku: Early pelan & mudah ditebak (5-8 detik), Mid sering ganti arah (10-15 detik), Late cepat + dash (15-25 detik), Legenda dash + pause tiba-tiba (20-30 detik).
- **Mode Bantu (Settings, default OFF):** kotak +10% lebar & ikan 15% lebih lambat, untuk aksesibilitas. Tidak ada pengurangan hadiah.

### 6.3 Joran & Umpan

> "Mancing Lv N", "Bertani Lv N", "Tukang Lv N" di tabel ini dan Bab 17.5 berarti **Player Lv N**, bukan level cabang atau level skill (Skill Tree Bab 5).

| Joran | Harga | Kotak | Syarat |
|-------|-------|-------|--------|
| Bambu | Gratis (tutorial) | 30% | Mancing Lv 1 |
| Kayu | 900 Koin + 10 Bambu | 33% | Mancing Lv 2 |
| Kayu Jati | 3.500 Koin + 20 Bambu | 36% | Mancing Lv 4 |
| Bambu Wulung | 9.000 Koin + 30 Bambu | 39% | Mancing Lv 6 |
| Besi | 18.000 Koin + 30 Bambu + 15 Batu | 42% | Mancing Lv 8 |
| Pusaka | 35.000 Koin + 40 Bambu + 20 Batu + 10 Ijuk | 45% | Mancing Lv 10 |

| Umpan | Harga | Efek | Sumber |
|-------|-------|------|--------|
| Cacing | 10 Koin | Standar | Beli di Kak Fajar |
| Jangkrik | 25 Koin | Gigitan 30% lebih cepat | Beli di Kak Fajar |
| Pelet | 45 Koin | +15% peluang Mid+ | Beli di Kak Fajar |
| Udang Kecil | 80 Koin (Mancing Lv 6) | +10% peluang Late+ | Beli di Kak Fajar |

### 6.4 Ikan Rilis (20) — LOCKED

Berat di-roll per tangkapan: Kecil x0,8 (40%), Sedang x1,0 (40%), Besar x1,2 (15%), Jumbo x1,5 (5%). Harga di tabel = Sedang.

| # | Ikan | Tier | Spot | Waktu | Jual | XP | Buka Lv |
|---|------|------|------|-------|------|----|---------|
| 1 | Wader Cakul | Early | Sungai Lahan | Kapan saja | 20 | 10 | 1 |
| 2 | Betok | Early | Sungai Lahan | Kapan saja | 26 | 12 | 1 |
| 3 | Sepat | Early | Sungai Lahan | Kapan saja | 30 | 14 | 2 |
| 4 | Lele | Early | Sungai Lahan | Malam | 45 | 18 | 2 |
| 5 | Mujair | Mid | Kanal Barat | Kapan saja | 70 | 26 | 5 |
| 6 | Nila | Mid | Kanal Barat | Kapan saja | 90 | 32 | 5 |
| 7 | Tawes | Mid | Kanal Barat | Siang | 110 | 38 | 6 |
| 8 | Gurame | Mid | Kanal Barat | Kapan saja | 160 | 50 | 8 |
| 9 | Patin | Mid | Kanal Barat | Kapan saja | 180 | 55 | 10 |
| 10 | Gabus | Mid | Kanal Barat | Hujan | 200 | 60 | 10 |
| 11 | Baung | Mid | Kanal Barat | Malam | 220 | 65 | 12 |
| 12 | Jelawat | Late | Kanal Timur | Kapan saja | 350 | 95 | 15 |
| 13 | Toman | Late | Kanal Timur | Sore/Malam | 420 | 110 | 18 |
| 14 | Tapah | Late | Kanal Timur (Spot 4 belum ada) | Malam | 600 | 150 | 18 |
| 15 | Sidat | Late | Kanal Timur (Spot 4 belum ada) | Malam + Hujan | 650 | 160 | 22 |
| 16 | Semah | Late | Kanal Timur | Pagi | 520 | 130 | 25 |
| 17 | Belida | Late | Kanal Timur (Spot 4 belum ada) | Kapan saja | 700 | 170 | 30 |
| 18 | **Gurame Raja** | Legenda | Kanal Timur | Pagi | 2.200 | 550 | 15 |
| 19 | **Belut Emas** | Legenda | Kanal Barat | Hujan Petir | 2.000 | 500 | 20 |
| 20 | **Ikan Dewa** | Legenda | Kanal Timur (Spot 4 belum ada) | Malam | 2.500 | 600 | 30 |

### 6.5 Ikan Legenda — Per-Player + Pity (LOCKED)

| Aturan | Detail |
|--------|--------|
| Peluang | 0,5% per lemparan **jika** spot + waktu/cuaca cocok dan Level cukup. |
| Pity | Counter per player per jenis Legenda, hanya naik saat lemparan di kondisi yang cocok. Lemparan ke-**200** dijamin Legenda (dikurangi skill Firasat, min 150). Counter reset setelah dapat. |
| Per-player | Tidak ada batas per server. Player lain tidak mengurangi peluang lo. Tidak ada alasan server hopping. |
| Firasat | Saat pity ≥ 75%, Kak Fajar (kalau dekat) bubble: `Airnya lagi tenang banget... firasatku bagus.` + gelembung emas di pelampung. Tidak ada angka pity di UI. |
| Pengumuman | Dapat Legenda → banner ke semua player di server: `Raka dapet IKAN DEWA (Jumbo)!` 3 detik + fanfare kecil untuk semua. |
| Tidak bisa dibiakkan | Legenda tidak bisa masuk kolam breeding. Bisa dipajang di Akuarium (Bab 8.6) atau dijual. |
| Tidak bisa dijual di Warung / dihadiahkan | Biar tidak jadi barang dagangan. Legenda juga tidak bisa dimasak di Dapur. |

### 6.6 Bubu (Overnight)

| Bubu | Harga | Isi per Panen | Waktu | Max |
|------|-------|---------------|-------|-----|
| Bambu | 400 Koin + 10 Bambu | 3-4 ikan Early | 6 jam | 3 bubu total |
| Kayu | 1.500 Koin + 20 Kayu | 4-6 ikan Early/Mid | 6 jam | (gabungan semua tipe) |
| Besi | 4.000 Koin + 15 Batu + 10 Kayu | 6-8 ikan Mid, 5% 1 ikan Late | 6 jam | |

- 6 jam = pas untuk "pasang sebelum sekolah, panen pulang sekolah" atau "pasang malam, panen pagi".
- Bubu TIDAK bisa di-instant pakai Bunga. Bubu tidak pernah memberi Legenda.

---

## 7. TERNAK + KOLAM — Pasif

### 7.1 Ternak Darat

Loop: Beli hewan → Isi Tempat Pakan (beli pakan) → Produksi jalan walau offline → Ambil produk → Jual / olah.

- Hewan tidak mati/sakit/kabur. Tidak ada daging. Produk: telur, susu (wol di Update 1).
- **Tempat Pakan (anti-AFK, LOCKED):** tiap kandang menampung max **3 jatah siklus** (skill Tempat Pakan Besar: max 5). Setiap 1 siklus produksi memakai 1 jatah per ekor. Jatah habis = produksi berhenti (hewan tetap sehat, idle lucu). Produk menumpuk max 3 per ekor; kalau penuh, produksi berhenti sampai diambil.

| Hewan | Buka Lv | Harga / Ekor | Max (Kandang Lv1/Lv2) | Pakan / Jatah | Produk | Cooldown | Jual | XP |
|-------|---------|--------------|------------------------|---------------|--------|----------|------|----|
| Ayam | 5 | 300 Koin | 6 / 10 | 15 Koin | Telur Ayam | 15 mnt | 40 | 10 |
| Bebek | 10 | 600 Koin | 5 / 8 | 20 Koin | Telur Bebek | 20 mnt | 55 | 13 |
| Sapi | 22 | 3.500 Koin | 2 / 4 | 30 Koin | Susu | 30 mnt | 160 | 28 |

| Kandang | Bangun | Upgrade ke Lv 2 |
|---------|--------|------------------|
| Ayam (12x12) | 800 Koin + 15 Kayu | 3.000 Koin + 20 Papan |
| Bebek (14x14) | 1.200 Koin + 20 Kayu | 5.000 Koin + 25 Papan + 10 Bata |
| Sapi (18x16) | 4.000 Koin + 30 Kayu + 15 Bata | 10.000 Koin + 30 Bata + 15 Semen |

- **Pakan Jagung:** 5 Jagung di Dapur → 6 jatah Pakan Ayam (alternatif gratis dari ladang sendiri, mengikat Nanem ke Ternak).
- **Mood Hujan (LOCKED):** 5 menit setelah hujan selesai, produk ternak yang diambil dapat **+10% Koin**. Breeding Kolam yang dimulai di window 5 menit itu dapat **-10% waktu**. Tidak ada kasih minum. Tidak ada bar haus. Hujan tidak menambah chore.
- Sesi ternak ideal: 1-2 menit (isi pakan semua kandang + ambil semua produk dengan 1 tombol `Ambil Semua` di depan kandang).

### 7.2 Kolam (Bagian dari Beternak)

Loop: Simpan 2 ikan sejenis (non-Legenda) → Isi Pakan Ikan (20 Koin / siklus) → Tunggu → 1 anak ikan → Jual / jadi indukan.

| Tier Kolam | Buka Lv | Harga | Waktu Breeding | Kapasitas Simpan |
|------------|---------|-------|----------------|------------------|
| Tanah | 3 | 1.000 Koin + 20 Batu | 6 jam | 10 ikan |
| Semen | 15 | 3.000 Koin + 20 Bata + 15 Semen | 5 jam | 20 ikan |
| Keramik | 30 | 6.000 Koin + 30 Bata + 25 Semen | 4 jam | 30 ikan |

- Max 4 kolam. **Kolam pertama = Kolam Kakek** (didapat dari Bundel Kakek, Bab 14.5): tier Tanah, gratis, breeding 10% lebih cepat dari kolam biasa, bisa di-upgrade ke Semen/Keramik dengan harga normal. Kolam ke-2 sampai ke-4 dibeli (Kolam Tanah bisa dibeli setelah Kolam Kakek pulih).
- 1 anak per kolam per siklus. Anak ikan dijual 100% harga jenisnya (berat Sedang).
- Kolam bisa di-instant Bunga (Bab 18.5).
- Kolam juga jadi "akuarium jalan": ikan berenang terlihat oleh tamu.
- Mood Hujan juga berlaku untuk Kolam: breeding yang dimulai dalam 5 menit setelah hujan selesai dapat -10% waktu.

---

## 8. NAMBANG + CRAFTING + HIAS

### 8.1 Nambang — Ada Skill, Bukan Cuma Tap

- Lokasi: Hutan Nambang (Lv 4). Node: Pohon (Kayu), Rumpun Bambu (Bambu), Batu Kali (Batu), Tebing Tanah (Tanah Liat), Pinggir Kali (Pasir), Pohon Aren (Ijuk, Lv 15).
- **Node per-player:** setiap player melihat node miliknya sendiri (instanced). Tidak ada rebutan. Node habis respawn **4 menit**.
- **Ritme Pukul:** tiap pukulan, lingkaran mengecil di node. Pencet saat lingkaran pas di tanda = **Critical** (+2 bahan, suara crunchy, partikel besar). Pencet asal = normal (+1 bahan). Satu node = 4 pukulan. Player tetap dapat bahan walau tidak pernah Critical.
- Rata-rata 1 putaran Hutan (± 5 menit) = 30-45 bahan campuran.
- Jerami juga dari panen Padi. Bahan mentah TIDAK dijual di toko mana pun.

### 8.2 Bahan

| Mentah (7) | Olahan (craft gratis di Meja Crafting) |
|------------|-----------------------------------------|
| Kayu, Bambu, Batu, Tanah Liat, Pasir, Jerami, Ijuk | Papan (2 Kayu), Bata (2 Tanah Liat), Semen (2 Pasir + 1 Batu), Anyaman (3 Bambu), Atap Ijuk (3 Ijuk), Genteng (3 Tanah Liat), Kaca (3 Pasir, Lv 25) |

Craft olahan: instan, gratis, hanya bahan. Craft massal: tombol `x10`.

### 8.3 Hias — Loop

Kumpul bahan → Buka Menu Hias → Pilih piece → Warna (12) + Material (4) → Ghost (hijau = bisa, merah muda = nabrak) → Pasang (bahan terpotong) → Putar / copy / undo 10 langkah → Pamer.

- Katalog rilis: **80 piece** (Struktur 25, Atap 10, Furniture 25, Dekor 20). Update menambah ±20 piece per update.
- Material: Kayu, Bambu, Batu, Cat. Warna: 12 lingkaran warna, palet warm kampung.
- Cap per lahan: **800 piece** (rumah + luar). Penuh → toast `Lahan sudah penuh hiasan`.
- Hanya di lahan sendiri. Bangun tidak bisa saat mancing aktif. Mode Hias: player bisa tembus dinding sendiri (anti kejebak).
- Validasi lembut: tanpa pintu / tanpa tiang → toast `Belum ada pintu nih` 1x, tetap boleh.
- Hapus = refund 100%, bahan terbang ke tas.

### 8.4 Dekor Berkah (Satu-satunya Dekor dengan Stat) — LOCKED

- Dari 80 piece rilis, **30 adalah Dekor Berkah** (ditandai ikon daun kecil di katalog). 50 lainnya murni visual.
- 1 Dekor Berkah = 1 stat. Duplikat tidak stack (stat dihitung 1x per jenis). Tidak ada popup; panel Stats yang berubah.
- Contoh stat: `+3% Koin Nanem`, `+3% XP Mancing`, `+3% Bahan Nambang`, `+5% peluang Bagus`, `-3% Cooldown Ternak`.
- Dekor Bunga (Bab 18.3) = Dekor Berkah dengan 2 stat.

### 8.5 Set Dekor

| Set | Isi | Bonus Lengkap |
|-----|-----|---------------|
| Set Kampung | Pagar Bambu, Bale-bale, Sumur Tua, Lampu Minyak, Lampion Bambu | +5% Koin Nanem |
| Set Sungai | Dermaga Kayu, Jembatan Bambu, Lampu Sungai, Perahu Mini, Bendera Kampung | +5% Koin Mancing |
| Set Kandang | Gerobak Jerami, Kincir Kecil, Papan Nama Kandang, Ember Seng, Lumbung Mini | +5% Koin Ternak |
| Set Joglo (Lv 50) | Atap Joglo, Saka Guru, Lantai Tegel, Gebyok, + 1 Dekor Bunga bebas | +5% XP semua |

- Set ditampilkan `Set Kampung 3/5` di panel Stats. Lengkap = 1 baris stat baru + efek kecil sekali (Bab 21).

### 8.6 Pajangan

| Pajangan | Buka | Fungsi |
|----------|------|--------|
| Akuarium | Lv 25 | Pajang 8 ikan (termasuk Legenda, termasuk ukuran Jumbo). |
| Bingkai Album | Lv 15 | Tampilkan % Album Kampung di dinding. |

- Rak Pajangan DIHAPUS total. Tidak ada lagi pajang hasil panen.
- Pajangan = alasan visit & like, dan alasan menyimpan barang langka alih-alih menjual.

### 8.7 Blueprint, Visit, Galeri

- **Blueprint:** simpan desain (3 slot gratis), bagikan kode ke teman. Teman tetap harus punya bahan sendiri. Saat dipakai, ghost blueprint muncul transparan dan bisa dipasang per bagian.
- **Blueprint BUKAN gating.** Dekor bisa langsung di-craft pakai bahan tanpa beli Blueprint. Tidak ada dekor yang terkunci di balik beli Blueprint. Gating yang boleh hanya Level / Koin / Quest (lihat Bab 5 di bawah: Gating). Slot Blueprint ekstra pakai Bunga (lihat Bab 4.1) hanya tambah slot simpan, bukan buka dekor.
- **Visit:** jalan-jalan, duduk, foto. Tidak bisa bangun/hapus/ambil.
- **Like:** `👍 Bagus!` 1x per lahan selamanya per player. Pemberi like +20 Koin (max 10 like berhadiah per hari). Like masuk hitungan mingguan.
- **Galeri Kampung:** papan di Alun-alun berisi 5 lahan dengan like mingguan terbanyak (global, bukan per server). Pencet = visit (teleport ke server pemilik jika online). **Pemilik offline: lahannya kosong, tidak ada yang bisa dikunjungi, tidak ada toast, tidak ada rumah snapshot** (Update owner 2026-11-22: sistem rumah snapshot DIHAPUS, Lampiran D #19).
- **Lomba Hias Bulanan:** tema (contoh: `Kampung 17-an`), juara dipilih dari like + kurasi tim. Hadiah Bunga + dekor eksklusif + title.

---

## 9. DAPUR & OLAHAN

- **Inti Dapur** (Tungku + Meja Olah) dicraft di Meja Crafting, ditaruh bebas di lahan. Bangunan dapur di sekitarnya murni Hias.
- Olahan jalan walau offline. Tidak bisa gosong / gagal.
- Dapur tetap Slot 1 / 2 / 3, 1 resep per slot, **tidak ada antrean**.

| Tier | Buka | Craft Inti | Slot | Waktu Olah |
|------|------|------------|------|------------|
| 1 Tungku | Lv 6 | 10 Kayu + 8 Batu + 5 Tanah Liat | 1 | 100% |
| 2 Kampung | Lv 15 | 15 Papan + 10 Bata | 2 | 85% |
| 3 Lengkap | Lv 35 | 20 Papan + 15 Bata + 10 Semen | 3 | 70% |

Upgrade: craft Inti baru, ganti yang lama (refund 100%), olahan berjalan tidak hilang.

### 9.1 Kualitas Olahan — LOCKED

- Kualitas Olahan ditentukan dari Kualitas bahan tertinggi: ada 1 bahan Prima → Olahan Prima, ada 1 bahan Bagus → Olahan Bagus, sisanya Biasa.
- Harga Olahan = base x Kualitas Olahan (Biasa x1,0 / Bagus x1,1 / Prima x1,25). Tidak double-count dengan Kualitas Panen.
- Prinsip harga: olahan ≈ 1,5-1,8x total nilai bahan mentah. Untuk resep branching (pakai olahan sebagai bahan), harga = nilai olahan + 1,6x nilai mentah tambahan (biar tidak double markup).
- Olahan bisa jadi syarat Agenda & Surat Kakek.
- Skill Rasa Prima: +1%/lv peluang Olahan Prima. Skill Koki Cepat: -3%/lv waktu olah.

### 9.2 Resep (24) — LOCKED (Kombinasi dari List Tanaman / Ikan / Ternak)

Semua bahan bisa dilacak ke: **Tanaman (18)** / **Ikan (20)** / **Ternak (Telur Ayam, Telur Bebek, Susu)** + Garam (beli di Pak Udin 10 Koin) + Daun Pisang (bonus 2 per panen Pisang). Resep ikan pakai **kategori** (Ikan Early / Mid / Late apa saja) agar semua 17 ikan non-Legenda bisa dipakai. Legenda tidak bisa dimasak.

**Tier 1 — Lv 6**

| Resep | Bahan | Waktu | Jual | XP |
|-------|-------|-------|------|----|
| Pakan Jagung | 5 Jagung | 3 mnt | (6 jatah pakan ayam) | 20 |
| Tumis Kangkung | 5 Kangkung + 1 Garam | 5 mnt | 160 | 40 |
| Tumis Bayam | 5 Bayam + 1 Garam | 5 mnt | 280 | 45 |
| Sambal Tomat | 4 Tomat + 2 Cabai | 6 mnt | 320 | 60 |
| Sup Ubi | 3 Ubi Jalar + 1 Jahe | 7 mnt | 400 | 55 |
| Jus Jagung | 3 Jagung + 1 Tebu | 8 mnt | 780 | 70 |
| Keripik Singkong | 4 Singkong + 1 Garam | 8 mnt | 620 | 65 |
| Ikan Early Goreng | 3 Ikan Early apa saja + 1 Garam | 6 mnt | 1,6x nilai bahan (contoh Wader 110, Lele 230) | 50 |

**Tier 2 — Lv 15**

| Resep | Bahan | Waktu | Jual | XP |
|-------|-------|-------|------|----|
| Telur Asin | 4 Telur Bebek + 1 Garam | 20 mnt | 350 | 90 |
| Selai Stroberi | 4 Stroberi + 2 Tebu | 30 mnt | 2.200 | 300 |
| Pepes Ikan Mid | 2 Ikan Mid apa saja + 1 Jahe + 1 Daun Pisang | 25 mnt | 1,6x nilai bahan (contoh Nila 510) | 110 |
| Nasi Goreng Spesial | 1 Sambal Tomat + 3 Padi + 1 Telur Ayam | 25 mnt | 2.300 | 200 |
| Es Tebu | 3 Tebu + 1 Melati | 20 mnt | 980 | 100 |
| Gulai Telur | 3 Telur Ayam + 2 Cabai + 1 Jahe | 24 mnt | 820 | 115 |
| Salad Sawi | 4 Sawi + 2 Tomat + 1 Garam | 20 mnt | 640 | 95 |
| Kue Pisang | 3 Pisang + 2 Tebu + 1 Telur Ayam | 30 mnt | 3.100 | 350 |

**Tier 3 — Lv 35**

| Resep | Bahan | Waktu | Jual | XP |
|-------|-------|-------|------|----|
| Kopi Tubruk | 4 Kopi + 1 Tebu | 40 mnt | 3.000 | 380 |
| Teh Melati | 3 Teh + 2 Melati | 45 mnt | 3.000 | 390 |
| Es Krim Durian | 2 Durian + 3 Susu + 1 Tebu | 60 mnt | 4.200 | 520 |
| Durian Goreng | 2 Durian + 1 Tebu + 1 Garam | 50 mnt | 4.400 | 500 |
| Kopi Susu Gula Aren | 1 Kopi Tubruk + 2 Susu + 1 Tebu | 50 mnt | 3.800 | 480 |
| Nasi Padang Mini | 1 Sambal Tomat + 1 Telur Asin + 3 Padi | 55 mnt | 2.600 | 220 |
| Ikan Late Bakar | 2 Ikan Late apa saja + 1 Cabai + 1 Jahe | 45 mnt | 1,6x nilai bahan (contoh Toman 1.770) | 250 |
| Salad Buah | 2 Mangga + 2 Pisang + 2 Stroberi | 45 mnt | 6.500 | 450 |

Cek kombinasi: **18/18 Tanaman terpakai, 17/17 Ikan non-Legenda bisa dipakai lewat kategori Early (Wader / Betok / Sepat / Lele) / Mid (Mujair / Nila / Tawes / Gurame / Patin / Gabus / Baung) / Late (Jelawat / Toman / Tapah / Sidat / Semah / Belida), 3/3 Produk Ternak terpakai.**

Pakan Jagung adalah pakan Ayam, bukan Olahan untuk player. Pakan Jagung tidak bisa dijual di Warung dan tidak memberi buff (lihat Bab 9.4).

### 9.3 Warung Player (Baru, 1 Core Loop)

- Warung dibuka di Lv 7 (Quest v0.3 Bab 6; sebelumnya Lv 6, bersamaan Dapur Tier 1). Warung adalah bangunan di lahan sendiri, 1 slot pajang per Warung.
- Player pajang olahan di Warung. NPC pengunjung datang tiap 5-10 menit (random, tidak butuh player lain). Mereka beli 1 olahan jika ada yang dipajang.
- Harga Warung = base x Kualitas Olahan (Biasa x1,0 / Bagus x1,1 / Prima x1,25). **Tanpa Reputasi Warung.** Reputasi dihapus karena tidak pernah dibahas.
- Warung offline: penjualan tetap jalan saat offline, max 5 penjualan per login (anti-AFK).
- Warung bukan Pasar antar-player. Tidak ada transaksi player-ke-player, tidak ada tawar-menawar, tidak ada harga dari player lain.
- Warung juga bisa jual hasil mentah? Tidak. Warung hanya untuk olahan. Hasil mentah dijual ke NPC (Bab 10).

### 9.4 Buff Olahan — Makan Sendiri untuk Kegiatan Aktif — LOCKED

- **Prinsip:** Olahan bisa **dijual ATAU dimakan sendiri.** Dijual = dapat Koin. Dimakan = dapat buff. Ada tradeoff beneran, tidak bisa dapat dua-duanya dari 1 Olahan.
- **Cuma 1 buff aktif.** Makan Olahan baru = ganti buff lama. Tidak bisa stack.
- **Durasi dari Kualitas Olahan:** Biasa 10 menit / Bagus 12 menit / Prima 15 menit. Timer jalan real-time, tidak pause offline. Sama seperti Mood Hujan 5 menit.
- **Hanya kegiatan AKTIF.** Buff hanya ngaruh ke aksi yang player lakukan sendiri saat itu. Tidak ada buff pasif.
- **Yang TIDAK kena buff (pasif, haram):** Cooldown Ternak, Breeding Kolam, Waktu Masak Dapur, Bubu, Warung offline, Mood Hujan, Stat Dekor, XP pasif.
- **Pakan Jagung tidak memberi buff.** Hanya untuk Ayam.

| Buff | Dari resep apa | Efek selama buff |
|---|---|---|
| **Buff Tani (Nanem)** | Olahan sayur / buah: Tumis Kangkung, Tumis Bayam, Sambal Tomat, Sup Ubi, Salad Sawi, Nasi Goreng Spesial, Nasi Padang Mini, Salad Buah | Panen +10% peluang Bagus (absolut). Tidak ngaruh ke waktu tumbuh (itu pasif). |
| **Buff Pancing (Mancing)** | Olahan ikan: Ikan Early Goreng, Pepes Ikan Mid, Ikan Late Bakar | Gigitan 20% lebih cepat + Kotak tarik +10% lebih lebar |
| **Buff Tukang (Nambang)** | Olahan energi: Jus Jagung, Keripik Singkong, Gulai Telur, Kue Pisang, Selai Stroberi, Es Tebu, Es Krim Durian, Durian Goreng | Jendela Critical +25% lebih lebar + +1 bahan saat Critical. Berlaku untuk Batu / Tanah Liat / Pasir / Bambu / Ijuk |
| **Buff Tebang (Nebang Pohon)** | Olahan kopi / teh / telur: Kopi Tubruk, Teh Melati, Kopi Susu Gula Aren, Telur Asin | Jendela Critical +25% lebih lebar + +1 Kayu saat Critical. Berlaku hanya untuk Pohon (Kayu) |

- Contoh: Makan Tumis Kangkung Prima = Buff Tani 15 menit. Selama 15 menit, setiap Panen punya +10% peluang Bagus (absolut). Setelah 15 menit habis, buff hilang.
- Buff + Skill stack (contoh: Skill Tangan Hijau + Buff Tani), tapi peluang Bagus tetap dibatasi cap Bagus max 50%, Prima max 20% (Bab 5.4).

---

## 10. NPC & SISTEM JUAL

### 10.1 NPC — LOCKED

| NPC | Peran | Lokasi |
|-----|-------|--------|
| Pak Udin | Warung utama. Jual bibit, pakan, hewan, garam, alat. Beli hasil mentah 100%. Tanpa kuota harian. Bibit Unggul DIHAPUS, hanya Bibit biasa. | Alun-alun |
| Kak Fajar | Joran & umpan. Beli ikan 100%. | Pinggir Kanal |
| Pak Amran | Tukang Kayu. Hadiah rangka rumah pertama, jual alat Tukang, Blueprint (simpan / share desain, bukan gating). | Alun-alun |
| Mak Sari | Warung Mak Sari. Beli olahan 100%. Narator tutorial. Sebelum Dapur terbuka hanya menampilkan baris sapaan. Selama Tutorial 1, ikut blok Bab 16.3 kecuali saat jadi target langkah FTUE. | Alun-alun |
| Nek Ani | Pos Ronda. Quest Kerja Bakti, info cuaca (tanda hujan, bukan ramalan). | Alun-alun |
| Bang Jali (x8) | Satu di depan setiap lahan. Beli semua barang 90%, tidak menjual apa pun. | Depan lahan |
| Pedagang Tamu | Rotasi 6 NPC, beli 1 jenis barang acak +50%, max 10 per player per malam (Pasar Malam). | Alun-alun |
| Tamu Event | Beli barang event, kasih hadiah event. | Alun-alun |

Nama lama yang dilarang: Bu Wati, Mbak Arsi, Bang Tarno, Pak RT, Bu Sari, Mbah Karto, Mas Yudi, Dik Rara. Villager Pesanan Harian diganti NPC v6.1 (Pak Udin, Kak Fajar, Pak Amran, Mak Sari, Nek Ani).

### 10.2 Sistem Jual — LOCKED

| Penjual | Beli Apa | Harga | Kuota |
|---------|----------|-------|-------|
| Pak Udin | Hasil mentah (tanaman) | 100% | Tanpa kuota |
| Kak Fajar | Ikan | 100% | Tanpa kuota |
| Mak Sari | Olahan | 100% | Tanpa kuota |
| Bang Jali | Semua barang | 90% | Tanpa kuota |
| Warung Player | Olahan (ke NPC pengunjung) | Base x Kualitas | Max 5 offline per login |
| Gerobak Kaget | Beli bibit varian / hewan varian / dekor | Lihat Bab 13.1 | Max 3 per slot per restock |

- Pasar Harian & Kualitas dikali di semua penjual.
- Jual pertama di FTUE tidak lewat interaksi bebas — lewat cutscene proximity Bab 16.4, tetap buka GUI Jual Pak Udin yang sama.
- Lapak Tetangga DIHAPUS. Tidak ada pajak Lapak 5%.

### 10.3 Sumber Semua Item (Audit — LOCKED)

| Item | Sumber | Keterangan |
|------|--------|------------|
| Bibit | Beli di Pak Udin | Termasuk Bibit Varian dari Gerobak Kaget |
| Garam | Beli di Pak Udin, 10 Koin | Barang warung dari supplier luar kampung, sengaja jadi sink Koin. Bukan hasil tani, bukan dari Nambang. |
| Daun Pisang | Bonus 2 per panen Pisang | Byproduct Pisang, kayak Padi → Jerami. Tidak bisa dibeli, tidak bisa ditanam sendiri. Stack 99, tidak dijual, hanya untuk Pepes. |
| Jerami | Bonus 2 per panen Padi | Byproduct Padi, bahan craft. |
| Pakan Ternak | Beli di Pak Udin (Ayam 15 / Bebek 20 / Sapi 30 / Ikan 20 per jatah) + Pakan Jagung dari Dapur (5 Jagung → 6 jatah Ayam) | 2 jalur: Koin atau ladang sendiri. |
| Umpan | Beli di Kak Fajar (Cacing 10 / Jangkrik 25 / Pelet 45 / Udang Kecil 80) | - |
| Hewan | Beli di Pak Udin (Ayam 300 / Bebek 600 / Sapi 3.500) | - |
| Alat | Beli di Pak Udin / Pak Amran / Kak Fajar | Lihat Bab 17.5. |
| Bahan Mentah | Nambang Hutan: Kayu dari Pohon, Bambu dari Rumpun Bambu, Batu dari Batu Kali, Tanah Liat dari Tebing Tanah, Pasir dari Pinggir Kali, Ijuk dari Pohon Aren Lv 15 | Per-player, respawn 4 menit. |
| Bahan Olahan | Craft gratis di Meja Crafting: Papan 2 Kayu, Bata 2 Tanah Liat, Semen 2 Pasir + 1 Batu, Anyaman 3 Bambu, Atap Ijuk 3 Ijuk, Genteng 3 Tanah Liat, Kaca 3 Pasir | - |
| Telur Ayam / Telur Bebek / Susu | Dari Ternak | - |
| Ikan | Mancing + Bubu + Kolam (anak ikan) | Legenda tidak bisa breeding, tidak bisa dimasak. |
| Olahan | Dapur | - |
| Bunga | Login Mingguan, Peti, Pencapaian, Album, Season, Event, Bundel | Tidak bisa ditukar Koin. |
| Koin | Jual hasil, Agenda, Bantu, Kerja Bakti, Warung | - |

---

## 11. ALBUM KAMPUNG — Koleksi (GUI)

Album adalah **GUI**, bukan item fisik di Tas, bukan bangunan. Album dibuka dari HUD, tampilannya kartu-kartu. Bingkai Album (Bab 8.6) hanya dekor yang menampilkan % Album.

| Tab | Isi Rilis | Entri |
|-----|-----------|-------|
| Ladang | 18 tanaman x 3 Kualitas (Biasa, Bagus, Prima) | 54 |
| Sungai | 20 ikan x 4 ukuran (Kecil, Sedang, Besar, Jumbo) | 80 |
| Kandang | 3 hewan + 2 Hewan Varian (Gerobak Kaget) | 5 |
| Rumah | 80 piece pernah dipasang | 80 |
| Dapur | 24 resep x 3 Kualitas Olahan (Biasa, Bagus, Prima) — dihitung per resep, bukan per Kualitas bahan | 72 |
| Varian | 6 Bibit Varian + 2 Hewan Varian — sudah dihitung di Ladang / Kandang? Tidak, Varian dihitung terpisah untuk kejelasan GUI: Ladang sudah termasuk Bibit Varian? Koreksi: Total di bawah adalah hitungan GUI yang disepakati. | - |
| **Total** | | **214** |

> Koreksi hitungan GUI yang disepakati: Ladang 54 + Sungai 80 + Dapur 72 + Varian 8 = **214**. Tab Kandang (5) dan Rumah (80) adalah tab terpisah yang tidak masuk ke total 214 GUI utama, karena Kandang / Rumah dihitung di Pencapaian terpisah. Di v6 total 254 termasuk Kandang + Rumah. Di v7.2 total GUI utama 214, Kandang + Rumah tetap ada sebagai tab, tapi tidak menambah total 214. Ini yang disepakati sebagai "214 dalam bentuk GUI".

- Tiap entri baru: kartu kecil `ALBUM +1` 1 detik.
- Milestone Album total (dari 214): 25% → 10 Bunga, 50% → 20 Bunga + Title Kolektor, 75% → 30 Bunga + Dekor Bingkai Emas, 100% → 50 Bunga + Title Legenda Kampung. Angka milestone ini USULAN, belum di-lock ulang, tapi total 214 sudah disepakati.
- **Kartu Album:** tombol `Bagikan` membuat gambar kartu (mode foto) dengan nama player, % Album, dan 3 entri terlangka → bahan share ke teman / medsos.
- Album target selesai: ~3 bulan untuk Player Kolektor (dengan konten Update 1-2 menambah entri).

---

## 12. SOSIAL

### 12.1 Prinsip Sosial

Sosial memberi, tidak pernah mengambil. Tidak ada pencurian, tidak ada rebutan, tidak ada transaksi player-ke-player.

### 12.2 Bantu Tetangga

| Aturan | Detail |
|--------|--------|
| Batas | Per lahan per hari: 1 Siram + 1 Panen. Per player per hari: max 5 lahan. Reset 05:00 WIB. |
| Hadiah dibantu | Siram: tanaman jadi Basah (ikut peluang Bagus / Prima). Panen: hasil masuk tas pemilik + 1 bibit sejenis bonus. Kualitas tetap milik pemilik. |
| Hadiah pembantu | +40 Koin +10 XP per bantu. Tidak mengurangi barang pembantu. |

### 12.3 Kirim Hadiah (Lv 20)

- 3 hadiah per hari, max 500 Koin per hadiah (barang, bukan Koin mentah).
- Hadiah tidak bisa Legenda, tidak bisa Bunga, tidak bisa Robux.
- Penerima dapat barang, pengirim dapat +20 Koin +5 XP per hadiah (max 3 per hari).

### 12.4 Gestur (Pengganti Emote)

- 4 Gestur ramah: Lambai, Jempol, Tepuk Tangan, Ketawa. Tidak ada hug / joget / tunjuk.
- Gestur bisa dipakai di mana saja, cooldown 3 detik, tidak ada hadiah.

### 12.5 Chat

- Chat per server, filter kata kasar, tidak ada DM antar-player, tidak ada chat pribadi.
- Chat tidak bisa kirim link / kode / gambar.

### 12.6 RW — Hanya Cerita, Bukan Sistem (LOCKED)

- RW **tidak** jadi sistem. Tidak ada struktur RW, tidak ada jabatan, tidak ada target RW, tidak ada hadiah RW.
- RW hanya muncul sebagai **cerita** di Quest NPC (misal: Nek Ani cerita "Dulu RW pernah bikin Kerja Bakti besar"). RW tidak bisa dipilih, tidak bisa di-upgrade, tidak bisa dikelola player.

### 12.7 Visit, Like, Galeri

Lihat Bab 8.7. Like +20 Koin max 10 per hari. Galeri Kampung 5 lahan dengan like mingguan terbanyak.

---

## 13. EVENT BERULANG (Hook Harian)

### 13.1 Gerobak Kaget (Restock 15 Menit)

- Restock tiap 15 menit nyata, 3 slot per restock.
- Slot 1: Bibit Varian (60%), Slot 2: Dekor / Bahan (35%), Slot 3: Hewan Varian / Dekor Langka (5%).
- Max 3 beli per slot per restock. Stok TIDAK habis karena player lain.
- Notifikasi: Toast kecil 1x saat ada Varian: `Gerobak Kaget: ada Semangka Kotak!` (bisa dimatikan di Settings).
- Bibit Varian (rilis 6): Jagung Ungu, Tomat Kuning, Semangka Kotak (tanaman baru, Late 3 jam), Cabai Pelangi, Stroberi Putih, Pisang Merah. Tumbuh seperti biasa, jual +50%, Kualitas tetap Biasa / Bagus / Prima.
- Hewan Varian (rilis 2): Ayam Cemani (hitam), Bebek Belang. Produksi sama, kosmetik + entri Album.

### 13.2 Pasar Malam (Tiap Malam Game, 9 Menit)

- Tiap Malam game (9 menit), Pedagang Tamu datang.
- Pedagang Tamu (rotasi 6 NPC, contoh: Pak Kumis Jamu) membeli 1 jenis barang acak dengan harga +50%, max 10 per player per malam.
- Mini-game opsional: Lempar Gelang (3x gratis per malam, hadiah Koin kecil / bahan / tiket dekor). Tidak pakai Robux.
- Pasar Malam bukan Pasar antar-player. Pasar Malam adalah event NPC.

### 13.3 Event Musiman + Pesanan Tamu

- Kalender rilis: Agustusan (10-24 Agu), Lebaran (mengikuti tanggal), Tahun Baru (28 Des - 7 Jan), Hari Tani (20-30 Sep), Festival Panen (musim panen).
- Hiasan alun-alun saat event dipasang otomatis dari Config (tidak tergantung setoran). Progres event 100% pribadi.
- Pesanan Tamu: Tamu Event minta 3-5 barang, hadiah Koin + Bunga + dekor event.

### 13.4 Kerja Bakti Kilat

| Aturan | Detail |
|--------|--------|
| Pemicu | Setelah Hujan Deres / Petir selesai. |
| Kotoran | 10 + 6 x player di server (max 58 untuk 8 player). |
| Hadiah | 15 Koin + 3 XP per poin, max 20 poin per Kerja Bakti, max 4 Kerja Bakti berhadiah per hari. |
| Bonus Kampung 100% | Semua yang punya ≥1 poin dapat +150 Koin + buff Diskon Warga (bibit, umpan, pakan di Toko Pak Udin -10% selama 1 hari game = 30 menit nyata). |
| Solo | 1 player pun bisa 100% karena target dihitung dari player di server saat itu. |

---

## 14. QUEST

### 14.1 Quest Types

- Main Quest (MQ): 12 quest, linear, cerita Kakek.
- Surat Kakek: 30 surat, 1 per hari login, kumulatif, retensi emosional.
- Side Quest: 10 contoh rilis, bisa diulang? Tidak, sekali saja.
- Agenda Harian: 5 tugas per hari, 150-400 Koin per tugas.
- Order Villager: Daily 3 + Weekly 1, permintaan NPC setor barang, reward x1,5 / x3. Lihat Bab 14.7. Beda dari Agenda.

### 14.2 Main Quest (MQ1-MQ12)

| MQ | Syarat | Hadiah |
|----|--------|--------|
| MQ1 Pulang Kampung | Masuk pertama | 100 Koin + 4 Bibit Kangkung |
| MQ2 Siram Pertama | Siram 1 tanaman | 50 Koin + 20 XP |
| MQ3 Panen Pertama | Panen 1 tanaman (dijamin Bagus) | 100 Koin + 30 XP |
| MQ4 Kolam Kakek (= M3) | Lv 4, Mak Sari datang | Kolam Kakek (Blueprint) |
| MQ5 Bubu Pertama (digabung ke M8) | Lv 8, Bubu | 1 Bubu Bambu |
| MQ6 Kokok Pertama | Lv 5, Pak Udin | Ayam gratis → isi pakan → ambil telur |
| MQ7 Dapur Pertama | Lv 6, Craft Dapur Tier 1 | 1 Tungku |
| MQ8 Jebakan Kak Fajar (= M8) | Lv 8, Bubu | 1 Bubu Bambu |
| MQ9 Warung Pertama (= M7) | Lv 7, Jual 1 olahan di Warung sendiri | 200 Koin + Slot Warung |
| MQ10 Bundel Pertama | Lv 8, Pulihkan 1 Bundel Kakek | 300 Koin + 5 Bunga |
| MQ11 Legenda Pertama | Dapat 1 Ikan Legenda / Panen 1 Prima Late | 500 Koin + Title |
| MQ12 Warga Kampoeng Tedoeh | Selesaikan semua MQ + 50% Album | Title Warga Kampoeng Tedoeh + 10 Bunga |

### 14.3 Surat Kakek (Retensi Emosional)

- 30 surat, 1 per hari login, kumulatif (tidak reset kalau tidak login).
- Surat berisi cerita Kakek + 1 tugas kecil + hadiah Koin / Bunga / bahan.
- Surat #1 contoh: `Nak, kalau hujan, jangan lari. Siram tanamanmu, biar Prima. — Kakek`

### 14.4 Side Quest (Contoh Rilis: 10)

| Side Quest | Pemberi | Syarat | Hadiah |
|------------|---------|--------|--------|
| Kucing Alun-alun | Pak Udin | Kasih makan kucing 3 hari berbeda | Title Penyayang Kucing + pet kucing kampung (kosmetik, gratis) |
| Joran Hilang | Kak Fajar | Cari 3 joran hilang di pinggir air | Joran Kayu + 200 Koin |
| Rumah Rapi | Pak Amran | Pasang 20 piece | Warna dinding spesial |
| Tetangga Baik | Nek Ani | Bantu 10 lahan | 300 Koin + Bubble Cepat ekstra |
| Resep Mak | Mak Sari | Masak 3 resep berbeda | Resep Pepes Ikan Mid |
| Panen Prima | Mak Sari | Panen 5 Kualitas Prima | Gembor (kosmetik) |
| Ikan Jumbo | Kak Fajar | Dapat 1 Ikan Jumbo | 200 Koin + Title |
| Kolektor Album | Nek Ani | Capai 25% Album | 10 Bunga |
| Kerja Bakti 10x | Nek Ani | Ikut 10 Kerja Bakti | 500 Koin + Title |
| Warung Laris | Mak Sari | Jual 10 olahan di Warung sendiri | 300 Koin |

Catatan: Side Quest Embun Pagi lama (Panen 5 Mutasi Embun) DIHAPUS, diganti Panen Prima (Kualitas, bukan Mutasi).

### 14.5 Agenda Harian

- 5 tugas per hari, reset 05:00 WIB. Contoh: Panen 5 tanaman, Mancing 3 ikan, Masak 1 olahan, Bantu 1 lahan, Nambang 10 bahan.
- Hadiah: 150-400 Koin per tugas. Tidak ada Bunga dari Agenda.

### 14.6 Bundel Kakek — Memulihkan Peninggalan Kakek

Bundel adalah proyek Blueprint. Kerangka kosong muncul di level bukanya. Biaya, setoran, dan hadiah sama.

| Bundel | Buka Lv | Ukuran | Setoran | Hadiah |
|--------|---------|--------|---------|--------|
| Sumur Tua | Lv 8 | 4x4 | 10 Kayu + 5 Batu + 2 Olahan | Sumur Tua (dekor, siram 1 petak otomatis per hari) |
| Saung Kakek | Lv 20 | 6x6 | 15 Anyaman + 10 Atap Ijuk + 3 olahan berbeda | Saung (duduk 5 detik → buff Istirahat Sejenak +5% XP 10 menit) |
| Lumbung | Lv 15 | 6x6 | 20 Papan + 10 Bata + 1 hasil Prima | Lumbung (penyimpanan visual) |
| Empang & Dermaga Kakek | Lv 30 | 10x10 | 30 Papan + 10 Semen + 10 ikan Mid + 1 ikan Jumbo apa saja | Spot mancing pribadi |
| Kolam Kakek | Lv 4 | 6x6 | 10 Batu + 5 Kayu + 3 ikan Early | Kolam Tanah gratis, breeding 10% lebih cepat |

- Catatan: Lumbung lama minta 1 hasil Mutasi, diganti 1 hasil Prima (Kualitas, bukan Mutasi).
- Bundel Kakek tidak mengubah total sink (biaya sama). Hadiah lahan bersih 200 Koin dihapus.

### 14.7 Order Villager — Permintaan NPC Setor Barang — LOCKED

- **Beda dari Agenda.** Agenda (Bab 14.5) = tugas sistem (contoh: Panen 5 tanaman, Mancing 3 ikan), tidak perlu setor barang. Order Villager = permintaan NPC spesifik setor barang (contoh: "Bawakan 5 Kangkung Bagus ke Pak Udin", "Bawakan 3 Ikan Mid ke Kak Fajar").
- **Jumlah:** Daily 3 + Weekly 1. Reset 05:00 WIB sama seperti Agenda.
- **Pemberi:** Pak Udin, Kak Fajar, Pak Amran, Mak Sari, Nek Ani (NPC v7.2, bukan nama lama). Order muncul di papan / HUD Order, player ambil lalu setor barang ke NPC yang minta.
- **Reward:** Nilai jual barang yang disetor x1,5 (Daily) / x3 (Weekly). Contoh: Setor barang yang kalau dijual ke Pak Udin 200 Koin, reward Order Daily = 300 Koin, Weekly = 600 Koin. Lebih untung dari jual biasa, karena player setor barang.
- **Hadiah = Koin + XP saja.** Tidak ada Bunga dari Order, sama seperti Agenda. Bunga hanya dari Login / Album / Season / dll (Bab 4.1, Bab 18.2).
- **Reroll:** 2 Bunga per Order, max 1x reroll per Order per hari. Reroll ganti permintaan jadi permintaan acak lain dengan tier yang sama. Tidak bisa reroll gratis.
- **Tidak ada dekor dari Order Weekly.** Weekly hanya reward x3 Koin + XP. Dekor hanya dari Craft / Gerobak / Season / Bundel.
- **Quest tidak gagal karena waktu.** Order yang tidak selesai hari itu hilang saat reset 05:00, tidak ada hukuman. Sama seperti prinsip Bab 1: Quest tidak gagal karena waktu.

---

### 14.8 Starter Quest Chain (Update owner 2026-11-22, Task 1 — USULAN, belum dikerjakan di kode)

Dimulai tepat setelah `t1b_kolam` (jual ikan ke Kak Fajar) selesai. Hadiah sama seperti FTUE lama:

1. Beli Bibit Bayam, lalu tanam 1 Bayam. (Event tanam Bayam belum ada di kode, Lampiran D #23.)
2. Nambang: pukul 1 node Kayu. Hadiah 20 XP.
3. Hias: pasang 1 Pagar Bambu.
4. Buka Surat Kakek #1 (Event buka surat belum ada di kode, Lampiran D #23).
5. Selesai chain: buka Agenda Harian + Gerobak Kaget. Hadiah 100 Koin. Agenda dan Gerobak baru terbuka di langkah ini.

## 15. HADIAH & PROGRESI JANGKA PANJANG

### 15.1 Login Mingguan (Kumulatif, Bukan Streak) — LOCKED

- 7 hari login kumulatif per minggu (tidak reset kalau tidak login di hari lain). **Diulang tiap minggu**: minggu baru mulai Senin 05:00 WIB (Update owner 2026-11-22, Lampiran D #15). Tiap hari WIB yang dibuka saat login = +1 hari; hadiah hari ke-n bisa diambil sekali per minggu. Hadiah: Hari 1: 100 Koin, Hari 2: 150 Koin, Hari 3: 200 Koin, Hari 4: 2 Bunga, Hari 5: 300 Koin, Hari 6: 3 Bunga, Hari 7: 500 Koin + 5 Bunga.

### 15.2 Hadiah Waktu Bermain (Sehat) — LOCKED

- 10 menit: 50 Koin, 20 menit: 100 Koin, 30 menit: 150 Koin, 45 menit: 200 Koin, 60 menit: 300 Koin. Setelah 60 menit tidak ada hadiah tambahan. Hanya Koin, tidak ada Bunga, tidak ada bahan.

### 15.3 Peti Bunga & Pencapaian

- Peti Bunga: dari Login Mingguan, Pencapaian, Album, Season, Event, Bundel Kakek (10 Bunga tiap bangunan pulih), Robux.
- **Isi 1 Peti Bunga = 25 Bunga** (Update owner 2026-11-22, Lampiran D #16). **Sumber peti yang sudah dihubungkan di kode (P2-9):** (1) tiap Title yang dimiliki, sekali per title; (2) tiap Album milestone 25 / 50 / 75 / 100% yang sudah diklaim, sekali per milestone; (3) Season F2P hari 30, sekali per season. **Belum dihubungkan:** Login, Pencapaian, Event (belum ada definisi "completion" di kode, Lampiran D #21), Bundel Kakek, Robux.
- Pencapaian: Album, Quest, Kerja Bakti, Koleksi, dll. Hadiah Bunga + Title.

### 15.4 Title (Dari Pencapaian Permanen) — LOCKED

- Title dari pencapaian permanen, bukan dari beli. Contoh: Kolektor (Album 50%), Warga Kampoeng Tedoeh (MQ12), Penyayang Kucing (Side Quest Kucing), Legenda Kampung (Album 100%).
- Title tidak memberi stat, kecuali yang tercantum di Bab 17.6 (max +25% per jenis stat, termasuk Title).
- **Syarat tiap Title (diambil dari kode, Update owner 2026-11-22; Lampiran D #17 + #22):**
  - Kolektor: Album 50%, lalu klaim milestone `p50` (Config/Book).
  - Legenda Kampung: Album 100%, lalu klaim milestone `p100` (Config/Book).
  - Warga Kampoeng Tedoeh: quest MQ12 `mq12_warga` (MQ11 selesai + Album 50%).
  - Penakluk Legenda: quest MQ11 `mq11_legenda` (1 ikan Legenda + 1 Panen Prima Late).
  - Dinding Spesial: quest `side_rumah_rapi` (pasang 20 piece dekor).
  - Raja Jumbo: quest `side_jumbo` (1 ikan Jumbo).
  - Pekerja Bakti: quest `side_kerjabakti` (ikut 10 Kerja Bakti).
  - Juragan Pondok: kategori Album rumah lengkap, lalu klaim (Config/Book CATEGORY_REWARDS).
  - Kebun Favorit: 200 like (Config/Social LIKE_MILESTONES).
  - Warga Teladan: TIDAK ADA sumber di kode, tidak masuk daftar (Lampiran D #22).
  - Setiap title yang dimiliki memberi 1 Peti Bunga, sekali per title. Title tetap tanpa stat.

---

## 16. TUTORIAL & FTUE

> **P2-8 Doc Fix (v7.4) — BUKAN FTUE baru.** FTUE lama dipertahankan persis seperti yang sudah jalan di game (cutscene + coachmark yang sudah works di commit sebelum P2-8). Yang diubah hanya 4 hal di bawah, tidak ada rebuild FTUE, tidak ada naskah baru. Kalau ada yang tidak disebut di sini, FTUE lama yang berlaku.

### 16.1 FTUE Rules (LOCKED)

- FTUE adalah state machine berbasis kondisi game. Langkah selesai saat kondisinya terpenuhi, atau saat kondisi langkah SESUDAHNYA terpenuhi (panen menyelesaikan Siram). Siram opsional: menyiram ATAU panen.
- **FTUE lama dipertahankan.** Alur, dialog, cutscene, coachmark, dan urutan langkah yang sudah ada di game tidak diganti. Dokumen ini hanya menyesuaikan alur lama ke dokumen terbaru (hapus Kolam, tambah blok NPC, tambah cutscene jual pertama).
- **No-skip (LOCKED, keputusan final).** Tidak ada tombol `Lewati`, `Lewati langkah`, `Lewati panduan`, `Lewati dialog`, atau skip cutscene / coachmark / dialog tutorial. FTUE / coachmark / cutscene / dialog tutorial tidak bisa di-skip sama sekali. P2-8 hanya menghapus tombol Lewati, bukan membangun ulang FTUE.
- Cutscene + Coachmark: satu aturan saja. Cutscene dan coachmark tidak bisa di-skip.

### 16.2 FTUE Steps (10 Menit) — Alur Lama, Disesuaikan ke Dokumen Terbaru

| Waktu | Langkah | Hadiah | Catatan P2-8 |
|-------|---------|--------|--------------|
| 0:00 | Masuk pertama, Mak Sari datang, dialog Kakek | - | FTUE lama. Mak Sari = narator + target langkah ini saja. NPC lain diblok (Bab 16.3). |
| 0:30 | Tanam Kangkung (4 Bibit gratis) | - | FTUE lama. |
| 0:50 | Panen pertama (dijamin Bagus) | 20 XP | FTUE lama. |
| 1:30 | Siram / Panen (opsional) | 20 XP | FTUE lama. |
| 2:00 | Mancing: Kak Fajar kasih Joran Bambu. Lempar → gigitan (dijamin) → tarik (ikan Early pelan) → Wader Cakul. Kartu `IKAN BARU!` | 20 XP | FTUE lama. Mancing di **sungai lahan** terdekat dari lahanmu (bukan dermaga Kanal; Update owner 2026-11-22, Task 1). Lihat Bab 16.5. |
| 3:00 | Jual hasil panen pertama ke Pak Udin — **via cutscene proximity (BARU)** | 20 XP | **Bukan interaksi bebas.** Mendekati Pak Udin = trigger cutscene jual pertama (Bab 16.4). Cutscene buka GUI Jual yang sama seperti biasa. |




| 3:30+ | **Akhir FTUE = jual ikan ke Kak Fajar (`jual_ikan`).** Langkah lama (Bayam, Nambang, Hias, Surat #1, Agenda + Gerobak) jadi Starter Quest Chain (Bab 14.8). | 100 Koin di akhir chain | Update owner 2026-11-22 (Task 1). |

- Joran Bambu ikut tampil di Tas. Tombol Mancing muncul saat dekat **dermaga** setelah Joran Bambu diberikan. **Selama Tutorial 1, tombol Mancing TIDAK muncul di kolam** karena Kolam belum ada di Tutorial 1.
- Ikon Tas per kategori. Label harga Pak Udin diambil dari config (100%), bukan teks tetap 90%.
- Garap: kotak yang dicek hanya terrain. Tap ke kotak tidak valid pindah ke kotak valid terdekat.
- **Tidak ada langkah Kolam di FTUE.** Lihat Bab 16.5.

### 16.3 Blok NPC Selama Tutorial 1 (LOCKED — BARU, P2-8)

- **Kapan aktif:** Dari Masuk pertama (0:00) sampai FTUE selesai (10:00). Setelah FTUE selesai, blok dibuka dan interaksi NPC normal (Bab 10).
- **Aturan:** Selama Tutorial 1, player **tidak bisa interaksi bebas dengan NPC**.
- **Yang diblok:** Toko / Beli / Jual bebas, dialog bebas, Quest, Order Villager, Kirim Hadiah, Bantu, dan semua GUI NPC — kecuali NPC yang jadi target langkah FTUE yang sedang berjalan, dan hanya lewat cara langkah itu (dialog FTUE / cutscene jual pertama).
- **Cara blok:** ProximityPrompt / tombol interaksi NPC di luar langkah aktif disembunyikan / nonaktif. Player yang mencoba mendekat / klik NPC di luar langkah aktif tidak membuka toko / dialog / GUI apa pun.
- **Jawaban NPC yang diblok (LOCKED, satu kalimat saja):** NPC menampilkan bubble / dialog singkat:
  > `Selesaikan tutorial dulu`
  Tidak ada dialog lain, tidak ada toko, tidak ada quest. Setelah bubble itu hilang, player kembali ke langkah FTUE yang sedang berjalan (coachmark / panah tetap menunjuk target langkah aktif).
- **Pengecualian:** Mak Sari di langkah 0:00, Kak Fajar di langkah Mancing (2:00), dan Pak Udin di langkah Jual Pertama (3:00, via cutscene Bab 16.4) adalah target langkah — mereka tidak diblok saat langkahnya aktif. Di luar langkahnya, mereka ikut diblok dengan kalimat yang sama.
- **Tidak ada pengecualian lain.** Nek Ani, Pak Amran, Bang Jali, Pedagang Tamu, Tamu Event — semuanya diblok selama Tutorial 1 dengan kalimat yang sama.

### 16.4 Cutscene Jual Pertama — Proximity-Triggered (LOCKED — BARU, P2-8)

> Ini adalah **edit** dari langkah Jual yang sudah ada di FTUE lama, bukan cutscene / FTUE baru. Tidak ada naskah baru yang dibuat di dokumen ini. Dialog cutscene memakai dialog jual Pak Udin yang sudah ada di game.

- **Trigger:** Proximity, bukan klik / ProximityPrompt. Saat player yang sedang di langkah Jual Pertama (3:00) mendekati Pak Udin sampai jarak trigger (jarak dekat NPC, sama seperti jarak interaksi NPC normal), cutscene jual pertama langsung mulai. Player tidak perlu klik NPC.
- **Alur cutscene:**
  1. Player mendekati Pak Udin → cutscene mulai, kontrol player dikunci, kamera ke Pak Udin.
  2. NPC ngobrol (dialog jual Pak Udin yang sudah ada di game — tidak ada naskah baru).
  3. **GUI Jual tetap dibuka.** Cutscene tidak menggantikan GUI Jual. GUI Jual yang dibuka adalah GUI Jual Pak Udin yang sama seperti jual biasa (bukan GUI baru).
  4. Player jual hasil panen pertama lewat GUI Jual itu (jual seperti biasa).
  5. GUI Jual ditutup → cutscene ditutup → kontrol player balik → langkah Jual selesai (20 XP) → FTUE lanjut ke langkah berikutnya (Beli Bibit Bayam).
- **Yang TIDAK boleh:** Cutscene tidak boleh jual otomatis tanpa GUI. Player harus tetap jual lewat GUI. Cutscene tidak boleh menambah / mengubah harga (tetap 100% Pak Udin, Bab 10.2). Cutscene tidak bisa di-skip (Bab 16.1).
- **Jika player menjauh sebelum trigger:** Tidak ada cutscene, tidak ada jual. Coachmark / panah tetap menunjuk Pak Udin sampai player mendekat.
- **Jika player mendekati Pak Udin di luar langkah Jual Pertama** (misal masih di langkah Tanam / Mancing): Berlaku blok Bab 16.3 — NPC jawab `Selesaikan tutorial dulu`, tidak ada cutscene, tidak ada GUI Jual.

### 16.5 Kolam — Bukan di Tutorial 1 (LOCKED — P2-8 Takeout)

- **Update owner 2026-11-22 (Lampiran D #13):** di luar Tutorial 1, kolam bisa dibangun mulai **Lv 4** (`Fishing.POND.UNLOCK_LEVEL`, keputusan owner, Lampiran D #30). Langkah "bangun kolam" di Quest Kolam (Bab 14.1) ikut terbuka di Lv 4. Kolam Kakek (Lv 4, M3 / Bundel) tetap ada dan tetap memberi kolam gratis + breeding 10% lebih cepat. Bagian di bawah ini tentang Tutorial 1 tetap berlaku.

- **Kolam DIHAPUS dari Tutorial 1 / FTUE.** Tidak ada langkah Buat Kolam, tidak ada langkah Simpan Ikan ke Kolam, tidak ada coachmark Kolam, tidak ada prompt Kolam, tidak ada tombol Kolam, tidak ada dialog Kolam di FTUE.
- **Alasan:** Di dokumen terbaru, Kolam dibuat nanti. Kolam pertama = **Kolam Kakek** (Bab 7.2, Bab 14.2 MQ4, Bab 14.6 Bundel Kakek): **Lv 4, Mak Sari datang, setoran 10 Batu + 5 Kayu + 3 ikan Early**. Kolam Tanah yang bisa dibeli juga **Lv 4** (Bab 4.4, Quest v0.3 Bab 6). FTUE (Lv 1, 10 menit) tidak boleh mengajarkan Kolam.
- **Mancing di FTUE:** di sungai lahan terdekat dari lahanmu (`sungai_lahan`, Early Lv 1). Bukan di kolam. Kanal barat (Lv 5) dan kanal timur (Lv 10) tidak dipakai di FTUE. Kalimat lama `Tombol Mancing muncul saat dekat dermaga atau kolam` **tidak berlaku** selama Tutorial 1.
- **Setelah FTUE:** Kolam baru dikenalkan lewat M3 / Bundel Kakek (Lv 4), bukan lewat FTUE. Tutorial Kolam (jika ada) adalah tutorial MQ4, bukan Tutorial 1.
- **Yang harus dihapus dari FTUE lama:** Semua referensi Kolam di langkah FTUE, coachmark ke Kolam, dan prompt / GUI Kolam yang muncul selama Tutorial 1. Kode / sistem Kolam di luar FTUE (Bab 7.2, MQ4, Bundel) tidak dihapus — hanya takeout dari FTUE.

---

### 16.6 Tutorial dan NPC Sisi Klien (Update owner 2026-11-22, Task 1 — BELUM DIKERJAKAN)

- Tutorial (Kak Fajar pemancing, NPC tutorial, dialog, bubble, cutscene, panah) sepenuhnya di sisi klien dan hanya untuk pemain itu.
- Kak Fajar tutorial = NPC klien yang muncul di sungai lahan terdekat dari lahan pemain. Kak Fajar server disembunyikan untuk pemain itu saja.
- Aturan global: bicara dengan NPC (dialog, bubble) dan NPC menoleh/menghadap pemain = sisi klien, hanya untuk pemain itu.
- Aksi pemain (jalan, lempar, joran, pelampung, tangkapan) tetap direplikasi.
- Server tetap pegang hadiah dan ekonomi: jual ikan ke Kak Fajar tutorial hanya diterima bila langkah = `jual_ikan` dan pemain dekat sungai lahan miliknya (posisi dihitung di server dari plot pemain, bukan dari posisi klien).
- Lampiran D #23 mencatat apa yang belum dikerjakan.

## 17. EKONOMI

### 17.1 Prinsip

1. Semua angka di Config (`Config/Economy`), bukan hardcode.
2. Penghasilan dihitung **bersih** (sudah dikurangi bibit, umpan, pakan).
3. Konten rilis ~71-72% selesai saat Level Cap 60. Sisa 27% + konten Update 1 menjembatani ke Lv 80.
4. Tidak ada cara Robux → Koin (langsung maupun tidak langsung).

### 17.2 Faucet (Sumber Koin) per Jam, Player Inti — Simulasi Full-Unlock

> Perbedaan dari v6: v6 faucet per fase (Lv 1-20 2.000/jam, Lv 21-45 6.000/jam, Lv 46-60 12.000/jam). Di v7.2, angka yang sama dihitung sebagai **simulasi full-unlock** (saat semua gameplay kebuka), bukan per fase. Angka totalnya sama, interpretasinya yang berubah.

| Fase (untuk referensi) | Nanem | Mancing | Ternak + Kolam + Bubu | Olahan + Warung | Agenda/Sosial/Event | Total Bersih / Jam |
|------------------------|-------|---------|------------------------|-----------------|----------------------|--------------------|
| Lv 1-20 | 700 | 600 | 150 | 100 | 450 | **2.000** |
| Lv 21-45 | 1.800 | 1.400 | 900 | 1.100 | 800 | **6.000** |
| Lv 46-60 (Full-Unlock) | 3.300 | 2.600 | 2.000 | 3.000 | 1.100 | **12.000** |

Total Koin bersih sampai Lv 60 ≈ 14 jam x 2.000 + 29 x 6.000 + 20 x 12.000 ≈ **442.000 Koin**.

Dengan Kualitas (+10% / +25%) dan Mood Hujan (5 menit +10%):
- Nanem: 3.300 x 1,055 = 3.482 (+182)
- Olahan: 3.000 x 1,05 = 3.150 (+150, dari Kualitas Olahan, tidak double-count dengan Nanem)
- Ternak: 2.000 x 1,0345 = 2.069 (+69, dari Mood Hujan 5 menit)
- Total Full-Unlock baru: ~12.400 (naik ~3,3% dari 12.000). Sink 442k → ~455k, 71% → ~73%. Masih di dalam validasi 65-80%. Lihat Lampiran C.

### 17.3 Pembagian Waktu (Agar Semua Sistem Dipakai)

Target porsi Koin player inti: Nanem 30% | Mancing 25% | Ternak+Kolam+Bubu 15% | Olahan 15% | Agenda/Sosial/Event 15%. Kalau playtest menunjukkan 1 sistem >40%, turunkan sistem itu, jangan naikkan yang lain.

### 17.4 Sink (Biaya Menyelesaikan Konten Rilis)

| Sink | Total Koin | Rincian |
|------|-----------|---------|
| Petak 7-36 | 96.750 | `n x 150` |
| Beli chunk lahan (14 chunk, Bab 3.1) | 88.790 | `1.500 x 1,2^n` untuk n = 0..13, dibulatkan 10 |
| Joran | 66.400 | Bab 6.3 |
| Alat Bertani | 15.800 | Bab 17.5 |
| Alat Tukang | 13.000 | Bab 17.5 |
| Kandang + upgrade | 24.000 | Bab 7.1 |
| Hewan (max slot) | 21.800 | 10 Ayam + 8 Bebek + 4 Sapi |
| Kolam (4, sampai Keramik) | 39.000 | 3 Kolam Tanah baru + 4 upgrade Semen + 4 upgrade Keramik |
| Bubu (3 sampai Besi) | 17.700 | Bab 6.6 |
| Skill (16 x 15.000, semua max) | 240.000 | Skill Tree Bab 1 dan 4 |
| **Total** | **~623.000** | |

**Angka skill untuk dua keadaan (Skill Tree Bab 4):** semua skill max = **240.000 Koin** (80 SP, tercapai Lv 81). Sampai **Lv 60** (59 SP) skill paling banyak menyerap **177.000 Koin**, jadi sink efektif Lv 60 ≈ 623.000 − 240.000 + 177.000 = **560.000**. **Faucet Lv 60 ≈ 442.000 → 442.000 / 560.000 ≈ 79%.** Dengan Kualitas + Mood Hujan, ~455.000 / 560.000 ≈ **81%**. Validasi 65-80% (Bab 17.8) mepet batas atas, lihat Bab 17.8. Sink kecil berulang (Gerobak Kaget, Garam, pakan ekstra) tidak dihitung, berfungsi sebagai rem inflasi.

### 17.5 Alat Koin (Versi F2P dari Alat Bunga)

> "Bertani Lv N", "Tukang Lv N" di tabel ini berarti **Player Lv N** (Skill Tree Bab 5), bukan level skill.

| Alat | Harga | Syarat | Efek |
|------|-------|--------|------|
| Gembor Plastik | Gratis | - | Siram 1 petak |
| Gembor Seng | 2.000 Koin + 10 Kayu | Bertani Lv 3 | Siram 2 petak (garis) |
| Gembor Kuningan | 8.000 Koin + 20 Papan | Bertani Lv 8 | Siram 3 petak (garis) |
| Sabit Kayu | Gratis | - | Panen 1 petak |
| Sabit Besi | 5.000 Koin + 10 Batu | Bertani Lv 5 | Panen 3 petak (garis) |
| Sepatu Bot | 800 Koin + 5 Ijuk | Bertani Lv 2 | Jalan +5% di lahan sendiri |
| Kapak Batu | Gratis | - | Normal |
| Kapak Besi | 3.000 Koin + 15 Batu | Tukang Lv 3 | +1 bahan per node |
| Kapak Baja | 10.000 Koin + 20 Batu + 10 Semen | Tukang Lv 7 | +2 bahan per node |

### 17.6 Cap Bonus (LOCKED)

- Bonus dari **Dekor Berkah + Dekor Bunga + Set + Title** dijumlah per jenis stat (contoh: `Koin Nanem`), dan dikunci **max +25%**.
- Skill cabang di luar cap (max +10% per jenis).
- Panel Stats menampilkan `Koin Nanem +25% (MAX)` dengan warna emas jika mentok. Tidak ada popup.
- Contoh max teoretis: Koin Nanem = 25% (dekor/set/title) + 10% (skill Panen Raya) = +35%. Sudah dihitung dalam faucet fase akhir.

### 17.7 Harga Lain

- Pasar Harian: +30%, 2 barang, semua penjual.
- Super DIHAPUS: tidak ada pengali Koin / XP.
- Kualitas: Bagus +10%, Prima +25% (bukan Mutasi x1,5 / x3 / x5 / x10). Kualitas: Durian Prima = 1.300 x 1,25 = 1.625 Koin (Super dihapus, Update owner 2026-11-22).
- Agenda: 150-400 Koin per tugas.

### 17.8 Validasi Ekonomi (Wajib Saat Playtest)

| Cek | Target | Kalau Meleset |
|-----|--------|---------------|
| Jam ke Lv 60 (player inti) | 55-70 jam | Ubah XP aksi, jangan ubah rumus level |
| % sink selesai di Lv 60 | 65-80% | Ubah harga Skill dulu (sink terbesar) |
| Porsi Koin 1 sistem | ≤ 40% | Turunkan sistem dominan |
| Koin mengendap (median saldo player Lv 60) | ≤ 50.000 | Tambah sink kosmetik Koin di Update |
| Kualitas Prima per player per minggu | Dihitung dari chance Bab 5.4 (Lampiran C), diukur di playtest | Ubah chance di Config/Kualitas, bukan target |

---

## 18. MONETISASI

### 18.1 Prinsip Monetisasi

- Bunga = kenyamanan & gaya, bukan kekuatan. Tidak ada Robux → Koin.
- Semua konten bisa dicapai F2P. Premium Roblox tidak memberi pengali Koin apa pun (termasuk hadiah pesanan).
- **Tidak ada Backpack Pass. Tas tanpa cap slot.** Tas pakai stack (contoh: Daun Pisang stack 99). Tidak ada Tas yang terkunci di balik Pass.

### 18.2 Sumber Bunga F2P

| Sumber | Bunga / Bulan (Bulan 2+) |
|--------|--------------------------|
| Login Mingguan | 40 (10 Bunga per minggu, Bab 15.1; Update owner 2026-11-22) |
| Pencapaian | 40 |
| Album | 30 |
| Season (F2P track) | 30 |
| Event | 30 |
| Bundel Kakek | 10 |
| Peti Bunga | 60 (2-3 peti per bulan, 1 peti = 25 Bunga; sumber lihat Bab 15.3) |
| **Total** | **~240** |

### 18.3 Alat Bunga (QoL, Bukan Kekuatan)

- Gembor Bunga: Siram 5 petak (garis), 100 Bunga.
- Sabit Bunga: Panen 5 petak (garis), 100 Bunga.
- Kapak Bunga: +1 bahan per node, 100 Bunga. Ini **alternatif Kapak Besi** (bayar Bunga, bukan Koin), bukan tier di atas Kapak Baja. Hanya kapak terbaik yang dihitung, tidak ditumpuk dengan kapak lain dan tidak ditumpuk dengan Tukang Cepat selain lewat batas +4 per node (Skill Tree Bab 6 keputusan 2).
- Dekor Bunga: Dekor Berkah dengan 2 stat, 50-150 Bunga per piece.

### 18.4 Robux

- Pack Bunga: 50 Bunga (Rp 15.000), 120 Bunga (Rp 30.000), 300 Bunga (Rp 60.000), 700 Bunga (Rp 120.000).
- Season Premium: 150 Bunga / season.
- Tidak ada Robux → Koin. Tidak ada loot box. Tidak ada iklan.

### 18.5 Instant & Skip

- Kolam bisa di-instant Bunga (1 Bunga per 10 menit sisa, max 30 Bunga).
- Bubu TIDAK bisa di-instant Bunga.
- Tidak ada instant panen / instant olahan pakai Bunga.

---

## 19. SEASON PASS — "Musim Panen"

- Season 30 hari. 2 track: F2P (gratis) dan Premium (150 Bunga).
- F2P track: Koin, bahan, Bunga (30 Bunga), dekor.
- Premium track: semua F2P + kosmetik eksklusif season (tidak akan dijual lagi), Bunga ekstra, dekor eksklusif.
- Season Premium tetap laku walau Bunga-nya < Pesta Bunga: kosmetik eksklusif season tidak akan dijual lagi (satu-satunya barang terbatas di game, dan itu kosmetik).
- Istilah Season Premium dipakai untuk paket Season, supaya tidak bentrok dengan Premium Roblox.
- **Aturan P2-9 (usulan, Lampiran D #18):** Season 1 mulai 1 Desember 2026 (WIB, reset 05:00). Setelah 30 hari, season berikutnya mulai otomatis dengan hadiah yang sama. Hari yang sudah lewat bisa diambil sekali; hari yang belum tiba belum bisa diambil.
- **F2P (gratis):** hadiah tiap 5 hari (hari 5, 10, 15, 20, 25, 30), USULAN (Update owner 2026-11-22; Lampiran D #20): hari 5 = 10 Bambu; hari 10 = 5 Bunga + 10 Kayu; hari 15 = 5 Batu; hari 20 = 10 Bunga + 5 Ijuk; hari 25 = 15 Bambu + 10 Kayu; hari 30 = 15 Bunga + 2 Atap Ijuk + 1 Dekor Rumpun Bambu + 1 Peti Bunga. Total Bunga F2P = 30. Bahan dan dekor di atas memakai id item yang sudah ada di kode.
- **Premium: SEGERA HADIR (Update owner 2026-11-22).** Belum bisa dibeli sampai kosmetik eksklusif season ada (`Rewards.SEASON.PREMIUM_OPEN = false`). Angka Premium di kode (40 Koin per hari, Bunga ekstra 60) masih usulan.

---

## 20. EXPERIENCE — Game Feel, Suara, Haptic

- Game Feel: Panen Prima = partikel emas lembut + suara `pop` + haptic kecil. Legenda = fanfare kecil + banner.
- Suara: Ayam berkokok Pagi, jangkrik Sore, kunang-kunang Malam, tik-tik Gerimis, gemuruh Deres, petir jauh Petir.
- Haptic: Panen, Critical Nambang, Tarik sukses, Legenda. Bisa dimatikan di Settings.
- Tidak ada suara keras / jumpscare. Semua suara cozy.

---

## 21. EFFECTS

- Panen Biasa: partikel daun kecil. Panen Bagus: kilau lembut. Panen Prima: partikel emas lembut.
- Hujan: Partikel 30 (Gerimis), 60 (Deres), 90 + kilat (Petir). Tidak ada salju.
- Mancing: Gelembung emas saat Firasat (pity ≥75%).
- Kerja Bakti: Kotoran visual di Alun-alun, hilang saat dibersihkan.
- Banner: Legenda + Prima Late + Pelangi (tidak ada Pelangi, jadi hanya Legenda + Prima Late).

---

## 22. ANIMASI

- Player: Jalan, lari, duduk, tanam, siram, panen, mancing (lempar, tarik), nambang (pukul), masak (aduk), hias (pasang), gestur (Lambai, Jempol, Tepuk, Ketawa).
- Hewan: Ayam jalan + patuk, Bebek jalan + quack, Sapi jalan + makan rumput. Idle lucu saat pakan habis.
- Ikan: Berenang di Kolam, di Akuarium, di air saat mancing (bayangan).
- NPC: Pak Udin sapu, Kak Fajar mancing, Mak Sari masak, Nek Ani duduk di Pos Ronda, Bang Jali berdiri.

---

## 23. GUI

- HUD: Koin, Bunga, Level, XP bar, Ikon Fase (Pagi / Siang / Sore / Malam), Ikon Cuaca (Terik / Hujan + tanda 10 detik), Tombol Tas, Tombol Menu, Tombol Mancing (saat dekat spot).
- Tas: Kategori (Tanaman / Ikan / Olahan / Bahan / Lainnya), filter, tooltip dengan Kualitas (Biasa / Bagus / Prima).
- Album: GUI (Bab 11), tab Ladang / Sungai / Dapur / Varian + Kandang / Rumah terpisah.
- Warung: GUI pajang 1 olahan, lihat pengunjung, ambil Koin.
- Dapur: GUI Slot 1 / 2 / 3, pilih resep, lihat waktu, ambil olahan.
- Settings: Mode Bantu (OFF), Suara, Haptic, Notifikasi Gerobak Kaget (ON), Bahasa.
- Tidak ada GUI Papan Pamer. Tidak ada GUI Rak Pajangan. Tidak ada GUI Ramalan Cuaca. Tidak ada GUI RW.
- **v7.5 (kode):** Font semua GUI = FredokaOne. Quest tracker tanpa panel (teks krem + outline gelap). Panel reel mancing kecil (260×108) dengan bingkai bambu Loading. Tombol Mancing bulat dengan ikon joran. Tombol Craft muncul hanya dekat Meja Crafting (Lv 4+). Detail dan status di Bab 0.3.2 dan Lampiran D.

---

## 24. PERFORMA — HP 4GB

- Target: RAM 4GB, Helio G99 / Unisoc T7250. StreamingEnabled ON.
- Cap: Max 8 player per server, max 800 piece hias per lahan, max 36 petak, max 4 kolam, max 3 bubu, max 10 hewan per kandang.
- Render: Bangunan Alun-alun selalu render, lahan lain render saat dekat.
- Playtest: 8 player di server, semua mancing + hujan + Kerja Bakti, FPS ≥ 30 di HP 4GB.

---

## 25. KPI & ANALYTICS

### 25.1 KPI

| KPI | Target |
|-----|--------|
| Retensi D1 / D7 / D30 | 35% / 15% / 6% |
| Konversi bayar | 3% |
| Sesi rata-rata | 20-40 menit |
| Jam ke Lv 60 (inti) | 55-70 jam |

### 25.2 Event Analytics (Wajib Log)

Plant, Water, Harvest (Kualitas), Cast, Bite, PullSuccess, Fish (Tier, Size), Feed, Collect, Cook (Recipe, Kualitas), WarungSale, Bantu, KerjaBakti, Quest, Surat, Album, Login, Playtime, GerobakKaget, PasarMalam.

---

## 26. LIVEOPS

- Update Besar tiap 2 bulan: +20 Level Cap (Lv 80 bulan ke-2, Lv 100 bulan ke-4), +20 piece hias, +3 resep, +2 ikan, +1 tanaman, +1 hewan (wol di Update 1).
- Event Musiman: Agustusan, Lebaran, Tahun Baru, Hari Tani, Festival Panen. Progres 100% pribadi.
- Season: Musim Panen 30 hari, 2 track.
- Tidak ada sistem global yang butuh banyak player. Semua LiveOps bisa selesai solo.

---

## 27. SATU CORE LOOP — Tanpa Fase, Tanpa Timeline (Untuk Claude Code)

> Semua gameplay adalah SATU CORE LOOP. Tidak ada MVP, tidak ada Fase 0-7, tidak ada timeline. Semua sistem dibangun sebagai satu core loop.

Core Loop: **Tanam → Panen (Kualitas) → Olah di Dapur (Kualitas Olahan) → Jual di Warung sendiri / NPC → Dapat Koin + XP → Beli petak / chunk / alat / skill / hias → Tanam lagi yang lebih baik.**

Semua sistem (Nanem, Mancing, Ternak, Nambang, Dapur, Warung, Hias, Sosial, Quest, Event) adalah bagian dari core loop ini, bukan fase terpisah.

---

## 28. STRUKTUR DATA

PlayerData: Level, XP, SP, Koin, Bunga, Tas (items + kualitas), Lahan (Petak, Chunk, Bangunan, Warung), Mancing (Pity per Legenda, Bubu), Ternak (Kandang, Pakan, Kolam), Dapur (Tier, Slot), Album (214 entri GUI), Quest (MQ, Surat, Side, Agenda), Sosial (Bantu, Hadiah, Like), Settings.

- `PlayerData.version` = 72. Tanpa kode migrasi: save lama direset (game belum rilis).
- Setiap angka hanya didefinisikan di 1 Config. Lihat Bab 1 Prinsip #15.

---

## 29. LARANGAN KERAS — Build Gagal Jika Dilanggar

- Tidak ada Mutasi, Pelangi, Greenhouse, Rak Pajangan, Papan Pamer, RW sebagai sistem, Pasar antar-player, Ramalan Cuaca, Antrean Dapur, Reputasi Warung, Kasih Minum Ternak, Pupuk, Hama, Stamina, Fail, Loot Box, Iklan, Robux → Koin, Premium → Koin, Bunga → Koin / XP / Level / Bahan Mentah / Hewan, Streak Reset, Hadiah >60 Menit, Salju, Daging, Hewan Mati, Tanaman Mati, Bangunan Roboh, Quest Gagal karena Waktu, Nama NPC Lama (Bu Wati, Mbak Arsi, Bang Tarno, Pak RT, Bu Sari, Mbah Karto, Mas Yudi, Dik Rara), Gestur Joget / Tunjuk / Hug, Jual Legenda di Warung / Hadiah, Masak Legenda, Instant Bubu pakai Bunga, Bunga dari Level-Up, Bunga dari Like, **Bibit Unggul (+10% tumbuh, x1,5 harga), Backpack Pass (+40 slot), Blueprint gating (dekor terkunci di balik beli Blueprint), Buff Pasif (buff untuk Ternak / Kolam / Dapur / Bubu / Warung).**
- Jika ada yang melanggar, build gagal.

---

## 30. PLAYTEST CHECKLIST

### 30.1 FTUE & Tutorial (WAJIB)

- [ ] FTUE selesai dalam 10 menit, tidak macet.
- [ ] FTUE lama dipertahankan — tidak ada FTUE baru, tidak ada naskah baru.
- [ ] No-skip: tidak ada tombol Lewati / Lewati langkah / Lewati panduan / Lewati dialog / skip cutscene / skip coachmark.
- [ ] Panen pertama dijamin Bagus.
- [ ] Joran Bambu tampil di Tas, tombol Mancing muncul di dermaga (bukan kolam) selama Tutorial 1.
- [ ] Tidak ada langkah / coachmark / prompt / tombol Kolam di Tutorial 1. Kolam pertama hanya lewat MQ4 / Bundel Kakek Lv 3.
- [ ] Selama Tutorial 1, NPC di luar langkah aktif diblok — ProximityPrompt nonaktif, NPC jawab `Selesaikan tutorial dulu`, tidak ada toko / dialog / GUI.
- [ ] Jual pertama: mendekati Pak Udin langsung trigger cutscene, NPC ngobrol, GUI Jual Pak Udin yang sama tetap dibuka, player jual lewat GUI, baru cutscene tutup.

### 30.2 Core Loop (WAJIB)

- [ ] Tanam → Panen (Kualitas Biasa / Bagus / Prima) → Olah → Jual → Beli → Tanam lagi bekerja.
- [ ] Kualitas beda stack, tidak tercampur.
- [ ] Warung jual olahan ke NPC pengunjung, max 5 offline per login.
- [ ] Kualitas Olahan dari Kualitas bahan, bukan Mutasi.

### 30.3 Cuaca & Waktu (WAJIB)

- [ ] Hujan 3 menit, tanda 10 detik, tidak ada ramalan.
- [ ] Hujan siram otomatis 1x, tumbuh 2x hanya tanaman luar, gigitan 2x, Mood Hujan 5 menit +10%.
- [ ] Kerja Bakti setelah Deres / Petir.
- [ ] Tidak ada Pelangi, tidak ada Greenhouse.

### 30.4 Sosial & Ekonomi Antar-Player (WAJIB)

- [ ] Bantu Siram + Panen bekerja, hadiah pembantu +40 Koin +10 XP.
- [ ] Tidak ada Papan Pamer, tidak ada Rak Pajangan, tidak ada RW sistem, tidak ada Pasar antar-player.
- [ ] Warung tidak ada Reputasi, tidak ada transaksi player-ke-player.

### 30.5 Monetisasi (WAJIB)

- [ ] Bunga tidak bisa beli Koin / XP / Level / Bahan Mentah / Hewan.
- [ ] Tidak ada Robux → Koin, tidak ada loot box, tidak ada iklan.
- [ ] Premium Roblox tidak memberi pengali Koin.

### 30.6 Performa & GUI (WAJIB)

- [ ] 8 player, hujan + Kerja Bakti, FPS ≥ 30 di HP 4GB.
- [ ] Album GUI 214 entri, Bingkai Album menampilkan % Album.
- [ ] Tas menampilkan Kualitas (Biasa / Bagus / Prima).

### 30.7 Animasi Tanam & Memancing (B-5, belum diuji di Studio)

- [ ] Animasi tanam (FarmPlant) dan siram (FarmWater) diputar saat menanam dan menyiram.
- [ ] Animasi joran diputar saat lempar (FishingCast), menunggu (FishingIdle), tarik (FishingReel), dan dapat ikan (FishingCatch).
- [ ] Dengan dua akun: pemain kedua melihat joran dan animasi memancing pemain pertama.

---

## Penutup — Pesan untuk Muse / Claude Code

Dokumen ini adalah Single Source of Truth v7.3. Ikuti angka di sini, jangan ngarang angka baru. Kalau ada yang tidak ada di dokumen ini, tanya owner, jangan isi sendiri. Yang tidak dibahas = LOCKED. Format dokumen ini adalah v6.2.3, bukan format template. Jangan pakai format file829. Jangan bahas map — map sudah ada di Roblox Studio. Perhatikan Bab 9.4 (Buff Olahan) dan Bab 14.7 (Order Villager) yang baru di v7.3, dan larangan baru di Bab 29 (Bibit Unggul, Backpack Pass, Blueprint gating, Buff Pasif).

---

## Lampiran A — Status dokumen lain (bukan sumber aturan)

- `00_Design_Doc.md` (v0.3) — digantikan, bukan sumber aturan.
- `Audit_v6.1.md` — digantikan, bukan sumber aturan.
- `Roadmap.md`, `TODO.md` — catatan status, tidak boleh mengubah angka di sini.
- `file829...md` (template) — hanya struktur yang dipakai di v7.1, sekarang TIDAK dipakai. Format v7.2 mengikuti v6.2.3.

## Lampiran B — Log kontradiksi yang diselesaikan (v6.2.3 → v7.2)

- Mutasi (Embun / Petir / Emas / Pelangi) → Kualitas (Biasa / Bagus / Prima). Alasan: Mutasi adalah judi / FOMO, hanya 15% player 16+ cozy tertarik.
- Pelangi sebagai sistem → dihapus. Alasan: sisa Mutasi yang dibungkus ulang.
- Greenhouse → dihapus. Alasan: merugikan player saat hujan.
- Rak Pajangan → dihapus total. Alasan: tidak ada lagi hasil Mutasi / Prima untuk dipajang, fungsi pamer pindah ke Album GUI + Like / Visit.
- Papan Pamer → dihapus total. Alasan: karangan, tidak pernah disepakati.
- RW sebagai sistem → hanya cerita. Alasan: game belum terbukti ramai.
- Pasar / Lapak antar-player → Warung Player (NPC). Alasan: gameplay sudah padat, tawar-menawar tanpa efek adalah mati.
- Ramalan cuaca → hanya tanda 10 detik. Alasan: tanpa FOMO.
- Terik +10% Nambang → Terik netral. Alasan: Terik tidak boleh mengontrol gameplay.
- Antrean Dapur (3 per slot) → dihapus. Alasan: tidak ada di v6, tidak pernah dibahas.
- Reputasi Warung (+2 / +5 / +25%) → dihapus. Alasan: karangan, tidak pernah dibahas.
- Album 254 (v6) → 214 GUI (v7.2). Alasan: tanpa Mutasi, dengan Kualitas.
- Map → tidak dibahas. Alasan: map sudah ada di Roblox Studio.
- Format file829 → format v6.2.3. Alasan: dokumen desain harus pakai format v6.2.3, bukan format implementasi.
- Order Villager (karangan di audit) → sistem LOCKED v7.3 Bab 14.7. Alasan: kelewat di v7.2, masih perlu. Beda dari Agenda.
- Buff Olahan → sistem LOCKED v7.3 Bab 9.4. Alasan: Olahan bisa dimakan sendiri, buff hanya untuk aktif (Nanem / Mancing / Nambang / Nebang).
- Bibit Unggul (+10% / x1,5) → dihapus. Alasan: karangan, pasif, nabrak Skill + Buff.
- Backpack Pass (+40 slot) → dihapus. Alasan: karangan, Tas tanpa cap slot.
- Blueprint gating → dihapus. Alasan: Blueprint bukan gating, hanya simpan / share desain.

## Lampiran D — Deviasi Kode vs Dokumen (v7.5, BELUM DIPUTUSKAN)

Daftar ini wajib dibaca sebelum playtest. Setiap butir adalah tempat kode TIDAK sesuai dengan teks dokumen (v7.4 / v7.5). Yang belum diputuskan owner tetap berjalan di kode sebagai usulan interim.

| # | Bab | Teks dokumen | Kode sekarang | Keputusan |
|---|-----|--------------|---------------|-----------|
| 1 | 4 (Perairan) | "Empat spot mancing" (Kanal, Danau, Sungai, Spot 4) | +32 spot sungai (8 × 4 sungai sumbu) di `FishService.buildRiverSpots`, angka di `Config/Map.RIVER_SPOTS`. Owner setuju 8 per sungai (2026-11-22). |  DITUTUP (Update owner 2026-11-22, Task 2): 32 spot sungai lahan diterima sebagai lokasi Early Lv 1 (`sungai_lahan`). Tidak ada Mid, Late, atau Legenda di sana. |
| 2 | 6.2 (Mini-game) | Ikan di kotak +15%/detik, di luar kotak -10%/detik | `FILL_GAIN = 0.28`, `FILL_DRAIN = 0.06`, `ZONE_SPEED = 0.9` (kanan), `ZONE_SPEED_LEFT = 0.55` (kiri) di `FishingController` |  DITUTUP (Update owner 2026-11-22, Task 4): nilai `FILL_GAIN 0.28`, `FILL_DRAIN 0.06`, `ZONE_SPEED 0.9`, `ZONE_SPEED_LEFT 0.55` ditulis di Bab 6.2. |
| 3 | 16.2 (FTUE) / coachmark | Coachmark "tarik" dipakai di FTUE mancing (Kak Fajar, Wader Cakul) | Frame coachmark "Tahan Tarik! Jaga ikan…" dihapus, `fishPending` ikut dihapus |  DITUTUP (Update owner 2026-11-22, Task 4): coachmark tarik tetap dihapus, dan dihapus juga dari Bab 16.2. |
| 4 | 16.2 (FTUE) | "Mancing hanya di dermaga Kanal" | Panah tutorial mencari spot `sungai` terdekat (`GuideController`). Spot sungai baru ikut terpilih bila pemain dekat sungai. |  BELUM DIKERJAKAN (Task 1): panah tutorial akan menunjuk spot sungai lahan terdekat dari lahan pemain (dihitung di server). Saat ini masih menunjuk spot sungai lahan terdekat secara umum. |
| 5 | 6.1 / 23 (Mancing) | "Tombol Mancing (saat dekat spot)" | Prompt dermaga dihapus; tombol bulat jadi satu-satunya cara cast di dermaga. Kolam tetap prompt. | Sesuai secara makna. Perlu dicek bahwa prompt kolam juga tidak dibutuhkan. |
| 6 | Roadmap §2 | "Jangan ubah map" | Spot sungai dibuat lewat kode (`FishService.Init`), bukan di Studio. `Config/Map.luau` ditambah `RIVER_SPOTS`. | Catat. Map fisik di Studio tidak diubah. |
| 7 | 8.2 (Meja Crafting) | Craft olahan di Meja Crafting | Tombol Craft mencari objek Workspace bernama "Meja Crafting". Objek itu belum ada di Studio. | BUTUH: buat/beri nama objek meja di Studio. Tanpa itu tombol Craft tidak pernah muncul. |
| 8 | 23 (GUI) | Tidak diatur | Batas tinggi quest tracker 200 px tetap, tidak dihitung dari tinggi layar. Pada layar pendek bisa menimpa area di bawahnya. |  DITUTUP (Update owner 2026-11-22, Task 5): tinggi maks tracker = min(200 px, 25% tinggi layar), dihitung ulang saat viewport berubah, maks 3 baris + "+N lainnya". Cek tumpang tindih dengan kartu XP di kiri bawah: perlu dicek di Studio. |
| 9 | 23 (GUI) | Tidak diatur font | Semua GUI FredokaOne. Dulu campuran Gotham. | Konsistensi. Perlu dicek apakah teks panjang (dialog) masih nyaman dibaca. |
| 10 | 10.1 (NPC) | Bang Jali di depan lahan | Rig Bang Jali menghadap sisi lain (membelakangi warung mini). | Sesuai. Tidak perlu keputusan. |
| 11 | 16.2 (FTUE) / 4.3 (XP) | Tabel 16.2: XP per langkah FTUE 20 + 20 + 20 (+ 1 per langkah awal), total tutorial sekitar 43 XP | `Config/Onboarding` langkah `jual_ikan` menambah `reward = { xp = 115 }`, sehingga tutorial membawa player ke 158 XP. Dengan 6 bibit gratis (kangkung 12 XP) habis dipanen, total 230 = Lv 2. |  DIPUTUSKAN owner (2026-11-22): 115 XP diterima. Pace ideal (6 bed, 1 panen per bed tiap 5 menit, ±972 XP/jam): Lv 2 = 230 XP total (±14 menit), Lv 5 = 1.100 XP total (±68 menit). Hambatan awal ada di Koin petak (petak 7 = 1.050 Koin), bukan XP. Verifikasi di playtest. |
| 12 | 14 (Quest) | Quest muncul sesuai level dan syarat (tidak menyebut tutorial) | Semua quest menunggu tutorial jual ikan (`t1b_kolam`) selesai. `QuestService.startAvailable` + `TutorialService.Finished`. Save lama yang belum pernah menjalankan `t1b_kolam` tetap terkunci sampai tutorial itu selesai. |  DIPUTUSKAN owner (2026-11-22): semua quest menunggu `t1b_kolam` selesai. Sebelum itu tidak ada GUI quest dan progres tidak dihitung. |
| 13 | 14.2 (Kolam) / 16.5 | Quest Kolam pertama: Lv 2, syarat Kolam Kakek pulih | `kolam_pertama` tanpa `requireKakek`: quest mulai di Lv 2, langkah "bangun kolam" menunggu Kolam Kakek (Lv 3, MQ4/Bundel). `PondBuild` tetap butuh `kakekUnlocked`. |  DIPUTUSKAN owner (2026-11-22): diperbarui oleh #30: langkah bangun kolam terbuka di Lv 4 (`Fishing.POND.UNLOCK_LEVEL = 4`, lewat Kolam Kakek / M3). Kolam Kakek tetap jalur lain. **SUPERSEDED (Q-1):** `kolam_pertama` tidak ada lagi di `Config/Quests`. Quest kolam sekarang M3 Kolam Kakek (Lv 4, Quest v0.3 Bab 6). Kolom 'Teks dokumen' dan 'Kode sekarang' di atas dibiarkan sebagai riwayat. |
| 14 | 5.2 (Petak) | Tidak menyebut refund petak; beli petak dengan harga n x 150 | Hapus Petak = refund 50% dari harga petak yang dibeli (`Farm.TILE_REFUND_RATE`). Petak gratis tidak ada refund. Harga per petak disimpan (`paid`). |  DIPUTUSKAN owner (2026-11-22): refund 50% untuk petak berbayar, ditulis di Bab 5.2. |
| 15 | 15.1 (Login) | 7 hari kumulatif, tanpa keterangan ulang | Login Mingguan diulang tiap minggu (Senin 05:00 WIB). `Config/Rewards.LOGIN`, `RewardsService`. |  DIPUTUSKAN owner (2026-11-22): Login Mingguan diulang tiap minggu, 10 Bunga per minggu. |
| 16 | 15.3 / 18.2 (Peti Bunga) | Isi peti tidak disebut. Sumber: Login, Pencapaian, Album, Season, Event, Bundel, Robux. Tabel 18.2: 60 Bunga/bulan dari peti | 1 peti = 25 Bunga (owner). P2-9 hanya memberi peti dari Title baru (1 per title), sekali. Total ~25–250 Bunga sekali jalan, belum 60/bulan. |  SEBAGIAN (Update owner 2026-11-22, Task 6): sudah dihubungkan: Title, Album milestone p25/50/75/100, Season F2P hari 30. Event completion BELUM ada definisinya di kode, lihat #21. |
| 17 | 15.4 (Title) | Title hanya contoh | 10 title di `Config/Rewards.TITLES`. Kolektor (Album 50%) dan Legenda Kampung (Album 100%) otomatis dari % Album. Tiap title = 1 peti. |  DIPUTUSKAN di kode (Update owner 2026-11-22, Task 6): syarat tiap title diambil dari kode (Bab 15.4). Warga Teladan tidak ada sumbernya, lihat #22. |
| 18 | 19 (Season) / 18.2 (Login) | Season 30 hari; F2P: Koin, bahan, 30 Bunga, dekor; Premium 150 Bunga. Login 20 Bunga/bulan di tabel 18.2 | Season 1 mulai 1 Des 2026 (WIB). F2P: 50 Koin/hari + 30 Bunga. Premium: 40 Koin/hari + 60 Bunga ekstra. Bahan, dekor, kosmetik belum ada. Login 10 Bunga/minggu (~40/bulan) melebihi tabel 18.2. |  SEBAGIAN (Update owner 2026-11-22, Task 6): F2P pakai hadiah tiap 5 hari (USULAN, #20). Premium ditunda (Segera hadir). Login 40 Bunga/bulan sudah masuk Bab 18.2. |
| 19 | 8.7 / 12.7 (Galeri) | Pemilik offline: rumah snapshot read-only | DIHAPUS. Pemilik offline = lahan kosong, tidak ada toast, tidak ada rumah snapshot. |  DIPUTUSKAN owner (2026-11-22): pemilik offline = lahan kosong. Toast dan rumah snapshot dihapus. |
| 20 | 19 (Season) | F2P: 50 Koin tiap hari, lalu hadiah tiap 5 hari (USULAN P2-9) | USULAN, belum final: hari 5 = 10 Bambu; hari 10 = 5 Bunga + 10 Kayu; hari 15 = 5 Batu; hari 20 = 10 Bunga + 5 Ijuk; hari 25 = 15 Bambu + 10 Kayu; hari 30 = 15 Bunga + 2 Atap Ijuk + 1 Dekor Rumpun Bambu + 1 Peti Bunga. Total Bunga F2P 30. Bahan / dekor / kosmetik lain belum ada. | BUTUH KEPUTUSAN: setujui daftar dan jumlah di atas, atau ganti. |
| 21 | 15.3 (Peti Bunga) | Event selesai = 1 peti (Update owner 2026-11-22) | Di kode belum ada definisi "completion" untuk Event (EventService hanya kalender). Tidak dihubungkan. | BUTUH KEPUTUSAN: definisi event selesai (misal: semua tugas event selesai, atau event tertentu). |
| 22 | 15.4 (Title) | Warga Teladan disebut sebagai title (contoh) | Tidak ada sumber di kode (tidak ada grant). Dikeluarkan dari daftar title. | BUTUH KEPUTUSAN: sumber Warga Teladan, atau hapus dari dokumen. |
| 23 | 16.2 / 16.6 / 14.8 (Task 1) | FTUE sampai jual ikan; Kak Fajar tutorial klien di sungai lahan; NPC bicara dan menoleh klien-only; starter quest chain | SEBAGIAN (Task 1, Update owner 2026-11-22). SELESAI di kode: (a) spot sungai lahan milik pemain dihitung di server (`FishService.AssignedRiverSpot`, atribut `RiverSpot`), panah tutorial menunjuk spot itu; (b) jual ikan ke Kak Fajar tutorial hanya diterima saat langkah `jual_ikan` dan dekat spot milik pemain (`ShopService`, jarak = `arrive` 14 studs, Onboarding); (c) Starter Quest Chain: `starter_bayam` (event plant_bayam), `starter_nambang` (+20 XP), `starter_pagar` (+100 Koin), Agenda terbuka setelah `starter_pagar`; (d) baris dialog Pak Udin. KLIEN-ONLY (Task 1 lanjutan): `src/client/KakFajarTutorial.client.luau` membuat salinan Kak Fajar lokal di spot sungai lahan pemain saat langkah jual_ikan (rig dari ReplicatedStorage.NpcTutorial.kak_fajar, atau dibangun dari warna Config/Npcs). Kak Fajar server disembunyikan (LocalTransparencyModifier + prompt mati) untuk pemain itu saja. `T1Dialog.NpcModel` memakai salinan itu. Bicara NPC sudah per pemain (NpcTalk), menoleh NPC lewat NpcPose hanya lokal. BELUM: Gerobak Kaget setelah chain, langkah Surat Kakek #1 (belum ada event), dan jarak jual spot memakai Shop.NPC_DISTANCE (USULAN, Lampiran D #25). BUTUH: model ReplicatedStorage.NpcTutorial.kak_fajar (opsional) dan keputusan event Surat #1 serta Gerobak. |
| 24 | 4.4 / 6.4 (Perairan) | Kanal Barat dan Kanal Timur di Bab 4.4 dan 6.4 | Kanal barat (`sungai`) Lv 5: Mid + Belut Emas, Late dipindah ke kanal timur (`empang`, Lv 10). Ini konsekuensi Task 2 (owner: "Mid pool"). | BUTUH KONFIRMASI owner: Late di kanal timur saja, atau tetap di kanal barat. |
| 25 | 16.2 (Task 1) | Jarak jual ikan ke Kak Fajar tutorial di spot sungai lahan | Memakai `Shop.NPC_DISTANCE` (25 studs), sama seperti jual ke NPC biasa. Angka ini USULAN. | BUTUH KEPUTUSAN: 25 studs diterima, atau angka lain. |
| 26 | 16.2 / 16.6 (Mancing) | Tidak disebut: pemain bisa bergerak saat memancing; tidak ada batas jarak saat memancing | **PERUBAHAN PERILAKU (B-5).** Server membatalkan pancing bila pemain menjauh lebih dari `Fishing.LEAVE_DISTANCE` (24 stud) dari spot (watchdog di `FishService`). Gerak dikunci selama memancing (B-4, `PlayerLock`). Angka 24 stud = USULAN; tidak mengubah angka gameplay lain. | BUTUH PERSETUJUAN OWNER: terima watchdog 24 stud, atau ubah nilai / hapus. |
| 27 | 14.4 / 14.2 / 16.2 (Quest, Naskah Bab 2-3) | Quest dimulai dari dialog pemberi (Naskah Mulai, lalu banner Dimulai untuk Main). Quest Side tanpa dialog tidak disebut. | **PERUBAHAN PERILAKU (Q-3):** quest yang punya baris Naskah (`dlg.<prefix>.start.1`) tidak lagi mulai otomatis: ditawarkan (`!` di pemberi) dan mulai saat dialog Mulai selesai (`QuestAccept`). Quest tanpa baris Naskah, yaitu side_rumah_rapi, side_tetangga, side_resep, side_prima, side_jumbo, tetap mulai otomatis tanpa dialog dan tanpa `!` (tidak ada teks di Naskah v0.1). side_kolektor dan MQ12 bersifat auto (langsung selesai) dan juga tanpa dialog. | BUTUH KEPUTUSAN OWNER: (a) terima aturan "dialog dulu, baru mulai", (b) tulis Naskah untuk 5 side_* dan Kolektor, atau biarkan mulai otomatis tanpa dialog. |
| 28 | 6.8 (Quest Log) | Quest Log: sheet dengan tab Main · Side. Label bagian tidak disebut. | Label baru di `Locale` (Q-4): "Quest Log", "Aktif", "Tersedia", "Berikutnya" (`???` untuk Main yang belum sampai level). "Tersedia" dan "Berikutnya" tidak ada di dokumen GUI. | BUTUH KEPUTUSAN OWNER: setujui label "Tersedia" dan "Berikutnya", atau ganti kata. |
| 29 | 4.5 (Layer) / 4.4 (Target sentuh) | Tabel layer Bab 4.5 dan target sentuh 24/32/40 px untuk semua UI. | Q-4 memakai `UiKit.LAYER` untuk file yang disentuh (panel 40, banner 80, dialog 120, fade 150, toast 60, modal 100, HUD 20). 19 `DisplayOrder` angka mentah masih ada di Coachmark (25, 60), Decor (20), Farm (5, 45, -1), Fishing (6), Guide (-2), Land (-1), Mining (6), Pond (6), Ranch (6), FarmFloat (-1), MenuFlow (200, 210, 250), T1Ghost (110), WorldArrow (30). `UiKit.TOUCH` masih 50 (Bab 4.4 minta 32). | Tahap UI-1 di GUI doc: pindahkan sisa 19 ke `UiKit.LAYER`; owner tentukan layer untuk Coachmark (tabel: 50/55), Farm (5, 45), dan MenuFlow. DITUTUP (commit `8ed8b0a`): 19 hit sudah memakai `UiKit.LAYER`, pemetaan per file ada di commit message. |
| 30 | 4.4 / 14.1 / 16.5 (Kolam) | Kolam Tanah dibangun mulai Lv 2 (keputusan #13). Quest v0.3 Bab 6: Kolam Lv 4 (`UNLOCK_LEVEL` 2 → 4). | Kode sekarang Lv 4 (`Fishing.POND.UNLOCK_LEVEL = 4`, Q-2). Bab 4.4 dan 14.6 di v7.7 sudah Lv 4. Teks #13 dan bab 14.1, 16.5 (Lv 2) belum diubah karena keputusan #13 belum dicabut. | DIPUTUSKAN owner (2026-11-22): Kolam Tanah Lv 4, lewat Kolam Kakek / M3, sesuai Quest v0.3 Bab 6 dan Roadmap §10. Teks Bab 16.5 dan #13 sudah Lv 4. Kode `Fishing.POND.UNLOCK_LEVEL = 4` tidak berubah. |
| 31 | 10.1 / 14.4 / 14.1 (Gerbang fitur) | Gerbang bicara Bang Jali dan KBPungut (lihat Changelog 0.3.4 #3-4). | DIPUTUSKAN di kode (Q-2c koreksi, Q-2d): bicara Bang Jali tidak digerbang (quest S3 mulai dari sana), jual tetap digerbang server. KBPungut digerbang Gerobak. Surat digerbang server. | Catat. Tidak perlu keputusan lagi kecuali owner ingin membalik. |
| 32 | 4.4 (Target sentuh) | Tier tombol: 24 min, 32 standar, 40 satu aksi utama per layar. Tombol HUD tetap. | UI-1: `UiKit.TOUCH` 50 → 32 (standar, berlaku ke semua `UiKit.button`). `TOUCH_CTA` 40 untuk Panen Semua (`FarmController` HarvestAll). `TOUCH_ROW` 32 untuk baris tracker. `TOUCH_HUD` 50 untuk pil HUD (dock text dan kolom menu) karena dokumen 4.4 menyatakan HUD tetap. Gembor (`FarmController`) memakai TOUCH 32. | BUTUH KEPUTUSAN OWNER: (a) Gembor 32 atau CTA 40 (Gembor dipakai berulang, tetapi bukan satu-satunya aksi di layar), (b) pil HUD tetap 50 (dokumen 4.4) atau ikut 32. Tombol di panel akan lebih kecil setelah UI-1, cek di playtest. |
| 33 | 5.1 (Bubble Dialog NPC) | Dua varian bubble: instruksi (tinggi 48-72, nama 12 px satu baris dengan teks, bingkai inset 12 px, foto 32) dan percakapan (tinggi 64-96, nama 13 px di atas teks, bingkai inset 14 px, foto 40). | UI-1: varian dibuat di `T1Dialog` (`METRICS`, `layoutFor`). Instruksi dipakai `T1Ghost.instructionOpts` (variant = "instruction"). Tinggi diukur dari teks lalu dijepit min / maks. Deviasi: (a) nama instruksi di atas teks, bukan satu baris (butuh posisi teks dan nama yang lebih rumit), (b) nama percakapan 14 px (token TEXT_SMALL, 13 px dipetakan ke 14), (c) inset bingkai tetap 34 px karena skin `UiAssets.PANEL` tebal; inset 14 px butuh skin tipis baru. | BUTUH KEPUTUSAN OWNER: setujui deviasi (a)-(c), atau minta skin tipis dan layout satu baris. |
| 34 | 6.1 (Hadiah) | Hadiah: tab Harian, Musim, Koleksi. Login 7 kartu ke samping, Peti Main sebagai bar waktu 0-60 menit, Peti Bunga sebagai satu kartu besar, Klaim Semua saat 2 atau lebih siap, Milestone Album pindah dari tab Album. Node Musim 64 px, milestone lebih besar. | UI-3: tiga tab dibuat (`RewardsController`). Musim: dua track horizontal (Gratis, Premium) dengan node 64 px; milestone (hari dengan hadiah Bunga, dari `Rewards.seasonReward`) 80 px. Tetap sebagai baris (klaim tidak berubah): Login Mingguan, Peti Main, Peti Bunga. Milestone Album ditampilkan di Koleksi lewat `BookController.RenderClaims`; tab Album masih punya salinan (belum dihapus). Belum dibuat: Login sebagai kartu, Peti Main sebagai bar, Peti Bunga sebagai kartu besar, dan tombol Klaim Semua (tidak ada remote klaim batch; kirim berurutan atau tambah remote adalah keputusan server). Agenda tidak punya klaim di kode (hadiah diberikan otomatis, `AgendaService`), jadi tidak ada di tab Harian. | BUTUH KEPUTUSAN OWNER: (a) ukuran node milestone 80 px (doc tidak menyebut angka), (b) Klaim Semua: remote batch atau kirim berurutan, (c) hapus Milestone Album dari tab Album (doc 6.9 menyebut 'pindah'), (d) Login, Peti Main, dan Peti Bunga tetap baris atau dibuat kartu seperti doc 6.1. |
| 35 | 14.1 / 16.2 (Sapaan NPC sesudah tutorial) | Sapaan pertemuan pertama (`npc.<id>.meet`) dan Naskah pembuka quest. Tutorial sudah memperkenalkan Mak Sari, Pak Udin, dan Kak Fajar. | Bug UI 3: tutorial (`T1Ghost` `speakerFor`) mencatat ketiganya sebagai sudah bertemu lewat `HasMet` saat baris mereka pertama tampil. Sapaan tidak diulang pada bicara pertama sesudah tutorial (contoh: S1 Pak Udin, "Halo, Piko! Saya Pak Udin, pengepul..."). Baris pembuka Naskah quest dari ketiga NPC ini (m5, m6, m3, s1, s2, s5, s7, s8, mq12, dst.) tidak diubah: tidak ada yang berupa perkenalan, jadi tidak dilewati. Naskah perkenalan lain (`dlg.s3.start.1` Bang Jali "Eh, tetangga baru!", `dlg.s4.start.1` Pak Amran "Saya Amran, tukang kayu", `dlg.m1.start.1` Nek Ani) tetap karena ketiga NPC itu belum ada di tutorial. | BUTUH KEPUTUSAN OWNER: setujui daftar NPC yang dianggap sudah dikenal lewat tutorial (Mak Sari, Pak Udin, Kak Fajar), dan apakah baris perkenalan di Naskah S3, S4, M1 perlu dilewati atau tetap. |

## Lampiran C — Nilai Harapan Koin per Panen & Hitungan Kualitas / Mood Hujan

### C.1 Kualitas Panen — Expected Multiplier

Distribusi rata-rata player: Biasa 60% / Bagus 30% / Prima 10% (asumsi campuran kondisi panen).
- Dengan +10% / +25%: Expected = 0,6 x 1,0 + 0,3 x 1,1 + 0,1 x 1,25 = 1,055.
- Dengan +20% / +50% lama: Expected = 0,6 x 1,0 + 0,3 x 1,2 + 0,1 x 1,5 = 1,110.

Player jago (Biasa 50% / Bagus 35% / Prima 15%):
- Dengan +10% / +25%: Expected = 0,5 x 1,0 + 0,35 x 1,1 + 0,15 x 1,25 = 1,0725.
- Dengan +20% / +50%: Expected = 0,5 x 1,0 + 0,35 x 1,2 + 0,15 x 1,5 = 1,145.

Kesimpulan: +10% / +25% menaikkan Nanem hanya +5,5% rata-rata, +7,25% untuk jago. Aman. +20% / +50% menaikkan Nanem +11% rata-rata, +14,5% untuk jago, terlalu besar dan bikin Kualitas mendominasi.

Durian Prima = 1.300 x 1,25 = 1.625 Koin (Super dihapus, Update owner 2026-11-22).

### C.2 Mood Hujan — Hitungan Hujan vs Siklus Ternak

- Terik 8-15 menit (rata-rata 11,5) + Hujan 3 menit = siklus hujan 14,5 menit.
- Hujan per jam: 4,14x, total hujan 12,4 menit / jam (20,7% waktu).
- Ayam 15 menit = 1,03x siklus hujan, Bebek 20 menit = 1,38x, Sapi 30 menit = 2,07x.
- Jika Mood = 1 siklus penuh setelah hujan: interval hujan 14,5 < 15 menit Ayam → buff aktif ~100% waktu → +10% jadi +10% permanen, bukan bonus hujan. Salah.
- Jika Mood = 5 menit setelah hujan: coverage 5 / 14,5 = 34,5% waktu. Expected bonus = 34,5% x 10% = +3,45% ke Ternak (2.000 → 2.069). Kecil, sesekali, cozy. Benar.

### C.3 Hujan — Contoh Tanam 30 Menit (LOCKED)

Tanaman 30 menit, siram hemat 4,5 menit (15%), sisa 25,5 menit, hujan 3 menit motong 6 menit (2x), sisa setelah hujan 19,5 menit, total 22,5 menit.

### C.4 Album 214 — Hitungan GUI

Ladang 54 (18 x 3) + Sungai 80 (20 x 4) + Dapur 72 (24 x 3) + Varian 8 (6 + 2) = 214. Kandang (5) dan Rumah (80) adalah tab terpisah, tidak masuk ke total 214 GUI utama.

