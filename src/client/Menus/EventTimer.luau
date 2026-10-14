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
local Ui = require(script.Parent.Parent.Ui)
local Layout = require(script.Parent.Parent.Interface.Layout)
local Style = require(script.Parent.Parent.Interface.Style)

local REFRESH_SECONDS = 0.5
local IDLE_COLOR = Color3.fromRGB(40, 44, 58)

local EventTimer = {}

local function clock(seconds: number): string
	local total = math.ceil(seconds)
	return string.format("%d:%02d", total // 60, total % 60)
end

function EventTimer.start()
	local pill = Ui.panel("EventoServidor", Layout.right())
	pill.LayoutOrder = 2
	pill.Size = UDim2.fromOffset(Layout.RIGHT_WIDTH, 50)
	Style.border(pill, 3)
	local title = Style.text(pill, "Nombre", 22, nil, 2)
	title.Position = UDim2.fromOffset(6, 3)
	title.Size = UDim2.new(1, -12, 0, 24)
	local detail = Style.text(pill, "Detalle", 17, nil, 1.5)
	detail.Position = UDim2.fromOffset(6, 27)
	detail.Size = UDim2.new(1, -12, 0, 19)

	task.spawn(function()
		while true do
			local kind = ServerEvents.active()
			if kind then
				pill.BackgroundColor3 = kind.color
				pill.BackgroundTransparency = 0.05
				title.Text = kind.name
				detail.Text = `{kind.text} · {clock(ServerEvents.secondsLeft())}`
				detail.TextColor3 = UIConfig.Colors.Text
			else
				local wait = ServerEvents.secondsToNext()
				pill.BackgroundColor3 = IDLE_COLOR
				pill.BackgroundTransparency = 0.25
				title.Text = "Próximo evento"
				detail.Text = if wait > 0 then `en {clock(wait)}` else "pronto"
				detail.TextColor3 = Color3.fromRGB(255, 220, 90)
			end
			task.wait(REFRESH_SECONDS)
		end
	end)
end

return EventTimer
