--!strict
--[[
	OverheadBadges

	Insignias del cartel sobre la cabeza (Overhead), todas dentro de un solo
	marco: una placa redonda azul noche con degradado, marco de oro y un brillo
	arriba. Adentro, separados por líneas finas:
		Monstruos  monstruo panzón (Icons "fed") y cuántos llenó
		VIP        corona y "VIP" en oro (solo si tiene el pase)
		Premium    el ícono de Roblox Premium (solo si es Premium)
	La placa se ajusta al ancho de lo que se muestra y queda centrada; los
	íconos sobresalen un poco del marco.
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
local GOLD = rgb(255, 214, 80)
-- Ancho de cada parte (fracción del ancho del cartel) y el margen de la placa.
local WIDTH = { kills = 0.27, vip = 0.21, premium = 0.11, line = 0.012 }
local SIDES = 0.05

local OverheadBadges = {}

local function round(parent: GuiObject)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = parent
end

local function gradient(parent: Instance, top: Color3, bottom: Color3)
	local fill = Instance.new("UIGradient")
	fill.Rotation = 90
	fill.Color = ColorSequence.new(top, bottom)
	fill.Parent = parent
end

local function plate(row: Frame): (Frame, Frame)
	local back = Instance.new("Frame")
	back.Name = "Placa"
	back.AnchorPoint = Vector2.new(0.5, 0.5)
	back.Position = UDim2.fromScale(0.5, 0.52)
	back.BackgroundColor3 = WHITE
	back.BorderSizePixel = 0
	round(back)
	gradient(back, rgb(54, 72, 150), rgb(16, 20, 50))
	local border = Instance.new("UIStroke")
	border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	border.Color = WHITE
	border.Thickness = 4
	border.Parent = back
	gradient(border, rgb(255, 240, 150), rgb(200, 120, 10))
	local shine = Instance.new("Frame")
	shine.Name = "Brillo"
	shine.BackgroundColor3 = WHITE
	shine.BackgroundTransparency = 0.82
	shine.BorderSizePixel = 0
	shine.Position = UDim2.fromScale(0.06, 0.07)
	shine.Size = UDim2.fromScale(0.88, 0.3)
	round(shine)
	shine.Parent = back
	back.Parent = row
	-- Las partes van en su propio cuadro (el brillo no entra en la fila).
	local inside = Instance.new("Frame")
	inside.Name = "Contenido"
	inside.BackgroundTransparency = 1
	inside.Size = UDim2.fromScale(1, 1)
	inside.Parent = back
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = inside
	return back, inside
end

local function part(parent: Instance, name: string, order: number): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.LayoutOrder = order
	frame.BackgroundTransparency = 1
	frame.Parent = parent
	return frame
end

local function divider(parent: Instance, order: number): Frame
	local holder = part(parent, "Linea", order)
	local line = Instance.new("Frame")
	line.AnchorPoint = Vector2.new(0.5, 0.5)
	line.Position = UDim2.fromScale(0.5, 0.5)
	line.Size = UDim2.new(0, 2, 0.6, 0)
	line.BackgroundColor3 = GOLD
	line.BackgroundTransparency = 0.25
	line.BorderSizePixel = 0
	line.Parent = holder
	return holder
end

local function icon(parent: Instance, kind: string, size: number, x: number)
	local image = Icons.view(parent, kind)
	image.SizeConstraint = Enum.SizeConstraint.RelativeYY
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.Position = UDim2.fromScale(x, 0.46)
	image.Size = UDim2.fromScale(size, size)
	image.ZIndex = 3
end

local function label(parent: Instance, text: string, color: Color3, x: number): TextLabel
	local value = Style.text(parent, "Texto", 90, color, 2.5)
	value.Text = text
	value.Position = UDim2.fromScale(x, 0.12)
	value.Size = UDim2.fromScale(0.96 - x, 0.76)
	value.ZIndex = 3
	return value
end

function OverheadBadges.build(row: Frame, player: Player): Badges
	local back, inside = plate(row)
	local kills = part(inside, "Monstruos", 1)
	icon(kills, "fed", 1.45, 0.2)
	local count = label(kills, "0", rgb(255, 244, 214), 0.44)
	local lineVip = divider(inside, 2)
	local vip = part(inside, "VIP", 3)
	icon(vip, "crown", 1.25, 0.26)
	label(vip, "VIP", GOLD, 0.5)
	local linePremium = divider(inside, 4)
	local premium = part(inside, "Premium", 5)
	local glyph = Instance.new("TextLabel")
	glyph.Name = "Icono"
	glyph.BackgroundTransparency = 1
	glyph.Position = UDim2.fromScale(0.12, 0.16)
	glyph.Size = UDim2.fromScale(0.76, 0.68)
	glyph.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold)
	glyph.Text = utf8.char(0xE001) -- el ícono de Premium que dibuja Roblox
	glyph.TextScaled = true
	glyph.TextColor3 = WHITE
	glyph.ZIndex = 3
	glyph.Parent = premium

	local hasVip = false
	local isPremium = player.MembershipType == Enum.MembershipType.Premium
	-- Ancho de la placa según lo que se ve; cada parte, en proporción.
	local function layout()
		type Entry = { frame: Frame, width: number, on: boolean }
		local shown: { Entry } = {
			{ frame = kills, width = WIDTH.kills, on = true },
			{ frame = lineVip, width = WIDTH.line, on = hasVip },
			{ frame = vip, width = WIDTH.vip, on = hasVip },
			{ frame = linePremium, width = WIDTH.line, on = isPremium },
			{ frame = premium, width = WIDTH.premium, on = isPremium },
		}
		local total = SIDES
		for _, entry in shown do
			if entry.on then
				total += entry.width
			end
		end
		back.Size = UDim2.fromScale(total, 0.84)
		for _, entry in shown do
			entry.frame.Visible = entry.on
			entry.frame.Size = UDim2.fromScale(entry.width / total, 1)
		end
	end
	layout()

	return {
		setKills = function(value: number)
			count.Text = NumberFormat.short(value)
		end,
		setVip = function(on: boolean)
			if on ~= hasVip then
				hasVip = on
				layout()
			end
		end,
	}
end

return table.freeze(OverheadBadges)
