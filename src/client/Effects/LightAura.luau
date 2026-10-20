--!strict
--[[
	LightAura

	Aura de luz alrededor de alguien (reemplaza al cilindro de neón, pedido
	del usuario: «es solo un tubo de color»). Todo con partículas propias
	(Assets.Particles), nada sólido y sin círculos en el suelo (tampoco
	gustaron: «eso no es un aura, solo un círculo»):
		- lenguas de energía del color de la rareza que suben pegadas al
		  cuerpo (FuegoFlip teñido), solo en burst: hay alguien dentro;
		- chispas y brasas que flotan hacia arriba alrededor del cuerpo
		  (Chispa, Brasa), más cuanto mayor es `level`;
		- una luz del mismo color a la altura del pecho.
	burst la enciende `seconds` y la apaga sola (peces raros o mejores);
	marker la deja puesta y la mueve (destino del tutorial). Con efectos
	reducidos salen menos partículas (FxQuality). Solo en este cliente.
]]

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Assets = require(ReplicatedStorage.Shared.Assets)
local FxQuality = require(script.Parent.Parent.Settings.FxQuality)

local WHITE = Color3.new(1, 1, 1)
local FADE_SECONDS = 1.2 -- lo que tardan en irse las últimas partículas al apagarla

export type Marker = {
	place: (position: Vector3) -> (),
	show: (visible: boolean) -> (),
}

local LightAura = {}

-- Emisor apagado con lo común; quien lo usa pone forma, tamaño y ritmo.
local function emitter(parent: Instance, texture: string, color: Color3): ParticleEmitter
	local particles = Instance.new("ParticleEmitter")
	particles.Texture = texture
	particles.Color = ColorSequence.new(WHITE:Lerp(color, 0.6), color)
	particles.LightEmission = 1
	particles.LightInfluence = 0
	particles.Enabled = false
	particles.Parent = parent
	return particles
end

-- Pieza invisible de la que salen partículas (un Attachment solo emite desde un punto).
local function invisible(name: string, size: Vector3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide, part.CanQuery, part.CanTouch = false, false, false
	part.CastShadow = false
	part.Size = size
	return part
end

-- Lenguas de energía por la superficie de `body` (un cilindro del tamaño del cuerpo).
local function tongues(body: Part, color: Color3, level: number): ParticleEmitter
	local particles = emitter(body, Assets.Particles.FuegoFlip, color)
	particles.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
	particles.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
	particles.Shape = Enum.ParticleEmitterShape.Cylinder
	particles.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	particles.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
	particles.EmissionDirection = Enum.NormalId.Top
	particles.Speed = NumberRange.new(0.5, 1.5)
	particles.Acceleration = Vector3.new(0, 7, 0)
	particles.Lifetime = NumberRange.new(0.7, 1)
	particles.Rotation = NumberRange.new(-12, 12)
	particles.LightEmission = 0.45 -- con 1 se pierden de día (ver las chispas)
	particles.Brightness = 2
	particles.Rate = 14 + level * 4
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(0.35, 1.7),
		NumberSequenceKeypoint.new(1, 0.7),
	})
	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.25),
		NumberSequenceKeypoint.new(0.7, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	return particles
end

-- Chispas y brasas que salen de `disc` (en el suelo) y suben flotando, y la luz.
-- level 1..6: más altas y más llenas.
local function build(disc: Part, color: Color3, level: number): { ParticleEmitter }
	local reach = 1 + level * 0.18 -- radio y alto crecen con la rareza
	disc.Size = Vector3.new(3.2 * reach, 0.1, 3.2 * reach)

	local all = {}
	for index, texture in { Assets.Particles.Chispa, Assets.Particles.Brasa } do
		local particles = emitter(disc, texture, color)
		particles.Shape = Enum.ParticleEmitterShape.Disc
		particles.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
		particles.EmissionDirection = Enum.NormalId.Top
		particles.SpreadAngle = Vector2.new(8, 8)
		particles.Speed = NumberRange.new(2.5 * reach, 5 * reach)
		particles.Lifetime = NumberRange.new(1.1, 1.8)
		particles.Drag = 0.6
		-- Con LightEmission 1 se suman a la luz y de día, sobre arena clara, no se ven.
		particles.LightEmission = 0.35
		particles.Brightness = 2
		particles.RotSpeed = NumberRange.new(-120, 120)
		particles.Rotation = NumberRange.new(0, 360)
		particles.Rate = (if index == 1 then 10 else 14) + level * 4
		local size = if index == 1 then 1.3 else 0.7
		particles.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.2, size * reach),
			NumberSequenceKeypoint.new(1, 0),
		})
		table.insert(all, particles)
	end
	-- A la altura del pecho y corta: tiñe al jugador sin lavar el suelo.
	local chest = Instance.new("Attachment")
	chest.Name = "Luz"
	chest.Position = Vector3.new(0, 3, 0)
	chest.Parent = disc
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 6 + level
	light.Brightness = 0.9
	light.Shadows = false
	light.Parent = chest

	for _, particles in all do
		FxQuality.scaleEmitter(particles)
	end
	return all
end

local function setEnabled(list: { ParticleEmitter }, on: boolean)
	for _, particles in list do
		particles.Enabled = on
	end
end

-- Aura de `seconds` alrededor de quien está en `feet` (centro del personaje).
function LightAura.burst(feet: Vector3, color: Color3, seconds: number, level: number)
	local disc = invisible("AuraCaptura", Vector3.one)
	local list = build(disc, color, level)
	disc.CFrame = CFrame.new(feet - Vector3.new(0, 2.8, 0))
	local body = invisible("Cuerpo", Vector3.new(2.6, 5, 2.6))
	body.CFrame = disc.CFrame * CFrame.new(0, 2.6, 0)
	body.Parent = disc
	local flames = tongues(body, color, level)
	FxQuality.scaleEmitter(flames)
	table.insert(list, flames)
	disc.Parent = Workspace
	setEnabled(list, true)
	task.delay(seconds, function()
		if disc.Parent then
			setEnabled(list, false)
			local light = disc:FindFirstChildWhichIsA("PointLight", true)
			if light then
				light.Enabled = false
			end
		end
	end)
	Debris:AddItem(disc, seconds + FADE_SECONDS + 0.6)
end

-- Aura fija que se mueve (destino del tutorial): place la pone en el suelo y show la prende.
function LightAura.marker(color: Color3): Marker
	local disc = invisible("AuraGuia", Vector3.one)
	local list = build(disc, color, 3)
	disc.Parent = Workspace
	local light = disc:FindFirstChildWhichIsA("PointLight", true) :: PointLight
	light.Enabled = false
	local visible = false

	local function show(on: boolean)
		if on ~= visible then
			visible = on
			setEnabled(list, on)
			light.Enabled = on
		end
	end

	local function place(position: Vector3)
		disc.CFrame = CFrame.new(position + Vector3.new(0, 0.2, 0))
	end

	return { place = place, show = show }
end

return LightAura
