--!strict
--[[
	ZoneMood

	Cambia el ambiente según dónde está el jugador. Al cruzar el puente hacia
	el Cráter del Abismo la luz se vuelve cálida, de lava (clara para jugar,
	pero se nota el peligro): bruma anaranjada, chispas que suben del lago,
	el fondo del abismo brilla en rojo, el océano se calla, entra un ambiente
	tenso y de vez en cuando hay relámpagos y truenos.

	SkyCycle lee ZoneMood.blend() para mezclar la luz del día con la del cráter.
]]

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Assets = require(ReplicatedStorage.Shared.Assets)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local Sounds = require(script.Parent.Parent.Audio.Sounds)

local BLEND_SHARPNESS = 1.5 -- qué tan rápido cambia el ambiente al entrar o salir (1/s)
local LIGHTNING_MIN_SECONDS, LIGHTNING_MAX_SECONDS = 14, 30

local ZoneMood = {}

local blend = 0

function ZoneMood.blend(): number
	return blend
end

local function invisiblePart(name: string, size: Vector3, position: Vector3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = CFrame.new(position)
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Parent = Workspace
	return part
end

-- Bruma sobre el lago del cráter y un brillo rojo que sube desde el abismo.
local function craterEffects()
	local lake = WorldLayout.craterLakeRadius * 1.6
	local fog = invisiblePart(
		"BrumaDelAbismo",
		Vector3.new(lake, 1, lake),
		WorldZones.craterCenter + Vector3.new(0, WorldLayout.waterLevel + 3, 0)
	)
	local mist = Instance.new("ParticleEmitter")
	mist.Texture = Assets.Particles.Mist
	mist.Shape = Enum.ParticleEmitterShape.Box
	mist.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	mist.Color = ColorSequence.new(Color3.fromRGB(255, 170, 120), Color3.fromRGB(200, 90, 60))
	mist.Size = NumberSequence.new(18, 34)
	mist.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.3, 0.82),
		NumberSequenceKeypoint.new(1, 1),
	})
	mist.Lifetime = NumberRange.new(9, 14)
	mist.Rate = 7
	mist.Speed = NumberRange.new(0.5, 2)
	mist.SpreadAngle = Vector2.new(180, 10)
	mist.RotSpeed = NumberRange.new(-8, 8)
	mist.Parent = fog

	local glow = invisiblePart(
		"BrilloDelAbismo",
		Vector3.one,
		WorldZones.craterCenter + Vector3.new(0, WorldLayout.waterLevel - 14, 0)
	)
	-- Suave y poco saturada: si es muy roja, tiñe de naranja al gigante de encima.
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 150, 110)
	light.Range = 50
	light.Brightness = 1.6
	light.Parent = glow
	TweenService:Create(
		light,
		TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Brightness = 0.7 }
	):Play()

	-- Chispas de lava que suben del lago hasta más arriba del borde.
	local embers = Instance.new("ParticleEmitter")
	embers.Name = "Chispas"
	embers.Texture = Assets.Particles.Spark
	embers.Shape = Enum.ParticleEmitterShape.Box
	embers.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	embers.Color = ColorSequence.new(Color3.fromRGB(255, 200, 80), Color3.fromRGB(255, 60, 20))
	embers.LightEmission = 1
	embers.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.9),
		NumberSequenceKeypoint.new(1, 0),
	})
	embers.Lifetime = NumberRange.new(4, 7)
	embers.Rate = 70
	embers.Speed = NumberRange.new(6, 12)
	embers.SpreadAngle = Vector2.new(25, 25)
	embers.Acceleration = Vector3.new(0, 2, 0)
	embers.Parent = fog
end

local function lightningLoop()
	task.spawn(function()
		local rng = Random.new()
		while true do
			task.wait(rng:NextNumber(LIGHTNING_MIN_SECONDS, LIGHTNING_MAX_SECONDS))
			local correction = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
			if blend > 0.6 and correction then
				for _ = 1, rng:NextInteger(1, 2) do
					correction.Brightness = 0.45
					TweenService:Create(correction, TweenInfo.new(0.35), { Brightness = 0 }):Play()
					task.wait(0.18)
				end
				task.wait(rng:NextNumber(0.3, 1.2))
				Sounds.play("Thunder")
			end
		end
	end)
end

function ZoneMood.start()
	craterEffects()
	lightningLoop()
	local ocean = Sounds.loop("OceanWaves")
	local horror = Sounds.loop("HorrorAmbience")
	local oceanVolume = if ocean then ocean.Volume else 0
	local horrorVolume = if horror then horror.Volume else 0
	if horror then
		horror.Volume = 0
	end

	RunService.Heartbeat:Connect(function(dt: number)
		local character = Players.LocalPlayer.Character
		local target = if character
			then WorldZones.craterBlend(character:GetPivot().Position)
			else 0
		blend += (target - blend) * (1 - math.exp(-dt * BLEND_SHARPNESS))
		if ocean then
			ocean.Volume = oceanVolume * (1 - blend * 0.8)
		end
		if horror then
			horror.Volume = horrorVolume * blend
		end
	end)
end

return ZoneMood
