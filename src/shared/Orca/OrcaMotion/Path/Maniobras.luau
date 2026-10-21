--!strict
--[[
	OrcaMotion/Path/Maniobras

	El próximo tramo del plan según lo que quiere hacer la orca (Intencion), con las
	reglas de un animal grande en el agua:
		- va hacia su lugar girando de a poco, siempre por el lado de la rampa (Rumbo);
		- una vuelta grande la da frenando y más rápido, nunca un círculo; si pasar por
		  el lado de la rampa no cabe en el lago, se da vuelta rápido por el otro lado
		  (FLIP: pasa los ~120° de espaldas en menos de 3 s);
		- nunca sale de R_HARD (prueba otra maniobra o se queda con la que menos sale);
		- alterna aletazos (acelera) y tramos planeando (frena);
		- para descansar frena y queda de costado a la rampa.
	Velocidades en radios del lago por segundo (U es el crucero).
]]

local Intencion = require(script.Parent.Intencion)
local Rumbo = require(script.Parent.Rumbo)
local Tramo = require(script.Parent.Tramo)

local U = 0.065 -- radios/s: el crucero (con 175 de radio, ~11 studs/s)
local OMEGA_LO, OMEGA_HI = 0.28, 0.5 -- rad/s de las curvas comunes
local FLIP = 0.9 -- rad/s: vuelta rápida
local BIG = 1.5 -- rad: desde esta vuelta frena y gira más rápido
local SLOW = 0.3 -- U: velocidad a la que da una vuelta cerrada
local BRAKE_SPEED = 0.2 -- U: frena antes de una vuelta que no cabe
local REST_SPEED = 0.08 -- U: así llega a descansar
local TURN_SECONDS = 10 -- s: una curva larga se parte en tramos de esto
local R_HARD = 0.9 -- radios: un tramo no pasa de aquí
local BURST = 0.55 -- probabilidad de un tramo con aletazos (si no, planea)
local ARRIVE = 0.35 -- radios: más cerca que esto del lugar, va frenando
local STRAIGHT = 0.12 -- rad: menos que esto de giro es un tramo casi recto
local WIGGLE = 0.3 -- rad: lo que serpentea un tramo casi recto
local FRONT_MARGIN = 0.03 -- rad: un tramo termina así de adentro del límite de la rampa

local Maniobras = {}

Maniobras.U = U

-- Corrige el giro para que al final del tramo no quede de espaldas a la rampa.
local function keepFront(seg: Tramo.Tramo): Tramo.Tramo
	local x, z, _, _, th = Tramo.at(seg, seg.D)
	local phi = Rumbo.facing(th, x, z)
	local _, lim = Rumbo.frame(x, z)
	if math.abs(phi) > lim then
		seg.w -= Rumbo.sign(phi) * (math.abs(phi) - lim + FRONT_MARGIN) / seg.D
	end
	return seg
end

local function turnSeg(
	t: number,
	x: number,
	z: number,
	th: number,
	v: number,
	v1: number,
	delta: number,
	omega: number,
	room: number
): Tramo.Tramo
	local D = math.abs(delta) / omega
	local turn = if D <= TURN_SECONDS then delta else delta * TURN_SECONDS / D
	return keepFront(
		Tramo.arc(t, x, z, th, v, v1, turn, math.min(math.max(D, 2), TURN_SECONDS, room))
	)
end

-- Tramo hacia (wx, wz) con la intención `mode`; room: segundos que le quedan a la época.
function Maniobras.travel(
	epoch: number,
	i: number,
	t: number,
	x: number,
	z: number,
	th: number,
	v: number,
	mode: string,
	wx: number,
	wz: number,
	room: number
): Tramo.Tramo
	local function h(field: number): number
		return Rumbo.rnd(epoch, i, 12, field)
	end
	local m = Intencion.mode(mode)
	local dx, dz = wx - x, wz - z
	local dist = math.sqrt(dx * dx + dz * dz)
	local v1 = U * (if h(0) < BURST then m.hi * (1 + 0.12 * h(1)) else m.lo * (0.8 + 0.2 * h(1)))
	if dist < ARRIVE then
		v1 = math.min(v1, U * math.max(0.35, dist / ARRIVE))
	end
	local phi0 = Rumbo.facing(th, x, z)
	local delta = Rumbo.wanted(math.atan2(dz, dx), x, z, phi0) - phi0 -- por el lado de la rampa
	if math.abs(delta) <= STRAIGHT then
		local turn = delta + (h(4) - 0.5) * WIGGLE
		local seg = keepFront(Tramo.arc(t, x, z, th, v, v1, turn, math.min(3 + 6 * h(3), room)))
		if Tramo.reach(seg) <= R_HARD then
			return seg
		end
		delta = Rumbo.wanted(math.atan2(-z, -x), x, z, phi0) - phi0 -- va contra la orilla: adentro
	end
	local omega = OMEGA_LO + (OMEGA_HI - OMEGA_LO) * h(2)
	local vTurn = v1 * (1 - 0.2 * omega / OMEGA_HI)
	if math.abs(delta) > BIG then -- frena y gira más rápido: no da un círculo
		omega, vTurn = OMEGA_HI + (FLIP - OMEGA_HI) * h(2), v1 * (0.45 + 0.25 * h(5))
	end
	local other = delta - Rumbo.sign(delta) * 2 * math.pi
	local function front(): Tramo.Tramo
		return turnSeg(t, x, z, th, v, vTurn, delta, omega, room)
	end
	local function back(): Tramo.Tramo -- se da vuelta rápido por el otro lado
		return turnSeg(t, x, z, th, v, SLOW * U, other, FLIP, room)
	end
	local tries: { () -> Tramo.Tramo } = if math.abs(delta) > math.pi
		then { back, front }
		else { front }
	table.insert(tries, function() -- frena y la vuelta se cierra
		return turnSeg(t, x, z, th, v, SLOW * U, delta, FLIP, room)
	end)
	table.insert(tries, function() -- frena antes, casi derecho
		local small = math.clamp(delta, -WIGGLE, WIGGLE)
		return keepFront(Tramo.arc(t, x, z, th, v, BRAKE_SPEED * U, small, math.min(3.5, room)))
	end)
	if math.abs(delta) > math.pi / 2 and math.abs(delta) <= math.pi then
		table.insert(tries, back)
	end
	local best, bestReach = nil :: Tramo.Tramo?, math.huge
	for _, make in tries do
		local seg = make()
		local r = Tramo.reach(seg)
		if r <= R_HARD then
			return seg
		end
		if r < bestReach then
			best, bestReach = seg, r
		end
	end
	return best :: Tramo.Tramo
end

-- Flota casi quieta `D` segundos. Sin destino: se deja llevar `drift` radios y se pone
-- de costado a la rampa (del lado que le queda más cerca).
function Maniobras.rest(
	t: number,
	x: number,
	z: number,
	th: number,
	v: number,
	D: number,
	drift: number,
	qx: number?,
	qz: number?,
	th1: number?
): Tramo.Tramo
	local phi0 = Rumbo.facing(th, x, z)
	local endX, endZ, endTh
	if qx and qz and th1 then
		endX, endZ, endTh = qx, qz, th1
	else
		local half = math.pi / 2
		local side = if math.abs(half - phi0) <= math.abs(-half - phi0) then half else -half
		endTh = Rumbo.frame(x, z) + side * Intencion.SIDE
		endX, endZ = x + math.cos(endTh) * drift, z + math.sin(endTh) * drift
	end
	local dth = Rumbo.facing(endTh, x, z) - phi0
	return Tramo.rest(t, x, z, th, v, D, endX, endZ, dth)
end

-- Frena para descansar y de paso gira un poco hacia un costado de la rampa.
function Maniobras.brake(
	t: number,
	x: number,
	z: number,
	th: number,
	v: number,
	D: number
): Tramo.Tramo
	local phi0 = Rumbo.facing(th, x, z)
	local side = Rumbo.sign(phi0) * math.pi / 2 * Intencion.SIDE
	local turn = math.clamp(side - phi0, -0.4, 0.4)
	return Tramo.arc(t, x, z, th, v, REST_SPEED * U, turn, D)
end

return table.freeze(Maniobras)
