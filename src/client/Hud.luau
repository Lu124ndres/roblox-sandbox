--!strict
--[[
	Hud

	Estadísticas grandes a la izquierda, al estilo simulador: ícono con su
	multiplicador debajo, el número grande con contorno y una línea chica:
		Monedas   (x de Monedas compradas)
		Poder     (x de Poder: compras y entrenamiento del servidor) · velocidad y peces por pique
		Peces     en la canasta / capacidad
		Kills     monstruos llenados
	En táctil las filas son más angostas (Layout.statWidth) y las líneas chicas
	usan textos cortos, para que se lean grandes en un teléfono.
	Solo muestra: los valores los decide el servidor.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local FishingPower = require(ReplicatedStorage.Shared.FishingPower)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Perks = require(ReplicatedStorage.Shared.Perks)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Device = require(script.Parent.Interface.Device)
local Icons = require(script.Parent.Interface.Icons)
local Layout = require(script.Parent.Interface.Layout)
local Style = require(script.Parent.Interface.Style)

local COLORS = UIConfig.Colors
local ATTR = Protocol.PlayerAttributes
local ROW_HEIGHT = 78
local VALUE_HEIGHT = 54
local DETAIL_HEIGHT = ROW_HEIGHT - VALUE_HEIGHT
-- Texto de la línea chica: en un teléfono (escala ~0.63) 20 se ve de ~13 px.
local DETAIL_MAX_TEXT = 22
local DETAIL_MIN_TEXT_TOUCH = 14

type Row = { value: TextLabel, detail: TextLabel, badge: TextLabel }

local Hud = {}

local function number(player: Player, attribute: string): number
	local value = player:GetAttribute(attribute)
	return if type(value) == "number" then value else 0
end

local function bump(label: TextLabel)
	local scale = label:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	scale.Parent = label
	scale.Scale = 1.18
	TweenService:Create(scale, UIConfig.Tweens.Pop, { Scale = 1 }):Play()
end

local function row(order: number, icon: string, color: Color3): Row
	local frame = Instance.new("Frame")
	frame.Name = `Stat{order}`
	frame.LayoutOrder = order
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromOffset(Layout.statWidth(), ROW_HEIGHT)
	frame.Parent = Layout.left()
	local view = Icons.view(frame, icon)
	view.Size = UDim2.fromOffset(ROW_HEIGHT, ROW_HEIGHT - 6)
	local badge = Style.text(frame, "Multiplicador", 26, nil, 2.5)
	badge.AnchorPoint = Vector2.new(0.5, 1)
	badge.Position = UDim2.new(0, ROW_HEIGHT / 2, 1, 2)
	badge.Size = UDim2.fromOffset(ROW_HEIGHT + 10, 26)
	badge.ZIndex = 3
	local value = Style.text(frame, "Valor", VALUE_HEIGHT, color, 3.5)
	value.TextXAlignment = Enum.TextXAlignment.Left
	value.Position = UDim2.fromOffset(ROW_HEIGHT + 6, 0)
	value.Size = UDim2.new(1, -ROW_HEIGHT - 6, 0, VALUE_HEIGHT)
	local detail = Style.text(frame, "Detalle", DETAIL_MAX_TEXT, nil, 1.5)
	detail.TextXAlignment = Enum.TextXAlignment.Left
	detail.Position = UDim2.fromOffset(ROW_HEIGHT + 4, VALUE_HEIGHT)
	detail.Size = UDim2.new(1, -ROW_HEIGHT - 4, 0, DETAIL_HEIGHT)
	local limit = detail:FindFirstChildOfClass("UITextSizeConstraint")
	if limit and Device.touch() then
		limit.MinTextSize = DETAIL_MIN_TEXT_TOUCH
	end
	return { value = value, detail = detail, badge = badge }
end

local function multiplier(value: number): string
	return if value >= 1000 then `x{NumberFormat.short(value)}` else `x{value}`
end

-- Devuelve la etiqueta de monedas (destino de las monedas que vuelan).
function Hud.mount(_screen: ScreenGui, player: Player): TextLabel
	local short = Device.touch() -- textos cortos en las líneas chicas
	local coins = row(1, "coin", COLORS.Coins)
	local power = row(2, "crystal", Color3.fromRGB(150, 205, 255))
	local fish = row(3, "basketFish", COLORS.Fishing)
	local kills = row(4, "skull", Color3.fromRGB(255, 120, 110))
	coins.detail.Visible = false
	kills.detail.Text = "monstruos llenados"
	kills.badge.Visible = false

	local last: { [TextLabel]: string } = {}
	local function set(label: TextLabel, text: string)
		if last[label] ~= text then
			if last[label] ~= nil then
				bump(label)
			end
			last[label] = text
			label.Text = text
		end
	end

	local function refresh()
		local amount = number(player, ATTR.Power)
		set(coins.value, NumberFormat.big(number(player, ATTR.Coins)))
		coins.badge.Text = multiplier(Perks.coinMultiplier(player))
		set(power.value, NumberFormat.big(amount))
		power.badge.Text = multiplier(Perks.powerMultiplier(player))
		local speed = string.format("%.1f", FishingPower.speed(amount))
		local perCatch = FishingPower.fishPerCatch(amount)
		power.detail.Text = if short
			then `x{speed} vel · {perCatch}/pique`
			else `Velocidad x{speed} · {perCatch} peces por pique`
		local capacity = FishingPower.playerCapacity(player)
		local carried = number(player, ATTR.CarriedFish)
		set(fish.value, `{carried}/{capacity}`)
		fish.value.TextColor3 = if carried >= capacity then COLORS.Feeding else COLORS.Fishing
		local full = carried >= capacity
		fish.detail.Text = if short
			then (if full then "¡Llena! Al volcán" else "en la canasta")
			else (if full
				then "¡Canasta llena! Llévalos al volcán"
				else "peces en la canasta")
		fish.badge.Visible = false
		set(kills.value, NumberFormat.big(number(player, ATTR.Kills)))
	end
	player.AttributeChanged:Connect(refresh)
	-- El entrenamiento del servidor vence solo: revisar su multiplicador de vez en cuando.
	task.spawn(function()
		while true do
			task.wait(1)
			power.badge.Text = multiplier(Perks.powerMultiplier(player))
		end
	end)
	refresh()
	return coins.value
end

return Hud
