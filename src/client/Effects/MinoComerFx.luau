--!strict
--[[
	MinoComerFx

	Los efectos de las reacciones del minotauro al comer (Minotauro/Comer; MinoStand
	los llama con sus eventos). Como Fx: todo local, se limpia solo y en modo
	rápido no sale ninguna partícula (ClientSettings.fxScale) ni se prende la luz.
	scale 1 = una persona (MinoStand pasa max(1, alto / 12), así crece con él):
		glow(cabeza, punto, rareza, scale)  le brillan los ojos: una luz y un halo del
		                                    color de la rareza pegados al hueso de la
		                                    cabeza y estrellitas alrededor
		goldburst(punto, scale)             revienta en estrellas doradas que suben
		confetti(punto, scale)              papelitos de colores que caen (festejos)
		burp(boca, scale)                   nubecita del eructo
		clap(punto, scale)                  destello blanco al aplaudir
]]

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Assets = require(ReplicatedStorage.Shared.Assets)
local Config = require(ReplicatedStorage.Shared.Config)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)

local GOLD = Color3.fromRGB(255, 206, 84)
local CONFETTI = {
	Color3.fromRGB(255, 92, 92),
	Color3.fromRGB(255, 206, 84),
	Color3.fromRGB(110, 226, 120),
	Color3.fromRGB(80, 170, 255),
	Color3.fromRGB(255, 110, 200),
}
local GLOW_SECONDS = 1.4
local MAX_BURST = 60 -- tope de partículas por ráfaga (la forma final es enorme)

local MinoComerFx = {}

local function amount(count: number): number
	return math.min(MAX_BURST, math.round(count * ClientSettings.fxScale()))
end

local function anchorAt(position: Vector3, lifetime: number): Attachment
	local attachment = Instance.new("Attachment")
	attachment.WorldPosition = position
	attachment.Parent = Workspace.Terrain
	Debris:AddItem(attachment, lifetime)
	return attachment
end

local function emitter(parent: Instance, texture: string, color: Color3): ParticleEmitter
	local particles = Instance.new("ParticleEmitter")
	particles.Texture = texture
	particles.Color = ColorSequence.new(color)
	particles.Enabled = false
	particles.Rate = 0
	particles.Rotation = NumberRange.new(0, 360)
	particles.RotSpeed = NumberRange.new(-120, 120)
	particles.LightEmission = 1
	particles.Parent = parent
	return particles
end

local function burst(particles: ParticleEmitter, count: number)
	local n = amount(count)
	if n > 0 then
		particles:Emit(n)
	end
end

-- El color de la rareza (Config.Economy.rarities por índice; UIConfig.RarityColors).
local function rarityColor(rarity: number): Color3
	local rarities = Config.Economy.rarities
	local def = rarities[math.clamp(rarity, 1, #rarities)]
	return UIConfig.RarityColors[def.id] or GOLD
end

local function stars(parent: Instance, color: Color3, scale: number, count: number)
	local s = emitter(parent, Assets.Particles.Chispa, color)
	s.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2 * scale),
		NumberSequenceKeypoint.new(0.3, 0.9 * scale),
		NumberSequenceKeypoint.new(1, 0),
	})
	s.Lifetime = NumberRange.new(0.6, 1.1)
	s.Speed = NumberRange.new(5 * scale, 11 * scale)
	s.SpreadAngle = Vector2.new(180, 180)
	s.Drag = 3
	burst(s, count)
end

function MinoComerFx.glow(head: Bone?, at: Vector3, rarity: number, scale: number)
	local color = rarityColor(rarity)
	stars(anchorAt(at, 2), color, scale, 10 + 4 * rarity)
	if not head or ClientSettings.get("lowFx") then
		return
	end
	local halo = emitter(head, Assets.Particles.Halo, color)
	halo.LockedToPart = true
	halo.Size = NumberSequence.new(1.6 * scale, 2.6 * scale)
	halo.Transparency = NumberSequence.new(0.35, 1)
	halo.Lifetime = NumberRange.new(0.5, 0.8)
	halo.Speed = NumberRange.new(0)
	halo.Rate = 10
	halo.Enabled = true
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 10 * scale
	light.Brightness = 0
	light.Parent = head
	local up = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local down = TweenInfo.new(GLOW_SECONDS - 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	TweenService:Create(light, up, { Brightness = 4 }):Play()
	task.delay(0.25, function()
		TweenService:Create(light, down, { Brightness = 0 }):Play()
	end)
	task.delay(GLOW_SECONDS - 0.5, function()
		halo.Enabled = false
	end)
	Debris:AddItem(halo, GLOW_SECONDS + 1)
	Debris:AddItem(light, GLOW_SECONDS + 0.1)
end

function MinoComerFx.goldburst(at: Vector3, scale: number)
	local attachment = anchorAt(at, 3)
	stars(attachment, GOLD, 1.4 * scale, 40)
	local rise = emitter(attachment, Assets.Particles.Brasa, GOLD)
	rise.Size = NumberSequence.new(0.5 * scale, 0)
	rise.Lifetime = NumberRange.new(1.2, 2)
	rise.Speed = NumberRange.new(2 * scale, 6 * scale)
	rise.SpreadAngle = Vector2.new(60, 60)
	rise.Acceleration = Vector3.new(0, 6 * scale, 0)
	burst(rise, 30)
end

function MinoComerFx.confetti(at: Vector3, scale: number)
	local attachment = anchorAt(at, 4)
	for _, color in CONFETTI do
		local bits = emitter(attachment, Assets.Particles.Sparkle, color)
		bits.LightEmission = 0.3
		bits.Size = NumberSequence.new(0.45 * scale, 0.3 * scale)
		bits.Lifetime = NumberRange.new(1.6, 2.4)
		bits.Speed = NumberRange.new(14 * scale, 24 * scale)
		bits.SpreadAngle = Vector2.new(50, 50)
		bits.Acceleration = Vector3.new(0, -14 * scale, 0)
		bits.Drag = 1.2
		bits.RotSpeed = NumberRange.new(-300, 300)
		burst(bits, 8)
	end
end

function MinoComerFx.burp(mouth: Vector3, scale: number)
	local puff = emitter(anchorAt(mouth, 3), Assets.Particles.Mist, Color3.fromRGB(236, 240, 220))
	puff.LightEmission = 0
	puff.Size = NumberSequence.new(0.4 * scale, 1.6 * scale)
	puff.Transparency = NumberSequence.new(0.3, 1)
	puff.Lifetime = NumberRange.new(0.8, 1.2)
	puff.Speed = NumberRange.new(2 * scale, 4 * scale)
	puff.SpreadAngle = Vector2.new(30, 30)
	puff.Acceleration = Vector3.new(0, 1.5 * scale, 0)
	puff.Drag = 2
	burst(puff, 6)
end

function MinoComerFx.clap(at: Vector3, scale: number)
	stars(anchorAt(at, 2), Color3.new(1, 1, 1), 0.6 * scale, 8)
end

return table.freeze(MinoComerFx)
