--!strict
--[[
	HudButtons

	Botones del menú con ícono (Icons) y nombre con contorno:
		HudButtons.side   grandes, en la columna derecha (Tienda, Mejoras), centrados
		HudButtons.top    redondos, en la barra de Roblox (Ajustes, Premio, Peces)
	Cada módulo agrega el suyo y decide qué hace al tocarlo. Un punto rojo
	avisa que hay algo nuevo (por ejemplo, el premio diario).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local TextCase = require(ReplicatedStorage.Shared.TextCase)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Layout = require(script.Parent.Parent.Interface.Layout)
local Style = require(script.Parent.Parent.Interface.Style)
local Sounds = require(script.Parent.Parent.Audio.Sounds)

local COLORS = UIConfig.Colors
local SIDE_SIZE = Layout.BUTTON_SIZE
local TOP_DARK = Color3.fromRGB(28, 30, 38)

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

-- Botón de ícono con nombre abajo; lo usan también los atajos de Robux. Todo el
-- cuadro (ícono y nombre) es el botón: el ícono y el nombre no reciben toques,
-- así el toque siempre llega al botón aunque caiga sobre el dibujo.
function HudButtons.iconButton(
	parent: Instance,
	text: string,
	icon: string,
	size: number
): TextButton
	local button = Instance.new("TextButton")
	button.Name = `Boton{text}`
	button.Text = ""
	button.BackgroundTransparency = 1
	button.Active = true
	button.Size = UDim2.fromOffset(size, size + 4)
	button.Parent = parent
	local view = Icons.view(button, icon)
	view.Size = UDim2.fromOffset(size, size - 10)
	view.Active = false
	view.Interactable = false
	local label = Style.text(button, "Nombre", 20, nil, 2)
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.Position = UDim2.new(0.5, 0, 1, 0)
	label.Size = UDim2.new(1, 4, 0, 22) -- casi el ancho del botón: no pisa al vecino
	label.Active = false
	label.Interactable = false
	label.Text = TextCase.upper(text)
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
	local button = HudButtons.iconButton(sideRow :: Frame, text, icon, SIDE_SIZE)
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
	button.LayoutOrder = order
	button.BackgroundColor3 = TOP_DARK
	button.BackgroundTransparency = 0.25
	button.Size = UDim2.fromScale(1, 1)
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.Parent = button
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = button
	button.Parent = bar
	table.insert(registered, button)
	local view = Icons.view(button, icon)
	view.AnchorPoint = Vector2.new(0.5, 0.5)
	view.Position = UDim2.fromScale(0.5, 0.5)
	view.Size = UDim2.fromScale(0.95, 0.95)
	press(button, onClick)
	local dot = alertDot(button)
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
