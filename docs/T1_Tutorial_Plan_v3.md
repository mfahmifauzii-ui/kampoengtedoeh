# T1 Tutorial Plan v3

## Info Dokumen

Status: Final untuk implementasi
Tujuan: Perbaiki tutorial awal dari pertama ketemu Pak Darmo sampai penutup tutorial, tanpa mengganggu pemain lama
Prinsip utama: Progress tutorial disimpan di server, dialog dan cutscene tidak boleh bisa di-skip dengan cara jalan, dan semua yang mengubah inventory atau kolam harus validasi server

## 1. Keputusan Final

Keputusan ini menjawab 6 pertanyaan yang menghambat implementasi. Anggap sudah disetujui, tidak perlu ditanya lagi kecuali ada temuan kode yang bertabrakan.

### 1.1 Server boleh diubah untuk kolam

Jawaban: Ya, wajib.

Alasan: Kolam sekarang hanya menyimpan waktu panen terakhir dan menghasilkan ikan sendiri tiap 10 menit lewat prompt Ambil Ikan. Untuk bisa titip dan ambil ikan, server harus menyimpan daftar ikan per kolam, punya event deposit dan withdraw, dan mencabut prompt Mancing di kolam sendiri. Kalau hanya disembunyikan di client, exploit bisa melewatinya.

### 1.2 Aturan berkembang biak kolam

Jawaban: Ganti penuh, bukan passive 10 menit lagi.

Aturan baru:
- Minimal 2 ikan sejenis di kolam yang sama untuk mulai berkembang biak
- Tiap 15 menit menghasilkan 1 anak sejenis
- Maksimal 10 ekor per jenis per kolam
- Passive lama dihapus supaya ikan titipan tidak kehitung double
- Anak ikan masuk ke inventory kolam, bukan langsung ke tas player

### 1.3 Joran

Jawaban: Pemain baru mulai tanpa joran. Tombol Terima Hadiah adalah grant beneran di server, tapi idempotent.

Detail:
- Kalau player belum punya joran, server memberi Joran Bambu
- Kalau player lama sudah punya joran, tombol hanya memberi feedback dan lanjut, tidak duplikasi
- Tidak ada migrasi massal yang menghapus joran lama

### 1.4 Petak baru di penutup

Jawaban: Cukup instruksi, jangan gate tombol Mengerti.

Alasan: Kalau digate, player bisa softlock kalau tidak punya uang, lahan penuh, atau belum paham cara buat lahan. Jadikan quest terpisah setelah tutorial selesai.

### 1.5 Mbok Minah di lahan

Jawaban: Dipandu ke gerbang.

Player diarahkan dengan arrow tanah dan coachmark ke gerbang lahan. Jangan suruh player menebak harus jalan menghampiri Mbok Minah.

### 1.6 Pemain lama

Jawaban: Tidak diganggu.

Semua akun yang sudah melewati tutorial lama diberi flag T1_completed = true. Mereka tidak mengulang dialog, tidak mengulang cutscene, dan tidak dipaksa ketemu NPC lagi.

## 2. Alur yang Dirasakan Pemain

Ini alur linear dari sudut pandang player. Jangan ada cabang yang bisa membuat player lompat langkah.

### Langkah 1: Pertama ketemu Pak Darmo

Dialog sapaan dulu, bukan langsung toko.
Contoh dialog:
- Loh [Nama Player], kamu sudah pulang? Bagaimana kabarnya?
- Next: Kamu bisa jual dan beli kebutuhan panenmu di sini.

Baru setelah dialog selesai, muncul tombol Jual / Beli dan Sampai Jumpa.
Ini jadi template untuk semua NPC pertama kali: sapaan, perkenalan fungsi NPC, baru aksi.

### Langkah 2: Jual panen pertama, langsung cutscene

Begitu jual pertama sukses, langsung masuk cutscene. Tidak menunggu interaksi berikutnya.
Selama cutscene:
- Input jalan player di-lock
- Kamera di-lock ke POV NPC
- Semua proximity prompt disembunyikan
- Player tidak bisa membuka inventory, toko, atau GUI lain

Tujuan: Memperbaiki scene yang telat di gambar 3, supaya POV NPC tidak berubah karena player keburu jalan.

### Langkah 3: Pak Darmo ke Mas Joko

Setelah jual atau beli pertama, Pak Darmo tidak mengenalkan kolam.
Dia menyuruh player ketemu Mas Joko, NPC yang jualan alat pancing.
Muncul coachmark dan arrow ke lokasi Mas Joko.

### Langkah 4: Mas Joko kasih joran

Dialog kenalan lagi, lalu Mas Joko memberi joran gratis.
Tombolnya: Terima Hadiah, bukan Jual / Beli.
Setelah ditekan:
- Server memberi Joran Bambu kalau belum punya
- Muncul feedback: Kamu mendapatkan Joran Bambu! Sekarang kamu bisa mancing
- Tutorial menunjukkan lokasi mancing di dermaga

### Langkah 5: Di lokasi mancing

Mas Joko lanjut dialog: tekan tombol Mancing untuk mulai.
Saat GUI mancing aktif, semua text percakapan disembunyikan total, bukan hanya dipindah ke belakang. Ini memperbaiki bug GUI mancing ketutupan text percakapan.

Urutan:
- Player tekan tombol Mancing
- Player mulai mancing
- Player dapat ikan pertama
- Mas Joko masuk dengan percakapan tentang cara dapetin ikannya
- Setelah berhasil dapat ikan, dialog update: Selamat kamu berhasil, sekarang bawa ikanmu ke Kolam, kalau kamu belum ada kolam, kamu perlu buat terlebih dahulu
- Tombol Mengerti untuk menutup dialog
- Coachmark dan arrow ke lahan muncul

### Langkah 6: Balik ke lahan

Arrow di tanah sebagai penunjuk arah lahan tetap ada.
Saat zoom out, muncul GUI floating besar di atas lahan bertuliskan Kebun [Nama Player].
Sifat GUI floating:
- Client side, hanya pemilik lahan yang melihat
- Berlaku sepanjang game, bukan cuma tutorial
- Hilang kalau player sudah berada di dalam zona lahannya sendiri, supaya tidak mengganggu pandangan
- Muncul lagi kalau player keluar dari zona lahan

### Langkah 7: Mbok Minah di lahan, buat kolam

Sampai di lahan, Mbok Minah muncul di gerbang dan mengajari pembuatan kolam.
Setelah kolam jadi, dia minta player memindahkan ikan ke dalam kolam lewat GUI pindah item mengikuti UIkit.

Aturan kolam:
- Player tidak bisa mancing di kolam sendiri
- Player bisa ambil ikan dari kolam
- Player bisa taro ikan dari tas ke kolam
- Dekat kolam ada GUI float untuk buka GUI pindah item
- GUI punya dua kolom: Tas dan Kolam
- Tombol: Pindah, Ambil, Pindah Semua, Ambil Semua

### Langkah 8: Penutup tutorial

Closing statement plus cutscene ke Mbok Minah.
Dia menyuruh player membuat 2 lahan garap baru dan mengenalkan sistem quest, misi, atau pesanan.
Tombol terakhir: Mengerti.
Setelah ditekan, tutorial benar-benar selesai dan free play dibuka.

## 3. Spesifikasi Per Sistem

### 3.1 Transisi setelah ngobrol dengan NPC

Masalah: Transisi terlalu kaku.
Solusi: Tambah dark screen dulu, lalu hilang dengan dissolve, baru mulai tutorial atau kontrol berikutnya.

Spesifikasi:
- Buat FadeManager terpusat, jangan buat fade per NPC
- Urutan: dialog tutup, layar hitam fade in 0.3 detik, tahan 0.15 detik, dissolve keluar 0.5 detik
- Selama fade, input player di-lock
- Fade dipakai untuk: habis ngobrol, masuk cutscene, keluar cutscene, dan pindah fase tutorial
- Jangan pakai fade untuk interaksi biasa di luar tutorial

### 3.2 Proximity prompt saat ngobrol

Masalah: Prompt masih muncul saat dialog jalan.
Solusi: Saat mode ngobrol aktif, semua proximity prompt disembunyikan.

Spesifikasi:
- Buat DialogueService yang punya state IsTalking
- Saat IsTalking = true, sembunyikan prompt toko, prompt mancing, prompt kolam, dan prompt NPC lain
- Saat dialog tutup, kembalikan prompt yang memang seharusnya muncul di lokasi itu
- Prompt kolam tidak boleh muncul bersamaan dengan dialog Mbok Minah

### 3.3 Tombol Panen Semua

Aturan: Hanya muncul kalau level 3 ke atas.
Kondisi sekarang: Tidak ada syarat level di kode, makanya muncul di Lv 1.

Spesifikasi:
- Gate di client saja, karena tombol hanya mengirim panen satu per satu yang sudah sah di server
- Di level 1 dan 2, tombol tidak dirender sama sekali, bukan hanya di-disable
- Saat pertama kali mencapai level 3, tampilkan coachmark sekali saja
- Coachmark: Panen Semua membuka panen sekaligus, tidak perlu panen satu per satu
- Simpan flag coachmark sudah ditampilkan, supaya tidak spam tiap buka lahan

### 3.4 First Meet NPC

Sistem baru: FirstMeetDialogue.
Setiap NPC punya flag hasMet per player.

Jika hasMet = false:
- Dialog sapaan wajib jalan dulu
- Dialog perkenalan fungsi NPC wajib jalan
- Tombol aksi baru muncul setelah dialog selesai
- Setelah dialog selesai, set hasMet = true di server

Jika hasMet = true:
- Langsung ke menu aksi normal, tanpa dialog sapaan

Template dialog per NPC:
- Pak Darmo: Sapaan pulang, perkenalan jual dan beli kebutuhan panen
- Mas Joko: Kenalan, perkenalan alat pancing, kasih joran gratis
- Mbok Minah: Kenalan, perkenalan lahan dan kolam

Gunakan placeholder [Nama Player] yang diisi dari nama player, bukan nama statis.

### 3.5 Cutscene setelah jual pertama

Trigger: Event OnFirstSellSuccess, bukan OnNextInteract.
Alasan: Kalau trigger di interaksi berikutnya, player keburu jalan dan POV berubah.

Spesifikasi:
- Begitu server konfirmasi jual pertama sukses, client langsung lock input dan kamera
- Cutscene jalan tanpa menunggu player menekan tombol lagi
- Setelah cutscene selesai, jalankan FadeManager, lalu lanjut ke dialog Pak Darmo yang menyuruh ke Mas Joko
- Jika player disconnect di tengah cutscene, saat login lagi, tutorial lanjut dari checkpoint setelah jual pertama, bukan mengulang jual

### 3.6 Mancing dan layering GUI

Masalah: GUI mancing ketutupan text percakapan.
Solusi: Saat fishing aktif, container dialog di-hide total.

Spesifikasi:
- Buat state FishingActive di client
- Saat FishingActive = true, sembunyikan container dialog, coachmark dialog, dan bubble NPC
- Saat fishing selesai atau dibatalkan, kembalikan dialog yang memang masih aktif
- ZIndex GUI mancing harus di atas semua GUI tutorial, tapi di bawah GUI sistem seperti pause
- Tombol Mancing hanya aktif di lokasi mancing yang valid, bukan di kolam sendiri

### 3.7 GUI Floating Kebun [Nama Player]

Ini fitur permanen, bukan hanya tutorial.

Spesifikasi:
- Tipe: BillboardGui di atas lahan milik player
- Text: Kebun [Nama Player]
- Ukuran: Lumayan besar, terbaca saat zoom out
- Sifat: Client side, hanya pemilik lahan yang melihat
- Dibuat dari data lahan milik sendiri, bukan dari data lahan orang lain
- Logika tampil: Tampil kalau player di luar zona lahan sendiri, sembunyi kalau player sudah di dalam zona lahan sendiri
- Jarak render: Batasi jarak supaya tidak berat, misalnya hilang total di jarak sangat jauh
- Tidak boleh menumpuk dengan GUI floating kolam atau GUI floating NPC
- Berlaku sepanjang game, tidak dimatikan setelah tutorial selesai

### 3.8 Kolam dan GUI Pindah Ikan

GUI pindah ikan mengikuti UIkit yang sudah ada. Jangan buat gaya baru.

Layout GUI:
- Judul: Kolam
- Kolom kiri: Tas, list ikan di tas player
- Kolom kanan: Kolam, list ikan di kolam
- Setiap item: ikon ikan, nama, jumlah
- Tombol per item: Pindah ke kolam, Ambil ke tas
- Tombol bulk: Pindah Semua, Ambil Semua
- Tombol tutup: Tutup atau X

Aturan interaksi:
- Dekat kolam, muncul GUI float untuk buka GUI pindah item
- GUI float ini berbeda dengan prompt Mancing
- Di kolam sendiri, prompt Mancing tidak muncul
- Di kolam orang lain atau kolam publik, aturan mancing tetap mengikuti aturan lama, kecuali sudah ditentukan lain

Aturan server untuk transfer:
- Event DepositFish: validasi ikan ada di tas, jumlah cukup, kolam milik player, kapasitas kolam tidak melebihi batas
- Event WithdrawFish: validasi ikan ada di kolam, jumlah cukup, tas masih ada slot
- Event Bulk: sama, tapi proses per item dan kembalikan hasil parsial kalau sebagian gagal
- Semua perubahan inventory dan kolam harus lewat server, client hanya menampilkan
- Jika transfer gagal, tampilkan feedback jelas, jangan diam

Kapasitas dan breeding:
- Kapasitas kolam: Tentukan satu angka di kode, contoh maksimal 20 ikan per kolam, bisa diubah di config
- Breeding: 2 ikan sejenis, tiap 15 menit hasilkan 1 anak, maksimal 10 per jenis
- Anak ikan masuk ke inventory kolam
- Jika kolam penuh, breeding berhenti sampai ada slot

## 4. Pembagian Client dan Server

### Client saja

- Fade dan dissolve transisi
- Hide proximity prompt saat dialog
- Gate tombol Panen Semua level 3
- Coachmark Panen Semua, coachmark ke Mas Joko, coachmark ke dermaga, coachmark ke lahan
- GUI floating Kebun [Nama Player]
- Arrow tanah penunjuk lahan
- Layering GUI mancing di atas dialog
- GUI float buka kolam

### Server wajib

- Flag hasMet per NPC per player
- Flag T1_completed
- Checkpoint progress tutorial
- Grant Joran Bambu yang idempotent
- Simpan daftar ikan per kolam
- Event DepositFish dan WithdrawFish
- Validasi kapasitas kolam
- Logika breeding kolam
- Mencabut prompt Mancing di kolam sendiri secara otoritatif, bukan hanya hide di client
- Quest kolam_pertama yang sudah diperbaiki

### Data yang disimpan

- TutorialState: currentStep, hasMetDarmo, hasMetJoko, hasMetMbokMinah, hasFirstSell, hasReceivedRod, hasFirstFish, hasPond, hasDepositedFish, T1_completed
- Kolam: pondId, ownerId, fishList, lastBreedTick
- FishList: speciesId, count
- Inventory: rod ownership, fish count per species

## 5. Perubahan Quest

### Quest kolam_pertama

Langkah lama yang salah:
- Langkah 2: Mancing di kolam

Langkah baru:
- Langkah 1: Buat kolam pertama
- Langkah 2: Simpan ikan ke kolam
- Langkah 3: Ambil ikan dari kolam, opsional untuk mengajarkan withdraw

### Quest setelah tutorial

- Quest baru: Buat 2 lahan garap baru, tidak mengunci tombol Mengerti
- Quest baru: Kenalan dengan sistem misi atau pesanan, dibuka setelah penutup tutorial
- Tutorial selesai tidak boleh mengunci quest lama yang sudah berjalan

## 6. Fase Pengerjaan

Urutan ini dibuat supaya Fase 1 dan 2 bisa jalan duluan tanpa menunggu server kolam.

### Fase 1: Transisi, prompt, Panen Semua

- Buat FadeManager
- Sembunyikan proximity prompt saat dialog
- Gate Panen Semua level 3 plus coachmark sekali
- Testing: Dialog buka tutup, fade tidak stuck, prompt kembali normal

### Fase 2: First Meet dan cutscene jual pertama

- Buat FirstMeetDialogue dan flag hasMet
- Dialog Pak Darmo: sapaan, perkenalan, baru tombol Jual / Beli
- Cutscene langsung setelah OnFirstSellSuccess, dengan lock input dan kamera
- Dialog Pak Darmo yang menyuruh ke Mas Joko
- Testing: Jual pertama langsung cutscene, player tidak bisa jalan di tengah cutscene

### Fase 3: Mas Joko sampai dermaga

- Dialog Mas Joko kenalan dan kasih joran
- Tombol Terima Hadiah dengan grant idempotent
- Feedback dapat Joran Bambu
- Coachmark dan arrow ke lokasi mancing
- Dialog di lokasi mancing: tekan tombol Mancing
- Hide dialog saat fishing aktif
- Dialog setelah dapat ikan, dan dialog selamat plus instruksi bawa ke kolam
- Tombol Mengerti plus coachmark ke lahan
- Testing: Player tanpa joran dapat joran, player lama tidak duplikasi

### Fase 4: Kebun floating dan balik ke lahan

- Arrow tanah tetap jalan
- GUI floating Kebun [Nama Player] client side, permanen, hilang di zona sendiri
- Mbok Minah di gerbang lahan
- Dialog Mbok Minah mengajari pembuatan kolam
- Testing: Zoom out, GUI terlihat, masuk zona lahan, GUI hilang, keluar zona, GUI muncul lagi

### Fase 5: Kolam server dan GUI transfer

- Server simpan ikan per kolam
- Event DepositFish dan WithdrawFish plus bulk
- Cabut mancing di kolam sendiri di server
- GUI pindah item mengikuti UIkit, dengan Pindah, Ambil, Pindah Semua, Ambil Semua
- GUI float buka GUI kolam di dekat kolam
- Ubah quest kolam_pertama
- Implementasi breeding 15 menit
- Testing: Deposit, withdraw, bulk, kapasitas penuh, breeding, anti exploit dengan client yang dimodifikasi

### Fase 6: Penutup dan quest system

- Closing statement dan cutscene ke Mbok Minah
- Instruksi buat 2 lahan garap baru
- Perkenalan quest, misi, atau pesanan
- Tombol Mengerti sebagai penanda T1_completed
- Matikan semua coachmark tutorial, tapi biarkan GUI floating Kebun jalan
- Testing: Tutorial selesai, free play normal, pemain lama tidak terganggu

## 7. Edge Case

- Player tutup game di tengah dialog: Lanjut dari checkpoint terakhir, bukan dari awal
- Player sudah punya kolam sebelum langkah kolam: Lompat ke langkah pindahkan ikan
- Player sudah punya ikan tapi kolam penuh: Pindah Semua hanya memindahkan yang muat, sisanya tetap di tas dengan feedback
- Player membatalkan mancing: Dialog Mas Joko kembali ke state sebelum mancing, tidak lompat ke selamat
- Player menjual ikan yang seharusnya disimpan ke kolam: Tutorial tidak gagal, player bisa mancing lagi untuk dapat ikan baru
- Player mencoba buka kolam orang lain: Tampilkan feedback tidak bisa, jangan buka GUI
- Player mencoba mancing di kolam sendiri lewat exploit: Server menolak, client menampilkan feedback
- Player mencapai level 3 di tengah tutorial: Coachmark Panen Semua muncul setelah tutorial selesai, bukan menumpuk dialog tutorial

## 8. Checklist Acceptance

- [ ] Setelah ngobrol, ada dark screen lalu dissolve, tidak langsung potong kaku
- [ ] Saat ngobrol, tidak ada proximity prompt yang muncul
- [ ] Tombol Panen Semua tidak muncul di Lv 1 dan Lv 2, muncul di Lv 3 dengan coachmark sekali
- [ ] Pertama ketemu Pak Darmo, Mas Joko, dan Mbok Minah selalu ada dialog sapaan dan perkenalan dulu
- [ ] Setelah jual pertama, cutscene langsung jalan, player tidak bisa jalan
- [ ] Pak Darmo menyuruh ke Mas Joko, bukan mengenalkan kolam
- [ ] Mas Joko memberi joran lewat tombol Terima Hadiah, ada feedback dapat Joran Bambu
- [ ] Di lokasi mancing, dialog menyuruh tekan Mancing, dan dialog hilang saat GUI mancing aktif
- [ ] Setelah dapat ikan, ada dialog cara dapetin ikan, lalu dialog selamat dan instruksi bawa ke kolam, dengan tombol Mengerti
- [ ] Arrow tanah ke lahan tetap ada, GUI floating Kebun [Nama Player] muncul saat zoom out, hanya pemilik yang lihat, hilang di zona sendiri, berlaku sepanjang game
- [ ] Mbok Minah di gerbang lahan mengajari buat kolam
- [ ] Setelah kolam jadi, player bisa pindah ikan tas ke kolam dan sebaliknya, dengan Pindah Semua dan Ambil Semua
- [ ] Player tidak bisa mancing di kolam sendiri di server, tapi bisa ambil ikan
- [ ] Dekat kolam ada GUI float untuk buka GUI pindah item
- [ ] Penutup ada cutscene ke Mbok Minah, instruksi buat 2 lahan baru, perkenalan quest atau pesanan, tombol Mengerti menyelesaikan tutorial
- [ ] Pemain lama dengan T1_completed tidak mengulang tutorial

## 9. Yang Tidak Dikerjakan di Plan Ini

- Redesign UIkit secara keseluruhan
- Perubahan harga jual atau beli
- Perubahan balance ikan di luar breeding kolam
- Perubahan sistem lahan di luar tambahan 2 lahan di penutup
- Fitur multiplayer untuk kolam, kolam tetap milik pribadi

## 10. Catatan untuk Claude Code

- Jangan tulis kode sebelum user menyetujui plan ini
- Jika menemukan kode yang bertabrakan dengan plan, berhenti dan laporkan, jangan diam-diam mengubah aturan
- Prioritaskan Fase 1 dan 2 dulu, Fase 5 server kolam dikerjakan terpisah karena mengubah data player
- Semua teks dialog harus pakai placeholder [Nama Player], jangan hardcode nama
- Semua flag tutorial harus di server, jangan hanya di LocalScript
