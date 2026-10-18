--!strict
--[[
	Zorro/Comer/Pivote

	Cómo el Body de Comer mueve al zorro entero en el lago:
		radius  radio de la carrera (fracción del alto) que deja todo el cuerpo
		        dentro del cráter desde donde está (el centro del lago o un témpano
		        de Zorro/Guarida): el círculo pasa por su lugar y puede ir hacia
		        cualquier lado, así que lo más lejos que llega es su lugar + dos
		        radios + lo que mide. Dos límites:
		          las patas y el pecho (FEET) sobre el agua: dentro de LAKE
		          lo que va por debajo del borde del cráter (REACH, medido en los
		          modelos v2: la cría entera, las colas bajas del joven y del
		          adulto; de la forma final solo el cuerpo, sus colas pasan por
		          encima del borde) sin entrar en la pared: dentro de CLIFF
		        Sin lugar, 0: gira en el lugar. La forma final no corre (Elegir).
		look    gira la cabeza hacia quien le dio el pez (en su marco: heading) y
		        hacia el bocado mientras lo atrapa (morsel: hacia donde venía el
		        pez y abajo, a la boca)
		build   el pivote: corrido por la carrera, girado sobre sí y, en el salto
		        mortal, dado vuelta alrededor de la cadera (no de los pies)
]]

local WorldLayout = require(script.Parent.Parent.Parent.WorldLayout)
local Capas = require(script.Parent.Capas)
local Cuerpo = require(script.Parent.Cuerpo)
local Pose = require(script.Parent.Parent.Pose)

local LAKE = WorldLayout.craterLakeRadius
local CLIFF = WorldLayout.craterCliffRadius
local LAKE_CENTER = Vector3.new(WorldLayout.craterCenter[1], 0, WorldLayout.craterCenter[2])
local HIP = 0.45 -- alto de la cadera (fracción del alto): eje del salto mortal
local FEET = 0.25 -- patas y pecho desde el pivote (fracción del alto)
local REACH = { 0.8, 1.15, 0.8, 0.35 } -- lo más lejos que llega por debajo del borde
local MAX_RADIUS = 0.5
local MIN_RADIUS = 0.05 -- menos que esto no se nota: gira en el lugar

local Pivote = {}

-- center: dónde está parado ahora (la base, sin la carrera).
function Pivote.radius(center: Vector3, height: number): number
	local away = (Vector3.new(center.X, 0, center.Z) - LAKE_CENTER).Magnitude
	local h = math.max(height, 1)
	local reach = REACH[Capas.stageFor(h)]
	local room = math.min(LAKE - away - FEET * h, CLIFF - away - reach * h)
	local r = math.min(room / (2 * h), MAX_RADIUS)
	return if r < MIN_RADIUS then 0 else r
end

local function wrap(angle: number): number
	return (angle + math.pi) % (math.pi * 2) - math.pi
end

-- Hacia dónde queda `at` en su marco (rad, + a su izquierda) y a qué distancia.
local function toward(at: Vector3, center: Vector3, heading: number): (number, Vector3)
	local d = at - center
	return wrap(math.atan2(-d.X, -d.Z) - heading), d
end

-- center: base del zorro; heading: hacia dónde mira (Angles(0, y, 0) mira a -Z).
function Pivote.look(
	pose: Pose.Pose,
	body: Cuerpo.Body,
	center: Vector3,
	height: number,
	heading: number
)
	local fed = body.fed
	if fed and body.morsel > 0 then
		local rel = toward(fed, center, heading)
		pose.lookYaw = (pose.lookYaw or 0) + math.clamp(rel, -0.6, 0.6) * 0.5 * body.morsel
		pose.lookPitch = (pose.lookPitch or 0) - 0.18 * body.morsel
	end
	local from = body.from
	if not from or body.look <= 0 then
		return
	end
	local rel, d = toward(from, center, heading)
	local flat = Vector3.new(d.X, 0, d.Z).Magnitude
	local pitch = math.atan2(from.Y - (center.Y + height * 0.85), math.max(flat, 1))
	pose.lookYaw = (pose.lookYaw or 0) + math.clamp(rel, -1.2, 1.2) * body.look
	pose.lookPitch = (pose.lookPitch or 0) + math.clamp(pitch, -0.5, 0.25) * body.look
	pose.lookHold = math.max(pose.lookHold or 0, body.look)
end

-- base: dónde estaría sin la carrera (con su altura). Devuelve el centro y el pivote.
function Pivote.build(
	base: Vector3,
	heading: number,
	body: Cuerpo.Body,
	height: number
): (Vector3, CFrame)
	local facing = CFrame.Angles(0, heading, 0)
	local center = base + facing:VectorToWorldSpace(Vector3.new(body.runX, 0, body.runZ)) * height
	local pivot = CFrame.new(center) * CFrame.Angles(0, heading + body.spin, 0)
	if body.flip ~= 0 then
		local hip = height * HIP
		pivot *= CFrame.new(0, hip, 0) * CFrame.Angles(body.flip, 0, 0) * CFrame.new(0, -hip, 0)
	end
	return center, pivot
end

return table.freeze(Pivote)
