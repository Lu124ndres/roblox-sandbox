--!strict
--[[
	LakeShape

	La forma del lago del cráter según el gigante: el cuenco de siempre o, para
	los que tienen GiantDef.deepLake (la orca), el lago hondo y plano a
	deepLakeFloor (WorldZones.lakeFloor con deep). TerrainBuilder arma el cuenco;
	aquí se reescriben solo los bloques del lago, repartidos en varios cuadros,
	cuando cambia la forma. Lo llama HabitatService al armar el hábitat del que
	llega, cuando el cráter se llena para él: el agua del servidor vuelve con la forma
	nueva y cada cliente la saca o la llena como siempre (CraterGuard, LakeFill).
	Se publica en EstadoGigante.LagoHondo.
		set(deep)
		isDeep() -> boolean
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local CraterShape = require(script.Parent.CraterShape)
local GiantPublish = require(script.Parent.Parent.Feeding.GiantPublish)
local IslandShape = require(script.Parent.IslandShape)
local TerrainVoxels = require(script.Parent.TerrainVoxels)

local L = WorldLayout
local VOXEL = TerrainVoxels.VOXEL
local COLUMNS = 16 -- columnas por lado de cada bloque (bloques chicos: el lago es hondo)
local FLOOR_Y = L.deepLakeFloor - 2 * VOXEL -- la roca baja hasta aquí en las dos formas
local FRAME_BUDGET = 0.015

local LakeShape = {}

local deepNow = false
local generation = 0

function LakeShape.isDeep(): boolean
	return deepNow
end

function LakeShape.set(deep: boolean)
	if deep == deepNow then
		return
	end
	deepNow = deep
	generation += 1
	local mine = generation
	GiantPublish.set(Protocol.GiantAttributes.DeepLake, deep)
	local terrain = Workspace.Terrain
	local size = COLUMNS * VOXEL
	local reach = math.ceil((L.craterLakeRadius + VOXEL) / size) * size
	local cx = math.floor(L.craterCenter[1] / size) * size
	local cz = math.floor(L.craterCenter[2] / size) * size
	local started = os.clock()
	for x0 = cx - reach, cx + reach - size, size do
		for z0 = cz - reach, cz + reach - size, size do
			if mine ~= generation then
				return -- otro cambio empezó: ese reescribe todo
			end
			if not IslandShape.touchesCrater(x0, z0, size, true) then
				continue
			end
			local chunk = TerrainVoxels.build(x0, z0, COLUMNS, function(x: number, z: number)
				return CraterShape.onSea(x, z, true, deep)
			end, FLOOR_Y)
			local region = Region3.new(
				Vector3.new(x0, chunk.yMin, z0),
				Vector3.new(x0 + size, chunk.yMax, z0 + size)
			)
			-- Primero aire: escribir Agua sobre un vóxel con roca a medias deja la roca
			-- (Roblox guarda el agua aparte y solo llena lo que queda libre).
			terrain:FillRegion(region, VOXEL, Enum.Material.Air)
			terrain:WriteVoxels(region, VOXEL, chunk.materials, chunk.occupancies)
			if os.clock() - started >= FRAME_BUDGET then
				task.wait()
				started = os.clock()
			end
		end
	end
end

return LakeShape
