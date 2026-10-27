--!strict
--[[
	SandTerrain

	Escribe y borra la arena del desierto del cráter en el terreno de este
	cliente (como el agua de CraterDrain: cada cliente simula su personaje).
	La arena es una cáscara: SandShape.SHELL studs bajo waterLevel hasta la
	superficie con dunas y rocas; debajo queda hueco (nadie lo ve, y así son
	~10 filas de vóxeles en vez de las 40 del pozo entero).

	Solo pinta vóxeles de aire (o agua): no toca el fondo ni el acantilado.
	Borrar es cambiar Arena y Arenisca por aire en esa caja, y el cráter no usa
	esos materiales (CraterShape). Se escribe por cuartos, un cuarto por cuadro,
	para no trabar el juego.

	Con streaming el terreno del cráter puede no haber llegado todavía (quien
	entra lejos): antes de escribir se pide y se espera a que el fondo del
	lago exista, si no la arena taparía un cráter que aún no está.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local SandShape = require(script.Parent.SandShape)

local L = WorldLayout
local MATERIAL = Enum.Material
local VOXEL = 4
local HALF_VOXEL = VOXEL / 2
local CENTER = WorldZones.craterCenter
-- Un vóxel de margen: el origen se corre a la cuadrícula y no debe perderse el borde.
local HALF = math.ceil(SandShape.REACH / VOXEL) * VOXEL + VOXEL
-- Esquina de la caja alineada a los vóxeles: ReadVoxels/WriteVoxels/ReplaceMaterial fallan
-- con regiones fuera de la cuadrícula, y el centro del cráter (z = 722) no es múltiplo de 4.
local ORIGIN_X = math.floor((CENTER.X - HALF) / VOXEL) * VOXEL
local ORIGIN_Z = math.floor((CENTER.Z - HALF) / VOXEL) * VOXEL
local Y_MIN = math.floor((L.waterLevel - SandShape.SHELL) / VOXEL) * VOXEL
local Y_MAX = math.ceil(SandShape.MAX_TOP / VOXEL) * VOXEL + VOXEL
local QUARTER = HALF / VOXEL -- columnas por lado de cada cuarto
local LOAD_TRIES = 30 -- segundos que espera el terreno del cráter

local SandTerrain = {}

local terrain = Workspace.Terrain

-- Superficie de cada columna, calculada una vez: [ix][iz] = { alto, material }.
type Column = { top: number, material: Enum.Material }
local columns: { { Column? } }? = nil

local function surface(): { { Column? } }
	local cached = columns
	if cached then
		return cached
	end
	local built: { { Column? } } = {}
	local side = QUARTER * 2
	for ix = 1, side do
		built[ix] = {}
		for iz = 1, side do
			local x = ORIGIN_X + (ix - 0.5) * VOXEL
			local z = ORIGIN_Z + (iz - 0.5) * VOXEL
			local dx, dz = x - CENTER.X, z - CENTER.Z
			if dx * dx + dz * dz <= SandShape.REACH * SandShape.REACH then
				local top, material = SandShape.sample(x, z)
				built[ix][iz] = { top = top, material = material }
			end
		end
	end
	columns = built
	return built
end

-- Un cuarto: columnas desde (cx, cz) (índices 0-based en la cuadrícula de surface()).
local function writeQuarter(cx: number, cz: number)
	local grid = surface()
	local x0 = ORIGIN_X + cx * VOXEL
	local z0 = ORIGIN_Z + cz * VOXEL
	local region = Region3.new(
		Vector3.new(x0, Y_MIN, z0),
		Vector3.new(x0 + QUARTER * VOXEL, Y_MAX, z0 + QUARTER * VOXEL)
	)
	local materials, occupancies = terrain:ReadVoxels(region, VOXEL)
	-- Bucles numéricos: las tablas de ReadVoxels también traen `Size`.
	for ix = 1, #materials do
		local plane = grid[cx + ix]
		for iy = 1, #materials[ix] do
			local bottom = Y_MIN + (iy - 1) * VOXEL
			local row, fill = materials[ix][iy], occupancies[ix][iy]
			for iz = 1, #row do
				local column = plane and plane[cz + iz]
				local current = row[iz]
				if column and (current == MATERIAL.Air or current == MATERIAL.Water) then
					-- Misma cuenta que TerrainBuilder: la superficie queda donde dice el diseño.
					local solid = math.clamp((column.top - bottom - HALF_VOXEL) / VOXEL, 0, 1)
					if solid > 0 then
						row[iz], fill[iz] = column.material, solid
					else
						row[iz], fill[iz] = MATERIAL.Air, 0
					end
				end
			end
		end
	end
	terrain:WriteVoxels(region, VOXEL, materials, occupancies)
end

-- ¿Llegó el terreno del cráter? Mira un vóxel macizo del fondo del lago (el paseo y el
-- acantilado son de la malla del volcán, World/BlockVolcano).
local function loaded(): boolean
	local radius = L.craterLakeRadius - 20
	local spot = CENTER + Vector3.new(0, WorldZones.lakeFloor(radius) - 6, -radius)
	local region = Region3.new(spot, spot + Vector3.one * VOXEL):ExpandToGrid(VOXEL)
	local materials = terrain:ReadVoxels(region, VOXEL)
	local first = materials[1] and materials[1][1] and materials[1][1][1]
	return first ~= nil and first ~= MATERIAL.Air
end

local function waitLoaded(alive: () -> boolean): boolean
	for _ = 1, LOAD_TRIES do
		if loaded() then
			return true
		elseif not alive() then
			return false
		end
		pcall(function()
			Players.LocalPlayer:RequestStreamAroundAsync(CENTER + Vector3.new(0, L.waterLevel, 0))
		end)
		task.wait(1)
	end
	return loaded()
end

-- Pone la arena. instant: todo en este cuadro (quien entra con el minotauro ya ahí).
-- alive() en false corta a mitad (la arena empezó a irse mientras se escribía).
-- Devuelve false si no la pudo poner (el terreno del cráter nunca llegó).
function SandTerrain.write(instant: boolean, alive: () -> boolean): boolean
	if not waitLoaded(alive) then
		return false
	end
	for _, quarter in { { 0, 0 }, { QUARTER, 0 }, { 0, QUARTER }, { QUARTER, QUARTER } } do
		if not alive() then
			return false
		end
		writeQuarter(quarter[1], quarter[2])
		if not instant then
			task.wait()
		end
	end
	return true
end

-- Quita la arena y las rocas (vuelve a quedar el cráter vacío).
function SandTerrain.clear()
	local region = Region3.new(
		Vector3.new(ORIGIN_X, Y_MIN, ORIGIN_Z),
		Vector3.new(ORIGIN_X + 2 * HALF, Y_MAX, ORIGIN_Z + 2 * HALF)
	)
	terrain:ReplaceMaterial(region, VOXEL, MATERIAL.Sand, MATERIAL.Air)
	terrain:ReplaceMaterial(region, VOXEL, MATERIAL.Sandstone, MATERIAL.Air)
end

return table.freeze(SandTerrain)
