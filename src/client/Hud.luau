--!strict
--[[
	Hud

	Estadísticas compactas a la izquierda, al estilo simulador: cada una en una
	placa de piedra (Interface/Kit) con el ícono asomando por la izquierda, su
	multiplicador debajo del ícono y el número grande con contorno (las
	monedas, doradas), sin palabras (pedido del usuario, 2026-10-18):
		Monedas   (x de Monedas compradas)
		Poder     (x de Poder: compras y entrenamiento del servidor)
		Peces     en la canasta / capacidad («LLENA» bajo el ícono cuando no cabe más)
		Kills     monstruos llenados
	Solo muestra: los valores los decide el servidor.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local FishingPower = require(ReplicatedStorage.Shared.FishingPower)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Perks = require(ReplicatedStorage.Shared.Perks)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Icons = require(script.Parent.Interface.Icons)
local Kit = require(script.Parent.Interface.Kit)
local Layout = require(script.Parent.Interface.Layout)
local Style = require(script.Parent.Interface.Style)

local COLORS = UIConfig.Colors
local ATTR = Protocol.PlayerAttributes
local ROW_HEIGHT = 60
local VALUE_HEIGHT = ROW_HEIGHT - 12
local BADGE_HEIGHT = 20
local PLATE_SLICE = 0.3 -- borde de la placa más fino que en las ventanas
local TEXT_RIGHT = 10 -- margen del texto al canto derecho de la placa

type Row = { value: TextLabel, badge: TextLabel }

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
	frame.Parent = Layout.stats()
	-- La placa empieza a media altura del ícono: el ícono asoma por la izquierda.
	local plate = Instance.new("Frame")
	plate.Name = "Placa"
	plate.BackgroundTransparency = 1
	plate.Position = UDim2.fromOffset(Layout.STAT_PLATE_LEFT, 2)
	plate.Size = UDim2.new(1, -Layout.STAT_PLATE_LEFT, 1, -4)
	plate.ZIndex = 0
	plate.Parent = frame
	Kit.skin(plate, "panel").SliceScale = PLATE_SLICE
	-- El ícono, centrado en el canto izquierdo de la placa y a su media altura.
	local view = Icons.view(frame, icon)
	view.AnchorPoint = Vector2.new(0.5, 0.5)
	view.Position = UDim2.new(0, Layout.STAT_PLATE_LEFT, 0.5, 0)
	view.Size = UDim2.fromOffset(Layout.STAT_ICON, ROW_HEIGHT - 4)
	local badge = Style.text(frame, "Multiplicador", BADGE_HEIGHT, nil, 2)
	badge.AnchorPoint = Vector2.new(0.5, 1)
	badge.Position = UDim2.new(0, Layout.STAT_PLATE_LEFT, 1, 2)
	badge.Size = UDim2.fromOffset(Layout.STAT_ICON + 10, BADGE_HEIGHT)
	badge.ZIndex = 3
	-- El número, grande y a media altura de la placa.
	local value = Style.text(frame, "Valor", VALUE_HEIGHT, color, 3)
	value.TextXAlignment = Enum.TextXAlignment.Left
	value.AnchorPoint = Vector2.new(0, 0.5)
	value.Position = UDim2.new(0, Layout.STAT_TEXT_LEFT, 0.5, 0)
	value.Size = UDim2.new(1, -Layout.STAT_TEXT_LEFT - TEXT_RIGHT, 0, VALUE_HEIGHT)
	return { value = value, badge = badge }
end

-- Un decimal como mucho (pedido del usuario el 2026-10-21): x1.32 → x1.3, x2.0 → x2.
local function multiplier(value: number): string
	if value >= 1000 then
		return `x{NumberFormat.short(value)}`
	end
	local text = string.format("%.1f", value)
	return `x{(string.gsub(text, "%.0$", ""))}`
end

-- Devuelve la etiqueta de monedas (destino de las monedas que vuelan).
function Hud.mount(_screen: ScreenGui, player: Player): TextLabel
	local coins = row(1, "coin", COLORS.Coins)
	local power = row(2, "crystal", Color3.fromRGB(150, 205, 255))
	local fish = row(3, "basketFish", COLORS.Fishing)
	local kills = row(4, "skull", Color3.fromRGB(255, 120, 110))
	Kit.gold(coins.value)
	Kit.gold(coins.badge)
	Kit.gold(power.badge)
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

	local function refreshBadges()
		coins.badge.Text = multiplier(Perks.coinMultiplier(player))
		power.badge.Text = multiplier(Perks.powerMultiplier(player))
	end

	local function refresh()
		set(coins.value, NumberFormat.big(number(player, ATTR.Coins)))
		set(power.value, NumberFormat.big(number(player, ATTR.Power)))
		refreshBadges()
		local capacity = FishingPower.playerCapacity(player)
		local carried = number(player, ATTR.CarriedFish)
		local full = carried >= capacity
		set(fish.value, `{NumberFormat.short(carried)}/{NumberFormat.short(capacity)}`)
		fish.value.TextColor3 = if full then COLORS.Feeding else COLORS.Fishing
		fish.badge.Text = "LLENA"
		fish.badge.TextColor3 = COLORS.Feeding
		fish.badge.Visible = full
		set(kills.value, NumberFormat.big(number(player, ATTR.Kills)))
	end
	player.AttributeChanged:Connect(refresh)
	-- Los impulsos con tiempo (servidor, x2 personal, x2 monedas de la ruleta, eventos,
	-- racha del diario) vencen solos sin cambiar atributos: revisar cada segundo.
	task.spawn(function()
		while true do
			task.wait(1)
			refreshBadges()
		end
	end)
	refresh()
	return coins.value
end

return Hud
