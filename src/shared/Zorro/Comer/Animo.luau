--!strict
--[[
	Zorro/Comer/Animo

	Lo que siente el zorro mientras come, encima de cada reacción:
		festejo  qué festejo toca con esta racha (5: cola, 15: carrera, 30 y
		         cada 30 más: gran); power, con qué rareza se arma
		gusto    contento (0..1, sube con cada pez y se pasa despacio): colas
		         abiertas que se menean, orejas arriba y jadeo
		mirada   el jugador de este cliente le dio un pez (visto): lo mira un rato
		         (mirar, 0..1), le dedica un gesto (gesto: ladea la cabeza, para
		         las orejas y menea las colas) y cada tanto le ladra
]]

local Pose = require(script.Parent.Parent.Pose)

local LOOK_SECONDS = 1.5
local THANKS_EVERY = 1.6 -- s como mínimo entre dos ladridos al jugador

-- A quién mira (from), desde y hasta cuándo, hacia dónde ladea la cabeza y su
-- ladrido; shown: cuánto lo mira ahora (sigue al objetivo sin saltos).
export type Mirada = {
	from: Vector3?,
	startAt: number,
	untilAt: number,
	shown: number,
	last: number,
	side: number,
	thanksAt: number,
	lastThanks: number,
}

local Animo = {}

function Animo.nuevaMirada(): Mirada
	return {
		startAt = 0,
		untilAt = 0,
		shown = 0,
		last = 0,
		side = 1,
		thanksAt = 0,
		lastThanks = -math.huge,
	}
end

function Animo.festejo(streak: number): string?
	if streak == 5 then
		return "cola"
	elseif streak == 15 then
		return "carrera"
	elseif streak >= 30 and streak % 30 == 0 then
		return "gran"
	end
	return nil
end

-- Rareza con que se arma el festejo: el gran festejo saca también los fuegos fatuos
-- y el aullido largo (los eventos de Grandes piden rareza).
function Animo.power(festejo: string): number
	return if festejo == "gran" then 6 else 1
end

function Animo.gusto(g: number, now: number): Pose.Pose
	local pant = math.sin(now * 9)
	return {
		tailFan = 0.35 * g,
		tailLift = 0.2 * g,
		tailWag = 0.5 * g,
		earL = 0.25 * g,
		earR = 0.25 * g,
		breathe = 0.015 * g * pant,
		jaw = 0.06 * g * (0.5 + 0.5 * pant),
	}
end

-- Le llegó un pez del jugador de este cliente (at: cuando empieza a mirarlo).
-- side: hacia dónde ladea la cabeza; queda fijo mientras lo mira.
function Animo.visto(m: Mirada, from: Vector3, side: number, at: number)
	if not m.from then
		m.side, m.startAt = side, at
	end
	m.from, m.untilAt = from, at + LOOK_SECONDS
	if at - m.lastThanks > THANKS_EVERY then
		m.thanksAt, m.lastThanks = at + 0.2, at
	end
end

-- Cuánto lo mira ahora (0..1) y si le ladra en este cuadro. Otro pez suyo mientras
-- lo mira alarga la mirada sin cortarla.
function Animo.mirar(m: Mirada, now: number): (number, boolean)
	local dt = math.clamp(now - m.last, 0, 0.1)
	m.last = now
	local wanted = if m.from and now >= m.startAt and now < m.untilAt - 0.3 then 1 else 0
	m.shown += (wanted - m.shown) * (1 - math.exp(-dt * 12))
	if m.from and now > m.untilAt then
		m.from = nil
	end
	local bark = m.thanksAt > 0 and now >= m.thanksAt
	if bark then
		m.thanksAt = 0
	end
	return m.shown, bark
end

-- El gesto que le dedica: ladea la cabeza, para las orejas y menea las colas.
function Animo.gesto(m: Mirada): Pose.Pose
	return { tilt = 0.22 * m.side, earL = 0.35, earR = 0.35, tailWag = 0.6 }
end

return table.freeze(Animo)
