--!strict
--[[
	Layout

	Dónde va cada parte del HUD, para que nada se encime en PC ni en móvil:
		menú           a la izquierda: el aviso del entrenamiento del servidor, el
		               Índice, Mejoras, Tienda, Misiones y Renacer
		estadísticas   a la derecha: monedas, poder, canasta, monstruos y el regalo
		               por jugar (se cambiaron de lado el 2026-10-21, pedido del usuario)
		barra          botones chicos en la esquina derecha de la barra de Roblox
		               (Interface/TopBar), con los atajos de Robux debajo (QuickBuys)
	Las columnas van en la franja libre entre la barra y los controles táctiles
	de Roblox (y el lugar del botón de acción, Interface/ActionSpot), y se
	achican si no caben (Interface/Columns).
	Todo el HUD se achica en pantallas bajas (UIScale según el alto).
	La columna del menú mide lo mismo que sus filas (dos botones con 10
	entre ellos) y las centra, así Tienda, Mejoras y los atajos quedan alineados.
]]

local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local ActionSpot = require(script.Parent.ActionSpot)
local Columns = require(script.Parent.Columns)
local Device = require(script.Parent.Device)
local TopBar = require(script.Parent.TopBar)

-- Escala 1 a partir de 760 px de alto (un monitor 1080p) y nunca más grande:
-- el HUD es chico y deja ver el juego.
local REFERENCE_HEIGHT = 760
local MIN_SCALE, MAX_SCALE = 0.5, 1
local PHONE_REFERENCE_HEIGHT, PHONE_MIN_SCALE = 760, 0.45
local STAT_WIDTH = 250 -- ancho de las filas de estadísticas en PC
local STAT_WIDTH_TOUCH = 210 -- más angostas en táctil: dejan sitio a la barra de hambre

local Layout = {}

-- Medidas de la columna del menú (antes de escalar), las comparten todas sus filas.
-- En PC y consola mide lo mismo que la de estadísticas (250; pedido del usuario el
-- 2026-10-21); en táctil, más chica.
Layout.BIG_MENU = not Device.touch()
Layout.BUTTON_SIZE = if Layout.BIG_MENU then 120 else 88
Layout.BUTTON_GAP = 10
Layout.MENU_WIDTH = Layout.BUTTON_SIZE * 2 + Layout.BUTTON_GAP
-- Filas de la columna de estadísticas: el ícono ocupa los primeros STAT_ICON píxeles,
-- la placa empieza en su mitad y el texto justo después del ícono. Las comparten
-- las estadísticas (Hud) y el regalo por jugar (PlaytimeEntry) para quedar alineados.
Layout.STAT_ICON = 60
Layout.STAT_PLATE_LEFT = Layout.STAT_ICON / 2
Layout.STAT_TEXT_LEFT = Layout.STAT_ICON + 4

local stats: Frame
local menu: Frame
local topBar: Frame
local scales: { UIScale } = {}
local scaleCallbacks: { () -> () } = {}
local currentScale = 1

-- Ancho de las filas de la columna de estadísticas.
function Layout.statWidth(): number
	return if Device.touch() then STAT_WIDTH_TOUCH else STAT_WIDTH
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

-- Las columnas no se meten debajo ni encima de `object` (está pegado a un borde).
Layout.avoid = Columns.avoid

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
	Columns.setMaxScale(currentScale)
end

function Layout.mount(screen: ScreenGui, playerGui: Instance)
	topBar = TopBar.mount(playerGui, screen.DisplayOrder)
	stats, menu = Columns.mount(screen, playerGui, Layout.statWidth, function()
		return Layout.MENU_WIDTH
	end)
	Columns.avoid(ActionSpot.mount(screen)) -- las estadísticas no bajan hasta Pescar

	refreshScale()
	local camera = Workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(refreshScale)
	end
end

function Layout.stats(): Frame
	return stats
end

function Layout.menu(): Frame
	return menu
end

function Layout.topBar(): Frame
	return topBar
end

-- Borde de abajo de la columna del menú en píxeles (la tarjeta de captura va debajo).
function Layout.menuBottom(): number
	local bottom = menu.AbsolutePosition.Y
	for _, child in menu:GetChildren() do
		if child:IsA("GuiObject") and child.Visible then
			bottom = math.max(bottom, child.AbsolutePosition.Y + child.AbsoluteSize.Y)
		end
	end
	return bottom
end

return Layout
