--!strict
--[[
	GiantPortrait

	Retrato del monstruo actual a la izquierda del panel de hambre: su modelo
	(la etapa 1 de ModelosGigantes, o el marcador de primitivas si aún no
	tiene modelo) visto de frente y un poco de lado, que se mece despacio.
	Cambia solo cuando cambia el monstruo.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local GiantTemplates = require(script.Parent.GiantTemplates)

local SWAY_SPEED, SWAY_ANGLE = 0.9, math.rad(14)

export type Portrait = { set: (giantId: string) -> () }

local GiantPortrait = {}

local function defFor(giantId: string): Config.GiantDef?
	for _, def in Config.Giants.chain do
		if def.id == giantId then
			return def
		end
	end
	return nil
end

local function modelFor(def: Config.GiantDef): Model
	local folder = ReplicatedStorage:FindFirstChild(Protocol.GiantModelsFolder)
	local template = folder and GiantTemplates.templateFor(folder, def, 1)
	if template then
		local model = template:Clone()
		for _, item in model:GetDescendants() do
			if item:IsA("BaseScript") or item:IsA("Sound") then
				item:Destroy()
			end
		end
		return model
	end
	return (GiantTemplates.placeholder())
end

-- `view`: el ViewportFrame donde se dibuja (lo arma HungerPanel).
function GiantPortrait.attach(view: ViewportFrame): Portrait
	local camera = Instance.new("Camera")
	camera.FieldOfView = 28
	camera.Parent = view
	view.CurrentCamera = camera
	local shownId: string? = nil
	local model: Model? = nil

	RunService.RenderStepped:Connect(function()
		if model and view.Visible then
			model:PivotTo(CFrame.Angles(0, math.sin(os.clock() * SWAY_SPEED) * SWAY_ANGLE, 0))
		end
	end)

	local function set(giantId: string)
		if giantId == shownId then
			return
		end
		shownId = giantId
		if model then
			model:Destroy()
			model = nil
		end
		local def = defFor(giantId)
		if not def then
			return
		end
		local nextModel = modelFor(def)
		nextModel:PivotTo(CFrame.new())
		nextModel.Parent = view
		model = nextModel
		-- Mira a -Z: la cámara va de lado (se ve su perfil), cerca de la cabeza.
		local box, size = nextModel:GetBoundingBox()
		local extent = size.Magnitude
		local target = box.Position + Vector3.new(0, size.Y * 0.15, 0)
		camera.CFrame =
			CFrame.lookAt(target + Vector3.new(extent * 1.1, extent * 0.15, -extent * 0.5), target)
	end

	return { set = set }
end

return GiantPortrait
