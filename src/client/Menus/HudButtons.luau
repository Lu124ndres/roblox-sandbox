--!strict
--[[
	HudButtons

	Botones del menú con ícono (Icons) y nombre dorado, de piedra tallada
	(Interface/Kit):
		HudButtons.side   grandes, en la columna derecha (Tienda, Mejoras), centrados;
		                  piedra gris, salvo los de LAVA (la TIENDA, con marco de lava)
		HudButtons.top    cuadraditos de piedra en la esquina derecha de la barra de
		                  Roblox (Premio, Peces, Códigos, Grupo, Ajustes)
	Cada módulo agrega el suyo y decide qué hace al tocarlo. Un punto rojo
	avisa que hay algo nuevo (por ejemplo, el premio diario).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local TextCase = require(ReplicatedStorage.Shared.TextCase)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Kit = require(script.Parent.Parent.Interface.Kit)
local Layout = require(script.Parent.Parent.Interface.Layout)
local Style = require(script.Parent.Parent.Interface.Style)
local Sounds = require(script.Parent.Parent.Audio.Sounds)

local COLORS = UIConfig.Colors
local SIDE_SIZE = Layout.BUTTON_SIZE
local TOP_SLICE = 0.2 -- borde de piedra más fino en los botones chicos de arriba
-- Los laterales que llevan el marco de lava (lo más importante).
local LAVA: { [string]: boolean } = { Tienda = true }
-- Orden de los botones de arriba (de izquierda a derecha); los demás van al final.
local TOP_ORDER: { [string]: number } =
	{ Ruleta = 1, Premio = 2, Peces = 3, ["Códigos"] = 4, Grupo = 5, Ajustes = 6, Admin = 7 }

export type HudButton = { button: TextButton, setAlert: (on: boolean) -> () }

local HudButtons = {}

local order = 0
local registered: { TextButton } = {} -- todos, en orden: los recorre el mando (GamepadNav)
local sideRow: Frame? = nil
local sideCount = 0 -- botones grandes ya puestos (van de dos en dos por fila)

local function alertDot(parent: GuiObject): Frame
	local dot = Instance.new("Frame")
	dot.Name = "Aviso"
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.new(1, -8, 0, 8)
	dot.Size = UDim2.fromOffset(14, 14)
	dot.BackgroundColor3 = COLORS.Bite
	dot.Visible = false
	dot.ZIndex = 6
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = dot
	Style.border(dot, 2)
	dot.Parent = parent
	return dot
end

-- Rebote al tocarlo, y sonido.
local function press(button: TextButton, onClick: () -> ())
	local scale = Instance.new("UIScale")
	scale.Parent = button
	button.Activated:Connect(function()
		Sounds.play("Click")
		scale.Scale = 0.88
		TweenService:Create(scale, UIConfig.Tweens.Pop, { Scale = 1 }):Play()
		onClick()
	end)
end

-- Botón de piedra con ícono y nombre dorado abajo; lo usan también los atajos de
-- Robux. `lava`: con el marco de lava (si no, piedra gris). Todo el cuadro (ícono y
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
	local skin = if lava then Kit.skin(button, "lava") else Kit.skin(button, "boton", Kit.STONE)
	Kit.press(button, skin)
	-- El ícono asoma un poco sobre el borde de arriba, como en los simuladores.
	local view = Icons.view(button, icon)
	view.AnchorPoint = Vector2.new(0.5, 0)
	view.Position = UDim2.new(0.5, 0, 0, -2)
	view.Size = UDim2.fromOffset(size - 8, size - 24)
	view.Active = false
	view.Interactable = false
	local label = Style.text(button, "Nombre", 20, nil, 2)
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.Position = UDim2.new(0.5, 0, 1, -6)
	label.Size = UDim2.new(1, -10, 0, 22)
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
		row.Size = UDim2.fromOffset(Layout.RIGHT_WIDTH, SIDE_SIZE + 4)
		row.Parent = Layout.right()
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
	button.LayoutOrder = order
	table.insert(registered, button)
	press(button, onClick)
	local dot = alertDot(button)
	return {
		button = button,
		setAlert = function(on: boolean)
			dot.Visible = on
		end,
	}
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
	local skin = Kit.skin(button, "boton", Kit.STONE)
	skin.SliceScale = TOP_SLICE
	Kit.press(button, skin)
	button.Parent = bar
	table.insert(registered, button)
	local view = Icons.view(button, icon)
	view.AnchorPoint = Vector2.new(0.5, 0.5)
	view.Position = UDim2.fromScale(0.5, 0.5)
	view.Size = UDim2.fromScale(0.9, 0.9)
	press(button, onClick)
	local dot = alertDot(button)
	dot.Size = UDim2.fromOffset(11, 11)
	dot.Position = UDim2.new(1, -4, 0, 4)
	return {
		button = button,
		setAlert = function(on: boolean)
			dot.Visible = on
		end,
	}
end

-- Los botones del HUD (primero los de la columna derecha), para el mando.
function HudButtons.all(): { TextButton }
	return registered
end

return HudButtons
