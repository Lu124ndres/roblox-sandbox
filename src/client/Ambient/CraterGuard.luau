--!strict
--[[
	CraterGuard

	Con streaming, el terreno del cráter puede llegarle a este cliente (o volver,
	si el jugador se alejó y regresó) DESPUÉS de que lo cambió: trae de nuevo el
	agua del servidor, encima de la lava del dragón o de la arena del minotauro.
	Cada GUARD_SECONDS mira una franja del centro a la altura del agua; si con lava
	o arena hay agua, la vuelve a sacar al instante (y en el desierto vuelve a poner
	la arena). No mira en los primeros SETTLE_SECONDS de cada cambio de relleno,
	mientras el agua se va o llega con su animación.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local CraterMode = require(script.Parent.CraterMode)
local CraterSand = require(script.Parent.CraterSand)
local LakeFill = require(script.Parent.LakeFill)

local GUARD_SECONDS = 2
local SETTLE_SECONDS = 6
local VOXEL = 4
local SAMPLE = 24 -- studs a cada lado del centro

local CraterGuard = {}

local function wet(): boolean
	local c = WorldZones.craterCenter
	local y = WorldLayout.waterLevel
	local region = Region3.new(
		Vector3.new(c.X - SAMPLE, y - VOXEL, c.Z - SAMPLE),
		Vector3.new(c.X + SAMPLE, y, c.Z + SAMPLE)
	):ExpandToGrid(VOXEL)
	local materials = Workspace.Terrain:ReadVoxels(region, VOXEL)
	for x = 1, #materials do
		for z = 1, #materials[x][1] do
			if materials[x][1][z] == Enum.Material.Water then
				return true
			end
		end
	end
	return false
end

function CraterGuard.start()
	local changedAt = os.clock()
	CraterMode.onChanged(function()
		changedAt = os.clock()
	end)
	task.spawn(function()
		while true do
			task.wait(GUARD_SECONDS)
			local mode = CraterMode.get()
			if
				(mode == "lava" or mode == "sand")
				and os.clock() - changedAt > SETTLE_SECONDS
				and wet()
			then
				LakeFill.drain(true)
				if mode == "sand" then
					CraterSand.rise(true)
				end
			end
		end
	end)
end

return table.freeze(CraterGuard)
