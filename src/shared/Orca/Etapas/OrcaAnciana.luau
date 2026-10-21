--!strict
--[[
	OrcaAnciana (etapa 4)

	Un leviatán antiguo, enorme, pesado y temible: se mueve despacio, con
	aletazos lentos y largos ratos planeando; tarda en salir a respirar y
	cuando lo hace echa un chorro gigante. Hace pocos trucos, pero enormes:
	un salto gigante que levanta una ola, largos descansos flotando con el
	lomo afuera, zambullidas hondas mostrando la cola, un asomarse lento que
	mira fijo a la rampa y un coletazo que retumba. No cabe parada en el lago:
	todo lo hace más acostada. Al comer abre la boca muy grande y traga
	despacio. Voz grave.
	Con los peces es lenta y majestuosa: traga despacio, echa chorros enormes y
	saluda sin apuro; no salta: con un pez raro emerge brillando y en los
	combos canta grave, azota la cola una vez y emerge como una isla.
]]

local Perfil = require(script.Parent.Perfil)
local Festejos = require(script.Parent.Parent.OrcaMotion.Comer.Festejos)
local Jumps = require(script.Parent.Parent.OrcaMotion.Tricks.Jumps)
local Show = require(script.Parent.Parent.OrcaMotion.Tricks.Show)
local Surface = require(script.Parent.Parent.OrcaMotion.Tricks.Surface)
local Tricks = require(script.Parent.Parent.OrcaMotion.Tricks)

local TALLA = Tricks.talla(165, 63 / 31, 19.6) -- 165 studs de alto, 63 x 31 módulos, ~20 studs/s

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
	talla = TALLA,
	trickEvery = 50,
	trickChance = 0.6,
	rest = 6,
	tricks = {
		{
			weight = 1,
			trick = Jumps.breach(
				0.7,
				0.25,
				24,
				{ talla = TALLA, sink = 0.55, size = 2.5, exit = 0.95, low = 0.5 }
			),
		},
		{ weight = 3, trick = Surface.logging(32, 4, { talla = TALLA }) },
		{ weight = 2, trick = Jumps.dive(0.6, 32, { talla = TALLA, steep = 0.5 }) },
		{
			weight = 2,
			trick = Show.spyhop(
				0.45,
				0,
				14,
				{ talla = TALLA, pitch = 0.7, stare = true, sub = 0.1 }
			),
		},
		{ weight = 1, trick = Surface.tailSlap(1, 9, { talla = TALLA, size = 2, pitch = -0.55 }) },
	},
	sounding = Jumps.dive(0.6, 36, { talla = TALLA, steep = 0.5 }),
	meal = {
		tempo = 1.5,
		snap = 0.7,
		roll = 0.5,
		hz = 1.3,
		damping = 0.9,
		gap = 1.4,
		gestures = {
			{ weight = 3, name = "chorro" },
			{ weight = 2, name = "saludo" },
			{ weight = 2, name = "tragar" },
			{ weight = 1, name = "panza" },
		},
		rare = Festejos.emerger(0.18, 7),
		party = { Festejos.rugido(5), Festejos.coletazo(1, 6), Festejos.isla(0.25, 10) },
	},
}

return profile
