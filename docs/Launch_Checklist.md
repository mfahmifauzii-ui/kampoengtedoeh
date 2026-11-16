# Launch Checklist — tick everything before public launch (tanpa tanggal; setelah Playtest #1 dan #2 lolos)

## Data (do these in order)
- [ ] Playtest finished, no data errors in the dashboard Error Report.
- [ ] `DataService.luau`: `DATA_STAGE = "live"`. This gives everyone fresh saves; playtest saves stay in `_playtest`.
- [ ] After launch, **never change `DATA_STAGE` or the template structure without a migration** (`Data/Migrations.luau` + bump `version`).
- [ ] Studio uses `KampungTeduh_Studio` automatically, so it never touches live saves.

## Game settings (Creator Dashboard / Studio Game Settings)
- [ ] Places → **Max Players = jumlah slot lahan** (**8**, sesuai peta cincin; `Config/Plots` `COUNT`). Server fill: default.
- [ ] Avatar: R15 (emotes and Animate assume default animations).
- [ ] **Devices:** Phone, Tablet, Computer (Console optional once tested).
- [ ] **Experience Questionnaire** answered honestly: no violence, no gambling, no paid random items, social chat = Roblox default.
- [ ] Genre: Town and City / Simulation. Source language: **Indonesian**. Turn on automatic translation later, after EN locale.
- [ ] Private servers: on, 50 R$/month (or free during the first weeks; your choice).
- [ ] Icon (512×512) + 3 thumbnails or a video. Show farming, fishing and a decorated plot. No misleading art.
- [ ] Description in Indonesian: what you do, that it's calm, "tanpa musuh". No "free Robux" or off-platform links.

## Monetization
- [ ] 4 passes + 7 products created; ids pasted into `Config/Monetization.luau`; names/icons match what is sold.
- [ ] Run `docs/Monetization_Review.md`; every box ticked.
- [ ] Test-buy one pass and one product in a **live** server (Studio test purchases are free), then rejoin to verify persistence.

## Content & assets
- [ ] All audio ids play in a live server: 4 music tracks, ambience, SFX. Replace any that fail (e.g. the one that returned HTTP 502 earlier).
- [ ] Placeholder buildings replaced by your models: plots, warung, river, empang, rumah. Names follow the contracts in each config header.
- [ ] Designed UI hooked up; every placeholder panel name kept (see the controller headers).
- [ ] HUD fits a 360×640 phone: group Pesanan, Koleksi, Warga, Atur and Toko into a menu.

## Quality
- [ ] Phone test (low-end Android): touch fishing, decor placement with Pasang/Putar, panels scroll, ≥ 30 FPS with 8 lahan terisi.
- [ ] Studio → Test → banyak pemain: Mampir, Suka, shared river/warung, plots assigned and freed correctly; pemain yang pindah server mendapat lahan dengan isi yang sama.
- [ ] Kuota warung: jual sampai habis, lalu ke Bang Tarno 0,7×; reset 00:00 WIB.
- [ ] Leave and rejoin mid-fishing, mid-growth, and right after a purchase; nothing is lost or duplicated.
- [ ] Output clean in a live server (Developer Console F9 → Server tab).
- [ ] Microprofiler / Developer Console memory: no steady growth over 30 minutes.

## Launch day
- [ ] Make public in the morning WIB (peak malam hari ~15:00–22:00 WIB; pantau segera setelahnya).
- [ ] Watch the funnel + Error Report on day 1; keep one hotfix slot free.

## Status jujur sesi overnight 16 Nov 2026 (dibuat otomatis, belum diverifikasi manusia)
Legenda: BERES = kode ada dan Play bersih; BELUM = belum dikerjakan; BELUM DITES = kode ada tapi belum diuji di Studio.

- [ ] Playtest #1 lolos: **BELUM DITES** (checklist ada di Playtest_Plan.md).
- [ ] Hapus `DevService` command `!tool gembor` dan `!rod` / `!koin` untuk launch: **BELUM** (masih ada, dipakai untuk tes).
- [ ] `DATA_STAGE = "live"`: **BELUM** (tidak diubah sesi ini).
- [ ] Performa 60 FPS Studio / 30 FPS HP, batas partikel 50, gabung part: **BELUM** (tidak dikerjakan).
- [ ] HP cek 844x390 dan 1280x720: **BELUM** (tidak dikerjakan).
- [ ] Save 3x rejoin tanpa data hilang: **BELUM DITES penuh** (satu akun sudah rejoin sekali, data sama; belum 3x dan belum akun baru).
- [ ] Audio: SFX pendek (cangkul, siram, panen, dll) **BELUM** (id SFX di Config/Audio masih nil). Volume musik 0,3, alam 0,4, SFX 0,5 **BERES** (config).
- [ ] Gembor Bambu, Sprinkler: Gembor **BELUM DITES** (pembelian belum terbukti). Sprinkler **BELUM**.
- [ ] Quest Misi Utama (3 langkah) + Daily: **BERES** kode dan tracker tampil Daily; **BELUM DITES** sampai selesai.
- [ ] Hias 6 item awal: **BERES** di config (pagar_bambu, jalan_batu, bunga_kamboja, lampu_taman, kursi_kayu, pohon_pisang_hias). Hapus = refund 50 persen: **BERES** kode, **BELUM DITES**. Pindah dengan preview transparan dan menu Pindah/Hapus/Putar: **BELUM DIVERIFIKASI** (sudah ada sebelumnya, tidak diubah).
- [ ] Mancing Stage 5: harga ikan (Lele 12, Mas 20, Gurame 25), Pancing Kayu (label), gigitan 3-5 dtk, no-fail (REEL_WINDOW 300 dtk): **BERES** config. Tombol Mancing 4 stud di kolam: **BELUM** (prompt masih 12 stud).
- [ ] Tas 50 di awal dan 100 dari Lv 10: **BERES** kode, **BELUM DITES**.
- [ ] Toko tiga tab (Bibit, Hias, Alat): **BELUM** (Alat Kebun baru ada sebagai section di Pak Darmo).
