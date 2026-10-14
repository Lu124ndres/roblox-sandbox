--!strict
--[[
	VolcanoLook

	Apariencia del Dios del Volcán (pase DiosDelVolcan), además de la corona
	de fuego y la capa de OutfitParts: piel de basalto con grietas de lava
	que brillan, ojos de fuego, hombreras de obsidiana con picos de magma,
	núcleo de lava en el pecho, botas negras y pies en llamas.
]]

local GearParts = require(script.Parent.GearParts)
local OutfitKit = require(script.Parent.OutfitKit)

local rgb, M = OutfitKit.rgb, OutfitKit.M
local piece, ball = OutfitKit.piece, OutfitKit.ball

local LAVA = rgb(255, 110, 20)
local OBSIDIAN = rgb(28, 22, 26)

local VolcanoLook = {}

local function crack(
	model: Model,
	anchor: BasePart,
	x: number,
	y: number,
	z: number,
	length: number,
	angle: number
)
	piece(
		model,
		"Grieta",
		anchor,
		Vector3.new(0.07, length, 0.04),
		CFrame.new(x, y, z) * CFrame.Angles(0, 0, math.rad(angle)),
		LAVA,
		M.Neon
	)
end

function VolcanoLook.build(model: Model, rig: OutfitKit.Rig)
	local s = rig.torso.Size
	local front = -s.Z / 2 - 0.02
	crack(model, rig.torso, -s.X * 0.25, s.Y * 0.15, front, s.Y * 0.45, 20)
	crack(model, rig.torso, -s.X * 0.15, -s.Y * 0.2, front, s.Y * 0.35, -25)
	crack(model, rig.torso, s.X * 0.28, s.Y * 0.05, front, s.Y * 0.55, -15)
	crack(model, rig.torso, s.X * 0.15, -s.Y * 0.3, front, s.Y * 0.3, 30)
	local core = ball(
		model,
		"Nucleo",
		rig.torso,
		Vector3.one * 0.42,
		CFrame.new(0, s.Y * 0.12, front - 0.06),
		LAVA,
		M.Neon
	)
	local glow = Instance.new("PointLight")
	glow.Color, glow.Brightness, glow.Range = LAVA, 1.6, 10
	glow.Parent = core
	for index, arm in rig.upperArms do
		local side = OutfitKit.side(index)
		crack(model, arm, side * arm.Size.X * 0.51, 0, 0, arm.Size.Y * 0.7, 12)
		local pad = CFrame.new(side * 0.08, arm.Size.Y / 2 + 0.06, 0)
		piece(
			model,
			"Hombrera",
			arm,
			Vector3.new(arm.Size.X * 1.5, 0.34, arm.Size.Z * 1.45),
			pad,
			OBSIDIAN,
			M.Basalt
		)
		for spike = -1, 1 do
			piece(
				model,
				"Pico",
				arm,
				Vector3.new(0.14, 0.5, 0.14),
				pad
					* CFrame.new(side * 0.22, 0.3, spike * 0.28)
					* CFrame.Angles(0, 0, math.rad(-side * 25)),
				LAVA,
				M.Neon
			)
		end
	end
	for index, leg in rig.upperLegs do
		crack(
			model,
			leg,
			0,
			0,
			-leg.Size.Z / 2 - 0.02,
			leg.Size.Y * 0.6,
			OutfitKit.side(index) * 15
		)
	end
	-- Máscara de basalto sobre la cara (también tapa las caras que vienen en la
	-- malla de la cabeza) y ojos de fuego.
	local h = rig.head.Size
	piece(
		model,
		"Mascara",
		rig.head,
		Vector3.new(h.X * 0.92, h.Y * 0.82, 0.04),
		CFrame.new(0, -h.Y * 0.02, -h.Z / 2 - 0.01),
		rgb(58, 48, 48),
		M.Basalt
	)
	crack(model, rig.head, -h.X * 0.25, -h.Y * 0.22, -h.Z / 2 - 0.035, h.Y * 0.3, 25)
	for _, x in { -1, 1 } do
		piece(
			model,
			"Ojo",
			rig.head,
			Vector3.new(0.22, 0.12, 0.05),
			CFrame.new(x * h.X * 0.18, h.Y * 0.08, -h.Z / 2 - 0.04),
			rgb(255, 210, 60),
			M.Neon
		)
	end
	GearParts.belt(model, rig, OBSIDIAN)
	GearParts.shoes(model, rig, OBSIDIAN, true)
	for _, shoe in model:GetChildren() do -- pies en llamas
		if string.sub(shoe.Name, 1, 6) == "Zapato" then
			local fire = Instance.new("Fire")
			fire.Size, fire.Heat = 2, 3
			fire.Color, fire.SecondaryColor = rgb(255, 150, 30), rgb(255, 60, 10)
			fire.Parent = shoe
		end
	end
end

return VolcanoLook
