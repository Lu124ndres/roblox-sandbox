--!strict
--[[
	EventIntro

	El anuncio grande cuando empieza un evento del servidor (o al entrar a uno
	que ya corre), para que se sepa cuál es: en el centro de arriba, rayos que
	giran del color del evento, su ícono, el nombre enorme («¡PESCA DORADA!»)
	en su color con contorno negro grueso y abajo qué da y cuánto dura. Entra
	de golpe con rebote, se queda unos segundos y sube desvaneciéndose. Lo
	arranca Main.client; el evento lo decide el servidor (EventScheduler).
	Durante el tutorial no sale (solo se ve el tutorial): si el evento sigue
	al terminarlo, se anuncia entonces.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Events = require(ReplicatedStorage.Shared.Config.Events)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local ServerEvents = require(ReplicatedStorage.Shared.ServerEvents)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Layout = require(script.Parent.Parent.Interface.Layout)
local Style = require(script.Parent.Parent.Interface.Style)

local WHITE = Color3.new(1, 1, 1)
local HOLD_SECONDS = 3.5
local POP = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local LEAVE = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local SPIN = TweenInfo.new(8, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)

local EventIntro = {}

local function show(screen: ScreenGui, kind: Events.EventDef)
	local group = Instance.new("CanvasGroup")
	group.Name = "AnuncioEvento"
	group.AnchorPoint = Vector2.new(0.5, 0.5)
	group.Position = UDim2.fromScale(0.5, 0.3)
	group.Size = UDim2.fromOffset(640, 230)
	group.BackgroundTransparency = 1
	group.ZIndex = 50
	group.Parent = screen
	Layout.scaleWith(group)
	local pop = Instance.new("UIScale")
	pop.Scale = 0.2
	pop.Parent = group

	local rays = Icons.view(group, "sunburst")
	rays.AnchorPoint = Vector2.new(0.5, 0.5)
	rays.Position = UDim2.fromScale(0.5, 0.32)
	rays.Size = UDim2.fromOffset(200, 200)
	if rays:IsA("ImageLabel") then
		rays.ImageColor3 = kind.color
		rays.ImageTransparency = 0.2
	end
	TweenService:Create(rays, SPIN, { Rotation = 360 }):Play()
	local icon = Icons.view(group, kind.icon)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.32)
	icon.Size = UDim2.fromOffset(110, 110)
	icon.ZIndex = 2

	local title = Style.text(group, "Nombre", 72, WHITE, 5)
	title.Text = string.upper(kind.name)
	title.AnchorPoint = Vector2.new(0.5, 0)
	title.Position = UDim2.fromScale(0.5, 0.52)
	title.Size = UDim2.new(1, 0, 0, 72)
	title.ZIndex = 3
	local fill = Instance.new("UIGradient")
	fill.Rotation = 90
	fill.Color = ColorSequence.new(kind.color:Lerp(WHITE, 0.6), kind.color)
	fill.Parent = title
	local detail = Style.text(group, "Detalle", 32, WHITE, 3)
	-- Los minutos reales: el panel admin puede lanzar uno más largo (o el admin abuse).
	local left = math.round(ServerEvents.secondsLeft() / 60)
	detail.Text = `{kind.text} · {if left > 0 then left else Events.durationMinutes} min`
	detail.AnchorPoint = Vector2.new(0.5, 0)
	detail.Position = UDim2.fromScale(0.5, 0.84)
	detail.Size = UDim2.new(1, 0, 0, 34)
	detail.ZIndex = 3

	Sounds.play("StageUp")
	TweenService:Create(pop, POP, { Scale = 1 }):Play()
	task.delay(HOLD_SECONDS, function()
		TweenService:Create(group, LEAVE, {
			GroupTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.22),
		}):Play()
		task.wait(LEAVE.Time)
		group:Destroy()
	end)
end

-- ¿Está en pleno tutorial (o todavía no se sabe)?
local function inTutorial(player: Player): boolean
	local step = player:GetAttribute(Protocol.PlayerAttributes.Tutorial)
	return player:GetAttribute(Protocol.PlayerAttributes.DataLoaded) ~= true
		or (if type(step) == "number" then step else 0) < #Config.Retention.tutorial
end

function EventIntro.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	local seen: string? = nil
	task.spawn(function()
		while true do
			if not inTutorial(player) then
				local kind = ServerEvents.active()
				local id = kind and kind.id
				if kind and id ~= seen then
					show(screen, kind)
				end
				seen = id
			end
			task.wait(0.5)
		end
	end)
end

return EventIntro
