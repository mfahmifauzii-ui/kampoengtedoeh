--!strict
-- DEV scenarios (Putaran 2, task 0): "!skenario <nama>" runs these chat commands in order, through the same server code paths
-- as the real game. Add a preset here, nothing else. Every line is one "!" command without the "!".
-- Studio only commands work in Studio and for the owner live (see DevService.IsAllowed).
return {
	pasca_tutorial = { "level 2", "give kangkung 6" },
	mancing = { "level 5", "rod kayu_jati", "give cacing 20", "give jangkrik 20", "give pelet 20" },
	lv6_dapur = { "level 6", "koin 2000", "give kangkung 10" },
	lv10_penuh = { "level 10", "koin 12000", "bunga 10", "give kangkung 20", "give cacing 20", "give jangkrik 20", "give pelet 20" },
	hujan_deres = { "cuaca deres" },
	event_agustusan = { "event agustusan" },
	pasar_malam = { "time malam", "event off" },
	solo_server = { "level 2" },
}
