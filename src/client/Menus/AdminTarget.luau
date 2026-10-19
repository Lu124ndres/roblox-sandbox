--!strict
--[[
	AdminTarget

	Arriba del panel admin: a quién se le aplican las órdenes de jugador. Una
	tira con un botón por jugador del servidor (el tuyo primero, "Yo"); el
	elegido se ve verde. Debajo, sus números en vivo (poder, monedas, kills,
	renacimientos y peces en la canasta), leídos de sus atributos. Si el
	elegido se va, vuelve a ti.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Style = require(script.Parent.Parent.Interface.Style)

local ATTR = Protocol.PlayerAttributes
local CARDS = Style.PALETTE.Cards
local CHIP_HEIGHT = 38
local CHIP_WIDTH = 170
local LABEL_WIDTH = 110

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

	local strip = Instance.new("ScrollingFrame")
	strip.Name = "Jugadores"
	strip.BackgroundTransparency = 1
	strip.BorderSizePixel = 0
	strip.Position = UDim2.fromOffset(LABEL_WIDTH, 0)
	strip.Size = UDim2.new(1, -LABEL_WIDTH, 0, CHIP_HEIGHT + 8)
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
		local list = Players:GetPlayers()
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
