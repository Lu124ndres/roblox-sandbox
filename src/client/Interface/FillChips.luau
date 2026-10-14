--!strict
--[[
	FillChips

	Fila de botones de colores debajo de la barra de hambre: "+25%", "+50%" y
	"+75%" con su precio en Robux (llenan al monstruo actual para todos). Solo
	se ven mientras el monstruo está comiendo.
	Cada botón mide al menos 44 px de alto ya escalado (lo mínimo para tocarlo
	con el dedo), y el panel de hambre crece para que quepan.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Purchases = require(script.Parent.Parent.Menus.Purchases)
local HungerPanel = require(script.Parent.HungerPanel)
local Layout = require(script.Parent.Layout)
local Style = require(script.Parent.Style)

local COLORS =
	{ Color3.fromRGB(110, 220, 60), Color3.fromRGB(255, 140, 30), Color3.fromRGB(235, 50, 60) }

local ROW_TOP = HungerPanel.CHIPS_TOP -- debajo de la fila del enojo
local CHIP_HEIGHT = 38 -- alto antes de escalar...
local MIN_SCREEN_HEIGHT = 34 -- ...pero nunca menos que esto en pantalla
local CHIP_MAX_WIDTH = 92
local GAP = 18

local FillChips = {}

-- Alto de los botones (antes de escalar) para que en pantalla midan ≥ 44 px.
local function chipHeight(): number
	return math.max(CHIP_HEIGHT, math.ceil(MIN_SCREEN_HEIGHT / Layout.scale()))
end

function FillChips.mount(panel: Frame)
	local row = Instance.new("Frame")
	row.Name = "Llenar"
	row.BackgroundTransparency = 1
	row.Position = UDim2.fromOffset(0, ROW_TOP)
	row.Parent = panel
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, GAP)
	list.Parent = row
	local function resize()
		local height = chipHeight()
		row.Size = UDim2.new(1, 0, 0, height)
		panel.Size = UDim2.new(panel.Size.X, UDim.new(0, ROW_TOP + height + 4))
	end
	resize()
	Layout.onScaleChanged(resize)

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
		-- Un tercio del panel cada uno (el panel se angosta en pantallas chicas).
		button.Size = UDim2.new(1 / 3, -GAP, 1, 0)
		local limit = Instance.new("UISizeConstraint")
		limit.MaxSize = Vector2.new(CHIP_MAX_WIDTH, math.huge)
		limit.Parent = button
		local price = Style.robuxBadge(button, fill.robux)
		local badge = price.Parent :: Frame
		badge.Position = UDim2.new(1, 10, 0, 0)
		badge.Size = UDim2.fromOffset(50, 20)
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
