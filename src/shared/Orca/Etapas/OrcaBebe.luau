--!strict
--[[
	OrcaBebe (etapa 1)

	Una cría curiosa y juguetona: aletea rápido con colazos cortos, se
	bambolea al nadar, sale seguido a respirar con chorritos y casi no se
	queda quieta. Sus trucos son muchos y chicos: saltitos seguidos (torpes,
	se bambolea y salpica), saltos chicos que caen de costado y, a veces, mal:
	de panza, con un panzazo; se asoma a mirar y da aletazos. Al comer se
	mueve de contenta y da mordisquitos rápidos. Su voz es aguda.
	Con cada pez da mordisquitos y rebota: se pone panza arriba, saluda,
	da coletazos chicos; con un pez raro salta con una vuelta y en los combos
	canta asomada, salpica la orilla y hace un tirabuzón.
]]

local Perfil = require(script.Parent.Perfil)
local Festejos = require(script.Parent.Parent.OrcaMotion.Comer.Festejos)
local Jumps = require(script.Parent.Parent.OrcaMotion.Tricks.Jumps)
local Show = require(script.Parent.Parent.OrcaMotion.Tricks.Show)
local Surface = require(script.Parent.Parent.OrcaMotion.Tricks.Surface)
local Tricks = require(script.Parent.Parent.OrcaMotion.Tricks)

local TALLA = Tricks.talla(16.5, 50 / 31, 11) -- 16.5 studs de alto, 50 x 31 módulos, ~11 studs/s

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
	breath = { seconds = 10, shallow = -0.04, deep = -0.12 },
	feed = { pitch = 0.5, rise = 0.12, jaw = 0.85, chew = 3.2, wiggle = 0.16 },
	talla = TALLA,
	trickEvery = 16,
	trickChance = 0.85,
	rest = 2,
	tricks = {
		{ weight = 3, trick = Jumps.hops(0.3, 3, 7.5, { talla = TALLA, clumsy = 0.4 }) },
		{ weight = 2, trick = Jumps.breach(0.55, 0.25, 10, { talla = TALLA, sink = 1.2 }) },
		{
			weight = 2,
			trick = Jumps.breach(
				0.4,
				0,
				10,
				{ talla = TALLA, flop = true, exit = 0.85, sink = 0.9 }
			),
		},
		{ weight = 1, trick = Show.spyhop(0.45, 2, 6, { talla = TALLA }) },
		{ weight = 1, trick = Surface.finSlap(3, 5, { talla = TALLA }) },
	},
	sounding = Jumps.dive(2, 12, { talla = TALLA }),
	meal = {
		tempo = 0.8,
		snap = 1.2,
		roll = 1.1,
		hz = 3,
		damping = 0.4,
		gap = 0.5,
		gestures = {
			{ weight = 3, name = "panza" },
			{ weight = 2, name = "coletazo" },
			{ weight = 2, name = "saludo" },
			{ weight = 2, name = "chorro" },
		},
		rare = Festejos.salto(0.7, 1, 2.8),
		party = {
			Festejos.canto(0.35, 2, 3.4),
			Festejos.coletazo(3, 3.6),
			Festejos.tirabuzon(0.9, 2, 3.2),
		},
	},
}

return profile
