--!strict
--[[
	GearPreview

	Miniatura 3D de las canastas y las botas para las filas de MEJORAS (las
	cañas usan RodPreview): la canasta del nivel armada sobre un torso
	invisible (BasketBuilder) o el par de botas (BootBuilder), dentro de un
	ViewportFrame, girada para que se vea su forma.
]]

local BasketBuilder = require(script.Parent.Parent.Effects.BasketBuilder)
local BootBuilder = require(script.Parent.Parent.Effects.BootBuilder)

local GearPreview = {}

local function viewport(parent: GuiObject, size: number): ViewportFrame
	local view = Instance.new("ViewportFrame")
	view.Name = "Vista"
	view.BackgroundTransparency = 1
	view.AnchorPoint = Vector2.new(0.5, 0.5)
	view.Position = UDim2.fromScale(0.5, 0.5)
	view.Size = UDim2.fromOffset(size, size)
	view.Ambient = Color3.fromRGB(200, 200, 210)
	view.LightColor = Color3.fromRGB(255, 250, 240)
	view.Parent = parent
	return view
end

local function frame(view: ViewportFrame, model: Model, from: Vector3)
	local box, extents = model:GetBoundingBox()
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	camera.CFrame = CFrame.lookAt(box.Position + from.Unit * extents.Magnitude * 1.9, box.Position)
	camera.Parent = view
	view.CurrentCamera = camera
end

function GearPreview.basket(parent: GuiObject, level: number, size: number): ViewportFrame
	local view = viewport(parent, size)
	local holder = Instance.new("Model") -- un "personaje" con solo el torso
	holder.Name = "Muestra"
	local torso = Instance.new("Part")
	torso.Name = "UpperTorso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.Transparency = 1
	torso.Anchored = true
	torso.CFrame = CFrame.new() * CFrame.Angles(0, math.rad(180), 0) -- la canasta queda de frente
	torso.Parent = holder
	holder.Parent = view
	local basket = BasketBuilder.build(holder, level)
	if basket then
		for _, tail in basket.tails do
			tail.Transparency = 0 -- con peces asomando se ve llena
		end
		frame(view, holder, Vector3.new(0.6, 0.45, -1)) -- el torso invisible es más chico que la canasta
	end
	return view
end

function GearPreview.boots(parent: GuiObject, level: number, size: number): ViewportFrame
	local view = viewport(parent, size)
	local model = BootBuilder.build(level)
	model.Parent = view
	frame(view, model, Vector3.new(1, 0.7, -0.8))
	return view
end

return GearPreview
