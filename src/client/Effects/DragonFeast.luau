--!strict
--[[
	DragonFeast

	Los efectos de la animación especial al comer del dragón (los pide
	Giant/DragonComer). color es el de la rareza del pez; scale, el de su
	tamaño (DragonKit.scale: 1 = una persona, el anciano ~8).
		sparkles(pos, color, scale)       estrellitas doradas y del color del pez
		                                  que saltan de la boca, con un destello
		flare(pos, color, scale)          llamarada hacia arriba del color del pez:
		                                  lenguas de fuego, chispas y una luz
		fireRing(center, radius, scale)   anillo de fuego que se abre alrededor del
		                                  dragón (llamas hacia afuera y una onda)
		shower(center, radius, scale)     lluvia de chispas doradas que cae
	Respetan el modo rápido (DragonKit.burst: sin partículas ni el destello de
	la llamarada); la onda del anillo se ve igual (una pieza). Todo se borra solo.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Assets = require(ReplicatedStorage.Shared.Assets)
local DragonKit = require(script.Parent.DragonKit)

local rgb = Color3.fromRGB
local GOLD = rgb(255, 214, 90)
local FIRE = ColorSequence.new({
	ColorSequenceKeypoint.new(0, rgb(255, 235, 150)),
	ColorSequenceKeypoint.new(0.5, rgb(255, 130, 30)),
	ColorSequenceKeypoint.new(1, rgb(170, 30, 8)),
})
local RING_FLAMES = 12 -- puntos alrededor del anillo

local DragonFeast = {}

local function fade(from: number): NumberSequence
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, from),
		NumberSequenceKeypoint.new(0.7, (from + 1) / 2),
		NumberSequenceKeypoint.new(1, 1),
	})
end

-- Un Attachment mirando hacia dir (los emisores salen por su frente).
local function aimed(position: Vector3, dir: Vector3, lifetime: number): Attachment
	local attachment = DragonKit.anchor(position, lifetime)
	local up = if math.abs(dir.Unit.Y) > 0.95 then Vector3.zAxis else Vector3.yAxis
	attachment.WorldCFrame = CFrame.lookAt(position, position + dir, up)
	return attachment
end

local function stars(parent: Instance, color: Color3, scale: number): ParticleEmitter
	local e =
		DragonKit.emitter(parent, Assets.Particles.Chispa, ColorSequence.new(GOLD, color), true)
	e.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5 * scale),
		NumberSequenceKeypoint.new(1, 0),
	})
	e.Lifetime = NumberRange.new(0.6, 1.1)
	e.Speed = NumberRange.new(6 * scale, 14 * scale)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Drag = 3
	e.Acceleration = Vector3.new(0, -2 * scale, 0)
	e.RotSpeed = NumberRange.new(-200, 200)
	return e
end

function DragonFeast.sparkles(position: Vector3, color: Color3, scale: number)
	local attachment = DragonKit.anchor(position, 2)
	DragonKit.burst(stars(attachment, color, scale), 14)
	local glow =
		DragonKit.emitter(attachment, Assets.Particles.Halo, ColorSequence.new(color), true)
	glow.Size = NumberSequence.new(1.5 * scale, 4 * scale)
	glow.Transparency = fade(0.4)
	glow.Lifetime = NumberRange.new(0.35, 0.5)
	glow.Speed = NumberRange.new(0, 0)
	DragonKit.burst(glow, 2)
end

function DragonFeast.flare(position: Vector3, color: Color3, scale: number)
	local attachment = aimed(position, Vector3.yAxis, 3)
	local tint = ColorSequence.new({
		ColorSequenceKeypoint.new(0, rgb(255, 250, 230)),
		ColorSequenceKeypoint.new(0.35, color),
		ColorSequenceKeypoint.new(1, color:Lerp(rgb(40, 20, 20), 0.6)),
	})
	local flames = DragonKit.emitter(attachment, Assets.Particles.FuegoFlip, tint, true)
	flames.EmissionDirection = Enum.NormalId.Front
	flames.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
	flames.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
	flames.Size = NumberSequence.new(1.2 * scale, 3.2 * scale)
	flames.Transparency = fade(0.1)
	flames.Lifetime = NumberRange.new(0.5, 0.8)
	flames.Speed = NumberRange.new(14 * scale, 22 * scale)
	flames.SpreadAngle = Vector2.new(12, 12)
	DragonKit.burst(flames, 16)
	local sparks =
		DragonKit.emitter(attachment, Assets.Particles.Spark, ColorSequence.new(GOLD, color), true)
	sparks.EmissionDirection = Enum.NormalId.Front
	sparks.Size = NumberSequence.new(0.3 * scale, 0)
	sparks.Lifetime = NumberRange.new(0.8, 1.4)
	sparks.Speed = NumberRange.new(16 * scale, 28 * scale)
	sparks.SpreadAngle = Vector2.new(30, 30)
	sparks.Acceleration = Vector3.new(0, -6 * scale, 0)
	DragonKit.burst(sparks, 18)
	if DragonKit.amount(10) == 0 then
		return -- modo rápido: tampoco el destello
	end
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = math.min(14 * scale, 60)
	light.Brightness = 5
	light.Shadows = false
	light.Parent = attachment
	TweenService:Create(light, TweenInfo.new(1.2), { Brightness = 0 }):Play()
end

function DragonFeast.fireRing(center: Vector3, radius: number, scale: number)
	for i = 1, RING_FLAMES do
		local angle = i / RING_FLAMES * math.pi * 2
		local out = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local attachment = aimed(center + out * radius * 0.3, out, 2.5)
		local flames = DragonKit.emitter(attachment, Assets.Particles.FuegoFlip, FIRE, true)
		flames.EmissionDirection = Enum.NormalId.Front
		flames.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
		flames.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
		flames.Size = NumberSequence.new(0.8 * scale, 2.4 * scale)
		flames.Transparency = fade(0.15)
		flames.Lifetime = NumberRange.new(0.5, 0.75)
		flames.Speed = NumberRange.new(radius * 1.6, radius * 2)
		flames.SpreadAngle = Vector2.new(8, 8)
		flames.Drag = 2
		DragonKit.burst(flames, 4)
	end
	DragonKit.ring(center, radius, 0.7, rgb(255, 140, 40))
end

function DragonFeast.shower(center: Vector3, radius: number, scale: number)
	for _ = 1, 3 do
		local offset = Vector3.new(math.random() - 0.5, 0.6, math.random() - 0.5) * radius
		local attachment = DragonKit.anchor(center + offset, 3)
		local e = stars(attachment, GOLD, scale)
		e.Lifetime = NumberRange.new(1.2, 2)
		e.Acceleration = Vector3.new(0, -5 * scale, 0)
		e.Drag = 1
		DragonKit.burst(e, 16)
	end
end

return table.freeze(DragonFeast)
