--!strict
--[[
	ShopParts

	Piezas de las tiendas estilo simulador (TIENDA, MEJORAS, premio), de
	piedra tallada (Interface/Kit):
		stone     viste un cuadro de piedra sin perder su borde de resaltar
		sunburst  piedra teñida de su color con rayos claros que giran despacio
		price     placa de piedra con ícono (Robux o moneda) y precio
		gift      botón de piedra rosa cuadrado con el regalo
		section   título de sección dorado con una línea dorada y una gema
		tag       etiqueta de piedra inclinada ("¡Mejor oferta!", "x4")
		scroller  lista con scroll para secciones y tarjetas
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Assets = require(ReplicatedStorage.Shared.Assets)
local TextCase = require(ReplicatedStorage.Shared.TextCase)
local Icons = require(script.Parent.Icons)
local Kit = require(script.Parent.Kit)
local StoneSkin = require(script.Parent.StoneSkin)
local Style = require(script.Parent.Style)

local SPIN = TweenInfo.new(40, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)
local LINE_GOLD = Color3.fromRGB(255, 206, 92)

export type Price = {
	button: TextButton,
	label: TextLabel,
	set: (text: string, enabled: boolean) -> (),
}

local ShopParts = {}

-- Viste de piedra sin perder el borde de resaltar (Interface/StoneSkin).
ShopParts.stone = StoneSkin.dress

-- Pinta `frame` de casilla volcánica con un toque de su color (como las tarjetas de
-- MEJORAS de la referencia: el color fuerte sobre piedra gris desentonaba) y rayos claros
-- desde el centro.
local HINT = 0.5 -- cuánto se aclara el color antes de teñir la piedra oscura
function ShopParts.sunburst(frame: GuiObject, color: Color3, size: number?)
	frame.BackgroundColor3 = color
	ShopParts.stone(frame, "casilla", color:Lerp(Color3.new(1, 1, 1), HINT))
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
	rays.ImageTransparency = 0.72 -- suaves: que se vea la piedra
	rays.ZIndex = 0 -- debajo del ícono y los textos de la tarjeta
	Icons.paint(rays, "sunburst")
	local square = Instance.new("UIAspectRatioConstraint")
	square.DominantAxis = Enum.DominantAxis.Height
	square.Parent = rays
	rays.Parent = frame
	TweenService:Create(rays, SPIN, { Rotation = 360 }):Play()
end

-- Placa de precio: `currency` "robux" o "coins" (las monedas, con el número dorado).
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
		Kit.gold(text)
	end
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Position = UDim2.new(0, 8, 0.5, 0)
	icon.Size = UDim2.fromScale(0.3, 0.72)
	local square = Instance.new("UIAspectRatioConstraint")
	square.Parent = icon
	text.AnchorPoint = Vector2.new(1, 0.5)
	text.Position = UDim2.new(1, -8, 0.5, 0)
	text.Size = UDim2.new(0.72, -12, 0.66, 0)
	local function set(value: string, enabled: boolean)
		text.Text = value
		button.Active = enabled
		-- La piedra se tiñe sola al cambiar BackgroundColor3 (Style.button).
		button.BackgroundColor3 = if enabled then color else Style.PALETTE.Disabled
		icon.Visible = enabled
		text.Size = if enabled then UDim2.new(0.72, -12, 0.66, 0) else UDim2.new(1, -16, 0.66, 0)
	end
	return { button = button, label = text, set = set }
end

function ShopParts.gift(parent: Instance): TextButton
	local button = Style.button(parent, "Regalar", Style.PALETTE.Gift, "")
	local icon = Icons.view(button, if Icons.has("giftPink") then "giftPink" else "gift")
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	icon.Size = UDim2.fromScale(0.78, 0.78)
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
	Kit.gold(label)
	local line = Instance.new("Frame")
	line.Name = "Linea"
	line.AnchorPoint = Vector2.new(1, 0.5)
	line.Position = UDim2.new(1, -14, 0.5, 0)
	line.Size = UDim2.new(0.55, -14, 0, 4)
	line.BackgroundColor3 = LINE_GOLD
	line.BackgroundTransparency = 0.2
	line.BorderSizePixel = 0
	local edge = Instance.new("UIStroke")
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Color = Kit.GOLD_OUTLINE
	edge.Thickness = 1.5
	edge.Parent = line
	line.Parent = holder
	local gem = Instance.new("ImageLabel")
	gem.Name = "Gema"
	gem.BackgroundTransparency = 1
	gem.Image = Assets.UI.PiedraGema
	gem.AnchorPoint = Vector2.new(1, 0.5)
	gem.Position = UDim2.fromScale(1, 0.5)
	gem.Size = UDim2.fromOffset(20, 26)
	gem.Parent = holder
	return holder
end

function ShopParts.tag(parent: Instance, text: string, color: Color3): TextLabel
	local tag = Instance.new("Frame")
	tag.Name = "Etiqueta"
	tag.BackgroundColor3 = color
	tag.Rotation = -8
	tag.ZIndex = 4
	-- Las etiquetas son chicas: el canto de la piedra más fino para que entre.
	Kit.skin(tag, "boton", color).SliceScale = 0.24
	local label = Style.text(tag, "Texto", 22, nil, 2)
	label.Size = UDim2.new(1, -10, 1, -6)
	label.Position = UDim2.fromOffset(5, 3)
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
	list.ScrollBarImageColor3 = LINE_GOLD
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
