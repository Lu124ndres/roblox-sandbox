--!strict
--[[
	DragonRecetasComer

	Las capas de los eventos de la animación especial al comer del dragón
	(Dragon/Comer), con la misma forma que DragonRecetas (DragonVoces busca en
	las dos). voice sigue el tono de la voz de la etapa; weight, el peso.
		chomp       chasquido de la mandíbula (cada pez; más grave al crecer)
		gulp        el trago que baja por el cuello
		savor       ronroneo de gusto (la cría y el joven ronronean; el adulto y
		            el anciano, un ronroneo gutural) con un resoplido
		dedicate    ronroneo y pío para el jugador que le dio el pez
		treat       campanitas del pez raro y un chillido o gruñido de gusto
		treatFlare  la llamarada del pez raro
		cheer       el grito de alegría de los festejos (joy, la vuelta o el
		            aletazo, suena con whoosh o con el rugido)
		fireRing    el anillo de fuego; feast, la lluvia de chispas doradas
	whoosh, roar y fireSky (también al festejar) son los de DragonRecetas.
]]

local DragonRecetas = require(script.Parent.DragonRecetas)

type Layer = DragonRecetas.Layer
type At = "head" | "mouth" | "body" | "ground"
type Options = { stages: { number }?, pitch: number?, volume: number?, delay: number? }

local SMALL, BIG = { 1, 2 }, { 3, 4 }
local BABY, GROWN = { 1 }, { 2, 3, 4 }

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
	chomp = { weight("DragonSnap", "mouth", { volume = 0.7 }) },
	gulp = { weight("DragonGulp", "head", { pitch = 0.9, volume = 0.5 }) },
	savor = {
		voice("DragonPurr", "head", { volume = 0.6, stages = SMALL }),
		voice("DragonPurrDeep", "head", { pitch = 1.2, volume = 0.6, stages = BIG }),
		weight("DragonSnort", "mouth", { volume = 0.35, delay = 0.15 }),
	},
	dedicate = {
		voice("DragonPurr", "head", { pitch = 1.1, volume = 0.7 }),
		voice("DragonChirp", "head", { volume = 0.5, stages = BABY, delay = 0.25 }),
		voice("DragonGrowl", "head", { pitch = 1.2, volume = 0.35, stages = BIG, delay = 0.25 }),
	},
	treat = {
		layer("DragonTreat", "mouth", nil, { volume = 0.7 }),
		voice("DragonChirp", "head", { volume = 0.6, stages = SMALL, delay = 0.15 }),
		voice("DragonGrowl", "head", { pitch = 1.15, volume = 0.5, stages = BIG, delay = 0.15 }),
	},
	treatFlare = {
		weight("DragonFlare", "mouth"),
		voice("DragonScreech", "head", { volume = 0.5, stages = SMALL }),
		voice("DragonRoarGrowl", "head", { pitch = 1.1, volume = 0.5, stages = BIG }),
	},
	cheer = {
		voice("DragonChirp", "head", { stages = BABY }),
		voice("DragonScreech", "head", { pitch = 1.1, volume = 0.6, stages = { 2 } }),
		voice("DragonPurrDeep", "head", { volume = 0.8, stages = BIG }),
		voice("DragonGrowl", "head", { pitch = 1.1, volume = 0.6, stages = BIG, delay = 0.3 }),
	},
	fireRing = {
		weight("DragonFireRing", "body"),
		weight("DragonFireLick", "body", { volume = 0.6, stages = GROWN, delay = 0.2 }),
	},
	feast = { layer("DragonTreat", "body", nil, { pitch = 0.85 }) },
}

return table.freeze(RECIPES)
