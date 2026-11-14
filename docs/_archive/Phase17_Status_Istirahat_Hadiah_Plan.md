# Fase 17 — Status pemain, Istirahat, Hadiah, Hias grid, Toko & Upgrade (rencana)

**Status:** rencana, **belum dikodekan**. Semua angka di bawah adalah **asumsi saya**; ubah sebelum kita mulai kode. Prinsip tetap: cozy, tanpa fail state, server-authoritative, HP landscape dulu.

**Titik awal (sudah ada, dites di Studio):** kit GUI bambu ForgeGUI (panel, tombol, pita judul, badge tutup, kartu baris, chip, plate bulat) terpasang lewat `Config/UiAssets.luau` dan `client/UiKit.luau`; HUD baru (Koin + Bunga di atas, kartu status kiri bawah, dock bawah tengah, menu kanan atas); **bar stamina di HUD sudah ada tapi belum ada sistemnya** (membaca atribut pemain `Stamina` / `StaminaMax`, default 100/100).

---

## 0. Ringkasan sub-fase

| # | Sub-fase | Isi singkat | Butuh server baru? | Perkiraan | Risiko |
|---|---|---|---|---|---|
| 17.0 | Fondasi GUI | komponen UiKit baru: tab, kartu produk, titik progres, titik notifikasi, popup klaim | tidak | kecil | rendah |
| 17.1 | Status & Istirahat | sistem stamina + mode istirahat + kartu status hidup | ya (`StaminaService`) | sedang | **sedang** (menyentuh semua aksi tani) |
| 17.2 | Hias lahan v2 | toolbar + grid item, kotak grid di peta, highlight hover, undo/redo, tampak atas | sedikit (undo) | **besar** | sedang |
| 17.3 | Hadiah harian | kalender 7 hari + streak | ya | kecil | rendah |
| 17.4 | Hadiah playtime | hadiah bertimer per sesi | ya | kecil | rendah |
| 17.5 | Hadiah koleksi | Koleksi jadi grid + klaim milestone | ya (ubah auto-beri jadi klaim) | sedang | rendah |
| 17.6 | Toko | toko ala referensi (tab samping + kartu) untuk Robux/hiasan/boost | sedikit | sedang | sedang (monetisasi) |
| 17.7 | Upgrade | daftar upgrade dengan titik progres, efek sebelum→sesudah, tombol beli | ya (`UpgradeService`) | sedang | sedang (ekonomi) |
| 17.8 | Poles & QA | tes di HP asli, string Locale, simulasi balance, update docs | tidak | kecil | rendah |

**Urutan yang disarankan:** 17.0 → 17.1 → 17.3 → 17.4 → 17.7 → 17.5 → 17.6 → 17.2 → 17.8.
Alasan: stamina (17.1) dan upgrade (17.7) saling bergantung angka, jadi stamina dulu; hadiah harian/playtime murah dan langsung terasa; hias lahan paling besar, jadi dikerjakan setelah komponen GUI matang. Boleh diubah: hias lahan bisa dimajukan kalau itu prioritasmu.

Aturan kerja tiap sub-fase (sama seperti fase sebelumnya): satu sub-fase satu waktu, tunggu "lanjut"; kode + tes di Studio + screenshot; baru dianggap selesai; dokumen ini ikut diperbarui.

---

## 17.0 Fondasi GUI (dikerjakan sebelum sub-fase lain)

Tambahan di `client/UiKit.luau` supaya semua panel baru konsisten:
- `UiKit.tabs(parent, tabs, onSelect)`: tab samping (toko) dan tab atas (hias, koleksi). Tab aktif = tombol hijau, lainnya krem.
- `UiKit.productCard(...)`: kartu persegi (ikon besar, nama, deskripsi, harga, label miring "Terlaris"/"Baru").
- `UiKit.progressDots(n, max)`: deretan lingkaran kecil terisi (untuk Upgrade).
- `UiKit.notifyDot(button)`: titik merah "!" di pojok tombol HUD (hadiah siap diklaim).
- `UiKit.rewardPopup(list)`: popup kecil "Kamu dapat: ..." setelah klaim (satu-satunya popup; hanya muncul setelah pemain menekan klaim).
- Aset ForgeGUI yang perlu dibuat (satu per satu, hemat kredit, cek `assets/gui` dulu): **ikon stamina** (daun/petir), **ikon hadiah/peti** (3 ukuran), **ikon kalender**, **ikon upgrade** (panah naik), **titik notifikasi**, **kartu produk persegi**, **tab bulat/persegi**, **tekstur grid** (garis tipis transparan untuk hias lahan).

## 17.1 Status pemain & Istirahat

**Tujuan:** pemain tidak bisa bertani terus-menerus; ada ritme kerja → istirahat. Tanpa fail state: stamina habis hanya berarti "capek", bukan hukuman.

**Kartu status (sudah dibuat):** foto avatar, bintang level, nama, bar XP, bar stamina. Yang tersisa: efek kecil saat stamina rendah (bar berdenyut di bawah 20%), ikon stamina dari ForgeGUI.

**Aturan stamina (asumsi):**
| Hal | Nilai |
|---|---|
| Stamina maks awal | 100 (naik lewat Upgrade 17.7: +10 per tingkat) |
| Biaya aksi | garap 4, tanam 2, siram 1, panen 2, memancing 3 per lempar, pasang hiasan 0 |
| Pulih saat berdiri/jalan | +1 tiap 6 detik |
| Pulih saat **istirahat** | +1 tiap 1,5 detik (≈ 100 dalam 2,5 menit) |
| Stamina 0 | aksi tani ditolak server dengan pesan ramah "Kamu capek. Istirahat dulu ya."; jalan, ngobrol, jual-beli, hias tetap bisa |
| Offline | pulih penuh setelah 20 menit offline (dihitung dari `staminaAt`) |

**Mode istirahat:**
- Tombol **Istirahat** muncul di kartu status saat stamina < 100 (atau lewat bangku/rumah). Pemain duduk (animasi R15 duduk) sampai bergerak atau menekan lagi.
- **Bangku hiasan** (`Config/Decor`) dan **rumah panggung** memberi bonus: pulih 1,5× kalau istirahat di dekat bangku milik sendiri. (Insentif memasang bangku; bangku sudah ada di katalog.)
- Malam hari (`DayPhase = malam`): istirahat di rumah memulihkan 2× — menyambung siklus hari yang sudah ada di `WorldService`.

**Teknis:**
- `Config/Stamina.luau` (semua angka), `server/Services/StaminaService.luau`: menyimpan `data.stamina = { value, at }` (nilai + timestamp, pulih dihitung malas saat dibaca, tidak ada loop per pemain), memasang atribut `Stamina` / `StaminaMax` ke pemain, dan menyediakan `StaminaService.Spend(player, cost): boolean`.
- Semua service aksi memanggil `Spend` **sebelum** mengubah data: `FarmService` (garap/tanam/siram/panen), `FishService` (lempar), `PondService` bila perlu. Validasi tetap di server; klien hanya menampilkan.
- Migrasi data **v7 → v8** (`Data/Migrations.luau`): tambah `stamina`.
- Remote baru: `Rest` (mulai/berhenti istirahat). Rate limit lewat `Modules/RateLimit`.
- Klien: `HudController` sudah membaca atribut; `FarmController` menampilkan toast "capek" dari kode penolakan server.

**Definisi selesai:** stamina turun saat bertani, pulih saat istirahat, ditolak saat 0, tersimpan, dites di Studio dengan perintah `!stamina <n>`.

## 17.2 Hias lahan v2 (referensi gambar 6 & 7)

**Tujuan tampilan:** saat masuk mode Hias, muncul **kotak grid di tanah plot**, sel yang disentuh/ditunjuk **menyala** (hijau = boleh, merah = terhalang), toolbar bawah dengan tab kategori dan baris item geser.

**GUI (landscape HP):**
- **Toolbar bawah** (mirip gambar 7): baris tab kategori (Semua, Pagar, Jalan, Lampu, Tanaman, Bangunan, Event...) di atas baris kartu item (ikon, nama, harga atau "x3 di tas"), geser horizontal, kartu aktif disorot.
- **Kiri**: tombol bulat Putar Kiri, Putar Kanan, Tampak Atas, Grid (nyala/mati).
- **Kanan**: Undo, Redo, Hapus (mode erase), Pilih (mode select/pindah).
- **Atas tengah**: petunjuk satu baris ("Ketuk tanah untuk menaruh, tekan lama untuk memindah").
- **Keluar**: tombol X di pojok. Dock dan kartu status disembunyikan selama mode Hias supaya pandangan lapang.

**Grid & highlight:**
- Grid = **satu Part transparan** di atas plot dengan `Texture` garis tipis (`StudsPerTile = 2`, sama dengan sel `DecorGrid`), hanya dibuat di klien selama mode Hias. Biaya render kecil (tidak ada Part per sel).
- Sorotan sel = satu Part tipis yang dipindah ke sel yang ditunjuk (mouse hover di PC, sentuhan terakhir di HP), diwarnai hijau/merah dari hasil validasi `DecorGrid` yang sama dengan server.
- Tampak Atas: kamera Scriptable di atas plot (tombol bulat), geser jari untuk menggeser, cubit untuk zoom. Keluar mode → kamera normal.
- Mobile: ketuk sel → hantu item pindah ke situ; tombol **Pasang** (sudah ada) atau ketuk dua kali. Seret hantu = pindah sel.

**Undo/Redo:** tumpukan operasi di klien (pasang, pindah, simpan) yang dibalik dengan remote yang sudah ada (`DecorService` memvalidasi tiap langkah seperti biasa). Batas 30 langkah, hilang saat keluar mode.

**Yang tidak diambil dari referensi:** lantai bertingkat (FLOOR) dan "Zones" (tidak ada di desain kita).

**Definisi selesai:** grid terlihat di plot sendiri saja, highlight mengikuti jari/mouse, tab kategori memfilter katalog, undo/redo bekerja, tidak ada lag di HP (cek jumlah Part: grid 1 + sorotan 1 + hantu).

## 17.3 Hadiah harian login (referensi gambar "Daily Rewards")

- Panel kecil modal: 7 kartu (Hari 1–7), kartu hari ini ditandai "HARI INI", tombol besar **Klaim**; hari 7 hadiah spesial (kartu emas).
- **Aturan (asumsi):** hari berganti pukul 00:00 WIB (sama seperti pesanan harian). Lewat satu hari: streak **dipertahankan sekali** (grace 1 hari), lewat dua hari: kembali ke Hari 1. Cozy, tidak menghukum.
- **Hadiah (asumsi):** H1 150 Koin, H2 bibit x3, H3 300 Koin, H4 2 Bunga, H5 600 Koin, H6 bibit unggul x2, H7 1.000 Koin + 5 Bunga. Angka di `Config/Rewards.luau`.
- Akses: tombol **Hadiah** di menu kanan atas dengan titik merah saat ada yang bisa diklaim. **Tidak ada popup otomatis** (prinsip Monetization_Review).
- Server: `RewardService`, data `rewards.daily = { day, lastKey, streak }`, remote `ClaimDaily`; klaim idempoten per hari WIB.

## 17.4 Hadiah playtime (referensi tombol Gifts + timer)

- Enam peti per hari: tersedia di menit **5, 10, 15, 25, 35, 50** waktu bermain (asumsi). Peti menampilkan hitung mundur; saat siap, bergoyang + titik merah.
- Dibuka dari tombol **Hadiah** (satu panel dengan tab Harian | Playtime).
- Server menghitung detik sesi (bukan klien), reset harian WIB; hadiah: Koin kecil, bibit, sesekali Bunga (tanpa barang yang bisa dibeli Robux).
- Anti-AFK sederhana: detik hanya bertambah kalau pemain bergerak/beraksi dalam 3 menit terakhir (cek posisi karakter dan aksi tani).
- Data `rewards.playtime = { dayKey, seconds, claimed = {bool x6} }`.

## 17.5 Hadiah koleksi (referensi gambar "Farm Book")

- Panel **Koleksi** dirombak: grid kartu kategori (Tanaman, Ikan, Hiasan, + kategori baru bila ada) dengan ikon bulat, judul, "x dari y terkumpul"; masuk ke kategori melihat daftar item (terkunci = siluet).
- **Perubahan perilaku:** hadiah milestone yang sekarang diberikan otomatis (`Config/Book`) menjadi **diklaim manual** dengan tombol (hadiah menumpuk tidak hilang). Migrasi: milestone yang sudah tercapai pada save lama ditandai "sudah diklaim" supaya tidak dobel.
- Data `book.claimed[milestoneId] = true`; remote `ClaimBook`.

## 17.6 Toko (referensi gambar "Farm Shop")

- Satu panel besar landscape: **tab samping** (Paket, Boost, Koin, Hias) + **kartu produk** (ikon besar, nama, deskripsi, harga Robux, tombol Beli; hadiahkan/gift **tidak** diambil).
- Isi awal = yang **sudah ada**: 4 game pass dan produk Bunga/Koin/Instant Grow dari `Config/Monetization.luau`. ID masih 0 → kartu menampilkan "Belum tersedia".
- Toko NPC (Pak Darmo dkk.) tetap ada untuk jual-beli barang; toko Robux ini hanya dari tombol **Toko** HUD. Boost baru (mis. x2 pertumbuhan sementara) **tidak** ditambah di fase ini tanpa tinjauan `Monetization_Review.md`.

## 17.7 Upgrade (referensi gambar "UPGRADES")

- Daftar baris: ikon + label "BARU", nama, deskripsi, **titik progres** (0/9), kotak "efek sebelum → sesudah", tombol beli berisi harga.
- Isi (asumsi): **Tas** (slot), **Kolam** (kapasitas ikan), **Lahan** (petak tambahan; sudah ada tangganya di `Config/Farm`), **Stamina Maks** (+10/tingkat), **Pemulihan** (istirahat lebih cepat), **Alat Siram** (siram hemat stamina), **Pupuk** (tumbuh lebih cepat kecil).
- Tiga upgrade pertama sudah ada logikanya di `ShopService` (`upgrade.backpack/pond/farm`): **dipindah** ke `UpgradeService` yang umum; data `upgrades[id] = tier`; save lama dimigrasi dari `backpackTier`, `pond.tier`, `farm.expansions`.
- Harga naik per tingkat (rumus di `Config/Upgrades.luau`); simulasi dengan `tools/balance_sim.py` sebelum dikunci.

## 17.8 Poles & QA

- Tes di HP asli (bukan hanya emulator Studio): ukuran sentuh, joystick vs kartu status, notch, rotasi.
- Semua string baru lewat `Locale/id.luau`.
- Perbarui `00_Design_Doc.md` (stamina, hadiah, upgrade), `GUI_Design.md`, dan `Playtest_Plan.md` (target ritme: berapa menit sebelum capek).
- Hook analitik (`AnalyticsHooks`): klaim harian, klaim playtime, stamina habis, upgrade dibeli.

---

## Perubahan data (rangkuman)

`DataTemplate` v7 → **v8** (satu migrasi untuk seluruh fase, ditulis saat 17.1 dimulai lalu ditambah bertahap):
```
stamina = { value = 100, at = 0 }
rewards = { daily = { day = 0, lastKey = "", streak = 0 },
            playtime = { dayKey = "", seconds = 0, claimed = {} } }
book.claimed = {}          -- milestone yang sudah diklaim
upgrades = {}              -- [id] = tier (menggantikan backpackTier / pond.tier / farm.expansions)
```

## Remote baru (via `Modules/Net`)
`Rest`, `ClaimDaily`, `ClaimPlaytime`, `ClaimBook`, `BuyUpgrade`, `DecorUndo` (opsional). Semua server-authoritative dengan `RateLimit`.

## Keputusan terbuka (perlu jawabanmu sebelum 17.1 / 17.3)
1. **Stamina:** angka di tabel 17.1 sudah sesuai ritme yang kamu bayangkan? Mau ada makanan/minuman yang memulihkan stamina (dibeli dari NPC)?
2. **Istirahat:** cukup duduk di mana saja, atau harus di bangku/rumah? (usulan: di mana saja, tetapi bangku/rumah lebih cepat)
3. **Streak harian:** grace 1 hari (usulan) atau reset ketat?
4. **Hadiah playtime:** boleh ada tombol "klaim cepat" berbayar Robux, atau murni gratis? (usulan: murni gratis)
5. **Kartu status vs joystick:** kalau terasa mengganggu di HP, pakai thumbstick Dynamic atau geser kartu ke kanan?
6. **Hias lahan:** perlu tampak atas penuh (kamera bebas) atau cukup grid + highlight di kamera biasa?

## Catatan teknis yang sudah dipelajari (hindari ulang kesalahan)
- Skin gambar harus **di atas** latar tapi **di bawah** teks: `ScreenGui.ZIndexBehavior = Sibling`, skin `ZIndex = 0`, teks tombol lewat label overlay. Jangan menunggu `IsLoaded` di tiap rebuild panel: pakai cache preload (`UiKit`), kalau tidak semua tombol berkedip saat satu ditekan.
- Panel dibangun ulang tiap perubahan data, jadi komponen baru harus murah dibuat dan tidak berkedip.
- HUD memakai `IgnoreGuiInset = true` + `ScreenInsets = DeviceSafeInsets` (menghindari notch); ikuti `Workspace.CurrentCamera` saat mengamati `ViewportSize`.
- Sinkronisasi file ke Studio tidak selalu otomatis: setelah mengedit, cek `Source` di Studio sebelum menguji.
