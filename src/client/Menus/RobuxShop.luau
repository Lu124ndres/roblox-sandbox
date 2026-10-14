--!strict
--[[
	RobuxShop

	La TIENDA (botón del HUD con el cofre): todo lo de Robux, estilo
	simulador.
		Banner         entrenamiento para todo el servidor (x2 → x4, tiempo)
		Para siempre   Poder y Monedas (x2, x4, x8...) y VIP
		Monstruo       llenarlo 25/50/75 % (para todos)
		Siguiente      elegir el monstruo que sale después del descanso
		Estanques      abrirlos para siempre
	Las tarjetas se repintan cada segundo con lo que toca comprar ahora. Las
	de Poder, Monedas, VIP y estanques se pueden regalar (botón rosa).
	Las compras las abre Purchases y las entrega el servidor.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Style = require(script.Parent.Parent.Interface.Style)
local ShopParts = require(script.Parent.Parent.Interface.ShopParts)
local BoostBanner = require(script.Parent.BoostBanner)
local GiftPicker = require(script.Parent.GiftPicker)
local HudButtons = require(script.Parent.HudButtons)
local OfferCard = require(script.Parent.OfferCard)
local Purchases = require(script.Parent.Purchases)
local RobuxOffers = require(script.Parent.RobuxOffers)
local Window = require(script.Parent.Window)

type Offer = RobuxOffers.Offer

local CARDS = Style.PALETTE.Cards
local MONETIZATION = Config.Monetization
local CARD_HEIGHT = 236
local GIANT_COLORS: { [string]: Color3 } = {
	Orca = CARDS.Blue,
	Minotauro = CARDS.Red,
	DragonMarino = CARDS.Purple,
	ZorroDeAgua = CARDS.Cyan,
}

local RobuxShop = {}

local function scroller(parent: Instance): ScrollingFrame
	local list = Instance.new("ScrollingFrame")
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Size = UDim2.fromScale(1, 1)
	list.ScrollBarThickness = 8
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.Parent = parent
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.Parent = list
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingLeft = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.Parent = list
	return list
end

local function grid(parent: Instance, order: number): Frame
	local frame = Instance.new("Frame")
	frame.Name = "Tarjetas"
	frame.LayoutOrder = order
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(1, -12, 0, 0)
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.Parent = parent
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.new(1 / 3, -10, 0, CARD_HEIGHT)
	layout.CellPadding = UDim2.fromOffset(12, 12)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = frame
	return frame
end

function RobuxShop.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	local window = Window.create(screen, "TiendaRobux", "Tienda", Vector2.new(760, 520))
	HudButtons.side("Tienda", "chest", window.toggle)
	local picker = GiftPicker.mount(screen)
	local list = scroller(window.content)
	local painters: { () -> () } = {}
	local order = 0
	local cards: Frame = list :: any

	local function buy(offer: Offer)
		if offer.isPass then
			Purchases.promptPass(offer.key)
		else
			Purchases.promptProduct(offer.key)
		end
	end
	local actions: OfferCard.Actions = { buy = buy, gift = picker.open, price = Purchases.price }

	local function section(text: string)
		order += 1
		ShopParts.section(list, order, text)
		order += 1
		cards = grid(list, order)
	end
	local function add(color: Color3, icon: string, spec: () -> Offer)
		order += 1
		table.insert(painters, OfferCard.new(cards, order, color, icon, spec, actions))
	end

	order += 1
	table.insert(painters, BoostBanner.new(list, order, buy, Purchases.price))

	section("Para siempre")
	add(CARDS.Blue, "crystal", RobuxOffers.level(player, "Power"))
	add(CARDS.Yellow, "coin", RobuxOffers.level(player, "Coins"))
	for _, key in MONETIZATION.passOrder do
		add(CARDS.Purple, "crown", RobuxOffers.pass(player, key))
	end

	section("Llenar al monstruo")
	local fillKeys = {}
	for key in MONETIZATION.fills do
		table.insert(fillKeys, key)
	end
	table.sort(fillKeys, function(a: string, b: string)
		return MONETIZATION.fills[a].order < MONETIZATION.fills[b].order
	end)
	for _, key in fillKeys do
		add(CARDS.Orange, "meat", RobuxOffers.fill(key))
	end

	section("Elige el siguiente monstruo")
	for _, def in Config.Giants.chain do
		add(
			GIANT_COLORS[def.id] or CARDS.Red,
			RobuxOffers.GIANT_ICONS[def.id] or "fang",
			RobuxOffers.choose(def)
		)
	end

	section("Estanques")
	for index = 2, #Config.Progression.ponds do
		add(CARDS.Green, "pond", RobuxOffers.pond(player, index))
	end

	local function paintAll()
		for _, paint in painters do
			task.spawn(paint) -- el precio real puede tardar (GetProductInfo)
		end
	end
	window.onOpen(paintAll)
	task.spawn(function()
		while true do
			task.wait(1)
			if window.isOpen() then
				paintAll()
			end
		end
	end)
end

return RobuxShop
