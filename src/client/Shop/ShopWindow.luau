--!strict
--[[
	ShopWindow

	Ventana MEJORAS (antes "tienda de la cabaña"), de madera: pestañas
	Cañas / Canastas / Botas, las monedas del jugador y la lista de niveles
	(UpgradeRow). El siguiente nivel se compra con monedas o con Robux. Solo
	dibuja; ShopController le dice qué hacer al comprar.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Style = require(script.Parent.Parent.Interface.Style)
local Window = require(script.Parent.Parent.Menus.Window)
local UpgradeRow = require(script.Parent.UpgradeRow)

local PALETTE = Style.PALETTE
local TAB_ICONS: { [string]: string } = { Rod = "rod", Basket = "basket", Boots = "boots" }
local TAB_COLORS: { [string]: Color3 } = {
	Rod = PALETTE.Cards.Orange,
	Basket = PALETTE.Cards.Green,
	Boots = PALETTE.Cards.Blue,
}

export type Shop = {
	window: Window.Window,
	refresh: () -> (),
	setTab: (category: Upgrades.Category) -> (),
}

local ShopWindow = {}

function ShopWindow.mount(
	screen: ScreenGui,
	player: Player,
	onBuy: (Upgrades.Category) -> (),
	onBuyRobux: (Upgrades.Category, level: number) -> (),
	robuxPrice: (key: string, robux: number) -> number
): Shop
	local window =
		Window.create(screen, "Mejoras", "Mejoras", Vector2.new(760, 520), PALETTE.WoodPanel)
	local content = window.content

	local tabs: { [Upgrades.Category]: TextButton } = {}
	for index, category: Upgrades.Category in Upgrades.categories do
		local tab = Style.button(
			content,
			`Pestana{category}`,
			TAB_COLORS[category],
			Upgrades.titles[category]
		)
		tab.Position = UDim2.new((index - 1) * 0.22, 0, 0, 0)
		tab.Size = UDim2.new(0.21, 0, 0, 46)
		local text = tab:FindFirstChild("Texto") :: TextLabel
		text.Position = UDim2.new(0, 44, 0, 4)
		text.Size = UDim2.new(1, -50, 1, -8)
		local icon = Icons.view(tab, TAB_ICONS[category])
		icon.Position = UDim2.fromOffset(4, 3)
		icon.Size = UDim2.fromOffset(40, 40)
		tabs[category] = tab
	end

	local wallet = Instance.new("Frame")
	wallet.BackgroundTransparency = 1
	wallet.AnchorPoint = Vector2.new(1, 0)
	wallet.Position = UDim2.new(1, -6, 0, 0)
	wallet.Size = UDim2.new(0.28, 0, 0, 46)
	wallet.Parent = content
	local coinIcon = Icons.view(wallet, "coin")
	coinIcon.Size = UDim2.fromOffset(42, 42)
	local coins = Style.text(wallet, "Monedas", 32, PALETTE.Coins, 3)
	coins.TextXAlignment = Enum.TextXAlignment.Left
	coins.Position = UDim2.fromOffset(46, 4)
	coins.Size = UDim2.new(1, -46, 1, -8)

	local list = Instance.new("ScrollingFrame")
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Position = UDim2.fromOffset(0, 58)
	list.Size = UDim2.new(1, 0, 1, -58)
	list.ScrollBarThickness = 8
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.Parent = content
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingLeft = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.Parent = list

	local current: Upgrades.Category = "Rod"

	local function refresh()
		local value = player:GetAttribute(Protocol.PlayerAttributes.Coins)
		local money = if type(value) == "number" then value else 0
		coins.Text = NumberFormat.short(money)
		for category: Upgrades.Category, tab in tabs do
			local selected = category == current
			tab.Size = UDim2.new(0.21, 0, 0, if selected then 50 else 42)
			tab.Position = UDim2.new(tab.Position.X.Scale, 0, 0, if selected then -4 else 2)
			local stroke = tab:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = if selected then Color3.new(1, 1, 1) else Style.OUTLINE
			end
		end
		for _, child in list:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		local owned = Upgrades.level(player, current)
		local prices = Config.Monetization.upgradeRobux[current]
		for index, def in Upgrades.list(current) do
			local robux = prices and prices[index]
			UpgradeRow.new(list, {
				category = current,
				index = index,
				def = def,
				owned = owned,
				coins = money,
				robux = if robux and robux > 0 then robux else nil,
				robuxPrice = robuxPrice,
				onCoins = function()
					onBuy(current)
				end,
				onRobux = function()
					onBuyRobux(current, index)
				end,
			})
		end
	end

	local function setTab(category: Upgrades.Category)
		current = category
		refresh()
	end
	for category: Upgrades.Category, tab in tabs do
		tab.Activated:Connect(function()
			setTab(category)
		end)
	end
	window.onOpen(refresh)

	return { window = window, refresh = refresh, setTab = setTab }
end

return ShopWindow
