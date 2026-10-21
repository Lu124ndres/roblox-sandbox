--!strict
--[[
	OrcaAdulta (etapa 3)

	La reina del cráter: poderosa, segura y tranquila. Da aletazos fuertes y
	luego planea un buen rato; respira con calma. Sus trucos son de
	exhibición y limpios: el salto completo que cae de costado y se hunde,
	asomarse para vigilar a los jugadores, zambullidas hondas con la cola
	afuera, aletazos acostada de costado y coletazos. Al comer levanta bien la
	cabeza y abre la boca grande.
	Con los peces agradece con calma: saluda con la aleta, echa chorros y se gira
	mostrando la panza; con un pez raro da un salto alto y cae de costado, y
	en los combos canta, salpica la orilla y hace un tirabuzón lento.
]]

local Perfil = require(script.Parent.Perfil)
local Festejos = require(script.Parent.Parent.OrcaMotion.Comer.Festejos)
local Jumps = require(script.Parent.Parent.OrcaMotion.Tricks.Jumps)
local Show = require(script.Parent.Parent.OrcaMotion.Tricks.Show)
local Surface = require(script.Parent.Parent.OrcaMotion.Tricks.Surface)
local Tricks = require(script.Parent.Parent.OrcaMotion.Tricks)

local TALLA = Tricks.talla(82.5, 64 / 31, 20.4) -- 82.5 studs de alto, 64 x 31 módulos, ~20 studs/s

local profile: Perfil.Profile = {
	name = "OrcaAdulta",
	voice = 1,
	swim = { speed = 1, beat = 1, amplitude = 1, glide = 0.4, wiggle = 0, bank = 0.7, flap = 0.8 },
	breath = { seconds = 16, shallow = -0.05, deep = -0.14 },
	feed = { pitch = 0.68, rise = 0.14, jaw = 1, chew = 1.8, wiggle = 0 },
	talla = TALLA,
	trickEvery = 32,
	trickChance = 0.7,
	rest = 3,
	tricks = {
		{ weight = 3, trick = Jumps.breach(1.1, 0.25, 18, { talla = TALLA, sink = 1 }) },
		{ weight = 2, trick = Show.spyhop(0.55, 1, 10, { talla = TALLA }) },
		{ weight = 2, trick = Jumps.dive(1.3, 24, { talla = TALLA }) },
		{ weight = 1, trick = Surface.finSlap(3, 7, { talla = TALLA }) },
		{ weight = 1, trick = Surface.tailSlap(3, 7, { talla = TALLA }) },
	},
	sounding = Jumps.dive(1.3, 26, { talla = TALLA }),
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
