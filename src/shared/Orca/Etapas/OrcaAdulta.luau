--!strict
--[[
	OrcaAdulta (etapa 3)

	La reina del cráter: poderosa y tranquila. Da aletazos fuertes y luego
	planea un buen rato; respira con calma. Sus trucos son de exhibición: un
	salto alto y lento con giro completo, aletazos acostada de costado,
	asomarse para vigilar a los jugadores y zambullidas hondas sacando la
	cola. Al comer levanta bien la cabeza y abre la boca grande.
]]

local Perfil = require(script.Parent.Perfil)
local Jumps = require(script.Parent.Parent.OrcaMotion.Tricks.Jumps)
local Show = require(script.Parent.Parent.OrcaMotion.Tricks.Show)
local Surface = require(script.Parent.Parent.OrcaMotion.Tricks.Surface)

local profile: Perfil.Profile = {
	name = "OrcaAdulta",
	voice = 1,
	swim = { speed = 1, beat = 1, amplitude = 1, glide = 0.4, wiggle = 0, bank = 0.7, flap = 0.8 },
	breath = { seconds = 16, shallow = -0.05, deep = -0.14 },
	feed = { pitch = 0.68, rise = 0.14, jaw = 1, chew = 1.8, wiggle = 0 },
	trickEvery = 24,
	trickChance = 0.7,
	tricks = {
		{ weight = 3, trick = Jumps.breach(1.05, 1, 4.2) },
		{ weight = 2, trick = Surface.finSlap(3, 5) },
		{ weight = 2, trick = Show.spyhop(0.3, 1, 5.5) },
		{ weight = 1, trick = Jumps.dive(1.1, 9) },
	},
}

return profile
