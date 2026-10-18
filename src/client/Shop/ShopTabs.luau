--!strict
--[[
	ShopTabs

	Pestañas de MEJORAS (Cañas / Canastas / Botas): botones de piedra teñidos
	de su color, con el ícono del nivel que tienes y "Nv 3/20". La elegida
	sube un poco, brilla en su color y lleva canto blanco y título dorado; las
	otras quedan en piedra más oscura.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local GearIcons = require(script.Parent.Parent.Interface.GearIcons)
local Kit = require(script.Parent.Parent.Interface.Kit)
local Style = require(script.Parent.Parent.Interface.Style)

local PALETTE = Style.PALETTE
local TAB_COLORS: { [string]: Color3 } = {
	Rod = PALETTE.Cards.Orange,
	Basket = PALETTE.Cards.Green,
	Boots = PALETTE.Cards.Blue,
}

local DIM = 0.4 -- cuánto se oscurece la piedra de las pestañas no elegidas
local STONE_CORNER = 10

type Tab = {
	button: TextButton,
	icon: ImageLabel,
	level: TextLabel,
	title: TextLabel,
	edge: UIStroke,
}

export type Tabs = {
	paint: (player: Player, current: Upgrades.Category) -> (),
	onPick: (callback: (Upgrades.Category) -> ()) -> (),
}

local ShopTabs = {}

local function tabButton(
	content: Frame,
	category: Upgrades.Category,
	index: number,
	TOP: number
): Tab
	local button = Style.button(content, `Pestana{category}`, TAB_COLORS[category], "")
	button.Position = UDim2.new((index - 1) * 0.215, 0, 0, 0)
	button.Size = UDim2.new(0.205, 0, 0, TOP - 6)
	local icon = GearIcons.view(button, category, 1)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Position = UDim2.new(0, 4, 0.5, 0)
	icon.Size = UDim2.fromOffset(TOP - 4, TOP - 4)
	local title = button:FindFirstChild("Texto") :: TextLabel
	title.Text = Upgrades.titles[category]
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Position = UDim2.new(0, TOP, 0, 5)
	title.Size = UDim2.new(1, -TOP - 8, 0.52, 0)
	Kit.gold(title)
	local level = Style.text(button, "Nivel", 18, Color3.fromRGB(255, 240, 210), 2)
	level.TextXAlignment = Enum.TextXAlignment.Left
	level.Position = UDim2.new(0, TOP, 0.56, 0)
	level.Size = UDim2.new(1, -TOP - 8, 0.34, 0)
	-- Canto blanco de la elegida, siguiendo la esquina redonda de la piedra.
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, STONE_CORNER)
	corner.Parent = button
	local edge = Instance.new("UIStroke")
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Color = Color3.new(1, 1, 1)
	edge.Thickness = 3
	edge.Parent = button
	return { button = button, icon = icon, level = level, title = title, edge = edge }
end

function ShopTabs.build(content: Frame, top: number): Tabs
	local tabs: { [Upgrades.Category]: Tab } = {}
	for index, category: Upgrades.Category in Upgrades.categories do
		tabs[category] = tabButton(content, category, index, top)
	end
	local function paint(player: Player, current: Upgrades.Category)
		for category: Upgrades.Category, tab in tabs do
			local on = category == current
			local level = Upgrades.level(player, category)
			GearIcons.paint(tab.icon, category, level)
			tab.level.Text = `Nv {level}/{#Upgrades.list(category)}`
			tab.button.Position = UDim2.new(tab.button.Position.X.Scale, 0, 0, if on then -4 else 2)
			-- Style.button tiñe la piedra al cambiar BackgroundColor3.
			local color = TAB_COLORS[category]
			tab.button.BackgroundColor3 = if on then color else color:Lerp(Color3.new(0, 0, 0), DIM)
			tab.edge.Enabled = on
			local gold = tab.title:FindFirstChildOfClass("UIGradient")
			if gold then
				gold.Enabled = on -- las no elegidas, título blanco
			end
		end
	end
	local function onPick(callback: (Upgrades.Category) -> ())
		for category: Upgrades.Category, tab in tabs do
			tab.button.Activated:Connect(function()
				callback(category)
			end)
		end
	end
	return { paint = paint, onPick = onPick }
end

return ShopTabs
