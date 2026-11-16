# Catatan Fase 1 (branch feat/t1-tutorial-v3)

Status: WIP. Lint sudah jalan untuk file Fase 1. Belum diuji di Studio. Jangan push atau merge sebelum uji Studio selesai.

## Keputusan

- **Walk-away sengaja tidak fade, bukan bug.** Walk-away adalah batal mendadak (pemain jalan menjauh), bukan penutup normal. Fade hanya untuk penutup yang dipilih pemain: "Sampai jumpa" dan "Jual / Beli" (layar gelap saat toko terbuka). Satu-satunya tempat yang mengatur ini adalah cabang walk-away di `DialogueController.Start`. Kalau spek nanti minta walk-away juga fade, ubah cabang itu saja.
- **Panen Semua: terkunci Gamepass dan disembunyikan sementara (16 Nov).** Aturan Lv 3 dibatalkan. Tombol tidak pernah tampil, fungsi panen dimatikan dengan `PANEN_SEMUA_ENABLED = false`, coachmark dimatikan. Lihat [Plan v3 bagian 3.3](T1_Tutorial_Plan_v3.md).

## Perubahan setelah review

- **TD-2 (PromptGate), diperbaiki sebagian.** Sekarang kepemilikan prompt dihitung: begitu prompt diubah pihak lain saat dialog (dinyalakan atau dimatikan), `PromptGate` membiarkan prompt itu sesuai keadaan terakhir pihak lain. `PromptGate` hanya menyalakan lagi prompt yang masih belum diubah siapa pun sejak dimatikan.
  - Sisa risiko: `PromptGate` tidak tahu MAKSUD pihak lain. Kalau pihak lain mematikan prompt sementara dan lupa menyalakannya, prompt itu tetap mati. Itu bukan wewenang `PromptGate`, jadi pemilik prompt wajib mengatur sendiri.
  - Reproduksi untuk uji Studio: dekat NPC, buka dialog (semua prompt mati), dari sistem lain (misal lewat Output command) ubah `Enabled` satu prompt, tutup dialog, cek prompt itu tetap sesuai perubahan terakhir, bukan dikembalikan.
  - Belum diuji di Studio.
- **Lint dan format** (lihat bagian Verifikasi).

## Tech debt

| ID | Isi | Dampak | Tiket |
|---|---|---|---|
| TD-1 | **Tidak berlaku sampai Gamepass aktif** (coachmark Panen Semua dimatikan, tombolnya disembunyikan). Saat diaktifkan nanti: flag coachmark hanya di memori, sekali per sesi, setelah login ulang bisa muncul lagi. Jangan diklaim "sekali selamanya". | Rendah | Tambah field `hasSeenPanenSemuaCoachmark` di profil server |
| TD-2 | Lihat bagian "Perubahan setelah review". Sisa: pemilik prompt harus mengatur sendiri kalau mematikan prompt sementara. | Sedang | FISH-PROMPT-OWNER |
| BUG-GARAP-415 | Error `attempt to call a nil value` di `GarapController` baris 415 (dipanggil dari `setBedHover`, baris 389). Penyebab: `refreshHint()` dipanggil di baris 415, tapi `local refreshHint` (forward declaration) baru ada di baris 420, jadi di baris 415 nama itu masih nil. Sudah ada di HEAD sebelum Fase 1. Perbaikan: pindahkan forward declaration ke atas `setBedHover`. Di luar batas Fase 1, tidak diperbaiki di branch ini. | Sedang (muncul saat pointer keluar dari petak di mode garap) | Tiket terpisah: GARAP-HINT-FORWARD-DECL |

## Verifikasi

- `rojo build default.project.json` lolos (output ke scratchpad).
- **selene 0.32.0** (pinned di `aftman.toml`), dengan std roblox:
  - `FadeManager.luau`, `PromptGate.luau`: 0 error, 0 warning.
  - `DialogueController.luau`, `FarmController.luau`: jumlah warning sama dengan HEAD (9 gabungan untuk dua file). Tidak ada warning baru dari Fase 1.
- **StyLua 2.6.0** (pinned di `aftman.toml`):
  - `FadeManager.luau`, `PromptGate.luau`: sudah diformat dan lolos `--check`.
  - `DialogueController.luau`, `FarmController.luau`: gagal `--check`, tapi versi HEAD juga gagal. Pelanggaran ini sudah ada sebelum Fase 1, jadi file itu tidak diformat ulang.
- **Tidak terverifikasi:** `lune` dan `luau` (type check) belum terpasang. Jangan klaim type check sudah lolos.
- **Studio:** belum diuji. Daftar uji ada di `Fase1-Review-TestPlan`.

## Limitasi yang diketahui (sebelum merge)

- **Kunci kontrol saat fade belum terverifikasi.** Di sesi uji tool, `PlayerModule` tidak ada di `PlayerScripts`, jadi `FadeManager` tidak bisa mengunci kontrol. Guard sudah mencegah fade macet dan memastikan kontrol dilepas kembali. Yang belum terbukti: pemain benar-benar tidak bisa bergerak selama fade. Ini harus dicek di playtest manual sungguhan.
- **Branch berisi lebih dari Fase 1.** `feat/t1-tutorial-v3` memuat commit `1367304` (WIP audio, VFX, dialog T1, dan perubahan tutorial lain, 57 file). Fase 1 bergantung pada kode itu (T1Dialog, DialogueController), jadi belum bisa dipisah tanpa keputusan.
- **Tiket terpisah, tidak diperbaiki di Fase 1:** MENUFLOW-LOADING, GARAP-HINT-FORWARD-DECL (GarapController:415), dan dua folder `Remotes` di ReplicatedStorage.

## Asal kode di branch bersih (feat/t1-tutorial-v3-clean)

- **Drag siram di `FarmController` ikut terbawa dari WIP, bukan fitur baru Fase 1.** Panen Semua dan drag siram ada dalam satu hunk yang sama, jadi belum dipisah. Base `43ce5c7` tidak punya kode drag siram (`dragWater` = 0 baris); branch bersih punya 9 baris. Fitur ini ikut dibiarkan di Fase 1.
- **Audio dan VFX yang sudah ada di base `43ce5c7` dibiarkan.** Tidak ada audio atau VFX baru dari WIP yang ikut masuk.

