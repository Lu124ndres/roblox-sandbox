--!strict
--[[
	Layout

	Dónde va cada parte del HUD, para que nada se encime en PC ni en móvil:
		izquierda   columna con las estadísticas y la misión del tutorial
		derecha     columna con el aviso del entrenamiento del servidor, Tienda y
		            Robux, y los atajos de Poder y Monedas
		barra       botones redondos en la barra de Roblox (ajustes, premio,
		            colección), justo después de los botones de Roblox
	Las columnas se achican en pantallas bajas (UIScale según el alto), así en
	un teléfono acostado no llegan a los botones de Pescar y Saltar.
	La columna derecha mide lo mismo que sus filas (dos botones de 96 con 12
	entre ellos) y las centra, así Tienda, Mejoras y los atajos quedan alineados.
]]

local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Device = require(script.Parent.Device)

local REFERENCE_HEIGHT = 600 -- alto de pantalla en que el HUD va a escala 1
local MIN_SCALE, MAX_SCALE = 0.55, 1.2
local PHONE_REFERENCE_HEIGHT, PHONE_MIN_SCALE = 700, 0.45
local MARGIN = 12
local STAT_WIDTH = 320 -- ancho de las filas de estadísticas en PC
local STAT_WIDTH_TOUCH = 260 -- más angostas en táctil: dejan sitio a la barra de hambre

local Layout = {}

-- Medidas de la columna derecha (antes de escalar), las comparten todas sus filas.
Layout.BUTTON_SIZE = 96
Layout.BUTTON_GAP = 12
Layout.RIGHT_WIDTH = Layout.BUTTON_SIZE * 2 + Layout.BUTTON_GAP

local left: Frame
local right: Frame
local topBar: Frame
local scales: { UIScale } = {}
local scaleCallbacks: { () -> () } = {}
local currentScale = 1

-- Ancho de las filas de la columna izquierda (estadísticas, impulso de amigos).
function Layout.statWidth(): number
	return if Device.touch() then STAT_WIDTH_TOUCH else STAT_WIDTH
end

local function column(screen: ScreenGui, name: string, anchorRight: boolean): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundTransparency = 1
	frame.AnchorPoint = Vector2.new(if anchorRight then 1 else 0, 0)
	frame.Position =
		UDim2.new(if anchorRight then 1 else 0, if anchorRight then -MARGIN else MARGIN, 0, MARGIN)
	frame.Size =
		UDim2.fromOffset(if anchorRight then Layout.RIGHT_WIDTH else Layout.statWidth(), 600)
	frame.Parent = screen
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 8)
	list.HorizontalAlignment = if anchorRight
		then Enum.HorizontalAlignment.Center
		else Enum.HorizontalAlignment.Left
	list.Parent = frame
	Layout.scaleWith(frame)
	return frame
end

-- El objeto se achica o agranda con la pantalla (como todo el HUD).
function Layout.scaleWith(object: GuiObject)
	local scale = Instance.new("UIScale")
	scale.Scale = currentScale
	scale.Parent = object
	table.insert(scales, scale)
end

function Layout.scale(): number
	return currentScale
end

-- `callback` corre cada vez que cambia la pantalla, ya con la escala nueva.
function Layout.onScaleChanged(callback: () -> ())
	table.insert(scaleCallbacks, callback)
end

local function refreshScale()
	local camera = Workspace.CurrentCamera
	local height = if camera then camera.ViewportSize.Y else REFERENCE_HEIGHT
	-- En teléfonos (pantalla baja y táctil) el HUD va un poco más chico.
	local phone = height <= 500 and UserInputService.TouchEnabled
	local reference = if phone then PHONE_REFERENCE_HEIGHT else REFERENCE_HEIGHT
	currentScale =
		math.clamp(height / reference, if phone then PHONE_MIN_SCALE else MIN_SCALE, MAX_SCALE)
	for _, scale in scales do
		scale.Scale = currentScale
	end
	for _, callback in scaleCallbacks do
		task.spawn(callback)
	end
end

-- Botones en la barra de Roblox, a la derecha de los suyos (GuiService.TopbarInset).
local function placeTopBar()
	local inset = GuiService.TopbarInset
	local height = inset.Height
	if height <= 0 then
		topBar.Position = UDim2.fromOffset(MARGIN, MARGIN)
		topBar.Size = UDim2.fromOffset(400, 44)
		return
	end
	topBar.Position = UDim2.fromOffset(inset.Min.X + 8, inset.Min.Y + 4)
	topBar.Size = UDim2.fromOffset(400, height - 8)
end

function Layout.mount(screen: ScreenGui, playerGui: Instance)
	left = column(screen, "ColumnaIzquierda", false)
	right = column(screen, "ColumnaDerecha", true)

	local barScreen = Instance.new("ScreenGui")
	barScreen.Name = "BarraSuperior"
	barScreen.ResetOnSpawn = false
	barScreen.IgnoreGuiInset = true
	barScreen.DisplayOrder = screen.DisplayOrder
	barScreen.Parent = playerGui
	topBar = Instance.new("Frame")
	topBar.Name = "Botones"
	topBar.BackgroundTransparency = 1
	topBar.Parent = barScreen
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 10)
	list.Parent = topBar
	placeTopBar()
	GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(placeTopBar)

	refreshScale()
	local camera = Workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(refreshScale)
	end
end

function Layout.left(): Frame
	return left
end

function Layout.right(): Frame
	return right
end

function Layout.topBar(): Frame
	return topBar
end

-- Borde de abajo de la columna izquierda en píxeles (para la tarjeta de captura).
function Layout.leftBottom(): number
	local bottom = left.AbsolutePosition.Y
	for _, child in left:GetChildren() do
		if child:IsA("GuiObject") and child.Visible then
			bottom = math.max(bottom, child.AbsolutePosition.Y + child.AbsoluteSize.Y)
		end
	end
	return bottom
end

return Layout
