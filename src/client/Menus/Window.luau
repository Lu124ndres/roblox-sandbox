--!strict
--[[
	Window

	Ventana estilo simulador: panel oscuro (o de madera) con borde negro
	grueso, el título enorme con contorno encima de la esquina izquierda y
	una X roja en la esquina derecha. Solo una ventana del menú está abierta
	a la vez: abrir una cierra la otra. La usan la TIENDA, MEJORAS, la
	colección, el premio diario, los ajustes, los códigos y el grupo.
	En pantallas táctiles la ventana ocupa casi toda la pantalla y se ve más
	grande (los dedos necesitan botones más grandes que el mouse).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local Device = require(script.Parent.Parent.Interface.Device)
local Style = require(script.Parent.Parent.Interface.Style)

local PALETTE = Style.PALETTE
local TITLE_HEIGHT = 34 -- cuánto sobresale el título por encima del panel
local CLOSE_SIZE = 56
local REFERENCE_HEIGHT = 720 -- alto de pantalla (px) en que la ventana se ve a escala 1
local TOUCH_REFERENCE_HEIGHT = 480 -- en táctil, escala 1 ya en pantallas más bajas
local SCREEN_SHARE = Vector2.new(0.72, 0.8) -- parte de la pantalla que ocupa (PC): deja ver el juego
local TOUCH_SCREEN_SHARE = Vector2.new(0.96, 0.94)

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

-- Escala para que las ventanas se vean del mismo tamaño en cualquier
-- pantalla (en una de 1440 px de alto, el doble que en una de 720).
function Window.fit(): number
	local height = Device.viewport().Y
	if Device.touch() then
		return math.clamp(height / TOUCH_REFERENCE_HEIGHT, 0.8, 2)
	end
	return math.clamp(height / REFERENCE_HEIGHT, 0.6, 1.6)
end

-- Tamaño (en escala de la pantalla) para que, ya escalada, ocupe SCREEN_SHARE.
function Window.share(): Vector2
	return if Device.touch() then TOUCH_SCREEN_SHARE else SCREEN_SHARE
end

local function resize(frame: Frame, fit: number)
	local share = Window.share()
	frame.Size = UDim2.fromScale(share.X / fit, share.Y / fit)
	frame.Position = UDim2.fromScale(0.5, if Device.touch() then 0.5 else 0.53)
end

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
	frame.Position = UDim2.fromScale(0.5, 0.53)
	frame.Size = UDim2.fromScale(0.94, 0.84)
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
	heading.Text = string.upper(title)
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
			local fit = Window.fit()
			resize(frame, fit)
			frame.Visible = true
			scale.Scale = fit * 0.85
			TweenService:Create(scale, UIConfig.Tweens.Pop, { Scale = fit }):Play()
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
	-- Para probar en Studio desde la barra de comandos: <ventana>.Abrir:Fire().
	local opener = Instance.new("BindableEvent")
	opener.Name = "Abrir"
	opener.Event:Connect(window.open)
	opener.Parent = frame
	-- Si la pantalla cambia con la ventana abierta (girar el teléfono), se reacomoda.
	Device.onResize(function()
		if frame.Visible then
			local fit = Window.fit()
			resize(frame, fit)
			scale.Scale = fit
		end
	end)
	return window
end

return Window
