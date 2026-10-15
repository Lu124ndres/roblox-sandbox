--!strict
--[[
	OrcaBebe (etapa 1)

	Una cría curiosa y juguetona: aletea rápido con colazos cortos, se
	bambolea al nadar, sale seguido a respirar con chorritos y casi no se
	queda quieta. Sus trucos: saltitos seguidos como delfín, dar vueltas
	persiguiéndose la cola, girar sobre su eje, asomarse a mirar a los
	jugadores y, a veces, un salto chiquito. Al comer se mueve de contenta y
	da mordisquitos rápidos. Su voz es aguda.
]]

local Perfil = require(script.Parent.Perfil)
local Jumps = require(script.Parent.Parent.OrcaMotion.Tricks.Jumps)
local Show = require(script.Parent.Parent.OrcaMotion.Tricks.Show)
local Surface = require(script.Parent.Parent.OrcaMotion.Tricks.Surface)

local profile: Perfil.Profile = {
	name = "OrcaBebe",
	voice = 1.45,
	swim = {
		speed = 1.05,
		beat = 1.7,
		amplitude = 1.25,
		glide = 0.15,
		wiggle = 0.1,
		bank = 0.6,
		flap = 1.3,
	},
	breath = { seconds = 10, shallow = -0.04, deep = -0.18 },
	feed = { pitch = 0.5, rise = 0.12, jaw = 0.85, chew = 3.2, wiggle = 0.16 },
	trickEvery = 15,
	trickChance = 0.85,
	tricks = {
		{ weight = 3, trick = Jumps.hops(0.45, 3, 4.2) },
		{ weight = 2, trick = Surface.spin(2, 4) },
		{ weight = 2, trick = Surface.roll(1, 2.6) },
		{ weight = 2, trick = Show.spyhop(0.35, 2, 5) },
		{ weight = 1, trick = Jumps.breach(0.75, 0.5, 3) },
	},
}

return profile
