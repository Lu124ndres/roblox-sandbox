--!strict
--[[
	OverheadBadges

	Fila de insignias del cartel sobre la cabeza (Overhead), cada una en su
	pastilla redonda con fondo en degradado, marco y un brillo arriba; el
	ícono sobresale un poco por la izquierda:
		Monstruos  monstruo panzón (Icons "fed") y cuántos llenó, fondo azul noche y marco de oro
		VIP        corona y "VIP" sobre oro (solo si tiene el pase)
		Premium    el ícono de Roblox Premium sobre fondo oscuro (solo si es Premium)
	Las pastillas que no se usan se ocultan y las demás quedan centradas.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Icons = require(script.Parent.Icons)
local Style = require(script.Parent.Style)

export type Badges = {
	setKills: (count: number) -> (),
	setVip: (on: boolean) -> (),
}

local rgb = Color3.fromRGB
local WHITE = Color3.new(1, 1, 1)

local OverheadBadges = {}

local function sequence(colors: { Color3 }): ColorSequence
	return ColorSequence.new(colors[1], colors[2])
end

local function round(parent: GuiObject)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = parent
end

-- Pastilla: fondo con degradado vertical, marco con degradado y brillo arriba.
local function pill(
	parent: Instance,
	name: string,
	width: number,
	order: number,
	fill: { Color3 },
	frame: { Color3 }
): Frame
	local back = Instance.new("Frame")
	back.Name = name
	back.LayoutOrder = order
	back.Size = UDim2.fromScale(width, 0.84)
	back.BackgroundColor3 = WHITE
	back.BorderSizePixel = 0
	round(back)
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = sequence(fill)
	gradient.Parent = back
	local border = Instance.new("UIStroke")
	border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	border.Color = WHITE
	border.Thickness = 4
	border.Parent = back
	local shade = Instance.new("UIGradient")
	shade.Rotation = 90
	shade.Color = sequence(frame)
	shade.Parent = border
	local shine = Instance.new("Frame")
	shine.Name = "Brillo"
	shine.BackgroundColor3 = WHITE
	shine.BackgroundTransparency = 0.8
	shine.BorderSizePixel = 0
	shine.Position = UDim2.fromScale(0.1, 0.08)
	shine.Size = UDim2.fromScale(0.8, 0.3)
	round(shine)
	shine.Parent = back
	back.Parent = parent
	return back
end

-- Ícono cuadrado que sobresale por la izquierda (medido con el alto de la pastilla).
local function icon(parent: Instance, kind: string, size: number): GuiObject
	local image = Icons.view(parent, kind)
	image.SizeConstraint = Enum.SizeConstraint.RelativeYY
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.Position = UDim2.fromScale(0.02, 0.48)
	image.Size = UDim2.fromScale(size, size)
	image.ZIndex = 3
	return image
end

local function label(parent: Instance, text: string, color: Color3, outline: Color3): TextLabel
	local value = Style.text(parent, "Texto", 90, color, 2.5)
	value.Text = text
	value.Position = UDim2.fromScale(0.3, 0.1)
	value.Size = UDim2.fromScale(0.64, 0.8)
	value.ZIndex = 3
	local stroke = value:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = outline
	end
	return value
end

function OverheadBadges.build(row: Frame, player: Player): Badges
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0.07, 0)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = row

	local kills = pill(row, "Monstruos", 0.3, 1, { rgb(52, 70, 140), rgb(18, 22, 54) }, {
		rgb(255, 236, 140),
		rgb(214, 140, 20),
	})
	icon(kills, "fed", 1.5)
	local count = label(kills, "0", rgb(255, 240, 200), rgb(20, 16, 40))

	local vip = pill(row, "VIP", 0.25, 2, { rgb(255, 226, 90), rgb(240, 130, 10) }, {
		rgb(255, 250, 220),
		rgb(130, 60, 0),
	})
	icon(vip, "crown", 1.35)
	label(vip, "VIP", WHITE, rgb(110, 50, 0))

	local premium = pill(row, "Premium", 0.15, 3, { rgb(70, 74, 92), rgb(20, 22, 30) }, {
		rgb(255, 255, 255),
		rgb(150, 156, 175),
	})
	local glyph = Instance.new("TextLabel")
	glyph.Name = "Icono"
	glyph.BackgroundTransparency = 1
	glyph.Position = UDim2.fromScale(0.15, 0.12)
	glyph.Size = UDim2.fromScale(0.7, 0.76)
	glyph.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold)
	glyph.Text = utf8.char(0xE001) -- el ícono de Premium que dibuja Roblox
	glyph.TextScaled = true
	glyph.TextColor3 = WHITE
	glyph.ZIndex = 3
	glyph.Parent = premium
	premium.Visible = player.MembershipType == Enum.MembershipType.Premium

	return {
		setKills = function(value: number)
			count.Text = NumberFormat.short(value)
		end,
		setVip = function(on: boolean)
			vip.Visible = on
		end,
	}
end

return table.freeze(OverheadBadges)
