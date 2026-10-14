--!strict
--[[
	FillChips

	Fila de botones de colores debajo de la barra de hambre: "+25%", "+50%" y
	"+75%" con su precio en Robux (llenan al monstruo actual para todos). Solo
	se ven mientras el monstruo está comiendo.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Purchases = require(script.Parent.Parent.Menus.Purchases)
local Style = require(script.Parent.Style)

local COLORS =
	{ Color3.fromRGB(110, 220, 60), Color3.fromRGB(255, 140, 30), Color3.fromRGB(235, 50, 60) }

local FillChips = {}

function FillChips.mount(panel: Frame)
	local row = Instance.new("Frame")
	row.Name = "Llenar"
	row.BackgroundTransparency = 1
	row.Position = UDim2.fromOffset(0, 114)
	row.Size = UDim2.new(1, 0, 0, 34)
	row.Parent = panel
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 30)
	list.Parent = row

	local keys = {}
	for key in Config.Monetization.fills do
		table.insert(keys, key)
	end
	table.sort(keys, function(a: string, b: string)
		return Config.Monetization.fills[a].order < Config.Monetization.fills[b].order
	end)
	for index, key in keys do
		local fill = Config.Monetization.fills[key]
		local button = Style.button(
			row,
			key,
			COLORS[index] or COLORS[1],
			`+{math.round(fill.fraction * 100)}%`
		)
		button.LayoutOrder = index
		button.Size = UDim2.fromOffset(104, 34)
		local price = Style.robuxBadge(button, fill.robux)
		local badge = price.Parent :: Frame
		badge.Position = UDim2.new(1, 14, 0, -4)
		badge.Size = UDim2.fromOffset(54, 22)
		task.spawn(function()
			price.Text = tostring(Purchases.price(key, false, fill.robux))
		end)
		button.Activated:Connect(function()
			Purchases.promptProduct(key)
		end)
	end

	local state = ReplicatedStorage:WaitForChild(Protocol.GiantStateFolder)
	local function refresh()
		row.Visible = state:GetAttribute(Protocol.GiantAttributes.Phase) == "feeding"
	end
	state:GetAttributeChangedSignal(Protocol.GiantAttributes.Phase):Connect(refresh)
	refresh()
end

return FillChips
