--!strict
--[[
	TopBar

	Los botones chicos de la esquina derecha de la barra de Roblox (premio,
	colección, códigos, grupo, ajustes; GuiService.TopbarInset). En PC van en
	una fila; en táctil, en dos filas de 4 que empiezan en la barra y bajan
	por debajo de ella: así dejan libre el centro de la barra para el panel de
	hambre y no tapan los botones de Roblox. En táctil su tamaño sigue al alto
	de la pantalla (TOUCH_SHARE).
	La parte de Layout: la columna derecha empieza debajo de `bottom()`.
]]

local GuiService = game:GetService("GuiService")

local Device = require(script.Parent.Device)

local MARGIN = 12
local BUTTON_MIN, BUTTON_MAX = 26, 36
-- En táctil, una parte del alto de la pantalla: se ven igual en un teléfono y en
-- una tablet, sin bajar del mínimo cómodo para el dedo ni salirse de la barra de Roblox.
local TOUCH_SHARE = 0.1
local TOUCH_MIN, TOUCH_MAX = 38, 50 -- 50: deja aire en la barra de Roblox (58) para el punto de aviso
local COLUMNS_TOUCH = 4
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
	if Device.touch() then
		-- Dos filas de 4 que empiezan en la barra de Roblox y bajan por debajo de ella.
		local size = math.clamp(math.round(Device.viewport().Y * TOUCH_SHARE), TOUCH_MIN, TOUCH_MAX)
		local grid = bar:FindFirstChildOfClass("UIGridLayout")
		if grid then
			grid.CellSize = UDim2.fromOffset(size, size)
		end
		bar.Position =
			UDim2.fromOffset(inset.Max.X - MARGIN, inset.Min.Y + math.max((height - size) / 2, 0))
		local width = COLUMNS_TOUCH * size + (COLUMNS_TOUCH - 1) * GAP
		bar.Size = UDim2.fromOffset(width, size * 2 + GAP)
		return
	end
	local size = math.clamp(height - 18, BUTTON_MIN, BUTTON_MAX)
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
	if Device.touch() then
		-- Cuadrícula de 4 columnas: los botones llenan de derecha a izquierda, fila por fila.
		local grid = Instance.new("UIGridLayout")
		grid.FillDirection = Enum.FillDirection.Horizontal
		grid.HorizontalAlignment = Enum.HorizontalAlignment.Right
		grid.SortOrder = Enum.SortOrder.LayoutOrder
		grid.FillDirectionMaxCells = COLUMNS_TOUCH
		grid.CellPadding = UDim2.fromOffset(GAP, GAP)
		grid.Parent = bar
	else
		local list = Instance.new("UIListLayout")
		list.FillDirection = Enum.FillDirection.Horizontal
		list.HorizontalAlignment = Enum.HorizontalAlignment.Right
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Padding = UDim.new(0, GAP)
		list.Parent = bar
	end
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
