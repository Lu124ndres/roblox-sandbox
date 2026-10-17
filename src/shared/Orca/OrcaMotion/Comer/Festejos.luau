--!strict
--[[
	OrcaMotion/Comer/Festejos

	Las reacciones grandes de la orca al comer: reemplazan su pose (como un
	truco) y el motor las mezcla al entrar y al salir. Son los trucos de
	siempre (Tricks) con los momentos de la comida encima (sonidos y efectos
	de OrcaFx/Comida):
		salto      pez raro: se hunde para tomar impulso, sale del agua con un
		           giro, cae y echa un chorro de alegría
		emerger    pez raro de la anciana (no salta): sube del fondo como una
		           isla, brilla y echa un chorro enorme
		canto      combo: se para en el agua con la cabeza fuera y canta
		coletazo   combo: azota la cola y la ola moja la orilla de quien la alimenta
		tirabuzon  combo grande: salto completo con varias vueltas y canto
		rugido     combo de la anciana: levanta la cabeza y canta grave
		isla       combo grande de la anciana: emerge cantando y la ola llega
		           a la orilla
	La anticipación (hundirse antes de saltar o de emerger) ya está en cada
	truco; las vueltas completas terminan derechas.
]]

local Tricks = require(script.Parent.Parent.Tricks)
local Jumps = require(script.Parent.Parent.Tricks.Jumps)
local Show = require(script.Parent.Parent.Tricks.Show)
local Surface = require(script.Parent.Parent.Tricks.Surface)

local PARTY_AT = { 5, 15, 30, 50, 75, 100, 150, 200 }
local PARTY_EVERY = 100 -- después del último

local Festejos = {}

-- Le toca festejar con esta racha de peces seguidos: 5, 15, 30, 50, 75, 100,
-- 150, 200 y después cada 100 (Turnos elige cuál: cada vez más grande).
function Festejos.due(streak: number): boolean
	local last = PARTY_AT[#PARTY_AT]
	return table.find(PARTY_AT, streak) ~= nil
		or (streak > last and (streak - last) % PARTY_EVERY == 0)
end

-- El mismo truco con otro nombre y otros momentos (los `drop` se quitan).
local function with(
	trick: Tricks.Trick,
	name: string,
	extra: { Tricks.Event },
	drop: string?
): Tricks.Trick
	local events: { Tricks.Event } = {}
	for _, event in trick.events do
		if event.kind ~= drop then
			table.insert(events, event)
		end
	end
	for _, event in extra do
		table.insert(events, event)
	end
	table.sort(events, function(a: Tricks.Event, b: Tricks.Event)
		return a.at < b.at
	end)
	return { name = name, seconds = trick.seconds, pose = trick.pose, events = events }
end

-- Salto con `twist` vueltas (sale del agua cerca de u = 0.24 y cae cerca de 0.8).
function Festejos.salto(apex: number, twist: number, seconds: number): Tricks.Trick
	return with(Jumps.breach(apex, twist, seconds), "saltoFeliz", {
		{ at = 0.06, kind = "clicks" },
		{ at = 0.25, kind = "rareLaunch" },
		{ at = 0.94, kind = "happySpout" },
	}, "call")
end

function Festejos.emerger(height: number, seconds: number): Tricks.Trick
	return with(Show.emerge(height, seconds), "emergerFeliz", {
		{ at = 0.4, kind = "clicks" },
		{ at = 0.55, kind = "rareLaunch" },
	})
end

function Festejos.canto(height: number, looks: number, seconds: number): Tricks.Trick
	return with(Show.spyhop(height, looks, seconds), "canto", {
		{ at = 0.26, kind = "song" },
		{ at = 0.6, kind = "clicks" },
		{ at = 0.92, kind = "happySpout" },
	}, "call")
end

function Festejos.coletazo(count: number, seconds: number): Tricks.Trick
	local slaps: { Tricks.Event } = { { at = 0.05, kind = "clicks" } }
	local base = Surface.tailSlap(count, seconds)
	for _, event in base.events do -- cada azote levanta una ola hacia la orilla
		table.insert(slaps, { at = event.at, kind = "shoreSlap", where = "tail" })
	end
	return with(base, "coletazoOrilla", slaps, "slap")
end

function Festejos.tirabuzon(apex: number, twist: number, seconds: number): Tricks.Trick
	return with(Jumps.breach(apex, twist, seconds), "tirabuzon", {
		{ at = 0.04, kind = "song" },
		{ at = 0.25, kind = "rareLaunch" },
		{ at = 0.81, kind = "partySplash" },
		{ at = 0.84, kind = "shoreSlap" },
		{ at = 0.95, kind = "happySpout" },
	}, "call")
end

function Festejos.rugido(seconds: number): Tricks.Trick
	return with(Show.roar(seconds), "rugidoFeliz", {
		{ at = 0.3, kind = "song" },
		{ at = 0.55, kind = "clicks" },
	}, "roar")
end

-- Combo grande de la anciana: emerge como una isla cantando y la ola llega a la orilla.
function Festejos.isla(height: number, seconds: number): Tricks.Trick
	return with(Show.emerge(height, seconds), "islaFeliz", {
		{ at = 0.33, kind = "song" },
		{ at = 0.55, kind = "rareLaunch" },
		{ at = 0.85, kind = "shoreSlap" },
	})
end

return table.freeze(Festejos)
