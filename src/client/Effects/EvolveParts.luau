--!strict
--[[
	EvolveParts

	Piezas sueltas de la evolución (EvolveCharge y EvolveBurst): partes
	ancladas que no chocan ni proyectan sombra, emisores de partículas con
	las texturas propias (Assets.Particles), el aro del suelo (una Decal con
	la textura Anillo sobre una placa invisible: las partículas no pasan de
	unos 100 studs y la onda del gigante final mide cientos) y las capas de
	pantalla (bordes teñidos y destello). Todo vive en la carpeta que pasa
	EvolveFx, que se borra al terminar.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Assets = require(ReplicatedStorage.Shared.Assets)

local EvolveParts = {}

local function bare(part: BasePart, folder: Instance)
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Parent = folder
end

-- Parte invisible que sostiene emisores y luces.
function EvolveParts.anchor(folder: Instance, size: Vector3): Part
	local part = Instance.new("Part")
	part.Name = "Ancla"
	part.Size = size
	part.Transparency = 1
	bare(part, folder)
	return part
end

-- Óvalo de campo de fuerza (el aura). El tamaño va en mesh.Scale.
function EvolveParts.ellipsoid(folder: Instance, color: Color3): (Part, SpecialMesh)
	local part = Instance.new("Part")
	part.Name = "Aura"
	part.Size = Vector3.one
	part.Color = color
	part.Material = Enum.Material.ForceField
	part.Transparency = 1
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = part
	bare(part, folder)
	return part, mesh
end

-- Pieza de neón (destello y columna de luz).
function EvolveParts.neon(folder: Instance, shape: Enum.PartType, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = "Luz"
	part.Shape = shape
	part.Color = color
	part.Material = Enum.Material.Neon
	bare(part, folder)
	return part
end

-- Aro plano en el suelo que se abre de diameterFrom a diameterTo y se desvanece.
function EvolveParts.groundRing(
	folder: Instance,
	position: Vector3,
	color: Color3,
	diameterFrom: number,
	diameterTo: number,
	seconds: number
)
	local plate = EvolveParts.anchor(folder, Vector3.new(diameterFrom, 0.2, diameterFrom))
	plate.Name = "Onda"
	plate.CFrame = CFrame.new(position + Vector3.new(0, 0.4, 0))
	local decal = Instance.new("Decal")
	decal.Texture = Assets.Particles.Anillo
	decal.Color3 = color
	decal.Face = Enum.NormalId.Top
	decal.Parent = plate
	local grow = TweenInfo.new(seconds, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	TweenService:Create(plate, grow, { Size = Vector3.new(diameterTo, 0.2, diameterTo) }):Play()
	local vanish = TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	TweenService:Create(decal, vanish, { Transparency = 1 }):Play()
end

-- Emisor apagado (Rate 0): se usa con Emit o se enciende después.
function EvolveParts.emitter(
	parent: Instance,
	texture: string,
	from: Color3,
	to: Color3
): ParticleEmitter
	local particles = Instance.new("ParticleEmitter")
	particles.Texture = texture
	particles.Color = ColorSequence.new(from, to)
	particles.LightEmission = 1
	particles.LightInfluence = 0
	particles.Rate = 0
	particles.Enabled = false
	particles.Rotation = NumberRange.new(0, 360)
	particles.RotSpeed = NumberRange.new(-120, 120)
	particles.Parent = parent
	return particles
end

-- Tamaño que arranca en `size` y termina en size * endFactor.
function EvolveParts.sizes(size: number, endFactor: number): NumberSequence
	return NumberSequence.new(size, size * endFactor)
end

local function layer(playerGui: Instance, name: string): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 0 -- debajo del HUD
	gui.ScreenInsets = Enum.ScreenInsets.None
	gui.Parent = playerGui
	return gui
end

-- Bordes de la pantalla teñidos (la viñeta del entrenamiento), transparentes al empezar.
function EvolveParts.vignette(playerGui: Instance?, color: Color3): ImageLabel?
	if not playerGui then
		return nil
	end
	local image = Instance.new("ImageLabel")
	image.Name = "Vineta"
	image.BackgroundTransparency = 1
	image.Size = UDim2.fromScale(1, 1)
	image.Image = Assets.UI.Vineta
	image.ImageColor3 = color
	image.ImageTransparency = 1
	image.ScaleType = Enum.ScaleType.Stretch
	image.Interactable = false
	image.Parent = layer(playerGui, "BordeEvolucion")
	return image
end

-- Destello de toda la pantalla que se apaga en `seconds`.
function EvolveParts.screenFlash(
	playerGui: Instance?,
	color: Color3,
	alpha: number,
	seconds: number
)
	if not playerGui or alpha <= 0 then
		return
	end
	local gui = layer(playerGui, "DestelloEvolucion")
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BorderSizePixel = 0
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = 1 - alpha
	frame.Interactable = false
	frame.Parent = gui
	local info = TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(frame, info, { BackgroundTransparency = 1 })
	tween.Completed:Once(function()
		gui:Destroy()
	end)
	tween:Play()
end

return table.freeze(EvolveParts)
