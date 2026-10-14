--!strict
--[[
	EventTimer

	En la columna derecha, debajo del entrenamiento del servidor: el evento
	del servidor activo (nombre, qué da y cuánto le queda, con su color) o,
	si no hay, cuánto falta para el siguiente ("Evento en 4:12"). La
	cuenta del siguiente da una razón para quedarse. Lo decide el servidor
	(server/Social/EventScheduler); aquí solo se muestra.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServerEvents = require(ReplicatedStorage.Shared.ServerEvents)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local CardParts = require(script.Parent.Parent.Interface.CardParts)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Layout = require(script.Parent.Parent.Interface.Layout)
local Style = require(script.Parent.Parent.Interface.Style)

local REFRESH_SECONDS = 0.5
local IDLE_COLOR = Color3.fromRGB(64, 72, 110)

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
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = pill
	Style.border(pill, 3)
	pill.Parent = Layout.right()
	local icon = Icons.view(pill, "bolt")
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Position = UDim2.new(0, 2, 0.5, 0)
	icon.Size = UDim2.fromOffset(46, 46)
	local title = Style.text(pill, "Nombre", 22, nil, 2)
	title.Position = UDim2.fromOffset(48, 4)
	title.Size = UDim2.new(1, -54, 0, 24)
	local detail = Style.text(pill, "Detalle", 17, nil, 2)
	detail.Position = UDim2.fromOffset(48, 29)
	detail.Size = UDim2.new(1, -54, 0, 20)
	local painted: Color3? = nil
	local function paint(color: Color3)
		if painted ~= color then
			painted = color
			CardParts.paint(pill, color)
		end
	end

	task.spawn(function()
		while true do
			local kind = ServerEvents.active()
			if kind then
				paint(kind.color)
				title.Text = kind.name
				detail.Text = `{kind.text} · {clock(ServerEvents.secondsLeft())}`
				detail.TextColor3 = UIConfig.Colors.Text
			else
				local wait = ServerEvents.secondsToNext()
				paint(IDLE_COLOR)
				title.Text = "Próximo evento"
				detail.Text = if wait > 0 then `en {clock(wait)}` else "pronto"
				detail.TextColor3 = Color3.fromRGB(255, 220, 90)
			end
			task.wait(REFRESH_SECONDS)
		end
	end)
end

return EventTimer
