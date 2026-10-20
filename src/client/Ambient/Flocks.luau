--!strict
--[[
	Flocks

	Las dos bandadas del mundo (Flock): gaviotas sobre la isla y murciélagos sobre
	el cráter. Separado de Main.client para que el punto de entrada no pase de 200 líneas.
		start()
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local Flock = require(script.Parent.Flock)

local EFFECTS = UIConfig.Effects

local Flocks = {}

function Flocks.start()
	Flock.start({
		name = "Gaviotas",
		center = Vector3.new(0, EFFECTS.SeagullHeight, 0),
		count = EFFECTS.SeagullCount,
		radius = EFFECTS.SeagullRadius,
		bodyColor = Color3.fromRGB(248, 250, 252),
		wingColor = Color3.fromRGB(150, 158, 170),
		beakColor = Color3.fromRGB(255, 196, 84),
		size = 1,
		flapSpeed = 9,
		orbitSeconds = 26,
		sound = "Seagull",
	})
	Flock.start({
		name = "Murcielagos",
		center = WorldZones.craterCenter + Vector3.new(0, WorldLayout.craterRimHeight + 30, 0),
		count = EFFECTS.BatCount,
		radius = WorldLayout.craterLakeRadius * 0.7,
		bodyColor = Color3.fromRGB(28, 22, 30),
		wingColor = Color3.fromRGB(40, 30, 44),
		beakColor = Color3.fromRGB(255, 50, 40),
		size = 0.9,
		flapSpeed = 18,
		orbitSeconds = 18,
		sound = nil,
	})
end

return table.freeze(Flocks)
