--!strict
--[[
	Columns

	Las dos columnas del HUD (Layout): cada una va centrada en su franja libre,
	entre lo de arriba (la barra de botones, o lo que se aparte con `avoid`) y
	lo de abajo (el joystick y el botón de saltar de Roblox, TouchControls).
	Si no cabe, la columna se achica (las dos por igual, así las filas se ven
	parejas), y así en un teléfono acostado nunca tapa el joystick ni Saltar.
	Se reacomodan cuando cambia una fila, la pantalla o los controles táctiles.
]]

local TopBar = require(script.Parent.TopBar)
local TouchControls = require(script.Parent.TouchControls)

local MARGIN = 12
local GAP = 8 -- aire entre una columna y lo que la limita arriba o abajo
local LIST_PADDING = 4
local MIN_SCALE = 0.3 -- pueden achicarse más que el resto del HUD para no tapar los controles

type Column = { frame: Frame, scale: UIScale, left: boolean, width: () -> number }

local Columns = {}

local screen: ScreenGui
local left: Column
local right: Column
local avoided: { GuiObject } = {}
local maxScale = 1
local pending = false

-- Alto de lo que hay en la columna, antes de escalar (todas sus filas miden en offset;
-- no se usa AbsoluteContentSize, que cambia con la propia escala).
local function contentHeight(frame: Frame): number
	local total, count = 0, 0
	for _, child in frame:GetChildren() do
		if child:IsA("GuiObject") and child.Visible then
			total += child.Size.Y.Offset
			count += 1
		end
	end
	return total + math.max(count - 1, 0) * LIST_PADDING
end

-- Franja libre de la columna en píxeles absolutos: de `top` a `bottom`.
local function band(column: Column): (number, number)
	local top, bottom = MARGIN, screen.AbsoluteSize.Y - MARGIN
	if not column.left then
		top = math.max(top, TopBar.bottom() + GAP)
	end
	local control = if column.left then TouchControls.thumbstickTop() else TouchControls.jumpTop()
	if control then
		bottom = math.min(bottom, control - GAP)
	end
	-- Lo apartado (la etiqueta de amigos): si está en la mitad de arriba, la columna
	-- empieza debajo; si está en la de abajo, termina encima.
	for _, object in avoided do
		local overColumn = (object.AbsolutePosition.X < screen.AbsoluteSize.X / 2) == column.left
		if object.Visible and object.Parent and overColumn then
			local objectTop = object.AbsolutePosition.Y
			local objectBottom = objectTop + object.AbsoluteSize.Y
			if objectTop + object.AbsoluteSize.Y / 2 < screen.AbsoluteSize.Y / 2 then
				top = math.max(top, objectBottom + GAP)
			else
				bottom = math.min(bottom, objectTop - GAP)
			end
		end
	end
	return top, math.max(bottom, top + 1)
end

local function place()
	local fit = maxScale
	local bands: { [Column]: Vector2 } = {}
	for _, column in { left, right } do
		local top, bottom = band(column)
		bands[column] = Vector2.new(top, bottom)
		local content = contentHeight(column.frame)
		if content > 0 then
			fit = math.min(fit, (bottom - top) / content)
		end
	end
	fit = math.max(fit, MIN_SCALE)
	for column, range in bands do
		column.scale.Scale = fit
		column.frame.Position = UDim2.new(
			if column.left then 0 else 1,
			if column.left then MARGIN else -MARGIN,
			0,
			range.X
		)
		column.frame.Size = UDim2.fromOffset(column.width(), (range.Y - range.X) / fit)
	end
end

-- Reacomoda en el siguiente cuadro (junta varios avisos en uno).
local function requestPlace()
	if pending then
		return
	end
	pending = true
	task.defer(function()
		pending = false
		place()
	end)
end

local function column(name: string, isLeft: boolean, width: () -> number): Column
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundTransparency = 1
	frame.AnchorPoint = Vector2.new(if isLeft then 0 else 1, 0)
	frame.Parent = screen
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, LIST_PADDING)
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.HorizontalAlignment = if isLeft
		then Enum.HorizontalAlignment.Left
		else Enum.HorizontalAlignment.Center
	list.Parent = frame
	-- Si aparece, se oculta o cambia una fila (el regalo, el aviso del evento), se reacomoda.
	list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(requestPlace)
	local scale = Instance.new("UIScale")
	scale.Parent = frame
	return { frame = frame, scale = scale, left = isLeft, width = width }
end

-- `leftWidth` y `rightWidth`: ancho de cada columna antes de escalar.
function Columns.mount(
	gui: ScreenGui,
	playerGui: Instance,
	leftWidth: () -> number,
	rightWidth: () -> number
): (Frame, Frame)
	screen = gui
	left = column("ColumnaIzquierda", true, leftWidth)
	right = column("ColumnaDerecha", false, rightWidth)
	local bar = TopBar.frame()
	bar:GetPropertyChangedSignal("AbsolutePosition"):Connect(requestPlace)
	bar:GetPropertyChangedSignal("AbsoluteSize"):Connect(requestPlace)
	TouchControls.onChange(requestPlace)
	TouchControls.start(playerGui)
	screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(requestPlace)
	requestPlace()
	return left.frame, right.frame
end

-- Las columnas nunca van más grandes que esto (la escala del resto del HUD).
function Columns.setMaxScale(scale: number)
	maxScale = scale
	requestPlace()
end

-- Las columnas no se meten debajo ni encima de `object` (está pegado a un borde).
function Columns.avoid(object: GuiObject)
	table.insert(avoided, object)
	object:GetPropertyChangedSignal("AbsolutePosition"):Connect(requestPlace)
	object:GetPropertyChangedSignal("AbsoluteSize"):Connect(requestPlace)
	object:GetPropertyChangedSignal("Visible"):Connect(requestPlace)
	requestPlace()
end

return Columns
