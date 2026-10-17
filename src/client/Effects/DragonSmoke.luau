--!strict
--[[
	DragonSmoke

	El humo que sale de la boca y la nariz del dragón (un dragón de fuego
	siempre echa algo): forward es hacia dónde mira la cabeza.
		nostrils(pos, forward, scale)  resoplido en reposo: dos chorritos grises
		                               hacia adelante que suben y se abren
		black(pos, forward, scale)     al terminar el fuego: humo negro espeso
		                               que sigue el chorro y sube
		roar(pos, forward, scale)      al rugir: vaho caliente y unas brasas
		wisp(pos, scale)               dormido: hilos de humo que suben despacio
	Mismo tamaño que DragonDust (DragonKit.scale). En modo rápido no sale nada.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage.Shared.Assets)
local DragonKit = require(script.Parent.DragonKit)

local rgb = Color3.fromRGB
local GREY = ColorSequence.new(rgb(190, 186, 184), rgb(120, 116, 116))
local SOOT = ColorSequence.new(rgb(52, 46, 46), rgb(22, 20, 22))
local HAZE = ColorSequence.new(rgb(255, 210, 160), rgb(160, 150, 150))
local EMBERS = ColorSequence.new(rgb(255, 210, 110), rgb(220, 70, 15))

local DragonSmoke = {}

-- Un Attachment mirando hacia forward (los emisores salen por su frente).
local function aimed(position: Vector3, forward: Vector3, lifetime: number): Attachment
	local attachment = DragonKit.anchor(position, lifetime)
	local dir = if forward.Magnitude > 1e-3 then forward.Unit else Vector3.yAxis
	local up = if math.abs(dir.Y) > 0.95 then Vector3.zAxis else Vector3.yAxis
	attachment.WorldCFrame = CFrame.lookAt(position, position + dir, up)
	return attachment
end

local function smoke(parent: Instance, color: ColorSequence, scale: number): ParticleEmitter
	local puff = DragonKit.emitter(parent, Assets.Particles.Mist, color, false)
	puff.EmissionDirection = Enum.NormalId.Front
	puff.Size = NumberSequence.new(0.4 * scale, 2.2 * scale)
	puff.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.55),
		NumberSequenceKeypoint.new(0.5, 0.75),
		NumberSequenceKeypoint.new(1, 1),
	})
	puff.Lifetime = NumberRange.new(1.2, 2)
	puff.Drag = 2
	puff.Acceleration = Vector3.new(0, 1.5 * scale, 0)
	return puff
end

function DragonSmoke.nostrils(position: Vector3, forward: Vector3, scale: number)
	local attachment = aimed(position, forward, 3)
	local puff = smoke(attachment, GREY, scale)
	puff.Speed = NumberRange.new(5 * scale, 9 * scale)
	puff.SpreadAngle = Vector2.new(12, 12)
	DragonKit.burst(puff, 6)
end

function DragonSmoke.black(position: Vector3, forward: Vector3, scale: number)
	local attachment = aimed(position, forward, 4)
	local soot = smoke(attachment, SOOT, scale)
	soot.Size = NumberSequence.new(1.2 * scale, 6 * scale)
	soot.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(0.6, 0.6),
		NumberSequenceKeypoint.new(1, 1),
	})
	soot.Lifetime = NumberRange.new(2, 3.2)
	soot.Speed = NumberRange.new(8 * scale, 16 * scale)
	soot.SpreadAngle = Vector2.new(20, 20)
	soot.Acceleration = Vector3.new(0, 2.5 * scale, 0)
	DragonKit.burst(soot, 10 + scale)
end

function DragonSmoke.roar(position: Vector3, forward: Vector3, scale: number)
	local attachment = aimed(position, forward, 3)
	local haze = smoke(attachment, HAZE, scale)
	haze.Speed = NumberRange.new(10 * scale, 18 * scale)
	haze.SpreadAngle = Vector2.new(25, 25)
	haze.Transparency = NumberSequence.new(0.75, 1)
	DragonKit.burst(haze, 8)
	local ember = DragonKit.emitter(attachment, Assets.Particles.Brasa, EMBERS, true)
	ember.EmissionDirection = Enum.NormalId.Front
	ember.Size = NumberSequence.new(0.25 * scale, 0)
	ember.Lifetime = NumberRange.new(0.8, 1.4)
	ember.Speed = NumberRange.new(10 * scale, 20 * scale)
	ember.SpreadAngle = Vector2.new(30, 30)
	ember.Drag = 1.5
	ember.Acceleration = Vector3.new(0, 2 * scale, 0)
	DragonKit.burst(ember, 10)
end

function DragonSmoke.wisp(position: Vector3, scale: number)
	local attachment = DragonKit.anchor(position, 4)
	local puff = smoke(attachment, GREY, 0.7 * scale)
	puff.EmissionDirection = Enum.NormalId.Top
	puff.Speed = NumberRange.new(1 * scale, 2.5 * scale)
	puff.SpreadAngle = Vector2.new(15, 15)
	puff.Lifetime = NumberRange.new(2, 3)
	DragonKit.burst(puff, 4)
end

return table.freeze(DragonSmoke)
