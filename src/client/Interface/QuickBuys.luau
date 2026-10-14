--!strict
--[[
	QuickBuys

	Atajos de Robux siempre a la vista en la columna derecha, debajo de
	Tienda y Robux: el siguiente nivel de Poder y de Monedas ("x4 Poder")
	con su precio en una insignia verde. Tocarlos abre la compra de Roblox.
	Lo que muestran sale de RobuxOffers (lo mismo que la tienda de Robux).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local HudButtons = require(script.Parent.Parent.Menus.HudButtons)
local Purchases = require(script.Parent.Parent.Menus.Purchases)
local RobuxOffers = require(script.Parent.Parent.Menus.RobuxOffers)
local Layout = require(script.Parent.Layout)
local Style = require(script.Parent.Style)

local SIZE = 84
local ICONS = { Power = "crystal", Coins = "coin" }

local QuickBuys = {}

function QuickBuys.start()
	local player = Players.LocalPlayer
	local row = Instance.new("Frame")
	row.Name = "AtajosRobux"
	row.LayoutOrder = 20
	row.BackgroundTransparency = 1
	row.Size = UDim2.fromOffset(SIZE * 2 + 24, SIZE + 16)
	row.Parent = Layout.right()
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Right
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 24)
	list.Parent = row

	local painters: { () -> () } = {}
	for index, key in Config.Monetization.levelOrder do
		local spec = RobuxOffers.level(player, key)
		local button = HudButtons.iconButton(row, key, ICONS[key] or "coin", SIZE)
		button.LayoutOrder = index
		local label = button:FindFirstChild("Nombre") :: TextLabel
		label.TextColor3 = Color3.fromRGB(255, 225, 90)
		local price = Style.robuxBadge(button)
		button.Activated:Connect(function()
			local offer = spec()
			if not offer.blocked then
				Purchases.promptProduct(offer.key)
			end
		end)
		table.insert(painters, function()
			local offer = spec()
			label.Text = (string.gsub(offer.title, "^(%S+) (x%d+)$", "%2 %1"))
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
