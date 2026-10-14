--!strict
--[[
	RestChips

	Durante el descanso, donde están los atajos de llenar la barra (que solo
	se ven mientras come), aparecen:
		- un botón por monstruo con su ícono y su precio en Robux: comprarlo
		  hace que salga ese al terminar el descanso (producto Choose<id>);
		  el que ya está elegido se marca en dorado;
		- el botón grande "IR A LA GUARIDA" (x2 poder): lleva directo a la
		  plataforma del lago (RestEnter). Se esconde si ya estás en ella.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local Purchases = require(script.Parent.Parent.Menus.Purchases)
local GiantPortrait = require(script.Parent.Parent.Giant.GiantPortrait)
local HungerPanel = require(script.Parent.HungerPanel)
local Icons = require(script.Parent.Icons)
local Style = require(script.Parent.Style)

local CHIP_HEIGHT, CHIP_WIDTH, GAP = 52, 70, 12
local BUTTON_HEIGHT = 42
local CARDS = Style.PALETTE.Cards

local RestChips = {}

function RestChips.mount(panel: Frame)
	local player = Players.LocalPlayer
	local remotes = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
	local enter = remotes:WaitForChild(Protocol.Remotes.RestEnter) :: RemoteEvent
	local state = ReplicatedStorage:WaitForChild(Protocol.GiantStateFolder)
	local boosts = ReplicatedStorage:WaitForChild(Protocol.BoostFolder)

	local row = Instance.new("Frame")
	row.Name = "ElegirMonstruo"
	row.BackgroundTransparency = 1
	row.Position = UDim2.fromOffset(0, HungerPanel.CHIPS_TOP + 6)
	row.Size = UDim2.new(1, 0, 0, CHIP_HEIGHT)
	row.Visible = false
	row.Parent = panel
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.Padding = UDim.new(0, GAP)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = row

	local chips: { [string]: TextButton } = {}
	for index, def in Config.Giants.chain do
		if not def.inRoulette then
			continue
		end
		local key = `Choose{def.id}`
		local robux = Config.Monetization.chooseGiant[def.id] or 0
		local chip = Style.button(row, key, CARDS.Purple, "")
		chip.LayoutOrder = index
		chip.Size = UDim2.fromOffset(CHIP_WIDTH, CHIP_HEIGHT)
		local icon = Icons.view(chip, GiantPortrait.iconFor(def.id))
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Position = UDim2.fromScale(0.5, 0.5)
		icon.Size = UDim2.fromScale(1.05, 1.05)
		local price = Style.robuxBadge(chip, robux)
		local badge = price.Parent :: Frame
		badge.Position = UDim2.new(1, 10, 0, 0)
		badge.Size = UDim2.fromOffset(52, 20)
		task.spawn(function()
			price.Text = tostring(Purchases.price(key, false, robux))
		end)
		chip.Activated:Connect(function()
			Purchases.promptProduct(key)
		end)
		chips[def.id] = chip
	end

	local go = Style.button(panel, "IrGuarida", Style.PALETTE.Buy, "IR A LA GUARIDA (x2)")
	go.AnchorPoint = Vector2.new(0.5, 0)
	go.Position = UDim2.new(0.5, 0, 0, HungerPanel.CHIPS_TOP + CHIP_HEIGHT + 14)
	go.Size = UDim2.fromOffset(260, BUTTON_HEIGHT)
	go.Visible = false
	go.Activated:Connect(function()
		enter:FireServer()
	end)

	local function onArena(): boolean
		local character = player.Character
		return character ~= nil and WorldZones.isInRestArena(character:GetPivot().Position)
	end

	local function refresh()
		local resting = state:GetAttribute(Protocol.GiantAttributes.Phase) == "rest"
		row.Visible = resting
		go.Visible = resting and not onArena()
		local chosen = boosts:GetAttribute(Protocol.BoostAttributes.NextGiant)
		for id, chip in chips do
			local stroke = chip:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = if id == chosen then Color3.fromRGB(255, 220, 70) else Style.OUTLINE
			end
		end
	end
	state:GetAttributeChangedSignal(Protocol.GiantAttributes.Phase):Connect(refresh)
	boosts:GetAttributeChangedSignal(Protocol.BoostAttributes.NextGiant):Connect(refresh)
	task.spawn(function()
		while true do
			task.wait(0.5)
			if row.Visible then
				refresh()
			end
		end
	end)
	refresh()
end

return RestChips
