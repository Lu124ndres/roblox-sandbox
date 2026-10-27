--!strict
--[[
	OrcaMotion/Path/Rumbo

	Las reglas del rumbo del plan, en radios del lago:
		- la puerta del cráter (WorldZones.craterDoor()) queda a más o
		  menos radios según la etapa, así que se mira hacia una dirección entre la de la
		  cría y la de la anciana, con un margen que cubre a las dos;
		- `facing` es el ángulo del rumbo contra esa dirección (0 = de frente a la rampa,
		  ±pi/2 = de costado); el plan nunca pasa de `lim` (~110°): así no le da la espalda;
		- del lado de la rampa la orilla cómoda queda más adentro (`soft`): ahí da las
		  vueltas mirando a la rampa y necesita lugar;
		- `wanted` es el rumbo hacia un lugar respetando las dos cosas.
	También están los números al azar del plan (`rnd`, el hash sin estado de Azar).
]]

local WorldZones = require(script.Parent.Parent.Parent.Parent.WorldZones)
local Azar = require(script.Parent.Parent.Parent.Parent.Minotauro.Azar)

local TAU = 2 * math.pi
local NEAR_RADIUS = 175 -- radio de nado de la cría (Path.radius): la puerta le queda más cerca
local FAR_RADIUS = 41 -- y el de la anciana: la puerta le queda más lejos
local PHI_MAX = math.rad(112) -- el rumbo se aparta como mucho esto de la dirección a la puerta
local SOFT = 0.7 -- radios: orilla cómoda a los costados
local SOFT_TILT = 0.12 -- cuánto más adentro del lado de la rampa (y más afuera del otro)
local INSIDE = 0.05 -- radios: los lugares que busca quedan así de adentro de la orilla cómoda
local LOOK = 0.35 -- radios: cuánto mira adelante para no ir contra la orilla
local PUSH = 0.35 -- cuánto se aparta de la orilla al ir contra ella
local BEHIND = math.rad(160) -- el lugar queda casi justo detrás: sigue por el lado que va

local door = WorldZones.craterDoor() - WorldZones.craterCenter -- la puerta: donde sale el túnel
local DOOR_X, DOOR_Z = door.X, door.Z -- studs desde el centro del lago

local Rumbo = {}

Rumbo.DOOR_X, Rumbo.DOOR_Z = DOOR_X, DOOR_Z
Rumbo.DOOR_ANGLE = math.atan2(DOOR_Z, DOOR_X) -- hacia dónde queda la rampa desde el centro

function Rumbo.wrap(a: number): number
	return (a + math.pi) % TAU - math.pi
end
local wrap = Rumbo.wrap

function Rumbo.sign(x: number): number
	return if x < 0 then -1 else 1
end

-- Número en [0, 1) del plan: época, decisión, para qué (salt < 16) y campo (< 32).
function Rumbo.rnd(epoch: number, i: number, salt: number, field: number): number
	return Azar.unit(epoch * 32 + field, i * 16 + salt)
end

-- Dirección a la puerta desde (x, z) y cuánto puede apartarse de ella el rumbo.
function Rumbo.frame(x: number, z: number): (number, number)
	local nx, nz = DOOR_X / NEAR_RADIUS - x, DOOR_Z / NEAR_RADIUS - z
	local fx, fz = DOOR_X / FAR_RADIUS - x, DOOR_Z / FAR_RADIUS - z
	local near = math.atan2(nz, nx)
	local gap = wrap(math.atan2(fz, fx) - near) / 2
	return near + gap, PHI_MAX - math.abs(gap)
end

function Rumbo.facing(th: number, x: number, z: number): number
	local g = Rumbo.frame(x, z)
	return wrap(th - g)
end

-- Radio cómodo en la dirección de (x, z).
function Rumbo.soft(x: number, z: number): number
	local m = math.sqrt(x * x + z * z)
	return SOFT + SOFT_TILT * (if m > 1e-6 then z / m else 0)
end

-- (x, z) traído hacia adentro de la orilla cómoda si hace falta.
function Rumbo.inside(x: number, z: number): (number, number)
	local m = math.sqrt(x * x + z * z)
	local lim = Rumbo.soft(x, z) - INSIDE
	if m > lim then
		local k = lim / m
		return x * k, z * k
	end
	return x, z
end

-- `facing` del rumbo hacia `thWant` desde (x, z), sin ir contra la orilla ni de espaldas
-- a la rampa. phi0: el `facing` que trae (decide el lado si el lugar queda detrás).
function Rumbo.wanted(thWant: number, x: number, z: number, phi0: number): number
	local qx, qz = x + math.cos(thWant) * LOOK, z + math.sin(thWant) * LOOK
	local m = math.sqrt(x * x + z * z)
	if math.sqrt(qx * qx + qz * qz) > Rumbo.soft(qx, qz) and m > 1e-3 then
		local nx, nz = x / m, z / m
		local dx, dz = math.cos(thWant), math.sin(thWant)
		local out = dx * nx + dz * nz
		if out > -PUSH then
			thWant = math.atan2(dz - nz * (out + PUSH), dx - nx * (out + PUSH))
		end
	end
	local phi = Rumbo.facing(thWant, x, z)
	local _, lim = Rumbo.frame(x, z)
	if math.abs(phi) > lim then
		local side = if math.abs(phi) < BEHIND or phi0 == 0 then phi else phi0
		phi = Rumbo.sign(side) * lim
	end
	return phi
end

return table.freeze(Rumbo)
