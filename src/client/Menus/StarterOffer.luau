--!strict
--[[
	StarterOffer

	Oferta de bienvenida: a los `DELAY_SECONDS` de cada partida, si todavía
	no compró el pack de inicio (atributo PackInicio), se abre una ventana
	con lo que trae y el botón de compra (producto PackInicio). Una vez por
	partida; también está siempre arriba en la TIENDA hasta comprarlo.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local CardParts = require(script.Parent.Parent.Interface.CardParts)
local Icons = require(script.Parent.Parent.Interface.Icons)
local ShopParts = require(script.Parent.Parent.Interface.ShopParts)
local Style = require(script.Parent.Parent.Interface.Style)
local Purchases = require(script.Parent.Purchases)
local Window = require(script.Parent.Window)

local DELAY_SECONDS = 150
local PACK = Config.Monetization.starterPack
local CARDS = Style.PALETTE.Cards

local StarterOffer = {}

function StarterOffer.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	local window =
		Window.create(screen, "PackInicio", "¡Oferta de bienvenida!", Vector2.new(620, 460))
	local content = window.content
	local gift = Icons.view(content, "giftPink")
	gift.AnchorPoint = Vector2.new(0.5, 0)
	gift.Position = UDim2.fromScale(0.5, 0)
	gift.Size = UDim2.fromOffset(100, 100)
	local once = ShopParts.tag(content, "¡SOLO UNA VEZ!", CARDS.Red)
	local tag = once.Parent :: Frame
	tag.AnchorPoint = Vector2.new(0, 0.5)
	tag.Position = UDim2.new(0.5, 40, 0, 30)
	tag.Size = UDim2.fromOffset(170, 34)
	-- Tres tarjetas con rayos: monedas, equipo y x2 poder.
	local items = {
		{
			icon = "coin",
			color = CARDS.Yellow,
			title = NumberFormat.short(PACK.coins),
			detail = "monedas",
		},
		{
			icon = "rod",
			color = CARDS.Blue,
			title = Upgrades.list("Rod")[PACK.rod].name,
			detail = `+ {Upgrades.list("Basket")[PACK.basket].name}`,
		},
		{
			icon = "bolt",
			color = CARDS.Purple,
			title = "x2 poder",
			detail = `{PACK.boostMinutes} minutos`,
		},
	}
	for index, item in items do
		local card = CardParts.card(content, `Item{index}`, item.color, 14)
		card.Position = UDim2.new((index - 1) / 3 + 0.01, 0, 0, 108)
		card.Size = UDim2.new(1 / 3 - 0.02, 0, 0, 176)
		local icon = Icons.view(card, item.icon)
		icon.AnchorPoint = Vector2.new(0.5, 0)
		icon.Position = UDim2.fromScale(0.5, 0.05)
		icon.Size = UDim2.fromScale(0.75, 0.48)
		local square = Instance.new("UIAspectRatioConstraint")
		square.Parent = icon
		local title =
			Style.text(card, "Titulo", 26, if index == 1 then UIConfig.Colors.Coins else nil, 2.5)
		title.Text = item.title
		title.Position = UDim2.fromScale(0.04, 0.56)
		title.Size = UDim2.fromScale(0.92, 0.2)
		local detail = Style.text(card, "Detalle", 20, nil, 2)
		detail.Text = item.detail
		detail.Position = UDim2.fromScale(0.04, 0.77)
		detail.Size = UDim2.fromScale(0.92, 0.18)
	end
	local note = Style.text(content, "Nota", 20, UIConfig.Colors.Coins, 2)
	note.Text = "¡Vale mucho más que su precio!"
	note.Position = UDim2.fromOffset(0, 292)
	note.Size = UDim2.new(1, 0, 0, 24)
	local buy = Style.button(content, "Comprar", Style.PALETTE.Buy, "")
	buy.AnchorPoint = Vector2.new(0.5, 1)
	buy.Position = UDim2.fromScale(0.5, 1)
	buy.Size = UDim2.new(0.6, 0, 0, 64)
	local price = Style.robuxBadge(buy, PACK.robux)
	local label = buy:FindFirstChild("Texto") :: TextLabel
	label.Text = "¡LO QUIERO!"
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
