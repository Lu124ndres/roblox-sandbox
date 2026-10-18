--!strict
--[[
	EventFx

	Lo que pasa en el mundo durante un evento del servidor (solo en este
	cliente, alrededor de la cámara), para que se note cuál hay:
		PescaDorada    destellos dorados que caen despacio del cielo
		Frenesi        lluvia celeste y relámpagos con trueno cada pocos segundos
		LluviaMonedas  monedas de oro que llueven girando (EventShapes), con destellos
		PoderDoble     una aurora violeta y celeste que ondula en el cielo (EventShapes)
	Entra y sale con la mezcla del cielo (EventSky). En modo rápido (FxQuality)
	hay menos partículas y monedas, y no hay aurora.
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Assets = require(ReplicatedStorage.Shared.Assets)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local FxQuality = require(script.Parent.Parent.Settings.FxQuality)
local EventShapes = require(script.Parent.EventShapes)

local CLOUD_HEIGHT = 40 -- la nube invisible que suelta las partículas, sobre la cámara
local COINS = 30
local FLASH = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local THUNDER_EVERY = NumberRange.new(4, 8) -- segundos entre relámpagos

local EventFx = {}

type Source = () -> (string?, number)

local function emitter(cloud: BasePart, settings: { [string]: any }): ParticleEmitter
	local particles = Instance.new("ParticleEmitter")
	particles.EmissionDirection = Enum.NormalId.Bottom
	particles.LightEmission = 1
	particles.Enabled = false
	for key, value in settings do
		(particles :: any)[key] = value
	end
	particles.Parent = cloud
	FxQuality.scaleEmitter(particles)
	return particles
end

local function makeEmitters(cloud: BasePart): { [string]: { ParticleEmitter } }
	local gold = emitter(cloud, {
		Texture = Assets.Particles.Sparkle,
		Color = ColorSequence.new(Color3.fromRGB(255, 214, 80)),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.3, 0.9),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Lifetime = NumberRange.new(5, 7),
		Speed = NumberRange.new(3, 6),
		SpreadAngle = Vector2.new(15, 15),
		RotSpeed = NumberRange.new(-90, 90),
		Rate = 60,
	})
	local rain = emitter(cloud, {
		Texture = Assets.Particles.Brasa,
		Color = ColorSequence.new(Color3.fromRGB(150, 230, 255)),
		Size = NumberSequence.new(0.14),
		Squash = NumberSequence.new(3),
		Orientation = Enum.ParticleOrientation.VelocityParallel,
		Transparency = NumberSequence.new(0.3),
		Lifetime = NumberRange.new(0.6, 0.9),
		Speed = NumberRange.new(80, 95),
		SpreadAngle = Vector2.new(4, 4),
		Rate = 260,
	})
	local glints = emitter(cloud, {
		Texture = Assets.Particles.Chispa,
		Color = ColorSequence.new(Color3.fromRGB(255, 200, 60)),
		Size = NumberSequence.new(0.6, 0),
		Lifetime = NumberRange.new(3, 4),
		Speed = NumberRange.new(8, 12),
		Rate = 25,
	})
	local motes = emitter(cloud, {
		Texture = Assets.Particles.Sparkle,
		Color = ColorSequence.new(Color3.fromRGB(190, 140, 255), Color3.fromRGB(120, 230, 255)),
		Size = NumberSequence.new(0.7, 0),
		Lifetime = NumberRange.new(4, 6),
		Speed = NumberRange.new(2, 4),
		Rate = 35,
	})
	return {
		PescaDorada = { gold },
		Frenesi = { rain },
		LluviaMonedas = { glints },
		PoderDoble = { motes },
	}
end

local function flash(correction: ColorCorrectionEffect)
	Sounds.play("Thunder")
	for _, peak in { 0.55, 0.3 } do
		correction.Brightness = peak
		TweenService:Create(correction, FLASH, { Brightness = 0 }):Play()
		task.wait(0.18)
	end
end

function EventFx.start(source: Source)
	local folder = Instance.new("Folder")
	folder.Name = "EventoFx"
	folder.Parent = Workspace
	local cloud = Instance.new("Part")
	cloud.Name = "Nube"
	cloud.Size = Vector3.new(140, 1, 140)
	cloud.Transparency = 1
	cloud.Anchored = true
	cloud.CanCollide, cloud.CanQuery, cloud.CanTouch = false, false, false
	cloud.Parent = folder
	local emitters = makeEmitters(cloud)
	local low = FxQuality.rateScale() < 1
	local coins = EventShapes.coins(folder, if low then 12 else COINS)
	local aurora = if low then {} else EventShapes.aurora(folder)
	local correction = Instance.new("ColorCorrectionEffect")
	correction.Name = "RelampagoEvento"
	correction.Parent = Lighting
	local nextThunder = 0
	local shown = { coins = false, aurora = false }

	RunService.RenderStepped:Connect(function(dt: number)
		local id, blend = source()
		local eye = Workspace.CurrentCamera.CFrame.Position
		local t = os.clock()
		cloud.Position = eye + Vector3.new(0, CLOUD_HEIGHT, 0)
		for kind, list in emitters do
			for _, particles in list do
				particles.Enabled = kind == id and blend > 0.4
			end
		end
		-- Las piezas solo se mueven mientras se ven (o hasta dejarlas ocultas).
		local coinFade = if id == "LluviaMonedas" then blend else 0
		if coinFade > 0 or shown.coins then
			EventShapes.updateCoins(coins, eye, t, dt, coinFade)
			shown.coins = coinFade > 0
		end
		local auroraFade = if id == "PoderDoble" then blend else 0
		if auroraFade > 0 or shown.aurora then
			EventShapes.updateAurora(aurora, eye, t, auroraFade)
			shown.aurora = auroraFade > 0
		end
		if id == "Frenesi" and blend > 0.6 and t >= nextThunder then
			nextThunder = t
				+ THUNDER_EVERY.Min
				+ math.random() * (THUNDER_EVERY.Max - THUNDER_EVERY.Min)
			task.spawn(flash, correction)
		end
	end)
end

return EventFx
