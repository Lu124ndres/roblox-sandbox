--!strict
--[[
	Minotauro/Caminar

	El minotauro camina por el fondo del cráter: cuando alguien le da de comer
	va hasta esa orilla (se para a una distancia según su tamaño, para que la
	boca quede cerca de quien lo alimenta); si no, pasea entre los lugares de su
	rutina (Minotauro/Rutina) a paso tranquilo (gait: fracción de su velocidad).
	Acelera, frena al llegar y da pasos del largo de su zancada (crece con la etapa).
		offset    dónde está, en el plano, respecto del centro del cráter
		speed     studs/s actuales
		phase     fase de los pasos (rad): cada media vuelta pisa una pata
	update devuelve cuánto está caminando (0..1), hacia dónde va (o nil) y si
	acaba de pisar; con anchor (de dónde salió el paseo) la fase de los pasos se
	acomoda de a poco a la distancia recorrida desde ahí, así todos los clientes
	ven las mismas piernas aunque hayan empezado a mirarlo en otro momento. turn gira hacia un ángulo sin pasar de su velocidad de giro
	(turnSpeed, rad/s) y devuelve cuánto giró y cuánto está girando (0..1, para
	los pasitos). angleTowards: el ángulo de CFrame.Angles(0, y, 0) que mira hacia d.
]]

local WorldLayout = require(script.Parent.Parent.WorldLayout)

export type Caminar = { offset: Vector3, speed: number, phase: number }

local SHORE_GAP = 14 -- studs entre la orilla y los pies cuando come
local REACH = 0.38 -- además, se queda este tanto de su alto lejos (la boca llega)
local BRAKE = 0.9 -- 1/s: cerca del destino quiere ir a BRAKE * distancia studs/s
local ACCEL = 2.5 -- 1/s: qué tan rápido alcanza la velocidad que quiere
local ARRIVED = 0.3 -- studs: ya llegó
local PHASE_SYNC = 1.5 -- rad/s como mucho que corrige la fase de los pasos hacia la de anchor

local Caminar = {}

function Caminar.new(): Caminar
	return { offset = Vector3.zero, speed = 0, phase = 0 }
end

-- Radio libre: hasta dónde puede ir sin salirse del fondo (el mismo de la orilla donde come).
local function freeRadius(height: number): number
	return math.max(WorldLayout.craterLakeRadius - SHORE_GAP - height * REACH, 0)
end

-- Dónde se para para comer, mirando hacia `direction` (unitaria, en el plano).
function Caminar.standFor(direction: Vector3, height: number): Vector3
	return direction * freeRadius(height)
end

-- Hasta dónde pasea: `roam` (0..1) del radio libre. Los grandes tienen menos lugar.
function Caminar.roamRadius(height: number, roam: number): number
	return freeRadius(height) * roam
end

-- Velocidad máxima (studs/s): los grandes dan pasos más largos.
local function topSpeed(height: number): number
	return 4 + height * 0.2
end

-- Cuánto tarda en recorrer `distance` y frenar (s), con la misma cuenta que update.
function Caminar.eta(distance: number, height: number, gait: number): number
	if distance < ARRIVED then
		return 0
	end
	local cruise = topSpeed(height) * gait
	local braking = cruise / BRAKE -- desde aquí frena: la distancia cae como exp(-BRAKE t)
	local tail = math.log(math.min(distance, braking) / ARRIVED) / BRAKE
	return math.max(distance - braking, 0) / cruise + tail + 1 / ACCEL
end

function Caminar.update(
	c: Caminar,
	dt: number,
	goal: Vector3,
	height: number,
	gait: number?,
	anchor: Vector3?
): (number, Vector3?, boolean)
	local top = topSpeed(height) * (gait or 1)
	local stride = math.max(height * 0.32, 2)
	local delta = goal - c.offset
	local distance = delta.Magnitude
	-- Frena al acercarse (llega sin pasarse) y acelera de a poco. Paseando da los
	-- mismos pasos largos, pero más despacio: lo que devuelve vale 1 a su velocidad
	-- de crucero (top con el gait).
	local want = math.min(top, distance * BRAKE)
	if distance < ARRIVED then
		want = 0
	end
	c.speed += (want - c.speed) * (1 - math.exp(-dt * ACCEL))
	local heading: Vector3? = nil
	if distance > 0.05 and c.speed > 0.05 then
		heading = delta.Unit
		c.offset += heading * math.min(c.speed * dt, distance)
	end
	-- Paseando, los pasos salen de lo recorrido desde anchor (igual en todos los clientes):
	-- casi quieto (las piernas casi no se mueven) salta a esa fase; andando, se acomoda.
	local synced = if anchor then (c.offset - anchor).Magnitude / stride * math.pi else nil
	if synced and c.speed < top * 0.15 then
		c.phase = synced
	end
	local before = math.floor(c.phase / math.pi)
	c.phase += c.speed * dt / stride * math.pi
	if synced and c.speed > 0.05 then
		local off = (synced - c.phase + math.pi) % (math.pi * 2) - math.pi
		c.phase += math.clamp(off, -dt * PHASE_SYNC, dt * PHASE_SYNC)
	end
	local stepped = math.floor(c.phase / math.pi) ~= before
	return math.clamp(c.speed / top * 1.4, 0, 1), heading, stepped
end

function Caminar.angleTowards(d: Vector3): number
	return math.atan2(-d.X, -d.Z) -- Angles(0, y, 0) mira a (-sin y, 0, -cos y)
end

function Caminar.turn(yaw: number, target: number, turnSpeed: number, dt: number): (number, number)
	local delta = (target - yaw + math.pi) % (math.pi * 2) - math.pi
	local turn = math.clamp(delta * 3, -turnSpeed, turnSpeed) * dt
	return turn, math.clamp(math.abs(turn / dt) / turnSpeed * 1.6, 0, 1)
end

return table.freeze(Caminar)
