--!strict
--[[
	OrcaAnciana (etapa 4)

	Un leviatán antiguo, enorme y pesado: se mueve despacio, con aletazos
	lentos y largos ratos planeando; tarda en salir a respirar y cuando lo
	hace echa un chorro gigante. No salta: ruge con la boca abierta y hace
	temblar todo, emerge del fondo como una isla con el agua cayéndole del
	lomo, se zambulle lento mostrando la cola y da un coletazo que levanta
	olas. Al comer abre la boca muy grande y traga despacio. Voz grave.
]]

local Perfil = require(script.Parent.Perfil)
local Jumps = require(script.Parent.Parent.OrcaMotion.Tricks.Jumps)
local Show = require(script.Parent.Parent.OrcaMotion.Tricks.Show)
local Surface = require(script.Parent.Parent.OrcaMotion.Tricks.Surface)

local profile: Perfil.Profile = {
	name = "OrcaAnciana",
	voice = 0.7,
	swim = {
		speed = 0.6,
		beat = 0.6,
		amplitude = 0.85,
		glide = 0.55,
		wiggle = 0,
		bank = 0.45,
		flap = 0.5,
	},
	breath = { seconds = 22, shallow = -0.04, deep = -0.1 },
	feed = { pitch = 0.45, rise = 0.12, jaw = 1.1, chew = 1, wiggle = 0 },
	trickEvery = 30,
	trickChance = 0.65,
	tricks = {
		{ weight = 3, trick = Show.roar(5) },
		{ weight = 2, trick = Show.emerge(0.2, 14) },
		{ weight = 2, trick = Jumps.dive(0.5, 14) },
		{ weight = 1, trick = Surface.tailSlap(1, 6) },
	},
}

return profile
