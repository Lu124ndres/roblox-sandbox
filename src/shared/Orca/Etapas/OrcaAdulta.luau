--!strict
--[[
	OrcaAdulta (etapa 3)

	La reina del cráter: poderosa y tranquila. Da aletazos fuertes y luego
	planea un buen rato; respira con calma. Sus trucos son de exhibición: un
	salto alto y lento con giro completo, aletazos acostada de costado,
	asomarse para vigilar a los jugadores y zambullidas hondas sacando la
	cola. Al comer levanta bien la cabeza y abre la boca grande.
	Con los peces agradece con calma: saluda con la aleta, echa chorros y se gira
	mostrando la panza; con un pez raro da un salto alto y cae de costado, y
	en los combos canta, salpica la orilla y hace un tirabuzón lento.
]]

local Perfil = require(script.Parent.Perfil)
local Festejos = require(script.Parent.Parent.OrcaMotion.Comer.Festejos)
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
	meal = {
		tempo = 1,
		snap = 1,
		roll = 0.9,
		hz = 2.2,
		damping = 0.65,
		gap = 0.9,
		gestures = {
			{ weight = 3, name = "saludo" },
			{ weight = 2, name = "chorro" },
			{ weight = 2, name = "panza" },
			{ weight = 1, name = "coletazo" },
		},
		rare = Festejos.salto(1.05, 0.5, 3.8),
		party = {
			Festejos.canto(0.3, 1, 4.6),
			Festejos.coletazo(2, 4.6),
			Festejos.tirabuzon(1.2, 2, 4.4),
		},
	},
}

return profile
