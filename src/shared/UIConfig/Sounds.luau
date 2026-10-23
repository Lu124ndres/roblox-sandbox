--!strict
--[[
	Volumen (0..10), tono y alcance de cada sonido de Assets.Sounds. Sección
	de UIConfig en su propio archivo para que ninguno pase de 200 líneas.
]]

export type SoundSettings = {
	volume: number,
	pitch: number?,
	rollOff: number?, -- distancia máxima en studs para sonidos 3D
}

local Sounds: { [string]: SoundSettings } = {
	OceanWaves = { volume = 0.45 },
	Seagull = { volume = 0.5, rollOff = 220 },
	RodOut = { volume = 0.35, pitch = 1.4, rollOff = 60 },
	Cast = { volume = 0.5, pitch = 1.6, rollOff = 70 },
	Plop = { volume = 0.35, pitch = 1.8, rollOff = 70 },
	Bite = { volume = 0.7, pitch = 1.2, rollOff = 60 },
	Reel = { volume = 0.6, rollOff = 60 },
	Catch = { volume = 0.6, pitch = 1.3, rollOff = 80 },
	Escape = { volume = 0.35, pitch = 0.7, rollOff = 60 },
	FishFlop = { volume = 0.6, rollOff = 50 },
	CatchPop = { volume = 0.5, rollOff = 70 },
	RareCatch = { volume = 0.7, rollOff = 120 },
	EpicCatch = { volume = 0.8, rollOff = 160 },
	LegendaryCatch = { volume = 1, rollOff = 260 },
	Whoosh = { volume = 0.5, rollOff = 90 },
	Chomp = { volume = 0.8, rollOff = 160 },
	OrcaCall = { volume = 0.7, rollOff = 260 },
	Spout = { volume = 0.6, pitch = 0.7, rollOff = 180 },
	BigSplash = { volume = 0.9, pitch = 0.6, rollOff = 260 },
	StageUp = { volume = 0.7 },
	GiantDefeat = { volume = 0.6 },
	EvolveShine = { volume = 0.8 },
	Coins = { volume = 0.6 },
	CoinPop = { volume = 0.25, pitch = 1.5 },
	PowerTick = { volume = 0.25, pitch = 1.7 },
	Roar = { volume = 1, rollOff = 600 },
	HorrorAmbience = { volume = 0.6 },
	MusicIsland = { volume = 0.3 },
	MusicCrater = { volume = 0.35 },
	MusicRest = { volume = 0.4 },
	Thunder = { volume = 0.7 },
	Click = { volume = 0.4 },
}

return Sounds
