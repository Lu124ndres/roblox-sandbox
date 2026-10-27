--!strict
--[[
	TerrainVoxels

	Los vóxeles de un bloque cuadrado de terreno según una forma (para
	Terrain:WriteVoxels), con la ocupación exacta de cada uno: las funciones Fill
	redondean a la cuadrícula de 4 studs y dejaban el suelo hasta 4 studs más alto
	que las piezas de madera. Lo usan TerrainBuilder (todo el mundo) y LakeShape
	(solo el lago del cráter, al cambiar de gigante).
		build(x0, z0, columns, shapeAt, floorY?) -> Voxels
	floorY: escribe roca desde ahí aunque el suelo esté más arriba (al rehacer el
	lago hay que rellenar el hueco del lago hondo).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)

local L = WorldLayout
local MATERIAL = Enum.Material
local VOXEL = 4
local HALF = VOXEL / 2
local Y_MIN = -40 -- más abajo solo donde el suelo baja (el lago hondo del cráter)
local Y_MAX = 40 -- más arriba solo donde hay montañas (el anillo del cráter)

export type Sampler = (x: number, z: number) -> (number, Enum.Material, number)
export type Voxels = { yMin: number, yMax: number, materials: { any }, occupancies: { any } }
type Sample = { height: number, material: Enum.Material, water: number }

local TerrainVoxels = {}

TerrainVoxels.VOXEL = VOXEL

function TerrainVoxels.build(
	x0: number,
	z0: number,
	columns: number,
	shapeAt: Sampler,
	floorY: number?
): Voxels
	-- Primero las alturas: el piso de este bloque baja hasta su punto más hondo.
	local samples: { { Sample } } = {}
	local yMin, yMax = Y_MIN, Y_MAX
	if floorY then
		yMin = math.min(yMin, math.floor(floorY / VOXEL) * VOXEL)
	end
	local openSea = floorY == nil -- todo el bloque es fondo de mar plano (lejos de la isla y el volcán)
	for ix = 1, columns do
		samples[ix] = {}
		for iz = 1, columns do
			local height, material, waterTop =
				shapeAt(x0 + (ix - 0.5) * VOXEL, z0 + (iz - 0.5) * VOXEL)
			samples[ix][iz] = { height = height, material = material, water = waterTop }
			yMin = math.min(yMin, math.floor(height / VOXEL) * VOXEL - VOXEL)
			yMax = math.max(yMax, math.ceil(height / VOXEL) * VOXEL + VOXEL)
			openSea = openSea and height <= L.seaFloorHeight
		end
	end
	if openSea then
		-- Mar abierto: una capa de fondo bajo el agua alcanza (nadie ve la roca de más
		-- abajo) y arriba del agua solo hay aire. Casi la mitad de vóxeles en el mar.
		yMin = math.floor(L.seaFloorHeight / VOXEL) * VOXEL - VOXEL
		yMax = math.ceil(L.waterLevel / VOXEL) * VOXEL + VOXEL
	end
	local rows = (yMax - yMin) / VOXEL
	local materials, occupancies = {}, {}
	for ix = 1, columns do
		local materialPlane, occupancyPlane = {}, {}
		materials[ix], occupancies[ix] = materialPlane, occupancyPlane
		for iy = 1, rows do
			materialPlane[iy], occupancyPlane[iy] = {}, {}
		end
		for iz = 1, columns do
			local sample = samples[ix][iz]
			local height, material, waterTop = sample.height, sample.material, sample.water
			for iy = 1, rows do
				-- Medido en Studio: la superficie del suelo queda en el centro del vóxel
				-- + ocupación x VOXEL (por eso se resta medio vóxel), y la del agua en
				-- la base + ocupación x VOXEL. Así las alturas del diseño
				-- (WorldLayout) son las que se ven.
				local bottom = yMin + (iy - 1) * VOXEL
				local solid = math.clamp((height - bottom - HALF) / VOXEL, 0, 1)
				if solid > 0 then
					materialPlane[iy][iz], occupancyPlane[iy][iz] = material, solid
				elseif bottom < waterTop then
					materialPlane[iy][iz] = MATERIAL.Water
					occupancyPlane[iy][iz] = math.clamp((waterTop - bottom) / VOXEL, 0, 1)
				else
					materialPlane[iy][iz], occupancyPlane[iy][iz] = MATERIAL.Air, 0
				end
			end
		end
	end
	return { yMin = yMin, yMax = yMax, materials = materials, occupancies = occupancies }
end

return table.freeze(TerrainVoxels)
