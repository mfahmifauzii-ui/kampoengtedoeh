--!strict
-- Surat Kakek (Bab 14.3, LOCKED, P2-7-fix): 30 surat, 1 per hari login, kumulatif
-- (tidak reset kalau tidak login). Tiap surat = 1 tugas kecil + hadiah.
-- Jumlah hadiah = USULAN (v7.3: "Koin / Bunga / bahan" tanpa angka; butuh lock owner).

export type Surat = {
	n: number,
	text: string, -- isi surat (1-2 baris, suara Kakek)
	event: string, -- event QuestService.Report yang dihitung
	count: number,
	reward: { koin: number?, bunga: number?, bahan: { [string]: number }? },
}

-- Bahan memakai id mentah (kayu/bambu/batu/tanah_liat/pasir) atau "garam".
local list: { Surat } = {
	{ n = 1, text = "Nak, kalau hujan, jangan lari. Siram tanamanmu, biar Prima.", event = "water", count = 1, reward = { koin = 50 } },
	{ n = 2, text = "Cangkul yang rajin. Tanam 2 Kangkung hari ini.", event = "plant_kangkung", count = 2, reward = { koin = 60 } },
	{ n = 3, text = "Ikan pagi paling segar. Mancing 1 ekor, jangan lupa umpan.", event = "catch", count = 1, reward = { koin = 60 } },
	{ n = 4, text = "Panen 2 tanaman. Yang matang jangan dibiarkan.", event = "harvest", count = 2, reward = { koin = 70 } },
	{ n = 5, text = "Kayu itu tulang kebun. Nambang 5 bahan.", event = "mine", count = 5, reward = { koin = 70, bahan = { kayu = 3 } } },
	{ n = 6, text = "Tetangga itu keluarga jauh. Bantu 1 lahan.", event = "bantu", count = 1, reward = { koin = 80 } },
	{ n = 7, text = "Perut kenyang, kerja senang. Masak 1 olahan.", event = "cook", count = 1, reward = { koin = 80 } },
	{ n = 8, text = "Siram 3 tanaman sebelum tengah hari.", event = "water", count = 3, reward = { koin = 90 } },
	{ n = 9, text = "Taruh 1 hiasan. Kebun cantik, hati senang.", event = "decor_placed", count = 1, reward = { koin = 90 } },
	{ n = 10, text = "Mancing 2 ikan. Kak Fajar titip salam.", event = "catch", count = 2, reward = { koin = 100 } },
	{ n = 11, text = "Panen 3 tanaman. Pilih yang paling segar.", event = "harvest", count = 3, reward = { koin = 100 } },
	{ n = 12, text = "Batu kali kuat untuk fondasi. Nambang 8 bahan.", event = "mine", count = 8, reward = { koin = 110, bahan = { batu = 3 } } },
	{ n = 13, text = "Hari ini genap 13. Bantu 1 lahan tetangga.", event = "bantu", count = 1, reward = { koin = 110 } },
	{ n = 14, text = "Dua minggu kebunmu jalan. Masak 1 olahan spesial.", event = "cook", count = 1, reward = { koin = 120, bunga = 1 } },
	{ n = 15, text = "Tanam 3 apa saja. Tanah jangan menganggur.", event = "plant", count = 3, reward = { koin = 120 } },
	{ n = 16, text = "Siram 3 tanaman. Air itu nyawa.", event = "water", count = 3, reward = { koin = 120 } },
	{ n = 17, text = "Mancing 3 ikan. Umpan yang sabar.", event = "catch", count = 3, reward = { koin = 130 } },
	{ n = 18, text = "Panen 4 tanaman. Bagi sedikit ke tetangga.", event = "harvest", count = 4, reward = { koin = 130 } },
	{ n = 19, text = "Nambang 10 bahan. Bangun yang kokoh.", event = "mine", count = 10, reward = { koin = 140, bahan = { bambu = 4 } } },
	{ n = 20, text = "Dua puluh surat! Bantu 2 lahan hari ini.", event = "bantu", count = 2, reward = { koin = 140, bunga = 1 } },
	{ n = 21, text = "Masak 2 olahan. Satu untukmu, satu untuk Mak Sari.", event = "cook", count = 2, reward = { koin = 150 } },
	{ n = 22, text = "Taruh 2 hiasan. Alun-alun iri padamu.", event = "decor_placed", count = 2, reward = { koin = 150 } },
	{ n = 23, text = "Tanam 4 apa saja. Musim tidak menunggu.", event = "plant", count = 4, reward = { koin = 150, bahan = { tanah_liat = 3 } } },
	{ n = 24, text = "Mancing 3 ikan di kolammu sendiri.", event = "catch_pond", count = 3, reward = { koin = 150 } },
	{ n = 25, text = "Seperempat ratus surat. Panen 5 tanaman.", event = "harvest", count = 5, reward = { koin = 150, bunga = 1 } },
	{ n = 26, text = "Siram 4 tanaman. Kakek bangga padamu.", event = "water", count = 4, reward = { koin = 150 } },
	{ n = 27, text = "Nambang 12 bahan. Tangan boleh kapalan.", event = "mine", count = 12, reward = { koin = 150, bahan = { pasir = 4 } } },
	{ n = 28, text = "Masak 2 olahan. Resep warisan jangan putus.", event = "cook", count = 2, reward = { koin = 150, bahan = { garam = 2 } } },
	{ n = 29, text = "Bantu 2 lahan. Kebaikan kembali padamu.", event = "bantu", count = 2, reward = { koin = 150, bunga = 2 } },
	{ n = 30, text = "Surat terakhir. Panen 5, Mancing 3 sudah cukup. Terima kasih sudah menjaga kampung, Nak.", event = "harvest", count = 5, reward = { koin = 200, bunga = 3 } },
}

local byN: { [number]: Surat } = {}
for _, surat in list do
	byN[surat.n] = surat
end

return {
	list = list,
	byN = byN,
	COUNT = 30,
}
