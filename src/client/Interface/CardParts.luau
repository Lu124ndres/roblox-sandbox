--!strict
--[[
	CardParts

	Piezas comunes de las ventanas con el estilo de la TIENDA y el premio
	diario (misiones, renacer, pack de inicio, regalos por jugar):
		card     cuadro redondo con borde negro, color, degradado y rayos
		paint    vuelve a pintar una tarjeta (quita los rayos y el degradado viejos)
		bar      barra de avance con borde, relleno con degradado y texto encima
		iconText ícono + texto en una fila (premios: moneda y cantidad)
]]

local ShopParts = require(script.Parent.ShopParts)
local Icons = require(script.Parent.Icons)
local Style = require(script.Parent.Style)

export type Bar = {
	track: Frame,
	fill: Frame,
	label: TextLabel,
	set: (fraction: number, text: string, color: Color3?) -> (),
}

local TRACK_COLOR = Color3.fromRGB(28, 30, 40)

local CardParts = {}

function CardParts.paint(frame: GuiObject, color: Color3)
	for _, child in frame:GetChildren() do
		if child:IsA("UIGradient") or child.Name == "Rayos" then
			child:Destroy()
		end
	end
	ShopParts.sunburst(frame, color)
end

function CardParts.card(parent: Instance, name: string, color: Color3, radius: number?): Frame
	local card = Instance.new("Frame")
	card.Name = name
	card.ClipsDescendants = false
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 14)
	corner.Parent = card
	Style.border(card, 3)
	ShopParts.sunburst(card, color)
	card.Parent = parent
	return card
end

local function repaintFill(fill: Frame, color: Color3)
	fill.BackgroundColor3 = color
	local old = fill:FindFirstChildOfClass("UIGradient")
	if old then
		old:Destroy()
	end
	Style.gradient(fill, color)
end

function CardParts.bar(parent: Instance, color: Color3, textSize: number?): Bar
	local track = Instance.new("Frame")
	track.Name = "Barra"
	track.BackgroundColor3 = TRACK_COLOR
	track.ClipsDescendants = true
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = track
	Style.border(track, 2.5)
	track.Parent = parent
	local fill = Instance.new("Frame")
	fill.Name = "Relleno"
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(0, 1)
	local fillCorner = corner:Clone()
	fillCorner.Parent = fill
	repaintFill(fill, color)
	fill.Parent = track
	local shine = Instance.new("Frame") -- brillo arriba, como la barra de hambre
	shine.Name = "Brillo"
	shine.BorderSizePixel = 0
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BackgroundTransparency = 0.75
	shine.Position = UDim2.fromScale(0, 0.1)
	shine.Size = UDim2.fromScale(1, 0.28)
	fillCorner:Clone().Parent = shine
	shine.Parent = fill
	local label = Style.text(track, "Cuenta", textSize or 20, nil, 2)
	label.Size = UDim2.new(1, -8, 1, -4)
	label.Position = UDim2.fromOffset(4, 2)
	label.ZIndex = 3
	local current = color
	local function set(fraction: number, text: string, tint: Color3?)
		fill.Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1)
		fill.Visible = fraction > 0
		label.Text = text
		if tint and tint ~= current then
			current = tint
			repaintFill(fill, tint)
		end
	end
	return { track = track, fill = fill, label = label, set = set }
end

-- Fila con ícono a la izquierda y texto (p. ej. moneda + "1.5K").
function CardParts.iconText(
	parent: Instance,
	icon: string,
	textSize: number,
	color: Color3?
): (Frame, TextLabel)
	local holder = Instance.new("Frame")
	holder.Name = "Premio"
	holder.BackgroundTransparency = 1
	holder.Parent = parent
	local view = Icons.view(holder, icon)
	view.Size = UDim2.fromScale(1, 1)
	local square = Instance.new("UIAspectRatioConstraint")
	square.Parent = view
	local label = Style.text(holder, "Texto", textSize, color, 2.5)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.AnchorPoint = Vector2.new(1, 0)
	label.Position = UDim2.fromScale(1, 0)
	label.Size = UDim2.new(1, -4, 1, 0)
	-- El texto empieza después del ícono (cuadrado del alto de la fila).
	local pad = Instance.new("UIPadding")
	pad.Parent = label
	holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		pad.PaddingLeft = UDim.new(0, holder.AbsoluteSize.Y + 2)
	end)
	return holder, label
end

return CardParts
