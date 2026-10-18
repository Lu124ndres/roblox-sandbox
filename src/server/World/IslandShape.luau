--!strict
--[[
	IslandShape

	Forma del mundo como campo de alturas: para cada punto (x, z) devuelve la
	altura del suelo, su material y hasta dónde llega el agua. TerrainBuilder
	la convierte en vóxeles. Todo sale de WorldLayout, igual que las piezas de
	tools/generar_isla.py.

	Isla principal: meseta de pasto, playa, el jardín de entrenamiento con sus
	estanques naturales (GardenShape), caminos, lomas, rocas y el promontorio del faro.
	Cráter del Abismo: su forma está en CraterShape (lago, acantilado, paseo,
	montañas con vetas de lava y ladera hacia el mar).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local CraterShape = require(script.Parent.CraterShape)
local GardenShape = require(script.Parent.GardenShape)

local L = WorldLayout
local MATERIAL = Enum.Material
local PATH_HALF_WIDTH = 4.5

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

local function polar(angleDegrees: number, radius: number): Vector2
	local a = math.rad(angleDegrees)
	return Vector2.new(math.cos(a), math.sin(a)) * radius
end

-- Caminos de piedra: del jardín de entrenamiento hacia cada destino.
local PATHS: { { Vector2 } } = {}
local function addPath(angle: number, toRadius: number)
	table.insert(PATHS, { polar(angle, L.plazaRadius - 2), polar(angle, toRadius) })
end
addPath(L.spawnAngle, L.plateauRadius - 2) -- por el arco de la entrada, a la playa
addPath(L.shopAngle, L.shopRadius - 4)
addPath(L.campAngle, L.campRadius - 8)
addPath(L.lighthouseAngle, L.plateauRadius - 2)
addPath(L.bridgeAngle, L.bridgeStartRadius + 4)

local LIGHTHOUSE = polar(L.lighthouseAngle, L.lighthouseRadius)
local CRATER = Vector2.new(L.craterCenter[1], L.craterCenter[2])

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
			material = if fromLighthouse < 10 then MATERIAL.Cobblestone else MATERIAL.Rock -- sin pasto alto: se ve la puerta
		end
	end

	if radius <= L.plazaRadius then
		return GardenShape.sample(point, height)
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

function IslandShape.sample(x: number, z: number): (number, Enum.Material, number)
	local point = Vector2.new(x, z)
	local height, material, waterTop = mainIsland(point)
	local offset = point - CRATER
	local rho, angle = offset.Magnitude, math.atan2(offset.Y, offset.X)
	local crater = CraterShape.height(rho, angle)
	-- Dentro del acantilado manda el cráter aunque sea más hondo que el fondo del mar.
	if crater and (crater > height or rho < L.craterCliffRadius) then
		height, material = crater, CraterShape.material(rho, angle, crater)
	end
	return height, material, waterTop
end

return IslandShape
