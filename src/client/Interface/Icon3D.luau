--!strict
--[[
	Icon3D

	Íconos 3D de la interfaz: un ViewportFrame con un modelo hecho de piezas
	(IconModels, o un pez de la colección) que se mueve solo. Tipos:
		coin, crystal, skull, basket, gift, gear, chest, "fish:<idPez>"
	Movimiento: las monedas se mecen, el engrane gira de lado, el resto da
	vueltas despacio y flota. Un solo RenderStepped mueve todos.
]]

local RunService = game:GetService("RunService")

local FishModel = require(script.Parent.Parent.Effects.FishModel)
local IconModels = require(script.Parent.IconModels)

type Entry = { model: Model, kind: string, offset: number, view: ViewportFrame }

local Icon3D = {}

local entries: { Entry } = {}
local running = false

local function motion(entry: Entry, t: number): CFrame
	local time = t + entry.offset
	if entry.kind == "coin" then
		return CFrame.Angles(0, math.sin(time * 1.6) * 0.55, 0)
	elseif entry.kind == "gear" then
		return CFrame.Angles(0, 0, time * 0.8)
	elseif string.sub(entry.kind, 1, 5) == "fish:" then
		return CFrame.new(0, math.sin(time * 2) * 0.12, 0)
			* CFrame.Angles(
				0,
				math.rad(90) + math.sin(time * 1.3) * 0.45,
				math.sin(time * 4) * 0.08
			)
	end
	return CFrame.new(0, math.sin(time * 2) * 0.12, 0) * CFrame.Angles(0, time * 0.9, 0)
end

local function start()
	if running then
		return
	end
	running = true
	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		for index = #entries, 1, -1 do
			local entry = entries[index]
			if not entry.view.Parent then
				table.remove(entries, index)
			elseif entry.view.Visible then
				entry.model:PivotTo(motion(entry, t))
			end
		end
	end)
end

local function build(kind: string): Model
	local fishId = string.match(kind, "^fish:(.+)$")
	if fishId then
		return FishModel.build(fishId, 1)
	end
	local model = Instance.new("Model")
	model.Name = kind
	local builder = (IconModels :: any)[kind]
	if type(builder) == "function" then
		builder(model)
	end
	-- Pivote en el origen sin girar: el movimiento no debe cambiar hacia dónde mira.
	model.WorldPivot = CFrame.new()
	return model
end

function Icon3D.view(parent: Instance, kind: string): ViewportFrame
	local view = Instance.new("ViewportFrame")
	view.Name = `Icono_{kind}`
	view.BackgroundTransparency = 1
	view.Ambient = Color3.fromRGB(175, 175, 185)
	view.LightColor = Color3.new(1, 1, 1)
	view.LightDirection = Vector3.new(-0.6, -1, -0.8)
	local model = build(kind)
	model.Parent = view
	local extent = model:GetExtentsSize().Magnitude
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	camera.CFrame = CFrame.lookAt(Vector3.new(0, extent * 0.15, extent * 1.75), Vector3.zero)
	camera.Parent = view
	view.CurrentCamera = camera
	view.Parent = parent
	table.insert(entries, { model = model, kind = kind, offset = #entries * 0.7, view = view })
	start()
	return view
end

return Icon3D
