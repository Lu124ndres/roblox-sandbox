--!strict
--[[
	TopBar

	Los botones chicos de la esquina derecha de la barra de Roblox (premio,
	ruleta, códigos, grupo, ajustes; GuiService.TopbarInset), en una sola fila
	centrada en la barra. En táctil van más chicos (pedido del usuario el
	2026-10-21) y su tamaño sigue al alto de la pantalla (TOUCH_SHARE).
	La parte de Layout: la columna derecha empieza debajo de `bottom()`.
]]

local GuiService = game:GetService("GuiService")

local Device = require(script.Parent.Device)

local MARGIN = 12
local BUTTON_MIN, BUTTON_MAX = 26, 36
-- En táctil, una parte del alto de la pantalla: se ven igual en un teléfono y en
-- una tablet, sin bajar del mínimo cómodo para el dedo ni salirse de la barra de Roblox.
local TOUCH_SHARE = 0.075
local TOUCH_MIN, TOUCH_MAX = 28, 40
local GAP = 6

local TopBar = {}

local bar: Frame

local function place()
	local inset = GuiService.TopbarInset
	local height = inset.Height
	bar.AnchorPoint = Vector2.new(1, 0)
	if height <= 0 then
		bar.Position = UDim2.new(1, -MARGIN, 0, MARGIN)
		bar.Size = UDim2.fromOffset(400, BUTTON_MAX)
		return
	end
	local size = if Device.touch()
		then math.clamp(math.round(Device.viewport().Y * TOUCH_SHARE), TOUCH_MIN, TOUCH_MAX)
		else math.clamp(height - 18, BUTTON_MIN, BUTTON_MAX)
	bar.Position = UDim2.fromOffset(inset.Max.X - MARGIN, inset.Min.Y + (height - size) / 2)
	bar.Size = UDim2.fromOffset(400, size)
end

function TopBar.mount(playerGui: Instance, displayOrder: number): Frame
	local screen = Instance.new("ScreenGui")
	screen.Name = "BarraSuperior"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.DisplayOrder = displayOrder
	screen.Parent = playerGui
	bar = Instance.new("Frame")
	bar.Name = "Botones"
	bar.BackgroundTransparency = 1
	bar.Parent = screen
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Right
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, GAP)
	list.Parent = bar
	place()
	GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(place)
	Device.onResize(place)
	return bar
end

function TopBar.frame(): Frame
	return bar
end

-- Borde de abajo de los botones en píxeles absolutos (los de AbsolutePosition).
function TopBar.bottom(): number
	local layout = bar:FindFirstChildWhichIsA("UIGridStyleLayout")
	local used = if layout then layout.AbsoluteContentSize.Y else bar.AbsoluteSize.Y
	return bar.AbsolutePosition.Y + math.min(used, bar.AbsoluteSize.Y)
end

return TopBar
