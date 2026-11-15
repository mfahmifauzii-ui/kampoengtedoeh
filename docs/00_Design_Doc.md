# Kampung Teduh — Design Doc (v0.3)

Sumber kebenaran tunggal untuk desain. Menggantikan v0.2, `Phase12_Garap_NPC_Design.md`, dan `Phase17_Status_Istirahat_Hadiah_Plan.md` (semuanya ada di `docs/_archive/`).
Rencana pengerjaan ada di `Roadmap.md`. Tidak ada tanggal atau jadwal di dokumen ini.

**Tanda status**
- ✅ sudah dikodekan (menurut dokumen terakhir; belum diverifikasi ulang ke kode)
- 🔧 keputusan baru, kode perlu diubah
- 🗓 rencana, belum dikodekan
- Angka bertanda *(asumsi)* belum disimulasikan; cek dengan `tools/balance_sim.py` sebelum dikunci.

---

## 1. Visi & target

Game cozy, tanpa fail state, di kampung Indonesia. Pemain bertani, memancing, menghias lahan, dan lama-lama membangun rumah serta beternak.

- **Target:** perempuan sekitar 16+, suka personalisasi dan estetika. Cek kebijakan rating & usia Roblox yang terbaru langsung dari sumbernya sebelum mengunci target ini.
- **Server:** **8 pemain** (8 lahan identik, ✅ R2), tiap pemain punya satu lahan. Peta: kanal bundar mengelilingi pulau kota, cincin jalan batu, 4 jalan silang, lahan mengapit jalan; lihat `Map_Plan.md`. Delapan dipilih karena hanya 8 atau 12 yang bisa benar-benar simetris dan adil.
- **Platform:** HP landscape dulu, UI berbahasa Indonesia.
- **Pilar:** Bertani · Mancing · Menghias. Menyusul: Beternak, Rumah, Warung pemain.

### Prinsip (tidak boleh dilanggar tanpa keputusan baru)
1. **Tanpa fail state dan tanpa penalti.** Tidak ada stamina, energi, lapar, atau haus yang menghalangi aksi. Tanaman tidak layu, hewan tidak mati, ikan tidak lepas.
2. **Buff boleh, penalti tidak.** Makanan atau minuman nanti hanya memberi bonus kecil. Tidak makan tidak merugikan.
3. **Server-authoritative.** Waktu dari `os.time()` server, semua aksi divalidasi di server, hadiah dari roll server.
4. **Tidak ada item acak berbayar, tidak ada popup jualan, tidak ada tekanan streak.** Detail di `Monetization_Review.md`.
5. **Tidak ada trading bebas antar pemain.** Hadiah antar pemain nanti dibatasi (lihat §14).

---

## 2. Loop

**Mikro (30–90 d):** tanam atau lempar pancing → tunggu singkat → panen atau tangkap → popup lembut + suara + XP.
**Sesi (10–20 mnt):** selesaikan pesanan → Koin + XP → beli bibit atau upgrade → buka tanaman, ikan, atau hiasan berikutnya.
**Meta (hari/minggu):** Buku Koleksi → hias lahan → perluas lahan → (🗓) ternak, rumah, kunjungan teman, tujuan bersama kampung.

---

## 3. Mata uang

| | **Koin** (lunak) | **Bunga** (premium-ringan) |
|---|---|---|
| Dapat | jual, pesanan, hadiah | gratis: naik level, pesanan mingguan, kunjungan harian hari ke-7, milestone Suka, Koleksi |
| Pakai | bibit, alat, upgrade, lahan, hiasan dasar | hiasan kosmetik, skin joran, reroll pesanan |
| Robux | paket kecil | paket |

Aturan: **tidak ada yang menghalangi progres dan hanya bisa dibeli dengan Bunga.** Semua yang memengaruhi progres bisa dibeli dengan Koin.
Dompet awal: 100 Koin, 10 Bunga. ✅

---

## 4. Lahan 🔧

Lahan pemain tersusun dari **blok 32×32 stud** (di kode masih disebut "chunk"; 32 habis dibagi 2, 4, dan 8 dan pas dengan lahan awal 128 dan kotak 192, jadi cocok dengan grid hiasan 2 stud, sel Terrain 4 stud, dan petak tanam 8 stud). Awalnya 16×16, tapi terlalu kecil dan pagarnya bergerigi, jadi diubah (migrasi v12). Semua pemain sama: **awal dan akhir lahan identik**.

- **Awal:** **128×128** (4×4 blok, ✅ R2), menempel ke jalan. **Maksimal:** **192×192** (6×6 blok, kotak cadangan tiap lahan; **20 blok** bisa dibeli). Ruang perluasan = belakang 64 stud dan samping 32 stud di tiap sisi (20.480 stud²).
- ✅ (R2b) **Blok** baru (32×32) dibeli satu per satu: tombol **+** melayang di atas tiap blok yang bisa dibeli (muncul saat karakter dekat, maksimal 3 sekaligus) membuka popup beli, dan blok **harus menempel** pada lahan yang sudah dimiliki. Harga blok ke-n (n mulai 0) = `1.500 × 1,2ⁿ` dibulatkan ke 10: **#1 1.500, #5 3.110, #10 7.740, #15 19.260, #20 47.920**; **20 blok seluruhnya ±280.000 Koin** *(asumsi, `balance_sim.py`: 15 dari 20 blok terbeli di hari 42 oleh pemain model)*. Pagar bambu mengikuti tepi blok yang dimiliki (segmen 8 stud, gerbang 32 stud di sisi jalan). Pass "Diskon Lahan" memotong 20% dan **tidak mengubah ukuran akhir** (semua pemain tetap berakhir 192×192).
- ✅ Area perluasan **diisi hutan** (pohon, semak, batu) yang dibersihkan saat blok dibeli, jadi peta tidak terlihat kosong. Lahan awal tampak terang dan berpagar bambu.
- Rumah panggung berada di dalam lahan awal (`Config/Map` `HOUSE`).
- Pemain yang menjual chunk? Tidak ada. Lahan hanya bertambah.
- ✅ **Batas jumlah petak tanam dihapus.** Luas lahan yang jadi batasnya (batas teknis 100 petak, hanya katup pengaman). Upgrade "Perluas Kebun" (300/800/2.000/5.000/12.000 Koin) dihapus; pemain yang sudah membelinya mendapat **refund penuh** lewat migrasi. ⚠️ Efek ekonomi: tanpa batas petak, pemasukan dan XP naik jauh (lihat `Playtest_Plan.md`); tuas penyeimbang: kuota Pak Darmo, harga bibit, kurva XP, dan harga chunk.
- Saat pemain keluar, lahan di server kembali ke lahan awal (blok dikembalikan jadi hutan) dan dibangun ulang dari data pemain berikutnya. Slot terakhir pemain (`plotSlot`) dicoba dipakai lagi saat masuk.

### Garap ✅
Rumput default hanya untuk hiasan. Petak **digarap** dulu jadi tanah (Terrain, 8×8 stud, kering = Ground, disiram = Mud), baru bisa ditanami. Alat **Cangkul** membaca apa yang ada di bawahnya: rumput → petak baru, petak kosong → kembali jadi rumput (**Hijaukan**, gratis, tanpa tombol terpisah), petak bertanaman → diteruskan ke siram/panen. Menanam dilakukan di luar mode Garap. Tanah dan hiasan tidak boleh bertumpuk (server cek dua arah). Setelah panen, petak tetap tanah.

---

## 5. Bertani

Tumbuh dihitung dari timestamp server, jadi tanaman tumbuh saat offline. **Menyiram opsional:** memangkas sisa waktu 20%. **Hujan:** semua petak dianggap sudah disiram. ✅

| Tanaman | Buka Lv | Bibit | Tumbuh | Jual | Untung/mnt | XP |
|---|---|---|---|---|---|---|
| Kangkung | 1 | 5 | 1 mnt | 9 | 4,0 | 2 |
| Cabai | 1 | 10 | 3 mnt | 20 | 3,3 | 3 |
| Tomat | 3 | 15 | 5 mnt | 30 | 3,0 | 5 |
| Terong | 5 | 25 | 10 mnt | 50 | 2,5 | 8 |
| Jagung | 8 | 40 | 20 mnt | 85 | 2,3 | 12 |
| Singkong | 11 | 60 | 45 mnt | 140 | 1,8 | 20 |
| Padi | 14 | 80 | 2 jam | 220 | 1,2 | 35 |
| Pisang (pohon, berbuah ulang ×3) | 18 | 200 | 8 jam/siklus | 120 × 3 tandan | ~0,75 | 40 |

Niat desain: tanaman pendek untung lebih per menit (menghargai main aktif), tanaman panjang menghargai waktu offline. Tidak ada yang jebakan.

**Bibit adalah item di Tas** (`seed_<tanaman>`, `seedx_<tanaman>`); menanam memakai 1 bibit. Pemain baru mulai dengan 6 bibit kangkung. Bibit unggul (Bu Wati) dipakai lebih dulu dan tumbuh 10% lebih cepat di setiap siklus (termasuk pisang berbuah ulang). ✅

---

## 6. Memancing ✅

**Lokasi:** **Sungai** (bersama), **Empang** (bersama, buka Lv 4; ujung sungai yang sama dengan sungai, hanya papan dan tabel ikan berbeda), **Kolam** (digali sendiri di lahan, buka Lv 6 lewat quest "Kolam Pertamamu").

**Alur:** ketuk untuk lempar → ikan menggigit 4–10 d (joran dan umpan mempersingkat) → **mini-game reel**: tahan agar penanda tetap di zona lunak ±3 d. **Ikan selalu tertangkap**; performa hanya menentukan ukuran (S/M/L, nilai ×1,0 / ×1,2 / ×1,5).

**Bobot langka dasar:** Umum 70 / Tak umum 22 / Langka 7 / Legendaris 1. Legendaris hanya bisa muncul bila syarat terpenuhi. **Hujan:** Langka ×1,5, Legendaris ×2.

| Ikan | Langka | Lokasi | Syarat | Jual |
|---|---|---|---|---|
| Wader | U | Sungai | – | 8 |
| Nila | U | Empang, Kolam | – | 10 |
| Mujair | U | Empang | – | 10 |
| Lele | U | Kolam, Empang | ×2 malam | 14 |
| Ikan Mas | TU | Empang, Kolam | – | 25 |
| Bawal | TU | Empang | – | 28 |
| Gabus | TU | Sungai | sore/malam | 35 |
| Belut | TU | Sungai | hujan | 40 |
| Gurame | L | Empang | pagi | 80 |
| Udang Galah | L | Sungai | malam | 90 |
| Koi Kampung | L | Kolam | ×2 hujan | 150 |
| Arwana | Leg | Sungai | hujan **dan** malam | 500 |

(U = Umum, TU = Tak umum, L = Langka, Leg = Legendaris)

**Joran:** Bambu (awal) · Rotan 500 Koin Lv5 (gigit −15%, Langka +2) · Fiber 2.000 Lv10 (−25%, +4) · Juragan 6.000 Lv18 (−35%, +6, Legendaris +1).
**Umpan:** Cacing gratis tak terbatas. Pelet 5 Koin, gigit −30%.

**Kolam:** tombol dock **Kolam** menggali kolam 16×16 (air Terrain sungguhan, dalam 8 stud) di mana saja di lahan hijau; mengetuk kolam yang sudah ada (alat yang sama, kotak oranye, dengan konfirmasi) menimbun dan mengembalikan 50% harga (ikan belum diambil hilang). Maksimal 4 kolam; harga: pertama gratis, lalu 400 / 900 / 1.600 Koin (`Config/Fishing` POND.PRICES). Kolam menghasilkan 1 ikan Umum/Tak umum tiap 10 menit, maksimal **10 per kolam** (upgrade Koin naik ke 20 → 30; pass 2× Offline melipatgandakan). Ambil dengan satu ketukan.
Kolam 16×16 = seperempat blok lahan (32×32).

---

## 7. Tas, jual-beli, dan NPC

- **Tas:** 40 slot, tumpuk 99. Upgrade Koin: 60 / 80 / 100 (1.000 / 4.000 / 10.000). Pass Tas Besar +40. ✅
- **Menjual hanya lewat NPC** (Tas tidak punya mode jual). ✅
- Panel dagang berupa satu daftar (Beli lalu Jual, tombol ×1 / ×10). ✅
- **NPC (Ngobrol → dialog 2 pilihan: `Jual/Beli` · `Sampai jumpa`).** Server mengecek jarak (maks 25 stud) dan harga. ✅

| NPC | Peran | Aturan |
|---|---|---|
| **Pak Darmo** | Beli **hasil panen** (bukan ikan), jual bibit, upgrade (tas, kolam, kapasitas warung) | harga 1,0× sampai **kuota harian** (lihat bawah) |
| **Bang Tarno** | Penadah: beli hasil panen saat kuota Pak Darmo habis | **0,7×**, tanpa batas |
| **Bu Wati** | Jual bibit unggul | 1,5× harga Pak Darmo, tumbuh 10% lebih cepat |
| **Mas Joko** | Jual joran dan umpan | harga sekarang |
| **Mbok Minah** | Beli dan jual ikan | beli 1,0×; jual ikan Kecil 1,3× (umum/langka biasa, supaya pesanan dan Buku tidak bergantung keberuntungan) |
| **Mbak Arsi** | Jual blueprint | per set (lihat §9) |

### Kuota harian Pak Darmo ✅ *(dikodekan dan dites di Studio di R1; angka masih asumsi)*
- Pak Darmo membeli **sampai 20 butir per jenis tanaman per hari** di harga 1,0×. Reset 00:00 WIB.
- Setelah kuota satu jenis habis, jenis itu hanya bisa dijual ke Bang Tarno (0,7×). **Tidak pernah ditolak.**
- Kuota naik lewat upgrade **Kapasitas Warung** (Koin, +5 per tingkat) *(asumsi)*.
- Kuota per jenis mendorong pemain menanam beragam, dan sekaligus jadi sink Koin yang dibutuhkan (lihat `Playtest_Plan.md`).
- Panel menampilkan sisa kuota ("Sisa hari ini: 12/20"), supaya harga yang lebih rendah tidak terasa seperti hukuman.
- Tawar-menawar, kedekatan NPC, diskon kedekatan, dan skill Tawar **dihapus** dari desain dan dari kode (migrasi data v7 → v8 membuang `npc` dan `skills`). Upgrade Kapasitas Warung: 600 / 2.000 / 5.000 / 12.000 Koin, buka Lv 3 *(asumsi)*.
- Simulasi: kuota mengurangi pemasukan Koin ±20–25%, tapi tidak cukup untuk menghentikan penimbunan; sink lain tetap dibutuhkan.

---

## 8. Pesanan & hadiah

- **NPC warga (5):** Pak RT, Bu Sari (warung), Mbah Karto (petani), Mas Yudi (nelayan), Dik Rara. ✅
- **Harian:** 3 per hari, tiap pesanan 1–3 jenis dari konten yang sudah terbuka. Hadiah ±1,5× nilai jual + XP. Satu reroll gratis/hari, tambahan 2 Bunga. ✅
- **Mingguan:** permintaan campuran lebih besar, ±3× nilai + 5 Bunga + hiasan. ✅
- **Reset hari:** 00:00 WIB. ✅
- **Kunjungan Harian** (kumulatif, bukan beruntun; melewatkan hari hanya menjeda): 1: 50 Koin · 2: 75 · 3: 100 · 4: paket bibit · 5: 150 · 6: 200 · 7: 3 Bunga. ✅ 🗓 Tampil sebagai kalender 7 kartu di panel Hadiah. Tidak ada hukuman streak.
- 🗓 **Hadiah playtime:** peti di menit 5/10/15/25/35/50 waktu bermain per hari; hitung di server; hanya jalan bila pemain bergerak atau beraksi dalam 3 menit terakhir; hadiah Koin kecil, bibit, sesekali Bunga. Murni gratis, tidak ada "klaim cepat" berbayar.
- 🗓 **Koleksi:** milestone diklaim manual (bukan otomatis), hadiah tidak hilang kalau belum diambil.

Akses hadiah lewat tombol **Hadiah** di menu dengan titik merah. Tidak ada popup otomatis.

---

## 9. Hias lahan & blueprint

- **Grid:** 2 stud, putar 90°, hanya di lahan sendiri, collision dicek server. Operasi: pasang, pindah, putar, simpan. ✅
- **Batas hiasan:** 150 terpasang; pass Perluasan Hias +100. ✅
- **Blueprint (Mbak Arsi):** set dasar, hiasan Bunga, dan hiasan event tanpa blueprint. Blueprint hanya menggerbang **pembelian**; barang yang sudah dimiliki tetap bisa dipasang. Set Taman 400 Koin (Lv3), Set Pondok Sawah 600 Koin (Lv5). Angka di `Config/Blueprints`. ✅
- **Set "Pondok Sawah" (12 item):** bale bambu, kursi bambu, meja kayu, lampu teplok, pot tanah liat, pagar bambu (lurus + sudut), jalan batu, orang-orangan sawah, gentong air, jemuran, sepeda onthel. Melengkapi set memberi gelar + hiasan bonus.
- **Hias v2 🗓 (ditunda):** toolbar kategori, grid terlihat di tanah, highlight sel, undo/redo, tampak atas. Hanya grid + highlight yang dipertimbangkan lebih awal; undo/redo dan kamera tampak atas menyusul belakangan.

---

## 10. Rumah 🗓

Rumah bertahap, dikerjakan setelah loop inti terbukti seru:
- **Tahap A:** rumah naik tingkat (kecil → sedang → besar) dengan interior bisa dihias.
- **Tahap B:** rumah modular. Pemain menambah ruangan di grid dan memilih gaya dinding, lantai, atap, pintu, jendela. Tetap berbasis grid dan mudah divalidasi server.
- **Bukan** bangun bebas ala Bloxburg: berat di HP, sulit divalidasi, proyek tersendiri.

---

## 11. Peternakan 🗓

Dimulai dari **ayam saja**; domba (bulu) dan sapi (susu) menyusul bila ayam terbukti disukai.

- Kandang dibangun di lahan (hiasan khusus, buka di level tertentu), beli dengan Koin.
- Hewan diberi pakan (dari panen/biji) untuk berproduksi. **Hewan tidak bisa mati atau sakit.** Tidak diberi pakan, produksi berhenti; produk menumpuk sampai batas maksimal (seperti kolam) selama offline.
- Produk (telur, bulu, susu) masuk ke pesanan, dijual, dan menjadi bahan masak nanti.
- Biaya terbesar: model dan animasi hewan.

---

## 12. Progresi & Koleksi

**Level 1–30.** XP ke level berikutnya: `floor(20·L^1,5 + 10·max(0, L−8)^2,1)`. Tiap naik level: 2 Bunga + yang terbuka. Ekstra sekali: Lv20 (10 Bunga + gelar), Lv25 (15 Bunga), Lv30 (25 Bunga + gelar). ✅

| Target ritme | Model (35 mnt/hari) |
|---|---|
| Lv 5 sesi pertama | hari 1 |
| Lv 10 | hari 3 |
| Lv 20 | hari 11 |
| Lv 30 | hari 31 |

**Buku Koleksi (32 entri):** 8 tanaman, 12 ikan, 12 hiasan Pondok Sawah. Ikan mencatat ukuran terbesar. Milestone: 25% → 500 Koin; 50% → 10 Bunga; 75% → Lampion Gantung; 100% → gelar "Warga Teladan" + gazebo eksklusif.

---

## 13. Dunia ✅

**Siklus hari:** 24 menit nyata (pagi 5 / siang 8 / sore 4 / malam 7), tiap fase punya preset Lighting. **Hujan:** dicek tiap 20 menit dengan peluang 25%, berlangsung 4–6 menit; menyiram tanaman otomatis, menaikkan ikan langka, memutar suara hujan.

---

## 14. Sosial

**Sudah ada ✅:** **Mampir** (teleport ke lahan orang lewat panel Warga), **Suka** (1 per pengunjung per lahan per hari WIB, hanya saat berdiri di lahan itu; milestone 10 → 3 Bunga, 50 → 10 Bunga, 200 → 25 Bunga + gelar), emote bawaan Roblox. Izin membangun hanya milik pemilik lahan.

**Rencana, urut prioritas (retensi pemain yang suka personalisasi):**
1. 🗓 **Mode foto.** Penyebar utama untuk target ini (orang membagikan screenshot).
2. 🗓 **Tujuan bersama kampung ("gotong royong").** Satu pesanan besar per server; semua pemain menyumbang bahan; semua dapat hadiah bila tercapai. Memberi alasan 8–10 orang berinteraksi.
3. 🗓 **Warung pemain + masak.** Pemain masak dan jual makanan ke pemain lain; makanan memberi **buff kecil** (mis. "Kenyang": XP +10% selama 10 menit). Tidak makan tidak merugikan. Jadi sink Koin utama.
4. 🗓 **Hadiah antar teman.** Pilihan terbatas (bibit, bunga), ada batas harian, tanpa trading bebas.
5. 🗓 **Teman hewan:** kucing kampung yang bisa dielus di lahan.
6. 🗓 **Tinggal bareng:** teman jadi co-owner rumah dan menghias bersama (setelah Rumah Tahap A).

Di luar itu, keterbukaan untuk lintas-server dan fitur lain baru dipertimbangkan setelah ada data pemain nyata.

---

## 15. GUI ✅

Kit bambu ForgeGUI terpasang, HUD baru jadi. Detail di `GUI_Design.md`. 🗓 Komponen baru yang dibutuhkan: tab, kartu produk, titik progres, titik notifikasi, popup klaim (satu-satunya popup, muncul setelah pemain menekan klaim).

---

## 16. Monetisasi ✅ (ID masih 0)

| Jenis | Item | Harga draf (R$) |
|---|---|---|
| Pass | Tas Besar (+40) | 99 |
| Pass | Kapasitas Offline 2× | 149 |
| Pass | Perluasan Hias (+100) | 149 |
| Pass | Diskon Lahan (−20% harga blok) | 199 ✅ *(menggantikan "Petak Ekstra"; tidak mengubah ukuran akhir)* |
| Produk | Bunga 50 / 120 / 300 | 49 / 99 / 229 |
| Produk | Koin S / M / L | 25 / 75 / 199 |
| Produk | Instant Grow (1 petak, maks 3/hari) | 15 |
| Premium | +10% Koin pesanan, +1 reroll | – |
| Server pribadi | | 50/bulan |

🗓 Auto-Collect dan VIP Warung baru dipertimbangkan nanti. Tidak ada item acak berbayar, tidak ada popup. Kuota warung dan upgrade lahan **selalu bisa dibeli dengan Koin**. `Monetization_Review.md` dijalankan sebelum setiap rilis yang menjual sesuatu.

---

## 17. Teknis

- **Alat:** Rojo 7.7.1 + VS Code, `--!strict` seperlunya. Git: repo `kampoengtedoeh` (privat).
- **Data:** ProfileStore (session lock, autosave). Skema berversi, migrasi di `Data/Migrations.luau`. Versi terakhir menurut dokumen: v7.
- **Remote:** satu modul `Net`, tiap handler cek tipe + rate limit + kepemilikan/jarak.
- **Config:** semua konten di `Shared/Config/*.luau`.
- **Performa:** StreamingEnabled, model lahan di-stream, VFX di-pool, tidak ada loop per-frame di server (tumbuh dihitung dari timestamp). Dengan 8 lahan, jumlah Part per lahan harus tetap kecil (hiasan ≤ 8 part per item).

```
src/
  server/Services/   Data, Economy, Farm, Fish, Inventory, Decor, Order, World, Social, ...
  shared/Config/     Crops, Fish, Decor, Orders, Progression, Shop, Blueprints, Npcs, ...
  shared/Modules/    Net, Types, Items, RateLimit, DecorGrid, Land, ...
  client/Controllers/ Hud, Farm, Fishing, Decor, Garap, Dialogue, Shop, ...
```

**Perubahan data yang diperlukan (satu migrasi per sub-fase, lihat `Roadmap.md`):**
```
hapus : skills, affinity (kedekatan NPC)
tambah: upgrades[id] = tier   -- tas, kolam, kapasitasWarung (🗓 R3: UpgradeService umum)
sudah : land = { chunks = { ["ix,iz"] = true } }, plotSlot = n   -- v12 (R2b; kuncinya sekarang blok 32×32)
        sales = { dayKey, sold = { [cropId] = count } }   -- kuota Pak Darmo
        rewards = { daily..., playtime = { dayKey, seconds, claimed } }
        book.claimed = {}
```

---

## 18. Ruang lingkup

| Dibangun sekarang | Setelah playtest |
|---|---|
| 8 tanaman, 12 ikan, 3 lokasi, 4 joran | Peternakan (ayam dulu) |
| Garap, kolam, hias grid, blueprint | Mode foto, tujuan bersama kampung |
| NPC dagang, kuota warung | Warung pemain + masak + buff |
| Pesanan, Koleksi, Level 1–30 | Rumah Tahap A/B |
| Siang-malam + hujan | Hadiah teman, kucing, tinggal bareng |
| Peta cincin 8–10 pemain, lahan chunk | Hias v2 (undo/redo, tampak atas) |
| Monetisasi dasar (4 pass, paket) | Locale EN, Auto-Collect, VIP Warung |

Event musiman **tidak** direncanakan sekarang. Kerangka `Config/Events` ada di kode tapi belum dipakai.

---

## 19. Risiko

1. **Data hilang:** ProfileStore, jangan simpan dari klien, hadiah lewat ProcessReceipt + log. Hapus fitur (tawar/kedekatan/skill) dengan migrasi dan uji pakai save lama.
2. **Exploit:** waktu hanya dari server; validasi penempatan; rate limit; reward dari roll server.
3. **Performa HP:** 8 lahan × hiasan itu berat; cek jumlah Part, streaming, dan FPS di HP asli.
4. **Kebijakan:** tidak ada item acak berbayar; isi kuesioner usia dengan jujur; cek aturan rating terbaru.
5. **Scope creep:** fitur baru hanya setelah playtest memberi data. Satu fase satu waktu.
6. **Paket Koin** bisa terasa pay-to-progress: jaga kecil dan jangan jual barang yang tidak bisa didapat gratis.
