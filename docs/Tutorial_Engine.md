# Mesin Tutorial (P1, 15 Nov 2026)

Rujukan teknis mesin yang dijelaskan di `Implementation_Plan.md` bagian 3 (tutorial T1, T1b, T2 … diisi di tahap berikutnya). Warung Mini tidak disentuh. Sprint dibatalkan.

## Data
`data.guide` (ditambah lewat Reconcile, tanpa migrasi; `sells` tetap untuk panduan lama):

| Kunci | Arti |
|---|---|
| `step = {id, n}` | tutorial yang sedang berjalan dan jumlah langkah yang sudah selesai (`id = ""` = tidak ada) |
| `done[id]` | tutorial selesai |
| `skipped[id]` | tutorial dilewati |
| `fastLeft` | sisa penanaman dengan timer cepat. `-1` = belum diputuskan: saat load, save baru (tanpa petak, tanpa `first_plant`, `sells = 0`) dapat `FAST_PLANTINGS` = 6, save lama dapat 0 |

Snapshot ke klien: `snapshot.guide = {step, done, skipped, fastLeft, fresh}`. `fresh` dihitung server tiap snapshot (pemicu `newPlayer`).

## Config (`Config/Onboarding`)
`TUTORIALS` berisi T1 (`t1_awal`, lihat "T1 sekarang" di bawah). `Tutorial`: `id`, `title`, `trigger`, `intro?`, `steps` (1–5), `reward?`, `auto?`. Tiap `Step`: `id`, `text`, `textStuck?`, `done` (kondisi `>=`), `highlight?` (nama tombol HUD), `target?` (`npc` atau `pos`, panah di tanah), `arrive?`, `reward?`, `modal?` (judul dan isi modal, hanya untuk kondisi `ack`).
- Kondisi: `always`, `tiles`, `planted`, `watered`, `ripe`, `item` (awalan id), `level`, `near` (npc), `panel` (nama ScreenGui), `garap`, `sells` (jumlah jual ke pembeli, `snapshot.guideSells`), `ack` (pemain menekan Mulai di modal, `id` = id langkah; hanya dari modal, tidak pernah dari waktu).
- Pemicu: `newPlayer`, `level`, `done` (tutorial lain selesai/dilewati), `manual`.
- Angka: `GAP_SECONDS` 120, `STUCK_STRONG` 45, `STUCK_TEXT` 90, `REPLAY_MIN_SECONDS` 4, `FAST_PLANTINGS` 6, `FAST_GROW_SECONDS` 20.
- `TEST_TUTORIAL` (`dev_test`, hanya Studio, `auto = false`): 3 langkah untuk menguji mesin. Ubah `auto = true` untuk melihatnya mulai sendiri di save baru Studio.

## T1 sekarang (`t1_awal`, newPlayer, auto)
Lima langkah, satu kalimat tiap langkah:
0. **sapa**: modal "Mbok Minah" (judul) dan "Selamat datang! Yuk, coba berkebun dulu." (isi). Tombol kiri **Lewati** (skip T1), kanan **Mulai** (langkah 1 mulai). Modal tidak hilang sendiri: langkah ini selesai hanya saat Mulai ditap (`ack`). Tidak ada hadiah.
1. **cangkul**: "Tap Cangkul, lalu tap rumput". Selesai saat `tiles >= 1`. Sorot `GarapButton`. Hadiah 1 XP.
2. **tanam**: "Pilih bibit, tap petak kosong". Selesai saat `planted >= 1`. Sorot pill **Tanam** (`TanamButton`, pill petak kosong di FarmFloat). Teks macet: "Bibit awal tumbuh cepat, ditunggu ya". Hadiah 1 XP.
3. **siram**: "Tap petak, lalu Siram". Selesai saat `watered >= 1`. Sorot pill **Siram** (`SiramButton`). Hadiah 1 XP.
4. **panen_jual**: "Panen, lalu jual ke Pak Darmo". Selesai saat `sells >= 1`. Sorot pill **Panen** (`PanenButton`) dan panah ke Pak Darmo. Hadiah tutorial: 30 Koin, tanpa Bunga dan hiasan.

Intro bukan lagi hint 4 detik: langkah 0 tetap tampil sampai Mulai atau Lewati. Modal memakai `UiKit.confirm` (`cancelText`/`confirmText`), dengan ukuran maks 86% lebar × 86% tinggi layar.

Setelah Mulai, setiap langkah dengan aksi tampil sebagai **coachmark** (`CoachmarkController`, lihat UIUX_Spec "Coachmark"):
- Langkah 1 (cangkul): sebelum Garap dibuka, coachmark fokus tombol **GarapButton** ("Tap Garap dulu"). Setelah Garap terbuka, coachmark pindah ke **fokus tanah** ("Tap rumput yang menyala") di depan pemain. Selesai saat `tiles >= 1`.
- Langkah 2 (tanam): fokus pill **TanamButton** ("Tap Tanam di petak kosong"). Garap ditutup otomatis di langkah ini. Teks macet: "Bibit awal tumbuh cepat, ditunggu ya".
- Langkah 3 (siram): fokus **SiramButton**. Langkah 4 (panen_jual): fokus **PanenButton**, tanpa blok (`block = false`), karena Pak Darmo ada di luar lubang.
- Hint bar lama disembunyikan saat coachmark aktif. Lewati coachmark = Lewati T1 (sama dengan Lewati di modal).

## Spawn di depan gerbang dan kamera awal (T1)
- **Siapa**: hanya pemain baru yang T1-nya belum selesai atau dilewati dan belum pernah menjual (`sells == 0`, `first_plant` belum true). `PlotService.isNewPlayer`. Pemain lama tetap di posisi terakhir (`SPAWN_OFFSET`).
- **Posisi**: `Plots.GATE_SPAWN` = 4 stud di luar gerbang, di sisi jalan lahan (`Plots.FRONT_Z`, gerbang 32 stud di tengah). Karakter menghadap gerbang (`CFrame.lookAt`). Pemain harus jalan 3–4 langkah masuk lewat gerbang.
- **Atribut**: server menulis `GateSpawn` (boolean) di Player tiap spawn. Klien membaca atribut ini.
- **Kamera**: `CoachmarkController` memasang kamera **sekali** di belakang karakter, 11 stud ke belakang dan 5,5 stud ke atas, melihat ke gerbang. Setelah 1,2 detik kamera kembali ke `Custom` (kontrol normal). Tidak ada kunci kamera selama T1.
- **Batas**: Mbok Minah tidak dipindahkan (NPC tidak diubah). Posisi dia di sekitar gerbang belum dicek.

## Server (`TutorialService`)
Satu remote `GuideEvent(action, id, n?)`: `start`, `step` (hanya maju, n ≤ jumlah langkah; membayar hadiah langkah; langkah terakhir menandai `done` dan membayar hadiah tutorial), `skip`, `replay` (hanya analytics, tanpa perubahan data dan hadiah). Satu tutorial aktif; tutorial selesai/dilewati tidak bisa dimulai lagi. `ConsumeFast(player)` dipanggil `FarmService.onPlant` setelah bibit berhasil dipakai: bila `fastLeft > 0`, kurangi satu dan `readyAt = now + 20`. Panen berulang memakai timer normal. Siram tetap −20% (16 d).
Catatan keamanan: klien yang menentukan kapan langkah selesai (ia yang melihat dunia); server hanya mengizinkan penghitung maju dan membayar hadiah kecil sekali. Cukup untuk hadiah T1–T5 yang kecil; bila hadiah dibesarkan, pindahkan pengecekan kondisi ke server.

## Klien (`GuideController`)
- Satu tutorial aktif. Mulai otomatis: lanjut tutorial tersimpan (tanpa jeda); selain itu, bila sudah lewat `GAP_SECONDS` sejak tutorial terakhir berakhir, tutorial pertama (urutan config) yang pemicunya terpenuhi dan belum selesai/dilewati.
- Tidak memblokir: tiap tick, semua langkah berurutan yang kondisinya sudah terpenuhi otomatis dicentang. Langkah `always` dan semua langkah saat replay tertahan minimal 4 d.
- UI: hint bar yang sama (dengan tombol **Lewati**; ia turun di bawah baris petunjuk Garap/Hias), jalur panah dari target langkah (`step.target`), cincin berdenyut + panah melambung (atas/bawah/kiri, pilih sisi yang lega) di tombol bernama `step.highlight`, di layar mana pun yang terbuka (HUD, dock, panel); `GuideRing` jadi anak tombol.
- Macet: tanpa kemajuan 45 d → cincin lebih terang dan besar; 90 d → `textStuck` (atau teks langkah + `tut.stuck_suffix`). Tidak pernah memaksa.
- Panduan lama (hint + panah ke Pak Darmo, `guide.sells < 3`) tetap jalan saat tidak ada tutorial aktif.
- Atur > **Panduan**: daftar tutorial dengan status (Belum dimulai / Sedang berjalan / Selesai / Dilewati) dan tombol **Ulang** (tanpa hadiah, tanpa mengubah save; mati selagi ada tutorial lain berjalan).

## Analytics (`AnalyticsService:LogCustomEvent`, field `CustomField01` = id tutorial)
`tut_<id>_start`, `tut_<id>_<langkah>`, `tut_<id>_done`, `tut_skip`, `tut_replay`. Funnel `joined → first_decor` tidak berubah.

## Teks
Semua lewat `Locale/id.luau`: `tut.*`, `settings.guide*`, `ui.guide`, `tut.dev_test.*`.

## Perintah Studio
`!tut` mencetak `data.guide`; `!tut reset` melupakan step/done/skipped; `!tut fast` mengisi `fastLeft = 6`. `!reset` ada di DevService (wipe lalu kick), tetapi di Studio ini save tidak kosong setelah rejoin, jadi tidak dipakai untuk tes save baru.

## Hasil uji Studio (15 Nov 2026)
- **Save lama** (Lv 1, `sells = 1`): masuk tanpa error; `fastLeft = 0`; `fresh = false`; tutorial tes tidak mulai; panduan lama tetap tampil.
- **Save kosong** (`!reset`): `fastLeft = 6`; tutorial tes mulai sendiri; cincin berdenyut di tombol Garap; Lewati tampil; hint turun di bawah baris Garap; langkah 1 (Garap terbuka) dan 2 (2 petak, +1 XP dari server) tercentang; panah tampil ke Pak Darmo di langkah 3; teks macet muncul setelah 90 d.
- Rejoin di tengah tutorial → lanjut dari langkah tersimpan. **Lewati** → tersimpan sebagai dilewati, tidak mulai lagi setelah rejoin, panduan lama kembali. Panduan: status benar, **Ulang** memutar dari awal dengan pengantar.
- Bibit cepat: tanam pertama tumbuh 20 d, `fastLeft` 6 → 5, setelah disiram sisa waktu ×0,8.
- Layar yang dicek lewat screenshot Studio (viewport 1335×630, bukan HP).

## Hasil uji Studio (T1 + modal sapaan, dikerjakan)
- **Save lama** (Lv 3, `sells = 3`): tidak ada modal, T1 tidak mulai, `step` tetap kosong.
- **Save baru** (`!tut_new`, dihapus lagi setelah tes): modal Mbok Minah muncul saat join dan tetap terbuka (diamati lebih dari 9 detik). Mulai → langkah 1 mulai, ring di GarapButton, server mencatat `step = t1_awal, n = 1`.
- **Rejoin sebelum langkah 0 selesai**: modal muncul lagi (resume di langkah 0).
- **Lewati**: server mencatat `skipped.t1_awal = true`, `step` kosong. Setelah rejoin, tidak ada modal dan tidak ada ring.
- **Coachmark (Studio, screenshot)**: spawn di depan gerbang (modal terbuka, kamera di belakang karakter). Mulai → coachmark Garap, overlay menelan klik Atur, hanya Garap yang bisa ditap. Garap → coachmark tanah. Satu petak dibuat dengan tap di lubang tanah → Langkah 1 selesai → coachmark Tanam di pill TanamButton (lubang tepat di pill).
- **Lewati dari coachmark**: server mencatat `skipped.t1_awal = true`. Ulang dari Atur > Panduan memunculkan modal lagi tanpa hadiah (Koin tetap 150).
- **Belum dites**: langkah 2–4 sampai hadiah 30 Koin, ring SiramButton dan PanenButton, rejoin ulang setelah Lewati coachmark (sudah diuji untuk Lewati modal), save lama Lv 3 setelah perubahan spawn, HP asli, 2+ pemain, save DataStore asli.

## Putaran terbaru (grid 2 stud, proximity, Pindah dengan tanaman, plang, Atur 1×4)
- **Flow nanam**: tanam sekarang lewat popup proximity (1 stud dari petak kosong), bukan picker modal. Tap petak kosong tidak membuka apa-apa. Dari popup: tap ikon bibit terang = tanam, lalu popup tutup. Ikon abu = tip "Bibit habis, beli di Toko". Ikon gembok = tip "Buka di Lv N".
- **Pindah** berlaku untuk petak kosong dan petak ditanami. Tanaman, `PlantedAt`, `ReadyAt`, dan status siram ikut pindah; timer tidak di-reset. Hapus Petak tetap hanya untuk petak kosong (merah bata).
- **Grid** satu visual: garis 2 stud (Hias) dan garis tebal 8 stud (batas petak Garap). Garap nge-snap ke 8 stud; Hias nge-snap ke 2 stud.
- **Plang gerbang** fisik menggantikan label melayang.
- **Atur** 1×4.

### Yang sudah dites di Studio (putaran ini)
- Grid 2 stud: garis tebal 8 stud terlihat; ghost Garap pas ke kotak 8×8; ghost abu di jalan, hijau di rumput.
- Popup proximity: muncul di atas petak kosong dalam jarak, dengan ring putus-putus; ikon kangkung terang (x3) dan ikon abu x0 terlihat benar; tap ikon terang menanam (server mencatat `ReadyAt`, petak berisi kangkung).
- Pindah petak ditanami: `(-48, 296)` → `(-40, 296)`. `PlantedAt` 1794759022 dan `ReadyAt` 1794759042 **tidak berubah**. Kangkung tetap di petak.
- Hapus Petak: menu petak kosong dengan merah bata (tombol Hapus, screenshot). Eksekusi Hapus belum diverifikasi di putaran ini.
- Menu petak ditanami: Pindah hijau aktif, Hapus abu terkunci, teks benar.
- Atur 1×4: empat baris penuh lebar, toggle dan Buka terlihat.
- Plang gerbang: "Kebun …" tampil di plang (screenshot menunjukkan papan kayu di samping gerbang).

### Belum dites di putaran ini
- Hapus Petak dieksekusi (konfirmasi lalu petak hilang); tes ini terhambat karena klik tombol Hapus tidak selalu tervalidasi.
- Tahan 0,3 detik pada ikon (tip nama · xN); animasi stagger 0,05 detik.
- Tap ikon 0 dan terkunci (tip tampil; tidak bisa ditanam) secara langsung.
- Sel terblokir (ghost merah di bawah bangunan/jalan) dengan ghost yang ditaruh.
- Drag siram, Panen Semua, Jual Semua, alat siram Gembor/Sprinkler: **belum dikerjakan** (lihat "Ditunda").
- Lewati coachmark dan Ulang dari Panduan (klik panel tidak stabil di tes ini; Replay mengembalikan false karena T1 sudah selesai di save ini).
- HP asli, 2+ pemain, save DataStore asli.

### Ditunda (bagian 8 dan 9 prompt)
- **Flow Panen Semua / Jual Semua / drag siram / alat siram (Gembor, Sprinkler)**: belum ada di kode. Ini fitur baru, butuh desain dan remote baru. Dikerjakan di langkah berikutnya.
- **Tap kontekstual** (tap petak kering = siram, tap petak matang = panen): sudah berlaku (perilaku lama), tapi tidak diuji ulang di putaran ini.

## Putaran perbaikan (grid, Pindah, copy, panel)
- **Langkah tanah** sekarang memakai grid Garap dan ghost + arrow (bukan ring tetap di satu titik). Dunia 3D tidak digelap; hanya panel UI yang digelap dan diblokir (`CoachmarkController`, mode "ground").
- **Garap** ditutup otomatis saat langkah Tanam mulai, karena pill bibit tersembunyi selama mode Garap aktif.
- **Tanam, Siram, Panen**: highlight mengikuti bentuk pill. Pill Panen tanpa blok (`block = false`), dengan arrow melayang ke Pak Darmo.
- **Pindah dan Hapus Petak** (fitur desain, bukan langkah T1): tahan pill petak kosong → menu. Petak yang ditanami terkunci dengan teks penjelasan. Pindah memakai grid dan ghost yang sama. Remote baru `FarmMove` (server cek jarak, lahan sendiri, sel bebas, belum ditanami).
- **Hapus Petak** memakai remote `FarmLevel` yang sudah ada (dulu "Hijaukan" di Garap; sekarang tidak ada lagi).
- **Modal Mbok Minah**: Mulai = hijau solid (utama), Lewati = krem muda kecil (sekunder).
- **Hint bar**: disembunyikan saat coachmark, modal, atau panel terbuka. Hint Garap ikut disembunyikan saat coachmark aktif.
- **Panduan**: entri "Tes mesin panduan (Studio)" tidak lagi ditampilkan.
- **Atur**: panel menyusut mengikuti isi (dua kolom kartu, tanpa scrollbar).
- **Copy**: "Ketuk" dan "Tekan" diganti "Tap" untuk aksi layar.

### Hasil uji (Studio, putaran ini)
- **T1 dari awal sampai selesai**: modal → Mulai → Garap (coachmark tombol) → tanah (ghost + grid) → petak dibuat → Tanam (pill, Garap tutup) → Siram → Panen → Jual ke Pak Darmo. `done.t1_awal = true`, `sells = 1`. Koin 150 → 189 (hadiah 30 + hasil jual). Penjualan dikirim lewat remote `Sell` dari klien setelah karakter dipindah ke dekat Pak Darmo (jalur tes, bukan lewat dialog).
- **Pindah**: tahan pill petak kosong → menu → Pindah → grid + ghost → tap sel valid. Petak pindah satu sel (−32, 288) → (−40, 296).
- **Hapus Petak**: menu → konfirmasi → petak hilang (`FarmTile` milik pemain = 0).
- **Terkunci**: long-press pill petak ditanami → teks "Lagi ditanami, tidak bisa dipindah", kedua tombol abu pudar.
- **Grid**: 160 garis, dari chunk yang dimiliki saja (x −64..64, z −32..96 di plot). Transparansi 0.62.
- **Ulang**: modal muncul lagi tanpa hadiah, Koin tetap.
- **Lewati coachmark**: diuji sebelumnya (server mencatat `skipped`). Belum diuji ulang setelah putaran ini.

## Keputusan yang masih terbuka
- **Grid 8 stud atau 2 stud?** Petak tanam = 8 stud (`Land.TILE`), jadi grid dibuat 8 stud agar ghost pas dengan petak. Hiasan terkecil = 2 stud. Kalau grid harus 2 stud, petak harus pindah ke grid 2 stud, dan itu mengubah data petak (migrasi save).
- **Mbok Minah dekat gerbang**: NPC ini satu di kota, dan ada 8 gerbang lahan. Memindahkan satu NPC ke satu gerbang salah untuk pemain lain. Pilihan: klon NPC per lahan (muncul di gerbang pemain baru), atau tetap di kota.

## Belum teruji
- HP asli: ukuran tombol Lewati, hint bar vs joystick, cincin di dock yang menyempit (mode HUD ringkas), tahan 0,45 detik untuk menu petak, grid dan ghost lewat sentuh.
- Cincin lebih terang pada 45 d (logika sama dengan 90 d, tidak dilihat di layar); pengulangan penuh sampai langkah terakhir; langkah `ripe`, `watered`, `item`, `level`, `panel`, `near` (hanya `garap`, `tiles`, `near` diuji lewat tutorial tes; `near` belum diselesaikan).
- Jeda antrean 120 d antar dua tutorial otomatis (hanya ada satu tutorial otomatis); `newPlayer` pada save lama tanpa petak.
- Hadiah koin/item/Bunga dan hadiah tutorial penuh (hanya XP langkah diuji); event analytics di dashboard Roblox (hanya dipanggil, dibungkus pcall).
- Timer bibit normal setelah 6 penanaman (kode: `fastLeft = 0` → timer biasa; belum ditanam sampai habis); bibit unggul pada penanaman cepat.
- 2+ pemain; bibit tutorial dengan hujan.
- Catatan: `docs/Implementation_Plan.md` belum ada di repo (versi yang dibaca ada di folder Downloads); dompet awal Studio saat ini 150 Koin, bukan 100 (P8).
