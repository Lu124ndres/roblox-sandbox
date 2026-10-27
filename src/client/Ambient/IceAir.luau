--!strict
--[[
	IceAir

	El aire frío del lago del zorro mientras está el hielo (IceLair):
		nieve     copos que caen lentos sobre todo el cráter, con algo de viento
		polvo     "polvo de diamante": destellos chicos de hielo que brillan en el
		de hielo  aire a poca altura sobre el agua
		vaho      niebla fría y baja que se arrastra sobre el agua y los témpanos
		          (el agua más tibia que el aire humea)
		escarcha  un brillo frío y suave sobre la orilla (no con el hábitat completo
		          de Blender, IceHabitat: ese trae sus luces)
	La luz fría del cielo y la niebla de la atmósfera las mezcla SkyCycle
	(SkyMoods.ice según CraterMode.iceBlend); la bruma del cráter la pone ZoneMood.
	Todo local; los emisores pasan por FxQuality (modo rápido = sin partículas).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Assets = require(ReplicatedStorage.Shared.Assets)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local IceParts = require(script.Parent.IceParts)
local LairParts = require(script.Parent.LairParts)

local I = IceParts
local P = LairParts
local L = WorldLayout
local WATER = L.waterLevel
local rgb = Color3.fromRGB
local SNOW_SPAN = L.craterCliffRadius * 2.1 -- un poco más que el cráter: nieva también en el borde
local SNOW_HEIGHT = L.craterRimHeight + 70
local SNOW_RATE = 55
local DUST_RATE = 14
local FOG_RATE = 9
local SHORE_GLOWS = 4 -- luces frías al pie del acantilado
local SHORE_LIGHT = rgb(170, 220, 255)

local IceAir = {}

local folder = Instance.new("Folder")
folder.Name = "AireFrio"
local glows = Instance.new("Folder") -- las luces de la orilla
glows.Name = "LucesOrilla"

local function fade(a: number, b: number, c: number): NumberSequence
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(a, b),
		NumberSequenceKeypoint.new(1, c),
	})
end

local function snow()
	local sky = P.holder(
		folder,
		CFrame.new(P.CENTER + Vector3.new(0, SNOW_HEIGHT, 0)),
		Vector3.new(SNOW_SPAN, 2, SNOW_SPAN)
	)
	local flakes = P.emitter(
		sky,
		Assets.Particles.Brasa,
		ColorSequence.new(I.SNOW, I.CRYSTAL_LIGHT),
		NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.45),
			NumberSequenceKeypoint.new(1, 0.3),
		}),
		SNOW_RATE
	)
	flakes.Shape = Enum.ParticleEmitterShape.Box
	flakes.EmissionDirection = Enum.NormalId.Bottom
	flakes.Lifetime = NumberRange.new(18, 26)
	flakes.Speed = NumberRange.new(3, 5.5)
	flakes.Acceleration = Vector3.new(0.9, -0.15, 0.5) -- el viento las lleva de costado
	flakes.RotSpeed = NumberRange.new(-60, 60)
	flakes.Transparency = fade(0.08, 0.1, 0.6)
end

local function diamondDust()
	local span = L.craterLakeRadius * 1.6
	local box = P.holder(
		folder,
		CFrame.new(P.CENTER + Vector3.new(0, WATER + 14, 0)),
		Vector3.new(span, 24, span)
	)
	local dust = P.emitter(
		box,
		Assets.Particles.Chispa,
		ColorSequence.new(I.GLOW, I.CRYSTAL),
		NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.5, 0.6),
			NumberSequenceKeypoint.new(1, 0),
		}),
		DUST_RATE
	)
	dust.Shape = Enum.ParticleEmitterShape.Box
	dust.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	dust.LightEmission = 0.8
	dust.Lifetime = NumberRange.new(2.5, 4.5)
	dust.Speed = NumberRange.new(0.2, 0.8)
	dust.SpreadAngle = Vector2.new(180, 180)
end

local function fog()
	local span = L.craterLakeRadius * 1.7
	local box = P.holder(
		folder,
		CFrame.new(P.CENTER + Vector3.new(0, WATER + 2, 0)),
		Vector3.new(span, 2, span)
	)
	local mist = P.emitter(
		box,
		Assets.Particles.Mist,
		ColorSequence.new(rgb(236, 246, 255), rgb(196, 224, 244)),
		NumberSequence.new(16, 34),
		FOG_RATE
	)
	mist.Shape = Enum.ParticleEmitterShape.Box
	mist.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	mist.Lifetime = NumberRange.new(10, 15)
	mist.Speed = NumberRange.new(1, 2.5)
	mist.SpreadAngle = Vector2.new(180, 6) -- se arrastra, casi no sube
	mist.Acceleration = Vector3.new(0.4, 0.1, 0.2)
	mist.RotSpeed = NumberRange.new(-6, 6)
	mist.Transparency = fade(0.3, 0.8, 1)
end

local function build()
	snow()
	diamondDust()
	fog()
	for k = 1, SHORE_GLOWS do
		local angle = (k + 0.25) / SHORE_GLOWS * math.pi * 2
		local at = P.at(angle, L.craterLakeRadius - 12, WATER + 10)
		P.light(P.holder(glows, CFrame.new(at)), SHORE_LIGHT, 0.6, 60)
	end
end

-- complete: está el hábitat completo (sin las luces de la orilla).
function IceAir.show(complete: boolean)
	if #folder:GetChildren() == 0 then
		build()
	end
	glows.Parent = if complete then nil else folder
	folder.Parent = Workspace
end

function IceAir.hide()
	folder.Parent = nil
end

return table.freeze(IceAir)
