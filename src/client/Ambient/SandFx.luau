--!strict
--[[
	SandFx

	Ráfagas de arena para el desierto del cráter, como Fx.splash para el agua:
		puff    nube de polvo que se abre y se asienta, con granos que saltan
		        (scale 1 = un pie; 4 = el minotauro cayendo de un salto)
		ring    onda de polvo a ras del suelo que se abre y se desvanece
		pour    cortina de arena que cae desde el borde del acantilado (al llenarse)
	Locales, se limpian solas y se achican con ClientSettings.fxScale() (modo
	rápido = nada). Las puede usar cualquiera que quiera "polvo en vez de
	salpicadura" cuando CraterMode.isSand().
]]

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Assets = require(ReplicatedStorage.Shared.Assets)
local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)

local DUST = Color3.fromRGB(226, 196, 150)
local DUST_DARK = Color3.fromRGB(176, 136, 96)
local GRAIN = Color3.fromRGB(240, 214, 160)

local SandFx = {}

SandFx.DUST = DUST

local function emitter(
	position: Vector3,
	lifetime: number,
	texture: string
): (ParticleEmitter, Attachment)
	local attachment = Instance.new("Attachment")
	attachment.WorldPosition = position
	attachment.Parent = Workspace.Terrain
	Debris:AddItem(attachment, lifetime)
	local particles = Instance.new("ParticleEmitter")
	particles.Texture = texture
	particles.Enabled = false
	particles.Rate = 0
	particles.Rotation = NumberRange.new(0, 360)
	particles.RotSpeed = NumberRange.new(-40, 40)
	particles.Parent = attachment
	return particles, attachment
end

local function burst(particles: ParticleEmitter, count: number)
	local amount = math.round(count * ClientSettings.fxScale())
	if amount > 0 then
		particles:Emit(math.max(1, amount))
	end
end

function SandFx.puff(position: Vector3, scale: number)
	local cloud = emitter(position, 4, Assets.Particles.Mist)
	cloud.Color = ColorSequence.new(DUST, DUST_DARK)
	cloud.Size = NumberSequence.new(2 * scale, 6 * scale)
	cloud.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.45),
		NumberSequenceKeypoint.new(1, 1),
	})
	cloud.Lifetime = NumberRange.new(1.6, 2.8)
	cloud.Speed = NumberRange.new(4 * scale, 9 * scale)
	cloud.SpreadAngle = Vector2.new(80, 80)
	cloud.Drag = 2.5 -- se frena y queda flotando
	cloud.Acceleration = Vector3.new(0, 1.5, 0)
	burst(cloud, math.floor(5 + 3 * scale))
	local grains = emitter(position, 2, Assets.Particles.Sparkle)
	grains.Color = ColorSequence.new(GRAIN)
	grains.Size = NumberSequence.new(0.3 * scale, 0.05)
	grains.Lifetime = NumberRange.new(0.5, 0.9)
	grains.Speed = NumberRange.new(10 * scale, 18 * scale)
	grains.SpreadAngle = Vector2.new(35, 35)
	grains.Acceleration = Vector3.new(0, -60, 0)
	burst(grains, math.floor(8 + 5 * scale))
end

function SandFx.ring(position: Vector3, radius: number)
	local pieces = 10
	for k = 1, pieces do
		local angle = (k + math.random()) / pieces * math.pi * 2
		local outward = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local band, attachment =
			emitter(position + Vector3.new(0, 0.5, 0), 4, Assets.Particles.Mist)
		attachment.WorldCFrame =
			CFrame.lookAt(attachment.WorldPosition, attachment.WorldPosition + outward)
		band.EmissionDirection = Enum.NormalId.Front
		band.Color = ColorSequence.new(DUST)
		band.Size = NumberSequence.new(radius * 0.06 + 2, radius * 0.12 + 5)
		band.Transparency = NumberSequence.new(0.6, 1)
		band.Lifetime = NumberRange.new(1.2, 2)
		band.Speed = NumberRange.new(radius * 0.7, radius * 0.9)
		band.SpreadAngle = Vector2.new(14, 4)
		band.Drag = 1.5
		burst(band, 2 + math.floor(radius / 40))
	end
end

-- Arena que cae del borde hacia adentro durante `seconds`, desde `from` (en el
-- acantilado) apuntando a `inward` (unitario, hacia el centro).
function SandFx.pour(from: Vector3, inward: Vector3, seconds: number)
	local scale = ClientSettings.fxScale()
	if scale <= 0 then
		return
	end
	local attachment = Instance.new("Attachment")
	attachment.WorldCFrame = CFrame.lookAt(from, from + inward)
	attachment.Parent = Workspace.Terrain
	Debris:AddItem(attachment, seconds + 3)
	local fall = Instance.new("ParticleEmitter")
	fall.Texture = Assets.Particles.Mist
	fall.Color = ColorSequence.new(GRAIN, DUST)
	fall.Size = NumberSequence.new(3, 7)
	fall.Transparency = NumberSequence.new(0.25, 1)
	fall.Lifetime = NumberRange.new(1.2, 1.8)
	fall.Speed = NumberRange.new(6, 10)
	fall.EmissionDirection = Enum.NormalId.Front
	fall.SpreadAngle = Vector2.new(12, 12)
	fall.Acceleration = Vector3.new(0, -45, 0)
	fall.Rate = 30 * scale
	fall.Parent = attachment
	task.delay(seconds, function()
		fall.Enabled = false
	end)
end

return table.freeze(SandFx)
