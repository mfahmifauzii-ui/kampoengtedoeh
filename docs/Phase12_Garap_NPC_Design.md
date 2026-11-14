# Konsep: Garap, Bangun, NPC & Skill

**Status:** bagian 1 (Lahan & Garap) dan 3 (Tersimpan) **sudah dikodekan dan dites di Studio** (Fase 12). Bagian 4 **sebagian** (Fase 13, dites di Studio): kerangka NPC + dialog 2 pilihan + Pak Darmo, Bu Wati, Mas Joko, Mbok Minah. **Fase 14 (dites di Studio): Bang Tarno + tawar + kedekatan + skill Tawar sudah jadi.** **Fase 15 (belum dites di Studio): Mbak Arsi + blueprint sudah dikodekan** (Set Taman 400 Koin Lv3, Set Pondok Sawah 600 Koin Lv5; set dasar, hiasan Bunga, dan hiasan event tanpa blueprint; blueprint hanya menggerbang PEMBELIAN, barang yang sudah dimiliki tetap bisa dipasang; syarat level per hiasan dihapus; save lama dimigrasi v3→v4 dan otomatis dapat blueprint untuk set yang sudah dipakai). Angka ada di `Config/Blueprints.luau`. Belum: model tanaman + GUI ForgeGUI (Fase 16).

**Aturan tawar & kedekatan seperti yang dikodekan (Fase 14)** — semua angka ada di `Config/Npcs.luau` dan `Config/Skills.luau`:
- **Bang Tarno** membeli hasil panen di **0,7×** harga normal. Di panelnya tiap tumpukan punya tombol **Tawar**: pilih berapa persen di atas harga dasar; yang dijual **seluruh tumpukan**, dibulatkan sekali pada total (bukan per butir).
- **Pilihan tawaran:** +10 / +20 / +30% selalu ada; **+40%** terbuka di kedekatan Kenal, **+50%** di Akrab, **+64%** di Sahabat. Tawaran tertinggi mendarat di **1,15×** harga Pak Darmo dan tidak pernah di atasnya (batas keras).
- **Peluang** = 70 − (persen tawaran) + bonus kedekatan (0 / 5 / 10 / 15) + 3 × (level Tawar − 1), dijepit 5–95%. Panel menampilkan peluang apa adanya.
- **Berhasil:** terjual di harga tawar, kedekatan +1, XP skill +6. **Gagal:** harga dasar tetap tersedia, kedekatan −1 (tidak turun di bawah tingkat yang sudah dicapai), XP skill +2. **Dua gagal berturut-turut:** Bang Tarno tidak mau menawar 60 detik (menjual di harga dasar tetap bisa). Tidak ada barang atau Koin yang hilang.
- **Kedekatan (0–100, per NPC):** Asing 0, Kenal 20, Akrab 50, Sahabat 80. Naik: ngobrol pertama tiap hari +2, tiap transaksi +1 (maks +5 per NPC per hari), tawar berhasil +1. Manfaat: **diskon beli 5% (Akrab) dan 10% (Sahabat) di semua NPC**, bonus peluang tawar, dan sapaan baru di Akrab ke atas. Kedekatan terlihat di kotak dialog.
- **Skill Tawar:** Lv 1–10; naik Lv butuh 20 + 10 × level XP. Kerangka `data.skills[id]` + `SkillService.AddXp` sudah umum untuk skill lain.
- **Perintah Studio:** `!affinity <npc> <0-100>`, `!skill tawar <1-10>`, `!skillxp tawar <n>`.

**Perubahan di Fase 13 (dibanding usulan):**
- **Bibit jadi item di Tas** (`seed_<tanaman>` dan `seedx_<tanaman>`); menanam memakai 1 bibit, bukan membayar Koin saat menanam. Pemain baru mulai dengan 6 bibit kangkung.
- Bibit unggul (Bu Wati) dipakai lebih dulu saat menanam dan tumbuh 10% lebih cepat di setiap siklus (termasuk pisang yang berbuah ulang).
- Pak Darmo membeli **hasil panen saja**; ikan dijual ke Mbok Minah. Mbok Minah juga menjual ikan Kecil (jenis umum/langka biasa saja, 1,3× nilai jual) supaya pesanan dan Buku tidak bergantung keberuntungan.
- Panel dagang berupa satu daftar (bagian Beli lalu Jual + tombol ×1 / ×10), belum bertab.
- Tas tidak punya mode jual lagi; menjual hanya di NPC.
Perubahan dari usulan awal: lahan = **wedge hijau di peta** (bukan kotak 96×96), tanah = **Terrain** (bukan Part), petak **8×8** (bukan 6×6, supaya pas dengan voxel Terrain 4 stud).

Semua angka di sini adalah **asumsi saya**; ubah sebelum kita mulai kode. Prinsip tetap: cozy, tanpa fail state, server-authoritative.

---

## 1. Lahan hijau & Garap

Hijau = **lahan milikmu** (plot 96 × 96). Di dalamnya bebas, selama tidak keluar batas.

| Zona | Aturan |
|---|---|
| **Rumput** | Default. Boleh dipasangi hiasan/bangunan. Belum bisa ditanami. |
| **Tanah garapan** | Rumput yang sudah **digarap** → baru bisa ditanami (siram, panen seperti sekarang). |
| **Tetap** | Rumah panggung. Tidak bisa digarap/dibangun di atasnya. (Kolam tidak lagi tetap: pemain menggali sendiri lewat Garap → Kolam, lihat 00_Design_Doc.) |

**Cara menggarap**
- Tombol **Garap** di tepi kiri layar (mode seperti Hias). Ketuk petak rumput → petak jadi **tanah** cokelat: cat Terrain rata (kering = Ground, disiram = Mud), tepinya lembut karena Terrain memadukan material.
- Ukuran petak garapan: **8 × 8 studs** (2 × 2 sel Terrain). Hiasan tetap di grid 2 studs.
- **Batas garapan** = jumlah petak maksimal: mulai 6, +3 tiap perluasan (300 / 800 / 2.000 / 5.000 / 12.000 Koin) sampai 21, +4 dengan pass Petak Ekstra. Jadi **ekonomi & monetisasi sekarang tidak berubah**; yang berubah: petaknya boleh di mana saja, tidak lagi layout tetap.
- **Ratakan**: petak kosong bisa dikembalikan jadi rumput (kuota petak kembali, tidak ada biaya).
- Tanah dan hiasan **tidak boleh bertumpuk**: server mengecek dua arah (garap di atas hiasan ditolak, pasang hiasan di atas tanah ditolak).
- Setelah panen, petak tetap tanah (tidak perlu digarap ulang).

**Kenapa begini:** kamu dapat kebebasan menata (kebun berbentuk L, baris panjang, kebun di samping rumah), tapi tetap ada "pekerjaan awal" (menggarap) dan batas yang ikut progres.

## 2. Bangun (Blueprint)

- Hiasan/bangunan dibuka lewat **Blueprint** yang dijual NPC Tukang. Satu blueprint = satu set (mis. Pondok Sawah, Taman Lampion, Gazebo).
- Set dasar (pagar, jalan batu, semak) **gratis**. Set lain: blueprint 200–1.500 Koin (set Bunga tetap bayar Bunga).
- Menggantikan syarat level hiasan yang sekarang; item di dalam set tetap bayar per buah.
- Cara menaruh/memindah/menyimpan **sama** seperti sekarang (grid 2 studs, putar 90°, hanya di plot sendiri).

## 3. Tersimpan saat keluar / pindah server

- Semua tersimpan di **ProfileStore** (autosave berkala, simpan saat keluar, simpan saat server mati, session lock → pindah server tidak bisa mengambil data setengah jalan).
- Data baru (versi 2): `farm.tiles = { {cx, cz, crop?, plantedAt?, readyAt?, watered?, harvestsLeft?} }` + `decor.placed` (sudah ada).
- Saat masuk: server membangun ulang **tanah, tanaman, hiasan** dari data. Tanaman tumbuh **walau kamu offline** (dihitung dari timestamp).
- Semua aksi (garap, ratakan, tanam, pasang) divalidasi server: jarak, di dalam plot, tidak bentrok, kuota. Client hanya pratinjau.
- **Migrasi v1 → v2:** petak lama diberi posisi sesuai layout lama, jadi save yang ada tidak hilang.
- Risiko: data plot ≤ ~3 KB, aman. Jangan ubah struktur lagi tanpa migrasi.

---

## 4. NPC & dialog (gaya The Forge)

Di kota jembatan. Mendekat → **satu tombol "Ngobrol"** → panel dialog: sapaan NPC + **2 pilihan: `Jual/Beli` · `Sampai jumpa`**. Jual/Beli membuka panel dagang NPC itu (tab Beli | Jual). Server mengecek jarak dan stok/harga.

| NPC | Peran | Harga |
|---|---|---|
| **Pak Darmo** (utama) | Beli hasil panen, jual bibit, dan upgrade (tas, kolam, perluasan lahan) | harga normal (1,0×) |
| **Bang Tarno** (tengkulak) | Beli hasil panen, **bisa ditawar** | dasar 0,7×, bisa naik lewat tawar |
| **Bu Wati** (bibit unggul) | Jual bibit | 1,5× dari Pak Darmo |
| **Mas Joko** (pancing) | Jual umpan dan joran | harga sekarang |
| **Mbak Arsi** (tukang) | Jual blueprint bangunan | per set |
| **Mbok Minah** (ikan) | Beli **dan** jual ikan | beli 1,0×; jual 1,3× |

*Usulan:* bibit Bu Wati 1,5× lebih mahal tapi **tumbuh 10% lebih cepat**, supaya ada alasan membelinya. Kalau tidak mau, cukup mahal saja seperti permintaanmu.

### Tawar-menawar (hanya Bang Tarno)
1. Pilih tumpukan → **Tawar** → pilih tawaran: **+10% / +20% / +30% / +50%** di atas harga dasar.
2. Peluang berhasil = dasar 70% − (kenaikan × 1,0) + bonus kedekatan + bonus skill (dibatasi 5%–95%).
3. **Berhasil:** terjual di harga tawar, kedekatan +1, XP skill Tawar naik. **Gagal:** Bang Tarno "kurang cocok", harga dasar tetap tersedia; dua gagal berturut-turut → **jeda 60 detik**. Tidak ada barang hilang, tidak ada denda.
4. Harga tertinggi yang mungkin: **1,15× harga Pak Darmo** (hanya di kedekatan & skill tertinggi), jadi tawar menguntungkan tapi tidak mengalahkan semuanya.

### Kedekatan (likeness) per NPC
- 0–100 poin. Tingkat: **Asing** (0) → **Kenal** (20) → **Akrab** (50) → **Sahabat** (80).
- Naik: ngobrol pertama tiap hari +2, tiap transaksi +1 (maks +5/hari), tawar berhasil +1. Turun: tawar gagal −1 (tidak turun di bawah tingkat sebelumnya).
- Manfaat: peluang tawar +5% / +10% / +15%, diskon beli 5% (Akrab) dan 10% (Sahabat), dialog baru.

### Skill pemain
- Awal: satu skill, **Tawar** (Lv 1–10). XP dari tawar (berhasil lebih besar). +3% peluang tawar per level.
- Kerangka dibuat umum (`data.skills[id]`) supaya **Bertani / Memancing / Membangun** bisa menyusul tanpa ubah struktur.

---

## 5. Model, tanaman & GUI dengan ForgeGUI

Prinsip: pakai seperlunya, jangan boros kredit.

| Apa | Cara | Jumlah generate |
|---|---|---|
| Bangunan (warung, ruko, rumah) | sudah ada di `assets/models/` | 0 lagi (3 sudah dipakai) |
| Toko tiap NPC | pakai ulang model ruko + papan nama berbeda | 0 |
| **Tanaman** (8 jenis) | 1 model per jenis, ukuran model dipakai untuk 3 tahap tumbuh | 8 |
| **GUI** (panel, tombol, bingkai, ikon) | satu kit gaya cozy, sekali jalan | ±6–8 gambar |
| NPC (orang) | rig R15 + warna pakaian (bukan ForgeGUI) | 0 |
| Pohon | tetap prosedural dari kode (sesuai permintaanmu) | 0 |

**Catatan teknis GUI:** ForgeGUI menghasilkan **gambar PNG**; supaya dipakai di game harus jadi aset gambar Roblox. Dua cara: (a) kamu hubungkan akun Roblox di ForgeGUI (forgegui.com/forge-mcp), lalu saya bisa publish; (b) kamu upload manual ke Creator Hub dan kirim ID-nya. Sebagai UI/UX designer, mungkin cara (b) lebih nyaman karena kamu yang menyetel finalnya.

## 6. Urutan kerja yang saya usulkan

1. **Fase 12 — Garap**: mode garap/ratakan, validasi server, penyimpanan, migrasi, bangunan boleh di mana saja di plot.
2. **Fase 13 — NPC & dialog**: kerangka NPC, panel dialog 2 pilihan, Pak Darmo, Bu Wati, Mas Joko, Mbok Minah (memindahkan logika toko yang sudah ada).
3. **Fase 14 — Tawar, kedekatan, skill**: Bang Tarno + sistemnya.
4. **Fase 15 — Blueprint**: Mbak Arsi, set hiasan jadi per-blueprint.
5. **Fase 16 — ForgeGUI**: model tanaman + kit GUI, lalu pasang.
