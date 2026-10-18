--!strict
--[[
	Style

	Estilo "simulador" de la interfaz: números grandes con contorno negro
	grueso, botones de piedra tallada teñidos de su color (Interface/Kit: el
	gris lleva el texto dorado) y la insignia verde de precio en Robux. Todo
	con fuentes y colores de UIConfig.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage.Shared.Assets)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Kit = require(script.Parent.Kit)

local COLORS = UIConfig.Colors
local OUTLINE = Color3.fromRGB(20, 20, 24)

local Style = {}

Style.OUTLINE = OUTLINE

local rgb = Color3.fromRGB
-- Colores de las tiendas (como los simuladores): botones y tarjetas.
Style.PALETTE = {
	Panel = rgb(40, 44, 60), -- fondo de las ventanas
	Wood = rgb(160, 102, 58), -- filas de MEJORAS
	WoodPanel = rgb(92, 58, 34),
	Close = rgb(236, 56, 56),
	Buy = rgb(70, 206, 70), -- botón de precio en Robux
	Coins = rgb(255, 196, 40), -- botón de precio en monedas
	RobuxAlt = rgb(160, 84, 240), -- Robux en MEJORAS (morado)
	Gift = rgb(255, 84, 176),
	Timer = rgb(255, 110, 200),
	Disabled = rgb(110, 116, 130),
	Cards = {
		Green = rgb(72, 196, 72),
		Orange = rgb(255, 146, 40),
		Blue = rgb(56, 140, 255),
		Purple = rgb(158, 92, 240),
		Red = rgb(236, 72, 72),
		Cyan = rgb(36, 196, 220),
		Yellow = rgb(255, 196, 36),
		Pink = rgb(255, 92, 176),
		Brown = rgb(176, 108, 60),
	},
}

-- Texto blanco (o del color dado) con contorno negro grueso, que escala.
function Style.text(
	parent: Instance,
	name: string,
	maxSize: number,
	color: Color3?,
	thickness: number?
): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.FontFace = UIConfig.Fonts.Title
	label.TextColor3 = color or COLORS.Text
	label.TextScaled = true
	label.TextStrokeTransparency = 1
	local stroke = Instance.new("UIStroke")
	stroke.Color = OUTLINE
	stroke.Thickness = thickness or 2.5
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = label
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = maxSize
	limit.Parent = label
	label.Parent = parent
	return label
end

-- Borde negro grueso alrededor de un cuadro o botón (no en los de piedra: la piedra trae su borde).
function Style.border(frame: GuiObject, thickness: number?)
	if frame:FindFirstChild("Piedra") then
		return
	end
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = OUTLINE
	stroke.Thickness = thickness or 3
	stroke.Parent = frame
end

-- Degradado vertical: arriba el color claro, abajo uno más oscuro.
function Style.gradient(frame: GuiObject, color: Color3)
	local h, s, v = color:ToHSV()
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new(
		Color3.fromHSV(h, math.max(0, s - 0.15), math.min(1, v + 0.15)),
		Color3.fromHSV(h, math.min(1, s + 0.1), v * 0.72)
	)
	gradient.Parent = frame
end

-- Botón de piedra tallada teñido de `color`, con texto con contorno (dorado si el color es
-- gris: el botón de piedra de MEJORAS). Si después le cambian BackgroundColor3, la piedra
-- se tiñe del color nuevo (así siguen andando los que lo apagan o lo pintan).
function Style.button(parent: Instance, name: string, color: Color3, text: string): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.Text = ""
	button.AutoButtonColor = false
	button.BackgroundColor3 = color
	local skin = Kit.skin(button, "boton", color)
	Kit.press(button, skin)
	local label = Style.text(button, "Texto", 30, nil, 2)
	label.Size = UDim2.new(1, -14, 1, -12)
	label.Position = UDim2.fromOffset(7, 5)
	label.Text = text
	local _, saturation = color:ToHSV()
	if saturation < 0.18 then
		Kit.gold(label)
	end
	button:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
		Kit.tint(skin, button.BackgroundColor3)
	end)
	button.BackgroundTransparency = 1
	button.Parent = parent
	return button
end

-- Botón con marco de lava (lo más importante: TIENDA, comprar con Robux). Texto dorado.
function Style.lavaButton(parent: Instance, name: string, text: string): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.Text = ""
	button.AutoButtonColor = false
	local skin = Kit.skin(button, "lava")
	Kit.press(button, skin)
	local label = Style.text(button, "Texto", 30, nil, 2)
	label.Size = UDim2.new(1, -18, 1, -16)
	label.Position = UDim2.fromOffset(9, 7)
	label.Text = text
	Kit.gold(label)
	button.Parent = parent
	return button
end

-- Insignia verde con el ícono de Robux y el precio (arriba a la derecha de un botón).
function Style.robuxBadge(parent: Instance, price: number?): TextLabel
	local badge = Instance.new("Frame")
	badge.Name = "Precio"
	badge.AnchorPoint = Vector2.new(1, 0.5)
	badge.Position = UDim2.new(1, 4, 0, 0)
	badge.Size = UDim2.fromOffset(62, 24)
	badge.BackgroundColor3 = COLORS.Robux
	badge.ZIndex = 5
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = badge
	Style.border(badge, 2)
	local icon = Instance.new("ImageLabel")
	icon.BackgroundTransparency = 1
	icon.Image = Assets.UI.RobuxIcon
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Position = UDim2.new(0, 3, 0.5, 0)
	icon.Size = UDim2.new(0, 20, 1, -2)
	icon.ScaleType = Enum.ScaleType.Fit
	icon.ZIndex = 6
	icon.Parent = badge
	local label = Style.text(badge, "Robux", 20, nil, 1.5)
	label.Position = UDim2.fromOffset(22, 1)
	label.Size = UDim2.new(1, -26, 1, -2)
	label.ZIndex = 6
	label.Text = if price then tostring(price) else "..."
	badge.Parent = parent
	return label
end

return Style
