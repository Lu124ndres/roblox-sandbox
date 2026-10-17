--!strict
--[[
	LairGround

	Con la lava, la repisa del cráter (piedra caliza, que bajo el agua se ve
	turquesa) se vuelve ceniza oscura en este cliente: Caliza → Tierra
	(Ground) teñida de ceniza, solo en la caja del lago. Ningún otro terreno
	del juego usa Ground (CraterShape, IslandShape), así que restore() la
	devuelve exacta (Tierra → Caliza) sin tocar nada más. No cambia la forma:
	los props y las rocas siguen apoyados igual.
	Se escribe por cuartos (uno por cuadro) para no trabar; restore() es de
	una vez, antes de que vuelva el agua o la arena (CraterDrain llama a
	sink antes de llenar). Con streaming, lo que llegue tarde queda caliza:
	una segunda pasada al rato lo alcanza.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)

local L = WorldLayout
local VOXEL = 4
local CENTER = WorldZones.craterCenter
local HALF = math.ceil((L.craterLakeRadius + 8) / VOXEL) * VOXEL
local Y_MIN = math.floor(
	(WorldZones.lakeFloor(L.craterLakeRadius - L.craterShelfWidth - 12) - 8) / VOXEL
) * VOXEL
local Y_MAX = math.ceil((L.waterLevel + 4) / VOXEL) * VOXEL
local ASH = Enum.Material.Ground
local SHELF = Enum.Material.Limestone
local ASH_COLOR = Color3.fromRGB(58, 50, 50)
local SECOND_PASS_SECONDS = 6

local LairGround = {}

local terrain = Workspace.Terrain
local generation = 0

local function region(x0: number, z0: number, x1: number, z1: number): Region3
	return Region3.new(
		Vector3.new(CENTER.X + x0, Y_MIN, CENTER.Z + z0),
		Vector3.new(CENTER.X + x1, Y_MAX, CENTER.Z + z1)
	):ExpandToGrid(VOXEL)
end

local function pass(mine: number, instant: boolean)
	for _, q in { { -HALF, -HALF }, { 0, -HALF }, { -HALF, 0 }, { 0, 0 } } do
		if mine ~= generation then
			return
		end
		terrain:ReplaceMaterial(region(q[1], q[2], q[1] + HALF, q[2] + HALF), VOXEL, SHELF, ASH)
		if not instant then
			task.wait()
		end
	end
end

-- La repisa se vuelve ceniza. instant: todo en este cuadro.
function LairGround.ash(instant: boolean)
	generation += 1
	local mine = generation
	terrain:SetMaterialColor(ASH, ASH_COLOR)
	task.spawn(function()
		pass(mine, instant)
		task.wait(SECOND_PASS_SECONDS)
		pass(mine, false)
	end)
end

-- Vuelve la caliza (de una, en este cuadro).
function LairGround.restore()
	generation += 1
	terrain:ReplaceMaterial(region(-HALF, -HALF, HALF, HALF), VOXEL, ASH, SHELF)
end

return table.freeze(LairGround)
