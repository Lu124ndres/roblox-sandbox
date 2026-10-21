--!strict
--[[
	TerrainBuilder

	Construye el terreno del mundo: océano de agua real (olas, reflejos, se
	puede nadar), isla principal con lomas, plaza, caminos y estanques de
	entrenamiento, promontorio del faro y el Cráter del Abismo del gigante.

	Escribe los vóxeles directamente (WriteVoxels) con la ocupación exacta de
	cada uno. Las funciones Fill redondean a la cuadrícula de 4 studs y dejaban
	el suelo hasta 4 studs más alto que las piezas de madera.

	El terreno no se puede guardar en un archivo de Rojo: se genera con este código y
	queda guardado en el lugar (PescaYAlimentaGigantes.rbxl) con su versión
	(TerrainVersion) en el atributo TerrenoVersion. Al arrancar, el servidor solo lo
	vuelve a construir si esa versión no es la de ahora (cambió WorldLayoutData o
	SHAPE_VERSION), y la pantalla de carga lo espera (Workspace.MundoListo).
	Para que construirlo tarde poco, los bloques de mar abierto (IslandShape.touches) no se
	muestrean: son todos iguales y sus vóxeles se calculan una vez. Además se escriben
	varios bloques por cuadro hasta FRAME_BUDGET (un bloque por cuadro tardaba 10 s solo
	en esperar cuadros: son 576 bloques).

	Para regenerarlo y guardarlo en el lugar (docs/setup.md), en Edit, en la barra de
	comandos, y después guardar y publicar:
		require(game.ServerScriptService.Server.World.TerrainBuilder).build(true)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local BlockIsland = require(script.Parent.BlockIsland)
local IslandShape = require(script.Parent.IslandShape)
local TerrainVersion = require(script.Parent.TerrainVersion)

local L = WorldLayout
local MATERIAL = Enum.Material
local VOXEL = 4
local HALF = VOXEL / 2
local Y_MIN = -40 -- más abajo solo donde el suelo baja (el lago hondo del cráter)
local Y_MAX = 40 -- más arriba solo donde hay montañas (el anillo del cráter)
local CHUNK_VOXELS = 32 -- columnas por lado en cada bloque escrito
local FRAME_BUDGET = 0.02 -- segundos de trabajo por cuadro antes de ceder

local TerrainBuilder = {}

local function style(terrain: Terrain)
	-- Colores saturados y cálidos, como las fotos del juego (2026-10-20). El agua es azul
	-- más hondo y menos transparente: el mar abierto se ve azul y la orilla, donde hay poca
	-- agua sobre la arena, turquesa.
	terrain.WaterColor = Color3.fromRGB(12, 104, 150)
	terrain.WaterTransparency = 0.45
	terrain.WaterReflectance = 0.5
	terrain.WaterWaveSize = 0.22
	terrain.WaterWaveSpeed = 14
	terrain:SetMaterialColor(MATERIAL.Grass, Color3.fromRGB(94, 182, 60))
	terrain:SetMaterialColor(MATERIAL.Sand, Color3.fromRGB(238, 206, 140))
	terrain:SetMaterialColor(MATERIAL.Cobblestone, Color3.fromRGB(126, 118, 108))
	terrain:SetMaterialColor(MATERIAL.Rock, Color3.fromRGB(128, 120, 112))
	terrain:SetMaterialColor(MATERIAL.Basalt, Color3.fromRGB(42, 38, 46))
	terrain:SetMaterialColor(MATERIAL.CrackedLava, Color3.fromRGB(255, 96, 40))
	terrain:SetMaterialColor(MATERIAL.Slate, Color3.fromRGB(150, 150, 156))
	terrain:SetMaterialColor(MATERIAL.Mud, Color3.fromRGB(96, 78, 54)) -- orillas de los estanques
	-- Pasto corto del jardín de entrenamiento (sin el pasto alto de Grass, que tapaba el agua).
	terrain:SetMaterialColor(MATERIAL.LeafyGrass, Color3.fromRGB(90, 176, 56))
	-- Fondo claro del lago del cráter: bajo el agua se ve turquesa (y el gigante resalta).
	terrain:SetMaterialColor(MATERIAL.Limestone, Color3.fromRGB(52, 92, 92))
	terrain:SetMaterialColor(MATERIAL.Asphalt, Color3.fromRGB(58, 46, 48)) -- cumbres del volcán
	-- Rocas del desierto del minotauro (las escribe el cliente: Ambient/SandTerrain).
	terrain:SetMaterialColor(MATERIAL.Sandstone, Color3.fromRGB(186, 128, 84))
	if not terrain:FindFirstChildOfClass("Clouds") then
		local clouds = Instance.new("Clouds")
		clouds.Cover = 0.55
		clouds.Density = 0.6
		clouds.Parent = terrain
	end
end

type Sample = { height: number, material: Enum.Material, water: number }

type Sampler = (x: number, z: number) -> (number, Enum.Material, number)
type Voxels = { yMin: number, yMax: number, materials: { any }, occupancies: { any } }

-- Los vóxeles de un bloque según la forma shapeAt.
local function voxels(x0: number, z0: number, columns: number, shapeAt: Sampler): Voxels
	-- Primero las alturas: el piso de este bloque baja hasta su punto más hondo.
	local samples: { { Sample } } = {}
	local yMin, yMax = Y_MIN, Y_MAX
	local openSea = true -- todo el bloque es fondo de mar plano (lejos de la isla y el volcán)
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

-- Todos los bloques de mar abierto son iguales: se calculan una vez y se reusan.
local openSeaVoxels: Voxels? = nil

-- blocks: la isla es de mallas (BlockIsland); el terreno solo pone el cráter y el mar.
local function writeChunk(
	terrain: Terrain,
	x0: number,
	z0: number,
	columns: number,
	blocks: boolean
)
	local size = columns * VOXEL
	local chunk: Voxels
	if blocks and IslandShape.touchesCrater(x0, z0, size) then
		chunk = voxels(x0, z0, columns, IslandShape.craterOnly)
	elseif not blocks and IslandShape.touches(x0, z0, size) then
		chunk = voxels(x0, z0, columns, IslandShape.sample)
	else
		chunk = openSeaVoxels or voxels(0, 0, columns, IslandShape.openSea)
		openSeaVoxels = chunk
	end
	local region =
		Region3.new(Vector3.new(x0, chunk.yMin, z0), Vector3.new(x0 + size, chunk.yMax, z0 + size))
	terrain:WriteVoxels(region, VOXEL, chunk.materials, chunk.occupancies)
end

local VERSION_ATTRIBUTE = "TerrenoVersion"

-- force: construirlo aunque el guardado en el lugar ya tenga la versión de ahora.
function TerrainBuilder.build(force: boolean?)
	local terrain = Workspace.Terrain
	local blocks = BlockIsland.present()
	local version = TerrainVersion.get(blocks)
	style(terrain)
	if not force and terrain:GetAttribute(VERSION_ATTRIBUTE) == version then
		print(`TerrainBuilder: terreno guardado en el lugar (versión {version})`)
		return
	end
	terrain:Clear()
	terrain:SetAttribute(VERSION_ATTRIBUTE, nil)
	local half = math.ceil(L.oceanHalfSize / (VOXEL * CHUNK_VOXELS)) * VOXEL * CHUNK_VOXELS
	local step = VOXEL * CHUNK_VOXELS
	local started = os.clock()
	local frameStarted = started
	for x0 = -half, half - step, step do
		for z0 = -half, half - step, step do
			writeChunk(terrain, x0, z0, CHUNK_VOXELS, blocks)
			-- Reparte el trabajo para no congelar el servidor, pero sin regalar cuadros.
			if os.clock() - frameStarted >= FRAME_BUDGET then
				task.wait()
				frameStarted = os.clock()
			end
		end
	end
	terrain:SetAttribute(VERSION_ATTRIBUTE, version)
	print(
		`TerrainBuilder: terreno construido en {string.format("%.1f", os.clock() - started)} s`
			.. ` (versión {version})`
	)
end

return TerrainBuilder
