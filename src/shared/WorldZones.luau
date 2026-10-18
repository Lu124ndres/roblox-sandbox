--!strict
--[[
	WorldZones

	Preguntas de geometría que hacen servidor y cliente: dónde está el centro
	del cráter, si un punto está dentro de la zona del gigante y dónde queda
	cada estanque de entrenamiento. Todo calculado desde WorldLayout.
]]

local WorldLayout = require(script.Parent.WorldLayout)

local L = WorldLayout

local WorldZones = {}

WorldZones.craterCenter = Vector3.new(L.craterCenter[1], 0, L.craterCenter[2])

local function flat(position: Vector3): Vector3
	return Vector3.new(position.X, 0, position.Z)
end

-- Distancia horizontal al centro del cráter.
function WorldZones.distanceToCrater(position: Vector3): number
	return (flat(position) - WorldZones.craterCenter).Magnitude
end

-- 0 fuera del cráter, 1 adentro; sube suave al cruzar el anillo (para la niebla).
function WorldZones.craterBlend(position: Vector3): number
	local distance = WorldZones.distanceToCrater(position)
	local inner, outer = L.craterRimOuter, L.craterBaseRadius + 40
	return math.clamp((outer - distance) / (outer - inner), 0, 1)
end

-- Altura del fondo del lago del cráter a `radius` del centro: una plataforma
-- poco honda junto al acantilado y, hacia el centro, un pozo hondo con el
-- fondo plano (la guarida del descanso, que se ve al vaciarse el volcán).
-- Misma curva que fondo_lago() en tools/generar_isla.py.
function WorldZones.lakeFloor(radius: number): number
	local shelfStart = L.craterLakeRadius - L.craterShelfWidth
	local shelf = L.waterLevel - L.craterShelfDepth
	if radius >= shelfStart then
		local t = math.min((radius - shelfStart) / L.craterShelfWidth, 1)
		return shelf + (L.craterShelfDepth - 3) * t
	end
	local t = math.max(radius - L.craterFlatRadius, 0) / (shelfStart - L.craterFlatRadius)
	return L.craterFloor + (shelf - L.craterFloor) * (1 - math.cos(math.pi * t)) / 2
end

-- Distancia horizontal al centro de la isla principal.
function WorldZones.distanceToIsland(position: Vector3): number
	return flat(position).Magnitude
end

-- Estanques: 1..trainingPondCount en círculo y, después, el sagrado en el centro.
WorldZones.SACRED_POND = L.trainingPondCount + 1

-- Centro del estanque número index, a la altura del agua (WorldLayout.pondPositions: los
-- más bajos cerca del puente al volcán, así el viaje a alimentar es corto).
function WorldZones.pondCenter(index: number): Vector3
	local spot = L.pondPositions[index]
	if index >= WorldZones.SACRED_POND or not spot then
		return Vector3.new(0, L.trainingPondWaterTop, 0)
	end
	return Vector3.new(spot[1], L.trainingPondWaterTop, spot[2])
end

-- Dónde se aparece (al nivel de la meseta).
function WorldZones.spawnPoint(): Vector3
	return Vector3.new(L.spawnPosition[1], L.plateauHeight, L.spawnPosition[2])
end

function WorldZones.pondRadius(index: number): number
	return if index >= WorldZones.SACRED_POND then L.sacredPondRadius else L.trainingPondRadius
end

-- Orilla natural: radio del agua del estanque `index` en la dirección `angle` (radianes,
-- medido como math.atan2(dz, dx) desde su centro). Ondula en 2, 3 y 5 lóbulos con una
-- fase propia por estanque, así ninguno es un círculo ni se parece al de al lado.
-- Misma fórmula que borde() en tools/estanques/forma.py.
function WorldZones.pondEdge(index: number, angle: number): number
	local wobble = L.pondWobble
	local shape = 1
		+ wobble[1] * math.sin(2 * angle + 1.7 * index)
		+ wobble[2] * math.sin(3 * angle + 2.9 * index)
		+ wobble[3] * math.sin(5 * angle + 0.8 * index)
	return WorldZones.pondRadius(index) * shape
end

-- El radio más grande que puede tener la orilla (para la tapa y los alcances).
function WorldZones.pondMaxRadius(index: number): number
	local wobble = L.pondWobble
	return WorldZones.pondRadius(index) * (1 + wobble[1] + wobble[2] + wobble[3])
end

-- Puente: del borde de la meseta a la puerta del cráter, en línea recta.
-- Misma geometría que puente() en tools/generar_isla.py.
function WorldZones.bridgeEnds(): (Vector3, Vector3)
	local direction =
		Vector3.new(math.cos(math.rad(L.bridgeAngle)), 0, math.sin(math.rad(L.bridgeAngle)))
	local start = direction * L.bridgeStartRadius + Vector3.new(0, L.deckHeight, 0)
	local finish = WorldZones.craterCenter
		- direction * (L.craterRimOuter - 2)
		+ Vector3.new(0, L.craterDeckHeight, 0)
	return start, finish
end

-- ¿Está sobre el puente? (para la corriente que acelera al jugador)
function WorldZones.isOnBridge(position: Vector3): boolean
	local start, finish = WorldZones.bridgeEnds()
	local along = finish - start
	local flatAlong = Vector3.new(along.X, 0, along.Z)
	local offset = Vector3.new(position.X - start.X, 0, position.Z - start.Z)
	local t = offset:Dot(flatAlong) / flatAlong:Dot(flatAlong)
	if t < -0.02 or t > 1.02 then
		return false
	end
	local lateral = (offset - flatAlong * t).Magnitude
	local deckY = start.Y + along.Y * math.clamp(t, 0, 1)
	return lateral <= L.bridgeWidth / 2 and math.abs(position.Y - deckY) < 8
end

-- Orilla del volcán: el borde del cráter (todo lo que está a la altura del borde y
-- dentro de su anillo exterior). Desde aquí se alimenta.
function WorldZones.isOnCraterShore(position: Vector3): boolean
	return WorldZones.distanceToCrater(position) <= L.craterRimOuter + 2
		and position.Y >= L.craterRimHeight - 4
		and position.Y <= L.craterRimHeight + 14
end

-- Guarida del descanso: la plataforma del fondo del volcán vacío. Solo ahí
-- se gana poder durante el descanso (las rampas no cuentan).
function WorldZones.isInRestArena(position: Vector3): boolean
	return WorldZones.distanceToCrater(position) <= L.restArenaRadius + 1
		and position.Y >= L.restArenaTop - 1
		and position.Y <= L.restArenaTop + 10
end

-- Dentro del cráter, por debajo del borde (la guarida): al terminar el descanso,
-- quien siga ahí sube al borde.
function WorldZones.isInCraterPit(position: Vector3): boolean
	return WorldZones.distanceToCrater(position) < L.craterCliffRadius
		and position.Y < L.craterRimHeight - 2
end

return table.freeze(WorldZones)
