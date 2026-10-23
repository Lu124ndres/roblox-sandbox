--!strict
--[[
	DragonRecetas

	Las capas de cada evento del dragón (los datos de DragonVoces, aparte para
	que ninguno pase de 200 líneas). voice(...) sigue el tono de la voz de la
	etapa; weight(...) el peso (tono y volumen, ver DragonVoces). Opciones:
		stages  etapas en que suena (todas si falta)
		pitch   multiplica el tono; volume el volumen; delay retraso en segundos
	Dónde suena: "head" (cabeza), "mouth" (boca), "body" (centro del cuerpo) o
	"ground" (el suelo bajo el dragón: la roca o la lava).
]]

export type Layer = {
	key: string,
	at: "head" | "mouth" | "body" | "ground",
	tone: ("voice" | "weight")?,
	pitch: number?,
	volume: number?,
	stages: { number }?,
	delay: number?,
}
type Options = { stages: { number }?, pitch: number?, volume: number?, delay: number? }
type At = "head" | "mouth" | "body" | "ground"

local SMALL, BIG = { 1, 2 }, { 3, 4 }
local BABY, YOUNG, ELDER = { 1 }, { 2 }, { 4 }
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
	roar = {
		voice("DragonBabyRoar", "head", { pitch = 1.5, stages = BABY }),
		voice("DragonScreech", "head", { stages = YOUNG }),
		voice("DragonRoarGrowl", "head", { volume = 0.5, stages = YOUNG }),
		voice("DragonRoar", "head", { pitch = 1.15, stages = BIG }),
		voice("DragonGrowl", "head", { pitch = 0.8, stages = { 3 }, delay = 0.3 }),
		layer("DragonRumble", "head", nil, { pitch = 0.85, volume = 0.8, stages = ELDER }),
	},
	fireStart = {
		weight("DragonFireLick", "mouth", { stages = SMALL }),
		weight("DragonFireStart", "mouth", { stages = BIG }),
		voice("DragonHatchling", "head", { volume = 0.6, stages = BABY }),
		voice("DragonGrowl", "head", { volume = 0.6, stages = GROWN }),
	},
	fireEnd = {
		weight("DragonFireLick", "mouth", { pitch = 0.8, volume = 0.8 }),
		weight("DragonSnort", "mouth", { volume = 0.6, delay = 0.25 }),
	},
	fireSky = {
		weight("DragonFireStart", "mouth", { pitch = 1.2, stages = BABY }),
		weight("DragonFireWave", "mouth", { stages = GROWN }),
		voice("DragonScreech", "head", { volume = 0.7, stages = SMALL }),
		voice("DragonRoar", "head", { pitch = 1.15, volume = 0.7, stages = BIG }),
	},
	flap = {
		weight("DragonFlapSmall", "body", { stages = BABY }),
		weight("DragonFlap", "body", { stages = { 2, 3 } }),
		weight("DragonFlapHeavy", "body", { stages = BIG }),
	},
	hover = { -- aleteo rápido para quedarse en el aire
		weight("DragonFlapSmall", "body", { volume = 0.8, stages = SMALL }),
		weight("DragonFlap", "body", { volume = 0.8, stages = BIG }),
	},
	whoosh = { weight("DragonGust", "body") },
	takeoff = {
		weight("DragonFlapBurst", "body"),
		weight("DragonGust", "ground", { volume = 0.8, delay = 0.15 }),
		voice("DragonHatchling", "head", { volume = 0.6, stages = BABY }),
		voice("DragonGrowl", "head", { volume = 0.5, stages = BIG }),
	},
	land = {
		weight("DragonFlapBurst", "body", { volume = 0.7 }),
		weight("DragonLand", "ground", { delay = 0.1 }),
		weight("DragonDebris", "ground", { volume = 0.7, stages = GROWN, delay = 0.25 }),
		weight("DragonBoom", "ground", { volume = 0.8, stages = ELDER, delay = 0.1 }),
		voice("DragonHatchling", "head", { volume = 0.6, stages = BABY, delay = 0.5 }),
	},
	fold = {
		weight("DragonFold", "body", { volume = 0.6 }),
		weight("DragonRocks", "ground", { volume = 0.4, stages = BIG, delay = 0.3 }),
	},
	stretch = {
		voice("DragonChirp", "head", { stages = SMALL }),
		voice("DragonYawn", "head", { pitch = 0.9, stages = BIG }),
		weight("DragonFold", "body", { volume = 0.5, delay = 0.2 }),
	},
	preen = {
		voice("DragonHiss", "head", { pitch = 1.2, volume = 0.4 }),
		weight("DragonFold", "body", { volume = 0.4, delay = 0.2 }),
		voice("DragonHatchling", "head", { volume = 0.6, stages = BABY, delay = 0.5 }),
	},
	sleep = {
		voice("DragonYawn", "head", { volume = 0.8 }),
		weight("DragonRocks", "ground", { volume = 0.5, stages = GROWN, delay = 0.4 }),
	},
	wake = {
		voice("DragonSnort", "head"),
		voice("DragonChirp", "head", { stages = SMALL, delay = 0.3 }),
		voice("DragonHiss", "head", { volume = 0.5, stages = BIG, delay = 0.3 }),
	},
	evolve = { -- al abrir las alas: trino y rugido de cría, rugido del adulto, trueno del anciano
		voice("DragonHatchling", "head", { stages = BABY }),
		voice("DragonBabyRoar", "head", { pitch = 1.35, stages = SMALL, delay = 0.2 }),
		voice("DragonRoar", "head", { pitch = 1.1, stages = BIG }),
		layer("DragonRumble", "head", nil, { pitch = 0.85, volume = 0.8, stages = ELDER }),
		weight("DragonFlapBurst", "body", { volume = 0.8, delay = 0.1 }),
	},
	fire = { -- truco del fuego: el grito antes de la llamarada (el fuego suena aparte)
		voice("DragonBabyRoar", "head", { pitch = 1.5, volume = 0.7, stages = SMALL }),
		voice("DragonRoarGrowl", "head", { volume = 0.8, stages = BIG }),
	},
	joy = { -- festejo al comer: trino de gusto; el grande ronronea debajo
		voice("DragonJoy", "head", { stages = SMALL }),
		voice("DragonJoy", "head", { pitch = 0.75, volume = 0.6, stages = BIG }),
		voice("DragonPurrDeep", "head", { volume = 0.7, stages = BIG, delay = 0.2 }),
	},
	glide = { -- deja de aletear y planea: ráfaga larga y un gruñido tranquilo
		weight("DragonGust", "body", { volume = 0.7 }),
		voice("DragonHatchling", "head", { volume = 0.5, stages = BABY, delay = 0.6 }),
		voice("DragonGrowl", "head", { pitch = 0.9, volume = 0.5, stages = GROWN, delay = 0.6 }),
	},
	flip = { -- voltereta: chillido de gusto arriba del todo
		voice("DragonHatchling", "head", { pitch = 1.2, stages = BABY }),
		voice("DragonScreech", "head", { pitch = 1.1, volume = 0.6, stages = YOUNG }),
		voice("DragonRoarGrowl", "head", { volume = 0.6, stages = BIG }),
	},
	idle = { -- posado, cada tanto: resopla humo y gruñe bajito
		voice("DragonSnort", "head", { volume = 0.5 }),
		voice("DragonHatchling", "head", { volume = 0.4, stages = BABY, delay = 0.4 }),
		voice("DragonGrowl", "head", { volume = 0.5, stages = BIG, delay = 0.3 }),
	},
	growl = { -- volando tranquilo, cada tanto
		voice("DragonHatchling", "head", { volume = 0.6, stages = BABY }),
		voice("DragonScreech", "head", { volume = 0.4, stages = YOUNG }),
		voice("DragonGrowl", "head", { volume = 0.7, stages = BIG }),
	},
}

return table.freeze(RECIPES)
