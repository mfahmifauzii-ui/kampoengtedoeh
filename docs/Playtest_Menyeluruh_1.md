# Playtest menyeluruh 1 (15 Nov 2026)

Dilakukan di Studio (Play) dengan save uji, lewat klik/ketik simulasi, pemanggilan remote, dan pembacaan state; ditambah audit kode untuk suara, VFX, dan kamera.
**Batasan penting:** setelah beberapa kali start/stop, tangkapan layar Studio hanya menampilkan GUI dengan dunia 3D hitam (viewport tidak menggambar saat dicek; log tidak ada error). Karena itu **semua pemeriksaan visual 3D di bawah ini dari sesi sebelumnya (screenshot yang berhasil) atau lewat state/atribut, bukan dilihat ulang**. Suara tidak bisa didengar dari sini; hanya diperiksa bahwa role dimuat dan tidak ada peringatan.

## Diperbaiki
| # | Temuan | Perbaikan |
|---|---|---|
| 1 | **Teks petunjuk dan toast terlalu panjang** (kalimat 60–100 karakter; tidak ada yang baca). | 40+ string dipangkas (petunjuk ≤ ±45 karakter, sapaan NPC 1 kalimat). Aturan baru di `GUI_Design.md`. Toast beruntun tidak lagi antre 1,8 d tiap satu (0,9 d bila ≥ 2 menunggu). |
| 2 | Teks di kotak gelap tampak keruh: `UIStroke` di `TextLabel` mengoutline huruf emas. | `ApplyStrokeMode = Border` di semua kotak gelap, font bold. Label "Siap panen!" di atas petak ikut dikontraskan. |
| 3 | Menu Garap berupa popup 4 tombol. | Dua tombol dock (Cangkul, Kolam); hijaukan/urug otomatis (lihat `GUI_Design.md`). |
| 4 | **Efek suara efek suara tidak bisa dimatikan**: `Sfx.play` tidak lewat SoundGroup `sfx`. | Sfx kini masuk grup `KT_sfx` sehingga Atur > Efek suara benar-benar mematikannya. |
| 5 | **Hampir tidak ada suara**: hanya 5 (lempar, tarik, tangkap, tanam, siram). Jual, pesanan, level, belanja, klik tombol, panen, cangkul, hias, ngobrol semuanya senyap; peta `Audio.SFX` isinya nil. | 7 role baru di `Config/SoundBank` (dicari di toolbox lalu **dimuat dan diukur di Studio**): `ui_click`, `coin_gain`, `level_up`, `order_done`, `notify_ding`, `npc_hello`, `place_item`. Dipasang: setiap tombol UiKit dan tombol dock, jual/beli, pesanan/quest/peti/hadiah, naik level, koleksi baru, kolam jadi, hias terpasang, buka dialog NPC; cangkul/hijaukan dan panen memakai suara gali yang ada dengan nada diubah. |
| 6 | **Kamera saat ngobrol dengan NPC tidak ada** (kamera diam di belakang pemain, NPC membelakangi). | Kamera meluncur 0,55 d ke bidikan dekat dari samping (FOV 52, 7 stud), NPC menoleh ke pemain (hanya di klien); menutup mengembalikan kamera 0,4 d. Dites: tipe Scriptable, FOV 52, kamera bergerak 11,5 stud, kembali Custom/FOV 70 setelah Sampai jumpa. |
| 7 | Naik level hanya sebuah toast dan semburan kecil. | Banner "LEVEL n!" besar (pop-in, tahan 2 d, memudar) + suara. Dites dengan `!level 2`. |
| 8 | **Pisang jebakan**: 8 jam, 3 panen × 120 − bibit 200 = 160 Koin per 24 jam (±7/jam) vs Padi 140 per 2 jam. Tidak ada alasan menanamnya. | Harga jual pisang 120 → 380 (±39/jam, tetap lebih rendah dari padi tapi layak "tanam sebelum tidur"). |
| 9 | Teks usang: kuest "Kolam Pertamamu" masih bilang "Garap → Kolam", tujuan "ketuk Garap". | Diganti ("Tekan tombol Kolam, ketuk lahan kosong"). |
| 10 | Panah/cincin tutorial hanya di HUD. | Menjangkau tombol apa pun (lihat `Tutorial_Engine.md`). |

## Ditemukan, belum diperbaiki (urut prioritas)
1. **Terlalu banyak ketukan per panen** dan **hampir tanpa keputusan** (lihat `Gameplay_Review.md`, tahap L1–L2). Terbesar untuk retensi.
2. **Hadiah pesanan mingguan di Lv 1: 1.026 Koin + 5 Bunga + hiasan** (9 Cabai + 18 Kangkung, ×3 hadiah). Hampir setara blok lahan pertama (1.500) di sesi pertama. Sebaiknya pesanan mingguan baru muncul setelah T2/Lv 5 dan pengali dihitung ulang di simulasi P8 (`Config/Orders` `WEEKLY_REWARD_MULT`).
3. **XP pesanan terlalu besar di awal**: satu pesanan 3 Cabai memberi 23 XP (Lv 2 butuh 20) sementara 3 panen Cabai hanya 9 XP.
4. **Nilai Koin per menit petak menurun menurut tingkat tanaman** saat pemain aktif (Kangkung ±4/menit, Padi ±1,2/menit): benar bagi pemain yang jarang kembali, tetapi pemain aktif tidak punya alasan membuka tanaman baru. Perlu simulasi sebelum mengubah harga (jangan sebelum P8).
5. **NPC yatim `bang_tarno`** (rig tangan lama) berdiri di alun-alun di (-43, 5, -28) tanpa prompt dan tidak ada di `Config/Npcs`; sisa versi lama. Hapus dari Workspace.Npcs di Studio (tidak saya hapus karena itu isi file place).
6. **Peringatan `rbxassetid://203785492` (Asset type does not match requested type)** muncul 6× tiap start; pelacakan di semua properti Part/Mesh/Sound/Decal/Image di Edit tidak menemukannya. Kemungkinan Texture/Animation/Sky di Terrain/Lighting; belum ketemu.
7. **Dermaga dan Warung Mini jauh**: lahan awal ke Pak Darmo ±240 stud (±15 d jalan) tanpa Sprint; perlu dicek di HP.
8. **Viewport hitam di capture** (batas alat uji, bukan bug game bila terbukti di Studio biasa): cek sekali di Studio Anda.

## Belum tercakup
Mancing penuh (lempar, gigitan, tarik; kolam penangkaran), toko selain Pak Darmo, hias penuh (taruh, putar, simpan), Hadiah/Koleksi/Warga/Toko Robux secara visual, HP asli, 2+ pemain, performa. Silakan jalankan ulang tahap ini ketika viewport bisa ditangkap.
