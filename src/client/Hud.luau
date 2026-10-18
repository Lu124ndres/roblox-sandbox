--!strict
--[[
	Hud

	Estadísticas compactas a la izquierda, al estilo simulador: cada una en una
	placa de piedra (Interface/Kit) con el ícono asomando por la izquierda, su
	multiplicador debajo, el número con contorno (las monedas, doradas) y una
	línea chica:
		Monedas   (x de Monedas compradas)
		Poder     (x de Poder: compras y entrenamiento del servidor) · velocidad y peces por pique
		Peces     en la canasta / capacidad («LLENA» bajo el ícono cuando no cabe más)
		Kills     monstruos llenados
	En táctil no hay líneas chicas (no se leerían): solo ícono y número.
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
local Kit = require(script.Parent.Interface.Kit)
local Layout = require(script.Parent.Interface.Layout)
local Style = require(script.Parent.Interface.Style)

local COLORS = UIConfig.Colors
local ATTR = Protocol.PlayerAttributes
local ROW_HEIGHT = 60
local VALUE_HEIGHT = 42
local DETAIL_HEIGHT = ROW_HEIGHT - VALUE_HEIGHT
local DETAIL_MAX_TEXT = 16
local BADGE_HEIGHT = 20
local PLATE_SLICE = 0.3 -- borde de la placa más fino que en las ventanas
local TEXT_RIGHT = 10 -- margen del texto al canto derecho de la placa

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
	-- Número y línea chica van en un bloque centrado a media altura de la placa:
	-- si una fila no tiene línea chica (monedas, o todas en táctil), el número
	-- queda solo en el medio en vez de pegado arriba.
	local texts = Instance.new("Frame")
	texts.Name = "Textos"
	texts.BackgroundTransparency = 1
	texts.Position = UDim2.fromOffset(Layout.STAT_TEXT_LEFT, 0)
	texts.Size = UDim2.new(1, -Layout.STAT_TEXT_LEFT - TEXT_RIGHT, 1, 0)
	texts.Parent = frame
	local stack = Instance.new("UIListLayout")
	stack.SortOrder = Enum.SortOrder.LayoutOrder
	stack.VerticalAlignment = Enum.VerticalAlignment.Center
	stack.Parent = texts
	-- En táctil el número es más grande y no hay línea chica (no se leería).
	local touch = Device.touch()
	local valueHeight = if touch then ROW_HEIGHT - 12 else VALUE_HEIGHT - 4
	local value = Style.text(texts, "Valor", valueHeight, color, 3)
	value.TextXAlignment = Enum.TextXAlignment.Left
	value.LayoutOrder = 1
	value.Size = UDim2.new(1, 0, 0, valueHeight)
	local detail = Style.text(texts, "Detalle", DETAIL_MAX_TEXT, nil, 1.5)
	detail.TextXAlignment = Enum.TextXAlignment.Left
	detail.LayoutOrder = 2
	detail.Size = UDim2.new(1, 0, 0, DETAIL_HEIGHT - 2)
	detail.Visible = not touch
	return { value = value, detail = detail, badge = badge }
end

local function multiplier(value: number): string
	return if value >= 1000 then `x{NumberFormat.short(value)}` else `x{value}`
end

-- Devuelve la etiqueta de monedas (destino de las monedas que vuelan).
function Hud.mount(_screen: ScreenGui, player: Player): TextLabel
	local coins = row(1, "coin", COLORS.Coins)
	local power = row(2, "crystal", Color3.fromRGB(150, 205, 255))
	local fish = row(3, "basketFish", COLORS.Fishing)
	local kills = row(4, "skull", Color3.fromRGB(255, 120, 110))
	coins.detail.Visible = false -- sin línea chica: el número se centra en la placa
	Kit.gold(coins.value)
	Kit.gold(coins.badge)
	Kit.gold(power.badge)
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
		local perCatch = NumberFormat.short(FishingPower.playerFishPerCatch(player))
		-- Corto, para que entre al mismo tamaño que las otras líneas chicas.
		power.detail.Text = `Vel. x{speed} · {perCatch}/pique`
		local capacity = FishingPower.playerCapacity(player)
		local carried = number(player, ATTR.CarriedFish)
		set(fish.value, `{NumberFormat.short(carried)}/{NumberFormat.short(capacity)}`)
		fish.value.TextColor3 = if carried >= capacity then COLORS.Feeding else COLORS.Fishing
		local full = carried >= capacity
		fish.detail.Text = if full then "¡Llena! Ve al volcán" else "peces en la canasta"
		fish.badge.Text = "LLENA"
		fish.badge.TextColor3 = COLORS.Feeding
		fish.badge.Visible = full
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
