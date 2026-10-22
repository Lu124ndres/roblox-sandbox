--!strict
--[[
	QuickBuys

	Atajos de Robux siempre a la vista, debajo de los botones de arriba
	(TopBar; en consola, más separados de ellos): el siguiente nivel de Poder y de Monedas ("x4 Poder") con su
	precio en una placa de piedra verde (Style.robuxBadge). Sin casilla: el
	ícono suelto, más grande que los botones de la columna, flota arriba y
	abajo con rayos que giran detrás para llamar la atención (FloatShortcut,
	pedido del usuario el 2026-10-21). Tocarlos abre la compra de Roblox.
	Lo que muestran sale de RobuxOffers (lo mismo que la tienda de Robux).
]]

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local TextCase = require(ReplicatedStorage.Shared.TextCase)
local HudButtonParts = require(script.Parent.Parent.Menus.HudButtonParts)
local Purchases = require(script.Parent.Parent.Menus.Purchases)
local RobuxOffers = require(script.Parent.Parent.Menus.RobuxOffers)
local FloatShortcut = require(script.Parent.FloatShortcut)
local Layout = require(script.Parent.Layout)
local TopBar = require(script.Parent.TopBar)

local SIZE = 100 -- cada atajo, antes de escalar (los botones de la columna miden 88)
local SIZE_TV = 130 -- en consola, más grandes (pedido del usuario el 2026-10-21)
local GAP = 16 -- entre los dos atajos (los nombres no se tocan)
local BELOW_BAR = 18 -- aire bajo los botones de arriba
local BELOW_BAR_TV = 90 -- en consola, más abajo (pedido del usuario el 2026-10-21)
local ICONS = { Power = "crystal", Coins = "coin" }

local QuickBuys = {}

function QuickBuys.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	local tv = GuiService:IsTenFootInterface()
	local size = if tv then SIZE_TV else SIZE
	local row = Instance.new("Frame")
	row.Name = "AtajosRobux"
	row.AnchorPoint = Vector2.new(1, 0)
	row.BackgroundTransparency = 1
	row.Size = UDim2.fromOffset(size * 2 + GAP, size)
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Right
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, GAP)
	list.Parent = row
	Layout.scaleWith(row)
	row.Parent = screen

	-- Pegado al borde derecho de los botones de arriba, justo debajo de ellos.
	local bar = TopBar.frame()
	local below = if tv then BELOW_BAR_TV else BELOW_BAR
	local function place()
		local origin = screen.AbsolutePosition
		local right = bar.AbsolutePosition.X + bar.AbsoluteSize.X - origin.X
		row.Position = UDim2.fromOffset(right, TopBar.bottom() - origin.Y + below)
	end
	bar:GetPropertyChangedSignal("AbsolutePosition"):Connect(place)
	bar:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
	screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
	place()
	Layout.avoid(row) -- la columna del menú empieza debajo

	local painters: { () -> () } = {}
	for index, key in Config.Monetization.levelOrder do
		local spec = RobuxOffers.level(player, key)
		local shortcut =
			FloatShortcut.new(row, `Atajo{key}`, ICONS[key] or "coin", size, (index - 1) / 2)
		shortcut.button.LayoutOrder = index
		local button, label, price = shortcut.button, shortcut.label, shortcut.price
		HudButtonParts.press(button, function()
			local offer = spec()
			if not offer.blocked then
				Purchases.promptProduct(offer.key)
			end
		end)
		table.insert(painters, function()
			local offer = spec()
			label.Text = TextCase.upper((string.gsub(offer.title, "^(%S+) (x%d+)$", "%2 %1")))
			price.Text = if offer.blocked
				then "MAX"
				else tostring(Purchases.price(offer.key, false, offer.robux))
		end)
	end
	local function paint()
		for _, painter in painters do
			task.spawn(painter)
		end
	end
	player.AttributeChanged:Connect(paint)
	paint()
end

return QuickBuys
