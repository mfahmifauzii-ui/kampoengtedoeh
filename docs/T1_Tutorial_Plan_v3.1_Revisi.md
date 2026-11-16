# T1 Tutorial Plan v3.1 - Addendum Revisi

## Status

Dokumen ini adalah addendum untuk docs/T1_Tutorial_Plan_v3.md.
Plan v3 tetap berlaku, tapi ada 6 tabrakan yang ditemukan Claude saat membaca kode. Addendum ini menyelesaikan tabrakan tersebut tanpa membatalkan Plan v3.

Keputusan utama: Fase 1 jalan sekarang. Fase 2 sampai 5 ditahan sampai revisi di bawah ini disetujui.

## 1. Keputusan: Fase 1 atau Revisi Dulu?

Jawaban: Keduanya, secara paralel.

- Fase 1 boleh dimulai sekarang, karena tidak bertabrakan dengan kode yang sudah dibaca
- Fase 2 sampai 5 tidak boleh dimulai sampai addendum ini disetujui
- Alasan: Fase 1 adalah sistem pendukung yang netral. Fase 2 sampai 5 mengubah alur, inventory, kolam, dan quest yang sudah ada

Yang Boleh Dikerjakan di Fase 1:

- FadeManager: dark screen lalu dissolve setelah ngobrol
- Sembunyikan proximity prompt saat mode dialog
- Gate tombol Panen Semua hanya Lv 3 ke atas, plus coachmark sekali

Syarat Fase 1:

- Tidak mengubah alur Onboarding.luau
- Tidak mengubah t1b_kolam
- Tidak mengubah FishService.luau
- Tidak mengubah quest kolam_pertama
- Tidak mengubah starter inventory joran
- Harus bisa di-rollback dengan menghapus satu modul saja

Yang Ditahan:

- First Meet dialog Pak Darmo, Mas Joko, Mbok Minah
- Cutscene langsung setelah jual pertama
- Grant joran dari Mas Joko
- GUI floating Kebun [Nama Player]
- GUI transfer ikan tas ke kolam
- Breeding kolam dan hapus passive 10 menit
- Perubahan quest kolam_pertama
- Closing cutscene ke Mbok Minah

## 2. Tabrakan 1: Alur T1 Sudah Berbeda

Fakta kode:

- Welcome modal lalu cangkul, tanam, siram, panen_jual di Config/Onboarding.luau
- Tutorial kedua t1b_kolam: warung, kolam, Mas Joko, mancing, bangun kolam
- Plan v3 mendeskripsikan alur linear yang berbeda: sapaan Pak Darmo, Mas Joko memberi joran, lalu Mbok Minah di lahan

Resolusi: Plan v3 bukan pengganti alur lama. Plan v3 adalah lapisan polish dan dialog di atas alur lama.

Pemetaan yang benar:

| Alur lama | Posisi di Plan v3 | Perlakuan |
|---|---|---|
| Welcome modal | Tetap di awal | Jangan diubah, hanya tambah FadeManager setelah modal tutup |
| Cangkul, tanam, siram | T1a, sebelum ketemu Pak Darmo | Tetap, tidak ada dialog Pak Darmo di sini |
| Panen, jual | Titik masuk Plan v3 | Di sinilah sapaan Pak Darmo pertama kali muncul |
| Warung di t1b_kolam | Sama dengan toko Pak Darmo | Pak Darmo adalah pemilik warung, jangan buat NPC warung kedua |
| Mas Joko, mancing | Tetap di t1b_kolam | Tambah dialog kenalan dan Terima Hadiah di sini, bukan alur baru |
| Bangun kolam | Tetap di t1b_kolam | Tambah dialog Mbok Minah di lahan di sini, bukan setelah alur lain |
| Penutup tutorial | Setelah t1b_kolam selesai | Closing ke Mbok Minah, instruksi 2 lahan baru, perkenalan quest |

Artinya: jangan buat tutorial linear baru dari nol. Sisipkan dialog, cutscene, dan transisi ke dalam checkpoint yang sudah ada.

Aturan tambahan:

- Jika ada langkah di Plan v3 yang tidak punya padanan di Onboarding.luau atau t1b_kolam, tandai sebagai NEW dan minta persetujuan, jangan langsung buat quest baru
- Nama checkpoint harus pakai nama yang sudah ada di kode, jangan buat nama baru yang duplikatif

## 3. Tabrakan 2: Joran Awal

Fakta kode: komentar di t1b_kolam bilang joran bambu sudah gratis dan dimiliki dari awal. Plan v3 bilang pemain baru mulai tanpa joran.

Resolusi awal (SUPERSEDED 16 Nov, lihat bagian 3A): Opsi A, karena paling aman dan tidak butuh migrasi.

Opsi A: joran tetap dari awal, Terima Hadiah jadi unlock plus hadiah pendukung.

- Pemain baru tetap mulai dengan Joran Bambu, sesuai kode sekarang
- Tombol Terima Hadiah dari Mas Joko tidak memberi joran duplikat
- Tombol Terima Hadiah melakukan 3 hal:
  - Set flag hasMetJoko = true
  - Set flag fishingTutorialUnlocked = true
  - Beri hadiah pendukung, contoh: 5 umpan, atau skin joran, atau 1 slot tas pancing, pilih satu saja di implementasi
- Feedback tetap: "Kamu mendapatkan hadiah dari Mas Joko! Sekarang kamu bisa mancing"
- Jangan ubah teks feedback menjadi "Kamu mendapatkan Joran Bambu", karena itu bohong kalau player sudah punya

Opsi B yang ditolak untuk sekarang: hapus joran dari starter inventory dan beri lewat Mas Joko. Ditolak karena butuh migrasi pemain lama, mengubah tutorial awal, dan berisiko softlock kalau player tidak ketemu Mas Joko. Jika di masa depan mau Opsi B, buat migrasi terpisah, bukan di dalam Fase 3.

## 3A. Revisi 16 Nov: Joran Diberi Mas Joko (Opsi B, menggantikan Opsi A)

Keputusan pemilik: pemain baru TIDAK punya joran dan umpan dari awal. Keduanya diberikan Mas Joko lewat Terima Hadiah. Opsi A di bagian 3 di atas SUPERSEDED dan tidak dipakai lagi.

Yang berubah:
- Starter pemain baru: tanpa joran (ownedRods kosong, rod kosong). Starter inventory joran DIHAPUS untuk akun baru
- Terima Hadiah Mas Joko memberi Joran Bambu dan umpan, idempotent: kalau sudah punya joran, tidak diduplikasi, tombol tetap memberi feedback dan lanjut
- Set flag hasMetJoko = true dan fishingTutorialUnlocked = true, sama seperti sebelumnya
- Feedback: "Kamu mendapatkan Joran Bambu dan umpan dari Mas Joko! Sekarang kamu bisa mancing"
- Server WAJIB menolak mancing tanpa joran yang dimiliki. Fallback `or Fishing.rods.bambu` di FishService.luau:207 dihapus untuk kasus ini
- Toko tidak menjual joran bambu (price 0 diblokir ShopService.luau:161). Satu-satunya sumber joran bambu baru adalah Terima Hadiah Mas Joko

Keputusan pemilik (16 Nov):
- Umpan: pelet (umpan paling basic, Config/Fishing BAIT), jumlah 5
- Tidak boleh ada fitur Lewati Tutorial sama sekali. Tutorial di map ini penting. Tombol Lewati di hint bar, di Panduan, dan di welcome modal dihapus. Server menolak aksi "skip"
- STATUS: FINAL (keputusan user, lanjut Fase 3). Tidak ada fitur Lewati di tutorial.
  - Welcome modal hanya punya Mulai (tidak ada Batal atau Lewati, tap di luar tidak menutup)
  - Tombol Lewati di hint bar dan coachmark dihapus, cabang aksi skip di TutorialService dihapus
  - Data lama dengan guide.skipped tetap dibaca, tidak ditulis lagi
- Konsekuensi: risiko softlock dari Lewati hilang. Tidak perlu aturan "Lewati memberi joran"

### Rencana migrasi

Akun lama (sudah punya data):
- Tidak ada yang dicabut. Akun dengan ownedRods.bambu = true tetap memegang joran. Tidak ada migrasi yang menghapus
- ProfileStore hanya mengisi kunci yang hilang dari template. Kunci ownedRods yang sudah ada tidak ditimpa, jadi akun lama aman. Ini harus diverifikasi di Studio dengan profil lama
- Akun yang sudah T1_completed tidak diulang tutorialnya (lihat bagian 1.6 Plan v3)

Akun baru setelah update:
- Mulai tanpa joran. Mancing ditolak server sampai Terima Hadiah Mas Joko dilakukan

Risiko softlock (wajib ditutup sebelum rilis):
- Pemain yang melewati tutorial (Lewati) belum pernah bertemu Mas Joko dan tidak punya joran. Mitigasi yang diusulkan: Terima Hadiah Mas Joko tetap bisa dilakukan dari menu Mas Joko kapan saja, bukan hanya di tutorial. Keputusan tambahan yang perlu dijawab: apakah Lewati juga memberi joran?
- Mancing tanpa joran harus menampilkan petunjuk "Temui Mas Joko dulu", bukan diam saja

Urutan implementasi (setelah disetujui):
1. DataTemplate: ownedRods = {}, rod = "" untuk akun baru
2. FishService: tolak mancing tanpa joran yang dimiliki, hapus fallback bambu
3. TutorialService: Terima Hadiah idempotent (joran + umpan + flag)
4. ShopService: tidak ada perubahan (joran bambu tetap tidak dijual)
5. Uji Studio: profil baru (tanpa joran), profil lama (punya joran), profil Lewati, dan profil yang sudah T1_completed

Rollback: kembalikan DataTemplate dan fallback FishService. Tidak ada data yang perlu dipulihkan karena tidak ada yang dicabut.

## 4. Tabrakan 3: Sistem Kolam

Fakta kode: kolam punya timer panen pasif dan prompt CollectPrompt / FishPrompt di FishService.luau. Plan v3 minta breeding baru, ikan titipan per kolam, dan mencabut prompt Ambil Ikan. Plan v3 sendiri bilang Fase 5 dikerjakan terpisah.

Resolusi: Fase 5 tetap terpisah, dan tidak boleh dicampur ke Fase 1 sampai 4.

Aturan transisi kolam:

- Kolam lama yang sudah ada tetap pakai sistem passive sampai migrasi diputuskan
- Kolam baru yang dibuat setelah update memakai sistem baru: storage ikan plus breeding
- Jangan hapus CollectPrompt untuk kolam lama sebelum migrasi
- Jangan hapus FishPrompt di kolam sendiri untuk kolam lama sebelum migrasi

Aturan breeding final, setelah migrasi:

- Minimal 2 ikan sejenis di kolam yang sama
- Tiap 15 menit menghasilkan 1 anak sejenis
- Maksimal 10 ekor per jenis per kolam
- Passive 10 menit dihapus hanya untuk kolam baru, bukan dihapus global sekaligus

Yang harus dilakukan sebelum Fase 5:

- Buat desain migrasi kolam lama ke kolam baru
- Tentukan apa yang terjadi dengan ikan passive yang belum diambil di kolam lama
- Tentukan apa yang terjadi dengan timer panen yang sedang berjalan
- Minta persetujuan migrasi sebelum menulis kode FishService.luau

## 5. Tabrakan 4: Quest kolam_pertama

Fakta kode: quest kolam_pertama sudah ada dengan langkah catch_pond, dan Plan v3 ingin mengubahnya.

Resolusi: jangan ubah quest yang sudah berjalan untuk pemain lama.

- Pemain yang sudah memulai kolam_pertama dengan versi lama tetap menyelesaikan dengan langkah lama catch_pond
- Pemain baru yang memulai setelah update memakai versi baru:
  - Langkah 1: Buat kolam pertama
  - Langkah 2: Simpan ikan ke kolam
  - Langkah 3: Ambil ikan dari kolam, opsional
- Buat versi quest baru dengan versi, contoh: kolam_pertama_v2, jangan timpa kolam_pertama_v1
- Jika sistem quest tidak mendukung versioning, buat quest baru dengan ID baru dan nonaktifkan quest lama hanya untuk pemain baru
- Jangan rename catch_pond secara langsung, karena bisa merusak progress pemain lama

## 6. Tabrakan 5: Working Tree Kotor

Fakta: ada sekitar 50 file yang sudah berubah dan belum di-commit di branch feat/farm-fishing-audio-vfx.

Resolusi:

- Jangan edit di atas working tree kotor
- Langkah wajib sebelum Fase 1: jalankan git status dan catat file yang berubah; pilih commit pekerjaan audio VFX ke branch yang sama, atau stash pekerjaan yang belum selesai, lalu buat branch baru dari branch yang bersih: feat/t1-tutorial-v3
- Semua pekerjaan Fase 1 hanya di branch baru ini
- Jangan merge branch tutorial ke branch audio VFX sampai keduanya stabil
- Jika ada file yang sama diubah di kedua branch, selesaikan konflik secara manual, jangan overwrite

## 7. Tabrakan 6: Verifikasi Terbatas

Fakta: Claude belum mengecek apakah rojo, lune, selene, atau stylua terpasang, dan perubahan Roblox tetap perlu diuji di Studio.

Resolusi: Fase 1 tidak dianggap selesai sebelum verifikasi ini jalan.

Checklist verifikasi Fase 1:

- Cek apakah rojo terpasang, dan versi berapa
- Cek apakah lune terpasang, untuk test logika jika ada
- Cek apakah selene terpasang, untuk lint Luau
- Cek apakah stylua terpasang, untuk format
- Jika salah satu tidak terpasang, catat di laporan, jangan pura-pura sudah dicek
- Setelah kode selesai, uji di Studio: fade tidak stuck, prompt hilang saat dialog lalu muncul lagi, Panen Semua hilang di Lv 1 dan Lv 2 dan muncul di Lv 3, tidak ada error di output Studio
- Jika verifikasi tidak bisa jalan di environment Claude, tulis di laporan: belum terverifikasi di Studio, perlu uji manual

## 8. Instruksi untuk Claude Code

- Mulai Fase 1 sekarang di branch baru feat/t1-tutorial-v3, setelah working tree dibersihkan
- Jangan mulai Fase 2 sampai 5 sampai addendum ini disetujui dan Plan v3 direvisi
- Jika menemukan tabrakan baru di Fase 1, berhenti dan lapor, jangan lanjut dengan asumsi
- Jangan mengubah Onboarding.luau, t1b_kolam, FishService.luau, atau quest kolam_pertama di Fase 1
- Semua kode Fase 1 harus modular, supaya bisa di-rollback tanpa merusak tutorial lama
- Setelah Fase 1 selesai, buat laporan: file yang diubah, hasil lint, hasil uji Studio, dan apa yang belum terverifikasi

## 9. Checklist Persetujuan Addendum

- [x] Setuju Fase 1 jalan sekarang, Fase 2 sampai 5 ditahan
- [x] Setuju pemetaan alur lama ke Plan v3 di bagian 2
- [x] ~~Setuju Opsi A untuk joran~~ SUPERSEDED 16 Nov: Opsi B, joran dan umpan dari Mas Joko (bagian 3A)
- [x] Setuju kolam lama tetap passive sampai migrasi, kolam baru pakai breeding
- [x] Setuju quest kolam_pertama tidak ditimpa, buat versi baru untuk pemain baru
- [x] Setuju branch baru setelah working tree dibersihkan
- [x] Setuju Fase 1 belum selesai tanpa checklist verifikasi Studio

Catatan: butir "Gate tombol Panen Semua hanya Lv 3" di bagian 1 sudah dibatalkan, lihat [T1_Tutorial_Plan_v3.md](T1_Tutorial_Plan_v3.md) bagian 3.3 (Panen Semua terkunci Gamepass, disembunyikan sementara).
