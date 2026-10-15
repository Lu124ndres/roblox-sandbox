--!strict
--[[
	PowerGainParts

	Las piezas de interfaz de PowerGainFx: el marco azul degradado de cada
	borde de la pantalla y el cristalito de energía (un rombo claro con halo).
]]

local BLUE = Color3.fromRGB(90, 175, 255)
local LIGHT = Color3.fromRGB(215, 240, 255)

local PowerGainParts = {}

function PowerGainParts.edge(
	parent: Instance,
	size: UDim2,
	position: UDim2,
	rotation: number
): Frame
	local frame = Instance.new("Frame")
	frame.Name = "Borde"
	frame.BorderSizePixel = 0
	frame.BackgroundColor3 = BLUE
	frame.BackgroundTransparency = 1
	frame.Size = size
	frame.Position = position
	frame.ZIndex = 0
	frame.Active = false
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = rotation
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.4, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	})
	gradient.Parent = frame
	frame.Parent = parent
	return frame
end

function PowerGainParts.orb(parent: Instance): (Frame, UIScale)
	local frame = Instance.new("Frame")
	frame.Name = "Energia"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Size = UDim2.fromOffset(46, 46)
	frame.BackgroundColor3 = BLUE
	frame.BackgroundTransparency = 0.72
	frame.ZIndex = 30
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(1, 0)
	round.Parent = frame
	local gem = Instance.new("Frame")
	gem.Name = "Cristal"
	gem.AnchorPoint = Vector2.new(0.5, 0.5)
	gem.Position = UDim2.fromScale(0.5, 0.5)
	gem.Size = UDim2.fromScale(0.5, 0.5)
	gem.Rotation = 45
	gem.BackgroundColor3 = LIGHT
	gem.ZIndex = 31
	local gemCorner = Instance.new("UICorner")
	gemCorner.CornerRadius = UDim.new(0.2, 0)
	gemCorner.Parent = gem
	local shade = Instance.new("UIGradient")
	shade.Color = ColorSequence.new(Color3.new(1, 1, 1), BLUE)
	shade.Rotation = 90
	shade.Parent = gem
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(20, 70, 140)
	stroke.Thickness = 1.5
	stroke.Parent = gem
	gem.Parent = frame
	local scale = Instance.new("UIScale")
	scale.Scale = 0
	scale.Parent = frame
	frame.Parent = parent
	return frame, scale
end

return PowerGainParts
