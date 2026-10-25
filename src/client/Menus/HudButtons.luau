--!strict
--[[
	HudButtons

	Botones del menú con ícono (Icons) y nombre dorado, en la "casilla
	volcánica" (Interface/Kit): piedra oscura con grietas de lava, como las
	tarjetas de MEJORAS de la referencia del usuario.
		HudButtons.side   grandes, en la columna del menú (Tienda, Mejoras), centrados;
		                  casilla, salvo los de LAVA (la TIENDA, con marco de lava)
		HudButtons.wide   placa ancha arriba de la columna del menú (Índice de peces)
		HudButtons.top    casillas chicas en la esquina derecha de la barra de
		                  Roblox (Ruleta, Premio, Códigos, Grupo, Ajustes)
	Cada módulo agrega el suyo y decide qué hace al tocarlo. Un punto rojo
	avisa que hay algo nuevo (por ejemplo, el premio diario).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TextCase = require(ReplicatedStorage.Shared.TextCase)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Kit = require(script.Parent.Parent.Interface.Kit)
local Layout = require(script.Parent.Parent.Interface.Layout)
local Style = require(script.Parent.Parent.Interface.Style)
local HudButtonParts = require(script.Parent.HudButtonParts)

local SIDE_SIZE = Layout.BUTTON_SIZE
-- Grosor del canto: el de la casilla mide 34 px en la imagen; a 0.32 queda en unos 10 px
-- sobre un botón de 88 (como las tarjetas de la referencia), y más fino en los de arriba.
local SIDE_SLICE = 0.32
local TOP_SLICE = 0.16
local INSET = 10 -- lo que ocupa el canto en los grandes: el ícono queda dentro
-- Los botones grandes de PC (Layout.BUTTON_SIZE) llevan la placa ancha y los nombres más grandes.
local BIG = Layout.BIG_MENU
local WIDE_HEIGHT = if BIG then 60 else 54 -- alto de la placa ancha (HudButtons.wide)
local WIDE_TEXT = if BIG then 26 else 24
local NAME_TEXT = if BIG then 22 else 19 -- nombre bajo el ícono de los botones grandes
-- Los laterales que llevan el marco de lava (lo más importante).
local LAVA: { [string]: boolean } = { Tienda = true }
-- Orden de los grandes dentro de su fila: la TIENDA a la izquierda (pedido del usuario el 2026-10-21).
local SIDE_ORDER: { [string]: number } = { Tienda = 1, Mejoras = 2, Misiones = 3, Renacer = 4 }
-- Orden de los botones de arriba (de izquierda a derecha); los demás van al final.
local TOP_ORDER: { [string]: number } =
	{ Ruleta = 1, Premio = 2, ["Códigos"] = 3, Ajustes = 5, Admin = 6 }

export type HudButton = { button: TextButton, setAlert: (on: boolean) -> () }

local HudButtons = {}

local order = 0
-- Cada botón grande con su apretón, por nombre (las flechas del mando y los globos de NextGoal).
local sides: { [string]: { button: TextButton, press: () -> () } } = {}
local sideRow: Frame? = nil
local sideCount = 0 -- botones grandes ya puestos (van de dos en dos por fila)

local alertDot = HudButtonParts.alertDot
local press = HudButtonParts.press

local function withDot(button: TextButton, dot: Frame): HudButton
	return {
		button = button,
		setAlert = function(on: boolean)
			dot.Visible = on
		end,
	}
end

-- Casilla con ícono y nombre dorado abajo. `lava`: con el marco de lava (si no, la casilla oscura). Todo el cuadro (ícono y
-- nombre) es el botón: el ícono y el nombre no reciben toques, así el toque
-- siempre llega al botón aunque caiga sobre el dibujo.
function HudButtons.iconButton(
	parent: Instance,
	text: string,
	icon: string,
	size: number,
	lava: boolean?
): TextButton
	local button = Instance.new("TextButton")
	button.Name = `Boton{text}`
	button.Text = ""
	button.AutoButtonColor = false
	button.Active = true
	button.Size = UDim2.fromOffset(size, size + 4)
	button.Parent = parent
	local skin = Kit.skin(button, if lava then "lava" else "casilla")
	skin.SliceScale = SIDE_SLICE
	Kit.press(button, skin)
	-- El ícono, centrado arriba dentro del canto; el nombre, abajo.
	local view = Icons.view(button, icon)
	view.AnchorPoint = Vector2.new(0.5, 0)
	view.Position = UDim2.new(0.5, 0, 0, INSET - 4)
	view.Size = UDim2.fromOffset(size - 2 * INSET - 2, size - 26)
	view.Active = false
	view.Interactable = false
	local label = Style.text(button, "Nombre", NAME_TEXT, nil, 2)
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.Position = UDim2.new(0.5, 0, 1, -7)
	label.Size = UDim2.new(1, -12, 0, NAME_TEXT + 1)
	label.Active = false
	label.Interactable = false
	label.Text = TextCase.upper(text)
	Kit.gold(label)
	return button
end

function HudButtons.side(text: string, icon: string, onClick: () -> ()): HudButton
	if sideCount % 2 == 0 then
		local row = Instance.new("Frame")
		row.Name = "Menu"
		row.LayoutOrder = 10 + sideCount // 2 * 30 -- Mejoras y Tienda arriba; Misiones y Renacer abajo de los atajos
		row.BackgroundTransparency = 1
		row.Size = UDim2.fromOffset(Layout.MENU_WIDTH, SIDE_SIZE + 4)
		row.Parent = Layout.menu()
		local list = Instance.new("UIListLayout")
		list.FillDirection = Enum.FillDirection.Horizontal
		list.HorizontalAlignment = Enum.HorizontalAlignment.Center
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Padding = UDim.new(0, Layout.BUTTON_GAP)
		list.Parent = row
		sideRow = row
	end
	order += 1
	sideCount += 1
	local button = HudButtons.iconButton(sideRow :: Frame, text, icon, SIDE_SIZE, LAVA[text])
	button.LayoutOrder = SIDE_ORDER[text] or 10 + order
	sides[text] = { button = button, press = press(button, onClick) }
	return withDot(button, alertDot(button))
end

-- El apretón del botón grande `text` (para las flechas del mando, GamepadNav).
function HudButtons.sidePress(text: string): (() -> ())?
	local side = sides[text]
	return if side then side.press else nil
end

-- El botón grande `text`, o nil si su módulo todavía no lo puso.
function HudButtons.sideButton(text: string): TextButton?
	local side = sides[text]
	return if side then side.button else nil
end

-- Placa ancha arriba de la columna del menú (el Índice de peces): ícono a la
-- izquierda y el nombre dorado, del ancho de una fila de dos botones.
function HudButtons.wide(text: string, icon: string, onClick: () -> ()): HudButton
	order += 1
	local button = Instance.new("TextButton")
	button.Name = `Boton{text}`
	button.Text = ""
	button.LayoutOrder = 2 -- debajo del entrenamiento del servidor, encima de Mejoras y Tienda
	button.AutoButtonColor = false
	button.Size = UDim2.fromOffset(Layout.MENU_WIDTH, WIDE_HEIGHT)
	local skin = Kit.skin(button, "casilla")
	skin.SliceScale = SIDE_SLICE
	Kit.press(button, skin)
	button.Parent = Layout.menu()
	local view = Icons.view(button, icon)
	view.AnchorPoint = Vector2.new(0, 0.5)
	view.Position = UDim2.new(0, 8, 0.5, 0)
	view.Size = UDim2.fromOffset(WIDE_HEIGHT - 12, WIDE_HEIGHT - 12)
	view.Active = false
	view.Interactable = false
	local label = Style.text(button, "Nombre", WIDE_TEXT, nil, 2)
	label.Position = UDim2.fromOffset(WIDE_HEIGHT, 10)
	label.Size = UDim2.new(1, -WIDE_HEIGHT - 10, 1, -20)
	label.Active = false
	label.Interactable = false
	label.Text = TextCase.upper(text)
	Kit.gold(label)
	press(button, onClick)
	return withDot(button, alertDot(button))
end

function HudButtons.top(text: string, icon: string, onClick: () -> ()): HudButton
	order += 1
	local bar = Layout.topBar()
	local button = Instance.new("TextButton")
	button.Name = `Boton{text}`
	button.Text = ""
	button.LayoutOrder = TOP_ORDER[text] or 10 + order
	button.AutoButtonColor = false
	button.Size = UDim2.fromScale(1, 1)
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.Parent = button
	local skin = Kit.skin(button, "casilla")
	skin.SliceScale = TOP_SLICE
	Kit.press(button, skin)
	button.Parent = bar
	local view = Icons.view(button, icon)
	view.AnchorPoint = Vector2.new(0.5, 0.5)
	view.Position = UDim2.fromScale(0.5, 0.5)
	view.Size = UDim2.fromScale(0.8, 0.8) -- dentro del canto
	press(button, onClick)
	local dot = alertDot(button)
	dot.Size = UDim2.fromOffset(11, 11)
	dot.Position = UDim2.new(1, -4, 0, 4)
	return withDot(button, dot)
end

return HudButtons
