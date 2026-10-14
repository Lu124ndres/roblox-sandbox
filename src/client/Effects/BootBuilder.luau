--!strict
--[[
	BootBuilder

	Arma un par de botas de piezas (BootLooks) para la vista 3D de la
	tienda: suela, pie redondeado, puntera, caña con su borde, cordones y el
	adorno de cada nivel (alas, rayos, llamas, cristales, estrellas, aletas).
	El modelo queda con el pivote en el origen, entre las dos botas.
]]

local BootLooks = require(script.Parent.BootLooks)

local M = Enum.Material
local Ball, Cylinder = Enum.PartType.Ball, Enum.PartType.Cylinder

local BootBuilder = {}

local function piece(
	model: Model,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material,
	shape: Enum.PartType?
): Part
	local part = Instance.new("Part")
	part.Size = size
	part.CFrame = cf
	part.Color = color
	part.Material = material
	part.Shape = shape or Enum.PartType.Block
	part.Anchored = true
	part.CanCollide = false
	part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	part.Parent = model
	return part
end

local function extras(model: Model, look: BootLooks.BootLook, at: CFrame, side: number)
	local glow = if look.glow then M.Neon else look.material
	local top = 0.5 + look.shaft
	if look.extra == "wings" then
		for k = 0, 2 do
			piece(
				model,
				Vector3.new(0.06, 0.22, 0.7 - k * 0.15),
				at
					* CFrame.new(side * 0.42, top - 0.1 + k * 0.18, 0.15)
					* CFrame.Angles(math.rad(-25 - k * 10), 0, 0),
				look.accent,
				M.SmoothPlastic
			)
		end
	elseif look.extra == "bolts" then
		for k = 0, 1 do
			piece(
				model,
				Vector3.new(0.05, 0.4, 0.12),
				at
					* CFrame.new(side * 0.41, 0.6 + k * 0.32, (k - 0.5) * 0.12)
					* CFrame.Angles(0, 0, math.rad(25 - k * 50)),
				look.accent,
				glow
			)
		end
	elseif look.extra == "flames" then
		for k = 0, 3 do
			piece(
				model,
				Vector3.new(0.12, 0.35 + k % 2 * 0.15, 0.12),
				at
					* CFrame.new((k - 1.5) * 0.18, top + 0.15, 0.1)
					* CFrame.Angles(0, 0, math.rad((k - 1.5) * 12)),
				look.accent,
				M.Neon
			)
		end
	elseif look.extra == "crystals" then
		for k = 0, 2 do
			piece(
				model,
				Vector3.new(0.14, 0.4, 0.14),
				at
					* CFrame.new(side * 0.4, 0.5 + k * 0.3, -0.1 + k * 0.1)
					* CFrame.Angles(math.rad(45), 0, math.rad(35)),
				look.accent,
				M.Neon
			)
		end
	elseif look.extra == "stars" then
		for k = 0, 3 do
			piece(
				model,
				Vector3.one * 0.14,
				at
					* CFrame.new(side * 0.4, 0.45 + k * 0.25, (k % 2 - 0.5) * 0.3)
					* CFrame.Angles(0, 0, math.rad(45)),
				look.accent,
				M.Neon
			)
		end
	elseif look.extra == "fins" then
		piece(
			model,
			Vector3.new(0.06, 0.5, 0.45),
			at * CFrame.new(0, top + 0.1, 0.25) * CFrame.Angles(math.rad(-30), 0, 0),
			look.accent,
			glow
		)
	end
end

local function boot(model: Model, look: BootLooks.BootLook, at: CFrame, side: number)
	piece(
		model,
		Vector3.new(0.84, 0.18, 1.5),
		at * CFrame.new(0, 0.09, -0.2),
		look.sole,
		M.SmoothPlastic
	)
	piece(
		model,
		Vector3.new(0.8, 0.45, 1.1),
		at * CFrame.new(0, 0.38, -0.05),
		look.color,
		look.material
	)
	piece(
		model,
		Vector3.new(0.8, 0.5, 0.8),
		at * CFrame.new(0, 0.33, -0.62),
		look.color,
		look.material,
		Ball
	)
	piece(
		model,
		Vector3.new(0.82, 0.12, 0.3),
		at * CFrame.new(0, 0.2, -0.85),
		look.accent,
		M.SmoothPlastic
	)
	if look.shaft > 0 then
		piece(
			model,
			Vector3.new(look.shaft, 0.76, 0.76),
			at * CFrame.new(0, 0.5 + look.shaft / 2, 0.15) * CFrame.Angles(0, 0, math.rad(90)),
			look.color,
			look.material,
			Cylinder
		)
		piece(
			model,
			Vector3.new(0.14, 0.86, 0.86),
			at * CFrame.new(0, 0.5 + look.shaft, 0.15) * CFrame.Angles(0, 0, math.rad(90)),
			look.accent,
			if look.glow then M.Neon else M.SmoothPlastic,
			Cylinder
		)
	end
	for k = 0, 2 do -- cordones o tiras
		piece(
			model,
			Vector3.new(0.5, 0.06, 0.08),
			at * CFrame.new(0, 0.62, -0.45 + k * 0.2),
			look.accent,
			M.Fabric
		)
	end
	extras(model, look, at, side)
end

function BootBuilder.build(level: number): Model
	local look = BootLooks[math.clamp(level, 1, #BootLooks)]
	local model = Instance.new("Model")
	model.Name = "Botas"
	for _, side in { -1, 1 } do
		boot(
			model,
			look,
			CFrame.new(side * 0.55, 0, 0) * CFrame.Angles(0, math.rad(side * -8), 0),
			side
		)
	end
	model.WorldPivot = CFrame.new()
	return model
end

return BootBuilder
