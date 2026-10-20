--!strict
--[[
	LightAura

	Aura de luz a los pies de alguien (reemplaza al cilindro de neón, pedido
	del usuario: «es solo un tubo de color»). Todo con partículas propias
	(Assets.Particles), nada sólido:
		- un brillo suave en el suelo (Halo) que respira;
		- anillos planos que nacen en el suelo y suben despacio abriéndose (Anillo);
		- chispas y brasas que flotan hacia arriba alrededor del cuerpo
		  (Chispa, Brasa), más cuanto mayor es `level`;
		- una luz del mismo color.
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

-- Base del aura: un disco invisible en el suelo (las chispas salen de toda su
-- superficie; un Attachment solo emite desde un punto) y su centro.
local function base(name: string): (Part, Attachment)
	local disc = Instance.new("Part")
	disc.Name = name
	disc.Transparency = 1
	disc.Anchored = true
	disc.CanCollide, disc.CanQuery, disc.CanTouch = false, false, false
	disc.CastShadow = false
	disc.Size = Vector3.new(4, 0.1, 4)
	local center = Instance.new("Attachment")
	center.Parent = disc
	return disc, center
end

-- Arma el aura sobre `disc` (en el suelo). level 1..6: más alta y más llena.
local function build(
	disc: Part,
	center: Attachment,
	color: Color3,
	level: number
): { ParticleEmitter }
	local reach = 1 + level * 0.18 -- radio y alto crecen con la rareza
	disc.Size = Vector3.new(3.2 * reach, 0.1, 3.2 * reach)

	local glow = emitter(center, Assets.Particles.Halo, color)
	glow.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
	glow.EmissionDirection = Enum.NormalId.Top
	glow.Speed = NumberRange.new(0.01)
	glow.Lifetime = NumberRange.new(1.2)
	glow.Rate = 2.5
	glow.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2.6 * reach),
		NumberSequenceKeypoint.new(0.5, 3.4 * reach),
		NumberSequenceKeypoint.new(1, 2.6 * reach),
	})
	glow.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.4, 0.72),
		NumberSequenceKeypoint.new(1, 1),
	})

	local rings = emitter(center, Assets.Particles.Anillo, color)
	rings.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
	rings.EmissionDirection = Enum.NormalId.Top
	rings.SpreadAngle = Vector2.zero
	rings.Speed = NumberRange.new(2.2 * reach)
	rings.Lifetime = NumberRange.new(1.4)
	rings.Rate = 1.6
	rings.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2.5 * reach),
		NumberSequenceKeypoint.new(1, 5.5 * reach),
	})
	rings.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.15, 0.05),
		NumberSequenceKeypoint.new(1, 1),
	})

	-- Chispas y brasas: salen del disco alrededor de los pies y suben flotando.
	local motes = {}
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
		table.insert(motes, particles)
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

	local all = { glow, rings, motes[1], motes[2] }
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

-- Aura de `seconds` a los pies (`feet` = centro del personaje: baja hasta el suelo).
function LightAura.burst(feet: Vector3, color: Color3, seconds: number, level: number)
	local disc, center = base("AuraCaptura")
	local list = build(disc, center, color, level)
	disc.CFrame = CFrame.new(feet - Vector3.new(0, 2.8, 0))
	disc.Parent = Workspace
	setEnabled(list, true)
	list[2]:Emit(1) -- el primer anillo sale ya, con el pez en alto
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
	local disc, center = base("AuraGuia")
	local list = build(disc, center, color, 3)
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
