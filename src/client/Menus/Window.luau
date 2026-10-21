--!strict
--[[
	Window

	Ventana estilo simulador: panel de piedra tallada (Interface/Kit), título
	enorme dorado arriba a la izquierda con una gema a cada lado y X de piedra
	roja. Solo una abierta a la vez.
	En táctil ocupa casi toda la pantalla. `onAnyChange` avisa de toda ventana
	que se abre o cierra (GamepadNav lleva el mando adentro).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local Device = require(script.Parent.Parent.Interface.Device)
local Kit = require(script.Parent.Parent.Interface.Kit)
local Style = require(script.Parent.Parent.Interface.Style)
local WindowLayout = require(script.Parent.WindowLayout)
local WindowTitle = require(script.Parent.WindowTitle)

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
	setShrink: (factor: number) -> (), -- ocupa menos pantalla (1 = lo normal)
}

local Window = {}

local current: Window? = nil
local changeListeners: { (window: Window, opened: boolean) -> () } = {}

function Window.onAnyChange(listener: (window: Window, opened: boolean) -> ())
	table.insert(changeListeners, listener)
end

Window.fit = WindowLayout.fit
Window.share = WindowLayout.share

-- `panelColor`: ya no se usa (todas las ventanas son de piedra); queda por compatibilidad.
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
	Kit.skin(panel, "panel")

	-- El marco mide siempre `maxSize` en sus unidades (WindowLayout.resize lo topa ahí).
	WindowTitle.make(frame, title, math.min(maxSize.X * 0.8, maxSize.X - 110), TITLE_HEIGHT + 30)

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
	local shrink = 1
	-- Acomoda la ventana. Las achicadas (setShrink) tienen aire: suben medio título para
	-- que el panel, no el marco, quede en el centro de la pantalla.
	local function resize(): number
		local fit = WindowLayout.resize(frame, screen, limit.MaxSize, shrink)
		if shrink < 1 then
			frame.Position += UDim2.fromOffset(0, -TITLE_HEIGHT * fit / 2)
		end
		return fit
	end
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
			local fit = resize()
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
		setShrink = function(factor: number)
			shrink = factor
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
			scale.Scale = resize()
		end
	end)
	return window
end

return Window
