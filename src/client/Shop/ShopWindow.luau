--!strict
--[[
	ShopWindow

	Ventana MEJORAS: arriba las pestañas Cañas / Canastas / Botas (con el
	ícono de lo que tienes y "Nv 3/20") y tus monedas. A la izquierda el
	panel grande del nivel elegido (UpgradeDetail) con los botones de compra;
	a la derecha la cuadrícula de todos los niveles (UpgradeCard). Al abrir
	queda elegido el siguiente por comprar. Solo dibuja; ShopController le
	dice qué hacer al comprar.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local Icons = require(script.Parent.Parent.Interface.Icons)
local ShopParts = require(script.Parent.Parent.Interface.ShopParts)
local Style = require(script.Parent.Parent.Interface.Style)
local Window = require(script.Parent.Parent.Menus.Window)
local WindowLayout = require(script.Parent.Parent.Menus.WindowLayout)
local ShopTabs = require(script.Parent.ShopTabs)
local UpgradeCard = require(script.Parent.UpgradeCard)
local UpgradeDetail = require(script.Parent.UpgradeDetail)

local PALETTE = Style.PALETTE
local TOP = 58 -- alto de la fila de pestañas
local CELL = Vector2.new(124, 150)
local GAP = 10

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
	-- En táctil, ancha y baja: se ve más grande y la cuadrícula gana una columna.
	local size = WindowLayout.size(Vector2.new(920, 580), Vector2.new(1100, 480))
	local window = Window.create(screen, "Mejoras", "Mejoras", size, PALETTE.WoodPanel)
	local content = window.content
	local current: Upgrades.Category = "Rod"
	local selected = 2
	local lastOwned = 0

	local tabs = ShopTabs.build(content, TOP)

	local wallet = Instance.new("Frame")
	wallet.BackgroundTransparency = 1
	wallet.AnchorPoint = Vector2.new(1, 0)
	wallet.Position = UDim2.new(1, -6, 0, 4)
	wallet.Size = UDim2.new(0.33, 0, 0, TOP - 14)
	wallet.Parent = content
	local coinIcon = Icons.view(wallet, "coin")
	coinIcon.AnchorPoint = Vector2.new(1, 0.5)
	coinIcon.Position = UDim2.fromScale(1, 0.5)
	coinIcon.Size = UDim2.fromOffset(44, 44)
	local coins = Style.text(wallet, "Monedas", 34, PALETTE.Coins, 3)
	coins.TextXAlignment = Enum.TextXAlignment.Right
	coins.Size = UDim2.new(1, -50, 1, 0)

	local body = Instance.new("Frame")
	body.BackgroundTransparency = 1
	body.Position = UDim2.fromOffset(0, TOP + 6)
	body.Size = UDim2.new(1, 0, 1, -TOP - 6)
	body.Parent = content
	local detail = UpgradeDetail.mount(body, function()
		onBuy(current)
	end, function()
		onBuyRobux(current, selected)
	end)
	local grid = ShopParts.scroller(body)
	grid.AnchorPoint = Vector2.new(1, 0)
	grid.Position = UDim2.fromScale(1, 0)
	grid.Size = UDim2.fromScale(0.63, 1)
	for _, child in grid:GetChildren() do
		if child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromOffset(CELL.X, CELL.Y)
	layout.CellPadding = UDim2.fromOffset(GAP, GAP)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid
	local padding = grid:FindFirstChildOfClass("UIPadding") or Instance.new("UIPadding")
	padding.PaddingTop, padding.PaddingLeft = UDim.new(0, 8), UDim.new(0, 8)
	padding.Parent = grid

	local cards: { UpgradeCard.Card } = {}
	local refresh: () -> ()

	local function money(): number
		local value = player:GetAttribute(Protocol.PlayerAttributes.Coins)
		return if type(value) == "number" then value else 0
	end

	local function showDetail()
		local list = Upgrades.list(current)
		local owned = Upgrades.level(player, current)
		local prices = Config.Monetization.upgradeRobux[current]
		local robux = prices and prices[selected]
		detail.update({
			category = current,
			level = selected,
			def = list[selected],
			currentDef = list[owned],
			owned = owned,
			count = #list,
			coins = money(),
			robux = if robux and robux > 0 then robuxPrice(`{current}{selected}`, robux) else nil,
		})
		for level, card in cards do
			card.setSelected(level == selected)
		end
	end

	refresh = function()
		coins.Text = NumberFormat.short(money())
		tabs.paint(player, current)
		local list = Upgrades.list(current)
		local owned = Upgrades.level(player, current)
		if owned ~= lastOwned then -- recién abierta o compró: elige el siguiente
			lastOwned = owned
			selected = math.min(owned + 1, #list)
		end
		for _, card in cards do
			card.button:Destroy()
		end
		table.clear(cards)
		for level, def in list do
			cards[level] = UpgradeCard.new(grid, {
				category = current,
				level = level,
				price = def.price,
				owned = owned,
				onSelect = function()
					selected = level
					showDetail()
				end,
			})
		end
		showDetail()
	end

	local function setTab(category: Upgrades.Category)
		current, lastOwned = category, 0
		refresh()
		local row = (selected - 1) // math.max(layout.AbsoluteCellCount.X, 1)
		grid.CanvasPosition = Vector2.new(0, math.max(row - 1, 0) * (CELL.Y + GAP))
	end
	tabs.onPick(setTab)
	window.onOpen(function()
		setTab(current)
	end)

	return { window = window, refresh = refresh, setTab = setTab }
end

return ShopWindow
