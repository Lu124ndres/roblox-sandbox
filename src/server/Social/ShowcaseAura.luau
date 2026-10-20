--!strict
--[[
	ShowcaseAura

	El aura del traje en su vitrina (Social/Showcase), en su color: rayos y un
	brillo redondo detrás (un BillboardGui que los clientes corren hacia atrás
	desde la cámara y giran, así siempre quedan detrás del traje), una nube
	de luz y partículas que suben por todo el cuerpo. (Una luz pegada al cuerpo
	lo lavaba: la luz sale del botón del pedestal, en ShowcaseStage.)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage.Shared.Assets)
local ShowcaseStage = require(script.Parent.ShowcaseStage)

type Look = ShowcaseStage.Look

local CELL = 256 -- hoja de íconos 2: rayos (celda 12) y brillo redondo (celda 13)

local ShowcaseAura = {}

-- Rayos y brillo detrás del traje, un aura de partículas y una luz alrededor del cuerpo.
function ShowcaseAura.build(model: Model, top: Vector3, height: number, look: Look)
	local body = ShowcaseStage.part(
		model,
		"Aura",
		Vector3.new(height * 0.4, height * 0.8, height * 0.4),
		CFrame.new(top + Vector3.new(0, height * 0.5, 0)),
		look.main,
		Enum.Material.SmoothPlastic
	)
	body.Transparency, body.CanCollide = 1, false
	local rays = Instance.new("BillboardGui")
	rays.Name = "Rayos"
	rays.Size = UDim2.fromScale(height * 1.9, height * 1.9)
	-- Detrás del traje mirado desde la cámara: cada cliente lo corre por la línea
	-- cámara -> traje (Trajes/Vitrinas); StudsOffset se corre según hacia dónde
	-- mira la cámara y, con el pedestal a un lado de la pantalla, se salía de él.
	rays:SetAttribute("Fondo", height * 0.45)
	rays.LightInfluence = 0
	rays.MaxDistance = 140
	for i, cell in { 13, 12 } do -- brillo redondo y rayos encima
		local image = Instance.new("ImageLabel")
		image.Name = if cell == 12 then "Rayos" else "Brillo"
		image.BackgroundTransparency = 1
		image.Size = UDim2.fromScale(1, 1)
		image.Image = Assets.UI.IconSheet2
		image.ImageRectOffset = Vector2.new((cell % 4) * CELL, math.floor(cell / 4) * CELL)
		image.ImageRectSize = Vector2.new(CELL, CELL)
		image.ImageColor3 = if i == 1 then look.main else look.light
		image.ImageTransparency = if i == 1 then 0.25 else 0.45
		image.Parent = rays
	end
	rays.Parent = body
	for i, texture in look.particles do
		local e = Instance.new("ParticleEmitter")
		e.Texture = texture
		e.Color = ColorSequence.new(look.light, look.main)
		e.LightEmission, e.LightInfluence = 1, 0
		e.Size = NumberSequence.new(if i == 1 then height * 0.03 else height * 0.05, 0)
		e.Transparency = NumberSequence.new(0.1, 1)
		e.Lifetime = NumberRange.new(1.2, 2.2)
		e.Speed = NumberRange.new(height * 0.05, height * 0.12)
		e.SpreadAngle = Vector2.new(25, 25)
		e.Rate = if i == 1 then 18 else 8
		e.Shape, e.ShapeStyle =
			Enum.ParticleEmitterShape.Cylinder, Enum.ParticleEmitterShapeStyle.Surface
		e.Parent = body
	end
	local puff = Instance.new("ParticleEmitter") -- nube de brillo alrededor (como humo de luz)
	puff.Texture = Assets.Particles.Halo
	puff.Color = ColorSequence.new(look.main)
	puff.LightEmission, puff.LightInfluence = 1, 0
	puff.Size = NumberSequence.new(height * 0.3, height * 0.5)
	puff.Transparency = NumberSequence.new(0.6, 1)
	puff.Lifetime = NumberRange.new(1.5, 2.5)
	puff.Speed = NumberRange.new(height * 0.02)
	puff.Rate = 9
	puff.Parent = body
	-- Lenguas de fuego o de agua (hoja animada 4x4) que suben por toda la silueta.
	local tongues = Instance.new("ParticleEmitter")
	tongues.Texture = look.tongues
	tongues.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
	tongues.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
	tongues.Color = ColorSequence.new(look.light, look.main)
	tongues.LightEmission, tongues.LightInfluence = 0.7, 0
	tongues.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, height * 0.1),
		NumberSequenceKeypoint.new(0.5, height * 0.16),
		NumberSequenceKeypoint.new(1, height * 0.08),
	})
	tongues.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(0.3, 0.25),
		NumberSequenceKeypoint.new(1, 1),
	})
	tongues.Lifetime = NumberRange.new(0.7, 1.1)
	tongues.Speed = NumberRange.new(height * 0.04, height * 0.08)
	tongues.Acceleration = Vector3.new(0, height * 0.12, 0)
	tongues.Rotation = NumberRange.new(-10, 10)
	tongues.Rate = 22
	tongues.Shape, tongues.ShapeStyle =
		Enum.ParticleEmitterShape.Cylinder, Enum.ParticleEmitterShapeStyle.Surface
	tongues.Parent = body
end
return table.freeze(ShowcaseAura)
