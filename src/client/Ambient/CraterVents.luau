--!strict
--[[
	CraterVents

	Fumarolas en el fondo del lago del cráter: un brillo de lava allá abajo
	(se ve a través del agua), una columna de burbujas que sube hasta la
	superficie y un hervor de espuma arriba; de vez en cuando una suelta un
	burbujón (salpicadura y onda). Solo en el cliente.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage.Shared.Assets)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local Fx = require(script.Parent.Parent.Effects.Fx)

local L = WorldLayout
local WATER = L.waterLevel
local CENTER = WorldZones.craterCenter
local GLOW = Color3.fromRGB(120, 255, 230)
local FOAM = Color3.fromRGB(235, 252, 250)
local LAVA = Color3.fromRGB(255, 110, 40)
local VENTS = { { 35, 0.35 }, { 140, 0.62 }, { 215, 0.48 }, { 300, 0.75 }, { 260, 0.2 } } -- ángulo, radio

local CraterVents = {}

local function holder(folder: Instance, name: string, size: Vector3, cframe: CFrame): Part
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

-- Fumarolas: brillo de lava en el fondo y una columna de burbujas que revienta arriba.
local function build(folder: Instance): { Vector3 }
	local tops = {}
	for index, vent in VENTS do
		local angle, radius = math.rad(vent[1]), vent[2] * L.craterLakeRadius
		local flat = CENTER + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		-- Sobre el disco más hondo del abismo (CraterWater): ahí se ven brillar.
		local bottom = math.max(WorldZones.lakeFloor(radius), WATER - 18)
		local column = holder(
			folder,
			`Fumarola{index}`,
			Vector3.new(3, 1, 3),
			CFrame.new(flat + Vector3.new(0, bottom + 1, 0))
		)
		local light = Instance.new("PointLight")
		light.Color = LAVA
		light.Range = 22
		light.Brightness = 3
		light.Shadows = false
		light.Parent = column
		local bubbles =
			emitter(column, Assets.Particles.Sparkle, Color3.fromRGB(255, 220, 170), GLOW, 14)
		bubbles.LightEmission = 0.6
		bubbles.Size = NumberSequence.new(0.6, 1.4)
		bubbles.Transparency = NumberSequence.new(0.1, 0.6)
		bubbles.Speed = NumberRange.new(12, 16)
		bubbles.Lifetime = NumberRange.new((WATER - bottom) / 14)
		bubbles.SpreadAngle = Vector2.new(6, 6)
		local top = flat + Vector3.new(0, WATER, 0)
		local boil = holder(
			folder,
			`Hervor{index}`,
			Vector3.new(8, 0.5, 8),
			CFrame.new(top + Vector3.new(0, 0.4, 0))
		)
		local froth = emitter(boil, Assets.Particles.Mist, FOAM, GLOW, 5)
		froth.Shape = Enum.ParticleEmitterShape.Box
		froth.Size = NumberSequence.new(2, 5)
		froth.Transparency = NumberSequence.new(0.4, 1)
		froth.Lifetime = NumberRange.new(1, 2)
		froth.Speed = NumberRange.new(1, 3)
		table.insert(tops, top)
	end
	return tops
end

-- Crea las fumarolas dentro de folder (quien llama ajusta los emisores con FxQuality).
function CraterVents.start(folder: Instance, getBlend: () -> number)
	local tops = build(folder)
	task.spawn(function()
		local rng = Random.new()
		while true do
			task.wait(rng:NextNumber(4, 9))
			if getBlend() > 0.5 then
				local top = tops[rng:NextInteger(1, #tops)]
				Fx.splash(top, 1.6)
				Fx.ring(top, 10, 1.4)
			end
		end
	end)
end

return CraterVents
