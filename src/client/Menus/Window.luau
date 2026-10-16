--!strict
--[[
	Window

	Ventana estilo simulador: panel oscuro (o de madera), borde negro grueso,
	título enorme arriba a la izquierda y X roja. Solo una abierta a la vez.
	En táctil ocupa casi toda la pantalla. `onAnyChange` avisa de toda ventana
	que se abre o cierra (GamepadNav lleva el mando adentro).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local TextCase = require(ReplicatedStorage.Shared.TextCase)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local Device = require(script.Parent.Parent.Interface.Device)
local Style = require(script.Parent.Parent.Interface.Style)
local WindowLayout = require(script.Parent.WindowLayout)

local PALETTE = Style.PALETTE
local TITLE_HEIGHT = 34 -- cuánto sobresale el título por encima del panel
local CLOSE_SIZE = 56

export type Window = {
	frame: Frame,
	scale: UIScale, -- escala de la ventana (para pasar tamaños de pantalla a los suyos)
	panel: Frame,
	content: Frame,
	open: () -> (),
	close: () -> (),
	toggle: () -> (),
	isOpen: () -> boolean,
	onOpen: (callback: () -> ()) -> (),
	onClose: (callback: () -> ()) -> (),
}

local Window = {}

local current: Window? = nil
local changeListeners: { (window: Window, opened: boolean) -> () } = {}

function Window.onAnyChange(listener: (window: Window, opened: boolean) -> ())
	table.insert(changeListeners, listener)
end

Window.fit = WindowLayout.fit
Window.share = WindowLayout.share

-- `panelColor`: color del fondo (por defecto el oscuro de la tienda).
function Window.create(
	screen: ScreenGui,
	name: string,
	title: string,
	maxSize: Vector2,
	panelColor: Color3?
): Window
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundTransparency = 1
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Visible = false
	frame.ZIndex = 10
	frame.Parent = screen
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = maxSize + Vector2.new(0, TITLE_HEIGHT)
	limit.Parent = frame
	local scale = Instance.new("UIScale")
	scale.Parent = frame
	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.BackgroundColor3 = panelColor or PALETTE.Panel
	panel.Position = UDim2.fromOffset(0, TITLE_HEIGHT)
	panel.Size = UDim2.new(1, 0, 1, -TITLE_HEIGHT)
	panel.Parent = frame
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 18)
	corner.Parent = panel
	Style.gradient(panel, panelColor or PALETTE.Panel)
	Style.border(panel, 5)

	local heading = Style.text(frame, "Titulo", 64, nil, 4.5)
	heading.Text = TextCase.upper(title)
	heading.TextXAlignment = Enum.TextXAlignment.Left
	heading.Position = UDim2.fromOffset(14, 0)
	heading.Size = UDim2.new(0.7, 0, 0, TITLE_HEIGHT + 30)
	heading.ZIndex = 3
	heading.Rotation = -2

	local closeButton = Style.button(frame, "Cerrar", PALETTE.Close, "X")
	closeButton.AnchorPoint = Vector2.new(0.5, 0.5)
	closeButton.Position = UDim2.new(1, -10, 0, TITLE_HEIGHT + 8)
	closeButton.Size = UDim2.fromOffset(CLOSE_SIZE, CLOSE_SIZE)
	closeButton.ZIndex = 4
	closeButton.Rotation = 4
	local content = Instance.new("Frame")
	content.Name = "Contenido"
	content.BackgroundTransparency = 1
	content.Position = UDim2.fromOffset(16, 40)
	content.Size = UDim2.new(1, -32, 1, -54)
	content.Parent = panel

	local pop = TweenService:Create(scale, UIConfig.Tweens.Pop, {})
	local openCallbacks: { () -> () } = {}
	local closeCallbacks: { () -> () } = {}
	local window: Window
	window = {
		frame = frame,
		scale = scale,
		panel = panel,
		content = content,
		open = function()
			if current and current ~= window then
				current.close()
			end
			current = window
			for _, callback in openCallbacks do
				callback()
			end
			Sounds.play("Click")
			local fit = WindowLayout.resize(frame, screen, limit.MaxSize)
			frame.Visible = true
			scale.Scale = fit * 0.85
			pop = TweenService:Create(scale, UIConfig.Tweens.Pop, { Scale = fit })
			pop:Play()
			for _, listener in changeListeners do
				task.spawn(listener, window, true)
			end
		end,
		close = function()
			if not frame.Visible then
				return
			end
			frame.Visible = false
			if current == window then
				current = nil
			end
			for _, callback in closeCallbacks do
				callback()
			end
			for _, listener in changeListeners do
				task.spawn(listener, window, false)
			end
		end,
		toggle = function()
			if frame.Visible then
				window.close()
			else
				window.open()
			end
		end,
		isOpen = function()
			return frame.Visible
		end,
		onOpen = function(callback: () -> ())
			table.insert(openCallbacks, callback)
		end,
		onClose = function(callback: () -> ())
			table.insert(closeCallbacks, callback)
		end,
	}
	closeButton.Activated:Connect(window.close)
	local opener = Instance.new("BindableEvent")
	opener.Name = "Abrir" -- para probar en Studio: <ventana>.Abrir:Fire()
	opener.Event:Connect(window.open)
	opener.Parent = frame
	-- Si la pantalla cambia con la ventana abierta (girar el teléfono, o el teléfono
	-- termina de arrancar), se reacomoda; se corta el rebote, que si no la agranda.
	Device.onResize(function()
		if frame.Visible then
			pop:Cancel()
			scale.Scale = WindowLayout.resize(frame, screen, limit.MaxSize)
		end
	end)
	return window
end

return Window
