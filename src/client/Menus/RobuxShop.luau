--!strict
--[[
	RobuxShop

	La TIENDA (botón del HUD con el cofre): todo lo de Robux, estilo simulador.
		Banner         entrenamiento para todo el servidor (x2 → x4, tiempo)
		Personajes     los trajes de pase en tarjetas anchas (OutfitCard)
		Para siempre   Poder y Monedas (x2, x4, x8...) y VIP
		Monstruo       llenarlo 25/50/75 % (para todos)
		Siguiente      elegir el monstruo que sale después del descanso
		Estanques      abrirlos para siempre
	Pack de inicio y estanque sagrado en "Para siempre"; los demás
	estanques solo si sellPonds. Se repintan cada segundo; Poder, Monedas,
	VIP y estanques se pueden regalar (botón rosa).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local GiantPool = require(ReplicatedStorage.Shared.GiantPool)
local Style = require(script.Parent.Parent.Interface.Style)
local ShopParts = require(script.Parent.Parent.Interface.ShopParts)
local BoostBanner = require(script.Parent.BoostBanner)
local GiftPicker = require(script.Parent.GiftPicker)
local HudButtons = require(script.Parent.HudButtons)
local OfferCard = require(script.Parent.OfferCard)
local OutfitCard = require(script.Parent.OutfitCard)
local Purchases = require(script.Parent.Purchases)
local RobuxOffers = require(script.Parent.RobuxOffers)
local GiantPortrait = require(script.Parent.Parent.Giant.GiantPortrait)
local RouletteParts = require(script.Parent.Parent.Giant.RouletteParts)
local Window = require(script.Parent.Window)

type Offer = RobuxOffers.Offer
local CARDS = Style.PALETTE.Cards
local MONETIZATION = Config.Monetization
local CARD_HEIGHT = 268 -- OfferCard: chip, nombre, descripción y botones
local TWO_COLUMNS_BELOW = 540 -- ancho del contenido (antes de escalar) para pasar a 2 columnas
local THREE_COLUMNS = UDim2.new(1 / 3, -10, 0, CARD_HEIGHT)
local TWO_COLUMNS = UDim2.new(0.5, -6, 0, CARD_HEIGHT)
local GIANT_COLORS = RouletteParts.COLORS -- mismos colores que en la ruleta

local RobuxShop = {}

-- ¿Hay al menos dos monstruos que pueden salir? Si no, elegir no sirve de nada.
local function rouletteHasChoice(): boolean
	local count = 0
	for _, def in Config.Giants.chain do
		if GiantPool.listed(def) then
			count += 1
		end
	end
	return count >= 2
end

local function grid(parent: Instance, order: number): (Frame, UIGridLayout)
	local frame = Instance.new("Frame")
	frame.Name = "Tarjetas"
	frame.LayoutOrder = order
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(1, -12, 0, 0)
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.Parent = parent
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = THREE_COLUMNS
	layout.CellPadding = UDim2.fromOffset(12, 12)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = frame
	return frame, layout
end

function RobuxShop.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	local window = Window.create(screen, "TiendaRobux", "Tienda", Vector2.new(1000, 580))
	HudButtons.side("Tienda", "chest", window.toggle)
	local picker = GiftPicker.mount(screen)
	local list = ShopParts.scroller(window.content)
	local painters: { () -> () } = {}
	local order = 0
	local cards: Frame = list :: any
	local grids: { UIGridLayout } = {}

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
		local frame, layout = grid(list, order)
		cards = frame
		table.insert(grids, layout)
	end
	local function add(color: Color3, icon: string, spec: () -> Offer)
		order += 1
		table.insert(painters, OfferCard.new(cards, order, color, icon, spec, actions))
	end

	order += 1
	table.insert(painters, BoostBanner.new(list, order, buy, Purchases.price))

	order += 1
	ShopParts.section(list, order, "Personajes")
	order += 1
	table.insert(
		painters,
		OutfitCard.mount(list, order, actions, function()
			return window.scale.Scale
		end)
	)

	section("Para siempre")
	add(CARDS.Pink, "giftPink", RobuxOffers.starter(player))
	add(CARDS.Blue, "crystal", RobuxOffers.level(player, "Power"))
	add(CARDS.Yellow, "coin", RobuxOffers.level(player, "Coins"))
	add(CARDS.Cyan, "pond", RobuxOffers.pond(player, #Config.Progression.ponds)) -- sagrado
	for _, key in MONETIZATION.passOrder do
		if not MONETIZATION.passes[key].outfit then -- los trajes van en Personajes
			add(CARDS.Purple, "crown", RobuxOffers.pass(player, key))
		end
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

	if rouletteHasChoice() then
		section("Elige el siguiente monstruo")
		for _, def in Config.Giants.chain do
			if GiantPool.listed(def) then -- los no lanzados no se venden
				add(
					GIANT_COLORS[def.id] or CARDS.Red,
					GiantPortrait.iconFor(def.id),
					RobuxOffers.choose(def)
				)
			end
		end
	end

	for index = 2, if MONETIZATION.sellPonds then #Config.Progression.ponds - 1 else 1 do
		if index == 2 then
			section("Estanques")
		end
		add(CARDS.Green, "pond", RobuxOffers.pond(player, index))
	end

	-- AbsoluteSize ya viene escalado: se divide entre la escala de la ventana.
	local function columns()
		local scale = window.scale.Scale
		if scale <= 0 then
			return
		end
		local width = list.AbsoluteSize.X / scale
		local cell = if width < TWO_COLUMNS_BELOW then TWO_COLUMNS else THREE_COLUMNS
		for _, layout in grids do
			layout.CellSize = cell
		end
	end
	list:GetPropertyChangedSignal("AbsoluteSize"):Connect(columns)
	columns()

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
