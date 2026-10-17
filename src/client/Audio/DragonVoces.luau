--!strict
--[[
	DragonVoces

	Qué suena en cada momento del dragón según su etapa. Como MinoVoces: cada
	evento es una lista de capas (DragonRecetas y, al comer, DragonRecetasComer:
	claves de Assets.Sounds, secciones Dragón y Comer: Dragón) que pueden sonar
	solo en algunas etapas, en la cabeza, la boca, el cuerpo o el suelo, y con
	un retraso.

	Por etapa:
		voz    la cría chilla agudo y juguetón (pterodáctilo con el tono alto) y
		       pía cuando se posa o se acicala; el joven chilla más grave con un
		       gruñido debajo; el adulto ruge (monstruo) con un gruñido de león y
		       el anciano suma un trueno grave debajo del rugido.
		peso   aletazos, despegue, golpe en la roca y fuego bajan de tono y suben
		       de volumen al crecer (WEIGHT y LOUD): la cría aletea liviano, el
		       anciano mueve el aire con golpes de cuero enormes.
	El tono de la voz es state.voice (Dragon/Etapas). La fuerza de un aletazo
	(info.strength) multiplica su volumen. Un evento sin receta no suena.

	Volumen y alcance de cada clave: Sounds.define al cargar (solo las usa el
	dragón, como las del minotauro en MinoVoces).
]]

local DragonRecetas = require(script.Parent.DragonRecetas)
local DragonRecetasComer = require(script.Parent.DragonRecetasComer)
local Sounds = require(script.Parent.Sounds)

export type Info = {
	stage: number,
	voice: number,
	strength: number?, -- 0..1: fuerza del aletazo
	head: Vector3,
	mouth: Vector3,
	body: Vector3,
	ground: Vector3,
}

local WEIGHT = { 1.35, 1.1, 0.88, 0.7 } -- tono de los sonidos de peso por etapa
local LOUD = { 0.6, 0.75, 0.9, 1 } -- y su volumen

Sounds.define({
	DragonScreech = { volume = 0.9, rollOff = 600 },
	DragonChirp = { volume = 0.7, rollOff = 260 },
	DragonRoar = { volume = 1.1, rollOff = 800 },
	DragonRoarGrowl = { volume = 0.9, rollOff = 600 },
	DragonRumble = { volume = 1, rollOff = 800 },
	DragonGrowl = { volume = 0.8, rollOff = 400 },
	DragonHiss = { volume = 0.6, rollOff = 300 },
	DragonSnort = { volume = 0.6, rollOff = 260 },
	DragonSnore = { volume = 0.5, rollOff = 240 },
	DragonYawn = { volume = 0.8, rollOff = 400 },
	DragonFlapSmall = { volume = 0.6, rollOff = 220 },
	DragonFlap = { volume = 0.8, rollOff = 320 },
	DragonFlapHeavy = { volume = 1, rollOff = 450 },
	DragonFlapBurst = { volume = 1, rollOff = 500 },
	DragonGust = { volume = 0.8, rollOff = 400 },
	DragonFold = { volume = 0.6, rollOff = 220 },
	DragonFireStart = { volume = 1, rollOff = 600 },
	DragonFireLick = { volume = 0.9, rollOff = 400 },
	DragonFireLoop = { volume = 0.7, rollOff = 500 },
	DragonFireWave = { volume = 1, rollOff = 700 },
	DragonLand = { volume = 1, rollOff = 450 },
	DragonDebris = { volume = 0.7, rollOff = 350 },
	DragonBoom = { volume = 1, rollOff = 700 },
	DragonRocks = { volume = 0.6, rollOff = 260 },
	-- Al comer (DragonRecetasComer)
	DragonSnap = { volume = 0.7, rollOff = 260 },
	DragonGulp = { volume = 0.6, rollOff = 220 },
	DragonPurr = { volume = 0.6, rollOff = 220 },
	DragonPurrDeep = { volume = 0.7, rollOff = 300 },
	DragonTreat = { volume = 0.6, rollOff = 400 },
	DragonFlare = { volume = 0.9, rollOff = 500 },
	DragonFireRing = { volume = 1, rollOff = 600 },
})

local DragonVoces = {}

local function playLayer(layer: DragonRecetas.Layer, info: Info)
	local stage = math.clamp(info.stage, 1, #WEIGHT)
	local pitch, volume = layer.pitch or 1, (layer.volume or 1) * (info.strength or 1)
	if layer.tone == "voice" then
		pitch *= info.voice
	elseif layer.tone == "weight" then
		pitch *= WEIGHT[stage]
		volume *= LOUD[stage]
	end
	local position = if layer.at == "head"
		then info.head
		elseif layer.at == "mouth" then info.mouth
		elseif layer.at == "body" then info.body
		else info.ground
	Sounds.play(layer.key, position, pitch, volume)
end

-- Suena el evento kind (las capas de esta etapa). Sin receta: nada.
function DragonVoces.play(kind: string, info: Info)
	local recipe = DragonRecetas[kind] or DragonRecetasComer[kind]
	if not recipe then
		return
	end
	for _, layer in recipe do
		if layer.stages == nil or table.find(layer.stages, info.stage) ~= nil then
			if layer.delay then
				task.delay(layer.delay, playLayer, layer, info)
			else
				playLayer(layer, info)
			end
		end
	end
end

-- Tono y volumen de peso de una etapa (para los bucles de DragonLoops).
function DragonVoces.weight(stage: number): (number, number)
	local s = math.clamp(stage, 1, #WEIGHT)
	return WEIGHT[s], LOUD[s]
end

return table.freeze(DragonVoces)
