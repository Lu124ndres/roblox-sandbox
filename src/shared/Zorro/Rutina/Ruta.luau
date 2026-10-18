--!strict
--[[
	Zorro/Rutina/Ruta

	Por dónde camina de un lugar a otro, para que desde la puerta del cráter se le
	vea de frente o de costado y nunca la cola (guía, "Mirar al público"):
		- si el tramo derecho deja su frente a menos de ~117° de la puerta en todo
		  el camino (DIRECT), va derecho;
		- si no (el lugar queda más lejos de la puerta), zigzaguea como un velero
		  contra el viento: tramos a TACK de la puerta, alternando el lado, hasta que
		  el lugar le queda derecho. Cada tramo mide como mucho `leg` studs (unos
		  segundos de paseo) y no se sale del radio que le cabe.
	Las esquinas se redondean con arcos (Rutina/Trazo) de radio speed / rate:
	caminando a `speed` studs/s no gira más rápido que `rate` rad/s (si el tramo
	alcanza), así el rumbo cambia parejo y no gira en seco. Un tramo de zigzag más
	corto que MIN_LEG del largo de un tramo al final no se hace: va derecho.
		build(from, to, height, leg, speed, rate)  arma la ruta (plana, Y = 0)
		sample(ruta, s)                            posición y dirección a s studs
	Todo es puro: la misma ruta en todos los clientes.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local Lugares = require(script.Parent.Lugares)
local Trazo = require(script.Parent.Trazo)

export type Ruta = Trazo.Trazo

local TACK = -0.42 -- coseno entre su frente y la puerta en un tramo de zigzag (~115°)
local DIRECT = -0.45 -- va derecho si el coseno no baja de esto (~117°)
local MAX_LEGS = 14
local MIN_LEG = 0.2 -- fracción de `leg`: el último tramo, si es más corto, no se hace
local CENTER = Vector3.new(WorldZones.craterCenter.X, 0, WorldZones.craterCenter.Z)
local ANGLE = math.acos(TACK)

local Ruta = {}

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function doorFrom(p: Vector3): Vector3
	return (flat(Lugares.door()) - p).Unit
end

local function rotate(v: Vector3, a: number): Vector3
	local c, s = math.cos(a), math.sin(a)
	return Vector3.new(v.X * c - v.Z * s, 0, v.X * s + v.Z * c)
end

local function cross(a: Vector3, b: Vector3): number
	return a.X * b.Z - a.Z * b.X
end

-- ¿El tramo derecho de p a q lo deja de frente o de costado todo el camino?
local function straight(p: Vector3, q: Vector3): boolean
	local h = (q - p).Unit
	for _, k in { 0, 0.25, 0.5, 0.75, 1 } do
		if h:Dot(doorFrom(p:Lerp(q, k))) < DIRECT then
			return false
		end
	end
	return true
end

-- Dónde corta el rayo p + u·x a la recta q - v·y (x e y > 0), o nil: el punto desde
-- el que q le queda derecho con el rumbo v.
local function meet(p: Vector3, u: Vector3, q: Vector3, v: Vector3): number?
	local den = cross(u, v)
	if math.abs(den) < 1e-6 then
		return nil
	end
	local w = q - p
	local x, y = cross(w, v) / den, cross(u, w) / den
	return if x > 0 and y > 0 then x else nil
end

-- El rumbo de un tramo de zigzag hacia un lado (+1/-1), medido con la puerta vista
-- desde el final del tramo: al avanzar, la puerta queda cada vez más atrás.
local function tackFrom(p: Vector3, most: number, side: number): Vector3
	local first = rotate(doorFrom(p), ANGLE * side)
	return rotate(doorFrom(p + first * most), ANGLE * side)
end

local function inside(p: Vector3, limit: number): boolean
	return (p - CENTER).Magnitude <= limit + 0.01
end

function Ruta.build(
	from: Vector3,
	to: Vector3,
	height: number,
	leg: number,
	speed: number,
	rate: number
): Ruta
	local p, goal = flat(from), flat(to)
	local points = { p }
	local limit = Lugares.limit(height)
	local side = 0
	for _ = 1, MAX_LEGS do
		if (goal - p).Magnitude < 0.5 then
			break
		end
		if straight(p, goal) then
			break
		end
		local h = (goal - p).Unit
		local most = math.min(leg, 0.3 * (flat(Lugares.door()) - p).Magnitude)
		local a, b = tackFrom(p, most, 1), tackFrom(p, most, -1)
		if side == 0 then
			side = if a:Dot(h) >= b:Dot(h) then 1 else -1
		end
		local tack, other = if side > 0 then a else b, if side > 0 then b else a
		local x = meet(p, tack, goal, other)
		local step = if x and x <= most then x else most
		local nextPoint = p + tack * step
		if not inside(nextPoint, limit) then -- se saldría: va por el otro lado
			side = -side
			tack = other
			nextPoint = p + tack * most
			if not inside(nextPoint, limit) then
				local out = nextPoint - CENTER
				nextPoint = CENTER + out.Unit * limit
			end
		end
		p = nextPoint
		table.insert(points, p)
		side = -side
	end
	-- El último tramo muy corto (o el que llega casi al lugar) se junta con el anterior,
	-- y un tramo de en medio muy corto (al topar con el borde) se saltea.
	while #points > 1 and (goal - points[#points]).Magnitude < MIN_LEG * leg do
		table.remove(points)
	end
	table.insert(points, goal)
	for i = #points - 1, 2, -1 do
		if (points[i] - points[i - 1]).Magnitude < MIN_LEG * leg then
			table.remove(points, i)
		end
	end
	return Trazo.build(points, speed / rate)
end

function Ruta.sample(r: Ruta, s: number): (Vector3, Vector3)
	return Trazo.sample(r, s)
end

return table.freeze(Ruta)
