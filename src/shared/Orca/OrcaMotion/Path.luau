--!strict
--[[
	OrcaMotion/Path

	El recorrido de la orca dentro del lago del cráter como función de la hora
	del servidor (Workspace:GetServerTimeNow()): todos los clientes la ven en el
	mismo lugar sin mandar nada por la red.
		- Nada en vueltas que cambian solas de radio y de ritmo (parece al azar).
		- Cada `breath.seconds` baja un poco y vuelve a subir a respirar.
		- En algunos tramos de `trickEvery` segundos hace un truco de su etapa;
		  cuál y cuándo sale de un hash del tramo (igual en todos los clientes).
	Las alturas van en altos del modelo (negativo = bajo el agua).
]]

export type Sample = {
	position: Vector3, -- desde el centro del lago (Y = 0)
	velocity: Vector3,
	depth: number,
	breath: number, -- 0..1 del ciclo de respirar (0 = en la superficie)
}
export type Breath = { seconds: number, shallow: number, deep: number }

local WorldLayout = require(script.Parent.Parent.Parent.WorldLayout)
local WorldZones = require(script.Parent.Parent.Parent.WorldZones)
local Perfil = require(script.Parent.Parent.Etapas.Perfil)

local Path = {}

local function hash(n: number): number
	local x = math.sin(n * 12.9898 + 78.233) * 43758.5453
	return x - math.floor(x)
end

-- Radio en que puede nadar sin que la cabeza toque el acantilado (el cuerpo
-- mide ~1.5 veces el alto del modelo). Las etapas enormes casi no se mueven.
function Path.radius(lakeRadius: number, height: number): number
	return math.max(0, lakeRadius - height * 0.9 - 4)
end

-- Fondo del lago a esa distancia del centro, en studs respecto al agua.
function Path.floor(radius: number): number
	return WorldZones.lakeFloor(radius) - WorldLayout.waterLevel
end

-- Velocidad de crucero en studs/s: las más grandes avanzan más rápido.
function Path.speed(height: number): number
	return 8 + 0.15 * height
end

local function point(t: number, radius: number, speed: number): Vector3
	if radius < 1 then
		return Vector3.zero
	end
	local omega = math.min(speed / (radius * 0.62), 0.35)
	local angle = omega * t + 0.9 * math.sin(t * 0.071)
	local r = radius * (0.62 + 0.28 * math.sin(t * 0.113 + 1.7) + 0.08 * math.sin(t * 0.31))
	return Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
end

function Path.sample(t: number, radius: number, speed: number, breath: Breath): Sample
	local position = point(t, radius, speed)
	local cycle = (t % breath.seconds) / breath.seconds
	return {
		position = position,
		velocity = (point(t + 0.25, radius, speed) - position) / 0.25,
		depth = breath.shallow + (breath.deep - breath.shallow) * math.sin(math.pi * cycle) ^ 2,
		breath = cycle,
	}
end

-- Truco del tramo actual: índice en `tricks` (0 = ninguno), su avance (0..1) y
-- el número de tramo (sirve para saber cuándo empieza uno nuevo).
function Path.trick(
	t: number,
	every: number,
	chance: number,
	tricks: { Perfil.Entry }
): (number, number, number)
	local slot = math.floor(t / every)
	if #tricks == 0 or hash(slot) > chance then
		return 0, 0, slot
	end
	local total = 0
	for _, entry in tricks do
		total += entry.weight
	end
	local pick, index = hash(slot + 0.25) * total, #tricks
	for k, entry in tricks do
		pick -= entry.weight
		if pick <= 0 then
			index = k
			break
		end
	end
	local seconds = tricks[index].trick.seconds
	local start = slot * every + 2 + hash(slot + 0.5) * math.max(0, every - seconds - 4)
	local u = (t - start) / seconds
	if u >= 0 and u < 1 then
		return index, u, slot
	end
	return 0, 0, slot
end

return table.freeze(Path)
