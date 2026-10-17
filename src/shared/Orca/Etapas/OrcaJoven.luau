--!strict
--[[
	OrcaJoven (etapa 2)

	Una orca joven, ágil y presumida: nada rápido, se inclina mucho en las
	curvas y aletea con fuerza. Le encanta llamar la atención: saltos con una
	vuelta completa, coletazos que salpican a todos, carreras de saltitos y
	giros sobre su eje. Al comer muerde con ganas. Voz algo aguda.
	Con los peces presume: coletazos, giros de costado y chorros; con un pez raro
	salta con una vuelta y en los combos canta, azota la cola contra la
	orilla y hace un tirabuzón de dos vueltas.
]]

local Perfil = require(script.Parent.Perfil)
local Festejos = require(script.Parent.Parent.OrcaMotion.Comer.Festejos)
local Jumps = require(script.Parent.Parent.OrcaMotion.Tricks.Jumps)
local Surface = require(script.Parent.Parent.OrcaMotion.Tricks.Surface)

local profile: Perfil.Profile = {
	name = "OrcaJoven",
	voice = 1.15,
	swim = {
		speed = 1.15,
		beat = 1.3,
		amplitude = 1.1,
		glide = 0.25,
		wiggle = 0.04,
		bank = 0.8,
		flap = 1,
	},
	breath = { seconds = 13, shallow = -0.05, deep = -0.13 },
	feed = { pitch = 0.62, rise = 0.14, jaw = 0.95, chew = 2.4, wiggle = 0.06 },
	trickEvery = 18,
	trickChance = 0.75,
	tricks = {
		{ weight = 3, trick = Jumps.breach(1, 1, 3.6) },
		{ weight = 2, trick = Surface.tailSlap(3, 5) },
		{ weight = 1, trick = Jumps.hops(0.6, 2, 3.4) },
		{ weight = 1, trick = Surface.roll(1, 2.4) },
	},
	meal = {
		tempo = 0.9,
		snap = 1.1,
		roll = 1,
		hz = 2.6,
		damping = 0.5,
		gap = 0.7,
		gestures = {
			{ weight = 3, name = "coletazo" },
			{ weight = 2, name = "panza" },
			{ weight = 2, name = "chorro" },
			{ weight = 1, name = "saludo" },
		},
		rare = Festejos.salto(0.95, 1, 3.2),
		party = {
			Festejos.canto(0.3, 1, 3.8),
			Festejos.coletazo(3, 4.2),
			Festejos.tirabuzon(1.15, 2, 3.8),
		},
	},
}

return profile
