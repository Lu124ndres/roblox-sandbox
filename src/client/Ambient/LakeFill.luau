--!strict
--[[
	LakeFill

	El agua del lago del volcán en este cliente, por capas, con
	Terrain:ReplaceMaterial (la usa CraterDrain):
		drain   el agua baja hasta el fondo en drainSeconds, con remolinos y
		        retumbos (instant: de una, sin efectos);
		refill  sube en refillSeconds hasta waterLevel y avisa al terminar.
	Empezar uno corta al otro (generation).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local CameraShake = require(script.Parent.Parent.Effects.CameraShake)
local Fx = require(script.Parent.Parent.Effects.Fx)

local L = WorldLayout
local CYCLE = Config.Giants.cycle
local VOXEL = 4
local STEP = 8 -- studs de agua por capa
local HALF = math.ceil((L.craterLakeRadius + 8) / VOXEL) * VOXEL
local BOTTOM = math.floor(L.craterFloor / VOXEL) * VOXEL - VOXEL
local SURFACE = math.floor(L.waterLevel / VOXEL) * VOXEL -- fila de la superficie (agua a medias)
local CENTER = WorldZones.craterCenter

local LakeFill = {}

local terrain = Workspace.Terrain
local generation = 0

local function slab(y0: number, y1: number): Region3
	return Region3.new(
		Vector3.new(CENTER.X - HALF, y0, CENTER.Z - HALF),
		Vector3.new(CENTER.X + HALF, y1, CENTER.Z + HALF)
	):ExpandToGrid(VOXEL)
end

-- La fila de la superficie: agua solo hasta waterLevel (como la deja TerrainBuilder).
local function fillSurface()
	local region = slab(SURFACE, SURFACE + VOXEL)
	local materials, occupancies = terrain:ReadVoxels(region, VOXEL)
	local level = (L.waterLevel - SURFACE) / VOXEL
	-- Bucles numéricos: las tablas de ReadVoxels también traen `Size`.
	for x = 1, #materials do
		for y = 1, #materials[x] do
			local row = materials[x][y]
			for z = 1, #row do
				if row[z] == Enum.Material.Air then
					row[z] = Enum.Material.Water
					occupancies[x][y][z] = level
				end
			end
		end
	end
	terrain:WriteVoxels(region, VOXEL, materials, occupancies)
end

local function nearness(): number
	local character = Players.LocalPlayer.Character
	return if character then WorldZones.craterBlend(character:GetPivot().Position) else 0
end

-- Remolino y retumbo mientras el agua se mueve (level: altura del agua ahora).
local function churn(level: number)
	local spot = CENTER + Vector3.new(0, level, 0)
	Fx.splash(spot, 4)
	Fx.ring(spot, L.craterLakeRadius * 0.5, 1.2)
	Sounds.play("BigSplash", spot, 0.55)
	CameraShake.shake(0.2 * nearness(), 0.8)
end

function LakeFill.drain(instant: boolean)
	generation += 1
	local mine = generation
	local pause = CYCLE.drainSeconds / ((SURFACE + VOXEL - BOTTOM) / STEP)
	local count = 0
	local y = SURFACE + VOXEL
	while y > BOTTOM and mine == generation do
		terrain:ReplaceMaterial(
			slab(math.max(y - STEP, BOTTOM), y),
			VOXEL,
			Enum.Material.Water,
			Enum.Material.Air
		)
		y -= STEP
		count += 1
		if not instant then
			if count % 8 == 1 then
				churn(math.max(y, L.craterFloor))
			end
			task.wait(pause)
		end
	end
end

-- onFull() cuando el agua llegó arriba (y no la cortó otro cambio).
function LakeFill.refill(onFull: () -> ())
	generation += 1
	local mine = generation
	local pause = CYCLE.refillSeconds / ((SURFACE - BOTTOM) / STEP + 1)
	local count = 0
	local y = BOTTOM
	while y < SURFACE and mine == generation do
		terrain:ReplaceMaterial(
			slab(y, math.min(y + STEP, SURFACE)),
			VOXEL,
			Enum.Material.Air,
			Enum.Material.Water
		)
		y += STEP
		count += 1
		if count % 8 == 1 then
			churn(math.min(y, L.waterLevel))
		end
		task.wait(pause)
	end
	if mine == generation then
		fillSurface()
		onFull()
		churn(L.waterLevel)
	end
end

return table.freeze(LakeFill)
