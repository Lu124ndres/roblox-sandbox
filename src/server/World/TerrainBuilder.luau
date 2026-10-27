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
local BlockVolcano = require(script.Parent.BlockVolcano)
local CraterShape = require(script.Parent.CraterShape)
local IslandShape = require(script.Parent.IslandShape)
local TerrainStyle = require(script.Parent.TerrainStyle)
local TerrainVersion = require(script.Parent.TerrainVersion)
local TerrainVoxels = require(script.Parent.TerrainVoxels)

local L = WorldLayout
local VOXEL = TerrainVoxels.VOXEL
local CHUNK_VOXELS = 32 -- columnas por lado en cada bloque escrito
local FRAME_BUDGET = 0.02 -- segundos de trabajo por cuadro antes de ceder

local TerrainBuilder = {}

-- Todos los bloques de mar abierto son iguales: se calculan una vez y se reusan.
local openSeaVoxels: TerrainVoxels.Voxels? = nil

-- Qué escribe el terreno: "island" la isla y el cráter; "crater" solo el cráter (la isla es
-- de mallas, BlockIsland); "lake" solo el lago (el volcán también, BlockVolcano).
type Mode = "island" | "crater" | "lake"

local function writeChunk(terrain: Terrain, x0: number, z0: number, columns: number, mode: Mode)
	local size = columns * VOXEL
	local chunk: TerrainVoxels.Voxels
	local lake = mode == "lake"
	if mode ~= "island" and IslandShape.touchesCrater(x0, z0, size, lake) then
		chunk = TerrainVoxels.build(x0, z0, columns, function(x: number, z: number)
			return CraterShape.onSea(x, z, lake)
		end)
	elseif mode == "island" and IslandShape.touches(x0, z0, size) then
		chunk = TerrainVoxels.build(x0, z0, columns, IslandShape.sample)
	else
		chunk = openSeaVoxels or TerrainVoxels.build(0, 0, columns, IslandShape.openSea)
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
	local lake = blocks and BlockVolcano.present()
	local mode: Mode = if lake then "lake" elseif blocks then "crater" else "island"
	local version = TerrainVersion.get(blocks, lake)
	TerrainStyle.apply(terrain)
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
			writeChunk(terrain, x0, z0, CHUNK_VOXELS, mode)
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
