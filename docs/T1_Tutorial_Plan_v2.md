# Plan Tutorial T1 v2 (intro sampai penutup)

Status: PLAN, belum ada kode. Menunggu keputusan di bagian 4.

## 1. Yang saya tangkap (14 permintaan, dikelompokkan)

| # | Permintaan | Jenis |
|---|---|---|
| A | Transisi setelah ngobrol NPC: layar gelap dulu, lalu dissolve, baru tutorial mulai | client |
| B | "Panen Semua" baru muncul di Lv 3 (sekarang muncul di Lv 1); kenalkan dengan coachmark saat Lv 3 tercapai | client + 1 flag |
| C | Selama ngobrol NPC, prompt "Ngobrol" hilang | client |
| D | Pertemuan pertama dengan SETIAP NPC: percakapan perkenalan dulu ("Loh <nama> kamu sudah pulang? Bagaimana kabarnya", lalu "kamu bisa jual dan beli ..."), baru tombol Jual/Beli atau Sampai jumpa | client + server (flag "sudah kenal") |
| E | Setelah jual hasil panen pertama, LANGSUNG cutscene (POV NPC tidak boleh berubah karena pemain keburu jalan) | client |
| F | Kolam bukan diperkenalkan Pak Darmo. Pak Darmo menyuruh temui NPC alat pancing, yang memberi joran gratis sebagai hadiah | client (+ server kalau hadiah harus nyata) |
| G | Mas Joko: berkenalan lagi, kasih joran, tombol "Terima hadiah", feedback dapat joran, tunjukkan lokasi mancing | client |
| H | Di dermaga: Mas Joko lanjut, pemain tekan Mancing, dialog disembunyikan saat mancing, dapat ikan -> Mas Joko jelaskan cara, "selamat, bawa ikan ke Kolam; belum ada kolam? buat dulu", tombol "Mengerti" menutup teks + coachmark | client |
| I | Kembali ke lahan: panah di tanah menuntun pulang | client |
| J | GUI melayang "Kebun <nama>" di atas lahan sendiri, besar, hanya dilihat pemilik, selalu (bukan hanya tutorial), hilang bila pemain sudah di zona lahannya | client |
| K | Di lahan: Mbok Minah ajari bikin Kolam; setelah jadi, minta pindahkan ikan ke kolam lewat GUI pindah item (gaya UiKit, seperti gambar daftar kiri-kanan). Tidak bisa mancing di kolam sendiri, tapi bisa ambil ikan. Dekat kolam ada GUI melayang untuk membuka GUI pindah (tas <-> kolam, ambil semua / taruh semua) | client + SERVER |
| L | GUI mancing tertutup teks percakapan: saat mancing teks dihilangkan | client |
| M | Penutup: closing statement, cutscene Mbok Minah: bikin 1-2 petak garap baru, kenalkan Misi dan Pesanan, tombol "Mengerti" lalu tutorial selesai | client |
| N | Semua tetap client-only kecuali yang tidak mungkin | aturan |

## 2. Storyboard baru (urutan layar yang dialami pemain)

Pembicara dan lokasi tiap babak mengikuti permintaan Anda. "Cut" = transisi gelap lalu dissolve (A).

1. **Intro** (sudah ada): loading, Mbok Minah datang dari kanan, 4 dialog dengan Next, ia berdiri di gerbang.
2. **T1 langkah 1-4** (sudah ada): Garap, Tanam, Siram, Tunggu/Panen. Dialog Mbok Minah tanpa kamera ngobrol.
3. **Penjualan pertama ke Pak Darmo**: begitu `guideSells` jadi 1, panel toko otomatis ditutup dan gerakan dikunci seketika, lalu cut ke cutscene (E). Tidak menunggu panel ditutup pemain dan tidak menunggu poll 0,25 detik.
4. **Pak Darmo, perkenalan pertama** (D): "Loh Piko, kamu sudah pulang? Bagaimana kabarnya?" lalu "Di sini kamu bisa jual hasil panen, beli bibit, dan upgrade". Setiap baris Next.
5. **Pak Darmo menyuruh temui Mas Joko** (F): "Temui Mas Joko di Toko Pancing, dia punya hadiah untukmu". Arah: panah di tanah, kamera kembali ke pemain lewat transisi.
6. **Mas Joko, perkenalan** (D, G): sapaan pertama, lalu tawaran "Terima hadiah". Tombol "Terima hadiah" memunculkan popup UiKit "Joran Bambu didapat", dan ia menunjukkan lokasi mancing (panah tanah menuju dermaga, mungkin kamera singgah ke dermaga).
7. **Dermaga** (H): dialog Mas Joko "Tekan Mancing". Prompt Mancing menyala (coachmark). Dialog TERSEMBUNYI saat sesi mancing aktif (L). Setelah ikan didapat, dialog Mas Joko muncul lagi: penjelasan cara dapat ikan, lalu "Selamat! Bawa ikanmu ke Kolam. Belum punya kolam? Buat dulu." Tombol "Mengerti" menutup teks dan coachmark.
8. **Pulang ke lahan** (I, J): panah tanah ke lahan. Di peta jauh (zoom out) tampil GUI melayang besar "Kebun Piko" (hanya pemilik; hilang di dalam zonanya).
9. **Mbok Minah, bikin kolam** (K): ia bicara saat pemain tiba di dekat gerbang. Coachmark glow Kolam lalu tanah hijau. Kolam pertama gratis.
10. **Pindahkan ikan** (K): setelah kolam jadi, Mbok Minah minta pindahkan ikan. GUI melayang "Kelola Ikan" di dekat kolam membuka GUI pindah item. Langkah selesai saat ada ikan di kolam.
11. **Penutup** (M): cut ke Mbok Minah: closing statement, suruh bikin 1-2 petak baru, kenalkan Misi dan Pesanan (coachmark ke tombol Misi dan Pesanan). Tombol "Mengerti" menyelesaikan tutorial, Mbok Minah dihancurkan, chat dibuka.

## 3. Rancangan teknis

### 3.1 Client saja
- **Transition** (modul baru): `Transition.To(fn)` = fade ke hitam 0,4 dtk, jalankan fn (ganti kamera, tutup/buka dialog), dissolve keluar 0,8 dtk. Dipakai di semua pergantian adegan (A).
- **TutorialDirector**: mengganti logika di `T1Ghost` yang kini campur aduk. Skrip percakapan jadi DATA (`TutorialScript.luau`): tiap babak = pembicara, baris, jenis tombol (Next, Mengerti, Terima hadiah, pilihan), kamera (ngobrol / bebas), dan syarat selesai. Satu mesin menjalankannya.
- **Dialog**: `T1Dialog` mendapat jenis tombol baru ("Mengerti", "Terima hadiah") dan aturan sembunyi otomatis saat `FishingUI` aktif (L).
- **Prompt Ngobrol** (C): selama percakapan, `ProximityPromptService.Enabled = false` di client lalu dikembalikan.
- **Pertemuan pertama** (D): `DialogueController` memeriksa flag "sudah kenal NPC ini"; bila belum, memutar skrip perkenalan (sapa dengan `DisplayName`, lalu penjelasan fungsi NPC), baru menampilkan pilihan Jual/Beli dan Sampai jumpa.
- **Kebun <nama> melayang** (J): BillboardGui di plot sendiri, terlihat hanya di client pemilik (otomatis, dibuat lokal), ukuran besar, sembunyi bila root pemain di dalam batas plot. Permanen, bukan khusus tutorial.
- **Panen Semua Lv 3** (B): `refreshHarvestAllButton` ditambah syarat level >= 3. Ini hanya kosmetik karena tombol itu cuma mengirim panen satu per satu yang sudah sah di server. Coachmark sekali saat Lv 3 pertama kali (butuh flag, lihat 3.2).

### 3.2 Butuh perubahan SERVER (bertentangan dengan aturan "client-only", jadi saya minta izin)
1. **Pindah ikan tas <-> kolam** (K): data kolam harus menyimpan ikan. `PondEntry` kini hanya punya `lastCollect`. Perlu `fish: { [itemId]: number }`, event Net baru (`PondDeposit`, `PondWithdraw`), migrasi data, dan validasi server.
2. **Tidak bisa mancing di kolam sendiri** (K): kini `FishService.SetupPond` membuat prompt Mancing di kolam. Harus dicabut di server (kalau hanya disembunyikan di client, itu bisa dilewati exploit).
3. **Kolam berkembang biak**: kini kolam menghasilkan 1 ikan tiap 10 menit (cap 10) lewat prompt "Ambil Ikan 0/10". Aturan baru perlu didefinisikan (lihat pertanyaan 2).
4. **Quest `kolam_pertama`**: langkah keduanya "mancing di kolam" (`catch_pond`) jadi mustahil. Harus diganti, misalnya event baru `pond_stocked`.
5. **Flag "sudah kenal NPC"** (D): `data.met[npcId]`, di `DataTemplate` dan disimpan. Event kecil `NpcMet`.
6. **Hadiah joran nyata** (F, G): lihat pertanyaan 3.
7. **Flag one-shot** tampilan coachmark Panen Semua Lv 3 dan penutup tutorial. Bisa memakai `guide.done` yang sudah ada (tutorial manual baru `t1c_penutup`, `t1d_panen_semua`), tanpa kode server baru selain konfigurasi.

## 4. Keputusan yang saya butuh dari Anda

1. **Server boleh diubah** untuk 3.2 nomor 1 sampai 5? Tanpa ini fitur pindah ikan tidak mungkin.
2. **Aturan kolam baru**: apakah kolam masih menghasilkan ikan sendiri tiap 10 menit (dan "ambil ikan" yang ada tetap), atau diganti penuh jadi: ikan yang dimasukkan berkembang biak (contoh: tiap pasangan ikan sejenis menghasilkan 1 anak tiap N menit sampai kapasitas kolam)? Angka N, kapasitas, dan ukuran ikan anak perlu Anda pilih.
3. **Joran**: pemain baru sudah punya joran bambu sejak awal. Pilihan: (a) tetap punya, "Terima hadiah" hanya presentasi, aman tanpa server; (b) pemain baru TIDAK punya joran, joran diberikan server saat "Terima hadiah" (butuh perubahan server kecil dan migrasi pemain lama).
4. **Penutup "1-2 petak baru"**: petak baru hanya instruksi (pemain menggarap biasa, gratis), atau wajib dua petak sebelum "Mengerti" aktif?
5. **Panen Semua**: sembunyikan di bawah Lv 3 secara client (kosmetik), atau perlu penegakan server juga?
6. **Lokasi Mbok Minah di lahan**: ia kini berdiri di gerbang. Untuk percakapan di lahan, pemain dipandu ke gerbang dulu, atau ia berjalan menghampiri pemain? Saya sarankan dipandu ke gerbang (lebih sederhana, kamera pasti rapi).
7. **Pemain lama** (sudah selesai T1 sebelum ini): tidak diganggu. Setuju?

## 5. Urutan kerja yang saya usulkan

| Fase | Isi | Server? | Risiko |
|---|---|---|---|
| 1 | Transition, prompt Ngobrol, dialog tersembunyi saat mancing, Panen Semua Lv 3, Kebun melayang | tidak | rendah |
| 2 | TutorialScript + Director, ulang alur 3-7 (cutscene langsung setelah jual, Pak Darmo, Mas Joko, hadiah, dermaga) | tidak (kecuali pilihan 3b) | sedang: banyak state yang harus bisa di-resume |
| 3 | Pertemuan pertama semua NPC | ya (flag) | rendah |
| 4 | Server kolam: simpan ikan, deposit/withdraw, cabut mancing kolam, aturan berkembang biak, migrasi, quest | ya | tinggi: data pemain, ekonomi |
| 5 | GUI pindah item (UiKit) + GUI melayang dekat kolam | pakai fase 4 | sedang |
| 6 | Babak 8-11: pulang, kolam, pindah ikan, penutup Misi dan Pesanan | sebagian | sedang |

Cara uji tiap fase: jalankan sendiri di Studio dengan screenshot (seperti sebelumnya), termasuk rejoin di tengah tutorial (resume), pemain lama tidak terganggu, dan layout di viewport 800x360.

Catatan jujur: fase 4 mengubah data pemain dan perlu migrasi, jadi sebaiknya dikerjakan dan diuji terpisah, dan saya sarankan tidak digabung dengan fase lain dalam satu perubahan.
