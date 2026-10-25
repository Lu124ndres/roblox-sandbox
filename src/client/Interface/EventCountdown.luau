--!strict
--[[
	EventCountdown

	Pastilla chica abajo a la derecha con la cuenta regresiva del siguiente
	evento del servidor (Config/Events): «Evento en 4:32». Mientras hay uno
	activo muestra su ícono, su nombre y lo que le queda («¡Pesca dorada! ·
	2:10»). Es discreta a propósito (pedido del usuario: «sutil y no
	estorboso»): fondo semitransparente, texto chico y, como mucho, un pulso
	suave en los últimos segundos antes de que empiece.
	Dónde va, para no tapar nada:
		PC      pegada al borde de abajo, en la franja libre que deja el botón
		        de acción (ActionSpot lo pone a 32 px del borde)
		táctil  justo encima del botón de saltar de Roblox, alineada con el borde
		        derecho de las columnas; el botón de acción y el aviso de los
		        prompts quedan a su izquierda. Las columnas la esquivan
		        (Layout.avoid), así las estadísticas no bajan hasta ella.
	Se oculta con el resto del HUD durante el tutorial y con una ventana abierta
	en táctil (TutorialHud y HudFocus la buscan por su nombre, «ContadorEvento»).
	Lo que pasa lo decide el servidor (EventScheduler); aquí solo se lee
	(Shared/ServerEvents).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ServerEvents = require(ReplicatedStorage.Shared.ServerEvents)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Device = require(script.Parent.Device)
local HudVisibility = require(script.Parent.HudVisibility)
local Icons = require(script.Parent.Icons)
local Layout = require(script.Parent.Layout)
local TouchControls = require(script.Parent.TouchControls)

local NAME = "ContadorEvento" -- TutorialHud y HudFocus la ocultan por este nombre
local REFRESH_SECONDS = 1
-- Alto antes de escalar: en táctil un poco más alta porque el HUD se achica más en teléfonos.
local HEIGHT = if Device.touch() then 30 else 22
local TEXT_SIZE = if Device.touch() then 19 else 15
local PADDING = 8
local GAP = 4 -- entre el ícono y los textos
local MARGIN = 12 -- el mismo borde derecho que las columnas (Interface/Columns)
local BOTTOM = 5 -- PC: debajo del botón de acción, que deja 32 px libres
local JUMP_GAP = 8 -- táctil: aire sobre el botón de saltar
local BACKGROUND_TRANSPARENCY = 0.45
local STROKE = 1.2
local WAITING_ICON = "sunburst" -- rayos teñidos: todavía no se sabe cuál toca
local PULSE_SECONDS = 10 -- últimos segundos antes del siguiente: pulso suave
local PULSE = TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local PULSE_TRANSPARENCY = 0.35
local HIDDEN_REASON = "sinEvento" -- sin datos del servidor (HudVisibility)

local COLORS = UIConfig.Colors

local EventCountdown = {}

local function label(parent: Instance, name: string, order: number, color: Color3): TextLabel
	local text = Instance.new("TextLabel")
	text.Name = name
	text.LayoutOrder = order
	text.BackgroundTransparency = 1
	text.AutomaticSize = Enum.AutomaticSize.X
	text.Size = UDim2.fromScale(0, 1)
	text.FontFace = UIConfig.Fonts.Title
	text.TextSize = TEXT_SIZE
	text.TextColor3 = color
	local stroke = Instance.new("UIStroke")
	stroke.Color = COLORS.TextStroke
	stroke.Thickness = STROKE
	stroke.Parent = text
	text.Parent = parent
	return text
end

local function clock(seconds: number): string
	local total = math.ceil(seconds)
	return string.format("%d:%02d", total // 60, total % 60)
end

function EventCountdown.start(screen: ScreenGui)
	local pill = Instance.new("Frame")
	pill.Name = NAME
	pill.AnchorPoint = Vector2.new(1, 1)
	pill.AutomaticSize = Enum.AutomaticSize.X
	pill.Size = UDim2.fromOffset(0, HEIGHT)
	pill.BackgroundColor3 = COLORS.Panel
	pill.BackgroundTransparency = BACKGROUND_TRANSPARENCY
	pill.Active = false
	pill.Interactable = false -- no se come los toques de lo que hay detrás
	pill.Parent = screen
	Layout.scaleWith(pill)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = pill
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, PADDING)
	padding.PaddingRight = UDim.new(0, PADDING)
	padding.Parent = pill
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, GAP)
	list.Parent = pill

	-- Dos textos: el de las palabras se traduce entero (AutoTranslate) y el del
	-- reloj, sin letras, se queda igual; así no hace falta una plantilla por evento.
	local title = label(pill, "Titulo", 2, COLORS.TextMuted)
	local clockText = label(pill, "Tiempo", 3, COLORS.Text)

	local icon: GuiObject? = nil
	local iconKind = ""
	local function setIcon(kind: string, color: Color3?)
		if kind ~= iconKind then
			if icon then
				icon:Destroy()
			end
			local view = Icons.view(pill, kind)
			view.LayoutOrder = 1
			view.Size = UDim2.fromOffset(HEIGHT - 4, HEIGHT - 4)
			icon, iconKind = view, kind
		end
		if icon and icon:IsA("ImageLabel") then
			icon.ImageColor3 = color or Color3.new(1, 1, 1)
		end
	end

	local function place()
		local jumpTop = TouchControls.jumpTop()
		if jumpTop then
			local y = jumpTop - screen.AbsolutePosition.Y - JUMP_GAP
			pill.Position = UDim2.new(1, -MARGIN, 0, y)
		else
			pill.Position = UDim2.new(1, -MARGIN, 1, -BOTTOM)
		end
	end
	TouchControls.onChange(place)
	screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
	place()
	Layout.avoid(pill)

	local pulse: Tween? = nil
	local function setPulse(on: boolean)
		if on == (pulse ~= nil) then
			return
		end
		if pulse then
			pulse:Cancel()
			pulse = nil
			clockText.TextTransparency = 0
		else
			local tween =
				TweenService:Create(clockText, PULSE, { TextTransparency = PULSE_TRANSPARENCY })
			tween:Play()
			pulse = tween
		end
	end

	local function refresh()
		local kind = ServerEvents.active()
		if kind then
			setIcon(kind.icon)
			title.Text = kind.name
			title.TextColor3 = kind.color
			clockText.Text = `· {clock(ServerEvents.secondsLeft())}`
			setPulse(false)
			HudVisibility.set(pill, HIDDEN_REASON, false)
			return
		end
		local untilNext = ServerEvents.secondsToNext()
		setIcon(WAITING_ICON, COLORS.Warning)
		title.Text = "Evento en"
		title.TextColor3 = COLORS.TextMuted
		clockText.Text = clock(untilNext)
		setPulse(untilNext > 0 and untilNext <= PULSE_SECONDS)
		-- Sin hora del siguiente (el servidor todavía no la puso): no hay nada que contar.
		HudVisibility.set(pill, HIDDEN_REASON, untilNext <= 0)
	end

	refresh()
	task.spawn(function()
		while pill.Parent do
			task.wait(REFRESH_SECONDS)
			refresh()
		end
	end)
end

return EventCountdown
