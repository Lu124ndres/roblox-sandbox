--!strict
--[[
	CraterDrain

	Vacía y vuelve a llenar el lago del volcán en este cliente, según
	EstadoGigante.VolcanVacio (lo publica RestArena):
		- al empezar el descanso el agua baja hasta el fondo en drainSeconds,
		  con remolinos y retumbos, y queda a la vista la guarida del fondo;
		- vacío también en la ruleta: cuando llega el siguiente monstruo sube el
		  agua en refillSeconds, o la lava si es el dragón (CraterLava).
	El agua es de cada cliente (los personajes se simulan en su propio
	cliente), así que se cambia aquí, por capas, con Terrain:ReplaceMaterial.
	Quien entra con el volcán vacío lo ve vacío al instante. onShown avisa a
	CraterWater para esconder el abismo, las motas y las fumarolas sin agua.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local CameraShake = require(script.Parent.Parent.Effects.CameraShake)
local Fx = require(script.Parent.Parent.Effects.Fx)
local CraterLava = require(script.Parent.CraterLava)

local L = WorldLayout
local CYCLE = Config.Giants.cycle
local VOXEL = 4
local STEP = 8 -- studs de agua por capa
local HALF = math.ceil((L.craterLakeRadius + 8) / VOXEL) * VOXEL
local BOTTOM = math.floor(L.craterFloor / VOXEL) * VOXEL - VOXEL
local SURFACE = math.floor(L.waterLevel / VOXEL) * VOXEL -- fila de la superficie (agua a medias)
local CENTER = WorldZones.craterCenter

local CraterDrain = {}

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

local function drain(instant: boolean)
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

local function refill(onShown: (boolean) -> ())
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
		onShown(true)
		churn(L.waterLevel)
	end
end

type Mode = "water" | "empty" | "lava"

local defs: { [string]: Config.GiantDef } = {}
for _, def in Config.Giants.chain do
	defs[def.id] = def
end

-- onShown(false) cuando no hay agua (vacío o lava): sin abismo ni efectos del agua.
function CraterDrain.start(onShown: (boolean) -> ())
	local stateFolder = ReplicatedStorage:WaitForChild(Protocol.GiantStateFolder)
	local ATTR = Protocol.GiantAttributes
	local mode: Mode = "water" -- así lo deja TerrainBuilder
	-- Vacío en el descanso y en la ruleta: se llena cuando llega el siguiente.
	local function wanted(): Mode
		if
			stateFolder:GetAttribute(ATTR.Drained) == true
			or stateFolder:GetAttribute(ATTR.Phase) == "rest"
		then
			return "empty"
		end
		local def = defs[stateFolder:GetAttribute(ATTR.Id) :: any]
		return if def and def.lava then "lava" else "water"
	end
	local function apply(instant: boolean)
		local target: Mode = wanted()
		if target == mode then
			return
		end
		local from: Mode = mode
		mode = target
		if from == "water" then
			onShown(false)
			task.spawn(drain, instant or target == "lava")
		elseif from == "lava" then
			CraterLava.sink(instant or target == "water")
		end
		if target == "water" then
			task.spawn(refill, onShown)
		elseif target == "lava" then
			CraterLava.rise(instant)
		end
	end
	for _, attribute in { ATTR.Drained, ATTR.Phase, ATTR.Id } do
		stateFolder:GetAttributeChangedSignal(attribute):Connect(function()
			apply(false)
		end)
	end
	apply(true) -- quien entra lo ve como está, al instante
end

return CraterDrain
