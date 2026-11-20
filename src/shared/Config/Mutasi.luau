--!strict
-- Mutasi panen (docs/Kampoeng_Tedoeh_Gameplay_Lengkap_v6.2.md Bab 5.4). Fase 1 isi: Embun only, for the FTUE first harvest
-- (Onboarding.FTUE_FIRST_MUTATION). The random roll (Embun 20%, Petir 10%, Emas 1%, Pelangi 3%) comes in Fase 2 and adds
-- entries here. A mutated item is "<mutation>_<crop>" (e.g. embun_kangkung); Super stacks in front: super_embun_kangkung.
-- price = sellPrice x mult (Bab 17.7: Mutasi and Super multiply, they do not replace each other).

export type Mutation = {
	id: string,
	mult: number,
	nameKey: string, -- Locale key of the mutation name (shown as "{crop} {mutation}")
}

local list: { Mutation } = {
	{ id = "embun", mult = 1.5, nameKey = "mutasi.embun" },
}

local byId: { [string]: Mutation } = {}
for _, mutation in list do
	byId[mutation.id] = mutation
end

return {
	list = list,
	byId = byId,
}
