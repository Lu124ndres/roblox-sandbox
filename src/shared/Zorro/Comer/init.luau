--!strict
--[[
	Zorro/Comer

	La animación especial del zorro al comer (solo en el cliente; cada cliente
	reacciona a los peces que ve llegar). Tres capas que se suman a su pose:
		bocado   cada pez (Elegir: el ciclo de su etapa; la cría a veces salta
		         torpe, la forma final come con calma); uno nuevo se funde con el
		         anterior (FADE): una ráfaga de peces es un solo movimiento
		grande   un pez raro (Elegir.grande) o un combo (a los 5, 15, 30 y cada 30
		         más), una a la vez y con BIG_GAP de calma entre dos. Un combo que
		         no cabe espera hasta PENDING_FOR; un raro que no cabe hace un
		         bocado con destellos. Durante una grande los bocados siguen, chicos.
		gusto    cada pez lo pone más contento y se le pasa despacio: colas que
		         se menean (más rápido si le encanta: racha larga) y cara feliz
	Cara (Animo.cara): las puntas de las orejas a cada pez; un raro, sorpresa y
	después alegría. Mira el bocado (Body.morsel) y al dejar de comer se relame. Al
	jugador de este cliente que le dio el pez lo mira (Body.look/from) y le ladra.
	Peso por etapa: Capas. Gusto, festejos y mirada: Animo. Cuerpo entero: Cuerpo.
]]

local Animo = require(script.Animo)
local Capas = require(script.Capas)
local Cuerpo = require(script.Cuerpo)
local Curvas = require(script.Curvas)
local Elegir = require(script.Elegir)
local Pose = require(script.Parent.Pose)

local FADE = 0.14 -- s de fundido entre dos bocados
local LICK_AFTER = 0.9 -- s sin comer: se relame
local BIG_GAP = 1.2 -- s de calma entre dos reacciones grandes
local PENDING_FOR = 5 -- s que espera un festejo que no pudo empezar
local UNDER_BIG = 0.45 -- peso de un bocado durante una reacción grande
local MOOD_SECONDS = 2.5
local STREAK_GAP = 2.5 -- s sin comer: se cortó la racha (como FedInfo)

export type Fed = { from: Vector3, rarity: number, isLocal: boolean, streak: number }
type Playing = Capas.Playing
export type Comer = {
	small: Playing?,
	fades: { Capas.Fade }, -- las chicas que se van apagando
	big: Playing?, -- reacción grande en curso (mientras, no hay trucos)
	pending: { name: string, at: number }?,
	fedFrom: Vector3?, -- de dónde vino el último pez (mira el bocado)
	queue: { Capas.Out },
	fadeStart: number,
	nextBig: number,
	lastFed: number,
	licked: boolean,
	count: number,
	side: number,
	mood: number,
	glad: number, -- el gusto que se ve (sigue a mood) y cuánto le encanta (0..1)
	love: number,
	streak: number,
	flickAt: number, -- cuándo llegó el último pez, y el último raro
	surpriseAt: number,
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
		fades = {},
		fadeStart = -math.huge,
		nextBig = 0,
		lastFed = -math.huge,
		licked = true,
		count = 0,
		side = 1,
		mood = 0,
		glad = 0,
		love = 0,
		streak = 0,
		flickAt = -math.huge,
		surpriseAt = -math.huge,
		mirada = Animo.nuevaMirada(),
		stage = 1,
		radius = 0.4,
		last = os.clock(),
		body = Cuerpo.new(),
	}
end

local function start(c: Comer, clip: Capas.Clip, now: number, rarity: number): Playing
	local p = Capas.start(clip, now, c.stage, c.side, c.radius, rarity)
	p.weight = if c.big then UNDER_BIG else 1
	return p
end

-- La reacción chica en curso pasa a fundirse y entra otra (o ninguna).
local function swap(c: Comer, nextSmall: Playing?, now: number)
	c.fadeStart = Capas.retire(c.fades, c.small, now, c.fadeStart, FADE)
	c.small = nextSmall
end

-- Empieza una reacción grande; la chica en curso se funde.
local function startBig(c: Comer, clip: Capas.Clip, now: number, rarity: number)
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
	c.streak, c.fedFrom, c.flickAt = info.streak, info.from, now
	local since = now - c.lastFed
	c.lastFed, c.licked = now, false
	push(c, "catch", rarity)
	if info.isLocal then
		Animo.visto(c.mirada, info.from, c.side, now + 0.3 * Capas.PACE[c.stage])
	end
	c.surpriseAt = if rarity >= Elegir.RARE then now else c.surpriseAt
	local party = Animo.festejo(info.streak)
	local free = c.big == nil and now >= c.nextBig
	if party and free then -- el festejo empieza con este pez
		return startBig(c, Elegir.festejo(c.stage, party), now, Animo.power(party))
	elseif party then
		c.pending = { name = party, at = now }
	end
	local big = Elegir.grande(c.stage, rarity)
	if big and free and not c.pending then
		return startBig(c, big, now, rarity)
	end
	swap(c, start(c, Elegir.bocado(c.stage, c.count, since, c.big ~= nil), now, rarity), now)
	if big then
		push(c, "glitter", rarity)
	end
end

local function startDue(c: Comer, now: number)
	local pending = c.pending
	if pending and now - pending.at > PENDING_FOR then
		c.pending = nil
	elseif pending and c.big == nil and now >= c.nextBig then
		c.pending = nil
		startBig(c, Elegir.festejo(c.stage, pending.name), now, Animo.power(pending.name))
	end
	if c.big == nil and c.small == nil and not c.licked and now - c.lastFed > LICK_AFTER then
		c.licked = true
		swap(c, start(c, Elegir.relamer, now, 1), now)
	end
end

-- radius: radio de la carrera que cabe en el lago (fracción del alto). Devuelve la
-- pose a sumar y el Body (lo que mueve al cuerpo entero).
function Comer.step(c: Comer, now: number, height: number, radius: number): (Pose.Pose, Cuerpo.Body)
	local dt = math.clamp(now - c.last, 1 / 240, 0.1)
	c.last, c.stage, c.radius = now, Capas.stageFor(height), radius
	startDue(c, now)
	local pose: Pose.Pose = {}
	local f = Curvas.smooth((now - c.fadeStart) / FADE) -- entra mientras la otra se va
	local small, big = c.small, c.big
	if small and not Capas.play(c.queue, small, now, pose, f * small.weight, true) then
		c.small = nil
	end
	Capas.fades(c.fades, now, pose, FADE)
	if big and not Capas.play(c.queue, big, now, pose, 1, true) then
		c.big, c.nextBig = nil, now + BIG_GAP
	end
	-- El gusto, la cara y el gesto al jugador de este cliente, sin saltos.
	c.mood *= math.exp(-dt / MOOD_SECONDS)
	local follow = 1 - math.exp(-dt * 5)
	c.glad += (math.min(1, c.mood) - c.glad) * follow
	local streak = if now - c.lastFed < STREAK_GAP then c.streak else 0
	c.love += (Animo.encanta(c.mood, streak) - c.love) * follow
	Pose.add(pose, Animo.gusto(c.glad, c.love, now))
	Pose.add(pose, Animo.cara(c.flickAt, c.side, c.surpriseAt, now))
	local from = c.mirada.from
	local look, bark = Animo.mirar(c.mirada, now)
	Pose.add(pose, Animo.gesto(c.mirada), look)
	if bark then
		push(c, "thanks", 1)
	end
	return pose, Cuerpo.take(c.body, pose, dt, look, from, c.fedFrom)
end

-- Los eventos acumulados desde la última vez (sonidos y efectos).
function Comer.drain(c: Comer): { Capas.Out }
	local out = c.queue
	c.queue = {}
	return out
end

return table.freeze(Comer)
