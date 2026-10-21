--!strict
--[[
	OrcaMotion/Comer/Festejos

	Las reacciones grandes de la orca al comer: reemplazan su pose (como un
	truco) y el motor las mezcla al entrar y al salir. Son los trucos de
	siempre (Tricks) con los momentos de la comida encima (sonidos y efectos
	de OrcaFx/Comida):
		salto      pez raro: se agacha de la sorpresa, da un salto chico al
		           lado, cae de costado y vuelve a asomarse con un chorro
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

local smooth, span, bell = Tricks.smooth, Tricks.span, Tricks.bell

local PARTY_AT = { 5, 15, 30, 50, 75, 100, 150, 200 }
local PARTY_EVERY = 100 -- después del último
local HOP_SCALE = 0.45 -- el salto por un pez raro llega a esta parte del salto completo
local HOP_FROM, HOP_TO = 0.28, 0.62 -- tramo del salto en el aire
local HOP_BASE = -0.1 -- altura del centro al salir y al caer

local Festejos = {}

-- Las reacciones pensadas desde la orca asomada (las demás arrancan nadando).
local UPRIGHT: { [Tricks.Trick]: boolean } = setmetatable({}, { __mode = "k" }) :: any

-- La reacción arranca y termina asomada (Grande no le suma el cabeceo de la postura).
function Festejos.upright(trick: Tricks.Trick): boolean
	return UPRIGHT[trick] == true
end

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

-- Pez raro: salto chico al lado. Se agacha de la sorpresa, salta de costado
-- (`twist` de vuelta, a lo sumo media: cae de costado), salpica al caer y
-- vuelve a asomarse para pedir más. `apex` es la del salto completo de la
-- etapa: este llega a HOP_SCALE de esa altura.
function Festejos.salto(apex: number, twist: number, seconds: number): Tricks.Trick
	local top = apex * HOP_SCALE
	local tilt = math.min(twist, 0.5) * math.pi
	local trick: Tricks.Trick = {
		name = "saltoFeliz",
		seconds = seconds,
		events = {
			{ at = 0.06, kind = "clicks" },
			{ at = HOP_FROM, kind = "rareLaunch" },
			{ at = HOP_TO + 0.02, kind = "splash" },
			{ at = 0.93, kind = "happySpout" },
		},
		pose = function(u: number, from: number): Tricks.Pose
			local hop = span(u, HOP_FROM, HOP_TO)
			if hop > 0 and hop < 1 then -- en el aire: parábola exacta
				return {
					depth = HOP_BASE + (top - HOP_BASE) * 4 * hop * (1 - hop),
					pitch = 0.95 - 1.1 * hop,
					roll = tilt * smooth(hop),
					yaw = 0.45 * bell(hop * 0.5),
					jaw = 0.6,
					fins = -0.45,
					effort = 0.3,
					air = true,
				}
			end
			if u <= HOP_FROM then -- se agacha y toma impulso
				local crouch = smooth(span(u, 0, 0.18))
				local push = smooth(span(u, 0.18, HOP_FROM))
				local depth = from - 0.12 * crouch
				return {
					depth = depth + (HOP_BASE - depth) * push,
					pitch = 1.1 - 0.15 * push,
					jaw = 0.7 * crouch,
					fins = -0.4 * crouch,
					effort = 0.6 + 1.2 * push,
				}
			end
			-- Cae de costado, se endereza bajo el agua y vuelve a asomarse.
			local splash = bell(span(u, HOP_TO, 0.8))
			local back = smooth(span(u, HOP_TO, 1))
			return {
				depth = HOP_BASE + (from - HOP_BASE) * back - 0.15 * splash,
				pitch = -0.15 + 1.25 * back,
				roll = tilt * (1 - back),
				yaw = 0.45 * (1 - back),
				jaw = 0.3 * (1 - back),
				fins = -0.3,
				effort = 0.9,
			}
		end,
	}
	UPRIGHT[trick] = true
	return trick
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
