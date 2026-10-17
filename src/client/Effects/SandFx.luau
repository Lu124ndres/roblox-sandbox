--!strict
--[[
	SandFx

	Efectos de arena y polvo para los gigantes del desierto (el minotauro con
	def.sand): lo que en el agua es salpicadura y onda, en la arena es una nube
	de polvo, un faldón de polvo que corre pegado al suelo, granos que saltan y
	un anillo de arena que se abre. Como Fx: todo local, se limpia solo y en
	modo rápido no sale ninguna partícula (ClientSettings.fxScale); el anillo
	sí, porque es una sola pieza. scale 1 = una persona; el minotauro usa
	max(1, alto / 12) x fuerza de la etapa, así que todo crece con él.
		SandFx.puff(pos, scale)          pisada: polvito, granos y anillo chico
		SandFx.slam(pos, scale, radio)   pisotón o caída de un salto
		SandFx.settle(pos, scale)        se sienta: el polvo se abre por el suelo
]]

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Assets = require(ReplicatedStorage.Shared.Assets)
local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)

local SAND = Color3.fromRGB(214, 182, 124)
local DUST = Color3.fromRGB(232, 212, 170)
local SHADE = Color3.fromRGB(170, 134, 84) -- granos de abajo, más oscuros
local SKIRT_DIRECTIONS = 12 -- direcciones del faldón de polvo
local MAX_BURST = 70 -- tope de partículas por ráfaga (la forma final es enorme)

local SandFx = {}

local holderFolder = Instance.new("Folder")
holderFolder.Name = "EfectosArena"
holderFolder.Parent = Workspace

local function amount(count: number): number
	return math.min(MAX_BURST, math.round(count * ClientSettings.fxScale()))
end

local function burst(particles: ParticleEmitter, count: number)
	local n = amount(count)
	if n > 0 then
		particles:Emit(n)
	end
end

local function anchorAt(position: Vector3, lifetime: number): Attachment
	local attachment = Instance.new("Attachment")
	attachment.WorldPosition = position
	attachment.Parent = Workspace.Terrain
	Debris:AddItem(attachment, lifetime)
	return attachment
end

local function emitter(parent: Instance, texture: string, color: ColorSequence): ParticleEmitter
	local particles = Instance.new("ParticleEmitter")
	particles.Texture = texture
	particles.Color = color
	particles.Enabled = false
	particles.Rate = 0
	particles.EmissionDirection = Enum.NormalId.Top
	particles.Rotation = NumberRange.new(0, 360)
	particles.RotSpeed = NumberRange.new(-40, 40)
	particles.LightInfluence = 0.6 -- el polvo se ve de día y no brilla de noche
	particles.Parent = parent
	return particles
end

local function dustEmitter(parent: Instance, scale: number): ParticleEmitter
	local dust = emitter(parent, Assets.Particles.Mist, ColorSequence.new(DUST, SAND))
	dust.Size = NumberSequence.new(1.2 * scale, 4.5 * scale)
	dust.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 0.7),
		NumberSequenceKeypoint.new(1, 1),
	})
	return dust
end

-- Nube que sube despacio, se abre y flota (el polvo no cae como el agua).
local function cloud(parent: Instance, scale: number, count: number)
	local dust = dustEmitter(parent, scale)
	dust.Lifetime = NumberRange.new(1.4, 2.4)
	dust.Speed = NumberRange.new(3 * scale, 8 * scale)
	dust.SpreadAngle = Vector2.new(60, 60)
	dust.Drag = 1.5
	dust.Acceleration = Vector3.new(0, 1.2 * scale, 0)
	burst(dust, count)
end

-- Granos que saltan y caen. La gravedad crece con scale: la parábola se ve
-- igual en el becerro y en la forma final, solo que más grande.
local function grains(parent: Instance, scale: number, count: number)
	local bits = emitter(parent, Assets.Particles.Sparkle, ColorSequence.new(SAND, SHADE))
	bits.Size = NumberSequence.new(0.35 * scale, 0.15 * scale)
	bits.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.8, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	bits.Lifetime = NumberRange.new(0.6, 1.1)
	bits.Speed = NumberRange.new(12 * scale, 22 * scale)
	bits.SpreadAngle = Vector2.new(40, 40)
	bits.Acceleration = Vector3.new(0, -45 * scale, 0)
	bits.LightEmission = 0
	burst(bits, count)
end

-- Faldón: el polvo sale en todas direcciones pegado al suelo y se frena.
-- Un solo emisor que se gira entre ráfagas (sale hacia el frente del Attachment).
local function skirt(position: Vector3, scale: number, count: number)
	local each = math.floor(amount(count) / SKIRT_DIRECTIONS)
	if each < 1 then
		return
	end
	local attachment = anchorAt(position, 3)
	local dust = dustEmitter(attachment, scale)
	dust.EmissionDirection = Enum.NormalId.Front
	dust.Lifetime = NumberRange.new(1, 1.7)
	dust.Speed = NumberRange.new(16 * scale, 26 * scale)
	dust.SpreadAngle = Vector2.new(14, 6)
	dust.Drag = 3
	dust.Acceleration = Vector3.new(0, scale, 0)
	for index = 1, SKIRT_DIRECTIONS do
		local yaw = (index + math.random()) / SKIRT_DIRECTIONS * math.pi * 2
		attachment.WorldCFrame = CFrame.new(position)
			* CFrame.Angles(0, yaw, 0)
			* CFrame.Angles(math.rad(8), 0, 0) -- un poco hacia arriba
		dust:Emit(each)
	end
end

-- Anillo de arena que se abre sobre el suelo y se desvanece.
local function ring(position: Vector3, radius: number, seconds: number)
	local part = Instance.new("Part")
	part.Name = "AnilloArena"
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(0.15, radius * 0.4, radius * 0.4)
	part.CFrame = CFrame.new(position + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
	part.Color = SAND
	part.Material = Enum.Material.Sand
	part.Transparency = 0.35
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Parent = holderFolder
	local info = TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService
		:Create(part, info, { Size = Vector3.new(0.15, radius * 2, radius * 2), Transparency = 1 })
		:Play()
	Debris:AddItem(part, seconds + 0.1)
end

function SandFx.puff(position: Vector3, scale: number)
	local attachment = anchorAt(position, 3)
	cloud(attachment, 0.6 * scale, 3 + scale)
	grains(attachment, 0.5 * scale, 6 + 2 * scale)
	ring(position, 2.2 * scale, 0.9)
end

function SandFx.slam(position: Vector3, scale: number, radius: number)
	local attachment = anchorAt(position, 4)
	cloud(attachment, scale, 6 + 2 * scale)
	grains(attachment, scale, 14 + 4 * scale)
	skirt(position, scale, 24 + 4 * scale)
	ring(position, radius, 1.4)
end

function SandFx.settle(position: Vector3, scale: number)
	local attachment = anchorAt(position, 3)
	cloud(attachment, 0.7 * scale, 4 + scale)
	skirt(position, 0.6 * scale, 16 + 2 * scale)
	ring(position, 2 * scale, 1.1)
end

return table.freeze(SandFx)
