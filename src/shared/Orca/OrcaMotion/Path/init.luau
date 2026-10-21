--!strict
--[[
	OrcaMotion/Path

	El recorrido de la orca dentro del lago del cráter como función de la hora del
	servidor (Workspace:GetServerTimeNow()) y de un hash sin estado: todos los
	clientes la ven en el mismo lugar sin mandar nada por la red.
		- Ruta: nada como un animal, no en vueltas: cruza el lago, patrulla la orilla,
		  pasea o descansa flotando; la velocidad sube con los aletazos y baja planeando;
		  da las vueltas frenando y se deja ver de costado o de frente desde la rampa.
		- Aliento: series de respiraciones cortas y una inmersión larga.
		- trick: qué truco de su etapa hace y cuándo, eligiendo el momento en que va de
		  costado o de frente a la rampa.
	El plan va en radios del lago: cambia de tamaño con la etapa sin saltar. Las
	alturas van en altos del modelo (negativo = bajo el agua). La simulación que mide
	todo esto está en tools/orca_recorrido_sim.py (replica la cuenta).
]]

local WorldLayout = require(script.Parent.Parent.Parent.WorldLayout)
local WorldZones = require(script.Parent.Parent.Parent.WorldZones)
local Azar = require(script.Parent.Parent.Parent.Minotauro.Azar)
local Perfil = require(script.Parent.Parent.Etapas.Perfil)
local Aliento = require(script.Aliento)
local Maniobras = require(script.Maniobras)
local Rumbo = require(script.Rumbo)
local Ruta = require(script.Ruta)
local Tramo = require(script.Tramo)

export type Breath = Aliento.Breath
export type Sample = {
	position: Vector3, -- desde el centro del lago (Y = 0)
	velocity: Vector3,
	depth: number,
	breath: number, -- 0..1 entre soplidos (vuelve a 0 al soplar)
	heading: number, -- rumbo del plan (yaw de CFrame.Angles(0, yaw, 0))
	resting: boolean, -- flota descansando: el cuerpo puede derivar de costado
	mode: string, -- cruce, orilla, paseo, frenar o descanso
	effort: number, -- 0..1: aletazos (1) o planeando
	blow: boolean, -- acaba de soplar por el espiráculo (BLOW_SECONDS)
}

local LAKE = WorldLayout.craterLakeRadius + 4 -- hasta el pie del acantilado (como OrcaMotion)
local MIN_CRUISE = 3 -- studs/s: la etapa más grande igual se mueve
local LEAD = 0.5 -- s: la altura se adelanta lo que tarda el cuerpo en llegar al soplar
local REST_EASE = 3 -- s: al descansar sube a flotar en este tiempo
local BLOW_SECONDS = 0.8
local EFFORT_REST, EFFORT_GLIDE, EFFORT_BURST = 0.15, 0.3, 1
local TRICK_DOMAIN = 9100 -- separa el azar de los trucos
local TRICK_EDGE = 2 -- s: un truco no empieza ni termina tan cerca del borde de su tramo
local TRICK_STARTS = 4 -- momentos que prueba para cada truco
local TRICK_LOOKS = 5 -- veces que mira el rumbo durante el truco
local BACK = -0.5 -- adelante · (puerta - orca) más bajo que esto: de espaldas a la rampa

local Path = {}

-- Radio en que puede nadar sin que la cabeza toque el acantilado (el cuerpo
-- mide ~1.5 veces el alto del modelo). Las etapas enormes casi no se mueven.
function Path.radius(lakeRadius: number, height: number): number
	return math.max(0, lakeRadius - height * 0.9 - 4)
end

-- Fondo del lago a esa distancia del centro, en studs respecto al agua.
function Path.floor(radius: number): number
	return WorldZones.lakeFloor(radius) - WorldLayout.waterLevel
end

-- Velocidad de crucero en studs/s: la del plan, que va en radios del lago (las etapas
-- grandes tienen menos lago y nadan más despacio, con más peso).
function Path.speed(height: number): number
	return math.max(MIN_CRUISE, Maniobras.U * Path.radius(LAKE, height))
end

-- Dónde está la puerta del cráter (la rampa) desde el centro del lago, en studs.
function Path.door(): Vector3
	return Vector3.new(Rumbo.DOOR_X, 0, Rumbo.DOOR_Z)
end

local function yawOf(th: number): number
	return math.atan2(-math.cos(th), -math.sin(th)) -- Angles(0, y, 0) mira a (-sin y, 0, -cos y)
end

-- `_cruise` ya no cambia el plan (el enojo no puede apurar un plan fijo sin moverlo):
-- lo usa Steer como tope de velocidad.
function Path.sample(t: number, radius: number, _cruise: number, breath: Breath): Sample
	local seg, tau = Ruta.locate(t)
	local x, z, vx, vz, th = Tramo.at(seg, tau)
	local rest = 0
	if seg.rest then
		rest = Tramo.smooth(tau / REST_EASE) * Tramo.smooth((seg.D - tau) / REST_EASE)
	end
	local phase, _, since = Aliento.phase(t, breath.seconds)
	local depth = Aliento.depth(t + LEAD, breath)
	depth += (breath.shallow - depth) * rest -- descansando flota con el lomo afuera
	local effort = if seg.rest
		then EFFORT_REST
		elseif seg.v1 > seg.v0 then EFFORT_BURST
		else EFFORT_GLIDE
	return {
		position = Vector3.new(x * radius, 0, z * radius),
		velocity = Vector3.new(vx * radius, 0, vz * radius),
		depth = depth,
		breath = phase,
		heading = yawOf(th),
		resting = seg.rest,
		mode = seg.mode,
		effort = effort,
		blow = since < BLOW_SECONDS,
	}
end

-- Rumbo medio del plan en los próximos `seconds` (vector plano, unitario; cero si flota
-- quieta): para que un truco salga hacia un costado de la rampa.
function Path.heading(t: number, seconds: number): Vector3
	local sx, sz = 0, 0
	for k = 0, TRICK_LOOKS - 1 do
		local _, _, vx, vz = Ruta.at(t + seconds * k / (TRICK_LOOKS - 1))
		local m = math.sqrt(vx * vx + vz * vz)
		if m > 1e-6 then
			sx, sz = sx + vx / m, sz + vz / m
		end
	end
	local m = math.sqrt(sx * sx + sz * sz)
	return if m > 1e-3 then Vector3.new(sx / m, 0, sz / m) else Vector3.zero
end

-- adelante · (puerta - orca) del plan a la hora `t`: 1 de frente a la rampa, 0 de
-- costado, -1 de espaldas.
function Path.facing(t: number): number
	local x, z, _, _, th = Ruta.at(t)
	return math.cos(Rumbo.facing(th, x, z))
end

-- Qué tan bien se ve un truco que empieza en `start`: de costado es lo mejor, de frente
-- también sirve, de espaldas no.
local function showScore(start: number, seconds: number): number
	local score = 0
	for k = 0, TRICK_LOOKS - 1 do
		local f = Path.facing(start + seconds * k / (TRICK_LOOKS - 1))
		if f < BACK then
			score -= 10
		else
			score += (1 - math.abs(f)) + 0.3 * math.max(f, 0)
		end
	end
	return score
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
	if #tricks == 0 or Azar.unit(slot, TRICK_DOMAIN) > chance then
		return 0, 0, slot
	end
	local total = 0
	for _, entry in tricks do
		total += entry.weight
	end
	local pick, index = Azar.unit(slot, TRICK_DOMAIN + 1) * total, #tricks
	for k, entry in tricks do
		pick -= entry.weight
		if pick <= 0 then
			index = k
			break
		end
	end
	local seconds = tricks[index].trick.seconds
	local first = slot * every + TRICK_EDGE
	local span = math.max(0, every - seconds - 2 * TRICK_EDGE)
	local start, best = first, -math.huge
	for k = 0, TRICK_STARTS - 1 do
		local at = first + span * (k + Azar.unit(slot, TRICK_DOMAIN + 2 + k)) / TRICK_STARTS
		local score = showScore(at, seconds)
		if score > best then
			start, best = at, score
		end
	end
	local u = (t - start) / seconds
	if u >= 0 and u < 1 then
		return index, u, slot
	end
	return 0, 0, slot
end

return table.freeze(Path)
