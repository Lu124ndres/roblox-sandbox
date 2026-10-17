--!strict
--[[
	Zorro/Comer

	La animación especial del zorro al comer (solo en el cliente; cada cliente
	reacciona a los peces que ve llegar). Tres capas que se suman a su pose:
		bocado   cada pez (Bocados): alterna atrapa, zarpazo, atrapa y sacude, y
		         el primero tras una pausa es un brinco; un bocado nuevo se funde
		         con el anterior (FADE), así una ráfaga de peces se ve como un
		         solo movimiento que cambia de lado y no como un tic
		grande   un pez raro (Grandes: pirueta o salto mortal) o un combo
		         (Festejos: a los 5, 15, 30 y cada 30 más); una a la vez y con
		         BIG_GAP de calma entre dos. Un combo que llega con otra en curso
		         espera hasta PENDING_FOR; un raro que no cabe hace un bocado con
		         destellos. Durante una grande los bocados siguen, más chicos.
		gusto    cada pez lo pone más contento (más si es raro) y se le pasa
		         despacio: colas abiertas que se menean, orejas arriba, jadea
	Al dejar de comer se relame. Si el pez lo dio el jugador de este cliente, lo
	mira y le ladea la cabeza (Body.look/from), y cada tanto le ladra (thanks).
	Peso por etapa: Capas. Gusto, festejos y mirada: Animo. Cuerpo entero: Cuerpo.
]]

local Animo = require(script.Animo)
local Bocados = require(script.Bocados)
local Capas = require(script.Capas)
local Clip = require(script.Clip)
local Cuerpo = require(script.Cuerpo)
local Curvas = require(script.Curvas)
local Festejos = require(script.Festejos)
local Grandes = require(script.Grandes)
local Pose = require(script.Parent.Pose)

local CYCLE = { "atrapa", "zarpazo", "atrapa", "sacude" }
local FADE = 0.14 -- s de fundido entre dos bocados
local PAUSE = 1.5 -- s sin comer: el próximo pez es un brinco
local LICK_AFTER = 0.9 -- s sin comer: se relame
local BIG_GAP = 1.2 -- s de calma entre dos reacciones grandes
local PENDING_FOR = 5 -- s que espera un festejo que no pudo empezar
local RARE_SPIN, RARE_FLIP = 3, 4 -- rareza (índice) de la pirueta y del mortal
local UNDER_BIG = 0.45 -- peso de un bocado durante una reacción grande
local MOOD_SECONDS = 2.5

export type Fed = { from: Vector3, rarity: number, isLocal: boolean, streak: number }
type Playing = Capas.Playing
export type Comer = {
	small: Playing?,
	prev: Playing?,
	big: Playing?, -- reacción grande en curso (mientras, no hay trucos)
	pending: { name: string, at: number }?,
	queue: { Capas.Out },
	fadeStart: number,
	nextBig: number,
	lastFed: number,
	licked: boolean,
	count: number,
	side: number,
	mood: number,
	glad: number, -- el gusto que se ve: sigue a mood suave
	mirada: Animo.Mirada,
	stage: number,
	radius: number,
	last: number,
	body: Cuerpo.State,
}

local Comer = {}

function Comer.new(): Comer
	return {
		queue = {},
		fadeStart = 0,
		nextBig = 0,
		lastFed = -math.huge,
		licked = true,
		count = 0,
		side = 1,
		mood = 0,
		glad = 0,
		mirada = Animo.nuevaMirada(),
		stage = 1,
		radius = 0.4,
		last = os.clock(),
		body = Cuerpo.new(),
	}
end

local function start(c: Comer, clip: Clip.Clip, now: number, rarity: number): Playing
	local p = Capas.start(clip, now, c.stage, c.side, c.radius, rarity)
	p.weight = if c.big then UNDER_BIG else 1
	return p
end

-- La reacción chica en curso pasa a fundirse y entra otra (o ninguna).
local function swap(c: Comer, nextSmall: Playing?, now: number)
	c.prev, c.small, c.fadeStart = c.small, nextSmall, now
end

-- Empieza una reacción grande; la chica en curso se funde.
local function startBig(c: Comer, clip: Clip.Clip, now: number, rarity: number)
	c.big = start(c, clip, now, rarity)
	swap(c, nil, now)
end

local function push(c: Comer, kind: string, power: number)
	table.insert(c.queue, { kind = kind, power = power, side = c.side })
end

function Comer.fed(c: Comer, info: Fed, now: number)
	local rarity = math.max(1, math.floor(info.rarity))
	c.side, c.count = -c.side, c.count + 1
	c.mood = math.min(1.5, c.mood + 0.2 + 0.15 * (rarity - 1))
	local since = now - c.lastFed
	c.lastFed, c.licked = now, false
	push(c, "catch", rarity)
	if info.isLocal then
		Animo.visto(c.mirada, info.from, c.side, now + 0.3 * Capas.PACE[c.stage])
	end
	local party = Animo.festejo(info.streak)
	local free = c.big == nil and now >= c.nextBig
	if party and free then -- el festejo empieza con este pez
		return startBig(c, Festejos[party], now, Animo.power(party))
	elseif party then
		c.pending = { name = party, at = now }
	end
	if rarity >= RARE_SPIN and free and not c.pending then
		return startBig(
			c,
			Grandes[if rarity >= RARE_FLIP then "mortal" else "pirueta"],
			now,
			rarity
		)
	end
	local name = if c.big
		then "atrapa"
		elseif since > PAUSE then "brinco"
		else CYCLE[c.count % #CYCLE + 1]
	swap(c, start(c, Bocados[name], now, rarity), now)
	if rarity >= RARE_SPIN then
		push(c, "glitter", rarity)
	end
end

-- Empieza el festejo pendiente o el relamido si toca.
local function startDue(c: Comer, now: number)
	local pending = c.pending
	if pending and now - pending.at > PENDING_FOR then
		c.pending = nil
	elseif pending and c.big == nil and now >= c.nextBig then
		c.pending = nil
		startBig(c, Festejos[pending.name], now, Animo.power(pending.name))
	end
	if c.big == nil and c.small == nil and not c.licked and now - c.lastFed > LICK_AFTER then
		c.licked = true
		swap(c, start(c, Bocados.relamer, now, 1), now)
	end
end

-- radius: radio de la carrera que cabe en el lago (fracción del alto). Devuelve la
-- pose a sumar y el Body (lo que mueve al cuerpo entero).
function Comer.step(c: Comer, now: number, height: number, radius: number): (Pose.Pose, Cuerpo.Body)
	local dt = math.clamp(now - c.last, 1 / 240, 0.1)
	c.last, c.stage, c.radius = now, Capas.stageFor(height), radius
	startDue(c, now)
	local pose: Pose.Pose = {}
	local f = if c.prev then Curvas.smooth((now - c.fadeStart) / FADE) else 1
	local small, prev, big = c.small, c.prev, c.big
	if small and not Capas.play(c.queue, small, now, pose, f * small.weight, true) then
		c.small = nil
	end
	if
		prev and (f >= 1 or not Capas.play(c.queue, prev, now, pose, (1 - f) * prev.weight, false))
	then
		c.prev = nil
	end
	if big and not Capas.play(c.queue, big, now, pose, 1, true) then
		c.big, c.nextBig = nil, now + BIG_GAP
	end
	-- El gusto, y el gesto al jugador de este cliente (lo mira y ladea la cabeza).
	c.mood *= math.exp(-dt / MOOD_SECONDS)
	c.glad += (math.min(1, c.mood) - c.glad) * (1 - math.exp(-dt * 5)) -- sin saltos
	Pose.add(pose, Animo.gusto(c.glad, now))
	local from = c.mirada.from
	local look, bark = Animo.mirar(c.mirada, now)
	Pose.add(pose, Animo.gesto(c.mirada), look)
	if bark then
		push(c, "thanks", 1)
	end
	return pose, Cuerpo.take(c.body, pose, dt, look, from)
end

-- Los eventos acumulados desde la última vez (sonidos y efectos).
function Comer.drain(c: Comer): { Capas.Out }
	local out = c.queue
	c.queue = {}
	return out
end

return table.freeze(Comer)
