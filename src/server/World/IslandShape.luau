--!strict
--[[
	IslandShape

	Forma del mundo como campo de alturas: para cada punto (x, z) devuelve la
	altura del suelo, su material y hasta dónde llega el agua. TerrainBuilder
	la convierte en vóxeles. Todo sale de WorldLayout, igual que las piezas de
	tools/generar_isla.py.

	Isla principal: meseta de pasto, playa, plaza de piedra con 10 estanques
	de entrenamiento, caminos, lomas, rocas y el promontorio del faro.
	Cráter del Abismo: lago profundo de basalto, acantilado interior, anillo
	volcánico con grietas de lava y ladera exterior hacia el mar.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)

local L = WorldLayout
local MATERIAL = Enum.Material
local PATH_HALF_WIDTH = 4.5
local POND_RIM_WIDTH = 1.6

local IslandShape = {}

-- Perfil de la isla principal. Misma curva que altura_terreno() en generar_isla.py.
function IslandShape.baseHeight(radius: number): number
	if radius <= L.plateauRadius then
		return L.plateauHeight
	elseif radius <= L.beachEndRadius then
		local t = (radius - L.plateauRadius) / (L.beachEndRadius - L.plateauRadius)
		return L.plateauHeight + (L.beachEndHeight - L.plateauHeight) * t
	elseif radius <= L.shelfRadius then
		local t = (radius - L.beachEndRadius) / (L.shelfRadius - L.beachEndRadius)
		return L.beachEndHeight + (L.seaFloorHeight - L.beachEndHeight) * t
	end
	return L.seaFloorHeight
end

-- Perfil del cráter según la distancia a su centro. Misma curva que altura_crater().
function IslandShape.craterHeight(rho: number): number?
	if rho >= L.craterBaseRadius then
		return nil
	elseif rho < L.craterLakeRadius then
		return L.craterFloor + (rho / L.craterLakeRadius) ^ 2 * L.craterBowlRise -- cuenco
	elseif rho < L.craterCliffRadius then
		local t = (rho - L.craterLakeRadius) / (L.craterCliffRadius - L.craterLakeRadius)
		local foot = L.craterFloor + L.craterBowlRise
		return foot + (L.craterRimHeight - foot) * t
	elseif rho < L.craterRimOuter then
		return L.craterRimHeight
	end
	local t = (rho - L.craterRimOuter) / (L.craterBaseRadius - L.craterRimOuter)
	return L.craterRimHeight + (L.seaFloorHeight - L.craterRimHeight) * t
end

local function polar(angleDegrees: number, radius: number): Vector2
	local a = math.rad(angleDegrees)
	return Vector2.new(math.cos(a), math.sin(a)) * radius
end

-- Caminos de piedra: de la plaza hacia cada destino.
local PATHS: { { Vector2 } } = {}
local function addPath(angle: number, toRadius: number)
	table.insert(PATHS, { polar(angle, L.plazaRadius - 2), polar(angle, toRadius) })
end
addPath(L.spawnAngle, L.spawnRadius + 6)
addPath(L.shopAngle, L.shopRadius - 4)
addPath(L.campAngle, L.campRadius - 8)
addPath(L.lighthouseAngle, L.plateauRadius - 2)
addPath(L.bridgeAngle, L.bridgeStartRadius + 4)
for _, angle in L.pierAngles do
	addPath(angle, L.pierStartRadius + 2)
end

local LIGHTHOUSE = polar(L.lighthouseAngle, L.lighthouseRadius)
local CRATER = Vector2.new(L.craterCenter[1], L.craterCenter[2])

local PONDS: { { center: Vector2, radius: number } } = {}
for index = 1, WorldZones.SACRED_POND do
	local center = WorldZones.pondCenter(index)
	PONDS[index] =
		{ center = Vector2.new(center.X, center.Z), radius = WorldZones.pondRadius(index) }
end

local function distanceToSegment(point: Vector2, a: Vector2, b: Vector2): number
	local ab = b - a
	local t = math.clamp((point - a):Dot(ab) / ab:Dot(ab), 0, 1)
	return (point - (a + ab * t)).Magnitude
end

local function mainIsland(point: Vector2): (number, Enum.Material, number)
	local radius = point.Magnitude
	local height = IslandShape.baseHeight(radius)
	local material = if radius <= L.plateauRadius - 2 then MATERIAL.Grass else MATERIAL.Sand
	local waterTop = L.waterLevel

	for _, hill in L.hills do
		local d = (point - Vector2.new(hill[1], hill[2])).Magnitude
		if d < hill[3] * 1.6 then
			local bump = L.plateauHeight
				+ hill[3] * 0.55 * math.cos(d / (hill[3] * 1.6) * math.pi / 2)
			if bump > height then
				height, material = bump, MATERIAL.Grass
			end
		end
	end
	for _, rock in L.shoreRocks do
		local center = Vector2.new(rock[1], rock[2])
		local d = (point - center).Magnitude
		if d < rock[3] then
			local top = IslandShape.baseHeight(center.Magnitude)
				+ rock[3] * 0.8 * (1 - (d / rock[3]) ^ 2)
			if top > height then
				height, material = top, MATERIAL.Rock
			end
		end
	end
	local fromLighthouse = (point - LIGHTHOUSE).Magnitude
	if fromLighthouse < L.lighthouseMoundRadius then
		local t = math.clamp(
			(L.lighthouseMoundRadius - fromLighthouse) / (L.lighthouseMoundRadius - 9),
			0,
			1
		)
		local top = L.waterLevel - 3 + t * (L.lighthouseBaseHeight - L.waterLevel + 3)
		if top > height then
			height = top
			material = if fromLighthouse < 9 then MATERIAL.Grass else MATERIAL.Rock
		end
	end

	if radius <= L.plazaRadius then
		material = MATERIAL.Cobblestone
		-- Estanques de entrenamiento: borde de piedra y fondo de arena con agua propia.
		for _, pond in PONDS do
			local d = (point - pond.center).Magnitude
			if d < pond.radius then
				local bowl = (d / pond.radius) ^ 2
				height = L.trainingPondFloor
					+ bowl * (L.trainingPondWaterTop - L.trainingPondFloor - 0.6)
				material, waterTop = MATERIAL.Sand, L.trainingPondWaterTop
			elseif d < pond.radius + POND_RIM_WIDTH then
				material = MATERIAL.Slate
			end
		end
	elseif radius <= L.plateauRadius then
		for _, path in PATHS do
			if distanceToSegment(point, path[1], path[2]) <= PATH_HALF_WIDTH then
				material = MATERIAL.Cobblestone
				break
			end
		end
	end
	return height, material, waterTop
end

-- Grietas de lava en el anillo: un patrón de vetas según el ángulo y la distancia.
local function lavaVein(offset: Vector2): boolean
	local angle = math.atan2(offset.Y, offset.X)
	local rho = offset.Magnitude
	return math.sin(angle * 11 + rho * 0.35) + math.sin(angle * 5 - rho * 0.2) > 1.55
end

function IslandShape.sample(x: number, z: number): (number, Enum.Material, number)
	local point = Vector2.new(x, z)
	local height, material, waterTop = mainIsland(point)
	local offset = point - CRATER
	local crater = IslandShape.craterHeight(offset.Magnitude)
	if crater and crater > height then
		height = crater
		local rho = offset.Magnitude
		if rho >= L.craterRimOuter then
			material = MATERIAL.Rock
		elseif rho >= L.craterCliffRadius and lavaVein(offset) then
			material = MATERIAL.CrackedLava
		else
			material = MATERIAL.Basalt
		end
	end
	return height, material, waterTop
end

return IslandShape
