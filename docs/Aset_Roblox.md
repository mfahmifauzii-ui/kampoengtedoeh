# Aset yang sudah di-upload ke Roblox (15 Nov 2026)

Dibuat di ForgeGUI, dipublikasikan lewat koneksi "Roblox account" (user 9416491408), disetujui moderasi, lalu dimasukkan ke Studio.

## Model tanaman (`ReplicatedStorage.CropModels.<id>`)
Satu model = satu-satunya sumber: dipakai di petak **dan** sebagai gambar kartu di pemilih bibit (ViewportFrame membingkai model yang sama), jadi thumbnail dan model tidak mungkin berbeda.

| Tanaman | Asset id (Model) |
|---|---|
| kangkung | 129253939609482 |
| cabai | 71736422592826 |
| tomat | 105593311764194 |
| terong | 112065616628779 |
| jagung | 133678754256341 |
| singkong | 133178576895572 |
| padi | 90856688320565 |
| pisang | 120999355179984 |

Tinggi ditentukan `CROP_HEIGHT` di `FarmController` (satu model untuk tiga tahap tumbuh, diskalakan 30/65/100%).
**Catatan:** model disimpan sebagai paket di Studio (PackageLink dihapus). Isi `CropModels` ada di place, bukan di repo: jangan hapus folder itu.

## Ikon GUI (Config/UiAssets)
| Ikon | Image id |
|---|---|
| siram (kaleng siram) | 128270474264694 |
| panen (bakul sayur) | 72510453002470 |

## NPC (`ServerStorage.NpcModels.<npcId>`)
Avatar R15 dari pembuat avatar Roblox (Studio MCP `generate_avatar`, pipeline `npc`), satu per orang, ±7 menit tiap karakter dan Studio terputus selama itu. `NpcService` memakai template ini bila ada (id NPC atau `model` di `Config/Npcs`), menanamnya di lantai, dan memutar animasi diam. Rig polos lama di `Workspace.Npcs` dihapus agar template yang dipakai.

| NPC | Deskripsi |
|---|---|
| pak_darmo | pria Jawa ±55 th, peci hitam, batik krem, kacamata |
| bu_wati | wanita Jawa ±40 th, sanggul, kebaya hijau, kain batik |
| mas_joko | nelayan ±30 th, caping bambu, kaos biru, celana pendek |
| mbok_minah | nenek ±60 th, sanggul abu, kebaya bata, jarik, selendang |
| mbak_arsi | tukang ±28 th, kuncir + ikat kepala batik, kemeja kuning kerja, ban perkakas |
| bang_tarno | pria ±45 th, kemeja koko putih, sarung kotak, kopiah (dipakai 4 warung mini) |

**Risiko:** aset hasil generator memicu ratusan peringatan `No asset content representation found` di log Play. Di Studio semua tampil benar; **belum dicek di server live** (aset mungkin perlu dipublikasikan bersama place). Cek di playtest nyata.
`assets/rig/r15.blend` (rig R15 dari pemilik) belum dipakai: dibuat bila model Blender sendiri diperlukan.
