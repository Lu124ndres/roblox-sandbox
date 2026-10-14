--!strict
--[[
	RodParts

	Piezas básicas para armar cañas (RodBuilder y RodOrnaments). La caña se
	arma con el mango en el origen y la punta hacia -Z; luego Rod la mueve.
]]

local RodParts = {}

function RodParts.piece(
	model: Model,
	name: string,
	size: Vector3,
	frame: CFrame,
	color: Color3,
	material: Enum.Material?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = frame
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Parent = model
	return part
end

-- Cilindro a lo largo de -Z (Roblox los crea a lo largo de X), desde fromZ.
function RodParts.shaft(
	model: Model,
	name: string,
	length: number,
	diameter: number,
	fromZ: number,
	color: Color3,
	material: Enum.Material?
): Part
	local frame = CFrame.new(0, 0, fromZ - length / 2) * CFrame.Angles(0, math.rad(90), 0)
	local part =
		RodParts.piece(model, name, Vector3.new(length, diameter, diameter), frame, color, material)
	part.Shape = Enum.PartType.Cylinder
	return part
end

-- Anillo fino alrededor de la vara en z (amarres, nudos, virolas).
function RodParts.ring(
	model: Model,
	name: string,
	z: number,
	diameter: number,
	color: Color3,
	material: Enum.Material?
): Part
	return RodParts.shaft(model, name, 0.12, diameter, z + 0.06, color, material)
end

function RodParts.ball(
	model: Model,
	name: string,
	position: Vector3,
	size: number,
	color: Color3,
	material: Enum.Material?
): Part
	local part =
		RodParts.piece(model, name, Vector3.one * size, CFrame.new(position), color, material)
	part.Shape = Enum.PartType.Ball
	return part
end

function RodParts.light(parent: BasePart, color: Color3, range: number)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = 1.6
	light.Parent = parent
end

-- Partículas pegadas a una pieza (destellos, chispas, humo, burbujas).
function RodParts.particles(
	parent: BasePart,
	texture: string,
	color: Color3,
	rate: number,
	speed: number,
	size: number
)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = texture
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 0.8
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.3, size),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Lifetime = NumberRange.new(0.5, 1)
	emitter.Speed = NumberRange.new(speed * 0.5, speed)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rate = rate
	emitter.Parent = parent
end

return RodParts
