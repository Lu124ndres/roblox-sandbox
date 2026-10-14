--!strict
--[[
	RodPreview

	Miniatura 3D de una caña para las filas de la tienda: la caña de ese
	nivel (RodBuilder) acostada en diagonal dentro de un ViewportFrame.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local RodBuilder = require(script.Parent.Parent.Fishing.RodBuilder)

local RodPreview = {}

function RodPreview.attach(parent: GuiObject, tier: number, size: number): ViewportFrame
	local view = Instance.new("ViewportFrame")
	view.Name = "Vista"
	view.BackgroundTransparency = 1
	view.AnchorPoint = Vector2.new(0.5, 0.5)
	view.Position = UDim2.fromScale(0.5, 0.5)
	view.Size = UDim2.fromOffset(size, size)
	view.Ambient = Color3.fromRGB(200, 200, 210)
	view.LightColor = Color3.fromRGB(255, 250, 240)
	view.Parent = parent
	local looks = UIConfig.RodLooks
	local built = RodBuilder.build(looks[math.clamp(tier, 1, #looks)])
	-- La caña se arma hacia -Z: se apunta en diagonal (punta arriba a la derecha).
	built.model:PivotTo(CFrame.lookAt(Vector3.zero, Vector3.new(1, 1, -0.15)))
	built.model.Parent = view
	-- Encuadre: la cámara mira al centro de la caña desde su costado.
	local center, extents = built.model:GetBoundingBox()
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	camera.CFrame = CFrame.lookAt(
		center.Position + Vector3.new(0, 0, extents.Magnitude * 1.25),
		center.Position
	)
	camera.Parent = view
	view.CurrentCamera = camera
	return view
end

return RodPreview
