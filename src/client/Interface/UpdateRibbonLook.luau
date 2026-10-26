--!strict
--[[
	UpdateRibbonLook

	Cómo se ve la cinta de la próxima actualización (Interface/UpdateRibbon):
	banda oscura de puntas desvanecidas con borde dorado y el brillo que la
	cruza cada tanto.
]]

local TweenService = game:GetService("TweenService")

local Kit = require(script.Parent.Kit)

local NAME = "CintaActualizacion"
local SHINE_EVERY = 8
local SHINE = TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local BAND = Color3.fromRGB(28, 18, 14)

local UpdateRibbonLook = {}

function UpdateRibbonLook.band(panel: GuiObject, size: Vector2): TextButton
	local ribbon = Instance.new("TextButton")
	ribbon.Name = NAME
	ribbon.Text = ""
	ribbon.AutoButtonColor = false
	ribbon.AnchorPoint = Vector2.new(0.5, 0)
	ribbon.Size = UDim2.fromOffset(size.X, size.Y)
	ribbon.BackgroundColor3 = BAND
	ribbon.BackgroundTransparency = 0.2
	ribbon.ClipsDescendants = true
	ribbon.Visible = false
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = ribbon
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = Kit.GOLD_OUTLINE
	stroke.Thickness = 2
	stroke.Parent = ribbon
	-- Las puntas se desvanecen: parece una cinta y no un botón más.
	local fade = Instance.new("UIGradient")
	fade.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.55),
		NumberSequenceKeypoint.new(0.15, 0),
		NumberSequenceKeypoint.new(0.85, 0),
		NumberSequenceKeypoint.new(1, 0.55),
	})
	fade.Parent = ribbon
	ribbon.Parent = panel
	return ribbon
end

-- Un brillo cruza la cinta cada SHINE_EVERY segundos.
function UpdateRibbonLook.shine(ribbon: GuiObject)
	local light = Instance.new("Frame")
	light.Name = "Brillo"
	light.BackgroundColor3 = Color3.new(1, 1, 1)
	light.BorderSizePixel = 0
	light.Size = UDim2.fromScale(0.25, 1)
	light.Position = UDim2.fromScale(-0.3, 0)
	light.ZIndex = 3
	local gradient = Instance.new("UIGradient")
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	})
	gradient.Rotation = 20
	gradient.Parent = light
	light.Parent = ribbon
	task.spawn(function()
		while ribbon.Parent do
			task.wait(SHINE_EVERY)
			if ribbon.Visible then
				light.Position = UDim2.fromScale(-0.3, 0)
				TweenService:Create(light, SHINE, { Position = UDim2.fromScale(1.05, 0) }):Play()
			end
		end
	end)
end

return UpdateRibbonLook
