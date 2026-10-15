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
-- clara y poco honda junto al acantilado y, hacia el centro, un pozo hondo.
-- Misma curva que fondo_lago() en tools/generar_isla.py.
function WorldZones.lakeFloor(radius: number): number
	local shelfStart = L.craterLakeRadius - L.craterShelfWidth
	local shelf = L.waterLevel - L.craterShelfDepth
	if radius >= shelfStart then
		local t = math.min((radius - shelfStart) / L.craterShelfWidth, 1)
		return shelf + (L.craterShelfDepth - 3) * t
	end
	local t = radius / shelfStart
	return L.craterFloor + (shelf - L.craterFloor) * (1 - math.cos(math.pi * t)) / 2
end

-- Distancia horizontal al centro de la isla principal.
function WorldZones.distanceToIsland(position: Vector3): number
	return flat(position).Magnitude
end

-- Estanques: 1..trainingPondCount en círculo y, después, el sagrado en el centro.
WorldZones.SACRED_POND = L.trainingPondCount + 1

-- Centro del estanque número index, a la altura del agua.
-- El 1 y el último del círculo quedan a los lados del camino que llega desde la aparición.
function WorldZones.pondAngle(index: number): number
	local step = 360 / L.trainingPondCount
	return L.spawnAngle + step / 2 + (index - 1) * step
end

function WorldZones.pondCenter(index: number): Vector3
	if index >= WorldZones.SACRED_POND then
		return Vector3.new(0, L.trainingPondWaterTop, 0)
	end
	local angle = math.rad(WorldZones.pondAngle(index))
	local radius = L.trainingPondRingRadius
	return Vector3.new(math.cos(angle) * radius, L.trainingPondWaterTop, math.sin(angle) * radius)
end

function WorldZones.pondRadius(index: number): number
	return if index >= WorldZones.SACRED_POND then L.sacredPondRadius else L.trainingPondRadius
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

-- Guarida del descanso: la plataforma que emerge en el centro del lago. Solo ahí
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
