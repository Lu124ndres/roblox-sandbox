--!strict
--[[
	CraterWater

	El agua del lago del cráter, solo en el cliente:
		- al entrar al cráter el agua cambia a un turquesa de cristal, más
		  clara para ver nadar al gigante (el color del agua es uno solo para
		  todo el mapa, así que se mezcla con ZoneMood.blend());
		- motas bioluminiscentes que flotan sobre la superficie;
		- espuma y vapor donde el agua toca el acantilado caliente;
		- fumarolas en el fondo (CraterVents).
	Los emisores pasan por FxQuality (modo rápido = sin partículas).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Assets = require(ReplicatedStorage.Shared.Assets)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)
local FxQuality = require(script.Parent.Parent.Settings.FxQuality)
local CraterVents = require(script.Parent.CraterVents)

local L = WorldLayout
local WATER = L.waterLevel
local CENTER = WorldZones.craterCenter
local LAKE_COLOR = Color3.fromRGB(0, 160, 150) -- jade turquesa
local LAKE_TRANSPARENCY = 0.55
local LAKE_REFLECTANCE = 0.15 -- poco reflejo: si no, la bruma naranja lo vuelve beige
local LAKE_WAVES = 0.32 -- un poco más agitada que el mar
local GLOW = Color3.fromRGB(120, 255, 230)
local FOAM = Color3.fromRGB(235, 252, 250)
local EDGE_PIECES = 20 -- tramos de espuma alrededor del acantilado

local CraterWater = {}

local folder = Instance.new("Folder")
folder.Name = "AguaDelCrater"

local function holder(name: string, size: Vector3, cframe: CFrame): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Parent = folder
	return part
end

local function emitter(
	parent: Instance,
	texture: string,
	from: Color3,
	to: Color3,
	rate: number
): ParticleEmitter
	local particles = Instance.new("ParticleEmitter")
	particles.Texture = texture
	particles.Color = ColorSequence.new(from, to)
	particles.Rate = rate
	particles.Rotation = NumberRange.new(0, 360)
	particles.RotSpeed = NumberRange.new(-30, 30)
	particles.Parent = parent
	return particles
end

-- Motas que brillan apenas sobre el agua, en todo el lago.
local function motes()
	local size = L.craterLakeRadius * 1.6
	local box = holder(
		"Motas",
		Vector3.new(size, 1, size),
		CFrame.new(CENTER + Vector3.new(0, WATER + 1.5, 0))
	)
	local glow = emitter(box, Assets.Particles.Sparkle, GLOW, Color3.fromRGB(60, 200, 255), 45)
	glow.Shape = Enum.ParticleEmitterShape.Box
	glow.LightEmission = 1
	glow.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.3, 0.7),
		NumberSequenceKeypoint.new(1, 0),
	})
	glow.Lifetime = NumberRange.new(5, 9)
	glow.Speed = NumberRange.new(0.3, 1.2)
	glow.SpreadAngle = Vector2.new(180, 20)
	glow.Acceleration = Vector3.new(0, 0.4, 0)
end

-- Espuma y vapor donde el agua golpea el acantilado.
local function edge()
	local radius = L.craterLakeRadius + (L.craterCliffRadius - L.craterLakeRadius) * 0.35
	local arc = 2 * math.pi * radius / EDGE_PIECES
	for k = 1, EDGE_PIECES do
		local angle = (k - 0.5) / EDGE_PIECES * math.pi * 2
		local spot = CENTER
			+ Vector3.new(math.cos(angle) * radius, WATER + 0.3, math.sin(angle) * radius)
		local piece = holder(
			`Orilla{k}`,
			Vector3.new(arc, 0.5, 6),
			CFrame.lookAt(spot, CENTER + Vector3.new(0, WATER + 0.3, 0))
		)
		local foam = emitter(piece, Assets.Particles.Mist, FOAM, GLOW, 6)
		foam.Shape = Enum.ParticleEmitterShape.Box
		foam.Size = NumberSequence.new(3, 7)
		foam.Transparency = NumberSequence.new(0.45, 1)
		foam.Lifetime = NumberRange.new(1.5, 2.5)
		foam.Speed = NumberRange.new(0.5, 2)
		foam.SpreadAngle = Vector2.new(60, 60)
		local steam = emitter(
			piece,
			Assets.Particles.Mist,
			Color3.fromRGB(240, 236, 232),
			Color3.fromRGB(255, 170, 120),
			2
		)
		steam.Shape = Enum.ParticleEmitterShape.Box
		steam.Size = NumberSequence.new(4, 14)
		steam.Transparency = NumberSequence.new(0.75, 1)
		steam.Lifetime = NumberRange.new(4, 7)
		steam.Speed = NumberRange.new(2, 5)
		steam.SpreadAngle = Vector2.new(15, 15)
	end
end

-- getBlend: 0 fuera del cráter, 1 adentro (ZoneMood).
function CraterWater.start(getBlend: () -> number)
	motes()
	edge()
	folder.Parent = Workspace
	FxQuality.scaleAll(folder)

	local terrain = Workspace.Terrain
	local seaColor, seaClear = terrain.WaterColor, terrain.WaterTransparency
	local seaShine, seaWaves = terrain.WaterReflectance, terrain.WaterWaveSize
	local shown = -1
	RunService.Heartbeat:Connect(function()
		local blend = getBlend()
		if math.abs(blend - shown) > 0.01 then
			shown = blend
			terrain.WaterColor = seaColor:Lerp(LAKE_COLOR, blend)
			terrain.WaterTransparency = seaClear + (LAKE_TRANSPARENCY - seaClear) * blend
			if not ClientSettings.get("lowFx") then -- el modo rápido apaga olas y reflejos
				terrain.WaterReflectance = seaShine + (LAKE_REFLECTANCE - seaShine) * blend
				terrain.WaterWaveSize = seaWaves + (LAKE_WAVES - seaWaves) * blend
			end
		end
	end)
	CraterVents.start(folder, getBlend)
end

return CraterWater
