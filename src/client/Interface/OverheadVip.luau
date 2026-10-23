--!strict
--[[
	OverheadVip

	Lo del pase VIP en el cartel sobre la cabeza (pedido del usuario: que se
	note de lejos):
		paint   la placa de insignias (OverheadBadges) pasa de lava a oro
		        (degradado dorado con borde marrón) y un destello blanco la
		        recorre cada pocos segundos
		ribbon  cinta de lava inclinada en la esquina de arriba, con la corona
		        y "VIP" en dorado, que late
		name    el nombre del jugador en oro (Overhead le da el brillo que
		        recorre el texto, como a los títulos altos)
]]

local TweenService = game:GetService("TweenService")

local Icons = require(script.Parent.Icons)
local Kit = require(script.Parent.Kit)
local Style = require(script.Parent.Style)

local rgb = Color3.fromRGB
local WHITE = Color3.new(1, 1, 1)
local EDGE = rgb(90, 45, 10) -- borde marrón de la placa de oro
local CORNER = UDim.new(0.3, 0)
local SHINE = TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 1.8)
local PULSE = TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

local OverheadVip = {}

-- Destello: una franja blanca inclinada que cruza la placa de izquierda a derecha.
local function shine(back: Frame)
	local band = Instance.new("Frame")
	band.Name = "Brillo"
	band.BackgroundColor3 = WHITE
	band.Size = UDim2.fromScale(1, 1)
	band.ZIndex = 2 -- sobre el oro, debajo del contenido (ZIndex 3)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = CORNER
	corner.Parent = band
	local sweep = Instance.new("UIGradient")
	sweep.Rotation = 20
	sweep.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.4, 1),
		NumberSequenceKeypoint.new(0.5, 0.3),
		NumberSequenceKeypoint.new(0.6, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	sweep.Offset = Vector2.new(-1, 0)
	sweep.Parent = band
	band.Parent = back
	TweenService:Create(sweep, SHINE, { Offset = Vector2.new(1, 0) }):Play()
end

-- Placa de lava o de oro. El oro no es la piedra de Kit tintada (es oscura y
-- queda ocre): un degradado dorado con borde marrón y esquinas redondas.
function OverheadVip.paint(back: Frame, vip: boolean, slice: number)
	local old = back:FindFirstChild("Brillo")
	if old then
		old:Destroy()
	end
	if not vip then
		Kit.skin(back, "lava").SliceScale = slice -- también quita el oro (degradado, borde, esquinas)
		return
	end
	local skin = back:FindFirstChild("Piedra")
	if skin then
		skin:Destroy()
	end
	back.BackgroundColor3 = WHITE
	back.BackgroundTransparency = 0
	local fill = Instance.new("UIGradient")
	fill.Rotation = 90
	fill.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, rgb(255, 248, 180)),
		ColorSequenceKeypoint.new(0.5, rgb(255, 208, 60)),
		ColorSequenceKeypoint.new(1, rgb(220, 130, 20)),
	})
	fill.Parent = back
	local corner = Instance.new("UICorner")
	corner.CornerRadius = CORNER
	corner.Parent = back
	local edge = Instance.new("UIStroke")
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Color = EDGE
	edge.Thickness = 3.5
	edge.Parent = back
	shine(back)
end

-- Cinta de lava inclinada en la esquina de arriba a la izquierda: corona y "VIP".
function OverheadVip.ribbon(back: Frame): Frame
	local tag = Instance.new("Frame")
	tag.Name = "CintaVIP"
	tag.AnchorPoint = Vector2.new(0.5, 0.5)
	tag.Position = UDim2.fromScale(0.05, 0.02)
	tag.SizeConstraint = Enum.SizeConstraint.RelativeYY
	tag.Size = UDim2.fromScale(1.75, 0.72)
	tag.Rotation = -14
	tag.ZIndex = 5
	Kit.skin(tag, "lava").SliceScale = 0.18
	local crown = Icons.view(tag, "crown")
	crown.AnchorPoint = Vector2.new(0.5, 0.5)
	crown.Position = UDim2.fromScale(0.2, 0.42)
	crown.SizeConstraint = Enum.SizeConstraint.RelativeYY
	crown.Size = UDim2.fromScale(1.15, 1.15)
	crown.ZIndex = 7
	local text = Style.text(tag, "Texto", 60, WHITE, 2)
	text.Text = "VIP"
	text.Position = UDim2.fromScale(0.38, 0.1)
	text.Size = UDim2.fromScale(0.56, 0.8)
	text.ZIndex = 6
	Kit.gold(text)
	local scale = Instance.new("UIScale")
	scale.Parent = tag
	TweenService:Create(scale, PULSE, { Scale = 1.12 }):Play()
	tag.Visible = false
	tag.Parent = back
	return tag
end

-- Nombre en oro (VIP) o como venía. Devuelve el degradado dorado para que brille.
function OverheadVip.name(label: TextLabel, vip: boolean): UIGradient?
	local gradient = label:FindFirstChild("OroVIP")
	if not vip then
		if gradient then
			gradient:Destroy()
		end
		local stroke = label:FindFirstChildOfClass("UIStroke")
		local color = label:GetAttribute("BordeOriginal")
		if stroke and typeof(color) == "Color3" then
			stroke.Color = color
		end
		return nil
	end
	local stroke = label:FindFirstChildOfClass("UIStroke")
	if stroke and label:GetAttribute("BordeOriginal") == nil then
		label:SetAttribute("BordeOriginal", stroke.Color)
	end
	Kit.gold(label)
	local fill = label:FindFirstChildOfClass("UIGradient") :: UIGradient
	fill.Name = "OroVIP"
	return fill
end

return table.freeze(OverheadVip)
