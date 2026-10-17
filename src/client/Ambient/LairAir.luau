--!strict
--[[
	LairAir

	El aire de la guarida volcánica mientras está la lava del dragón:
		humo      columnas altas y oscuras que suben de la laguna, con chispas;
		ceniza    copos grises (y alguna brasa) que caen sobre todo el cráter;
		calor     un vaho tibio y lento sobre la lava (el aire que tiembla);
		resplandor luces rojas al pie del acantilado que tiñen las paredes;
		retumbo   el volcán ruge bajito (en bucle), más fuerte cuanto más
		          cerca del cráter está la cámara.
	La luz roja del cielo la mezcla SkyCycle (SkyMoods.lair). Todo local;
	los emisores pasan por FxQuality (modo rápido = sin partículas).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Assets = require(ReplicatedStorage.Shared.Assets)
local Guarida = require(ReplicatedStorage.Shared.Dragon.Guarida)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local LairParts = require(script.Parent.LairParts)

local P = LairParts
local L = WorldLayout
local LAVA = Guarida.lava
local rgb = Color3.fromRGB
local PLUMES = { { 125, 60 }, { 250, 70 }, { 10, 75 }, { 180, 104 } } -- ángulo (grados) y radio
local GLOWS = 5 -- luces rojas al pie del acantilado
local ASH_SPAN = L.craterCliffRadius * 1.9
local ASH_HEIGHT = L.craterRimHeight + 60
local VOLUME_STEP = 0.3 -- cada cuánto se ajusta el retumbo (s)
local RUMBLE_VOLUME = 0.55

Sounds.define({ LairRumble = { volume = RUMBLE_VOLUME } })

local LairAir = {}

local folder = Instance.new("Folder")
folder.Name = "AireDeLaGuarida"
local generation = 0

local function plume(degrees: number, radius: number)
	local holder = P.holder(
		folder,
		CFrame.new(P.at(math.rad(degrees), radius, LAVA + 1)),
		Vector3.new(10, 1, 10)
	)
	local smoke = P.emitter(
		holder,
		Assets.Particles.Mist,
		ColorSequence.new(P.SMOKE, rgb(96, 88, 86)),
		NumberSequence.new(12, 46),
		2.5
	)
	smoke.Shape = Enum.ParticleEmitterShape.Box
	smoke.Lifetime = NumberRange.new(10, 14)
	smoke.Speed = NumberRange.new(9, 14)
	smoke.SpreadAngle = Vector2.new(8, 8)
	smoke.Acceleration = Vector3.new(1.5, 0.5, 1)
	smoke.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.1, 0.45),
		NumberSequenceKeypoint.new(1, 1),
	})
	smoke.RotSpeed = NumberRange.new(-10, 10)
	local sparks = P.emitter(
		holder,
		Assets.Particles.Spark,
		ColorSequence.new(P.MAGMA_HOT, P.EMBER),
		NumberSequence.new(0.7, 0),
		6
	)
	sparks.Lifetime = NumberRange.new(2.5, 4)
	sparks.Speed = NumberRange.new(10, 18)
	sparks.SpreadAngle = Vector2.new(15, 15)
	sparks.LightEmission = 1
end

-- Ceniza que cae sobre el cráter: copos grises y algunas brasas.
local function ash()
	local sky = P.holder(
		folder,
		CFrame.new(P.CENTER + Vector3.new(0, ASH_HEIGHT, 0)),
		Vector3.new(ASH_SPAN, 2, ASH_SPAN)
	)
	local kinds = {
		{ color = rgb(150, 140, 138), glow = 0, rate = 34, size = 0.35 }, -- ceniza
		{ color = P.MAGMA_HOT, glow = 1, rate = 6, size = 0.3 }, -- brasas
	}
	for _, kind in kinds do
		local flakes = P.emitter(
			sky,
			Assets.Particles.Brasa,
			ColorSequence.new(kind.color),
			NumberSequence.new(kind.size),
			kind.rate
		)
		flakes.Shape = Enum.ParticleEmitterShape.Box
		flakes.EmissionDirection = Enum.NormalId.Bottom
		flakes.Lifetime = NumberRange.new(16, 22)
		flakes.Speed = NumberRange.new(3, 6)
		flakes.Acceleration = Vector3.new(1.2, -0.3, 0.8)
		flakes.LightEmission = kind.glow
		flakes.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.1, 0.2),
			NumberSequenceKeypoint.new(1, 0.9),
		})
	end
end

-- El vaho de calor sobre la laguna.
local function heat()
	local span = L.craterLakeRadius * 1.4
	local box = P.holder(
		folder,
		CFrame.new(P.CENTER + Vector3.new(0, LAVA + 2, 0)),
		Vector3.new(span, 1, span)
	)
	local haze = P.emitter(
		box,
		Assets.Particles.Mist,
		ColorSequence.new(rgb(255, 214, 180)),
		NumberSequence.new(12, 26),
		10
	)
	haze.Shape = Enum.ParticleEmitterShape.Box
	haze.Lifetime = NumberRange.new(3, 5)
	haze.Speed = NumberRange.new(2, 4)
	haze.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.4, 0.88),
		NumberSequenceKeypoint.new(1, 1),
	})
	haze.RotSpeed = NumberRange.new(-25, 25)
	haze.LightEmission = 0.2
end

local function build()
	for _, spot in PLUMES do
		plume(spot[1], spot[2])
	end
	ash()
	heat()
	for k = 1, GLOWS do
		local angle = (k + 0.5) / GLOWS * math.pi * 2
		local at = P.at(angle, L.craterLakeRadius - 30, P.ground(L.craterLakeRadius - 30) + 6)
		P.light(P.holder(folder, CFrame.new(at)), P.MAGMA, 1.4, 60)
	end
end

-- El retumbo sigue a la cámara: fuerte en el cráter, apenas en la isla.
local function rumble(mine: number)
	local sound = Sounds.loop("LairRumble")
	if not sound then
		return
	end
	sound.Volume = 0
	while mine == generation do
		local camera = Workspace.CurrentCamera
		local near = if camera then WorldZones.craterBlend(camera.CFrame.Position) else 0
		local target = RUMBLE_VOLUME * (0.15 + 0.85 * near)
		sound.Volume += (target - sound.Volume) * 0.3
		task.wait(VOLUME_STEP)
	end
	sound:Destroy()
end

function LairAir.show()
	if #folder:GetChildren() == 0 then
		build()
	end
	generation += 1
	folder.Parent = Workspace
	task.spawn(rumble, generation)
end

function LairAir.hide()
	generation += 1
	folder.Parent = nil
end

return table.freeze(LairAir)
