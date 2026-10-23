--!strict
--[[
	MinoVocesTrucos

	Voces de los trucos del minotauro que no sonaban, y su evolución con voz
	propia. Son recetas de MinoVoces (MinoStand las suma con MinoVoces.add):
		happy    baile: el becerro bala contento; el adulto resopla y gruñe de
		         gusto, y la forma final remata con un bramido corto
		scratch  se rasca la cabeza: frote de pelo y un gruñido de alivio
		tap      golpetea el suelo con el pie mientras se rasca (como un perro)
		evolve   al crecer: balido de becerro, bramido del adulto y, en la
		         forma final, un retumbo grave debajo
]]

local MinoVoces = require(script.Parent.MinoVoces)

type Layer = MinoVoces.Layer

local SMALL, BIG = { 1, 2 }, { 3, 4 }

local recipes: { [string]: { Layer } } = {
	happy = {
		{ key = "MinoCalf", at = "head", tone = "voice", pitch = 1.15, stages = SMALL },
		{ key = "MinoHappy", at = "head", tone = "voice", stages = BIG },
		{
			key = "MinoBellow",
			at = "head",
			tone = "voice",
			volume = 0.6,
			stages = { 4 },
			delay = 0.5,
		},
	},
	scratch = {
		{ key = "MinoScratch", at = "head", tone = "weight", pitch = 1.2 },
		{ key = "MinoYum", at = "head", tone = "voice", volume = 0.6, delay = 0.9 },
	},
	tap = {
		{ key = "MinoStepSand", at = "ground", tone = "weight", volume = 0.6, floor = "sand" },
		{ key = "Plop", at = "ground", pitch = 0.6, volume = 0.6, floor = "water" },
	},
	evolve = {
		{ key = "MinoCalf", at = "head", tone = "voice", stages = SMALL },
		{ key = "MinoSnort", at = "head", tone = "voice", pitch = 0.9, delay = 0.2 },
		{ key = "MinoBellowDeep", at = "head", tone = "voice", pitch = 1.1, stages = BIG },
		{ key = "MinoRumble", at = "head", pitch = 0.85, volume = 0.8, stages = { 4 } },
		{
			key = "MinoBoom",
			at = "ground",
			tone = "weight",
			volume = 0.6,
			stages = BIG,
			delay = 0.3,
		},
	},
}

return recipes
