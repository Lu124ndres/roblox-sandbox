--!strict
--[[
	Ui

	Fábrica mínima de piezas de interfaz con el estilo del juego: paneles
	redondeados con borde, textos con contorno legible sobre la playa y
	escalado automático para pantallas de móvil.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)

local COLORS = UIConfig.Colors
local SPACING = UIConfig.Spacing

local Ui = {}

function Ui.corner(parent: GuiObject, radius: number?)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or SPACING.Corner)
	corner.Parent = parent
end

function Ui.stroke(parent: GuiObject, color: Color3?, thickness: number?, transparency: number?)
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = color or COLORS.PanelStroke
	stroke.Thickness = thickness or SPACING.Stroke
	stroke.Transparency = transparency or 0.6
	stroke.Parent = parent
end

function Ui.panel(name: string, parent: Instance): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundColor3 = COLORS.Panel
	frame.BackgroundTransparency = SPACING.PanelTransparency
	frame.BorderSizePixel = 0
	Ui.corner(frame)
	Ui.stroke(frame)
	frame.Parent = parent
	return frame
end

function Ui.label(name: string, parent: Instance, font: Font, maxTextSize: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.FontFace = font
	label.TextColor3 = COLORS.Text
	label.TextStrokeColor3 = COLORS.TextStroke
	label.TextStrokeTransparency = 0.4
	label.TextScaled = true
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = maxTextSize
	limit.Parent = label
	label.Parent = parent
	return label
end

function Ui.screen(name: string, playerGui: Instance, displayOrder: number): ScreenGui
	local screen = Instance.new("ScreenGui")
	screen.Name = name
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = false
	screen.DisplayOrder = displayOrder
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.Parent = playerGui
	return screen
end

return Ui
