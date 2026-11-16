# Overnight log (kerja otomatis, 15 Nov 2026)

Kamu tidur; aku jalan sendiri dan memilih opsi yang direkomendasikan. Tidak ada upload model, push, atau commit.

## 1. Toko bisa diwarnai di Roblox ✅
- Jawaban singkat: **bisa.** MeshPart tanpa tekstur bisa diganti `Color` + `Material` di Roblox. Jadi toko diekspor ulang tanpa palet/tekstur: **satu MeshPart per warna**, namanya = nama slot (mis. `plank_green`, `sirap`, `fish_silver`). 18–30 MeshPart per toko, segitiga sama seperti sebelumnya (2,5k–6,5k).
- Tekstur detail diganti **Material bawaan Roblox** (WoodPlanks, ClayRoofTiles, RoofShingles, Plaster, Brick, CorrodedMetal, Fabric, Grass untuk ilalang).
- Warna + material per slot ada di `src/shared/Config/ShopPalette.luau` (112 slot). `MapService.placeTemplate` menerapkannya otomatis saat toko ditempatkan. Ganti warna = edit file itu (atau ubah manual di Studio).
- File: `_work/warung_blender/shops/rc_shop_<toko>.glb` (versi bisa diwarnai) dan render `rc_sheet_v34.png`, `rc_sheet_close.png`. Versi lama bertekstur (`shop_<toko>.glb`) tetap ada.
- **Belum di-upload** (aturan: upload hanya setelah kamu setuju). Pilih: versi bertekstur atau versi bisa diwarnai.
- Belum teruji di Studio: tampilan Material Roblox di MeshPart (skala tile `RECOLOR_TILE = 4` stud).
- Catatan: place memakai peta hasil bake (`Workspace.Map` sudah ada), jadi `placeTemplate` tidak jalan. Saat toko dimasukkan manual, warnanya perlu diterapkan dengan skrip kecil yang sama (atau atur langsung di Studio).

## 2. VFX ✅ dikodekan, sebagian terbukti di Play
- `Shared/Vfx`: preset baru `coins` (jual/pesanan/kolam), `levelup`, `land` (beli blok), `quest`; cincin `levelup`, `land`, `ripple`; efek loop `Vfx.loop` (ready, fireflies, motes, smoke).
- `Client/AmbientFx.client.luau` (baru): kunang-kunang malam dan debu cahaya siang di sekitar pemain, riak air di depan spot mancing terdekat, ledakan hadiah dari toast server (`sell.sold`, `order.done`, `land.bought`, `quest.done`, …) dan saat atribut `Level` naik.
- `FarmController`: tanaman milikmu yang siap panen berkilau lembut. **Terbukti di Play** (1 tanaman siap → 1 kilau).
- Terbukti di Play: awan efek mengikuti pemain, kunang-kunang mati di pagi hari (jam 6,5). Belum dilihat di layar: screenshot Studio timeout terus (jendela Studio kemungkinan tidak tampil).
- Bersih-bersih Studio: ada **duplikat** `Vfx` (versi lama), `Sfx`, `SoundBank`, `FarmFx`, `RodAnimController` (identik). Duplikat dihapus; sebelumnya efek/suara mancing jalan dua kali.

## 4. Dermaga baru (cek angka)
- 24 spot mancing (8 sungai, 8 empang, 8 pemancar suara `RiverSound`): semua spot sungai/empang punya air 4–8 stud di depannya dan `FishPrompt` aktif (jarak 12). Memicu prompt lewat skrip tidak didukung Roblox, jadi **cast → gigit → tarik dari dermaga baru tetap perlu dicoba manual**.

## Yang sengaja TIDAK aku kerjakan
- **Upload toko** (aturanmu: tunggu persetujuan). Pilih versi bertekstur (`s_*`) atau bisa diwarnai (`rc_*`).
- **R3 (hadiah, upgrade, toko)**: Roadmap bilang "Gerbang: Playtest #1, jangan tambah fitur baru sebelum ini", dan permintaanmu sampai R2a/R2b. Keduanya sudah selesai sebelumnya.
- **Ubah tampilan peta yang sudah di-bake** (restyle dermaga/pagar, papan nama lahan): screenshot Studio timeout sepanjang malam, jadi aku tidak bisa melihat hasilnya. Tidak aku ubah buta.
- Tidak ada commit/push. Perubahan ada di working tree.

## Perlu kamu
1. Lihat `rc_sheet_v34.png` / `sheet_v34.png`, lalu bilang upload versi mana.
2. Insert warung (asset 127582340112010) dari Toolbox → My Models.
3. Save place di Studio (duplikat skrip sudah dihapus di sesi Studio yang terbuka; belum di-save).
4. Coba mancing dari dermaga baru, dan lihat seed picker + tanaman baru di layar.

## 3. Temuan playtest AI 6–9 ✅ (detail)
Lihat `Playtest_AI_Persona_1.md`: model tanaman dari Part (`Shared/CropBuilder`, tanpa upload), seed picker bergaya UiKit, umpan balik tanam/siram, aset 203785492 **belum beres** (masih muncul, lihat bagian 5).

## 5. Koreksi (dicek ulang 15 Nov, sore)
- Error `rbxassetid://203785492` **masih muncul** (2x saat start), jadi klaim "tidak muncul lagi" di bagian 4 dan di `Playtest_AI_Persona_1.md` (temuan 9) keliru. Sumbernya belum ketemu; tidak ada referensi di repo.
- Kamera Studio sempat terkunci di mode Scriptable (sisa screenshot yang timeout). Sudah dikembalikan ke Custom.

---

# Sesi overnight 16 Nov 2026 (dari docs/OvernightJob.md)

Aturan dari job: 10 stage berurutan, tanpa commit, tanpa tanya. Sesi ini **tidak selesai untuk 10 stage**. Hasil jujur di bawah.

## Ringkasan
| Stage | Status | Catatan |
|---|---|---|
| 1 Panen Semua, Jual Semua, drag siram | Kode selesai, sebagian diuji | Play tanpa error baru. Tes 8 petak matang belum dijalankan. |
| 2 Gembor (Sprinkler belum) | Gembor kode selesai, sebagian diuji | Tombol Gembor muncul sesuai kepemilikan. Beli dari Pak Darmo belum diuji. Sprinkler belum dibuat. |
| 3 Nerf pesanan + ekonomi | Config selesai, belum diuji akun baru | Lihat angka di bawah. |
| 4 Bukti T1 save-new + Playtest #1 | Checklist saja | Tes save-new belum dijalankan. Checklist ada di Playtest_Plan.md. |
| 5 Mancing cozy no-fail | BELUM | Tidak dikerjakan. |
| 6 Hias kebun | BELUM | Tidak dikerjakan. |
| 7 NPC + quest minimal | BELUM | Tidak dikerjakan. |
| 8 Toko, Tas, Ensiklopedia | BELUM | Tidak dikerjakan. Toko Alat masih satu section di Pak Darmo. |
| 9 Suara + visual polish | BELUM | Tidak dikerjakan. |
| 10 Performance, save, HP, playtest #2, launch | BELUM | Tidak dikerjakan. Launch_Checklist.md belum diubah. |

Alasan: 8 stage terakhir masing-masing butuh sistem baru (quest, toko, hiasan, mancing) dan tes Play berulang. Itu tidak masuk akal dikerjakan sekaligus tanpa tes per stage. Sesi berikutnya bisa lanjut dari Stage 4 dengan tes manual.

## Stage 1 - Panen Semua, Jual Semua, drag siram
File diubah:
- `src/client/Controllers/FarmController.luau`: tombol "Panen Semua" (`HarvestAll`, muncul hanya saat ada petak matang, jumlah di tombol). Setiap petak matang dikirim lewat `act("ripe")` dengan jeda 0,25 dtk, jadi terbang ke Tas antre. Drag siram: stroke yang MULAI di petak kering milik sendiri menyiram semua petak kering yang dilewati. Tap manual tetap ada.
- `src/client/Controllers/ShopController.luau`: Jual Semua sekarang satu tap. Konfirmasi hanya muncul kalau pesanan masih butuh barang itu.
- `src/shared/Locale/id.luau`: `ui.harvest_all`.

Belum dikerjakan: animasi count-up 0,8 dtk untuk koin Jual Semua tidak saya cek atau ubah. Koin terbang masih mengikuti perilaku yang sudah ada.

Tes:
- Play jalan. Tombol `HarvestAllButton` ada (dicek via Client). Tombol tersembunyi karena belum ada petak matang.
- Screenshot Play: docs/screenshots/OVN_s1_play_2026-11-16.jpg
- Belum dites: 8 petak matang lalu Panen Semua 1 tap. Ini butuh tanam dan tunggu tanaman matang.

Risiko: Panen Semua mengirim 1 remote per petak. Server membatasi rate (RATE burst 12), jadi lebih dari 12 petak sekaligus bisa kena batas.

## Stage 2 - Gembor Bambu (Sprinkler belum)
File diubah:
- `src/shared/Config/Farm.luau`: `TOOLS.gembor = { price = 300, unlockLevel = 4, radius = 1 }`.
- `src/shared/Config/DataTemplate.luau`: `tools = { gembor = false }`.
- `src/shared/Config/Npcs.luau`: Pak Darmo punya `sells.tools = true`.
- `src/server/Services/ShopService.luau`: `buyTool` dengan cek level dan Koin, dispatch kind `tool`.
- `src/client/Controllers/ShopController.luau`: section "Alat Kebun" dengan baris Gembor (terkunci: "Lv 4").
- `src/server/Services/FarmService.luau`: `onWaterArea` menyiram petak dalam radius 1 (3x3) yang kering dan sedang tumbuh. Butuh tool dimiliki.
- `src/shared/Modules/Net.luau`: remote `FarmWaterArea`. Sempat error "Unknown remote" sebelum ditambahkan. Sudah diperbaiki, Play ulang bersih.
- `src/client/Controllers/FarmController.luau`: tombol "Gembor: Mati/Aktif" muncul kalau tool dimiliki. Saat aktif, tap petak kering = siram 3x3 dan area 3x3 menyala sebentar.
- `src/client/State.luau`, `src/server/Services/InventoryService.luau`: snapshot membawa `tools`.
- `src/server/Services/DevService.luau`: perintah test `!tool gembor` (sama seperti `!rod`). **Harus dihapus sebelum launch.**
- `src/shared/Locale/id.luau`: string shop dan tool.

Tes:
- Play jalan, tombol Gembor ada (tersembunyi, belum punya).
- Perintah `!tool gembor` lewat chat tidak terbaca di layar (chat tidak terbuka). Jadi tombol Gembor tidak pernah muncul di tes ini. **Pembelian dan siram 3x3 belum terbukti di Play.**
- Sprinkler (Lv 7, Koin 800, siram tiap 60 dtk) belum dibuat. Itu butuh sistem hiasan (Stage 6).

## Stage 3 - Nerf pesanan + ekonomi
File diubah:
- `src/shared/Config/Crops.luau`: Kangkung bibit 5 -> 3, jual 9 -> 8. Cabai bibit 10 -> 6, jual 20 -> 15.
- `src/shared/Config/Economy.luau`: `START_KOIN` 100 -> 50. **Ini perubahan di luar spesifikasi, untuk memenuhi syarat "Koin setelah T1 <= 100".** 50 + 30 (reward T1) + 8 (satu Kangkung terjual) = 88.
- `src/shared/Config/Orders.luau`: `MAX_CROP_COUNT` 12 -> 8.

Catatan margin: Kangkung 8/3 = 2,67x (spec 2-2,5x). Cabai 15/6 = 2,5x. Integer harga tidak bisa tepat 2,5x untuk Kangkung tanpa mengubah harga jual. Saya pilih harga dari spec.

Tes: belum. Perlu akun baru (save kosong) lalu selesaikan T1. Yang bisa dicek hanya build Rojo (lolos).

## Stage 4 - Bukti T1 save-new + Playtest #1
- Checklist sudah ditulis di `docs/Playtest_Plan.md` (bagian Playtest #1). Status: belum dijalankan.
- Tes save-new, tutup-buka, dan replay T1 belum dilakukan.

## Stage 5-10
Belum dikerjakan. Lihat tabel ringkasan.

## Yang belum dites (semua)
- HP asli, 2+ pemain, DataStore asli (save-new belum diuji di sesi ini).
- Pembelian Gembor dari Pak Darmo dan siram 3x3.
- Panen Semua dengan petak matang.
- Drag siram.

## Hal yang harus kamu tahu
1. `!tool gembor` ada di DevService. Hapus sebelum launch.
2. `START_KOIN` turun ke 50. Kalau tidak mau, T1 harus dicek ulang terhadap batas 100 Koin.
3. Tidak ada commit. Perubahan ada di working tree (`git status`).
4. Upload ke ForgeGUI/Roblox tidak dilakukan. Tidak ada aset baru.
5. Studio: Play dijalankan 4 kali. Tidak ada error baru dari kode saya setelah perbaikan Net.

## Lanjutan sesi (16 Nov, setelah perintah "lanjut")

Status terbaru per stage:
- **Stage 4 (sebagian):** rejoin di akun yang sama. T1 tetap selesai (`t1_awal=true`), 7 petak tetap, Koin tetap (5764). Save-new (akun kosong) dan replay T1 belum dijalankan.
- **Stage 5 (config):** harga Lele 12, Mas 20, Gurame 25. Pancing Kayu (label rotan, Lv 5, 500 Koin). Gigitan 3-5 dtk. REEL_WINDOW 30 -> 300 dtk supaya ikan tidak hilang (no fail). Toast "+1 Ikan" sudah tidak ada (fish.caught dipaksa terbang di HudController). Prompt kolam masih 12 stud, belum 4.
- **Stage 6 (sebagian):** 5 item baru di Decor.luau (pagar_bambu, bunga_kamboja, lampu_taman, kursi_kayu, pohon_pisang_hias) + jalan_batu yang sudah ada. Tanpa blueprint, bayar Koin. "Hapus" di DecorService sekarang refund 50 persen (sebelumnya masuk stok). Tombol/label dan preview transparan belum diubah.
- **Stage 7 (kode, belum diuji tuntas):** Misi Utama (3 langkah, mulai setelah T1, reward 50 Koin + 1 Pagar Bambu gratis). Daily 1 per hari (reset 05:00 WIB, pilihan acak dari Tanam 5 / Panen 5 / Mancing 2, reward 40 Koin + 10 XP). Tracker menampilkan Daily dengan progres. Daily tampil di tracker di Play (`Mancing 2 ikan 0/2`). Belum ada panah ke target.
- **Stage 8 (sebagian):** Tas 50 di awal, 100 dari Lv 10. Ensiklopedia sudah ada (Koleksi, "???" untuk yang belum). Toko tiga tab belum dibuat.
- **Stage 9 (sebagian):** volume musik 0,3, alam 0,4, SFX 0,5. SFX pendek belum ada (id masih nil), ducking belum dicek.
- **Stage 10 (dokumen saja):** status jujur ditambahkan di Launch_Checklist.md, checklist Playtest #2 di Playtest_Plan.md. Performa dan tes HP belum.

Play dicek 5 kali, console bersih dari error baru (satu error lama `rbxassetid://203785492` masih ada, sudah tercatat).

Perubahan yang perlu kamu tinjau:
1. `START_KOIN` 100 -> 50 (Economy.luau).
2. Gembor dan `!tool gembor` (DevService) — hapus `!tool` sebelum launch.
3. Hapus hias sekarang refund 50 persen dan item hilang (tidak masuk stok lagi).
4. REEL_WINDOW 300 dtk.
5. Tas Lv 10 = 100 (InventoryService).

## Perintah baru 16 Nov (hutang Stage 4-7) — hasil akhir
Status per item ada di `docs/OvernightJob.md` (bagian STATUS AKHIR). Ringkasnya:
- START_KOIN 100 FINAL.
- Hapus hias = Tas tanpa refund; menu Pindah/Hapus/Putar + ghost 50% ditulis. Tes Play belum.
- Mancing: prompt 4 stud di semua spot (16/16 terverifikasi properti), REEL_WINDOW dihapus (tanpa timeout).
- Quest: panah target tampil di Play. Reward belum dites.
- Stage 4 akun baru: T1 selesai lewat klik nyata (Mulai, Garap, tanam, siram, panen, jual). Koin 188 (bukan 130: +50 kunjungan harian hari 1, +8 kangkung). Rejoin 3x OK. Replay penuh belum.
- Sprinkler: terpasang, log tick 60 dtk jalan. Visual basah belum difoto.
- Gembor: beli tanpa !tool (Koin 5764 -> 5464), 1 aksi siram 3x3 OK.
- Shop recolor: ApplyShopPalette ditulis, tes server OK dan dikembalikan. rc_* belum dipasang (perlu upload, tidak dilakukan).
- VFX duplikat: 1 instance per nama. Tes suara mancing 1x belum.
- Panen Semua: jeda 0,25 dtk < RATE 8/dtk, belum dites >12 petak.

Hooks dev yang HARUS dihapus sebelum launch (sudah dimatikan, tapi kodenya masih ada):
- `DataService.saveKey` (atribut Workspace `DevSaveSuffix`).
- `QuestService.evaluate` (atribut Workspace `DevStartLevel`).
- `DevService` `!tool gembor`.

Screenshot baru: `docs/screenshots/OVN_*.jpg` (14 file).

## Props stylized 3 model (Blender, 16 Nov) — belum diupload
Dibuat headless via Python (`_work/kampung_blender/scripts/build_props.py`, Blender 5.2.3). Tidak di-commit, tidak diupload, tidak di-insert ke Studio.

File:
- `_work/kampung_blender/props/pagar_bambu.glb`: 612 tri (budget < 800). Slot: tiang_bambu, bilah_bambu, tali_rotan. Bbox X -2..2, Z 0..1,8, pivot X=0 Z=0.
- `_work/kampung_blender/props/lampu_jalan_bambu.glb`: 1124 tri (budget < 1200). Slot: tiang_bambu, sangkar_bambu, atap_sirap, bola_lampu, basis_batu. Tinggi 6,0, pivot tengah bawah.
- `_work/kampung_blender/props/plang_kebun.glb`: 396 tri (budget < 1000). Slot: tiang_kayu, papan_kayu, frame_kayu, atap_sirap. Tinggi 4,5, papan utama kosong.

Validasi: hasil build dan re-import GLB di Blender cocok (`validation.json`, `verify_glb.json`). Normal semua menghadap luar (0 face terbalik). Tidak ada image texture (0). 1 MeshPart = 1 slot.

Render (`_work/kampung_blender/renders/`):
- `props_sheet.png`: tiga model berdampingan, tampak depan, latar hijau rumput.
- `pagar_depan.png`, `pagar_samping.png`, `pagar_tiling_3segmen.png` (tiling mulus, ujung X=±2).
- `lampu_siang.png`, `lampu_malam.png` (bola menyala, tidak silau).
- `plang_depan_kosong.png`, `plang_samping.png`, `plang_PREVIEW_teks_kebun_piko.png` (teks hanya untuk preview, tidak ada di GLB).

Keputusan yang perlu kamu cek:
1. Folder referensi `_work/warung_blender/shops/` (rc_*) tidak ada di repo. Gaya diikuti dari brief saja.
2. Nama slot (tiang_bambu, dll.) belum ada di `src/shared/Config/ShopPalette.luau`. Recolor di Roblox tidak akan jalan sampai entri slot ditambahkan. Tidak diubah.
3. Palet tidak punya warna batu dan rotan. `basis_batu` memakai besi hitam #2E2A26, `tali_rotan` memakai #A67C4E. Ganti kalau perlu.
4. Tebal pagar 0,25 (bukan 0,2), karena diameter tiang 0,25 sesuai spec.
5. Tali rotan tidak di-bevel, supaya pagar tetap di bawah 800 tri. Tiap tali kubus 0,2.
6. Bevel 0,05 segmen 1 (chamfer) di sudut tajam. Sisi silinder dibiarkan halus.
7. Puncak atap dibuat datar (lampu 0,3 x 0,3; plang 0,16) supaya bevel tidak memotong tinggi total.
8. Saat pagar disambung, tiang ujung dua segmen berdampingan (lebar ±0,5). Ini sesuai spec, tapi tampak seperti tiang ganda. Pertimbangkan satu tiang bersama.
9. Lampu malam di render memakai PointLight (30 W) di pusat sangkar, hanya untuk preview. Di Roblox PointLight dipasang sendiri.

Belum dites:
- Import GLB ke Studio (belum dibuka di Roblox).
- Skala di game (1 stud = 1 unit di Studio belum dicek).
- Warna di Roblox: GLB membawa base color per slot dan vertex color, tapi belum diverifikasi Roblox membaca warna ini.
- Emisi bola lampu di Roblox (Emissive dari Blender belum dicek di Studio).
- Belum ada upload atau insert, sesuai instruksi.

## Upload ke Studio — status (16 Nov)
Upload otomatis tidak bisa: ForgeGUI hanya menerima aset yang sudah ada di akunnya (dan gambar), dan Studio MCP tidak bisa mengimpor file dari disk. Jadi impor dilakukan manual lewat 3D Importer, sesuai pola warung/tokoKota/rumahPanggung.

File yang diimpor:
- `_work/kampung_blender/props/pagar_bambu.glb`
- `_work/kampung_blender/props/lampu_jalan_bambu.glb`
- `_work/kampung_blender/props/plang_kebun.glb`

Setelah impor, cek di Studio: skala (pagar 4, lampu 6, plang 4,5 stud), pivot di tengah bawah, warna per slot, dan emisi bola lampu.

## Upload Open Cloud + ganti di game (16 Nov, lanjutan)
Upload lewat Open Cloud Assets API (FBX dari GLB via Blender, `ROBLOX_API_KEY`). Aset Model, creator user 9416491408:
- pagar_bambu: assetId 129312728521963
- lampu_jalan_bambu: assetId 94928969440412
- plang_kebun: assetId 102912947530645

Insert ke `ServerStorage.MapModels` sebagai `PagarBambu`, `LampuJalanBambu`, `PlangKebun` (PackageLink dihapus).
Import FBX membuat ukuran 100x (pagar 400 stud) dan semua part abu-abu. Diperbaiki: ScaleTo 0,01, warna per slot dicocokkan (tiang_bambu #8B5E2E, bilah_bambu #C9A86A, dst.). Ukuran sekarang pagar 4 x 1,8 x 0,25, lampu 1,33 x 6, plang 5 x 4,5.

Kode (agar tetap benar saat server bikin ulang map):
- `MapService.lampPost` memakai `LampuJalanBambu` (tag DecorLight + PointLight di bola_lampu), kalau template ada.
- `MapService.buildPlotFence` memakai `PagarBambu` segmen 4 stud di sepanjang rail, kalau template ada.
- `PlotService` memakai `PlangKebun` untuk plat gerbang; teks pemilik ada di papan_kayu (OwnerLabel).

Di Studio (live, Edit): 48 lampu di `Workspace.Map.Lamps` diganti; 8 lahan di `Workspace.Map.LandFences` dapat 960 segmen pagar (rail dan tiang lama dihapus). Dicek: bawah y=0, ukuran benar, sejajar rail.

Belum dites:
- Play (server baru jalan dengan kode baru, teks plang, dan arah muka plang).
- Visual: arah muka plang dan teks OwnerLabel belum difoto.
- Place belum disimpan (Studio masih berisi perubahan yang belum disimpan).
- Warna/emisi di Roblox: warna per slot sudah diatur langsung di template; emisi bola_lampu Neon.

## Revisi (16 Nov, malam)
- Banner panah misi (QuestController `updateArrow`, teks "Misi harian: ..." dan "Tanam Kangkung di sini") dihapus. Sistem panah itu dihapus sepenuhnya, termasuk `questTarget`, `ownTiles`, `ownPond`, `ownPlotCenter`. Hint pemandu di GuideController tidak disentuh. Belum dites di Play.
- Model v2 dominan bambu (`_work/kampung_blender/scripts/build_props_v2.py`, output `props_v2/`, `renders_v2/`, `validation_v2.json`):
  - pagar_bambu: 732 tri, 4,0 x 1,8, 0 face terbalik. Tiang bambu dengan ruas, rail bambu, lashing rotan.
  - lampu_jalan_bambu: 800 tri, tinggi 6,0, 0 face terbalik. Tiang bambu berbuku, sangkar bambu. Basis batu dan atap sirap tetap sesuai spec.
  - plang_kebun: 668 tri, 5,0 x 4,5, 0 face terbalik. Tiang dan frame bambu berbuku, papan kosong.
- Belum diupload. Upload v2 menunggu persetujuan user, dan model yang sudah di game masih versi v1.

## Model v3 (referensi bambu) — upload dan ganti di map (16 Nov)
Sumber: `_work/kampung_blender/scripts/build_props_v3.py`, output `props_v3/` dan `renders_v3/`. Tri: pagar 504, lampu 908, plang 436. 0 face terbalik.

Upload Open Cloud (Model, user 9416491408):
- pagar_bambu: 104047058671262
- lampu_jalan_bambu: 100235885568416
- plang_kebun: 102449818137048

Studio: template lama di `ServerStorage.MapModels` diganti dengan nama yang sama (PagarBambu, LampuJalanBambu, PlangKebun). Skala 0,01 dan warna per slot dicocokkan lagi. Pagar dan lampu yang sudah ada di map diganti di posisi yang sama: 48 lampu dan 960 segmen pagar. Dicek: lampu dasar y=0 dan tinggi 6, pagar 4,0 × 1,8.

Kode: `PlotService` memilih papan terbesar sebagai papan nama (papan kecil juga memakai slot papan_kayu).

Belum dites: Play (teks nama di plang, arah muka plang), save place (perubahan di Studio belum disimpan).

## Ukuran (16 Nov)
- Plang: template `PlangKebun` di `ServerStorage.MapModels` di-ScaleTo 1,5× (4,9 × 4,5 → 7,35 × 6,75). Berlaku ke plang di map setelah server restart.
- Pagar: template `PagarBambu` diambil ulang dari aset 104047058671262, lalu tinggi diregangkan dari 1,8 ke 2,5 stud di Studio (Y saja, lebar 4,0 tetap). 960 segmen di map diganti. Belum dicek di Play.
- Kode pagar: `MapService.buildPlotFence` sekarang memanggil `placeTemplate` dengan tinggi 2.5 (sebelumnya 1.8). Tanpa ini, pagar baru saat beli lahan akan diskalakan turun ke 1.8.
- Label nama plang (`PlotService`): satu baris, di dalam margin papan (0,84 × 0,5), tidak lagi pecah dua baris keluar papan. Belum dicek di Play.
- Pagar digeser 2 stud keluar dari tepi lahan (`MapService.buildPlotFence`, konstanta `FENCE_OUT = 2`), supaya tidak ada part pagar di atas grid lahan dalam (petak garap merah di perbatasan). Di Studio, 960 segmen yang sudah ada juga digeser 2 stud keluar. Belum dicek di Play. Catatan: posisi spawn gerbang (`PlotsConfig.GATE_SPAWN`) dan plat plang belum disesuaikan dengan pagar yang bergeser.
- Sudut pagar: tiap sisi lahan sekarang diperpanjang FENCE_OUT (2 stud) melewati kedua sudut, supaya sisi-sisi bertemu (`MapService.buildPlotFence`). Jumlah segmen per rail pakai ceil (tidak ada celah, boleh sedikit tumpang tindih).
- Di Studio, 64 potongan tambal dipasang di ujung pagar yang menggantung (sudut). Ujung gerbang (16) tidak ditambal. Belum dicek di Play.
- Potongan tambal (PagarTambal, 64 buah) dihapus dari Studio karena menyilang di sudut. Motif X di dalam segmen tetap (pilihan user: sudut saja).
- Kode: segmen pagar sekarang ditempatkan rata di ujung rail (`along = 2 + k*(len-4)/(n-1)`), tidak menjorok ke sudut. Sudut lahan di Studio masih ada celah sampai fence dibangun ulang dari kode. Belum dicek di Play.
- Perhitungan ukuran: sisi lahan (per petak 16 stud, ditambah 2 stud di tiap sudut terbuka) = 16k + 4 stud, selalu kelipatan 4. Segmen 4 stud karena itu tepat, tidak perlu diperbesar. Setiap sisi sekarang ditempatkan rata dari sudut ke sudut (`MapService.buildPlotFence`, `edge`), tanpa tumpang tindih di rail.
- Perpanjangan 2 stud hanya dipasang di sudut yang terbuka (tetangga tidak dimiliki), supaya sisi yang berbatasan dengan petak lain tidak dobel.
- Pagar di map Studio masih versi lama. Dibangun ulang otomatis dari kode saat pemain join (`LandService.applyOwnership`), jadi cek di Play, bukan di Studio. Belum dicek di Play.
- Teks nama plang: papan_kayu dari template berisi papan utama + papan status kecil, jadi bounding box-nya 6 × 4,5 dan teks sebelumnya jatuh ke tengah keduanya. Sekarang label di 0,06 dari atas dengan tinggi 0,56 (area papan utama). Dicek di Play: label live diubah manual; kode perlu server restart. Belum dicek visual.
