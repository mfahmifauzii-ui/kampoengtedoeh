# Catatan Fase 1 (branch feat/t1-tutorial-v3)

Status: WIP. Belum diuji di Studio. Tidak boleh merge ke branch utama sebelum checklist Studio di `Fase1-Review-TestPlan` lolos.

## Keputusan

- **Walk-away tidak memanggil fade.** Walk-away adalah batal mendadak (pemain jalan menjauh), bukan penutup normal. Fade hanya untuk penutup yang dipilih pemain: "Sampai jumpa" dan "Jual / Beli" (layar gelap saat toko terbuka). Kalau nanti spek ingin walk-away juga fade, ubah satu baris di `DialogueController` (`DialogueController.Start`, cabang walk-away).
- **Panen Semua: tombol di bawah Lv 3 tidak tampil (`Visible = false`).** Spek sudah direvisi di Plan v3 bagian 3.3.

## Tech debt

| ID | Isi | Dampak | Tiket |
|---|---|---|---|
| TD-1 | Flag coachmark Panen Semua hanya di memori, sekali per sesi. Setelah login ulang coachmark bisa muncul lagi untuk pemain Lv 3 ke atas. | Rendah | Tambah field `hasSeenPanenSemuaCoachmark` di profil server |
| TD-2 | `PromptGate` tidak menimpa perubahan yang dibuat sistem lain saat dialog terbuka (mengabaikan prompt yang dinyalakan pihak lain). Kalau pihak lain MEMATIKAN prompt saat dialog, `PromptGate` tetap menyalakannya lagi saat dialog tutup. | Sedang | FISH-PROMPT-OWNER: tiap pemilik prompt mendaftar state yang diinginkan, `PromptGate` hanya meminta refresh |

## Verifikasi

- `rojo build default.project.json` lolos (output ke folder scratchpad, bukan ke repo).
- Syntax Luau: lihat hasil di laporan Fase 1. Rojo tidak mengecek syntax Luau.
- Belum diuji di Studio. Daftar uji ada di `Fase1-Review-TestPlan`.
