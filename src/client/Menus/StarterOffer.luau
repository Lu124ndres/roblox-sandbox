--!strict
--[[
	StarterOffer

	Oferta de bienvenida: a los `DELAY_SECONDS` de cada partida, si todavía
	no compró el pack de inicio (atributo PackInicio), se abre esta ventana.
	Arriba el regalo sobre rayos, el título y la etiqueta de descuento; en el
	medio cinco tarjetas con lo que trae (monedas, caña, canasta, botas con
	sus íconos de MEJORAS y x2 poder); abajo lo que costaría por separado
	(precios en Robux de MEJORAS) tachado y el botón que late. Una vez por
	partida; también está siempre arriba en la TIENDA hasta comprarlo.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Assets = require(ReplicatedStorage.Shared.Assets)
local Config = require(ReplicatedStorage.Shared.Config)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local Style = require(script.Parent.Parent.Interface.Style)
local Purchases = require(script.Parent.Purchases)
local StarterParts = require(script.Parent.StarterParts)
local Window = require(script.Parent.Window)

local DELAY_SECONDS = 150
local PACK = Config.Monetization.starterPack
local ROBUX = Config.Monetization.upgradeRobux
local CARDS = Style.PALETTE.Cards
local PULSE = TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

type Item = {
	color: Color3,
	title: string,
	detail: string,
	gear: string?,
	level: number?,
	icon: string?,
}

local StarterOffer = {}

-- Lo que costarían las mejoras del pack compradas con Robux en MEJORAS.
local function separateRobux(): number
	local function price(category: string, level: number): number
		local list = ROBUX[category]
		return if list and list[level] then list[level] else 0
	end
	return price("Rod", PACK.rod) + price("Basket", PACK.basket) + price("Boots", PACK.boots)
end

local function gearItem(category: Upgrades.Category, level: number, color: Color3): Item
	return {
		color = color,
		title = Upgrades.list(category)[level].name,
		detail = `Nivel {level}`,
		gear = category,
		level = level,
	}
end

function StarterOffer.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	local window = Window.create(screen, "PackInicio", "¡Oferta!", Vector2.new(820, 500))
	local content = window.content
	local separate = separateRobux()
	StarterParts.header(
		content,
		if separate > PACK.robux then math.floor((1 - PACK.robux / separate) * 100) else 0
	)
	local items: { Item } = {
		{
			color = CARDS.Yellow,
			title = NumberFormat.short(PACK.coins),
			detail = "monedas",
			icon = "coin",
		},
		gearItem("Rod", PACK.rod, CARDS.Blue),
		gearItem("Basket", PACK.basket, CARDS.Green),
		gearItem("Boots", PACK.boots, CARDS.Cyan),
		{
			color = CARDS.Purple,
			title = "x2 poder",
			detail = `{PACK.boostMinutes} minutos`,
			icon = "bolt",
		},
	}
	for index, item in items do
		StarterParts.card(content, index, item)
	end

	local value = Style.text(content, "Valor", 24, Color3.fromRGB(255, 200, 200), 2)
	value.RichText = true
	value.Text = `Solo el equipo, por separado: <s>{separate} R$</s>   ¡Hoy {PACK.robux} R$!`
	value.Position = UDim2.fromOffset(0, 310)
	value.Size = UDim2.new(1, 0, 0, 28)
	value.Visible = separate > PACK.robux

	local buy = Style.button(content, "Comprar", Style.PALETTE.Buy, "")
	buy.AnchorPoint = Vector2.new(0.5, 1)
	buy.Position = UDim2.new(0.5, 0, 1, -4)
	buy.Size = UDim2.new(0.56, 0, 0, 74)
	local label = buy:FindFirstChild("Texto") :: TextLabel
	label.Text = "¡LO QUIERO!"
	label.Size = UDim2.new(0.58, 0, 1, -10)
	local robux = Instance.new("ImageLabel")
	robux.BackgroundTransparency = 1
	robux.Image = Assets.UI.RobuxIcon
	robux.ScaleType = Enum.ScaleType.Fit
	robux.Position = UDim2.new(0.6, 0, 0.18, 0)
	robux.Size = UDim2.new(0.12, 0, 0.64, 0)
	robux.Parent = buy
	local price = Style.text(buy, "Precio", 40, nil, 3)
	price.Text = tostring(PACK.robux)
	price.TextXAlignment = Enum.TextXAlignment.Left
	price.Position = UDim2.new(0.74, 0, 0.12, 0)
	price.Size = UDim2.new(0.24, 0, 0.76, 0)
	local beat = Instance.new("UIScale")
	beat.Parent = buy
	TweenService:Create(beat, PULSE, { Scale = 1.06 }):Play()
	buy.Activated:Connect(function()
		Purchases.promptProduct("PackInicio")
	end)
	window.onOpen(function()
		task.spawn(function()
			price.Text = tostring(Purchases.price("PackInicio", false, PACK.robux))
		end)
	end)
	player:GetAttributeChangedSignal(Protocol.PlayerAttributes.StarterPack):Connect(function()
		if
			player:GetAttribute(Protocol.PlayerAttributes.StarterPack) == true and window.isOpen()
		then
			window.close()
		end
	end)

	task.delay(DELAY_SECONDS, function()
		if player:GetAttribute(Protocol.PlayerAttributes.StarterPack) ~= true then
			window.open()
		end
	end)
end

return StarterOffer
