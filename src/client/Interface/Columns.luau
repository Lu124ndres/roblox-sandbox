--!strict
--[[
	Columns

	Las dos columnas del HUD (Layout), el menú a la izquierda y las estadísticas a
	la derecha: cada una va centrada en la pantalla, pero
	sin salir de su franja libre, entre lo de arriba (la barra de botones, o lo
	que se aparte con `avoid`) y lo de abajo (el joystick y el botón de saltar
	de Roblox, TouchControls).
	Si no cabe, la columna se achica (cada una lo justo: la derecha tiene menos
	alto por los botones de arriba), y así en un teléfono acostado nunca tapa el
	joystick ni Saltar.
	Se reacomodan cuando cambia una fila, la pantalla o los controles táctiles.
]]

local TopBar = require(script.Parent.TopBar)
local TouchControls = require(script.Parent.TouchControls)

local MARGIN = 12
local GAP = 8 -- aire entre una columna y lo que la limita arriba o abajo
local LIST_PADDING = 4
local MIN_SCALE = 0.3 -- pueden achicarse más que el resto del HUD para no tapar los controles
local MENU_LIFT = 0.06 -- el menú (izquierda) va un poco más arriba del centro: parte del alto

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
	-- Lo apartado (la etiqueta de amigos, la zona del botón de acción) que cae en el
	-- ancho de la columna: si está en la mitad de arriba, la columna empieza debajo;
	-- si está en la de abajo, termina encima.
	local width = column.width() * maxScale
	local columnLeft = if column.left then MARGIN else screen.AbsoluteSize.X - MARGIN - width
	for _, object in avoided do
		local x = object.AbsolutePosition.X - screen.AbsolutePosition.X
		local overColumn = x < columnLeft + width and x + object.AbsoluteSize.X > columnLeft
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
	for _, column in { left, right } do
		local top, bottom = band(column)
		local content = contentHeight(column.frame)
		local fit = if content > 0 then math.min(maxScale, (bottom - top) / content) else maxScale
		fit = math.max(fit, MIN_SCALE)
		column.scale.Scale = fit
		-- Centrada en la pantalla si cabe ahí (el menú, un poco más arriba); si no,
		-- corrida lo justo dentro de su franja.
		local height = content * fit
		local center = (top + bottom) / 2
		if height < bottom - top then
			local wanted = screen.AbsoluteSize.Y * (0.5 - if column.left then MENU_LIFT else 0)
			center = math.clamp(wanted, top + height / 2, bottom - height / 2)
		end
		column.frame.Position = UDim2.new(
			if column.left then 0 else 1,
			if column.left then MARGIN else -MARGIN,
			0,
			center - height / 2
		)
		column.frame.Size = UDim2.fromOffset(column.width(), content)
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

-- `statsWidth` y `menuWidth`: ancho de cada columna antes de escalar. Devuelve
-- la de estadísticas (a la derecha) y la del menú (a la izquierda).
function Columns.mount(
	gui: ScreenGui,
	playerGui: Instance,
	statsWidth: () -> number,
	menuWidth: () -> number
): (Frame, Frame)
	screen = gui
	left = column("ColumnaMenu", true, menuWidth)
	right = column("ColumnaEstadisticas", false, statsWidth)
	local bar = TopBar.frame()
	bar:GetPropertyChangedSignal("AbsolutePosition"):Connect(requestPlace)
	bar:GetPropertyChangedSignal("AbsoluteSize"):Connect(requestPlace)
	TouchControls.onChange(requestPlace)
	TouchControls.start(playerGui)
	screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(requestPlace)
	requestPlace()
	return right.frame, left.frame
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
