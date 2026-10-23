--!strict
--[[
	ZorroRecetas

	Las capas de cada evento del zorro de agua (los datos de ZorroVoces.event,
	aparte para que ninguno pase de 200 líneas). voice(...) sigue el tono de la
	voz de la etapa; weight(...) el peso (tono y volumen, ver ZorroVoces).
	Opciones:
		stages   etapas en que suena (todas si falta)
		surface  "water" solo si pisa agua, "ice" solo si pisa un témpano
		pitch    multiplica el tono; volume el volumen; delay retraso en segundos
	Dónde suena: "head" (cabeza), "body" (centro del cuerpo) o "ground" (bajo
	el zorro: el agua o el hielo).

	Por etapa: la cría gañe y chilla, el joven ladra, el adulto y la forma
	final aúllan grave; desde el adulto un retumbo grave acompaña el aullido
	y las caídas, y los cristales de hielo de las colas tintinean.
]]

export type At = "head" | "body" | "ground"
export type Surface = "water" | "ice"
export type Layer = {
	key: string,
	at: At,
	tone: ("voice" | "weight")?,
	pitch: number?,
	volume: number?,
	stages: { number }?,
	surface: Surface?,
	delay: number?,
}
type Options = {
	stages: { number }?,
	surface: Surface?,
	pitch: number?,
	volume: number?,
	delay: number?,
}

local SMALL, BIG = { 1, 2 }, { 3, 4 }
local BABY, YOUNG, FINAL = { 1 }, { 2 }, { 4 }
local GROWN = { 2, 3, 4 } -- todas menos la cría

local function layer(key: string, at: At, tone: ("voice" | "weight")?, o: Options?): Layer
	local opts: Options = o or {}
	return {
		key = key,
		at = at,
		tone = tone,
		pitch = opts.pitch,
		volume = opts.volume,
		stages = opts.stages,
		surface = opts.surface,
		delay = opts.delay,
	}
end
local function voice(key: string, at: At, o: Options?): Layer
	return layer(key, at, "voice", o)
end
local function weight(key: string, at: At, o: Options?): Layer
	return layer(key, at, "weight", o)
end

local RECIPES: { [string]: { Layer } } = {
	howl = {
		voice("ZorroHowlYoung", "head", { pitch = 1.1, stages = BABY }),
		voice("ZorroHowlJoy", "head", { stages = YOUNG }),
		voice("ZorroHowlDeep", "head", { pitch = 1.15, stages = BIG }),
		voice("ZorroHowlBig", "head", { pitch = 0.9, volume = 0.5, stages = FINAL, delay = 0.4 }),
		layer("ZorroRumble", "ground", nil, { pitch = 0.8, volume = 0.7, stages = BIG }),
		weight("ZorroIceTink", "body", { volume = 0.5, stages = BIG, delay = 0.7 }),
	},
	fan = {
		weight("ZorroTailSwish", "body"),
		weight("ZorroBubbles", "body", { pitch = 1.2, volume = 0.4, delay = 0.15 }),
		layer(
			"ZorroShimmer",
			"body",
			nil,
			{ pitch = 1.2, volume = 0.5, stages = BIG, delay = 0.2 }
		),
		weight("ZorroIceTink", "body", { volume = 0.6, stages = FINAL, delay = 0.35 }),
	},
	crouch = {
		voice("ZorroGrowl", "head", { pitch = 1.2, volume = 0.3, stages = GROWN }),
		weight("ZorroStepWater", "ground", { volume = 0.5, surface = "water" }),
		weight("ZorroIceCrack", "ground", { volume = 0.5, surface = "ice" }),
	},
	land = {
		weight("ZorroSplash", "ground", { surface = "water" }),
		weight("ZorroSplashDeep", "ground", { volume = 0.8, stages = BIG, surface = "water" }),
		weight("ZorroIceCrack", "ground", { stages = SMALL, surface = "ice" }),
		weight("ZorroIceCrackBig", "ground", { stages = BIG, surface = "ice" }),
		layer("ZorroRumble", "ground", nil, { pitch = 1.1, volume = 0.6, stages = BIG }),
		weight("ZorroDrip", "ground", { volume = 0.6, delay = 0.5 }),
		voice("ZorroYelp", "head", { volume = 0.6, stages = BABY, delay = 0.4 }),
	},
	shake = {
		weight("ZorroShakeSwish", "body"),
		weight("ZorroDrip", "ground", { delay = 0.4 }),
		weight("ZorroIceTink", "body", { volume = 0.5, stages = BIG, delay = 0.3 }),
	},
	happy = {
		voice("ZorroYelp", "head", { stages = BABY }),
		voice("ZorroYipDouble", "head", { stages = GROWN }),
		voice("ZorroGekker", "head", { pitch = 1.2, volume = 0.5, stages = BABY, delay = 0.3 }),
		voice("ZorroGekker", "head", { pitch = 0.85, volume = 0.6, stages = BIG, delay = 0.4 }),
		voice("ZorroWhimper", "head", { pitch = 1.2, volume = 0.4, stages = BABY, delay = 0.5 }),
	},
	step = {
		weight("ZorroStepWater", "ground", { volume = 0.6, surface = "water" }),
		weight("ZorroIceCrack", "ground", { volume = 0.5, stages = SMALL, surface = "ice" }),
		weight("ZorroIceCrackBig", "ground", { volume = 0.4, stages = BIG, surface = "ice" }),
	},
	yip = {
		voice("ZorroYelp", "head", { stages = BABY }),
		voice("ZorroYip", "head", { stages = GROWN }),
		voice("ZorroBark", "head", { volume = 0.5, stages = BIG, delay = 0.1 }),
		voice("ZorroGekker", "head", { pitch = 0.8, volume = 0.5, stages = BIG, delay = 0.3 }),
	},
	whine = { -- gañido de la cría (prueba el hielo, persigue su cola y no la alcanza)
		voice("ZorroWhimper", "head", { stages = SMALL }),
		voice("ZorroGrowl", "head", { pitch = 1.3, volume = 0.25, stages = BIG }),
	},
	pounce = {
		weight("ZorroTailSwish", "body", { pitch = 1.3, volume = 0.7 }),
		weight("ZorroWhoosh", "body", { volume = 0.7, stages = BIG }),
		voice("ZorroYelp", "head", { volume = 0.7, stages = SMALL, delay = 0.1 }),
		voice("ZorroBark", "head", { volume = 0.6, stages = BIG, delay = 0.1 }),
		voice("ZorroScream", "head", { pitch = 0.9, volume = 0.6, stages = { 4 }, delay = 0.15 }),
	},
	yawn = {
		voice("ZorroYawn", "head", { pitch = 1.25 }),
		voice("ZorroWhimper", "head", { pitch = 1.3, volume = 0.3, stages = BABY, delay = 0.9 }),
	},
	sniff = {
		voice("ZorroSniff", "head", { pitch = 1.3, volume = 0.8 }),
		weight(
			"ZorroBubbles",
			"ground",
			{ pitch = 1.3, volume = 0.3, surface = "water", delay = 0.3 }
		),
	},
	splash = { -- manotazo o brinco chico en el agua
		weight("ZorroPaw", "ground", { surface = "water" }),
		weight("ZorroSplash", "ground", { pitch = 1.2, volume = 0.5, surface = "water" }),
		weight("ZorroIceCrack", "ground", { volume = 0.7, surface = "ice" }),
	},
	bite = {
		voice("ZorroBite", "head"),
		voice("ZorroGrowl", "head", { pitch = 1.2, volume = 0.3, stages = GROWN, delay = 0.1 }),
	},
}

return table.freeze(RECIPES)
