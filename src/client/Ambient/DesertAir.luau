--!strict
--[[
	DesertAir

	El aire del desierto del cráter mientras está la arena (CraterMode "sand"):
		viento   granos de arena que vuelan en rachas, estirados en la dirección
		         del viento (SandShape.WIND);
		polvo    nubes bajas que se arrastran a ras del suelo;
		calor    un vaho claro y lento que sube de la arena (el aire que tiembla);
		bancos   arena que el viento levanta de las crestas junto al acantilado;
		remolinos de vez en cuando (DustDevils).
	La luz cálida la mezcla SkyCycle (SkyMoods.desert). Todo local; los
	emisores pasan por FxQuality (modo rápido = sin partículas).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Assets = require(ReplicatedStorage.Shared.Assets)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local FxQuality = require(script.Parent.Parent.Settings.FxQuality)
local CraterMode = require(script.Parent.CraterMode)
local DustDevils = require(script.Parent.DustDevils)
local SandFx = require(script.Parent.SandFx)
local SandShape = require(script.Parent.SandShape)

local L = WorldLayout
local CENTER = WorldZones.craterCenter
local TOP = L.waterLevel
local SPAN = L.craterLakeRadius * 1.7 -- lado de las cajas que sueltan partículas
local GRAIN = Color3.fromRGB(236, 208, 156)
local HEAT = Color3.fromRGB(255, 246, 226)
local CRESTS = 8 -- puntos alrededor del cráter donde el viento levanta arena de los bancos
local SETTLE_SECONDS = 2.5 -- el aire del desierto aparece cuando la arena ya subió
local rgb = Color3.fromRGB

local DesertAir = {}

local folder = Instance.new("Folder")
folder.Name = "AireDelDesierto"

-- Caja invisible que suelta partículas; su -Z (Front) mira hacia donde sopla el viento.
local function box(name: string, size: Vector3, height: number, offset: Vector3?): Part
	local at = CENTER + (offset or Vector3.zero) + Vector3.new(0, height, 0)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = CFrame.lookAt(at, at + SandShape.WIND)
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide, part.CanQuery, part.CanTouch = false, false, false
	part.Parent = folder
	return part
end

local function emitter(
	parent: Instance,
	texture: string,
	color: ColorSequence,
	rate: number
): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Texture = texture
	e.Color = color
	e.Rate = rate
	e.Shape = Enum.ParticleEmitterShape.Box
	e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	e.EmissionDirection = Enum.NormalId.Front -- con el viento
	e.Rotation = NumberRange.new(0, 360)
	e.Parent = parent
	return e
end

local function build()
	-- Granos que vuelan: rayitas estiradas en la dirección en que van.
	local wind = emitter(
		box("Viento", Vector3.new(SPAN, 8, SPAN), TOP + 5),
		Assets.Particles.Spark,
		ColorSequence.new(GRAIN, SandFx.DUST),
		70
	)
	wind.Orientation = Enum.ParticleOrientation.VelocityParallel
	wind.Rotation = NumberRange.new(0)
	wind.Squash = NumberSequence.new(1.8)
	wind.Size = NumberSequence.new(0.35, 0.2)
	wind.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	wind.Lifetime = NumberRange.new(1.2, 2.2)
	wind.Speed = NumberRange.new(28, 44)
	wind.SpreadAngle = Vector2.new(6, 3)
	wind.Acceleration = Vector3.new(0, -3, 0)

	-- Polvo que se arrastra a ras del suelo.
	local dust = emitter(
		box("Polvo", Vector3.new(SPAN, 2, SPAN), TOP + 1.5),
		Assets.Particles.Mist,
		ColorSequence.new(SandFx.DUST, rgb(200, 164, 118)),
		14
	)
	dust.Size = NumberSequence.new(7, 16)
	dust.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.3, 0.78),
		NumberSequenceKeypoint.new(1, 1),
	})
	dust.Lifetime = NumberRange.new(4, 7)
	dust.Speed = NumberRange.new(8, 14)
	dust.SpreadAngle = Vector2.new(10, 2)
	dust.RotSpeed = NumberRange.new(-15, 15)

	-- Calor: vaho claro, casi transparente, que sube lento y tiembla.
	local heat = box("Calor", Vector3.new(SPAN, 1, SPAN), TOP + 2)
	local haze = emitter(heat, Assets.Particles.Mist, ColorSequence.new(HEAT), 12)
	haze.EmissionDirection = Enum.NormalId.Top
	haze.Size = NumberSequence.new(10, 22)
	haze.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.4, 0.9),
		NumberSequenceKeypoint.new(1, 1),
	})
	haze.Lifetime = NumberRange.new(3, 5)
	haze.Speed = NumberRange.new(1.5, 3.5)
	haze.RotSpeed = NumberRange.new(-25, 25)
	haze.LightEmission = 0.15

	-- Arena que el viento levanta de los bancos contra el acantilado.
	for k = 1, CRESTS do
		local a = (k - 0.5) / CRESTS * math.pi * 2
		local offset = Vector3.new(math.cos(a), 0, math.sin(a)) * 172
		local crest = emitter(
			box(`Cresta{k}`, Vector3.new(36, 3, 36), TOP + 8, offset),
			Assets.Particles.Mist,
			ColorSequence.new(GRAIN),
			3
		)
		crest.Size = NumberSequence.new(3, 9)
		crest.Transparency = NumberSequence.new(0.55, 1)
		crest.Lifetime = NumberRange.new(1.5, 2.5)
		crest.Speed = NumberRange.new(14, 22)
		crest.SpreadAngle = Vector2.new(8, 20)
		crest.Acceleration = Vector3.new(0, -4, 0)
	end
	FxQuality.scaleAll(folder)
end

function DesertAir.start()
	build()
	local function refresh()
		folder.Parent = if CraterMode.isSand() then Workspace else nil
	end
	CraterMode.onChanged(function(mode: CraterMode.Mode)
		if mode == "sand" then
			task.delay(SETTLE_SECONDS, refresh)
		else
			refresh()
		end
	end)
	refresh()
	DustDevils.start(CraterMode.isSand)
end

return table.freeze(DesertAir)
