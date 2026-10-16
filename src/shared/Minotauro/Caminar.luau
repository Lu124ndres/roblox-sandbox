--!strict
--[[
	Minotauro/Caminar

	El minotauro camina por el lago: cuando alguien le da de comer va hasta esa
	orilla (se para a una distancia según su tamaño, para que la boca quede cerca
	de quien lo alimenta) y cuando dejan de darle vuelve al centro. Acelera,
	frena al llegar y da pasos del largo de su zancada (crece con la etapa).
		offset    dónde está, en el plano, respecto del centro del cráter
		speed     studs/s actuales
		phase     fase de los pasos (rad): cada media vuelta pisa una pata
	update devuelve cuánto está caminando (0..1), hacia dónde va (o nil) y si
	acaba de pisar.
]]

local WorldLayout = require(script.Parent.Parent.WorldLayout)

export type Caminar = { offset: Vector3, speed: number, phase: number }

local SHORE_GAP = 14 -- studs entre la orilla y los pies cuando come
local REACH = 0.38 -- además, se queda este tanto de su alto lejos (la boca llega)

local Caminar = {}

function Caminar.new(): Caminar
	return { offset = Vector3.zero, speed = 0, phase = 0 }
end

-- Dónde se para para comer, mirando hacia `direction` (unitaria, en el plano).
function Caminar.standFor(direction: Vector3, height: number): Vector3
	local radius = WorldLayout.craterLakeRadius - SHORE_GAP - height * REACH
	return direction * math.max(radius, 0)
end

function Caminar.update(
	c: Caminar,
	dt: number,
	goal: Vector3,
	height: number
): (number, Vector3?, boolean)
	local top = 4 + height * 0.2 -- studs/s: los grandes dan pasos más largos
	local stride = math.max(height * 0.32, 2)
	local delta = goal - c.offset
	local distance = delta.Magnitude
	-- Frena al acercarse (llega sin pasarse) y acelera de a poco.
	local want = math.min(top, distance * 0.9)
	if distance < 0.3 then
		want = 0
	end
	c.speed += (want - c.speed) * (1 - math.exp(-dt * 2.5))
	local heading: Vector3? = nil
	if distance > 0.05 and c.speed > 0.05 then
		heading = delta.Unit
		c.offset += heading * math.min(c.speed * dt, distance)
	end
	local before = math.floor(c.phase / math.pi)
	c.phase += c.speed * dt / stride * math.pi
	local stepped = math.floor(c.phase / math.pi) ~= before
	return math.clamp(c.speed / top * 1.4, 0, 1), heading, stepped
end

return table.freeze(Caminar)
