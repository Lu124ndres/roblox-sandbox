--!strict
--[[
	OverheadVip

	Lo del pase VIP en la placa sobre la cabeza (OverheadBadges): la placa
	pasa de lava a oro (degradado dorado con borde marrón) y en su esquina de
	arriba a la izquierda aparece una cinta de lava inclinada que dice "VIP"
	en dorado.
]]

local Kit = require(script.Parent.Kit)
local Style = require(script.Parent.Style)

local rgb = Color3.fromRGB
local WHITE = Color3.new(1, 1, 1)
local EDGE = rgb(90, 45, 10) -- borde marrón de la placa de oro

local OverheadVip = {}

OverheadVip.LINE = rgb(110, 60, 10) -- las líneas doradas no se ven sobre el oro

-- Placa de lava o de oro. El oro no es la piedra de Kit tintada (es oscura y
-- queda ocre): un degradado dorado con borde marrón y esquinas redondas.
function OverheadVip.paint(back: Frame, vip: boolean, slice: number)
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
		ColorSequenceKeypoint.new(0, rgb(255, 246, 170)),
		ColorSequenceKeypoint.new(0.5, rgb(255, 206, 64)),
		ColorSequenceKeypoint.new(1, rgb(214, 128, 24)),
	})
	fill.Parent = back
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.3, 0)
	corner.Parent = back
	local edge = Instance.new("UIStroke")
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Color = EDGE
	edge.Thickness = 3
	edge.Parent = back
end

-- Cinta "VIP" de lava, inclinada, en la esquina de arriba a la izquierda de la placa.
function OverheadVip.ribbon(back: Frame): Frame
	local tag = Instance.new("Frame")
	tag.Name = "CintaVIP"
	tag.AnchorPoint = Vector2.new(0.5, 0.5)
	tag.Position = UDim2.fromScale(0.06, 0.02)
	tag.SizeConstraint = Enum.SizeConstraint.RelativeYY
	tag.Size = UDim2.fromScale(1.25, 0.58)
	tag.Rotation = -14
	tag.ZIndex = 5
	Kit.skin(tag, "lava").SliceScale = 0.18
	local text = Style.text(tag, "Texto", 60, WHITE, 2)
	text.Text = "VIP"
	text.Position = UDim2.fromScale(0.12, 0.1)
	text.Size = UDim2.fromScale(0.76, 0.8)
	text.ZIndex = 6
	Kit.gold(text)
	tag.Visible = false
	tag.Parent = back
	return tag
end

return table.freeze(OverheadVip)
