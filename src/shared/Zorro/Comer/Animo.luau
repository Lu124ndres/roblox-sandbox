--!strict
--[[
	Zorro/Comer/Animo

	Lo que siente el zorro mientras come, encima de cada reacción:
		festejo  qué festejo toca con esta racha (5: cola, 15: carrera, 30 y
		         cada 30 más: gran); power, con qué rareza se arma
		gusto    contento (0..1, sube con cada pez y se pasa despacio): colas
		         abiertas que se menean, orejas arriba, jadeo y cara feliz; si
		         le encanta (racha larga), las colas se menean más rápido
		cara     cada pez sacude las puntas de las orejas; un raro da sorpresa
		         (ojos y orejas) y después alegría
		mirada   el jugador de este cliente le dio un pez (visto): lo mira un rato
		         (mirar, 0..1), le dedica un gesto (gesto: ladea la cabeza, para
		         las orejas y menea las colas) y cada tanto le ladra
]]

local Curvas = require(script.Parent.Curvas)
local Pose = require(script.Parent.Parent.Pose)

local LOOK_SECONDS = 1.5
local THANKS_EVERY = 1.6 -- s como mínimo entre dos ladridos al jugador
local LOVE_STREAK = 12 -- peces seguidos con los que ya le encanta

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

-- Cuánto le encanta (0..1): mucho gusto acumulado o una racha larga.
function Animo.encanta(mood: number, streak: number): number
	return math.clamp(math.max((mood - 0.9) / 0.6, streak / LOVE_STREAK), 0, 1)
end

-- g: el gusto que se ve (0..1); love: le encanta (0..1, racha larga o mucho gusto):
-- las colas se menean más rápido (tailGusto) y jadea más.
function Animo.gusto(g: number, love: number, now: number): Pose.Pose
	local pant = math.sin(now * (9 + 4 * love))
	return {
		tailFan = 0.35 * g,
		tailLift = 0.2 * g,
		tailWag = 0.5 * g + 0.45 * love,
		tailGusto = math.max(0.7 * g, love),
		earL = 0.25 * g,
		earR = 0.25 * g,
		breathe = 0.015 * g * pant,
		jaw = 0.06 * g * (0.5 + 0.5 * pant),
		emoFeliz = g,
	}
end

-- La cara de cada pez: las puntas de las orejas se sacuden una después de la otra
-- (flick: cuándo llegó el pez); un pez raro (surprise: cuándo llegó) da sorpresa,
-- con las orejas paradas, y después más alegría.
function Animo.cara(flick: number, side: number, surprise: number, now: number): Pose.Pose
	local a = now - flick
	local tipL = if a >= 0 and a < 0.3 then math.sin(math.pi * a / 0.3) else 0
	local b = a - 0.09
	local tipR = if b >= 0 and b < 0.3 then math.sin(math.pi * b / 0.3) else 0
	local c = now - surprise
	local wow = Curvas.hold(c, 0, 0.08, 0.4, 0.7)
	local joy = Curvas.hold(c, 0.45, 0.7, 1.6, 2.4)
	return {
		earTipL = 0.45 * side * tipL,
		earTipR = -0.45 * side * tipR,
		emoSorpresa = wow,
		emoFeliz = 0.6 * joy - 0.6 * wow,
		earL = 0.35 * wow,
		earR = 0.35 * wow,
		blink = Curvas.bell(Curvas.span(c, 0.38, 0.5)),
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
	return { tilt = 0.22 * m.side, earL = 0.35, earR = 0.35, tailWag = 0.6, emoFeliz = 0.4 }
end

return table.freeze(Animo)
