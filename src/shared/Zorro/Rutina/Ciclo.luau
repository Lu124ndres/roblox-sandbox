--!strict
--[[
	Zorro/Rutina/Ciclo

	El ciclo c de la rutina armado una vez (puro: depende solo de c, la etapa, el
	alto y la lista; se guarda en un caché chico):
		[0, t1)       gira en el lugar del rumbo con el que terminó c-1 al de salida
		[t1, t2)      camina la Ruta del lugar de c-1 al de c: arranca y frena suave
		              en `ramp` s; si no entra en LONG_TRIP del ciclo, se apura
		[t2, start)   al llegar gira de frente a la puerta (con el desvío)
	Si el viaje es corto (menos de SHUFFLE altos: se acomoda en el témpano), no se
	da vuelta para caminar: da unos pasos girando de a poco al rumbo nuevo.
		[start, fin)  sus turnos (Agenda); antes de cada uno gira a su rumbo (los
		              trucos, de frente) y al final vuelve al de la estadía
	get(c, etapa, height, lista) lo arma; at(ciclo, t, giro) da el rumbo, la base,
	cuánto camina (0..1) y lo recorrido (studs) a los t segundos del ciclo.
]]

local Agenda = require(script.Parent.Agenda)
local Habitos = require(script.Parent.Parent.Habitos)
local Lugares = require(script.Parent.Lugares)
local Ruta = require(script.Parent.Ruta)
local Tipos = require(script.Parent.Parent.Tipos)

export type Ciclo = {
	from: Lugares.Lugar,
	to: Lugares.Lugar,
	ruta: Ruta.Ruta,
	speed: number,
	ramp: number,
	t1: number,
	t2: number,
	start: number,
	h0: number, -- rumbo al salir
	h1: number, -- rumbo al llegar
	shuffle: boolean, -- se acomoda sin darse vuelta
	turnos: { Agenda.Turno },
	paseo: Agenda.Turno?, -- lo que hace mientras camina (lo pone Rutina)
	paseado: boolean, -- ya se eligió el paseo
}

local LEG_SECONDS = 6 -- un tramo de zigzag dura como mucho esto
local WALK_TURN = 2.5 -- caminando gira hasta esto más rápido que en el lugar
local LONG_TRIP = 0.7 -- el viaje (giros incluidos) cabe en esta parte del ciclo
local SHUFFLE = 0.4 -- altos: un viaje más corto es acomodarse
local SHUFFLE_WALK = 0.6 -- cuánto camina al acomodarse
local CACHE = 16
local TAU = math.pi * 2

local Ciclo = {}

local function wrap(a: number): number
	return (a + math.pi) % TAU - math.pi
end

local function smooth(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

local function towards(d: Vector3): number
	return math.atan2(-d.X, -d.Z)
end

-- Segundos para girar `delta` rad con la curva suave (su pico es `rate`).
local function turnTime(delta: number, rate: number): number
	return math.max(math.abs(wrap(delta)) / rate * 1.5, 1e-3)
end

local function turnAt(from: number, to: number, k: number): number
	return from + wrap(to - from) * smooth(k)
end

local cache: { [string]: Ciclo } = {}
local cached = 0

function Ciclo.get(c: number, etapa: number, height: number, lista: { Tipos.Conducta }): Ciclo
	local id = `{c}:{etapa}:{height}:{tostring(lista)}`
	local hit = cache[id]
	if hit then
		return hit
	end
	local habito = Habitos.de(etapa)
	local from, to = Lugares.target(c - 1, etapa, height), Lugares.target(c, etapa, height)
	local speed = habito.velocidad * height
	local leg = speed * LEG_SECONDS
	local ruta = Ruta.build(from.position, to.position, height, leg, speed, habito.giro * WALK_TURN)
	local walks = ruta.length > 0.05
	local shuffle = ruta.length < SHUFFLE * height
	local _, d0 = Ruta.sample(ruta, 0)
	local _, d1 = Ruta.sample(ruta, ruta.length)
	local h0 = if walks and not shuffle then towards(d0) else from.facing
	local h1 = if walks and not shuffle then towards(d1) elseif walks then to.facing else from.facing
	local t1 = if walks then turnTime(h0 - from.facing, habito.giro) else 0
	local arrive = turnTime(to.facing - h1, habito.giro)
	local cruise = ruta.length / speed
	local most = habito.ciclo * LONG_TRIP - t1 - arrive - habito.arranque
	if walks and cruise > most then -- viaje largo: se apura
		speed = ruta.length / math.max(most, 1)
		cruise = ruta.length / speed
	end
	local ramp = if walks then math.min(habito.arranque, cruise) else 0
	local t2 = t1 + (if walks then cruise + ramp else 0)
	local start = t2 + arrive
	local door = Lugares.facing(to.position)
	local ciclo: Ciclo = {
		from = from,
		to = to,
		ruta = ruta,
		speed = speed,
		ramp = ramp,
		t1 = t1,
		t2 = t2,
		start = start,
		h0 = h0,
		h1 = h1,
		shuffle = shuffle,
		turnos = Agenda.build(c, etapa, start, habito.ciclo, to.facing, door, lista),
		paseo = nil,
		paseado = false,
	}
	if cached >= CACHE then
		table.clear(cache)
		cached = 0
	end
	cache[id], cached = ciclo, cached + 1
	return ciclo
end

-- Lo recorrido a los x segundos de echar a andar (arranca y frena suave en `ramp`).
local function along(x: number, ramp: number): number
	if x <= 0 then
		return 0
	elseif x <= ramp then
		local u = x / ramp
		return ramp * (u * u * u - u * u * u * u / 2)
	end
	return ramp / 2 + (x - ramp)
end

-- El rumbo en la estadía: el de cada turno, girando en la pausa de antes.
local function stayYaw(k: Ciclo, t: number, rate: number): number
	local yaw, last = k.to.facing, k.start
	for _, turno in k.turnos do
		if t < turno.from then
			return turnAt(yaw, turno.facing, (t - last) / turnTime(turno.facing - yaw, rate))
		end
		yaw, last = turno.facing, turno.to
	end
	return turnAt(yaw, k.to.facing, (t - last) / turnTime(k.to.facing - yaw, rate))
end

function Ciclo.at(k: Ciclo, t: number, rate: number): (number, Vector3, number, number)
	if t < k.t1 then
		return turnAt(k.from.facing, k.h0, t / k.t1), k.from.position, 0, 0
	elseif t < k.t2 then
		local x = t - k.t1
		local run = k.t2 - k.t1 - k.ramp
		local s = k.speed * (along(x, k.ramp) - along(x - run, k.ramp))
		local walk = smooth(x / k.ramp) - smooth((x - run) / k.ramp)
		local p, d = Ruta.sample(k.ruta, s)
		local y = Lugares.ground(p)
		if k.shuffle then
			local yaw = turnAt(k.from.facing, k.to.facing, s / k.ruta.length)
			return yaw, Vector3.new(p.X, y, p.Z), walk * SHUFFLE_WALK, s
		end
		return towards(d), Vector3.new(p.X, y, p.Z), walk, s
	elseif t < k.start then
		local k2 = (t - k.t2) / (k.start - k.t2)
		return turnAt(k.h1, k.to.facing, k2), k.to.position, 0, k.ruta.length
	end
	return stayYaw(k, t, rate), k.to.position, 0, k.ruta.length
end

return table.freeze(Ciclo)
