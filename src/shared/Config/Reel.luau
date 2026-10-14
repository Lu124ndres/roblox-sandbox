--!strict
--[[
	Reel

	Minijuego al recoger (como Fish It): cuando pica, una barra empieza en
	`startProgress`; cada toque la sube `gain` y el pez la baja `drain` por
	segundo. Llega a 1: atrapado. Llega a 0 o pasan `timeoutSeconds`: se
	escapa. El pez (y su rareza) se decide al picar, así los raros pelean más.

	Tiempo para atraparlo tocando a `tapsPerSecond` toques por segundo:
		(1 - startProgress) / (gain * fuerza * toques - drain)
	A 7 toques/s con la caña 1: Común ~0.8 s, Poco común ~1.2 s, Raro ~1.8 s,
	Épico ~2.6 s, Legendario ~3.8 s, Mítico ~5.5 s. Cada nivel de caña suma
	`strengthPerRodLevel` a la fuerza (caña 10 = x1.9), y los pases con
	traje la multiplican (ver Config.Monetization.passes).

	El servidor cuenta los toques (máximo `maxTapsPerSecond`, con `tapBurst`
	de colchón por el ping) y empieza a bajar la barra `graceSeconds` después
	de que pica, lo que tarda el aviso en llegar al jugador.
	Desde la rareza `announceFromRarity` (Legendario), todo el servidor ve un
	cartel con quién lo sacó.
]]

export type RarityReel = { gain: number, drain: number }

export type ReelConfig = {
	startProgress: number,
	timeoutSeconds: number,
	graceSeconds: number,
	maxTapsPerSecond: number,
	tapBurst: number,
	strengthPerRodLevel: number,
	announceFromRarity: number, -- índice en Config.Economy.rarities
	byRarity: { RarityReel }, -- en el orden de Config.Economy.rarities
}

local Reel: ReelConfig = {
	startProgress = 0.25,
	timeoutSeconds = 10,
	graceSeconds = 0.3,
	maxTapsPerSecond = 14,
	tapBurst = 4,
	strengthPerRodLevel = 0.1,
	announceFromRarity = 5,
	byRarity = {
		{ gain = 0.15, drain = 0.12 }, -- Común
		{ gain = 0.125, drain = 0.25 }, -- Poco común
		{ gain = 0.103, drain = 0.3 }, -- Raro
		{ gain = 0.09, drain = 0.34 }, -- Épico
		{ gain = 0.082, drain = 0.38 }, -- Legendario
		{ gain = 0.078, drain = 0.41 }, -- Mítico
	},
}

table.freeze(Reel.byRarity)
for _, entry in Reel.byRarity do
	table.freeze(entry)
end
table.freeze(Reel)

return Reel
