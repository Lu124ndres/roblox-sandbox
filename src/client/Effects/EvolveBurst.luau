--!strict
--[[
	EvolveBurst

	El estallido de la evolución y la calma que le sigue (EvolveFx):
		- destello: una esfera de neón blanca que se abre y se apaga, más un
		  destello de pantalla que depende de lo cerca que esté el jugador;
		  tapa el cambio de modelo, que pasa en este mismo cuadro;
		- columna de luz hacia el cielo que se afina y desaparece;
		- onda expansiva en el suelo (dos aros) y, en el agua, salpicadura;
		- chispas que salen disparadas y caen en arco;
		- polvo o bruma que se abre por el suelo y se disipa despacio;
		- en la calma, chispas doradas que caen alrededor mientras crece.
	Escala con el alto viejo (destello) y el nuevo (columna, onda, polvo).
	Con el modo rápido (light) no hay partículas.
]]

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Assets = require(ReplicatedStorage.Shared.Assets)
local EvolveParts = require(script.Parent.EvolveParts)
local Fx = require(script.Parent.Fx)

export type Burst = {
	folder: Instance,
	center: Vector3,
	ground: Vector3,
	oldHeight: number,
	newHeight: number,
	accent: Color3,
	core: Color3,
	gold: Color3,
	dust: Color3,
	water: boolean, -- el suelo es agua: salpica
	light: boolean, -- modo rápido
	rate: number, -- multiplicador de partículas (0 en modo rápido)
	near: number, -- 0 lejos del cráter, 1 adentro
}

local WHITE = Color3.new(1, 1, 1)
local MAX_SPEED = 260 -- studs/s de las chispas más rápidas
local MAX_RING = 330 -- radio máximo de la onda del suelo

local EvolveBurst = {}

local function tween(
	instance: Instance,
	seconds: number,
	goal: { [string]: any },
	style: Enum.EasingStyle?
)
	local info = TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(instance, info, goal):Play()
end

local function count(base: number, rate: number): number
	return math.round(base * rate)
end

local function flash(b: Burst)
	local sphere = EvolveParts.neon(b.folder, Enum.PartType.Ball, WHITE)
	sphere.Size = Vector3.one * b.oldHeight * 1.2
	sphere.CFrame = CFrame.new(b.center)
	tween(sphere, 0.5, { Size = Vector3.one * b.oldHeight * 2.2, Transparency = 1 })
	local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	EvolveParts.screenFlash(playerGui, WHITE, 0.15 + 0.55 * b.near, 0.6)
end

-- Columna vertical (los cilindros de Roblox van a lo largo de X: se giran 90°).
local function beam(b: Burst, color: Color3, widthFactor: number, transparency: number)
	local length = math.clamp(b.newHeight * 7, 500, 2000)
	local width = b.newHeight * widthFactor
	local part = EvolveParts.neon(b.folder, Enum.PartType.Cylinder, color)
	part.Size = Vector3.new(length, width, width)
	part.CFrame = CFrame.new(b.ground + Vector3.new(0, length / 2, 0))
		* CFrame.Angles(0, 0, math.rad(90))
	part.Transparency = transparency
	local thin = Vector3.new(length, width * 0.05, width * 0.05)
	tween(part, 1.2, { Size = thin, Transparency = 1 }, Enum.EasingStyle.Quart)
end

local function column(b: Burst)
	beam(b, b.accent, 0.34, 0.2)
	beam(b, WHITE, 0.14, 0) -- núcleo blanco
end

local function shockwave(b: Burst)
	local radius = math.min(b.newHeight * 1.7, MAX_RING)
	EvolveParts.groundRing(b.folder, b.ground, b.accent, b.oldHeight * 0.5, radius * 2, 1.1)
	EvolveParts.groundRing(b.folder, b.ground, WHITE, b.oldHeight * 0.3, radius * 1.2, 0.6)
	if b.water then
		Fx.splash(b.ground, 3 + b.newHeight / 25)
		Fx.ring(b.ground, radius * 0.8, 1.6)
	end
end

local function holder(position: Vector3, lifetime: number): Attachment
	local attachment = Instance.new("Attachment")
	attachment.WorldPosition = position
	attachment.Parent = Workspace.Terrain
	Debris:AddItem(attachment, lifetime)
	return attachment
end

local function sparks(b: Burst)
	local h = b.newHeight
	local burst =
		EvolveParts.emitter(holder(b.center, 3), Assets.Particles.Chispa, b.core, b.accent)
	burst.Lifetime = NumberRange.new(0.8, 1.4)
	burst.Speed = NumberRange.new(math.min(h * 0.7, MAX_SPEED * 0.6), math.min(h * 1.4, MAX_SPEED))
	burst.SpreadAngle = Vector2.new(180, 180)
	burst.Drag = 2
	burst.Acceleration = Vector3.new(0, -math.min(h * 0.5, 80), 0)
	burst.Size = EvolveParts.sizes(math.min(h * 0.045, 6), 0.2)
	burst:Emit(count(90, b.rate))
	local glow = EvolveParts.emitter(holder(b.center, 3), Assets.Particles.Halo, WHITE, b.accent)
	glow.Lifetime = NumberRange.new(0.6)
	glow.Speed = NumberRange.new(0)
	glow.RotSpeed = NumberRange.new(0)
	glow.Size = EvolveParts.sizes(math.min(b.oldHeight * 1.4, 100), 1.6)
	glow.Transparency = NumberSequence.new(0, 1)
	glow:Emit(count(1, b.rate))
end

local function dust(b: Burst)
	local h = b.newHeight
	local cloud = EvolveParts.emitter(holder(b.ground, 4), Assets.Particles.Mist, b.dust, b.dust)
	cloud.LightEmission = 0.2
	cloud.Lifetime = NumberRange.new(1.6, 2.4)
	cloud.Speed = NumberRange.new(math.min(h * 0.6, 140), math.min(h * 1.1, 220))
	cloud.SpreadAngle = Vector2.new(85, 85) -- casi rasante, hacia todos lados
	cloud.Drag = 2.2
	cloud.Acceleration = Vector3.new(0, math.min(h * 0.05, 8), 0)
	cloud.Size = NumberSequence.new(math.min(h * 0.2, 40), math.min(h * 0.45, 95))
	cloud.Transparency = NumberSequence.new(0.35, 1)
	cloud:Emit(count(28, b.rate))
end

-- Chispas doradas que caen alrededor del gigante durante `seconds`.
local function goldRain(b: Burst, seconds: number)
	local h = b.newHeight
	local sky = EvolveParts.anchor(b.folder, Vector3.new(h * 0.9, 1, h * 0.9))
	sky.CFrame = CFrame.new(b.ground + Vector3.new(0, h * 1.05, 0))
	local rain = EvolveParts.emitter(sky, Assets.Particles.Chispa, b.gold, WHITE)
	rain.Shape = Enum.ParticleEmitterShape.Box
	rain.EmissionDirection = Enum.NormalId.Bottom
	rain.Lifetime = NumberRange.new(1.2, 1.8)
	rain.Speed = NumberRange.new(h * 0.05, h * 0.15)
	rain.Acceleration = Vector3.new(0, -math.min(h * 0.35, 60), 0)
	rain.Drag = 0.6
	rain.Size = EvolveParts.sizes(math.min(h * 0.03, 4), 0.1)
	rain.Rate = 70 * b.rate
	rain.Enabled = b.rate > 0
	task.delay(seconds, function()
		rain.Enabled = false
	end)
end

-- Todo el estallido; calmSeconds = cuánto dura la calma (lluvia dorada).
function EvolveBurst.play(b: Burst, calmSeconds: number)
	flash(b)
	column(b)
	shockwave(b)
	if b.light or b.rate <= 0 then
		return
	end
	sparks(b)
	dust(b)
	goldRain(b, math.max(0.3, calmSeconds - 0.5))
end

return table.freeze(EvolveBurst)
