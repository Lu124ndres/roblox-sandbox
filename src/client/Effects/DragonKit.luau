--!strict
--[[
	DragonKit

	Piezas comunes de los efectos del dragón (DragonDust, DragonSmoke): un
	Attachment en el mundo que se borra solo, un emisor apagado listo para
	ráfagas, la ráfaga que respeta el modo rápido (ClientSettings.fxScale: 0 =
	ninguna partícula) con un tope por ráfaga (el anciano mide ~100 studs) y
	un anillo plano que se abre y se desvanece (una sola pieza: se ve también
	en modo rápido). Todo es local y se limpia solo.
]]

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)

local MAX_BURST = 70

local DragonKit = {}

local folder = Instance.new("Folder")
folder.Name = "EfectosDragon"
folder.Parent = Workspace

-- Cuántas partículas de verdad: la cuenta pedida por el ajuste, con tope.
function DragonKit.amount(count: number): number
	return math.min(MAX_BURST, math.round(count * ClientSettings.fxScale()))
end

function DragonKit.burst(particles: ParticleEmitter, count: number)
	local n = DragonKit.amount(count)
	if n > 0 then
		particles:Emit(n)
	end
end

function DragonKit.anchor(position: Vector3, lifetime: number): Attachment
	local attachment = Instance.new("Attachment")
	attachment.WorldPosition = position
	attachment.Parent = Workspace.Terrain
	Debris:AddItem(attachment, lifetime)
	return attachment
end

-- Emisor sin ritmo (solo ráfagas). light: true brilla (fuego), false se ilumina como el mundo.
function DragonKit.emitter(
	parent: Instance,
	texture: string,
	color: ColorSequence,
	light: boolean
): ParticleEmitter
	local particles = Instance.new("ParticleEmitter")
	particles.Texture = texture
	particles.Color = color
	particles.Enabled = false
	particles.Rate = 0
	particles.EmissionDirection = Enum.NormalId.Top
	particles.Rotation = NumberRange.new(0, 360)
	particles.RotSpeed = NumberRange.new(-40, 40)
	particles.LightEmission = if light then 1 else 0
	particles.LightInfluence = if light then 0 else 0.8
	particles.Parent = parent
	return particles
end

-- Anillo plano en el suelo: de 0.3 a 2 veces el radio en seconds, y se desvanece.
function DragonKit.ring(position: Vector3, radius: number, seconds: number, color: Color3)
	local part = Instance.new("Part")
	part.Name = "AnilloDragon"
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(0.2, radius * 0.6, radius * 0.6)
	part.CFrame = CFrame.new(position + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90))
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Transparency = 0.45
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Parent = folder
	local info = TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService
		:Create(part, info, { Size = Vector3.new(0.2, radius * 2, radius * 2), Transparency = 1 })
		:Play()
	Debris:AddItem(part, seconds + 0.1)
end

-- Tamaño de los efectos para un dragón de length studs (1 = una persona).
function DragonKit.scale(length: number): number
	return math.max(1, length / 12)
end

return table.freeze(DragonKit)
