--!strict
--[[
	GardenShape

	Terreno de la zona de entrenamiento (todo lo que queda dentro de plazaRadius):
	un jardín de pasto con senderos de arena y estanques naturales.
		- un sendero en anillo por fuera de los estanques (gardenRingRadius), donde
		  desembocan los caminos de la isla;
		- senderos rectos hacia el centro, entre estanque y estanque
		  (gardenSpokeAngles), y un claro de arena alrededor del sagrado;
		- cada estanque es una hoya de barro con agua propia, de orilla ondulada
		  (WorldZones.pondEdge), con una franja de barro alrededor.
	Los bordes de los senderos ondulan un poco: no parecen trazados con regla. Son de
	arena (no de Ground: la guarida de lava le cambia el color a ese material). El pasto
	es LeafyGrass, no Grass: Roblox le pone pasto alto encima a Grass y tapaba los estanques.
	Las piezas del jardín (rocas, nenúfares, juncos, árboles) salen de tools/estanques.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)

local L = WorldLayout
local MATERIAL = Enum.Material
local PATH_WIGGLE = 0.6 -- cuánto ondula el borde de los senderos (studs)
local BOWL_LIP = 0.6 -- la hoya llega a la orilla así de bajo el agua

local GardenShape = {}

local PONDS: { Vector2 } = {}
for index = 1, WorldZones.SACRED_POND do
	if WorldZones.pondExists(index) then -- los quitados quedan como pasto
		local center = WorldZones.pondCenter(index)
		PONDS[index] = Vector2.new(center.X, center.Z)
	end
end

local SPOKES: { { Vector2 } } = {}
for _, angle in L.gardenSpokeAngles do
	local direction = Vector2.new(math.cos(math.rad(angle)), math.sin(math.rad(angle)))
	table.insert(SPOKES, { direction * L.gardenClearingRadius, direction * L.gardenRingRadius })
end

local function distanceToSegment(point: Vector2, a: Vector2, b: Vector2): number
	local ab = b - a
	local t = math.clamp((point - a):Dot(ab) / ab:Dot(ab), 0, 1)
	return (point - (a + ab * t)).Magnitude
end

local function onPath(point: Vector2): boolean
	local wiggle = (math.sin(point.X * 0.21) + math.sin(point.Y * 0.17)) * PATH_WIGGLE / 2
	local half = L.gardenPathHalfWidth + wiggle
	local radius = point.Magnitude
	if
		math.abs(radius - L.gardenRingRadius) <= half
		or radius <= L.gardenClearingRadius + wiggle
	then
		return true
	end
	for _, spoke in SPOKES do
		if distanceToSegment(point, spoke[1], spoke[2]) <= half then
			return true
		end
	end
	return false
end

-- Altura del suelo, material y tope del agua de un punto del jardín; `height` es la
-- altura de la meseta en ese punto.
function GardenShape.sample(point: Vector2, height: number): (number, Enum.Material, number)
	local material = if onPath(point) then MATERIAL.Sand else MATERIAL.LeafyGrass
	for index, center in PONDS do
		local offset = point - center
		local distance = offset.Magnitude
		local edge = WorldZones.pondEdge(index, math.atan2(offset.Y, offset.X))
		if distance < edge then
			local bowl = (distance / edge) ^ 2
			local depth = L.trainingPondWaterTop - L.trainingPondFloor - BOWL_LIP
			return L.trainingPondFloor + bowl * depth, MATERIAL.Mud, L.trainingPondWaterTop
		elseif distance < edge + L.pondBankWidth then
			material = MATERIAL.Mud
		end
	end
	return height, material, L.waterLevel
end

return GardenShape
