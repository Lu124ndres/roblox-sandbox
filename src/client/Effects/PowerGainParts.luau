--!strict
--[[
	PowerGainParts

	Las piezas de interfaz de PowerGainFx: la viñeta azul de los bordes de la
	pantalla y el cristalito de energía (un rombo claro con halo).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage.Shared.Assets)

local BLUE = Color3.fromRGB(90, 175, 255)
local LIGHT = Color3.fromRGB(215, 240, 255)

local PowerGainParts = {}

-- Brillo azul en los bordes de la pantalla: una viñeta (Assets.UI.Vineta) en su propia
-- ScreenGui que ignora la barra de Roblox, así cubre toda la pantalla de forma pareja
-- (antes eran 4 franjas que dejaban un hueco arriba y se pisaban en las esquinas).
function PowerGainParts.vignette(playerGui: Instance): ImageLabel
	local layer = Instance.new("ScreenGui")
	layer.Name = "BrilloEntrenar"
	layer.IgnoreGuiInset = true
	layer.ResetOnSpawn = false
	layer.DisplayOrder = 0 -- debajo del HUD
	layer.ScreenInsets = Enum.ScreenInsets.None
	local image = Instance.new("ImageLabel")
	image.Name = "Vineta"
	image.BackgroundTransparency = 1
	image.Size = UDim2.fromScale(1, 1)
	image.Image = Assets.UI.Vineta
	image.ImageColor3 = BLUE
	image.ImageTransparency = 1
	image.ScaleType = Enum.ScaleType.Stretch
	image.Active = false
	image.Interactable = false
	image.Parent = layer
	layer.Parent = playerGui
	return image
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
