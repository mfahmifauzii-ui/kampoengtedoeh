# Roadmap

Tanpa tanggal. Aturan kerja: **satu tahap satu waktu, tunggu "lanjut"**. Tiap tahap: kode, tes di Studio (screenshot), update docs, baru dianggap selesai. Migrasi data wajib uji pakai save lama. Tahap besar dipecah dan dites bertahap.

Desain lengkap di `00_Design_Doc.md`, peta di `Map_Plan.md`.

---

## Sudah selesai (menurut dokumen terakhir)

| Fase | Isi |
|---|---|
| 1–11 | Fondasi, bertani, memancing, tas/toko, hias, pesanan + Buku + level, siang-malam + hujan + audio, monetisasi + analitik, sosial ringan (Mampir, Suka), playtest plan, live-ops plan |
| 12 | Lahan & **Garap** (tanah Terrain, simpan, migrasi) |
| 13 | NPC & dialog (Pak Darmo, Bu Wati, Mas Joko, Mbok Minah); bibit jadi item |
| 14 | Bang Tarno + tawar + kedekatan + skill ⛔ *(dibatalkan; kode dihapus di R1, Bang Tarno tetap sebagai penadah)* |
| 15 | Mbak Arsi + blueprint (**belum dites di Studio**) |
| 16 | Model tanaman + kit GUI ForgeGUI, HUD baru |
| 17 (sebagian) | Bar stamina di HUD ⛔ *(hanya tampilan, tidak ada sistem; dihapus di R1)* |
| R1 | Kuota warung + penadah + pembersihan ✅ dikodekan dan dites di Studio |
| – | Repo git `kampoengtedoeh` (privat), docs dirapikan |

**Dibatalkan:** stamina, istirahat, bonus bangku, tawar-menawar, kedekatan NPC, skill Tawar.
**Ditunda sampai setelah playtest:** peternakan, rumah, mode foto, tujuan bersama, warung pemain/masak, hias v2.

---

## R1 — Pembersihan & kuota warung ✅ selesai dan dites di Studio (14 Nov 2026)

Mengubah desain NPC jual-beli dan membuang kode yang dibatalkan.

**Teruji di Studio (1 pemain, Play):** server start tanpa error baru; save masuk sebagai v8 dengan `npc`/`skills` nil; jual 20 kangkung ke Pak Darmo (+180), sisa ditolak dengan toast; jual sisa ke Bang Tarno 0,7× (+72); panel Pak Darmo dan Bang Tarno tampil benar (sisa kuota, tanpa tombol Tawar); upgrade Kapasitas Warung (kuota 20 → 25); harga beli di Mas Joko, Mbok Minah, Bu Wati, Mbak Arsi tanpa diskon; migrasi v7 → v8 dari save buatan dan pergantian hari pada kuota diuji lewat skrip.
**Belum teruji:** 2+ pemain, HP asli, pergantian hari WIB sungguhan (hanya lewat skrip), save v7 asli dari DataStore, dan penolakan "terlalu jauh" dari NPC.
Perintah dev baru: `!give <item> <n>`, `!sales`, `!quota reset`.

Hasil simulasi (`balance_sim.py`, setelah R1): hari ke-42 Koin tertimbun ±162 ribu (sebelumnya ±205 ribu). **Kuota menurunkan pemasukan sekitar 20–25%, tapi tidak menyelesaikan penimbunan Koin.** Sink sebenarnya tetap harus datang dari chunk lahan (R2), upgrade, dan konten berikutnya.

- Hapus: `AffinityService`, `SkillService`, `Config/Skills`, tawar di `NpcService`/`ShopService`, sapaan berdasar kedekatan, diskon kedekatan, perintah dev `!affinity`, `!skill`, `!skillxp`, tampilan kedekatan di dialog, bar stamina di `HudController` dan atribut `Stamina`.
- Migrasi data: buang `skills` dan data kedekatan (bumpkan versi; uji save lama).
- Tambah: **kuota harian Pak Darmo** per jenis tanaman (20, *asumsi*), `data.sales`; **Bang Tarno** jadi penadah 0,7× tanpa tawar; tampil sisa kuota di panel; upgrade **Kapasitas Warung** (+5/tingkat, *asumsi*) lewat Koin.
- Perbarui `tools/balance_sim.py`: tambah kuota dan penadah.
- Selesai bila: jual sampai kuota habis, lalu jual ke Bang Tarno 0,7×; reset 00:00 WIB; save lama masuk tanpa error.

## R2 — Peta cincin 8–10 pemain + lahan chunk

Perubahan terbesar. Detail di `Map_Plan.md` §1.

- Peta cincin dengan N slot yang bisa diatur; slot kosong tampil "Lahan kosong".
- Lahan dari chunk 16×16 (mulai 3×3, maks 6×6), beli per chunk; `plotSlot` disimpan dan dicoba dipakai lagi.
- Hapus batas jumlah petak tanam; garap, kolam, dan hias memakai daftar chunk.
- Migrasi: save lama (baji besar) dipetakan ke chunk; tidak ada tanah, tanaman, atau hiasan yang hilang. **Siapkan strategi untuk save yang isinya di luar 96×96 baru.**
- Pass "Petak Ekstra" diganti bentuk (lihat Design Doc §16).
- Uji 2+ pemain di Studio (Test → banyak pemain); uji performa dengan 10 lahan.
- Dipecah: R2a peta + slot, R2b chunk + migrasi, R2c kolam/hias/garap di lahan baru.

### R2a — peta cincin + 10 slot ✅ selesai dan dites di Studio (14 Nov 2026)
Cincin **persegi** (bukan lingkaran, karena tanah garap Terrain harus sejajar sumbu): 10 lahan 96×96 di empat sisi, peta 608×608, slot kosong berlabel "Lahan kosong", migrasi v8 → v9. Detail dan screenshot di `Map_Plan.md`. Lahan masih penuh 96×96; chunk menyusul di R2b. Belum teruji: 2+ pemain dan HP asli.

## Gerbang: Playtest #1

Jangan tambah fitur baru sebelum ini. Isi: `Playtest_Plan.md`.
- **Playtest AI persona** (jalan lewat alur dari sudut pandang pemain baru) untuk menemukan kebingungan dan bug. Bukan pengganti uji orang asli (AI tidak bisa menilai "seru").
- **3–5 orang asli** dari target (perempuan 16+), tanpa dijelaskan.
- Keluar dari gerbang dengan daftar perbaikan, bukan daftar fitur.

## R3 — Hadiah, Upgrade, Toko (dari rencana Fase 17 yang masih dipakai)

Urutan: 17.0 → 17.3 → 17.4 → 17.7 → 17.5 → 17.6.
- **17.0 Fondasi GUI:** `UiKit.tabs`, `productCard`, `progressDots`, `notifyDot`, `rewardPopup`; aset ForgeGUI (hemat kredit, cek `assets/gui` dulu): ikon hadiah, kalender, upgrade, titik notifikasi, kartu produk, tab.
- **17.3 Hadiah harian:** kalender 7 kartu di atas Kunjungan Harian yang sudah ada (kumulatif, tanpa hukuman).
- **17.4 Hadiah playtime:** 6 peti/hari, gratis, hitung di server, anti-AFK sederhana.
- **17.7 Upgrade:** `UpgradeService` umum (Tas, Kolam, Lahan, Kapasitas Warung); data `upgrades[id] = tier`; pindahkan logika dari `ShopService`; migrasi dari `backpackTier`, `pond.tier`, `farm.expansions`. Simulasi harga di `balance_sim.py`.
- **17.5 Koleksi:** grid kategori, milestone diklaim manual; migrasi: milestone yang sudah tercapai ditandai "sudah diklaim".
- **17.6 Toko:** satu panel dengan tab samping dan kartu produk (Paket, Koin, Bunga, Hias); ID masih 0 → "Belum tersedia". Tidak ada boost baru tanpa `Monetization_Review.md`.
- Catatan teknis dari fase GUI: skin gambar di atas latar tapi di bawah teks (`ZIndexBehavior = Sibling`, skin `ZIndex = 0`); pakai cache preload agar tombol tidak berkedip; panel dibangun ulang tiap perubahan data, jadi komponen harus murah; HUD memakai `IgnoreGuiInset = true` + `ScreenInsets = DeviceSafeInsets`; cek `Source` di Studio setelah edit karena sinkronisasi file tidak selalu otomatis.

## R4 — QA & poles

Tes di HP asli (sentuhan, joystick vs kartu status, notch, rotasi); semua string lewat `Locale/id.luau`; hook analitik (klaim harian, klaim playtime, upgrade); perbarui docs.

## Playtest #2

Ulangi playtest dengan build R3–R4.

## Setelah playtest (urutan ditentukan oleh data)

Kandidat, bukan komitmen: **mode foto**, **tujuan bersama kampung**, **peternakan ayam**, **warung pemain + masak + buff**, **hadiah teman**, **kucing**, **rumah Tahap A lalu B**, **hias v2** (grid + highlight dulu, undo/redo dan tampak atas belakangan), **tinggal bareng**.

---

## Keputusan terbuka

1. ~~Sungai di peta cincin~~ — selesai di R2a: tidak perlu jembatan tambahan, lahan tersusun di dalam sektor sungai/jalan.
2. **Kuota Pak Darmo:** 20 per jenis cocok? Apakah kuota naik juga per level? (R1, simulasikan)
3. **Harga chunk lahan:** kurva harga dan jumlah chunk awal. (R2b)
4. **Pass Petak Ekstra:** diganti apa? (R2b)
5. **Kartu status vs joystick di HP:** pakai thumbstick Dynamic atau geser kartu ke kanan? (R4, tes di HP)
6. **Peta v4:** apakah 10 slot cukup, atau perlu lebih? (setelah Playtest #1 melihat jumlah pemain sebenarnya)
