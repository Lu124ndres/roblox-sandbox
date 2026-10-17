--!strict
--[[
	OrcaVoces

	Volumen y alcance de los sonidos de la orca al comer (Assets.Sounds, bloque
	"Comer: Orca"; los usa OrcaFx/Comida). No están en UIConfig.Sounds porque
	solo los usa la orca: se definen al cargar con Sounds.define. El canto y la
	ola de los festejos se oyen lejos; el chasquido y el trago, solo cerca.
]]

local Sounds = require(script.Parent.Sounds)

Sounds.define({
	OrcaSnap = { volume = 0.6, rollOff = 200 },
	OrcaGulp = { volume = 0.8, pitch = 0.8, rollOff = 200 },
	OrcaHappySpout = { volume = 0.5, rollOff = 260 },
	OrcaClicks = { volume = 0.7, rollOff = 240 },
	OrcaSong = { volume = 0.9, rollOff = 520 },
	OrcaTailSlap = { volume = 0.9, rollOff = 320 },
	OrcaPartySplash = { volume = 1, rollOff = 450 },
	OrcaShine = { volume = 0.7, pitch = 1.25, rollOff = 320 },
	OrcaGhostWhoosh = { volume = 0.8, rollOff = 340 },
})

return {}
