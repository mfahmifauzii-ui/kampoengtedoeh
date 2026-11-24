# KAMPOENG TEDOEH — Asset Bible v1.0 (3D, Animasi, VFX, SFX, Musik, Ikon)

> Baru (sebelumnya hanya tersebar di GDD Bab 20–22, Roadmap §6–§7, dan Lampiran D). Satu daftar lengkap semua aset yang dibutuhkan untuk rilis.
> Angka gameplay tetap di `01_GDD`. Aturan GUI di `05_GUI_Spec.md`. Urutan kerja di `06_Roadmap.md` Fase 4–7.
> Status: **Ada** = sudah dipakai di game · **Uji** = sudah dibuat, belum diuji di Studio · **Cek** = mungkin ada di Studio, Claude Code wajib cek · **Belum** = harus dibuat.
> Prioritas: **★** = dibutuhkan untuk Vertical Slice Lv 1–10 (Roadmap G1). Tanpa ★ = sebelum rilis.

---

## 1. Arah Gaya

| Aspek | Aturan |
|-------|--------|
| Rasa | Cozy, hangat, kampung Indonesia tahun 90-an. Tenang, tidak ramai. |
| Bentuk | Low-poly halus, sudut membulat, proporsi sedikit chunky. Tidak realistis, tidak kartun berlebihan. |
| Material | Bambu, kayu jati, anyaman, genteng tanah liat, batu kali, kain batik (motif sederhana, bukan motif bermerek). |
| Warna | Muted & hangat. Pakai palet UiKit: bambu, parchment, daun; emas `GOLD (255,226,120)` hanya untuk "spesial" (Prima, Legenda, siap klaim). Air `WATER (46,104,128)`. Hindari neon dan saturasi tinggi. |
| Kualitas | Biasa = normal · Bagus = kilau lembut (putih hangat) · Prima = emas. Selalu ada **ikon/bentuk**, bukan warna saja (buta warna). |
| Cahaya | Pagi kabut tipis, siang hangat, sore oranye, malam biru + lampu kuning hangat otomatis. |
| Larangan | Tidak meniru karakter / logo / gaya game lain yang dikenal. Tidak ada salju, darah, daging, senjata. |
| Konsistensi | Buat **1 contoh per kategori → Claude Code periksa terhadap Bab 1 → produksi massal** (Roadmap R4.1). Owner memberi masukan lewat playtest, tidak memblokir. |

---

## 2. Anggaran Teknis (HP RAM 4GB) — pedoman, diverifikasi di R10.3

| Kelas aset | Triangle maks | Tekstur | Catatan |
|------------|---------------|---------|---------|
| NPC / avatar rig | 4.000 | 1 atlas 512 | R15. Satu atlas untuk badan + baju. |
| Hewan | 1.500 | 256 | Ayam/Bebek ≤ 800. |
| Tanaman per tahap | 300 (Late/pohon 800) | atlas tanaman bersama 512 | 4 tahap per tanaman. |
| Ikan 3D | 400 | atlas ikan 512 | Dipakai di kolam & akuarium. |
| Bangunan fungsi | 3.000 | 512 | Kandang, Dapur, Warung, Kolam, Bundel. |
| Piece hias | 600 (struktur ≤ 200) | atlas material 512 | Piece paling sering dipasang = paling ringan. |
| Alat dipegang | 500 | atlas alat 256 | |
| Props alun-alun | 1.500 | 512 | |

Aturan umum:
- Pakai **MeshPart**. Collision `Box` untuk dekor kecil, `Hull` untuk bangunan. `CastShadow = false` untuk dekor < 2 stud.
- Satu lahan penuh (800 piece + 36 tanaman + bangunan) target ≤ **2.500 instance**. Model dekor `ModelStreamingMode = Atomic` / streaming per lahan.
- Partikel: ≤ 40 partikel hidup per efek, ≤ 300 total di layar; hujan ikut GDD (30/60/90). Setting **"Efek rendah"** memotong semua rate 50%. Di kode, setting ini adalah **Kualitas gambar Rendah** (`settings.quality` = 1, R6.5): hujan dimatikan sama sekali, tidak ada setting baru. Hujan Deres (60) dan Petir (90) di atas 40 karena dikecualikan oleh aturan hujan di atas; kalau FPS turun di HP (B18), turunkan `Config/Weather` PARTICLES dulu.
- Audio: SFX mono, ≤ 3 dtk (kecuali loop), normalisasi −14 LUFS. Musik stereo, loop mulus.
- Kalau FPS < 30 di R10.3: turunkan dulu partikel & jarak streaming, baru cap piece (Config).

---

## 3. Pipeline (karena semua dibuat lewat Claude Code)

1. **Prompt** — Claude Code menulis prompt aset dari tabel di file ini + Bab 1.
2. **Generate** — pakai ForgeGUI (sudah dipakai untuk skin GUI): gambar/ikon/GUI, model 3D (+ remesh, rig, animasi), SFX, musik. Bila hasil kurang, edit kecil di Studio atau Blender (opsional).
3. **Review diri** — contoh pertama tiap kategori dicek terhadap Bab 1 (palet, outline, proporsi, ukuran), screenshot disimpan di laporan. Lolos → batch sisanya. Masukan owner dari playtest dikerjakan sebagai revisi batch.
4. **Import** — Claude Code memasang ke Studio lewat MCP Studio, struktur folder: `ReplicatedStorage/Assets/<Kategori>/<id>` (model) dan id aset di `Config/UiAssets` (ikon), `Config/Audio` (suara), `Config/<Sistem>.ANIMS` (animasi).
5. **Uji** — checklist di `07_QA_Test_Plan.md` Bab D.

Aturan Roblox yang wajib diingat:
- **Animasi dan audio harus dimiliki pemilik yang sama dengan game** (akun owner atau grup yang sama). Kalau game dipindah ke grup, animasi harus di-publish ulang atas nama grup.
- ID animasi dari `RegisterKeyframeSequence` hanya berlaku di Studio. ID permanen = **Publish to Roblox** (owner sudah melakukannya untuk 6 animasi).
- Audio upload melewati moderasi; siapkan cadangan.
- Nama id aset = huruf kecil + garis bawah, sama dengan id di Config (contoh `kangkung`, `kapak_besi`).

---

## 4. Model 3D

### 4.1 Karakter

| Aset | Jumlah | Status | ★ | Catatan |
|------|--------|--------|---|---------|
| Mak Sari, Pak Udin, Kak Fajar, Pak Amran, Nek Ani | 5 | Cek (`ServerStorage.NpcModels`; Kak Fajar ada) | ★ | Siluet beda jelas dari jauh. Pak Udin: peci + celemek warung. Kak Fajar: topi caping kecil + rompi. Mak Sari: kerudung + selendang. Nek Ani: kebaya + tongkat. Pak Amran: kaus + sarung tangan + pensil di telinga. |
| Bang Jali | 1 rig, dipakai ×8 | Cek | ★ | Variasi warna baju per lahan (opsional). |
| Pedagang Tamu malam | 6 (pak_kumis, nek_esih, bang_dodo, mpok_riah, kang_asep, yu_tum) | Belum | | Tiap NPC bawa properti dagangan (gerobak jamu, pikulan, dll.). |
| Tamu Event | 1–5 (bisa ganti baju per event) | Belum | | |
| Pengunjung Warung | 3 generik | Belum | | Rig ringan, tanpa dialog. |
| Kucing kampung (pet) | 1 + 2 warna | Belum | | Side Kucing Alun-alun. |
| Potret NPC (2D) | 6 + 7 + tamu | Cek (ada foto di bubble) | ★ | Untuk bubble dialog & kartu Order. |

### 4.2 Tanaman (4 tahap: bibit, tumbuh, matang, telat/besar ×1,1)

| Aset | Jumlah model | Status | ★ |
|------|--------------|--------|---|
| Kangkung, Bayam, Tomat, Sawi, Jagung, Ubi Jalar, Singkong, Cabai, Padi | 9 × 3 tahap (tahap 4 = skala) | Cek | ★ (Lv 1–8) |
| Stroberi, Pisang, Tebu, Jahe, Kopi, Teh, Melati, Mangga, Durian | 9 × 3 | Cek | |
| Bibit Varian: Jagung Ungu, Tomat Kuning, Cabai Pelangi, Stroberi Putih, Pisang Merah | recolor 5 | Belum | |
| Semangka Kotak (tanaman baru) | 1 × 3 | Belum | |
| Petak tanah (kering / basah) | 2 material | Cek | ★ |

Kualitas tidak butuh model baru (VFX, Bab 6).

### 4.3 Hewan & Produk

| Aset | Status | ★ |
|------|--------|---|
| Ayam, Bebek, Sapi | Cek | ★ Ayam |
| Ayam Cemani, Bebek Belang (recolor) | Belum | |
| Telur Ayam, Telur Bebek, Susu (botol/kendi) — model pickup + ikon | Cek | ★ |
| Tempat Pakan (kosong / terisi) | Cek | ★ |

### 4.4 Ikan

| Aset | Jumlah | Status | ★ |
|------|--------|--------|---|
| Ikan 3D low-poly (kolam, akuarium, kartu tangkapan) | 20 | Cek | ★ Early (4) |
| Bayangan ikan di air (decal) | 1–3 ukuran | Cek | ★ |
| Riak spot Sungai Lahan | 1 | Ada | ★ |
| Pelampung, tali (Beam) | 1 | Ada (B-5) | ★ |

### 4.5 Bangunan Fungsi

| Aset | Varian | Status | ★ |
|------|--------|--------|---|
| **Meja Crafting** (objek Workspace bernama persis "Meja Crafting") | 1 | **Belum — tombol Craft tidak muncul tanpa ini** | ★ |
| Inti Dapur: Tungku + Meja Olah | Tier 1 / 2 / 3 | Cek | ★ T1 |
| Warung Pemain (etalase 1 slot) | 1 | Cek | ★ |
| Kandang Ayam / Bebek / Sapi | Lv 1 / Lv 2 (6 model) | Cek | ★ Ayam Lv 1 |
| Kolam Tanah / Semen / Keramik | 3 + air animasi | Cek | ★ Tanah |
| Bubu Bambu / Kayu / Besi | 3 (terpasang di air + isi) | Belum | ★ Bambu |
| Akuarium (8 slot) | 1 | Belum | |
| Bingkai Album (teks %) | 1 | Belum | |
| Lapak Kak Fajar | 1 | Cek (map) | ★ |
| Rangka rumah (hadiah S4) | 1 | Cek | ★ |

### 4.6 Node Hutan (penuh + habis)

| Node | Bahan | Status | ★ |
|------|-------|--------|---|
| Pohon | Kayu | **Belum** (sekarang fallback DEV di 268,268) | ★ |
| Rumpun Bambu | Bambu | Belum | ★ |
| Batu Kali | Batu | Belum | ★ |
| Tebing Tanah | Tanah Liat | Belum | ★ |
| Pinggir Kali | Pasir | Belum | ★ |
| Pohon Aren | Ijuk (Lv 15) | Belum | |

Tiap node: model penuh, model habis (tunggul / lubang), titik tanda ritme (attachment). Wajib part `Mining` + atribut `NodeId`.

### 4.7 Alat (dipegang)

| Alat | Varian | Status | ★ |
|------|--------|--------|---|
| Cangkul | 1 | Cek | ★ |
| Gembor | Plastik, Seng, Kuningan, Bunga, skin Emas (K-15) | Cek | ★ Plastik |
| Sabit | Kayu, Besi, Bunga | Cek | ★ Kayu |
| Kapak | Batu, Besi, Baja, Bunga | Cek | ★ Batu |
| Joran | Bambu, Kayu, Kayu Jati, Bambu Wulung, Besi, Pusaka | Cek (Bambu ada) | ★ Bambu |
| Sepatu Bot (aksesori) | 1 | Belum | |

### 4.8 Katalog Hias 80 piece — [nama FINAL; key boleh disesuaikan dengan Config]

Nama bertanda (S) = anggota Set (GDD 8.5). Pilih **30 Dekor Berkah**: usul semua anggota set (19) + Orang-orangan Sawah + 10 lain.

**Struktur (25):** Dinding Bambu, Dinding Anyaman, Dinding Papan, Dinding Bata, Dinding Setengah Bata, Dinding Kaca (Lv 25), Tiang Bambu, Tiang Kayu, Saka Guru (S Joglo), Lantai Papan, Lantai Tanah Liat, Lantai Batu, Lantai Tegel (S Joglo), Pintu Kayu, Pintu Bambu, Gebyok (S Joglo), Jendela Kayu, Jendela Krepyak, Jendela Kaca (Lv 25), Tangga Kayu, Pagar Bambu (S Kampung), Pagar Kayu, Pagar Bata Rendah, Gapura Bambu, Undakan Batu.

**Atap (10):** Atap Ijuk, Atap Genteng, Atap Rumbia, Atap Seng, Atap Joglo (S Joglo), Atap Limasan, Atap Pelana Bambu, Atap Teras, Lisplang Kayu, Talang Bambu.

**Furniture (25):** Bale-bale (S Kampung), Kursi Rotan, Meja Kayu, Bangku Panjang, Lemari Jati, Lemari Kaca, Rak Piring, Rak Buku, Tempat Tidur Kayu, Kasur Kapuk, Tikar Pandan, Karpet Batik, Bantal Batik, Meja Rias, Cermin Ukir, Jam Dinding, Radio Tua, Lampu Minyak (S Kampung), Lampion Bambu (S Kampung), Gentong Air, Kendi, Ayunan Rotan, Kipas Anyaman, Meja Belajar, Sangkar Burung.

**Dekor (20):** Orang-orangan Sawah, Dermaga Kayu (S Sungai), Jembatan Bambu (S Sungai), Lampu Sungai (S Sungai), Perahu Mini (S Sungai), Bendera Kampung (S Sungai), Gerobak Jerami (S Kandang), Kincir Kecil (S Kandang), Papan Nama Kandang (S Kandang), Ember Seng (S Kandang), Lumbung Mini (S Kandang), Rumpun Bambu (hadiah Season), Pot Melati, Pot Lidah Mertua, Pohon Pisang Hias, Batu Taman, Lampu Taman, Air Mancur Gentong, Bangku Taman, Tugu Kampung.

Sumur Tua (S Kampung) = hasil Bundel, bukan item katalog. Tiap piece: 12 warna + 4 material lewat `Color`/`MaterialVariant`, bukan model terpisah.

### 4.9 Bundel Kakek (kerangka + pulih)

| Bundel | Model | Status | ★ |
|--------|-------|--------|---|
| Kolam Kakek | rusak + pulih | Cek | ★ |
| Sumur Tua | rusak + pulih | Cek | ★ |
| Lumbung | rusak + pulih | Cek | |
| Saung Kakek | rusak + pulih (+ titik duduk) | Cek | |
| Empang & Dermaga Kakek | rusak + pulih (+ spot mancing) | Cek | |

### 4.10 Props Alun-alun, Cuaca, Event

| Aset | Status | ★ |
|------|--------|---|
| Gerobak Kaget (gerobak + 3 slot pajang) | Cek | ★ |
| Papan Galeri Kampung (5 bingkai) | Cek | |
| Kebun Warga (4 petak NPC, K-17) | Belum | ★ bila K-17 (a) |
| Sampah Kerja Bakti (daun kering, ranting, kaleng, kertas) | Cek | ★ |
| Lapak Pasar Malam (6, satu per Pedagang Tamu) + lampion | Belum | |
| Permainan Lempar Gelang (botol + gelang) | Belum | |
| Joran hilang ×3 (Side Joran Hilang) | Belum | |
| Mangkuk makan kucing | Belum | |
| Event Agustusan: bendera, umbul-umbul, gapura, panjat pinang (dekor) | Belum (sekarang Part sementara) | |
| Event Lebaran: ketupat gantung, obor, beduk | Belum | |
| Event Tahun Baru: lampion, terompet (dekor) | Belum | |
| Event Hari Tani: orang-orangan, ikatan padi | Belum | |
| Event Festival Panen: tumpeng hasil bumi, keranjang | Belum | |

---

## 5. Animasi

Key yang statusnya Belum = **nama final**; Claude Code boleh menyesuaikan dengan struktur Config yang ada, asal konsisten.

### 5.1 Pemain

| Animasi | Key `Config` | Status | ★ |
|---------|--------------|--------|---|
| Tanam | `Farm.ANIMS.FarmPlant` (72416432910267) | Uji | ★ |
| Siram | `Farm.ANIMS.FarmWater` (106687765397165) | Uji | ★ |
| Mancing: Idle / Lempar / Tarik / Dapat | `Fishing.ANIMS` (FishingIdle, FishingCast, FishingReel, FishingCatch) | Uji | ★ |
| Cangkul (garap petak) | `Farm.ANIMS.FarmTill` | Belum | ★ |
| Panen (petik) | `Farm.ANIMS.FarmHarvest` | Belum | ★ |
| Tebang (kapak ke pohon) | `Mining.ANIMS.Chop` | Belum | ★ |
| Pukul (batu/tanah/pasir/bambu) | `Mining.ANIMS.Hit` | Belum | ★ |
| Critical (pukulan kuat, 1 frame tahan) | `Mining.ANIMS.Crit` | Belum | |
| Aduk masak | `Dapur.ANIMS.Stir` | Belum | ★ |
| Makan olahan | `Dapur.ANIMS.Eat` | Belum | ★ |
| Isi pakan / ambil telur | `Ranch.ANIMS.Feed`, `Collect` | Belum | ★ |
| Pasang hias (palu) | `Decor.ANIMS.Place` | Belum | ★ |
| Serah barang ke NPC (jual / setor) | `Npc.ANIMS.Give` | Belum | ★ |
| Pungut sampah | `KerjaBakti.ANIMS.Pick` | Belum | |
| Duduk (bale, saung) | default Roblox + pose | Cek | |
| Gestur: Lambai, Jempol, Tepuk Tangan, Ketawa | `Social.ANIMS.*` | Jempol belum (Roadmap §5 #10), lain Cek | |
| Lempar Gelang | `Repeat.ANIMS.Toss` | Belum | |
| Sorak (level up / Legenda, 1 dtk) | `Fx.ANIMS.Cheer` | Belum | |

Prioritas animasi pemain: `Action` untuk aksi, `Idle` untuk mancing menunggu. Durasi aksi ≤ 0,8 dtk agar loop tanam 1 dtk/petak tetap terasa cepat.

### 5.2 NPC

| Animasi | Siapa | Status |
|---------|-------|--------|
| Idle khas | Pak Udin sapu, Kak Fajar mancing, Mak Sari masak, Nek Ani duduk, Bang Jali berdiri santai, Pak Amran serut kayu | Cek |
| Bicara (gerak tangan ringan, loop) | Semua | Belum ★ |
| Menoleh ke pemain (prosedural, klien) | Semua | Ada |
| Melambai saat pertemuan pertama | Semua | Belum |
| Pengunjung Warung: jalan → beli → pergi | 3 generik | Belum |

### 5.3 Hewan, Ikan, Pet

| Animasi | Status |
|---------|--------|
| Ayam: jalan, patuk, duduk (idle lucu saat pakan habis) | Cek ★ |
| Bebek: jalan goyang, quack, idle | Cek |
| Sapi: jalan, makan rumput, rebahan | Cek |
| Ikan kolam/akuarium: berenang (tween prosedural, tidak perlu rig) | Cek ★ |
| Kucing: jalan, makan, tidur, mengusap kaki | Belum |

### 5.4 Motion UI (token di `UiKit`, angka motion — bukan angka desain)

| Token | Nilai | Dipakai |
|-------|-------|---------|
| `MOTION.POP` | 0,12 dtk, Back Out | Tombol ditekan, angka naik |
| `MOTION.PANEL_IN` / `OUT` | 0,22 / 0,16 dtk, Quad Out | Sheet slide dari bawah |
| `TOAST_FADE` | 0,25 dtk | Toast (K-38) |
| `BUBBLE_MIN` / `BUBBLE_MAX` | 0,18 / 0,22 dtk | Minimize / restore Bubble Instruksi |
| `FLY` | 0,6 dtk, kurva | Koin / item terbang ke HUD |
| `BANNER` | masuk 0,4, tahan 2,2, keluar 0,4 | Dimulai / Selesai |

Setting **"Kurangi gerak"** mematikan bounce dan layar bergetar.

---

## 6. VFX

Semua lewat satu modul (`FxService` klien, pool emitter, dipanggil dengan id efek). Id efek = kolom Key.

| Momen | Key | Efek | ★ |
|-------|-----|------|---|
| Cangkul | `fx.till` | Debu tanah kecil 6 partikel | ★ |
| Tanam | `fx.plant` | Tanah "puff" + daun kecil | ★ |
| Siram | `fx.water` | Percik air dari gembor + tanah jadi gelap (material Basah) | ★ |
| Panen Biasa | `fx.harvest.biasa` | Daun kecil 6–8 partikel | ★ |
| Panen Bagus | `fx.harvest.bagus` | + kilau putih hangat 4 bintang | ★ |
| Panen Prima | `fx.harvest.prima` | + partikel emas + cincin cahaya singkat | ★ |
| Tanaman matang | `fx.ready` | Kilau kecil berkala di ujung tanaman (bukan terus menerus) | ★ |
| Pasar Harian | `fx.market` | Ikon koin kecil melayang di atas petak | |
| Lempar kail | `fx.cast` | Cipratan kecil di titik jatuh | ★ |
| Gigitan | `fx.bite` | Pelampung tenggelam + riak + tanda "!" BillboardGui | ★ |
| Tarik sukses | `fx.catch` | Cipratan besar + tetesan | ★ |
| Ikan lepas | `fx.escape` | Riak menjauh | ★ |
| Firasat Legenda | `fx.firasat` | Gelembung emas di pelampung | |
| Legenda didapat | `fx.legend` | Pilar cahaya emas 1,5 dtk + gelembung | |
| Pukul node | `fx.hit` | Serpih sesuai bahan (kayu/batu/tanah/pasir/bambu/ijuk) | ★ |
| Critical | `fx.crit` | Serpih besar + kilat putih + kamera goyang 0,1 dtk (mati bila "Kurangi gerak") | ★ |
| Node habis / respawn | `fx.node_gone` / `fx.node_back` | Debu / tumbuh dengan skala | ★ |
| Craft | `fx.craft` | Bahan berputar menyatu di atas meja | ★ |
| Masak berjalan | `fx.cook` | Uap dari tungku (loop, rate rendah) | ★ |
| Masak selesai | `fx.cook_done` | Uap besar + ikon olahan memantul | ★ |
| Makan (buff) | `fx.buff.tani/pancing/tukang/tebang` | Aura tipis warna kategori 1 dtk + ikon buff terbang ke HUD | ★ |
| Produk ternak siap | `fx.product` | Ikon telur/susu melayang kecil di atas kandang | ★ |
| Mood Hujan | `fx.mood` | Tetes air kecil berkilau di kandang (BUKAN pelangi) | |
| Breeding selesai | `fx.breed` | Gelembung + ikan kecil melompat | |
| Hujan Gerimis / Deres / Petir | `fx.rain.*` | 30 / 60 / 90 partikel + kilat untuk Petir; genangan decal. **Kode (R6.5):** satu `ParticleEmitter` di `WorldController` ikut kamera, rate naik-turun 3 dtk (`Config/Weather` RAIN_FADE_SECONDS), Kualitas Rendah = mati. Kilat dan genangan belum (di luar R6.5) | ★ |
| Tanda hujan | `fx.rain_sign` | Langit menggelap (Lighting tween 10 dtk) | ★ |
| Kabut pagi, kunang-kunang malam | `fx.ambient.*` | Rate sangat rendah | |
| Pasang hias | `fx.place` | Debu kecil + "tok" | ★ |
| Ghost hias | — | Highlight hijau (bisa) / merah muda (nabrak) | ★ |
| Hapus hias / refund | `fx.refund` | Bahan terbang ke Tas | ★ |
| Set lengkap | `fx.set_done` | Kilau di semua piece set 1x | |
| Koin / Bunga / XP terbang | `fx.fly.*` | Ikon terbang ke counter HUD | ★ |
| Level naik | `fx.levelup` | Konfeti hangat (bukan neon) + cahaya di kaki | ★ |
| Album +1 | `fx.album` | Kartu kecil membalik | ★ |
| Quest Dimulai / Selesai | `fx.banner` | (di banner UI) kilau judul emas | ★ |
| Bundel pulih | `fx.restore` | Kerangka "tumbuh" jadi bangunan + debu emas | ★ |
| Kerja Bakti sampah dipungut | `fx.trash` | Puff kecil | ★ |
| Gerobak Kaget datang | `fx.cart` | Debu roda + lonceng (SFX) | ★ |
| Like | `fx.like` | Jempol / hati kecil di papan kebun | |
| Pasar Malam | `fx.night_market` | Lampion bercahaya (PointLight hangat) | |
| Kembang api Tahun Baru | `fx.firework` | Hanya saat event | |

---

## 7. SFX

Key di `Config/Audio`. Grup suara: `Musik`, `SFX`, `Ambience`, `UI` (masing-masing volume di Settings).

| Grup | Key | Bunyi | ★ |
|------|-----|-------|---|
| UI | `ui.tap` | Klik kayu lembut | ★ |
| UI | `ui.open` / `ui.close` | Gulungan kertas / lipat | ★ |
| UI | `ui.tab` | Tik kecil | ★ |
| UI | `ui.error` | Bunyi rendah lembut (bukan buzzer) | ★ |
| UI | `ui.claim` | Lonceng kecil | ★ |
| UI | `ui.coin` / `ui.bunga` | Koin gemerincing / denting bunga | ★ |
| UI | `ui.toast` | Pop halus | ★ |
| UI | `ui.levelup` | Jingle 2 dtk (angklung) | ★ |
| UI | `ui.album` | Kertas membalik + denting | ★ |
| UI | `ui.banner_start` / `ui.banner_done` | Gong kecil / jingle selesai | ★ |
| UI | `ui.npc_talk.<npc>` | "Blip" bicara (pitch beda per NPC) | ★ |
| Kebun | `farm.till`, `farm.plant`, `farm.water`, `farm.harvest`, `farm.prima` | Tanah, tanam, air, pop, denting emas | ★ |
| Mancing | `fish.cast`, `fish.plop`, `fish.bite`, `fish.reel` (loop), `fish.catch`, `fish.escape`, `fish.legend` | | ★ (kecuali legend) |
| Hutan | `mine.chop`, `mine.hit_stone`, `mine.hit_soft`, `mine.crit` (crunchy), `mine.gone` | Ganti placeholder `place_item` pitch-up | ★ |
| Craft | `craft.make` | Ketukan kayu + "ting" | ★ |
| Dapur | `cook.sizzle` (loop), `cook.done`, `eat` | | ★ |
| Ternak | `ranch.cluck`, `ranch.quack`, `ranch.moo`, `ranch.collect`, `ranch.feed` | | ★ cluck |
| Kolam | `pond.deposit`, `pond.withdraw`, `pond.breed_done` | Cebur kecil | ★ |
| Hias | `decor.place`, `decor.rotate`, `decor.delete`, `decor.refund` | | ★ |
| Sosial | `social.like`, `social.gesture` | | |
| Event | `event.cart_bell`, `event.night_market`, `event.toss`, `event.kerjabakti_pick` | | ★ cart, pick |

**Pemetaan SFX Kebun & Mancing (2026-11-24, R7.3):** key di atas dipetakan ke role `Config/SoundBank` (satu tempat untuk id). `farm.water` = `water_pour` (id ada). `farm.plant` = `plant_seed` (id ada). `farm.harvest` = `farm_harvest` = "cartoon pluck" id 126130663615387, 0.267 s, volume 0.4 (fallback `plant_seed` jika id kosong). `fish.bite` = `fish_bite` = "cartoon plop sound" id 18145114696, 0.540 s, volume 0.45. `fish.reel` = `fish_reel` (loop, saat gigitan). Id kosong = diam, tanpa error. Kedua id dicari dengan toolbox dan diukur `TimeLength` di Studio edit mode; belum dimainkan di Play.
| Cuaca | `wx.drizzle` (loop), `wx.heavy` (loop), `wx.thunder_far`, `wx.sign_rumble` | | ★ |

## 8. Ambience & Musik

| Key | Isi | Instrumen / rasa | ★ |
|-----|-----|------------------|---|
| `amb.pagi` | Ayam berkokok jauh, burung | — | ★ |
| `amb.siang` | Burung, angin daun | — | ★ |
| `amb.sore` | Jangkrik mulai | — | ★ |
| `amb.malam` | Jangkrik + kodok, kunang | — | ★ |
| `amb.sungai` | Air mengalir (3D, dekat sungai/kanal) | — | ★ |
| `amb.hutan` | Daun, burung hutan | — | |
| `music.menu` | Tema utama 60–90 dtk loop | Angklung + gitar akustik | ★ |
| `music.pagi` / `siang` / `sore` / `malam` | 4 lagu, ganti halus per fase | Kecapi, gamelan lembut, lo-fi, suling | ★ (1 lagu dulu) |
| `music.hujan` | Lapisan pelan di atas lagu fase | Piano + hujan | |
| `music.pasar_malam` | Ceria pelan | Gamelan, kendang ringan | |
| `music.event.<id>` | 5 tema event | Variasi tema utama | |
| Sting | Legenda (3 dtk), Selesai Main Quest (2 dtk) | | |

Aturan: musik volume default 50%, tidak pernah lebih keras dari SFX aksi. Tidak ada lagu berlirik. Tidak memakai lagu milik orang lain.

## 9. Haptic

| Momen | Kekuatan |
|-------|----------|
| Panen (semua) | Sangat ringan |
| Panen Prima | Ringan |
| Critical | Ringan |
| Tarik sukses | Sedang |
| Legenda | Sedang, 2 denyut |

Bisa dimatikan di Settings. Claude Code wajib cek dukungan perangkat (`HapticService`) dan diam bila tidak didukung.

---

## 10. Ikon & 2D

| Kelompok | Jumlah | Status | ★ |
|----------|--------|--------|---|
| Tombol HUD: Acara, Skill, Hadiah, Warga, Toko, Atur, Garap, Kolam, Hias, Tas, Pesanan, Quest, Season, Album, Surat, Papan Hari Ini | 16 | Acara & Skill **Belum** (placeholder teks), lain Cek | ★ |
| Tombol Aksi: Mancing (Ada), Pukul, Tebang, Kelola Kandang, Breeding, Craft, Masak | 7 | 1 Ada | ★ |
| Item: 18 tanaman (+ versi bibit), 6 varian, 20 ikan, 24 olahan, 7 bahan mentah + 7 olahan, Garam, Daun Pisang, Jerami, 4 umpan, telur ×2, susu, 4 pakan, ±20 alat | ±135 | Umpan **Belum** (placeholder "tas") | ★ Lv 1–10 |
| Skill (unik per skill, K-35) | 16 | Belum | ★ |
| Buff | 4 | Cek | ★ |
| Fase hari, cuaca | 4 + 3 | Cek | ★ |
| Kualitas badge (bentuk beda: titik / daun / bintang) | 3 | Cek | ★ |
| Title badge | 10 | Belum | |
| Potret NPC | 6 + 7 + tamu | Cek | ★ |
| Skin UI ForgeGUI: panel, ribbon, plate, close, **skin bambu tipis** untuk bubble (K-38) | — | Skin tipis Belum | ★ |
| Ikon game & 5 thumbnail toko | 6 | Belum | (R11.2) |

Format ikon: 256×256 PNG transparan, gaya ForgeGUI yang sama, garis luar gelap tipis agar terbaca di atas parchment maupun air.

---

## 11. Juice per Momen Kunci (gabungan)

Supaya tiap aksi terasa "enak", Claude Code memasang paket ini sekaligus:

| Momen | Animasi | VFX | SFX | UI | Haptic |
|-------|---------|-----|-----|----|--------|
| Panen | FarmHarvest | `fx.harvest.<kualitas>` | `farm.harvest` / `farm.prima` | Item terbang ke Tas, angka Koin pop | Ringan (Prima) |
| Ikan dapat | FishingCatch | `fx.catch` | `fish.catch` | Kartu ikan (ukuran + "BARU!" bila pertama) | Sedang |
| Critical | Crit | `fx.crit` | `mine.crit` | Angka "+2" memantul | Ringan |
| Masak selesai | — | `fx.cook_done` | `cook.done` | Slot berkedip "Ambil" | — |
| Level naik | Cheer | `fx.levelup` | `ui.levelup` | Banner LEVEL n + toast "Terbuka: …" | — |
| Quest Main selesai | — | `fx.banner` | `ui.banner_done` | Banner Selesai, GUI lain disembunyikan | — |
| Bundel pulih | — | `fx.restore` | sting kecil | Toast + kamera menyorot 2 dtk | — |
| Legenda | Cheer | `fx.legend` | sting Legenda | Banner server | 2 denyut |

---

## 12. Placeholder Aktif (daftar)

| Aset | Dipakai di | Keterangan | Status |
|------|-----------|------------|--------|
| Gembor Emas (ikon + model) | Hadiah `side_prima` (K-15, dialog `dlg.side_prima.done.1`) | Model Gembor yang ada, diwarnai emas. Visual saja, tanpa stat. | **PLACEHOLDER (replace in Fase 4)**. Belum dibangun: item & aturan "tidak mengubah siram" menunggu kerja fitur |
| Warna dinding ke-13 "Dinding Spesial" | `Config/Decor` WALL_PALETTE_EXTRA | Satu warna muted hangat (214,178,124). Tidak butuh aset. | **PLACEHOLDER (replace in Fase 4)** |
