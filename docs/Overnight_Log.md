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
