--!strict
--[[
	RodBuilder

	Arma el modelo de una caña según su aspecto (UIConfig.RodLooks):
	contera, mango con amarres, portacarrete, carrete con platos y manivela,
	tres tramos que se afinan con virolas, anillas que se achican hacia la
	punta y puntera. Después RodOrnaments agrega los adornos de su estilo.
	El mango queda en el origen y la punta hacia -Z.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local RodOrnaments = require(script.Parent.RodOrnaments)
local RodParts = require(script.Parent.RodParts)

local CORK = Color3.fromRGB(198, 160, 112)
local METAL = Color3.fromRGB(196, 202, 210)
local SEGMENTS = { { 2.6, 0.2 }, { 2.4, 0.14 }, { 2.2, 0.09 } } -- largo y grosor de cada tramo

local RodBuilder = {}

export type Built = { model: Model, tip: Attachment, tipPart: Part, trail: Trail }

local function tipTrail(tipPart: Part, z: number, color: Color3): Trail
	local upper, lower = Instance.new("Attachment"), Instance.new("Attachment")
	upper.WorldPosition = Vector3.new(0, 0.35, z)
	lower.WorldPosition = Vector3.new(0, -0.35, z)
	upper.Parent = tipPart
	lower.Parent = tipPart
	local trail = Instance.new("Trail")
	trail.Attachment0 = upper
	trail.Attachment1 = lower
	trail.Lifetime = 0.25
	trail.Color = ColorSequence.new(Color3.new(1, 1, 1), color)
	trail.Transparency = NumberSequence.new(0.25, 1)
	trail.LightEmission = 0.6
	trail.FaceCamera = true
	trail.Enabled = false
	trail.Parent = tipPart
	return trail
end

local function reel(model: Model, look: UIConfig.RodLook)
	local p = RodParts.piece
	local spool = p(
		model,
		"Carrete",
		Vector3.new(0.4, 0.75, 0.75),
		CFrame.new(0, -0.55, -0.9),
		look.accent,
		Enum.Material.Metal
	)
	spool.Shape = Enum.PartType.Cylinder
	for side = -1, 1, 2 do
		local plate = p(
			model,
			`Plato{side}`,
			Vector3.new(0.06, 0.95, 0.95),
			CFrame.new(side * 0.22, -0.55, -0.9),
			METAL,
			Enum.Material.Metal
		)
		plate.Shape = Enum.PartType.Cylinder
	end
	p(
		model,
		"Pata",
		Vector3.new(0.15, 0.4, 0.22),
		CFrame.new(0, -0.22, -0.9),
		METAL,
		Enum.Material.Metal
	)
	p(
		model,
		"Manivela",
		Vector3.new(0.08, 0.08, 0.5),
		CFrame.new(0.3, -0.55, -0.75),
		METAL,
		Enum.Material.Metal
	)
	RodParts.ball(
		model,
		"Perilla",
		Vector3.new(0.3, -0.55, -0.52),
		0.18,
		look.accent,
		Enum.Material.SmoothPlastic
	)
end

function RodBuilder.build(look: UIConfig.RodLook): Built
	local model = Instance.new("Model")
	model.Name = "Cana"

	-- Mango: contera, corcho con amarres y portacarrete.
	RodParts.ball(model, "Contera", Vector3.new(0, 0, 0.85), 0.42, look.accent, Enum.Material.Metal)
	local grip = RodParts.shaft(model, "Mango", 1.5, 0.4, 0.75, CORK, Enum.Material.Fabric)
	RodParts.ring(model, "AmarreMango1", 0.45, 0.44, look.accent)
	RodParts.ring(model, "AmarreMango2", -0.45, 0.44, look.accent)
	RodParts.shaft(model, "Portacarrete", 0.5, 0.34, -0.65, METAL, Enum.Material.Metal)
	reel(model, look)

	-- Tramos que se afinan, con virolas en cada unión y anillas abajo.
	local z = -0.9
	local last: Part = grip
	for index, segment in SEGMENTS do
		local length, diameter = segment[1], segment[2]
		last = RodParts.shaft(model, `Tramo{index}`, length, diameter, z, look.blank, look.material)
		if look.material == Enum.Material.Glass then
			last.Transparency = 0.35
		end
		RodParts.ring(
			model,
			`Virola{index}`,
			z - 0.05,
			diameter + 0.07,
			look.accent,
			Enum.Material.Metal
		)
		local guide = 0.34 - index * 0.06
		RodParts.ring(model, `AmarreAnilla{index}`, z - length + 0.45, diameter + 0.05, look.accent)
		local ring = RodParts.piece(
			model,
			`Anilla{index}`,
			Vector3.new(0.05, guide, guide),
			CFrame.new(0, -diameter / 2 - guide / 2, z - length + 0.35)
				* CFrame.Angles(0, math.rad(90), 0),
			METAL,
			Enum.Material.Metal
		)
		ring.Shape = Enum.PartType.Cylinder
		z -= length
	end
	local point = RodParts.ball(
		model,
		"Punta",
		Vector3.new(0, 0, z),
		0.14,
		look.accent,
		if look.glow then Enum.Material.Neon else Enum.Material.Metal
	)
	if look.glow then
		RodParts.light(point, look.accent, 8)
	end

	local tip = Instance.new("Attachment")
	tip.Name = "PuntaSedal"
	tip.WorldPosition = Vector3.new(0, 0, z)
	tip.Parent = last
	local trail = tipTrail(last, z, look.accent)

	RodOrnaments.add(model, look, z, point)
	model.WorldPivot = CFrame.new() -- el pivote es el origen: el centro del mango
	return { model = model, tip = tip, tipPart = point, trail = trail }
end

return RodBuilder
