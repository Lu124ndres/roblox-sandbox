--!strict
--[[
	MinoVoces

	Qué suena en cada evento del minotauro según su etapa y el suelo que pisa.
	Cada evento es una lista de capas (claves de Assets.Sounds, sección
	Minotauro); una capa puede sonar solo en algunas etapas, solo sobre arena o
	solo sobre agua, en la cabeza o en el suelo, y con un retraso.

	Por etapa:
		voz     el becerro bala (MinoCalf, un bramido corto y agudo); el joven
		        brama con el tono alto; el adulto suma un gruñido de león y la
		        forma final un rugido grave y largo debajo del bramido.
		golpes  pisadas, pisotón, caída y sentarse bajan de tono y suben de
		        volumen al crecer (WEIGHT y LOUD); desde el joven las pisadas
		        suman un golpe sordo y desde el adulto el pisotón retumba (MinoBoom).
	Sobre agua los golpes suenan como siempre (Plop y BigSplash); los de arena
	son solo del desierto. El tono de la voz es profile.voice de
	Minotauro/Etapas. Un evento sin receta no suena (no rompe nada).

	Volumen y alcance de cada clave: Sounds.define al cargar (no están en
	UIConfig.Sounds porque solo los usa el minotauro).
]]

local Sounds = require(script.Parent.Sounds)

export type Layer = {
	key: string,
	at: "head" | "ground",
	tone: ("voice" | "weight")?, -- el tono sigue a la voz o al peso de la etapa
	pitch: number?,
	volume: number?,
	stages: { number }?, -- etapas en que suena (todas si falta)
	floor: ("sand" | "water")?, -- solo sobre ese suelo
	delay: number?,
}

export type Info = {
	stage: number,
	voice: number,
	head: Vector3,
	ground: Vector3,
	sand: boolean,
}

local WEIGHT = { 1.25, 1.05, 0.85, 0.68 } -- tono de los golpes por etapa
local LOUD = { 0.55, 0.7, 0.85, 1 } -- volumen de los golpes por etapa
local SMALL, BIG = { 1, 2 }, { 3, 4 }

Sounds.define({
	MinoBellow = { volume = 1, rollOff = 600 },
	MinoBellowDeep = { volume = 1.1, rollOff = 700 },
	MinoGrowl = { volume = 0.8, rollOff = 500 },
	MinoRumble = { volume = 1, rollOff = 700 },
	MinoSnort = { volume = 0.8, rollOff = 260 },
	MinoBreath = { volume = 0.7, rollOff = 220 },
	MinoGrunt = { volume = 0.7, rollOff = 280 },
	MinoYawn = { volume = 0.9, rollOff = 400 },
	MinoSniff = { volume = 0.7, rollOff = 180 },
	MinoStepSand = { volume = 0.8, rollOff = 240 },
	MinoStepHeavy = { volume = 0.9, rollOff = 340 },
	MinoSandHit = { volume = 1, rollOff = 380 },
	MinoBoom = { volume = 1, rollOff = 600 },
	MinoSit = { volume = 1, rollOff = 300 },
	MinoCalf = { volume = 0.9, rollOff = 400 },
	MinoHungry = { volume = 0.9, rollOff = 600 },
	MinoHappy = { volume = 0.8, rollOff = 320 },
	MinoScratch = { volume = 0.6, rollOff = 200 },
})

local RECIPES: { [string]: { Layer } } = {
	roar = {
		{ key = "MinoCalf", at = "head", tone = "voice", stages = { 1 } },
		{ key = "MinoBellow", at = "head", tone = "voice", stages = { 2 } },
		{ key = "MinoBellowDeep", at = "head", tone = "voice", pitch = 1.1, stages = BIG },
		{ key = "MinoGrowl", at = "head", tone = "voice", volume = 0.7, stages = { 3 } },
		{ key = "MinoRumble", at = "head", pitch = 0.9, volume = 0.8, stages = { 4 } },
	},
	snort = {
		{ key = "MinoSnort", at = "head", tone = "voice" },
		{
			key = "MinoBreath",
			at = "head",
			tone = "voice",
			volume = 0.6,
			stages = BIG,
			delay = 0.1,
		},
	},
	grunt = { -- en reposo, cada tanto (MinoStand)
		{ key = "MinoBreath", at = "head", tone = "voice", volume = 0.5, stages = SMALL },
		{ key = "MinoCalf", at = "head", tone = "voice", volume = 0.4, stages = { 1 } },
		{ key = "MinoGrunt", at = "head", tone = "voice", volume = 0.6, stages = BIG },
	},
	yawn = { { key = "MinoYawn", at = "head", tone = "voice", pitch = 1.15, volume = 0.8 } },
	sniff = { { key = "MinoSniff", at = "head", tone = "voice", pitch = 0.8, volume = 0.7 } },
	flex = { { key = "MinoBreath", at = "head", tone = "voice", volume = 0.6 } },
	evolve = { { key = "MinoSnort", at = "head", tone = "voice", pitch = 0.9 } },
	step = {
		{ key = "MinoStepSand", at = "ground", tone = "weight", volume = 0.8, floor = "sand" },
		{
			key = "MinoStepHeavy",
			at = "ground",
			tone = "weight",
			volume = 0.7,
			stages = { 2, 3, 4 },
			floor = "sand",
		},
		{ key = "Plop", at = "ground", pitch = 0.45, floor = "water" },
	},
	stomp = {
		{ key = "MinoSandHit", at = "ground", tone = "weight", floor = "sand" },
		{ key = "MinoStepHeavy", at = "ground", tone = "weight", floor = "sand" },
		{
			key = "MinoBoom",
			at = "ground",
			tone = "weight",
			volume = 0.8,
			stages = BIG,
			floor = "sand",
		},
		{ key = "BigSplash", at = "ground", pitch = 1.15, floor = "water" },
	},
	land = {
		{ key = "MinoSandHit", at = "ground", tone = "weight", floor = "sand" },
		{ key = "MinoStepHeavy", at = "ground", tone = "weight", floor = "sand" },
		{ key = "MinoBoom", at = "ground", tone = "weight", stages = { 2, 3, 4 }, floor = "sand" },
		{ key = "BigSplash", at = "ground", floor = "water" },
	},
	sit = {
		{ key = "MinoSit", at = "ground", tone = "weight", floor = "sand" },
		{ key = "MinoSandHit", at = "ground", tone = "weight", volume = 0.5, floor = "sand" },
		{ key = "BigSplash", at = "ground", pitch = 1.3, volume = 0.6, floor = "water" },
		{ key = "MinoBreath", at = "head", tone = "voice", volume = 0.5, delay = 0.2 },
	},
	standup = {
		{ key = "MinoBreath", at = "head", tone = "voice", volume = 0.7 },
		{ key = "MinoStepSand", at = "ground", tone = "weight", volume = 0.5, floor = "sand" },
	},
}

local MinoVoces = {}

local function plays(layer: Layer, info: Info): boolean
	if layer.floor and (layer.floor == "sand") ~= info.sand then
		return false
	end
	return layer.stages == nil or table.find(layer.stages, info.stage) ~= nil
end

local function playLayer(layer: Layer, info: Info)
	local stage = math.clamp(info.stage, 1, #WEIGHT)
	local pitch, volume = layer.pitch or 1, layer.volume or 1
	if layer.tone == "voice" then
		pitch *= info.voice
	elseif layer.tone == "weight" then
		pitch *= WEIGHT[stage]
		volume *= LOUD[stage]
	end
	local position = if layer.at == "head" then info.head else info.ground
	Sounds.play(layer.key, position, pitch, volume)
end

-- Suma recetas de otro módulo (las de sus reacciones al comer: Audio/MinoVocesComer).
function MinoVoces.add(recipes: { [string]: { Layer } })
	for kind, recipe in recipes do
		RECIPES[kind] = recipe
	end
end

-- Suena el evento kind (las capas que tocan a esta etapa y a este suelo).
function MinoVoces.play(kind: string, info: Info)
	local recipe = RECIPES[kind]
	if not recipe then
		return
	end
	for _, layer in recipe do
		if plays(layer, info) then
			if layer.delay then
				task.delay(layer.delay, playLayer, layer, info)
			else
				playLayer(layer, info)
			end
		end
	end
end

return table.freeze(MinoVoces)
