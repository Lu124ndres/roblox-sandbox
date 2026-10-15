--!strict
--[[
	Fx

	Efectos visuales locales reutilizables: salpicaduras, ondas en el agua,
	destellos, chorro del gigante y corazones. Todo es del cliente (no viaja
	por la red) y se limpia solo. Las texturas son las de partículas que
	trae Roblox instaladas (Assets.Particles), así que no hay nada que subir.
]]

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Assets = require(ReplicatedStorage.Shared.Assets)
local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)

local WATER_WHITE = Color3.fromRGB(235, 250, 255)
local WATER_BLUE = Color3.fromRGB(150, 220, 240)

local Fx = {}

local holderFolder = Instance.new("Folder")
holderFolder.Name = "EfectosLocales"
holderFolder.Parent = Workspace

-- Ráfaga de partículas; en modo rápido no sale ninguna.
local function burst(particles: ParticleEmitter, count: number)
	local amount = math.round(count * ClientSettings.fxScale())
	if amount > 0 then
		particles:Emit(math.max(1, amount))
	end
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
	particles.EmissionDirection = Enum.NormalId.Top
	particles.Rotation = NumberRange.new(0, 360)
	particles.RotSpeed = NumberRange.new(-90, 90)
	particles.Parent = parent
	return particles
end

local function droplets(parent: Instance, scale: number, count: number)
	local drops = emitter(parent, Assets.Particles.Sparkle, WATER_BLUE)
	drops.Size = NumberSequence.new(0.45 * scale, 0.1)
	drops.Transparency = NumberSequence.new(0, 1)
	drops.Lifetime = NumberRange.new(0.5, 0.9)
	drops.Speed = NumberRange.new(14 * scale, 24 * scale)
	drops.SpreadAngle = Vector2.new(30, 30)
	drops.Acceleration = Vector3.new(0, -70, 0)
	drops.LightEmission = 0.4
	burst(drops, count)
end

local function mist(parent: Instance, scale: number, count: number)
	local cloud = emitter(parent, Assets.Particles.Mist, WATER_WHITE)
	cloud.Size = NumberSequence.new(1.4 * scale, 4 * scale)
	cloud.Transparency = NumberSequence.new(0.35, 1)
	cloud.Lifetime = NumberRange.new(0.7, 1.2)
	cloud.Speed = NumberRange.new(5 * scale, 11 * scale)
	cloud.SpreadAngle = Vector2.new(45, 45)
	cloud.Acceleration = Vector3.new(0, -10, 0)
	burst(cloud, count)
end

-- Onda circular que se abre sobre el agua y se desvanece.
function Fx.ring(position: Vector3, radius: number, seconds: number?)
	local duration = seconds or 0.9
	local ring = Instance.new("Part")
	ring.Name = "Onda"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.12, radius * 0.4, radius * 0.4)
	ring.CFrame = CFrame.new(position + Vector3.new(0, 0.08, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Color = WATER_WHITE
	ring.Material = Enum.Material.SmoothPlastic
	ring.Transparency = 0.35
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.CastShadow = false
	ring.Parent = holderFolder
	local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService
		:Create(ring, info, { Size = Vector3.new(0.12, radius * 2, radius * 2), Transparency = 1 })
		:Play()
	Debris:AddItem(ring, duration + 0.1)
end

-- Salpicadura completa: gotas, bruma y onda. scale 1 = un corcho; 4 = un gigante.
function Fx.splash(position: Vector3, scale: number)
	local attachment = anchorAt(position, 2)
	droplets(attachment, scale, math.floor(10 + 6 * scale))
	mist(attachment, scale, math.floor(4 + 2 * scale))
	Fx.ring(position, 2.5 * scale)
end

function Fx.sparkle(position: Vector3, color: Color3, count: number?)
	local attachment = anchorAt(position, 2)
	local stars = emitter(attachment, Assets.Particles.Sparkle, color)
	stars.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.3, 1),
		NumberSequenceKeypoint.new(1, 0),
	})
	stars.Lifetime = NumberRange.new(0.6, 1)
	stars.Speed = NumberRange.new(6, 12)
	stars.SpreadAngle = Vector2.new(180, 180)
	stars.LightEmission = 1
	stars.Drag = 3
	burst(stars, count or 18)
end

-- Chorro de agua hacia arriba durante un segundo (el espiráculo de la orca).
function Fx.spout(position: Vector3, scale: number)
	local attachment = anchorAt(position, 3)
	local jet = emitter(attachment, Assets.Particles.Mist, WATER_WHITE)
	jet.Size = NumberSequence.new(0.8 * scale, 2.6 * scale)
	jet.Transparency = NumberSequence.new(0.2, 1)
	jet.Lifetime = NumberRange.new(0.8, 1.2)
	jet.Speed = NumberRange.new(26 * scale, 34 * scale)
	jet.SpreadAngle = Vector2.new(7, 7)
	jet.Acceleration = Vector3.new(0, -40 * scale, 0)
	jet.Rate = 60
	jet.Enabled = true
	droplets(attachment, scale, 24)
	task.delay(1, function()
		jet.Enabled = false
	end)
end

-- Corazones que suben y se desvanecen (cuando el gigante come).
function Fx.hearts(position: Vector3, count: number)
	for index = 1, count do
		local anchor =
			anchorAt(position + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3)), 2.5)
		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.fromOffset(46, 46)
		billboard.AlwaysOnTop = true
		billboard.LightInfluence = 0
		billboard.Adornee = anchor
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = "♥"
		label.TextScaled = true
		label.TextColor3 = Color3.fromRGB(255, 110, 150)
		label.TextStrokeTransparency = 0.4
		label.Parent = billboard
		billboard.Parent = anchor
		local info =
			TweenInfo.new(1.6 + index * 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(billboard, info, { StudsOffset = Vector3.new(0, 7, 0) }):Play()
		TweenService:Create(label, info, { TextTransparency = 1, TextStrokeTransparency = 1 })
			:Play()
	end
end

return Fx
