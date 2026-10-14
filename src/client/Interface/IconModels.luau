--!strict
--[[
	IconModels

	Modelos 3D chicos hechos con piezas para los íconos de la interfaz
	(Icon3D los muestra en un ViewportFrame). Cada uno mira hacia +Z, que es
	desde donde los ve la cámara, y mide unos 3 studs.
]]

local IconModels = {}

local GOLD = Color3.fromRGB(255, 204, 48)
local GOLD_DARK = Color3.fromRGB(222, 150, 20)

local function part(
	model: Model,
	size: Vector3,
	color: Color3,
	cframe: CFrame,
	shape: Enum.PartType?,
	material: Enum.Material?
): Part
	local piece = Instance.new("Part")
	piece.Anchored = true
	piece.CanCollide = false
	piece.Size = size
	piece.Color = color
	piece.CFrame = cframe
	piece.Shape = shape or Enum.PartType.Block
	piece.Material = material or Enum.Material.SmoothPlastic
	piece.TopSurface = Enum.SurfaceType.Smooth
	piece.BottomSurface = Enum.SurfaceType.Smooth
	piece.Parent = model
	return piece
end

local FACE = CFrame.Angles(0, math.rad(90), 0) -- eje de los cilindros hacia la cámara (+Z)

function IconModels.coin(model: Model)
	local coin = part(model, Vector3.new(0.55, 3, 3), GOLD, FACE, Enum.PartType.Cylinder)
	coin.Reflectance = 0.15
	part(model, Vector3.new(0.6, 2.2, 2.2), GOLD_DARK, FACE, Enum.PartType.Cylinder)
	part(
		model,
		Vector3.new(0.9, 0.9, 0.3),
		Color3.fromRGB(255, 236, 140),
		CFrame.new(0, 0, 0.25) * CFrame.Angles(0, 0, math.rad(45))
	)
end

function IconModels.crystal(model: Model)
	-- Gema en rombo (un cubo girado 45°) con brillo de vidrio y dos gemas chicas.
	local diamond = CFrame.Angles(0, 0, math.rad(45))
	part(
		model,
		Vector3.new(1.8, 1.8, 0.9),
		Color3.fromRGB(70, 160, 255),
		diamond,
		nil,
		Enum.Material.Neon
	)
	local shell = part(
		model,
		Vector3.new(2.15, 2.15, 1.1),
		Color3.fromRGB(200, 235, 255),
		diamond,
		nil,
		Enum.Material.Glass
	)
	shell.Transparency = 0.5
	part(
		model,
		Vector3.new(0.5, 0.5, 1.15),
		Color3.fromRGB(235, 250, 255),
		CFrame.new(-0.35, 0.45, 0) * diamond,
		nil,
		Enum.Material.Neon
	)
	for side = -1, 1, 2 do
		part(
			model,
			Vector3.new(0.7, 0.7, 0.5),
			Color3.fromRGB(130, 200, 255),
			CFrame.new(side * 1.45, -0.9, 0.2) * diamond,
			nil,
			Enum.Material.Neon
		)
	end
end

function IconModels.skull(model: Model)
	local bone = Color3.fromRGB(245, 240, 225)
	local black = Color3.fromRGB(25, 20, 25)
	part(model, Vector3.one * 2.4, bone, CFrame.new(0, 0.3, 0), Enum.PartType.Ball)
	part(model, Vector3.new(1.4, 0.8, 1.3), bone, CFrame.new(0, -0.85, 0.35))
	for side = -1, 1, 2 do
		part(model, Vector3.one * 0.7, black, CFrame.new(side * 0.5, 0.3, 0.95), Enum.PartType.Ball)
		part(model, Vector3.new(0.12, 0.5, 0.2), black, CFrame.new(side * 0.25, -0.9, 1.02))
	end
	part(model, Vector3.new(0.25, 0.3, 0.2), black, CFrame.new(0, -0.25, 1.15))
end

function IconModels.basket(model: Model)
	local red = Color3.fromRGB(235, 64, 92)
	local dark = Color3.fromRGB(170, 30, 60)
	part(model, Vector3.new(2.8, 1.8, 2), red, CFrame.new(0, -0.4, 0))
	part(model, Vector3.new(3.05, 0.35, 2.2), Color3.fromRGB(255, 120, 140), CFrame.new(0, 0.55, 0))
	for x = -0.9, 0.9, 0.6 do
		part(model, Vector3.new(0.22, 1.5, 0.1), dark, CFrame.new(x, -0.45, 1.02))
	end
	for side = -1, 1, 2 do
		part(
			model,
			Vector3.new(0.25, 1.4, 0.25),
			Color3.fromRGB(120, 140, 160),
			CFrame.new(side * 1.15, 1.3, 0)
		)
	end
	part(model, Vector3.new(2.55, 0.25, 0.25), Color3.fromRGB(120, 140, 160), CFrame.new(0, 2, 0))
end

function IconModels.gift(model: Model)
	local box = Color3.fromRGB(170, 90, 255)
	local ribbon = Color3.fromRGB(255, 214, 60)
	part(model, Vector3.new(2.2, 1.7, 2.2), box, CFrame.new(0, -0.45, 0))
	part(model, Vector3.new(2.45, 0.55, 2.45), Color3.fromRGB(200, 130, 255), CFrame.new(0, 0.6, 0))
	part(model, Vector3.new(0.45, 2.3, 2.5), ribbon, CFrame.new(0, -0.15, 0))
	part(model, Vector3.new(2.5, 2.3, 0.45), ribbon, CFrame.new(0, -0.15, 0))
	for side = -1, 1, 2 do
		part(model, Vector3.one * 0.8, ribbon, CFrame.new(side * 0.42, 1.2, 0), Enum.PartType.Ball)
	end
end

function IconModels.gear(model: Model)
	local steel = Color3.fromRGB(190, 198, 210)
	part(
		model,
		Vector3.new(0.6, 2.3, 2.3),
		steel,
		FACE,
		Enum.PartType.Cylinder,
		Enum.Material.Metal
	)
	for index = 0, 7 do
		local angle = index * math.pi / 4
		part(
			model,
			Vector3.new(0.65, 0.6, 0.6),
			steel,
			CFrame.Angles(0, 0, angle) * CFrame.new(0, 1.25, 0),
			nil,
			Enum.Material.Metal
		)
	end
	part(
		model,
		Vector3.new(0.65, 0.85, 0.85),
		Color3.fromRGB(60, 66, 80),
		FACE,
		Enum.PartType.Cylinder
	)
end

function IconModels.chest(model: Model)
	local wood = Color3.fromRGB(150, 92, 50)
	part(model, Vector3.new(2.6, 1.4, 1.7), wood, CFrame.new(0, -0.5, 0), nil, Enum.Material.Wood)
	part(
		model,
		Vector3.new(2.6, 0.6, 1.7),
		Color3.fromRGB(176, 110, 62),
		CFrame.new(0, 0.85, -0.25) * CFrame.Angles(math.rad(-20), 0, 0),
		nil,
		Enum.Material.Wood
	)
	for side = -1, 1, 2 do
		part(model, Vector3.new(0.25, 1.45, 1.75), GOLD, CFrame.new(side * 1.05, -0.5, 0))
	end
	part(model, Vector3.new(0.45, 0.5, 0.2), GOLD, CFrame.new(0, -0.15, 0.88))
	for index, x in { -0.6, 0.05, 0.65 } do
		part(
			model,
			Vector3.one * (0.55 + index * 0.05),
			Color3.fromRGB(40, 230, 120),
			CFrame.new(x, 0.35, 0.2),
			Enum.PartType.Ball,
			Enum.Material.Neon
		)
	end
end

return IconModels
