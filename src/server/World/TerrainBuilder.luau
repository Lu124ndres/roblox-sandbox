--!strict
--[[
	TerrainBuilder

	Construye el terreno del mundo: océano de agua real (olas, reflejos, se
	puede nadar), isla principal con lomas, plaza, caminos y estanques de
	entrenamiento, promontorio del faro y el Cráter del Abismo del gigante.

	Escribe los vóxeles directamente (WriteVoxels) con la ocupación exacta de
	cada uno. Las funciones Fill redondean a la cuadrícula de 4 studs y dejaban
	el suelo hasta 4 studs más alto que las piezas de madera.

	El terreno no se puede guardar en un archivo de Rojo, así que se genera al
	arrancar el servidor. Para verlo en modo Edit, en la barra de comandos:
		require(game.ServerScriptService.Server.World.TerrainBuilder).build()
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local IslandShape = require(script.Parent.IslandShape)

local L = WorldLayout
local MATERIAL = Enum.Material
local VOXEL = 4
local HALF = VOXEL / 2
local Y_MIN = -40 -- más abajo solo donde el suelo baja (el lago hondo del cráter)
local Y_MAX = 40 -- más arriba solo donde hay montañas (el anillo del cráter)
local CHUNK_VOXELS = 32 -- columnas por lado en cada bloque escrito

local TerrainBuilder = {}

local function style(terrain: Terrain)
	terrain.WaterColor = Color3.fromRGB(28, 168, 184)
	terrain.WaterTransparency = 0.65
	terrain.WaterReflectance = 0.55
	terrain.WaterWaveSize = 0.22
	terrain.WaterWaveSpeed = 14
	terrain:SetMaterialColor(MATERIAL.Grass, Color3.fromRGB(108, 176, 74))
	terrain:SetMaterialColor(MATERIAL.Sand, Color3.fromRGB(222, 198, 148))
	terrain:SetMaterialColor(MATERIAL.Cobblestone, Color3.fromRGB(126, 118, 108))
	terrain:SetMaterialColor(MATERIAL.Rock, Color3.fromRGB(122, 126, 134))
	terrain:SetMaterialColor(MATERIAL.Basalt, Color3.fromRGB(42, 38, 46))
	terrain:SetMaterialColor(MATERIAL.CrackedLava, Color3.fromRGB(255, 96, 40))
	terrain:SetMaterialColor(MATERIAL.Slate, Color3.fromRGB(150, 150, 156))
	-- Fondo claro del lago del cráter: bajo el agua se ve turquesa (y el gigante resalta).
	terrain:SetMaterialColor(MATERIAL.Limestone, Color3.fromRGB(70, 118, 112))
	terrain:SetMaterialColor(MATERIAL.Asphalt, Color3.fromRGB(58, 46, 48)) -- cumbres del volcán
	if not terrain:FindFirstChildOfClass("Clouds") then
		local clouds = Instance.new("Clouds")
		clouds.Cover = 0.55
		clouds.Density = 0.6
		clouds.Parent = terrain
	end
end

type Sample = { height: number, material: Enum.Material, water: number }

local function writeChunk(terrain: Terrain, x0: number, z0: number, columns: number)
	-- Primero las alturas: el piso de este bloque baja hasta su punto más hondo.
	local samples: { { Sample } } = {}
	local yMin, yMax = Y_MIN, Y_MAX
	for ix = 1, columns do
		samples[ix] = {}
		for iz = 1, columns do
			local height, material, waterTop =
				IslandShape.sample(x0 + (ix - 0.5) * VOXEL, z0 + (iz - 0.5) * VOXEL)
			samples[ix][iz] = { height = height, material = material, water = waterTop }
			yMin = math.min(yMin, math.floor(height / VOXEL) * VOXEL - VOXEL)
			yMax = math.max(yMax, math.ceil(height / VOXEL) * VOXEL + VOXEL)
		end
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
	local size = columns * VOXEL
	local region = Region3.new(Vector3.new(x0, yMin, z0), Vector3.new(x0 + size, yMax, z0 + size))
	terrain:WriteVoxels(region, VOXEL, materials, occupancies)
end

function TerrainBuilder.build()
	local terrain = Workspace.Terrain
	terrain:Clear()
	style(terrain)
	local half = math.ceil(L.oceanHalfSize / (VOXEL * CHUNK_VOXELS)) * VOXEL * CHUNK_VOXELS
	local step = VOXEL * CHUNK_VOXELS
	for x0 = -half, half - step, step do
		for z0 = -half, half - step, step do
			writeChunk(terrain, x0, z0, CHUNK_VOXELS)
			task.wait() -- reparte el trabajo para no congelar el servidor
		end
	end
end

return TerrainBuilder
