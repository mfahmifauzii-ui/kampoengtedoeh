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
`TUTORIALS` (kosong sampai P2) berisi `Tutorial`: `id`, `title`, `trigger`, `intro?`, `steps` (1–4), `reward?`, `auto?`. Tiap `Step`: `id`, `text`, `textStuck?`, `done` (kondisi `>=`), `highlight?` (nama tombol HUD), `target?` (`npc` atau `pos`, panah di tanah), `arrive?`, `reward?`.
- Kondisi: `always`, `tiles`, `planted`, `watered`, `ripe`, `item` (awalan id), `level`, `near` (npc), `panel` (nama ScreenGui), `garap`.
- Pemicu: `newPlayer`, `level`, `done` (tutorial lain selesai/dilewati), `manual`.
- Angka: `GAP_SECONDS` 120, `STUCK_STRONG` 45, `STUCK_TEXT` 90, `REPLAY_MIN_SECONDS` 4, `FAST_PLANTINGS` 6, `FAST_GROW_SECONDS` 20.
- `TEST_TUTORIAL` (`dev_test`, hanya Studio, `auto = false`): 3 langkah untuk menguji mesin. Ubah `auto = true` untuk melihatnya mulai sendiri di save baru Studio.

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
`!tut` mencetak `data.guide`; `!tut reset` melupakan step/done/skipped; `!tut fast` mengisi `fastLeft = 6`.

## Hasil uji Studio (15 Nov 2026)
- **Save lama** (Lv 1, `sells = 1`): masuk tanpa error; `fastLeft = 0`; `fresh = false`; tutorial tes tidak mulai; panduan lama tetap tampil.
- **Save kosong** (`!reset`): `fastLeft = 6`; tutorial tes mulai sendiri; cincin berdenyut di tombol Garap; Lewati tampil; hint turun di bawah baris Garap; langkah 1 (Garap terbuka) dan 2 (2 petak, +1 XP dari server) tercentang; panah tampil ke Pak Darmo di langkah 3; teks macet muncul setelah 90 d.
- Rejoin di tengah tutorial → lanjut dari langkah tersimpan. **Lewati** → tersimpan sebagai dilewati, tidak mulai lagi setelah rejoin, panduan lama kembali. Panduan: status benar, **Ulang** memutar dari awal dengan pengantar.
- Bibit cepat: tanam pertama tumbuh 20 d, `fastLeft` 6 → 5, setelah disiram sisa waktu ×0,8.
- Layar yang dicek lewat screenshot Studio (viewport 1335×630, bukan HP).

## Belum teruji
- HP asli: ukuran tombol Lewati, hint bar vs joystick, cincin di dock yang menyempit (mode HUD ringkas).
- Cincin lebih terang pada 45 d (logika sama dengan 90 d, tidak dilihat di layar); pengulangan penuh sampai langkah terakhir; langkah `ripe`, `watered`, `item`, `level`, `panel`, `near` (hanya `garap`, `tiles`, `near` diuji lewat tutorial tes; `near` belum diselesaikan).
- Jeda antrean 120 d antar dua tutorial otomatis (hanya ada satu tutorial otomatis); `newPlayer` pada save lama tanpa petak.
- Hadiah koin/item/Bunga dan hadiah tutorial penuh (hanya XP langkah diuji); event analytics di dashboard Roblox (hanya dipanggil, dibungkus pcall).
- Timer bibit normal setelah 6 penanaman (kode: `fastLeft = 0` → timer biasa; belum ditanam sampai habis); bibit unggul pada penanaman cepat.
- 2+ pemain; bibit tutorial dengan hujan.
- Catatan: `docs/Implementation_Plan.md` belum ada di repo (versi yang dibaca ada di folder Downloads); dompet awal Studio saat ini 150 Koin, bukan 100 (P8).
