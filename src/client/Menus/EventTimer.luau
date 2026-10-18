--!strict
--[[
	EventTimer

	En la columna derecha, debajo del entrenamiento del servidor: el evento
	del servidor activo (nombre, qué da y cuánto le queda, con su color) o,
	si no hay, cuánto falta para el siguiente ("Evento en 4:12"), en una
	placa de piedra oscura con grietas de lava (la casilla de Interface/Kit,
	como los botones de al lado) con el nombre dorado; durante un evento la
	piedra y el detalle toman su color, el ícono es el del evento y la placa
	late. La cuenta del siguiente da una razón para quedarse. También arranca
	el anuncio grande (EventIntro). Lo decide el servidor
	(server/Social/EventScheduler); aquí solo se muestra.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ServerEvents = require(ReplicatedStorage.Shared.ServerEvents)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Kit = require(script.Parent.Parent.Interface.Kit)
local Layout = require(script.Parent.Parent.Interface.Layout)
local Style = require(script.Parent.Parent.Interface.Style)
local EventIntro = require(script.Parent.EventIntro)

local REFRESH_SECONDS = 0.5
local SLICE_SCALE = 0.32 -- el mismo canto que los botones de la columna
local EVENT_TINT = 0.45 -- cuánto se tiñe la piedra del color del evento (0 = nada)
local IDLE_COLOR = Color3.new(1, 1, 1) -- la casilla tal cual mientras no hay evento
local IDLE_ICON = "bolt"
local BEAT = TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

local EventTimer = {}

local function clock(seconds: number): string
	local total = math.ceil(seconds)
	return string.format("%d:%02d", total // 60, total % 60)
end

function EventTimer.start()
	local pill = Instance.new("Frame")
	pill.Name = "EventoServidor"
	pill.LayoutOrder = 2
	pill.Size = UDim2.fromOffset(Layout.RIGHT_WIDTH, 54)
	local skin = Kit.skin(pill, "casilla")
	skin.SliceScale = SLICE_SCALE
	pill.Parent = Layout.right()
	local icon = Icons.view(pill, "bolt")
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Position = UDim2.new(0, 7, 0.5, 0)
	icon.Size = UDim2.fromOffset(40, 40)
	local title = Style.text(pill, "Nombre", 21, nil, 2)
	title.Position = UDim2.fromOffset(50, 6)
	title.Size = UDim2.new(1, -60, 0, 23)
	Kit.gold(title)
	local detail = Style.text(pill, "Detalle", 17, nil, 2)
	detail.Position = UDim2.fromOffset(50, 29)
	detail.Size = UDim2.new(1, -60, 0, 18)
	local beat = Instance.new("UIScale")
	beat.Parent = pill
	local pulse = TweenService:Create(beat, BEAT, { Scale = 1.07 })
	local iconKind = IDLE_ICON
	local function setIcon(kind: string)
		if kind ~= iconKind and icon:IsA("ImageLabel") and Icons.paint(icon, kind) then
			iconKind = kind
		end
	end
	local screen = pill:FindFirstAncestorOfClass("ScreenGui")
	if screen then
		EventIntro.start(screen)
	end
	local painted: Color3? = nil
	-- La casilla ya es oscura: un tinte entero (Kit.tint) la apagaría del todo, así
	-- que se mezcla blanco con el color del evento.
	local function paint(color: Color3)
		if painted ~= color then
			painted = color
			skin.ImageColor3 = IDLE_COLOR:Lerp(color, EVENT_TINT)
		end
	end

	task.spawn(function()
		while true do
			local kind = ServerEvents.active()
			if kind then
				paint(kind.color)
				setIcon(kind.icon)
				if pulse.PlaybackState ~= Enum.PlaybackState.Playing then
					pulse:Play()
				end
				title.Text = kind.name
				detail.Text = `{kind.text} · {clock(ServerEvents.secondsLeft())}`
				detail.TextColor3 = kind.color:Lerp(UIConfig.Colors.Text, 0.35)
			else
				local wait = ServerEvents.secondsToNext()
				paint(IDLE_COLOR)
				setIcon(IDLE_ICON)
				pulse:Cancel()
				beat.Scale = 1
				title.Text = "Próximo evento"
				detail.Text = if wait > 0 then `en {clock(wait)}` else "pronto"
				detail.TextColor3 = Color3.fromRGB(255, 220, 90)
			end
			task.wait(REFRESH_SECONDS)
		end
	end)
end

return EventTimer
