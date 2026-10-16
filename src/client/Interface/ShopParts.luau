--!strict
--[[
	ShopParts

	Piezas de las tiendas estilo simulador (TIENDA, MEJORAS, premio):
		sunburst  fondo de color con rayos blancos que giran despacio
		price     botón con ícono (Robux o moneda) y precio
		gift      botón rosa cuadrado con el regalo
		section   título de sección con una línea a la derecha
		tag       etiqueta inclinada ("¡Mejor oferta!", "x4")
		scroller  lista con scroll para secciones y tarjetas
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Assets = require(ReplicatedStorage.Shared.Assets)
local TextCase = require(ReplicatedStorage.Shared.TextCase)
local Icons = require(script.Parent.Icons)
local Style = require(script.Parent.Style)

local SPIN = TweenInfo.new(40, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)

export type Price = {
	button: TextButton,
	label: TextLabel,
	set: (text: string, enabled: boolean) -> (),
}

local ShopParts = {}

-- Pinta `frame` con su color, degradado y rayos claros desde el centro.
function ShopParts.sunburst(frame: GuiObject, color: Color3, size: number?)
	frame.BackgroundColor3 = color
	Style.gradient(frame, color)
	if not Icons.has("sunburst") then
		return
	end
	local rays = Instance.new("ImageLabel")
	rays.Name = "Rayos"
	rays.BackgroundTransparency = 1
	rays.AnchorPoint = Vector2.new(0.5, 0.5)
	rays.Position = UDim2.fromScale(0.5, 0.5)
	-- Cuadrado del alto del cuadro: los rayos se apagan antes del borde (no hace
	-- falta recortar) y pueden girar sin salirse.
	rays.Size = UDim2.fromScale(size or 1, size or 1)
	rays.ImageTransparency = 0.55
	rays.ZIndex = 0 -- debajo del ícono y los textos de la tarjeta
	Icons.paint(rays, "sunburst")
	local square = Instance.new("UIAspectRatioConstraint")
	square.DominantAxis = Enum.DominantAxis.Height
	square.Parent = rays
	rays.Parent = frame
	TweenService:Create(rays, SPIN, { Rotation = 360 }):Play()
end

-- Botón de precio: `currency` "robux" o "coins".
function ShopParts.price(parent: Instance, color: Color3, currency: string): Price
	local button = Style.button(parent, "Precio", color, "")
	local text = button:FindFirstChild("Texto") :: TextLabel
	local icon: GuiObject
	if currency == "robux" then
		local image = Instance.new("ImageLabel")
		image.BackgroundTransparency = 1
		image.Image = Assets.UI.RobuxIcon
		image.ScaleType = Enum.ScaleType.Fit
		image.Parent = button
		icon = image
	else
		icon = Icons.view(button, "coin")
	end
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Position = UDim2.new(0, 6, 0.5, 0)
	icon.Size = UDim2.new(0.3, 0, 0.8, 0)
	local square = Instance.new("UIAspectRatioConstraint")
	square.Parent = icon
	text.AnchorPoint = Vector2.new(1, 0.5)
	text.Position = UDim2.new(1, -6, 0.5, 0)
	text.Size = UDim2.new(0.72, -10, 0.7, 0)
	local function set(value: string, enabled: boolean)
		text.Text = value
		button.Active = enabled
		button.AutoButtonColor = enabled
		local tint = if enabled then color else Style.PALETTE.Disabled
		button.BackgroundColor3 = tint
		local gradient = button:FindFirstChildOfClass("UIGradient")
		if gradient then
			gradient:Destroy()
		end
		Style.gradient(button, tint)
		icon.Visible = enabled
		text.Size = if enabled then UDim2.new(0.72, -10, 0.7, 0) else UDim2.new(1, -12, 0.7, 0)
	end
	return { button = button, label = text, set = set }
end

function ShopParts.gift(parent: Instance): TextButton
	local button = Style.button(parent, "Regalar", Style.PALETTE.Gift, "")
	local icon = Icons.view(button, if Icons.has("giftPink") then "giftPink" else "gift")
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	icon.Size = UDim2.fromScale(0.85, 0.85)
	return button
end

function ShopParts.section(parent: Instance, order: number, text: string): Frame
	local holder = Instance.new("Frame")
	holder.Name = "Seccion"
	holder.LayoutOrder = order
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.new(1, -8, 0, 40)
	holder.Parent = parent
	local label = Style.text(holder, "Titulo", 34, nil, 3)
	label.Text = TextCase.upper(text)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.AutomaticSize = Enum.AutomaticSize.X
	label.TextScaled = false
	label.TextSize = 30
	label.Size = UDim2.fromScale(0, 1)
	local line = Instance.new("Frame")
	line.Name = "Linea"
	line.AnchorPoint = Vector2.new(1, 0.5)
	line.Position = UDim2.fromScale(1, 0.5)
	line.Size = UDim2.new(0.55, 0, 0, 4)
	line.BackgroundColor3 = Color3.new(1, 1, 1)
	line.BackgroundTransparency = 0.6
	line.BorderSizePixel = 0
	line.Parent = holder
	return holder
end

function ShopParts.tag(parent: Instance, text: string, color: Color3): TextLabel
	local tag = Instance.new("Frame")
	tag.Name = "Etiqueta"
	tag.BackgroundColor3 = color
	tag.Rotation = -8
	tag.ZIndex = 4
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = tag
	Style.border(tag, 2.5)
	local label = Style.text(tag, "Texto", 22, nil, 2)
	label.Size = UDim2.new(1, -8, 1, -4)
	label.Position = UDim2.fromOffset(4, 2)
	label.ZIndex = 5
	label.Text = text
	tag.Parent = parent
	return label
end

-- Lista con scroll de las tiendas (secciones y tarjetas una debajo de otra).
function ShopParts.scroller(parent: Instance): ScrollingFrame
	local list = Instance.new("ScrollingFrame")
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Size = UDim2.fromScale(1, 1)
	list.ScrollBarThickness = 8
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.Parent = parent
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.Parent = list
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingLeft = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.Parent = list
	return list
end

return ShopParts
