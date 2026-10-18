--!strict
--[[
	FeedBurst

	Los efectos de cada mordida del gigante, sin crear nada nuevo cada vez
	(con 10 peces por segundo, crear y destruir piezas y emisores daba tirones):
		shockwave  esfera de neón que se abre y se apaga; hay POOL esferas que
		           se turnan
		sparkle    chispas del color del pez: un emisor fijo por color, que se
		           mueve a la boca y suelta `count` partículas
	Solo efecto visual.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Assets = require(ReplicatedStorage.Shared.Assets)
local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)

local POOL = 8
local OPEN = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local HIDDEN = Vector3.new(0, -2000, 0)

local FeedBurst = {}

local folder = Instance.new("Folder")
folder.Name = "MordidaEfectos"
folder.Parent = Workspace

local balls: { Part } = {}
for index = 1, POOL do
	local ball = Instance.new("Part")
	ball.Name = `Onda{index}`
	ball.Shape = Enum.PartType.Ball
	ball.Material = Enum.Material.Neon
	ball.Anchored, ball.CanCollide, ball.CanQuery, ball.CanTouch = true, false, false, false
	ball.CastShadow = false
	ball.Transparency = 1
	ball.Position = HIDDEN
	ball.Parent = folder
	balls[index] = ball
end
local nextBall = 1

-- Onda de choque: una esfera de neón que se abre y se apaga.
function FeedBurst.shockwave(position: Vector3, radius: number, color: Color3)
	local ball = balls[nextBall]
	nextBall = nextBall % POOL + 1
	ball.Color = color
	ball.Transparency = 0.25
	ball.Size = Vector3.one * radius * 0.3
	ball.Position = position
	TweenService:Create(ball, OPEN, { Size = Vector3.one * radius * 2.2, Transparency = 1 }):Play()
end

local emitters: { [string]: { anchor: Attachment, particles: ParticleEmitter } } = {}

local function emitterFor(color: Color3)
	local key = color:ToHex()
	local found = emitters[key]
	if found then
		return found
	end
	local anchor = Instance.new("Attachment")
	anchor.Name = `Chispas{key}`
	anchor.Parent = Workspace.Terrain
	local particles = Instance.new("ParticleEmitter")
	particles.Texture = Assets.Particles.Sparkle
	particles.Color = ColorSequence.new(color)
	particles.Enabled = false
	particles.Rate = 0
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.3, 1),
		NumberSequenceKeypoint.new(1, 0),
	})
	particles.Lifetime = NumberRange.new(0.6, 1)
	particles.Speed = NumberRange.new(6, 12)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Rotation = NumberRange.new(0, 360)
	particles.RotSpeed = NumberRange.new(-90, 90)
	particles.LightEmission = 1
	particles.Drag = 3
	particles.Parent = anchor
	found = { anchor = anchor, particles = particles }
	emitters[key] = found
	return found
end

-- Chispas del color `color` en `position`.
function FeedBurst.sparkle(position: Vector3, color: Color3, count: number)
	local amount = math.round(count * ClientSettings.fxScale())
	if amount <= 0 then
		return
	end
	local emitter = emitterFor(color)
	emitter.anchor.WorldPosition = position
	emitter.particles:Emit(amount)
end

return FeedBurst
