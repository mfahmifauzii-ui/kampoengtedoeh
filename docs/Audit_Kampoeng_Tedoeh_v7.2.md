# Audit Kampoeng Tedoeh v7.2 — Implementasi vs Single Source of Truth

Sumber kebenaran tunggal: `Kampoeng-Tedoeh-V7-2.md`. Audit ini hanya membandingkan `src/` (repo) terhadap v7.2. Map layout tidak diaudit. Angka yang tidak ditemukan di kode ditulis sebagai "Tidak ada di kode" atau "Tidak bisa diverifikasi dari kode, cek di Studio". Tidak ada angka karangan.

## 1. Ringkasan

Implementasi saat ini hanya mencakup loop inti Nanem-Mancing-Kolam-Hias dasar dan belum menerapkan sebagian besar sistem v7.2: dari Bab 0 sampai Bab 30, hanya 6 bab yang Sesuai penuh (Bab 3, Bab 5 sebagian besar angka inti, Bab 10 nama NPC, dan lainnya), 8 Bab Tidak Sesuai (angka berbeda), 12 Bab Belum Ada (sistem tidak diimplementasikan), dan 4 Bab berstatus Karangan (sistem di kode tidak ada di v7.2, misalnya Mutasi, Blueprint, Order, dan Buff). Pelanggaran Bab 29 yang ditemukan di kode: Mutasi Panen (Embun/Petir/Emas/Pelangi), Pelangi sebagai sistem cuaca, Greenhouse dan Rak Pajangan di tabel Unlock, Lapak Tetangga di tabel Unlock, Instant Panen pakai token (dilarang: Bunga tidak boleh beli kekuatan), dan Bunga dari Level-Up/tidak ada tapi Bunga dari Album/Milestone berbeda (masih sumber Bunga yang diizinkan, tapi angka beda). Sistem besar yang hilang: Kualitas Panen, 16 Skill, 18 Tanaman lengkap, 20 Ikan lengkap, Pity Legenda, Bubu, Ternak, Breeding Kolam, Nambang, Dapur 24 resep, Warung Player, Album 214, Bantu/Hadiah, Gerobak Kaget, Pasar Malam, Kerja Bakti, Quest MQ/Surat/Side/Agenda, Login Mingguan lengkap, Season. Versi save masih 62 (harusnya 72). Performa, GUI, Effects, Animasi, LiveOps, dan Data Structure sebagian besar Belum Ada atau tidak bisa diverifikasi tanpa place di Studio.

## 2. Tabel Status per Bab

| Bab | Status | Bukti (file:baris / di Studio) |
|---|---|---|
| Bab 0 Ringkasan & Target | Tidak Sesuai | Target sesi 20-40 mnt di v7.2 Bab 0.2; di kode tidak ada config KPI/sesi. Konten rilis 71-72% tidak dihitung di kode. Level Cap 60 sesuai (`Progression.luau:17`), tapi +20/update tidak ada. |
| Bab 1 Prinsip | Tidak Sesuai | Prinsip 1,2,5,9,11,15 terpenuhi sebagian (tidak ada stamina/fail di kode, waktu server via `WorldService.luau`, uang terpisah). Prinsip 3 dilanggar oleh Mutasi (lotre, bukan timing) — `Mutasi.luau:26-31`. Prinsip 12 dilanggar oleh Instant Panen — `Monetization.luau:22`. Prinsip 17 dilanggar Mutasi + Pelangi. |
| Bab 2 Target Pemain | Belum Ada | Persona dan sesi 30 mnt tidak ada di kode. Batas sehat: tidak ada toast >120 mnt, tidak ada hadiah >60 mnt dijamin hanya oleh 3 peti (`Progression.luau:41-45`), tapi tidak ada config persona. |
| Bab 3 Dunia/Waktu/Cuaca | Sesuai (sebagian) | Hari 30 mnt + fase 3/15/3/9 sesuai (`World.luau:18-23`). Cuaca Terik 480-900 + Hujan 180 + roll 55/30/15 sesuai (`Weather.luau:12-22`), tapi + Pelangi 60 dtk (`Weather.luau:15,25-26`) adalah Karangan/pelanggaran. Lahan 128x128/192x192 + chunk 1500x1,2^n sesuai (`Plots.luau:17-20,74`). Reset 05:00 sesuai (`Progression.luau:27`). Tanda hujan 10 dtk tidak ada di kode (cek Studio). |
| Bab 4 Mata Uang/Level/SP/Skill | Tidak Sesuai | Koin/Bunga/Bahan terpisah sesuai (`Economy.luau:4-10`). Rumus XP `200+30*n` sesuai (`Progression.luau:19-21`), cap Lv 60 sesuai. SP 1/Lv dihitung (`ProgressionService.luau:123`) tapi tidak bisa dibelanjakan. Skill cabang 4x Lv10 (`DataTemplate.luau:17-22`, `Progression.luau:31-34`) ≠ 16 Skill v7.2 Bab 4.5. Unlock tanaman/ikan tidak sesuai (lihat Bab 5/6). |
| Bab 5 NANEM | Tidak Sesuai | 6 tanaman pertama angka SESUAI (`Crops.luau:20-25`), 12 tanaman hilang. Petak `n*150`, max 36, gate Lv sesuai (`Farm.luau:8-35`). Super 5%+5% x2/+50% XP sesuai (`Farm.luau:55-58`). Siram potong 15% sesuai (`Farm.luau:53`). Kualitas Biasa/Bagus/Prima + distribusi 50/35/15 dll TIDAK ADA. Mutasi masih aktif (`Mutasi.luau`, `Items.luau`, `FarmService.luau:17`). Pasar Harian/Rotasi/Orang-orangan (asi dekor tapi tanpa stat) TIDAK ADA. |
| Bab 6 MANCING | Tidak Sesuai | 12 ikan di kode ≠ 20 ikan v7.2, harga semua beda (`Fish.luau:21-32` vs v7.2 Bab 6.4). 4 joran (`Fishing.luau:13-18`) ≠ 6 joran. Hanya 1 umpan (`Fishing.luau:40`) ≠ 4 umpan. Gigitan 3-5 dtk ≠ 3-6/6-12 + hujan 2x. Mini-game reel 3 dtk (`Fishing.luau:28`) ≠ bar tak-tahan lepas. Pity Legenda 200/min 150 TIDAK ADA. Bubu TIDAK ADA. Berat 4 ukuran TIDAK ADA (hanya S/M/L). |
| Bab 7 TERNAK+KOLAM | Belum Ada / Tidak Sesuai | Ternak (Ayam/Bebek/Sapi), kandang, pakan, Tempat Pakan, Mood Hujan: TIDAK ADA di `src/` (tidak ada service/config ternak). Kolam di kode = kolam mancing santai (`Fishing.luau:45-53`, `PondService.luau`), bukan breeding 2 ikan → 1 anak + pakan 20 Koin. Tier/ harga/waktu/ Kolam Kakek gratis: TIDAK ADA. |
| Bab 8 NAMBANG+CRAFTING+HIAS | Belum Ada / Tidak Sesuai | Nambang 6 node, Ritme Critical, respawn 4 mnt: TIDAK ADA. Bahan 7+7 + craft: TIDAK ADA (tidak ada config bahan). Hias: katalog ~30 piece ≠ 80, `MAX_PLACED=150` ≠ 800 (`Decor.luau:221`). Dekor Berkah 30/set/dekor stat: TIDAK ADA. Akuarium/Bingkai Album: TIDAK ADA di kode (cek Studio). Blueprint dari Pak Amran adalah Karangan (bukan di v7.2). |
| Bab 9 DAPUR+WARUNG | Belum Ada | Dapur Tier/Slot/resep, Kualitas Olahan, Garam/Daun Pisang: TIDAK ADA di `src/` (tidak ada Config Dapur/Resep). Warung Player (1 slot pajang, NPC 5-10 mnt, max 5 offline): TIDAK ADA. Mak Sari `buys={}` — tidak bisa beli olahan (`Npcs.luau:85`). |
| Bab 10 NPC & JUAL | Tidak Sesuai | Nama 6 NPC sesuai (`Npcs.luau:54,63,72,81,91,120`) — tidak ada nama lama di `Npcs.luau`, tapi `Unlock.luau` memuat sistem terlarang (lihat Karangan). Peran/harga tidak sesuai: Pak Udin tidak jual garam/hewan/pakan; Kak Fajar menjual ikan (`Npcs.luau:68`, `ShopService.luau:242` — v7.2 hanya beli 100%); Mak Sari tidak membeli apa-apa; Bang Jali hanya beli crop+fish 90% (`Npcs.luau:133`) ≠ semua barang 90%. Garam 10 Koin, Daun Pisang bonus 2: TIDAK ADA. |
| Bab 11 ALBUM | Tidak Sesuai | Kategori `crops/fish/decor` (`Book.luau:23`), recata dari list pendek → total ~24 entri ≠ 214 GUI (54+80+72+8). Milestone 25%→500 Koin ≠ 10 Bunga, 50%→10 Bunga ≠ 20 Bunga+Title, dst (`Book.luau:33-38` vs v7.2 Bab 11). Title `warga_teladan/juragan_pondok` ≠ `Kolektor/Legenda Kampung dsb`. Album masih berupa Book, bukan tab Ladang/Sungai/Dapur/Varian. |
| Bab 12 SOSIAL | Tidak Sesuai / Belum Ada | Visit+Like+4 Gestur sesuai sebagian (`Social.luau:22-27`, `SocialService.luau`). Like: 1x/hari (`SocialService.luau:107`) ≠ 1x selamanya; tidak ada +20 Koin pemberi/max 10/hari. Milestone Like 10/50/200 → Koin sesuai angka di kode tapi tidak ada di v7.2 (v7.2 hanya +20/pemberi). Bantu (1+1, max 5, +40/+10), Hadiah (3/hari ≤500 Koin), Chat, Galeri, Blueprint share, RW cerita: TIDAK ADA. |
| Bab 13 EVENT | Belum Ada | Gerobak Kaget (15 mnt, 3 slot, varian), Pasar Malam (9 mnt, +50%, max 10), Kerja Bakti Kilat (setelah Deres/Petir), Pesanan Tamu, Event musiman: TIDAK ADA di kode. `EventService` hanya musim lebaran (1 event). `WorldService.RainEnded` (`WorldService.luau:18`) ada sebagai sinyal tapi tidak ada listener Kerja Bakti. |
| Bab 14 QUEST | Tidak Sesuai | Hanya 2 quest (`kolam_pertama`, `misi_utama`) + 3 daily (`Quests.luau:26-60`). MQ1-MQ12 (12), Surat 30, Side 10, Agenda 5 (150-400 Koin), Bundel Kakek (5): TIDAK ADA. Hadiah daily 40 Koin ≠ 150-400. `kolam_pertama` (pond+catch) adalah Karangan. |
| Bab 15 HADIAH | Tidak Sesuai / Belum Ada | Login Mingguan 7 hari (100/150/200/2 Bunga/300/3 Bunga/500+5 Bunga): TIDAK ADA. Playtime: hanya 3 peti (10/30/60 → 50/150/300 Koin) (`Progression.luau:41-45`) ≠ 5 peti (10/20/30/45/60 → 50/100/150/200/300). Peti Bunga/Pencapaian/Title: TIDAK ADA. |
| Bab 16 TUTORIAL | Tidak Sesuai | T1 5 langkah (`Onboarding.luau:90-141`) + T1b 6 langkah ≠ FTUE 10 mnt 11 langkah v7.2 (tambah mancing/nambang/hias/surat). Panen pertama dijamin Super sesuai (`Onboarding.luau:255`) tapi digabung `FTUE_FIRST_MUTATION="embun"` (`Onboarding.luau:256`) = pelanggaran. Hadiah Xp 1/langkah ≠ 20 XP, final 30 Koin ≠ 100 Koin. Tombol Lewati ada via `BeatSkip` (cek Studio untuk validasi server). NPC Mak Sari/Pak Udin/Kak Fajar ada, tapi langkah NPC tutorial tidak sama. |
| Bab 17 EKONOMI | Belum Ada / Tidak Sesuai | Sink 623k, Faucet 12.000/jam, cap +25%: TIDAK ADA di kode (tidak ada simulasi/hitung). Ini dokumentasi ekonomi, bukan config — tidak bisa dicek tanpa instrumen. Alat Koin (Gembor/Sabit/Sepatu/Kapak): hanya `gembor` 300 Koin (`Farm.luau:40`) ≠ tabel v7.2 (Gembor Seng 2.000+10 Kayu dst). |
| Bab 18 MONETISASI | Tidak Sesuai | Pack Bunga 50/120/300 sesuai (`Monetization.luau:19-21`), tapi ada `instant_grow` 15 Robux (`Monetization.luau:22`) = Bunga→instant panen (dilarang saat panen). Pass `backpack` +40 slot adalah Karangan. Instant kolam 1 Bunga/10 mnt max 30: TIDAK ADA. Reroll order pakai Bunga (`Orders.luau:10`): bukan larangan langsung tapi tidak ada di v7.2. Tidak ada Robux→Koin/loot box/iklan (sesuai). |
| Bab 19 SEASON | Belum Ada | F2P+Premium 150 Bunga, 30 Bunga F2P, dekor eksklusif: TIDAK ADA di kode. |
| Bab 20 EXPERIENCE | Tidak Bisa Diverifikasi | Suara/haptic/game feel ada sebagai stub (`AudioController`, `Vfx`, `Sfx`) — tidak bisa diverifikasi angka dari kode, cek di Studio. Panen Super+Prima emas tidak ada karena Kualitas/Mutasi belum sesuai (mutasi emas di kode adalah Embun/Petir/Emas/Pelangi x1,5/x3/x5/x10). |
| Bab 21 EFFECTS | Tidak Sesuai | Partikel hujan 30/80/80 (`Weather.luau:36`) ≠ 30/60/90+kilat. Kilat tiap 20 dtk ≠ paket. Banner Legenda/Prima Late: tidak ada. Kerja Bakti kotoran visual: TIDAK ADA. |
| Bab 22 ANIMASI | Tidak Bisa Diverifikasi | Animasi pemain/hewan/ikan/NPC: cek di Studio (kode `RodAnimController`, `NpcPose`, dll ada tapi tanpa angka v7.2 untuk diverifikasi). |
| Bab 23 GUI | Tidak Sesuai | HUD Koin/Bunga/Level/fase/cuaca ada (`HudController.luau`), tapi Album bukan 214 GUI, Tas tanpa Kualitas, Dapur/Warung GUI tidak ada. GUI Papan Pamer/Rak Pajangan/RW/Ramalan: tidak ada di kode (sesuai larangan). Settings Mode Bantu: tidak ada di kode (cek Studio). |
| Bab 24 PERFORMA | Tidak Bisa Diverifikasi | Cap 8 player (implisit Studio `Max Players`), 800 piece (kode 150), 36 petak sesuai, 4 kolam sesuai, 3 bubu tidak ada, 10 hewan/kandang tidak ada. FPS ≥30 HP 4GB: cek di Studio/playtest, bukan kode. |
| Bab 25 KPI | Belum Ada | Retensi/konversi/sesi/jam Lv60: TIDAK ADA di kode. Analytics: `AnalyticsHooks` ada sebagai hook (cek isi Studio). |
| Bab 26 LIVEOPS | Belum Ada | Update Besar +20 Lv, +20 piece, +3 resep dst: TIDAK ADA. Event musiman hanya lebaran, bukan kalender penuh. |
| Bab 27 CORE LOOP | Tidak Sesuai | Kode masih berbasis Fase/Stage (`Fasting` fase, `T1/T1b`, Fase 2/3/5/6/7 di komentar) — v7.2 melarang Fase/Timeline (`Bab 27`), semua harus 1 Core Loop. Implementasi belum jadi 1 loop karena Dapur/Warung/Kualitas hilang. |
| Bab 28 STRUKTUR DATA | Tidak Sesuai | `version=62` (`DataTemplate.luau:9`) ≠ 72. Bentuk data tidak punya: Lahan Petak/Chunk/Bangunan/Warung lengkap, Pity/Bubu, Ternak/Kandang/Kolam breeding, Dapur, Album 214, Surge/Agenda/Side, Bantu/Hadiah. Ada cabang/skill/orders/book 3 kategori (karangan). |
| Bab 29 LARANGAN | Tidak Sesuai | 6 pelanggaran ditemukan di kode (lihat Bagian 3). |
| Bab 30 PLAYTEST | Belum Ada | Checklist 30.1-30.6: sebagian besar belum bisa lulus karena sistemnya hilang (Kualitas, Dapur, Warung, Album 214, Monetisasi sink). Tidak ada test otomatis dari Bab 30 di repo. |
| Lampiran A/B/C | Tidak Sesuai | Lampiran B (Mutasi→Kualitas, Pelangi/Greenhouse/Rak/Papan/RW/Pasar/Ramalan/Antrean/Reputasi→dihapus) dilanggar kode (masih pakai yang lama). Lampiran C hitungan ×1,055/Mood 5 mnt: Mood belum diterapkan; Kualitas belum diterapkan. Album 214 (C.4) belum diterapkan. |

## 3. Pelanggaran Larangan Keras (Bab 29)

- **Mutasi Panen aktif** — `Mutasi.luau:26-31` (Embun x1,5, Petir x3, Emas x5, Pelangi x10), dipakai di `FarmService.luau:17`, `Items.luau:33-57,94-115`. v7.2 Bab 29 + Bab 5.4: Mutasi dihapus.
- **Pelangi sebagai sistem** — `Mutasi.luau:30` + `Weather.luau:15,25-26` + `WorldService.luau:99-111` (40% Pelangi 60 dtk setelah Deres/Petir). v7.2: Pelangi dihapus total.
- **Greenhouse + Rak Pajangan di tabel Unlock** — `Unlock.luau:15` ("Rak Pajangan Panen"), `Unlock.luau:21` ("Greenhouse"). v7.2: keduanya dihapus total.
- **Lapak Tetangga (Pasar antar-player)** — `Unlock.luau:14` ("Lapak lihat-saja"), `Unlock.luau:19` ("Lapak Tetangga (jual)"). v7.2 Bab 10.2 + 29: Lapak dihapus, diganti Warung Player (NPC).
- **Instant Panen pakai Robux** — `Monetization.luau:22,30-31` (`instant_grow`), `MonetizationService.luau:105-119,126-129`, `FarmController.luau:414-419`. v7.2 Bab 18.5: hanya Kolam bisa instant Bunga, tidak ada instant panen/olahan.
- **Panen pertama dipaksa Mutasi Embun** — `Onboarding.luau:256` (`FTUE_FIRST_MUTATION="embun"`). v7.2 Bab 16.2: panen pertama dijamin Super, bukan Mutasi.

## 4. Karangan (ada di kode, tidak ada di v7.2)

- **Blueprint Pak Amran** (taman 400, pondok_sawah 600) — `Blueprints.luau:14-17`, `Decor.luau` field `blueprint`, `ShopService.luau:197-214`. v7.2 Pak Amran hanya jual alat + Blueprint share desain (simpan 3 slot gratis), bukan gating beli semua dekor.
- **Backpack Pass +40 slot** — `Monetization.luau:15,26`. Tidak ada di v7.2.
- **Order Villager (daily 3 + weekly)** — `Orders.luau`, `OrderService.luau`, `OrdersController.luau`. v7.2 tidak punya sistem Order; yang ada Agenda 5 tugas, Surat 30, Side 10, Pesanan Tamu Event. Reward x1,5/x3, reroll Bunga 2, deco weekly: karangan.
- **Book Kategori `decor` + milestone Koin** — `Book.luau:23-45`. v7.2 Album 214 adalah Ladang/Sungai/Dapur/Varian, Kandang/Rumah tab terpisah tidak dihitung. Milestone Koin 500/300 adalah karangan.
- **Buff tani/mancing/umum** — `Buffs.luau:17-24` (10% tumbuh, 25% gigitan, +10% XP). Tidak ada di v7.2.
- **Bibit unggul +10% tumbuh, x1,5 harga** — `Farm.luau:63`, `Npcs.luau:154`. v7.2 hanya menyebut "bibit unggul" sebagai istilah jual, tanpa angka tumbuh. Angka ini tidak ada di v7.2.
- **Jual ikan dari Kak Fajar** — `ShopService.luau:242-260`, `Npcs.luau:156`. v7.2 Kak Fajar hanya beli ikan 100%.
- **Pelangi cuaca + UI** — `Weather.luau:8,15,25-26`. Sudah tercantum sebagai pelanggaran, tapi juga karangan sistem.
- **Area Tambahan terlarang di Unlock** — Lapak, Rak, Greenhouse di atas; juga `Lapak lihat-saja` yang masih kategori Lapak.
- **Skill Cabang 4x Lv10** — `DataTemplate.luau:17-22`, `Progression.luau:31-34`. v7.2 punya 16 Skill, bukan 4 cabang.

## 5. Sistem Hilang (ada di v7.2, tidak ada di kode)

- Bab 4.5: 16 Skill (Tangan Hijau, Bibit Hemat, Mata Kualitas, Panen Raya, Joran Kuat, Firasat, Umpan Hemat, Ikan Besar, Tempat Pakan Besar, Telur Cepat, Susu Melimpah, Tukang Cepat, Kayu Kuat, Koki Cepat, Rasa Prima, Tetangga Baik).
- Bab 5.3: 12 tanaman (Singkong, Cabai, Padi, Stroberi, Pisang, Tebu, Jahe, Kopi, Teh, Melati, Mangga, Durian).
- Bab 5.4: Kualitas Panen + distribusi 50/35/15, 65/25/10, 85/12/3 + banner Prima Late + Album 54. Pasar Harian +30%, Rotasi +5% XP, stat Orang-orangan +3% Super.
- Bab 6.3-6.6: 6 joran + 4 umpan lengkap, 20 ikan lengkap, berat 4 ukuran, Pity 200/min 150 + Firasat, pengumuman Legenda, larangan masak/jual Legenda, 3 tipe Bubu 6 jam.
- Bab 7: Ternak (3 hewan, kandang Lv1/2, pakan, Tempat Pakan max 3/5, Pakan Jagung, Mood Hujan +10%/5 mnt, Ambil Semua), Kolam breeding (Tanah/Semen/Keramik, Kolam Kakek gratis +10%, instant, akuarium jalan).
- Bab 8: 6 node Nambang + Critical + respawn 4 mnt, 7 bahan mentah + 7 olahan, katalog 80 piece, cap 800, 30 Dekor Berkah, 4 Set lengkap, Akuarium Lv25, Bingkai Album Lv15, Blueprint 3 slot gratis + Like/Galeri/Lomba.
- Bab 9: Dapur Tier 1/2/3, 24 resep, Garam 10 Koin, Daun Pisang, Kualitas Olahan, Warung Player (1 slot, NPC 5-10 mnt, max 5 offline).
- Bab 10.3: Sumber Garam/Daun Pisang/Jerami/Pakan 2 jalur — sebagian tidak ada.
- Bab 11: Album 214 + milestone Bunga + kartu Bagikan.
- Bab 12: Bantu, Kirim Hadiah, Chat, Galeri, cerita RW.
- Bab 13: Gerobak Kaget, Pasar Malam, Event musiman penuh, Kerja Bakti Kilat, Pesanan Tamu.
- Bab 14: MQ1-MQ12, Surat 30, Side 10, Agenda 5, Bundel Kakek 5.
- Bab 15: Login Mingguan, Playtime 5 peti, Peti Bunga, Title permanen.
- Bab 16: Langkah mancing/nambang/hias/surat + hadiah final 100 Koin.
- Bab 17: Hitung sink/faucet/cap terstruktur (tidak ada di kode).
- Bab 18: Alat Bunga (Gembor/Sabit/Bunga, Kapak, Dekor 2 stat), Season Premium.
- Bab 19: Season Pass penuh.
- Bab 20-30: Setting Mode Bantu, banner effects terstruktur, KPI, LiveOps Update Besar, Core Loop terpadu, migrasi version 72.

## 6. Angka Beda

| Item | Di v7.2 | Di Kode | Selisih |
|---|---|---|---|
| Jumlah tanaman | 18 | 6 (`Crops.luau:19-26`) | -12 |
| Jumlah ikan | 20 | 12 (`Fish.luau:20-33`), ID beda | -8, ID semua beda |
| Joran | 6 (gratis s/d 35.000+40 Bambu+20 Batu+10 Ijuk) | 4, 0/500/2.000/6.000 (`Fishing.luau:13-18`) | -2, harga & syarat beda |
| Umpan | 4 (10/25/45/80) | 1 pelet 5 (`Fishing.luau:40`) | -3 |
| Gigitan | 3-6/6-12 dtk, hujan 2x | 3-5 dtk (`Fishing.luau:26-27`), tanpa hujan | -1..-4 dtk |
| Ukuran ikan | 4 (x0,8/x1,0/x1,2/x1,5, 40/40/15/5) | 3 (S/M/L x1,0/x1,2/x1,5) (`Fish.luau:48-52`) | -1 tier, distribusi beda |
| Pity Legenda | 200 (min 150), 0,5%/cast | tidak ada | hilang |
| Bubu | 3 tipe, 6 jam, max 3 | tidak ada | hilang |
| Kolam | 4 (Tanah/Semen/Keramik), breeding 4-6 jam, simpan 10/20/30 | max 4 tapi interval 10 mnt (`Fishing.luau:46`), tier `tanah/batu/taman` | sistem beda total |
| Petak | 6 awal, max 36, n*150, total 96.750 | sama (`Farm.luau:8-15`) | Sesuai |
| Chunk | 14 chunk, 1.500x1,2^n, total 88.790 | sama (`Plots.luau:74`) | Sesuai (rounding 10 sesuai) |
| Super | 5% base, +5% Basah, x2/+50% | sama (`Farm.luau:55-58`) | Sesuai |
| Kualitas | Bagus +10%, Prima +25%, distribusi 50/35/15 dkk | tidak ada, diganti Mutasi | hilang + pelanggaran |
| XP ikan | 10 s/d 600 per ikan (tabel Bab 6.4) | C/U/R/L 3/6/15/40 (`Progression.luau:24`) | beda skala |
| Max piece hias | 800 | 150 (`Decor.luau:221`) | -650 |
| Katalog piece | 80 (30 Berkah) | ~30 | -50, tanpa Berkah |
| Harga jual crop (6 pertama) | sama persis (lihat Bab 5.3) | sama (`Crops.luau:20-25`) | Sesuai |
| Harga ikan contoh | Wader 20, Nila 90, Gurame Raja 2.200 | Wader 8, Nila 10, Arwana 500 (`Fish.luau:21-32`) | semua beda |
| Album | 214 | ~24 | -190 |
| Milestone Album 25% | 10 Bunga | 500 Koin (`Book.luau:34`) | jenis beda |
| Playtime | 5 peti s/d 60 mnt | 3 peti (10/30/60) (`Progression.luau:41-45`) | -2 peti (20/45 mnt) |
| Daily reward | Agenda 150-400 Koin | 40 Koin (`Quests.luau:60`) | -110..-360 |
| Quest | MQ12+Surat30+Side10 | 2 quest | hilang |
| `PlayerData.version` | 72 | 62 (`DataTemplate.luau:9`) | -10 |
| FISH_XP vs tabel | 10-600 | 3-40 | beda |
| Musim hujan partikel | 30/60/90 | 30/80/80 (`Weather.luau:36`) | Deres +20, Petir -10 |
| Gembor | Plastik gratis/ Seng 2.000+10 Kayu / Kuningan 8.000+20 Papan / Bunga 100 Bunga | 1 gembor 300 Koin Lv4 (`Farm.luau:40`) | beda total |
| Kolam Kakek | gratis, breeding 10% cepat | tidak ada (kolam pertama gratis tapi bukan Kakek, tanpa bonus) | khusus hilang |

## 7. Prioritas Perbaikan

- **P0 — Build gagal / langgar Bab 29 (perbaiki dulu):**
  1. Hapus Mutasi + Pelangi + Greenhouse + Rak Pajangan + Lapak dari kode/unlock, ganti Kualitas Panen (Bab 5.4) sebagai pengganti.
  2. Hapus Instant Panen (`instant_grow`) — ganti Instant Kolam 1 Bunga/10 mnt max 30 (Bab 18.5).
  3. Hapus `FTUE_FIRST_MUTATION` — panen pertama hanya Super.
  4. Perbaiki `Pengumuman Durian Prima` vs `banner Mutasi Emas` (sekarang `ANNOUNCE_MIN_GROW_SECONDS=0`, harus Late 2 jam+ untuk Prima).

- **P1 — Angka beda (perbaiki sebelum konten baru):**
  1. Tambah 12 tanaman + 8 ikan v7.2 dengan harga/waktu/XP persis Bab 5.3/6.4; perbaiki harga 12 ikan lama atau hapus dan ganti 20 resmi.
  2. Joran 6 + umpan 4 + gembor/sabit/kapak sesuai Bab 17.5 + XP/quest/agenda sesuai tabel.
  3. Album 214 + milestone Bunga + Playtime 5 peti + `version` 72.
  4. Partikel hujan 30/60/90, cap hias 800, hapus Blueprint gating.

- **P2 — Belum ada / polish:**
  1. Bangun sistem hilang sesuai urutan Core Loop: Nambang → Ternak+Kolam breeding → Dapur 24 + Warung → Skill 16 → Bantu/Hadiah → Gerobak/Pasar/Kerja Bakti → MQ/Surat/Agenda/Side/Bundel → Login/Season → Effects/Animasi/GUI lengkap → KPI/LiveOps.
  2. Perbaiki NPC buys/sells (Garam, hewan, pakan, olahan; hapus jual ikan Kak Fajar; Bang Jali semua barang).
  3. Playtest Checklist Bab 30 + aksesibilitas Mode Bantu (cek di Studio).

Catatan untuk Studio: tempat di Roblox Studio bisa kamu buka (place terhubung ke repo via `default.project.json` + Rojo). Semua yang tidak ada di `src/` ditulis "Tidak ada di kode" di audit ini; kalau kamu mau, aku bisa bantu buka Studio dan cek langsung apakah ada yang sudah dibuat manual di place (misalnya model NPC, Akuarium, Dapur, Warung) — tapi tanpa itu pun audit kode di atas sudah cukup untuk mulai perbaikan.
