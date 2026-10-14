--!strict
--[[
	OutfitParts

	Las piezas de cada traje (ver Outfits). Todo se mide con la cabeza y el
	torso del personaje (R15 o R6) y se suelda con WeldConstraint.
]]

type Look = {
	crown: Color3,
	crownMaterial: Enum.Material,
	spikes: number,
	spikeLength: number,
	gem: Color3?,
	cape: Color3,
	trim: Color3,
	trimMaterial: Enum.Material,
	fire: boolean,
}

local LOOKS: { [string]: Look } = {
	ReyDelMar = {
		crown = Color3.fromRGB(255, 200, 60),
		crownMaterial = Enum.Material.Metal,
		spikes = 5,
		spikeLength = 0.35,
		gem = Color3.fromRGB(60, 170, 255),
		cape = Color3.fromRGB(30, 70, 170),
		trim = Color3.fromRGB(255, 200, 60),
		trimMaterial = Enum.Material.Metal,
		fire = false,
	},
	DiosDelVolcan = {
		crown = Color3.fromRGB(255, 140, 30),
		crownMaterial = Enum.Material.Neon,
		spikes = 8,
		spikeLength = 0.6,
		gem = nil,
		cape = Color3.fromRGB(25, 20, 22),
		trim = Color3.fromRGB(255, 90, 20),
		trimMaterial = Enum.Material.Neon,
		fire = true,
	},
}

local OutfitParts = {}

local function piece(
	model: Model,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	anchor: BasePart
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.CastShadow = false
	part.Parent = model
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = anchor
	weld.Part1 = part
	weld.Parent = part
	return part
end

local function crown(look: Look, model: Model, head: BasePart)
	local width = head.Size.X * 0.9
	local height = 0.28 * head.Size.Y
	local top = head.CFrame * CFrame.new(0, head.Size.Y / 2 + height / 2 - 0.05, 0)
	-- El cilindro va acostado en X: se gira para que quede como un aro.
	piece(
		model,
		"Corona",
		Vector3.new(height, width, width),
		top * CFrame.Angles(0, 0, math.rad(90)),
		look.crown,
		look.crownMaterial,
		head
	)
	local radius = width / 2 - 0.08
	for index = 1, look.spikes do
		local angle = (index - 1) / look.spikes * math.pi * 2
		local at = top
			* CFrame.Angles(0, angle, 0)
			* CFrame.new(0, height / 2 + look.spikeLength / 2, -radius)
		piece(
			model,
			"Punta",
			Vector3.new(0.16, look.spikeLength, 0.16),
			at,
			look.crown,
			look.crownMaterial,
			head
		)
	end
	if look.gem then
		local gem = piece(
			model,
			"Gema",
			Vector3.one * 0.3,
			top * CFrame.new(0, 0, -width / 2),
			look.gem,
			Enum.Material.Neon,
			head
		)
		gem.Shape = Enum.PartType.Ball
	end
	if look.fire then
		local fire = Instance.new("Fire")
		fire.Size = 3
		fire.Heat = 6
		fire.Color = Color3.fromRGB(255, 140, 30)
		fire.SecondaryColor = Color3.fromRGB(255, 60, 10)
		fire.Parent = model:FindFirstChild("Corona")
	end
end

local function cape(look: Look, model: Model, torso: BasePart)
	local width = torso.Size.X * 0.95
	local length = torso.Size.Y * 1.9
	local back = torso.CFrame
		* CFrame.new(0, torso.Size.Y / 2 - length / 2 + 0.1, torso.Size.Z / 2 + 0.1)
		* CFrame.Angles(math.rad(-8), 0, 0)
	piece(
		model,
		"Capa",
		Vector3.new(width, length, 0.08),
		back,
		look.cape,
		Enum.Material.Fabric,
		torso
	)
	piece(
		model,
		"Borde",
		Vector3.new(width + 0.04, 0.14, 0.1),
		back * CFrame.new(0, -length / 2, 0),
		look.trim,
		look.trimMaterial,
		torso
	)
	piece(
		model,
		"Cuello",
		Vector3.new(width + 0.1, 0.18, 0.12),
		back * CFrame.new(0, length / 2, 0),
		look.trim,
		look.trimMaterial,
		torso
	)
	if look.fire then
		local sparks = Instance.new("ParticleEmitter")
		sparks.Color = ColorSequence.new(Color3.fromRGB(255, 170, 40), Color3.fromRGB(255, 50, 10))
		sparks.LightEmission = 1
		sparks.Rate = 6
		sparks.Lifetime = NumberRange.new(0.8, 1.4)
		sparks.Speed = NumberRange.new(1, 2.5)
		sparks.SpreadAngle = Vector2.new(60, 60)
		sparks.Size = NumberSequence.new(0.18, 0)
		sparks.Acceleration = Vector3.new(0, 3, 0)
		sparks.Parent = model:FindFirstChild("Capa")
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 120, 40)
		light.Brightness = 1.2
		light.Range = 8
		light.Parent = model:FindFirstChild("Capa")
	end
end

function OutfitParts.build(outfit: string, model: Model, head: BasePart, torso: BasePart)
	local look = LOOKS[outfit]
	if not look then
		return
	end
	crown(look, model, head)
	cape(look, model, torso)
end

return OutfitParts
