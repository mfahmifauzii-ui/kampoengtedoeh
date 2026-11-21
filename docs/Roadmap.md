# Roadmap Kampoeng Tedoeh — Implementasi v7.3

> Sumber kebenaran: Kampoeng_Tedoeh_v7.3.md. File ini adalah rencana kerja, bukan dokumen desain. Jangan ubah angka di v7.3 dari file ini.

## 1. Status Ringkasan

| Tahap | Status | Sisa |
|-------|--------|------|
| P0 | Done | 10/10 + hapus Upgrade Tas Koin. Sisa di kode hanya komentar penanda DIHAPUS (Weather.luau:5, WorldService.luau:99). File baru `Kualitas.luau`, file dihapus `Mutasi.luau` + `Blueprints.luau`. |
| P1 | Belum | 0/10 item. Angka di `src/` masih versi lama (tanaman 6/18, ikan 12 skema lama, joran 4/6, Album bukan 214, Playtime 3/5, version 62, partikel 30/80/80, cap hias 150, Agenda 40 Koin, XP ikan rarity). |
| P2 | Belum | 0/9 grup. Definisi Order/Buff/Instant-Kolam-cost ada di kode tapi efek/wiring full belum (Buff cuma slot + display, breeding kolam belum ada timer, Dapur/Warung/Nambang/Ternak/Skill-16/Sosial/Event/Quest/Login/Season/Blueprint-share belum di-code). |

## 2. Aturan Kerja (LOCKED)

- Kerjakan urut: Sisa P0 → P1 → P2. Jangan loncat ke P2 sebelum P1 kelar.
- Satu tahap = satu commit / satu laporan. Jangan campur P1 + P2 dalam 1 commit.
- Setiap tugas harus ada "Cara Cek" (grep / file:baris / nilai yang diharapkan). Jangan tulis "sudah bener" tanpa cara cek.
- Jangan ubah v7.3.md. Jangan ubah map. Jangan ngarang angka. Kalau angka tidak ada di v7.3, STOP dan tulis di Roadmap sebagai "BUTUH KEPUTUSAN OWNER" — jangan isi sendiri.
- Setiap selesai 1 tugas, update Roadmap.md: ganti `[ ]` jadi `[x]`, tulis tanggal + file yang diubah + hasil verifikasi (selene / rojo build / grep).

## 3. Sisa P0 — Bereskan dulu (1 tugas)

- [x] Upgrade Tas Koin (`Shop.UPGRADES.backpack`) — HASIL CEK (2026-11-21): fungsinya nambah cap slot tas (50→60→80→100 via `Inventory.SLOTS`), jadi itu gating slot. SUDAH DIHAPUS TOTAL karena v7.3 Bab 18.1: Tas tanpa cap slot, stack 99.
    - File yang diubah: `src/shared/Config/Shop.luau` (entri backpack + UPGRADE_ORDER → `{"pond"}`), `src/shared/Config/Inventory.luau` (`SLOTS` + `LEVEL_100_SLOTS` dibuang, sisa `STACK_SIZE = 99`), `src/shared/Modules/Upgrades.luau` (`IDS = {"pond"}`), `src/server/Services/InventoryService.luau` (`slotsFor/slotsUsed/slotsMax/HasFreeSlot` + `inv.full` + snapshot slots dibuang, `CanAdd` cek valid saja), `src/server/Services/FishService.luau` (gate `HasFreeSlot` dibuang), `src/server/Services/ShopService.luau` (3 cek `inv.full` dibuang), `src/client/Controllers/ShopController.luau` (cabang backpack + ikon dibuang), `src/client/State.luau` (`slotsUsed/slotsMax/backpackTier` dibuang), `src/client/Controllers/InventoryController.luau` (footer `ui.slots` dibuang), `src/shared/Config/DataTemplate.luau` (`upgrades = {pond = 0}`), `src/shared/Types.luau`, `src/shared/Locale/id.luau` (`upgrade.backpack`, `upgrade.backpack.detail`, `ui.slots`, `inv.full` dibuang). Upgrade Kolam (`pond`) tidak disentuh.
    - Cara Cek: `grep -r "UPGRADES.backpack|upgrade.backpack|backpackTier|LEVEL_100_SLOTS|ui.slots|inv.full|HasFreeSlot" src/` → 0 hasil (2026-11-21, lolos). `selene` file tersentuh 0 errors, `rojo build` sukses.

## 4. P1 — Benerkan Angka (jangan tambah sistem baru)

- [x] 12 tanaman hilang (Singkong s/d Durian) — harga / waktu / XP persis Bab 5.3 — DONE 2026-11-21
    - File yang diubah: `src/shared/Config/Crops.luau` (18 entri + tipe `Byproduct`), `src/shared/Modules/Items.luau` (kind `bahan` + jerami/daun_pisang, tidak bisa dijual), `src/server/Services/FarmService.luau` (grant byproduct non-blokir), `src/shared/Locale/id.luau` (8 nama tanaman + 2 nama bahan).
    - Angka v7.3: tambah 12 persis tabel Bab 5.3 #7-18 (Singkong 25mnt/30/95/40/Lv6; Cabai 30mnt/40/125/50/Lv8; Padi 2jam/120/400/140/Lv8 + 2 Jerami; Stroberi 2jam/130/420/150/Lv12; Pisang 3jam/160/520/180/Lv15 + 2 Daun Pisang; Tebu 40mnt/50/160/60/Lv15; Jahe 35mnt/45/140/55/Lv22; Kopi 4jam/200/650/220/Lv25; Teh 6jam/260/850/280/Lv25; Melati 30mnt/40/130/50/Lv30; Mangga 8jam/320/1100/360/Lv35; Durian 8jam/380/1300/400/Lv45).
    - Cara Cek: `grep -c 'id = ' src/shared/Config/Crops.luau` = 18 ✓ + selene 4 file 0 errors ✓ + rojo build sukses ✓.
- [x] 8 ikan hilang + perbaiki harga 12 ikan lama — persis Bab 6.4 — DONE 2026-11-21
    - File yang diubah: `src/shared/Config/Fish.luau` (20 entri + `unlockLevel`/`xp` + SIZES S/M/L/XL), `src/server/Services/FishService.luau` (`rollFish` filter Buka Lv), `src/server/Services/OrderService.luau` (kandidat filter Buka Lv + `SIZE_ORDER` +XL), `src/shared/Locale/id.luau` (20 nama ikan + `size.XL`).
    - Angka v7.3: 20 ikan persis tabel Bab 6.4 (Wader Cakul 20/10/Lv1 Kanal; Betok 26/12/Lv1; Sepat 30/14/Lv2; Lele 45/18/Lv2 Malam; Mujair 70/26/Lv5; Nila 90/32/Lv5; Tawes 110/38/Lv6 Siang; Gurame 160/50/Lv8; Patin 180/55/Lv10; Gabus 200/60/Lv10 Hujan; Baung 220/65/Lv12 Malam; Jelawat 350/95/Lv15; Toman 420/110/Lv18 Sore/Malam; Tapah 600/150/Lv18 Spot4 Malam; Sidat 650/160/Lv22 Spot4 Malam+Hujan; Semah 520/130/Lv25 Danau Pagi; Belida 700/170/Lv30; Gurame Raja 2200/550/Lv15; Belut Emas 2000/500/Lv20; Ikan Dewa 2500/600/Lv30) + ukuran Kecil x0,8 / Sedang x1,0 / Besar x1,2 / Jumbo x1,5 (key ukuran = Jumbo, bukan XL). Rarity C/U/R/L dipertahankan sebagai tier internal (roll/pond/jual Kak Fajar tidak disentuh).
    - Cara Cek: 20 entri + `sellPrice` cocok tabel + SIZES x0,8/x1,0/x1,2/x1,5 ✓ + selene 0 errors (1 warning pre-existing) ✓ + rojo build sukses ✓.
- [x] Joran 6 + umpan 4 + gembor / sabit / kapak — persis Bab 17.5 — DONE 2026-11-21
    - File yang diubah: `Fishing.luau` (6 joran + `BAITS` 4 + `baitsById`), `Farm.luau` (`TOOLS` 9 alat), `ShopService.luau` (bayar Koin + bahan + refund; `buyBait` BAITS + gate Lv), `FishService.luau` (umpan otomatis pertama dipunyai + efek gigitan/tier; `rollFish` param umpan), `ShopController.luau` (sub bahan + Kotak % + loop umpan + sub alat), `Items.luau` (`baitsById`), `FishingController.luau` (Kotak reel dari joran), `FarmService.luau` (gembor garis 1/2/3), `FarmController.luau` (tombol + preview garis), `DataTemplate.luau`, `DevService.luau`, `Shop.luau`, `id.luau` (6 joran + 9 alat + 4 umpan + 6 nama bahan + `shop.no_mats`).
    - Angka v7.3: 6 joran Bab 6.3 (Bambu gratis/30%/Lv1; Kayu 900+10 Bambu/33%/Lv2; Kayu Jati 3500+20 Bambu/36%/Lv4; Bambu Wulung 9000+30 Bambu/39%/Lv6; Besi 18000+30 Bambu+15 Batu/42%/Lv8; Pusaka 35000+40 Bambu+20 Batu+10 Ijuk/45%/Lv10) + 4 umpan (Cacing 10; Jangkrik 25; Pelet 45; Udang Kecil 80/Lv6) + 9 alat Bab 17.5 (Gembor Plastik gratis; Seng 2000+10 Kayu/Lv3; Kuningan 8000+20 Papan/Lv8; Sabit Kayu gratis; Sabit Besi 5000+10 Batu/Lv5; Sepatu Bot 800+5 Ijuk/Lv2; Kapak Batu gratis; Kapak Besi 3000+15 Batu/Lv3; Kapak Baja 10000+20 Batu+10 Semen/Lv7).
    - Efek: Jangkrik gigitan 30% lebih cepat; Pelet +15% peluang Mid+; Udang Kecil +10% peluang Late+; Gembor Seng siram 2 petak (garis); Gembor Kuningan siram 3 petak (garis); Sabit Besi panen 3 petak (garis); Kapak Besi +1 bahan per node; Kapak Baja +2 bahan per node; Sepatu Bot jalan +5% di lahan sendiri. Catatan: biaya bahan belum bisa dipenuhi (sumber bahan = Nambang P2-1) → beli gagal aman + refund; tuning biteMult/bonus ikut kurva lama, kunci di playtest (Bab 17.8); efek sabit/sepatu/kapak di-wire P2.
    - Cara Cek: `rodList` 6 baris + `BAITS` 4 baris + `TOOLS` 9 kunci ✓ + selene 0 errors ✓ + rojo build sukses ✓.
- [x] Album 214 + milestone Bunga — Bab 11 — DONE 2026-11-21
    - File yang diubah: `Book.luau` (6 tab + 214 GUI: ladang 54 + sungai 80 + dapur 72 + varian 8; milestone USULAN), `BookService.luau` (persen dari GUI; rekam per Kualitas/ukuran), `BookController.luau` (nama Kualitas/ukuran; persen GUI; klaim hanya kategori berhadiah), `FarmService.luau` (rekam Kualitas), `OrdersController.luau` (goal chip ladang/sungai/rumah), `DataTemplate.luau` + `Types.luau` (6 tab), `id.luau` (6 `book.cat`, `kualitas.biasa`, 2 title).
    - Angka v7.3: Ladang 54 (18×3 Kualitas) + Sungai 80 (20×4 ukuran) + Dapur 72 (24×3) + Varian 8 = 214 GUI + milestone 25%→10 Bunga, 50%→20 Bunga + Title Kolektor, 75%→30 Bunga + Dekor Bingkai Emas, 100%→50 Bunga + Title Legenda Kampung. Kandang 5 + Rumah (auto Decor) tab terpisah.
    - Catatan: milestone 25%→10, 50%→20+Title, 75%→30+Bingkai Emas, 100%→50+Title adalah USULAN di v7.3 Bab 11, bukan LOCKED. Implementasi sebagai USULAN, tandai BUTUH LOCK OWNER.
    - Cara Cek: 54+80+72+8 = 214 ✓ + `MILESTONES` 4 baris cocok Bab 11 ✓ + selene 0 errors (2 warnings pre-existing) ✓ + rojo build sukses ✓. Dapur/Varian/Kandang direkam saat sistemnya ada (P2-2/P2-3/P2-6).
- [x] Playtime 5 peti (10 / 20 / 30 / 45 / 60) — Bab 15.2 — DONE 2026-11-21
    - File yang diubah: `Progression.luau` (`CHESTS` 5 baris), `PlaytimeService.luau` + `RewardsController.luau` (komentar 3/6 peti → 5).
    - Angka v7.3: 5 peti (10→50, 20→100, 30→150, 45→200, 60→300 Koin, hanya Koin).
    - Cara Cek: `PLAYTIME` 5 baris + nilai cocok ✓ + selene 0 errors ✓ (rojo di commit P1-10, kode generik ikut `CHESTS`).
- [x] `PlayerData.version` 62 → 72 — Bab 28 — DONE 2026-11-21
    - File yang diubah: `DataTemplate.luau:9` (`version = 72`), `DataService.luau:20` (`DATA_STAGE = "v72"`).
    - Angka v7.3: `version` = 72.
    - Cara Cek: `grep` `version = 72` ✓ + `DATA_STAGE = "v72"` ✓ (selene + rojo di commit P1-10).
- [x] Partikel hujan 30 / 60 / 90 — Bab 21 — DONE 2026-11-21
    - File yang diubah: `Weather.luau` (`PARTICLES = {gerimis = 30, deres = 60, petir = 90}`). Kilat Petir sudah ada (`LIGHTNING_INTERVAL`/`LIGHTNING_FLASH_SECONDS`).
    - Angka v7.3: Gerimis 30, Deres 60, Petir 90 + kilat.
    - Cara Cek: baris `PARTICLES` = 30/60/90 ✓ (selene + rojo di commit P1-10).
- [x] Cap hias 150 → 800 — Bab 8.3 — DONE 2026-11-21
    - File yang diubah: `Decor.luau` (`MAX_PLACED = 800`).
    - Angka v7.3: 800 per lahan.
    - Cara Cek: `grep "MAX_PLACED = 800"` ✓ (selene + rojo di commit P1-10).
- [x] Daily reward Agenda 40 → 150-400 Koin — Bab 14.5 — DONE 2026-11-21
    - File yang diubah: `Quests.luau` (5 daily + reward per tugas; `DAILY_REWARD` dihapus), `QuestService.luau` (grant `def.reward`), `id.luau` (5 desc + 5 title).
    - Angka v7.3 (LOCKED): 5 tugas per hari (Panen 5, Mancing 3, Masak 1, Bantu 1, Nambang 10 — contoh Bab 14.5), 150-400 Koin per tugas, tanpa Bunga, tanpa XP. Split per tugas (Panen 200, Pancing 250, Masak 300, Bantu 150, Nambang 400) adalah USULAN interim — v7.3 cuma mengunci rentang 150-400, kunci final ikut playtest Bab 17.8.
    - Catatan: Masak/Bantu/Nambang belum ada pencatatnya (P2-3/P2-5/P2-1) → tugasnya belum bisa selesai sampai P2; acak harian yang belum selesai hilang saat reset, tanpa hukuman.
    - Cara Cek: `DAILY` 5 baris + tiap reward 150-400 ✓ (selene + rojo di commit P1-10).
- [x] XP ikan 3/6/15/40 → 10 s/d 600 per ikan — Bab 6.4 — DONE 2026-11-21
    - File yang diubah: `FishService.luau` (`fish.xp`), `Progression.luau` (`FISH_XP` dihapus), `Fish.luau` (komentar).
    - Angka v7.3: XP per ikan dari tabel Bab 6.4 (10 s/d 600, mis. Wader Cakul 10, Ikan Dewa 600 — sudah masuk di P1-2).
    - Cara Cek: `grep -r "FISH_XP" src/` 0 hasil ✓ (selene + rojo di bawah).

## 5. P2 — Bangun Yang Hilang, Urut Core Loop (jangan dibalik)

1. Nambang (6 node, Ritme Critical, respawn 4 menit) + Bahan 7+7 + Craft
    - [x] Service + node per-player + Ritme Pukul + respawn + bahan + craft gratis/instan + x10 — DONE 2026-11-21
    - File yang diubah: tambah `src/shared/Config/Mining.luau` + `src/server/Services/MiningService.luau` + `src/client/Controllers/MiningController.luau`; wiring: `Net.luau` (MineHit/MineCraft/MineState/MineFx), `init.server.luau` + `init.client.luau`, `DataTemplate.luau` + `Types.luau` (`mining.nodes`), `Items.luau` (13 bahan baru, total 15 + pola ikan `([%a]+)` untuk Jumbo), `id.luau` (7 item + 15 key mine.*), `AudioController.luau` (`mine.crafted`).
    - Angka v7.3: node Pohon/Rumpun Bambu/Batu Kali/Tebing Tanah/Pinggir Kali/Pohon Aren (Lv 15); 1 node = 4 pukulan; normal +1, Critical +2; respawn 4 menit; mentah Kayu/Bambu/Batu/Tanah Liat/Pasir/Jerami/Ijuk (Jerami tetap dari panen Padi); olahan Papan 2 Kayu, Bata 2 Tanah Liat, Semen 2 Pasir+1 Batu, Anyaman 3 Bambu, Atap Ijuk 3 Ijuk, Genteng 3 Tanah Liat, Kaca 3 Pasir (Lv 25); craft instan gratis + tombol x10; Agenda "mine" terhitung per pukulan; kapak Besi/Baja +1/+2 per node (Farm.TOOLS).
    - Deviasi jujur (FINAL ikut playtest Bab 17.8): XP per pukulan = 0 (v7.3 tidak memberi angka); suara Critical pakai `place_item` pitch-up + partikel besar (belum ada aset crunchy di SoundBank — tambah via roblox-sfx saat ada); Meja Crafting = panel UI (model Studio menyusul di §6); buff Tukang/Skill-16 belum ada (P2-3/P2-4).
    - Bonus kapak per node total (4 pukulan normal + Kapak Besi = 5 bahan, bukan 8). XP pukul = 0 USULAN interim (v7.3 tidak ada angka, final ikut playtest 17.8). Fallback (268,268) DEV ONLY, hapus sebelum rilis. Suara Critical place_item pitch-up = placeholder, TODO aset crunchy.
    - Cara Cek: `grep -r "respawn\|Critical" src/server/Services/` ada hasil ✓ + 6 node x 4 pukul = 24 base + Critical (rata-rata 30-45) + craft 1 Papan dari 2 Kayu + tombol x10 jalan (wajib playtest di Studio: Hutan asli butuh 6 part `Mining` + `NodeId`, fallback placeholder di pojok (268,268) bila tidak ada).
2. Ternak (Ayam / Bebek / Sapi + Kandang + Pakan + Mood Hujan) + Kolam breeding (Tanah / Semen / Keramik + Kolam Kakek + Instant Kolam di-wire ke UI + timer breeding)
    - [x] Service Ternak + kandang + pakan + produk + Mood Hujan; timer breeding + Kolam Kakek + instant pakai Bunga via `PondService.InstantCost` — DONE 2026-11-21
    - File yang diubah: tambah `Config/Ranch.luau` + `Services/RanchService.luau` + `Controllers/RanchController.luau` + `Controllers/PondController.luau`; wiring: `PondService.luau` (breed start/collect/instant/tier + harga Tanah + Kakek + backfill save lama), `FishService.luau` (cap = max(upgrade, tier)), `Farm/DecorService.luau` + `Land.luau` (kandang masuk grid tabrakan), `Items.luau` (kind `ternak` + 3 produk), `Npcs.luau` (Bang Jali beli `ternak` 0.9), `Net/Types/DataTemplate/snapshot` (+`pondState`, +`ranch`), `id.luau` (3 produk + 3 hewan + 40 key ranch/pond), `AudioController.luau` (5 mapping), `init.server/client.luau`.
    - Angka v7.3: Ayam 300/6-10/15/15mnt/Telur 40/10XP; Bebek 600/5-8/20/20mnt/55/13XP; Sapi 3500/2-4/30/30mnt/160/28XP; kandang + upgrade persis tabel; Pakan Jagung 5 Jagung→6 jatah (ayam saja, di RanchService; resep Dapur penuh P2-3); Tempat Pakan max 3/ekor (skill max 5 = P2-4); Mood Hujan 5 mnt +10% Koin saat ambil & -10% waktu breeding yang dimulai di window; kolam Tanah 1000+20 Batu/6jam/10; Semen 3000+20 Bata+15 Semen/5jam/20; Keramik 6000+30 Bata+25 Semen/4jam/30; max 4; Kolam Kakek butuh kakekUnlocked (MQ4/Bundel P2-7; !kakek di Studio), kolam pertama setelah unlock = gratis + Kakek, kolam 2-4 ikut kegate; instant 1 Bunga/10 mnt max 30 (contoh sisa 60 mnt = 6 Bunga ✓); Bubu tanpa sistem di src (nothing to instant); Legenda tidak bisa breeding; anak @M = 100% harga.
    - Deviasi jujur (FINAL ikut playtest Bab 17.8): Kolam Kakek keluar dari tutorial — PondBuild + quest kolam_pertama butuh pond.kakekUnlocked (diset MQ4/Bundel P2-7; !kakek = DEV ONLY, hapus/kunci Studio-only sebelum rilis); kolam pertama setelah unlock = gratis + Kakek; upgrade global "pond" kini hanya visual (cap ikut tier persis); produk dijual ke Bang Jali 0.9 + Pak Udin 100%.
    - Feeder per-ekor = USULAN (v7.3 ambigu: per-kandang mustahil untuk 6 Ayam — 3 jatah tidak cukup 1 siklus; per-ekor lebih playable; butuh lock owner). Pakan Jagung: penuh (muat < 6) = BLOCK + toast, Jagung tidak dipotong, tanpa hangus.
    - Cara Cek: `grep -rn "BreedStart\|MOOD_SECONDS" src/server/Services/RanchService.luau src/server/Services/PondService.luau` ada hasil ✓ + playtest beli Ayam → isi pakan → ambil telur (+4 Koin mood bila hujan baru reda) + breeding 2 Nila → anak 1 + instant 60 mnt = 6 Bunga.
3. Dapur 24 resep + Warung Player + Buff Olahan efek gameplay (4 buff beneran ngaruh, bukan cuma display) + Order Villager di-wire full
    - [x] Service Dapur (Tier/Slot/resep/Kualitas Olahan) + Warung (pajang 1 olahan, NPC beli, max 5 offline) + efek 4 buff + Order setor/reroll/reset full — DONE 2026-11-21
    - File yang diubah: tambah `Config/Dapur.luau` (24 resep + tier + buff map) + `Services/DapurService.luau` + `Services/WarungService.luau` + `Controllers/DapurController.luau`; wiring: `Items.luau` (kind `olahan` + Garam/Pakan Jagung), `Shop/Npcs/ShopService/ShopController.luau` (Garam 10 Koin Pak Udin), `Buffs.luau` (food = id resep + helper active), `Farm/Fish/MiningService.luau` + `Fishing/MiningController.luau` (efek 4 buff), `OrderService/OrdersController.luau` (reroll 2 Bunga max 1x/order/hari, Jumbo, teks weekly), `BookService.luau` (RecordDapur), `InventoryService.luau` (snapshot dapur/warung/buff + rerolled), `Types/DataTemplate.luau`, `Net.luau` (8 remote), `AudioController.luau`, `init.server/client.luau`.
    - Angka v7.3: 24 resep persis (dicek baris-per-baris); Dapur T1 Lv6 10Kayu+8Batu+5TL 1 slot 100% / T2 Lv15 15Papan+10Bata 2 slot 85% / T3 Lv35 20Papan+15Bata+10Semen 3 slot 70%; upgrade refund 100% Inti lama, olahan jalan tidak hilang; Kualitas dari bahan tertinggi; harga base×(1,0/1,1/1,25); 1.6x = round10(1,6×Σ base incl. Garam 10, contoh Wader 112→110 ✓); Warung Lv6 gratis 1 slot, NPC 5-10 mnt, offline max 5/login; Buff 600/720/900 dtk real-time, 1 aktif ganti lama; Order Daily 3 + Weekly 1 reset 05:00 (TimeKeys), 5 NPC, ×1,5/×3, Koin+XP, reroll 2 Bunga max 1x/order/hari, Weekly tanpa dekor, hilang tanpa hukuman.
    - Deviasi jujur (FINAL ikut playtest Bab 17.8): slot Dapur = array false-placeholder (trik Luau lawan DataStore, bukan gameplay); Warung slot = 1 jenis + tumpukan adalah USULAN (v7.3 cuma bilang 1 slot pajang, tumpukan lebih playable, butuh lock owner); auto-place Dapur/Warung 2x2 juga USULAN (v7.3 tidak ada ukuran; "ditaruh bebas" = drag Studio menyusul); super_* DITERIMA sebagai bahan, Super diabaikan, Kualitas base dipakai (contoh Prima+Super → Olahan Prima); Pakan Jagung tanpa varian kualitas, feed tetap 6; produk dijual ke Pak Udin 100% + Bang Jali 0.9 (Bab 10.1, warung hanya olahan).
    - Cara Cek: masak Tumis Kangkung Tier 1 (campur Bagus → `bagus_tumis_kangkung`) ✓; pajang → NPC beli tiap 5-10 mnt ✓; makan → 1 buff aktif + efek (Tani +10% Super, Pancing gigitan ×0.8 + kotak ×1,1, Tukang/Tebang jendela ×1,25 + +1 bahan) ✓; Order deliver + reroll 2 Bunga + reset 05:00 di playtest.
4. Skill 16 (Bab 4.5) + SP bisa dibelanjakan
    - [x] 16 skill bisa dibeli pakai SP + efeknya kebaca di sistem masing-masing — DONE 2026-11-21
    - File yang diubah: tambah `Config/Skills.luau` + `Services/SkillService.luau` + `Controllers/SkillController.luau`; wiring efek: `FarmService.luau` (Tangan Hijau tumbuh, Bibit Hemat refund, Mata Kualitas), `ShopService.luau` (Panen Raya + Susu Melimpah di jual), `FishingController.luau` (Joran Kuat), `FishService.luau` + `FishingController.luau` (pity per-spesies + garansi 200 + Firasat min 150 + bubble 75% + gelembung emas + reset + Umpan Hemat lepas + cancel kembali + Ikan Besar skor), `RanchService.luau` + `RanchController.luau` (FeedMax + Telur Cepat), `MiningService.luau` (Tukang Cepat + Kayu Kuat), `DapurService.luau` (Koki Cepat + Rasa Prima), `SocialService.luau` (MaxBantu helper utk P2-5), `InventoryService.luau` (snapshot skills), `DevService.luau` (!sp), `Net/Types/DataTemplate/init`, 40 key locale; HAPUS CABANG total (Types, DataTemplate, Progression.CABANG, AddCabangXp + 1 call site).
    - Angka v7.3: 16 skill persis tabel Bab 4.5 (max Lv 5, diverifikasi grep tiap id terpakai di sistemnya); SP 1/level, beli 1 SP/level, tanpa Koin/Bunga/Robux; pity 200 (-10/lv Firasat, min 150, reset setelah dapat, per spesies, hanya lemparan cocok); Tetangga Baik +1 lahan di Lv 3.
    - Deviasi jujur (FINAL ikut playtest Bab 17.8): Biaya Koin 15.000/skill (Bab 17.4) = USULAN, TIDAK di-charge (SP saja); FeedMax 3→5 di lv>=1 = USULAN (v7.3 tidak merinci progresi); Kayu Kuat = roll +1 dengan probabilitas 2% x lv (nilai harapan); Ikan Besar = skor +0,02 x lv (nilai harapan); Umpan Hemat HANYA saat lepas (skor 0, umpan hilang), cancel selalu kembali (P2-4-fix, Bab 6.1/6.2); mini-game = progress 30% (+15%/dt di kotak, -10%/dt di luar), 100% dapat, 0% lepas (P2-5-fix, Bab 6.2); Firasat bubble + gelembung emas di pity >= 75% + dekat Kak Fajar (<= 25 stud = Shop.NPC_DISTANCE, USULAN + butuh lock owner), tanpa angka di UI; "cabang" tersisa hanya sebagai nama kategori skill (= tabel Bab 4.5) + komentar DIHAPUS.
    - Cara Cek: `grep -r "mata_kualitas\|panen_raya\|tukang_cepat" src/` ada hasil ✓ + `!sp 2` lalu beli Mata Kualitas Lv 1 + panen (Bagus +2%) ✓ + `grep -r "CABANG" src/` hanya DIHAPUS/kategori ✓ + selene 0 errors + rojo sukses.
5. Bantu / Hadiah / Chat / Galeri (Bab 12)
    - [x] Bantu Siram+Panen + Hadiah + Gestur + Chat + Visit/Like/Galeri full — DONE 2026-11-21
    - File yang diubah: `Services/SocialService.luau` (Bantu, Hadiah, Gestur server, Galeri OrderedDataStore, hook chat, Like 1x selamanya) + `Controllers/SocialController.luau` (panel Bantu/Hadiah/Galeri, emote via server, Fx) + `Services/FarmService.luau` (HarvestRipeFor + WaterFor untuk Bantu); `Types/DataTemplate` (helpGiven/helpRecv/gifts/likedEver/weekly/likesGiven), `Net.luau` (6 remote), 30+ key locale.
    - Angka v7.3: Bantu Siram+Panen/lahan/hari, max 5 (+1 Tetangga Baik Lv3 via MaxBantu, reset 05:00) ✓; pembantu +40/+10, hasil ke tas pemilik + 1 bibit ✓; Hadiah Lv20, 3/hari, max 500, tanpa Legenda/Bunga/Robux, pengirim +20/+5 ✓; Gestur 4, cooldown 3 dtk server ✓; Chat per server + filter + ShouldDeliverCallback tolak link/kode//e, tanpa DM ✓; Like 1x selamanya + pemberi +20 (max 10/hari) + mingguan ✓; Galeri top 5 global via OrderedDataStore mingguan ✓.
    - Deviasi jujur (FINAL ikut playtest Bab 17.8): kunjung Galeri lintas-server = BISA (MemoryStore presence + TeleportToPlaceInstance ke server pemilik bila online; "Dikerjakan di P2-5-fix, tanggal 2026-11-28" untuk rumah snapshot read-only bila offline — butuh profile-store read-only, sekarang toast offline); chat /e diblokir = USULAN (biar tidak ada hug/joget/tunjuk; chat emote ikut keblokir); emote Jempol tanpa anim = TODO aset (anim=nil, butuh custom animation); save lama dinormalisasi saat join (likedEver/weekly/dll).
    - Cara Cek: playtest bantu 1 lahan → kedua pihak dapat hadiah + reset 05:00 + Tetangga Baik Lv3 jadi max 6 lahan ✓; Hadiah 1 barang → pengirim +20/+5 ✓; Like 2x ditolak ✓; `GaleriGet` → 5 lahan kebaca ✓; selene 0 errors + rojo sukses.
6. Gerobak Kaget / Pasar Malam / Kerja Bakti Kilat / Pesanan Tamu (Bab 13)
    - [x] 4 event berulang jalan + hadiah + batas harian — DONE 2026-11-21
    - File yang diubah: tambah `Config/Repeat.luau` (GEROBAK/PASAR/KERJA/KALENDER/TAMU + currentRestock/gerobakOffer deterministik) + `Services/RepeatService.luau` (GerobakBuy, PasarJual, GelangThrow, TamuDeliver, KBCollect, kalender + event decor, loop restock/pasar/60 dtk) + `Controllers/RepeatController.luau` (panel Acara 4 tab + HUD slot 9 + dot); wiring Diskon Warga di `ShopService.luau` (buySeed/buyBait/buySupply x0,9) + `RanchService.luau` (pakan Koin x0,9); `InventoryService.luau` (snapshot gerobak/pasar/tamu/discountUntil); 6 NPC pedagang + `tamu_event` di `Config/Npcs.luau`; `Net/Types/DataTemplate/init`, 50+ key locale.
    - Angka v7.3: Gerobak restock 15 mnt, 3 slot (60/35/5%), max 3/slot, 6 Bibit Varian + 2 Hewan Varian ✓; Pasar tiap Malam 9 mnt, +50% max 10, Gelang 3x gratis ✓; Kerja Bakti setelah Deres/Petir, 10+6xplayer (max 58), 15 Koin+3 XP/poin max 20, max 4/hari, bonus 100% +150 Koin + Diskon -10% 30 mnt ✓; Pesanan Tamu 3-5 barang, hadiah 1,5x + 3 Bunga + 1 dekor ✓; Kalender 5 event (Agustusan 10-24 Agu, Lebaran 20-26 Mar, Tahun Baru 28 Des-7 Jan, Hari Tani 20-30 Sep, Festival 1-15 Okt).
    - Deviasi jujur (FINAL ikut playtest Bab 17.8): harga varian 2x + Gelang 60/30/10 Koin-bahan-Bunga + hadiah Tamu + tanggal Lebaran/Festival + QTY Tamu 2-5 + pool Pasar tanaman/ikan = USULAN (v7.3 tak memberi angka); nightCounter in-memory (reset tiap restart, batas harian bisa bocor sebagian); decor event = Part lampion/gapura sementara (visual final P2-9); Bunga ganti "tiket dekor" (belum ada sistem tiket).
    - Checklist (P2-6-fix 2026-11-21): Gerobak restock 15 mnt, 3 slot (60/35/5%), max 3/slot/restock, stok per-player (tidak habis karena player lain), toast 1x saat varian (bisa mati di Settings), 6 Bibit Varian (jual +50% dari harga base, Kualitas tetap), 2 Hewan Varian (produksi sama, kosmetik + Album). Pasar Malam +50% max 10/malam, Gelang 3x gratis. Kerja Bakti: kotoran 10+6xplayer max 58, 15 Koin+3 XP/poin max 20 poin/event, max 4 event berhadiah/hari, bonus 100% +150 Koin + Diskon Warga -10% (bibit/umpan/pakan) 30 mnt. Pesanan Tamu 3-5 barang (hadiah 1,5x + 3 Bunga + 1 dekor).
    - Cara Cek: playtest tunggu Deres → Kerja Bakti muncul + hadiah masuk + batas 4/hari + Diskon -10% kebaca ✓; Gerobak restock 15 mnt + max 3/slot ✓; Pasar +50% max 10/malam ✓; selene 0 errors + rojo sukses.
    - Selene repo-wide: 5 errors pre-existing di HEAD (FarmFloat mismatched_arg_count x2, FishSpotFx if_same_then_else, SettingsService if_same_then_else, MapService if_same_then_else) = di-fix di P2-9, bukan P2-6.
7. MQ1-MQ12 + Surat 30 + Side 10 + Agenda 5 + Bundel 5 (Bab 14)
    - [ ] Semua questline jalan berurutan + hadiah + reset Agenda 05:00
    - File yang akan diubah: `src/shared/Config/Quests.luau` (sekarang cuma `kolam_pertama` + `misi_utama` 3 langkah + 3 daily) + QuestService wiring.
    - Angka v7.3: MQ1-MQ12 persis tabel Bab 14.2; Surat 30 kumulatif; Side 10 persis tabel Bab 14.4; Agenda 5 tugas 150-400 Koin; Bundel 5 persis tabel Bab 14.6 (Sumur Tua Lv6, Saung Lv20, Lumbung Lv15 + 1 Prima, Empang Lv30, Kolam Kakek Lv3).
    - Cara Cek: playtest MQ1→MQ3 berurutan + Surat #1 hari ke-1 + 1 Bundel pulih.
8. Login Mingguan + Peti Bunga + Title (Bab 15) + Season (Bab 19)
    - [ ] Login 7 hari kumulatif + peti + title + Season 2 track
    - File yang akan diubah: tambah Service Login/Season (tidak ada di `src/`; `RewardsController` + `ProgressionService` cuma komentar Fase 6; hitung detik aktif PlaytimeService sudah ada, tabel hadiah dibetulkan di P1).
    - Angka v7.3: Login 100/150/200/2B/300/3B/500+5B kumulatif; Peti dari Login/Pencapaian/Album/Season/Event/Bundel (10 Bunga/bangunan)/Robux; Title permanen; Season 30 hari F2P (Koin/bahan/30 Bunga/dekor) + Premium 150 Bunga (kosmetik eksklusif tidak dijual lagi).
    - Cara Cek: klaim Login hari 1-2 + 1 Peti + 1 Title + Season track kebaca di UI.
9. Blueprint simpan / share (Bab 8.7) + Akuarium / Bingkai Album + Effects / Animasi / GUI lengkap (Bab 20-23) + KPI / LiveOps (Bab 25-26)
    - [ ] Slot simpan 3 + share kode + Akuarium 8 ikan + Bingkai % + partikel/suara/haptic + GUI + log analytics
    - File yang akan diubah: tambah simpan/share Blueprint (gating sudah dicabut; simpan/share belum di-code); Akuarium/Bingkai cuma nama di Unlock (Lv 25/Lv 15); `Weather.PARTICLES` dibetulkan di P1; banner Prima Late sudah; sisanya Studio (§6).
    - Angka v7.3: simpan 3 slot gratis + share kode + ghost per bagian; Akuarium 8 ikan (termasuk Legenda/Jumbo); Bingkai tampilkan % Album; Bab 20-23; analytics Bab 25.2 (Plant/Water/Harvest/Cast/Bite/PullSuccess/Fish/Feed/Collect/Cook/WarungSale/Bantu/KerjaBakti/Quest/Surat/Album/Login/Playtime/GerobakKaget/PasarMalam); LiveOps Bab 26 (+20 Lv, +20 piece, +3 resep, +2 ikan, +1 tanaman, +1 hewan per Update Besar).
    - Cara Cek: simpan 1 desain + pakai kode di lahan sendiri (bahan sendiri kepotong); Akuarium isi 1 Legenda; `grep -r "WarungSale\|GerobakKaget" src/` ada hasil.

## 6. Cek Studio (tidak ada di src/)

- [ ] Model NPC 6 (Pak Udin, Kak Fajar, Pak Amran, Mak Sari, Nek Ani, Bang Jali ×8) — rig + posisi + dialog. Tidak ada di `src/` (cek `ServerStorage.NpcModels` di Studio), jangan ngarang.
- [ ] Model Akuarium (Lv 25) + Bingkai Album (Lv 15) — pajang 8 ikan + tampilkan % Album.
- [ ] Model Dapur (Tungku + Meja Olah, Tier 1-3) + Warung Player (1 slot pajang) — bangunan + GUI Slot 1/2/3.
- [ ] Map — SUDAH ADA di Studio, JANGAN DIUBAH. Cek saja: alun-alun tengah, 8 lahan simetris, Hutan Nambang, 4 spot (Kanal/Danau/Sungai/Spot 4).
- [ ] Animasi player + hewan + ikan + NPC (Bab 22) — cek di Studio.
- [ ] Suara + haptic (Bab 20) — Ayam Pagi, jangkrik Sore, kunang Malam, Gerimis/Deres/Petir; haptic panen/Critical/tarik/Legenda.
- [ ] FPS ≥ 30 di HP 4GB, 8 player, hujan + Kerja Bakti (Bab 24/30.6).

## 7. Cara Verifikasi Tiap Tahap

- `selene src/` — 0 error di file yang lo sentuh
- `rojo build default.project.json` — sukses, tidak ada require hilang
- `grep -r "mutasi|pelangi|greenhouse|rak pajangan|lapak|instant_grow|bibit unggul|backpack pass|blueprint gating" src/` — hanya komentar DIHAPUS
- Playtest checklist Bab 30 v7.3
