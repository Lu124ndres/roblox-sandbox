--!strict
--[[
	AdminTarget

	Arriba del panel admin: a quién se le aplican las órdenes de jugador. Una
	casilla para buscar por nombre y una tira con un botón por jugador del
	servidor que coincida (el tuyo primero, "Yo", siempre); el elegido se ve verde. Debajo, sus números en vivo (poder, monedas, kills,
	renacimientos y peces en la canasta), leídos de sus atributos. Si el
	elegido se va, vuelve a ti.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Style = require(script.Parent.Parent.Interface.Style)

local ATTR = Protocol.PlayerAttributes
local CARDS = Style.PALETTE.Cards
local CHIP_HEIGHT = 38
local CHIP_WIDTH = 170
local LABEL_WIDTH = 110
local SEARCH_WIDTH = 190

export type Target = {
	height: number,
	get: () -> Player,
}

local AdminTarget = {}

local function stat(player: Player, attribute: string): string
	local value = player:GetAttribute(attribute)
	return if type(value) == "number" then NumberFormat.short(value) else "-"
end

function AdminTarget.mount(parent: Instance): Target
	local me = Players.LocalPlayer
	local selected = me

	local title = Style.text(parent, "Objetivo", 22, nil, 2)
	title.Text = "Jugador:"
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Size = UDim2.fromOffset(LABEL_WIDTH, CHIP_HEIGHT)

	local search = Instance.new("TextBox")
	search.Name = "Buscar"
	search.PlaceholderText = "Buscar jugador"
	search.Text = ""
	search.ClearTextOnFocus = false
	search.TextScaled = true
	search.FontFace = UIConfig.Fonts.Title
	search.BackgroundColor3 = Color3.fromRGB(245, 245, 250)
	search.TextColor3 = Color3.fromRGB(20, 20, 30)
	search.PlaceholderColor3 = Color3.fromRGB(150, 150, 165)
	search.Position = UDim2.fromOffset(LABEL_WIDTH, 0)
	search.Size = UDim2.fromOffset(SEARCH_WIDTH - 10, CHIP_HEIGHT)
	local searchLimit = Instance.new("UITextSizeConstraint")
	searchLimit.MaxTextSize = 22
	searchLimit.Parent = search
	local searchPad = Instance.new("UIPadding")
	searchPad.PaddingLeft, searchPad.PaddingRight = UDim.new(0, 8), UDim.new(0, 8)
	searchPad.PaddingTop, searchPad.PaddingBottom = UDim.new(0, 6), UDim.new(0, 6)
	searchPad.Parent = search
	local searchCorner = Instance.new("UICorner")
	searchCorner.CornerRadius = UDim.new(0, 10)
	searchCorner.Parent = search
	Style.border(search, 2)
	search.Parent = parent

	local strip = Instance.new("ScrollingFrame")
	strip.Name = "Jugadores"
	strip.BackgroundTransparency = 1
	strip.BorderSizePixel = 0
	strip.Position = UDim2.fromOffset(LABEL_WIDTH + SEARCH_WIDTH, 0)
	strip.Size = UDim2.new(1, -(LABEL_WIDTH + SEARCH_WIDTH), 0, CHIP_HEIGHT + 8)
	strip.ScrollingDirection = Enum.ScrollingDirection.X
	strip.AutomaticCanvasSize = Enum.AutomaticSize.X
	strip.CanvasSize = UDim2.new()
	strip.ScrollBarThickness = 4
	strip.Parent = parent
	local flow = Instance.new("UIListLayout")
	flow.FillDirection = Enum.FillDirection.Horizontal
	flow.Padding = UDim.new(0, 8)
	flow.SortOrder = Enum.SortOrder.LayoutOrder
	flow.Parent = strip

	local info = Style.text(parent, "Numeros", 20, nil, 2)
	info.TextXAlignment = Enum.TextXAlignment.Left
	info.Position = UDim2.fromOffset(0, CHIP_HEIGHT + 12)
	info.Size = UDim2.new(1, 0, 0, 26)

	local function refreshInfo()
		info.Text =
			`{selected.DisplayName}  ·  Poder {stat(selected, ATTR.Power)}  ·  Monedas {stat(
				selected,
				ATTR.Coins
			)}  ·  Kills {stat(selected, ATTR.Kills)}  ·  Renac. {stat(selected, ATTR.Rebirths)}  ·  Peces {stat(
				selected,
				ATTR.CarriedFish
			)}`
	end

	local watching: RBXScriptConnection? = nil
	local rebuild: () -> ()
	local function choose(player: Player)
		selected = player
		if watching then
			watching:Disconnect()
		end
		watching = player.AttributeChanged:Connect(refreshInfo)
		refreshInfo()
		rebuild()
	end

	rebuild = function()
		for _, child in strip:GetChildren() do
			if child:IsA("GuiButton") then
				child:Destroy()
			end
		end
		local query = string.lower(search.Text)
		local list = {}
		for _, player in Players:GetPlayers() do
			local matches = string.find(string.lower(player.Name), query, 1, true)
				or string.find(string.lower(player.DisplayName), query, 1, true)
			if player == me or player == selected or matches then
				table.insert(list, player)
			end
		end
		table.sort(list, function(a, b)
			if a == me or b == me then
				return a == me
			end
			return a.DisplayName:lower() < b.DisplayName:lower()
		end)
		for index, player in list do
			local text = if player == me then "Yo" else player.DisplayName
			local color = if player == selected then CARDS.Green else CARDS.Blue
			local chip = Style.button(strip, player.Name, color, text)
			chip.LayoutOrder = index
			chip.Size = UDim2.fromOffset(CHIP_WIDTH, CHIP_HEIGHT)
			chip.Activated:Connect(function()
				choose(player)
			end)
		end
	end

	search:GetPropertyChangedSignal("Text"):Connect(function()
		rebuild()
	end)
	Players.PlayerAdded:Connect(rebuild)
	Players.PlayerRemoving:Connect(function(player)
		if player == selected then
			task.defer(choose, me)
		else
			task.defer(rebuild)
		end
	end)
	choose(me)

	return {
		height = CHIP_HEIGHT + 44,
		get = function()
			return selected
		end,
	}
end

return table.freeze(AdminTarget)
