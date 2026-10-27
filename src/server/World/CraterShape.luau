--!strict
--[[
	CraterShape

	Forma del Cráter del Abismo (el volcán del gigante) para el terreno:
		lago      plataforma clara y poco honda junto al acantilado (piedra
		          caliza: el agua se ve turquesa) y un pozo hondo de basalto en
		          el centro, donde se pierde la vista.
		acantilado pared casi vertical hasta el paseo.
		paseo     anillo plano a la altura del borde (desde aquí se alimenta).
		montañas  cumbres de basalto de alturas distintas alrededor, con vetas
		          de lava que bajan por las laderas; se abren en la puerta del
		          puente (ahí el camino sigue plano hasta la entrada).
		ladera    baja hasta el fondo del mar.
	Misma curva que altura_crater() en tools/generar_isla.py (piezas encima).
	onSea(x, z, lakeOnly) da el cráter sobre el mar abierto, sin la isla (la isla de bloques
	es de mallas); lakeOnly: solo el lago, porque el volcán de bloques (World/BlockVolcano)
	pone el acantilado, el paseo y la montaña, y el lago sigue siendo terreno (lo llenan el
	agua, la arena, la ceniza y el hielo).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)

local L = WorldLayout
local MATERIAL = Enum.Material
local GATE = math.rad(L.bridgeAngle + 180) -- del cráter hacia la isla
local RIDGE_END = 0.6 -- parte de la ladera exterior con montañas

local CraterShape = {}

local function smooth(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

-- 1 en la puerta del puente, 0 lejos de ella.
local function gate(angle: number): number
	local d = math.deg(math.abs((angle - GATE + math.pi) % (2 * math.pi) - math.pi))
	return 1 - smooth((d - 14) / 12)
end

-- Alto de las cumbres en esa dirección (varía alrededor del anillo).
local function peak(angle: number): number
	local shape = 0.55
		+ 0.3 * math.sin(5 * angle + 1.3)
		+ 0.15 * math.sin(11 * angle + 0.4)
		+ 0.08 * math.sin(23 * angle)
		+ 0.1 * math.abs(math.sin(37 * angle + 0.7)) -- picos filosos
	return L.craterPeakHeight * math.max(shape, 0.15) * (1 - gate(angle))
end

-- Altura del suelo a `rho` del centro en la dirección `angle` (radianes, atan2(z, x)).
function CraterShape.height(rho: number, angle: number, deep: boolean?): number?
	if rho >= L.craterBaseRadius then
		return nil
	elseif rho < L.craterLakeRadius then
		return WorldZones.lakeFloor(rho, deep)
	elseif rho < L.craterCliffRadius then
		local foot = WorldZones.lakeFloor(L.craterLakeRadius)
		local t = (rho - L.craterLakeRadius) / (L.craterCliffRadius - L.craterLakeRadius)
		return foot + (L.craterRimHeight - foot) * t ^ 0.6
	end
	local walkEnd = L.craterCliffRadius + L.craterWalkWidth
	if rho < walkEnd then
		return L.craterRimHeight
	end
	local t = (rho - walkEnd) / (L.craterBaseRadius - walkEnd)
	local slope = L.craterRimHeight + (L.seaFloorHeight - L.craterRimHeight) * t ^ 1.6
	local ridge = peak(angle) * math.sin(math.pi * math.min(t / RIDGE_END, 1)) ^ 1.3
	local height = slope + ridge
	if rho < L.craterRimOuter then -- en la puerta el camino sigue plano hasta la entrada
		height += (math.max(height, L.craterRimHeight) - height) * gate(angle)
	end
	return height
end

-- Vetas de lava: un patrón según el ángulo y la distancia.
local function lavaVein(angle: number, rho: number): boolean
	return math.sin(angle * 11 + rho * 0.35) + math.sin(angle * 5 - rho * 0.2) > 1.45
end

function CraterShape.material(rho: number, angle: number, height: number): Enum.Material
	if rho < L.craterLakeRadius then
		local shelfStart = L.craterLakeRadius - L.craterShelfWidth - 12
		return if rho >= shelfStart then MATERIAL.Limestone else MATERIAL.Basalt
	elseif rho < L.craterCliffRadius + L.craterWalkWidth then
		return MATERIAL.Basalt
	elseif height < L.waterLevel + 3 then
		return MATERIAL.Rock
	elseif lavaVein(angle, rho) then
		return MATERIAL.CrackedLava
	end
	return if height > L.craterRimHeight + L.craterPeakHeight * 0.55
		then MATERIAL.Asphalt
		else MATERIAL.Basalt
end

function CraterShape.onSea(
	x: number,
	z: number,
	lakeOnly: boolean,
	deep: boolean?
): (number, Enum.Material, number)
	local height, material, waterTop = L.seaFloorHeight, MATERIAL.Sand, L.waterLevel
	local offset = Vector2.new(x, z) - Vector2.new(L.craterCenter[1], L.craterCenter[2])
	local rho, angle = offset.Magnitude, math.atan2(offset.Y, offset.X)
	if lakeOnly and rho >= L.craterLakeRadius then
		-- Con el lago hondo se ve el costado de estas columnas (bajan hasta su fondo): basalto.
		return height, if deep then MATERIAL.Basalt else material, waterTop
	end
	local crater = CraterShape.height(rho, angle, deep)
	if crater and (crater > height or rho < L.craterCliffRadius) then
		height, material = crater, CraterShape.material(rho, angle, crater)
		if deep and rho < L.craterLakeRadius then
			material = MATERIAL.Basalt -- el lago hondo no tiene repisa clara: roca oscura
		end
	end
	return height, material, waterTop
end

return table.freeze(CraterShape)
