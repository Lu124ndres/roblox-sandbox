--!strict
--[[
	GiantMomentRecipes

	Qué suena en cada momento del ciclo de cada gigante (GiantMoments). Cada
	capa dice para qué edad es:
		young  cría (etapas 1 y 2): voces de cría de verdad, no la adulta aguda
		adult  adulto (3 y 4)
		final  solo la etapa final: las capas graves que la hacen enorme
		nil    todas
	at = "water" suena en el agua bajo el gigante; si no, en su cabeza. Los
	momentos sin lugar (hambre, furia, calma: el aviso del panel) suenan para
	todos sin posición. Exagerado a propósito: voz + cuerpo + agua o golpe.

	Los gigantes sin receta (Orca Fantasma, por ahora) usan "default": el
	rugido y el llamado de siempre.
]]

export type Age = "young" | "adult" | "final"
export type Layer = {
	key: string,
	age: Age?,
	pitch: number?,
	volume: number?,
	delay: number?,
	at: ("head" | "water")?,
}
type Options = { pitch: number?, volume: number?, delay: number?, at: ("head" | "water")? }

local function L(key: string, age: Age?, o: Options?): Layer
	local options: Options = o or {}
	return {
		key = key,
		age = age,
		pitch = options.pitch,
		volume = options.volume,
		delay = options.delay,
		at = options.at,
	}
end

local RECIPES: { [string]: { [string]: { Layer } } } = {
	Orca = {
		arrive = {
			L("OrcaCalfSqueak", "young", { pitch = 1.1 }),
			L("OrcaBlow", nil, { delay = 0.5 }),
			L("BigSplash", nil, { pitch = 0.8, delay = 0.6, at = "water" }),
		},
		farewell = {
			L("OrcaCalfSqueak", "young"),
			L("OrcaCall", "adult", { pitch = 0.9 }),
			L("OrcaCallDeep", "final", { pitch = 0.75, volume = 0.8 }),
			L("OrcaBlow", nil, { pitch = 0.8, delay = 0.4 }),
		},
		hungry = {
			L("OrcaCalfSqueak", "young", { pitch = 0.85 }),
			L("OrcaHungry", "adult", { pitch = 0.7 }),
		},
		furious = {
			L("OrcaCalfSqueak", "young", { pitch = 1.15 }),
			L("Roar", "adult", { pitch = 0.8 }),
			L("OrcaHungry", "adult", { pitch = 0.55, delay = 0.3 }),
			L("OrcaTailSlap", nil, { pitch = 0.8, delay = 0.5 }),
		},
		calm = {
			L("OrcaFull", "young", { pitch = 1.2 }),
			L("OrcaFull", "adult", { pitch = 0.9 }),
			L("OrcaClicks", nil, { delay = 0.6 }),
		},
		evolve = {
			L("OrcaCalfSqueak", "young", { pitch = 1.05 }),
			L("OrcaCall", "adult"),
			L("OrcaCallDeep", "final", { pitch = 0.7, volume = 0.8 }),
			L("Roar", "final", { pitch = 0.7, delay = 0.2 }),
			L("OrcaBlow", nil, { delay = 0.3 }),
		},
	},
	Minotauro = {
		arrive = {
			L("MinoCalf", "young", { pitch = 1.5 }),
			L("MinoSnort", nil, { pitch = 1.3, delay = 0.5 }),
			L("MinoSandHit", nil, { delay = 0.6, at = "water" }),
		},
		farewell = {
			L("MinoBellowDeep", "adult"),
			L("MinoRumble", "final", { pitch = 0.85 }),
			L("MinoCalf", "young", { pitch = 1.3 }),
			L("MinoBoom", nil, { delay = 0.6, at = "water" }),
		},
		hungry = {
			L("MinoCalf", "young", { pitch = 1.35 }),
			L("MinoHungry", "adult"),
			L("MinoSnort", "adult", { pitch = 0.8, delay = 0.9 }),
		},
		furious = {
			L("MinoCalf", "young", { pitch = 1.2 }),
			L("MinoSnort", nil, { delay = 0.3 }),
			L("MinoBellowDeep", "adult", { pitch = 0.9 }),
			L("MinoGrowl", "adult", { delay = 0.4 }),
			L("MinoRumble", "final", { pitch = 0.8, volume = 0.8 }),
		},
		calm = {
			L("MinoHappy", "young", { pitch = 1.4 }),
			L("MinoHappy", "adult"),
			L("MinoBurp", "adult", { pitch = 0.8, delay = 0.8 }),
		},
	},
	DragonMarino = {
		arrive = {
			L("DragonHatchling", "young", { pitch = 0.9 }),
			L("DragonBabyRoar", "young", { pitch = 1.5, delay = 0.4 }),
			L("DragonFlapSmall", nil, { delay = 0.2 }),
		},
		farewell = {
			L("DragonHatchling", "young"),
			L("DragonRoar", "adult"),
			L("DragonRumble", "final", { pitch = 0.85 }),
			L("DragonFlapBurst", nil, { delay = 0.3 }),
		},
		hungry = {
			L("DragonHatchling", "young", { pitch = 0.75 }),
			L("DragonHungry", "adult"),
			L("DragonHiss", "adult", { volume = 0.6, delay = 1 }),
		},
		furious = {
			L("DragonBabyRoar", "young", { pitch = 1.4 }),
			L("DragonRoar", "adult"),
			L("DragonFireLick", "adult", { delay = 0.5 }),
			L("DragonRumble", "final", { pitch = 0.8, volume = 0.8 }),
		},
		calm = {
			L("DragonJoy", "young"),
			L("DragonPurrDeep", "adult"),
			L("DragonJoy", "adult", { pitch = 0.75, volume = 0.6, delay = 0.5 }),
		},
	},
	ZorroDeAgua = {
		arrive = {
			L("ZorroYelp", "young"),
			L("ZorroWhimper", "young", { pitch = 1.2, volume = 0.6, delay = 0.4 }),
			L("ZorroSplash", nil, { delay = 0.5, at = "water" }),
		},
		farewell = {
			L("ZorroHowlYoung", "young"),
			L("ZorroHowlDeep", "adult"),
			L("ZorroHowlBig", "final", { pitch = 0.9, delay = 0.4 }),
			L("ZorroRumble", "final", { pitch = 0.8, volume = 0.7 }),
		},
		hungry = {
			L("ZorroWhimper", "young"),
			L("ZorroHungry", "adult", { pitch = 0.9 }),
		},
		furious = {
			L("ZorroYelp", "young", { pitch = 1.1 }),
			L("ZorroGekker", "young", { pitch = 1.3, delay = 0.2 }),
			L("ZorroScream", "adult", { pitch = 0.85 }),
			L("ZorroGekker", "adult", { pitch = 0.75, delay = 0.4 }),
			L("ZorroGrowl", "final", { pitch = 0.8, delay = 0.2 }),
		},
		calm = {
			L("ZorroYelp", "young", { pitch = 1.2 }),
			L("ZorroFull", "adult", { pitch = 1.2 }),
			L("ZorroYipDouble", "adult", { delay = 0.6 }),
		},
	},
	default = {
		arrive = { L("OrcaCall", nil, { pitch = 0.8 }), L("Roar", nil, { delay = 0.6 }) },
		farewell = { L("Roar") },
		hungry = { L("Roar", nil, { pitch = 1.15 }) },
		furious = { L("Roar") },
		evolve = { L("Roar") },
	},
}

return table.freeze(RECIPES)
