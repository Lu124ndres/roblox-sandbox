--!strict
--[[
	MinoVocesComer

	Lo que suena en las reacciones del minotauro al comer (Minotauro/Comer). Son
	recetas de MinoVoces (MinoStand las suma con MinoVoces.add): la voz sigue el
	tono de la etapa y los golpes su peso, como el resto de sus sonidos.
		gulp       traga (grave)                 clap   aplaude al atrapar el pez
		pat, drum  se palmea / toca el tambor    yum    gruñido de gusto
		burp       eructo chico                  wink   un "hm" cortito al guiñar
		glow       le brillan los ojos (campanitas; más agudas cuanto más raro)
		joy        salto de alegría (gruñido agudo y campanitas)
		hop        cae del saltito (polvo o agua)
		cheer      ruge de gusto en un festejo o con un pez legendario
		goldburst  revienta en oro (campanitas graves)
	Volumen y alcance: Sounds.define al cargar.
]]

local MinoVoces = require(script.Parent.MinoVoces)
local Sounds = require(script.Parent.Sounds)

type Layer = MinoVoces.Layer

local SMALL, BIG = { 1, 2 }, { 3, 4 }

Sounds.define({
	MinoGulp = { volume = 0.8, rollOff = 220 },
	MinoBurp = { volume = 0.8, rollOff = 260 },
	MinoYum = { volume = 0.7, rollOff = 260 },
	MinoPat = { volume = 0.7, rollOff = 240 },
	MinoDrum = { volume = 0.8, rollOff = 300 },
	MinoClap = { volume = 0.7, rollOff = 240 },
	MinoShine = { volume = 0.6, rollOff = 400 },
})

local recipes: { [string]: { Layer } } = {
	gulp = { { key = "MinoGulp", at = "head", tone = "voice", pitch = 0.7 } },
	clap = { { key = "MinoClap", at = "head", tone = "weight", volume = 0.9 } },
	pat = { { key = "MinoPat", at = "head", tone = "weight", pitch = 1.1, volume = 0.8 } },
	drum = {
		{ key = "MinoDrum", at = "head", tone = "weight" },
		{ key = "MinoPat", at = "head", tone = "weight", pitch = 0.8, volume = 0.5 },
	},
	yum = { { key = "MinoYum", at = "head", tone = "voice", pitch = 1.1 } },
	burp = { { key = "MinoBurp", at = "head", tone = "voice", pitch = 0.8, volume = 0.9 } },
	wink = { { key = "MinoYum", at = "head", tone = "voice", pitch = 1.35, volume = 0.45 } },
	glow3 = { { key = "MinoShine", at = "head", pitch = 1.3, volume = 0.6 } },
	glow4 = { { key = "MinoShine", at = "head", pitch = 1.2, volume = 0.75 } },
	glow5 = { { key = "MinoShine", at = "head", pitch = 1.05, volume = 0.9 } },
	glow6 = { { key = "MinoShine", at = "head", pitch = 1.05, volume = 0.9 } },
	joy = {
		{ key = "MinoYum", at = "head", tone = "voice", pitch = 1.25 },
		{ key = "MinoShine", at = "head", pitch = 1.4, volume = 0.4, delay = 0.1 },
	},
	hop = {
		{ key = "MinoStepSand", at = "ground", tone = "weight", floor = "sand" },
		{ key = "Plop", at = "ground", pitch = 0.5, floor = "water" },
	},
	cheer = {
		{ key = "MinoBellow", at = "head", tone = "voice", pitch = 1.15, stages = SMALL },
		{ key = "MinoBellowDeep", at = "head", tone = "voice", pitch = 1.2, stages = BIG },
		{ key = "MinoShine", at = "head", pitch = 1.1, volume = 0.5, delay = 0.15 },
	},
	goldburst = { { key = "MinoShine", at = "head", pitch = 0.85, volume = 0.9 } },
}

return recipes
