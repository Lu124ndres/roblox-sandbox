--!strict
--[[
	Overhead

	Lo que se ve sobre la cabeza de cada jugador (para todos):
		colmillo de monstruo con sus kills al lado (monstruos llenados) y "VIP" si lo tiene
		su título, según su poder (Config.Social.titles), con un degradado por rango
		su nombre
	Reemplaza el nombre de Roblox (se oculta en este cliente). Lee atributos
	que pone el servidor (Power, Kills, Pase_VIP). Solo reescribe el título
	y las kills cuando cambian de verdad (Power cambia a cada rato). Con
	efectos reducidos se quitan los contornos UIStroke y se ve de más cerca.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Perks = require(ReplicatedStorage.Shared.Perks)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)
local Icons = require(script.Parent.Icons)
local OverheadLook = require(script.Parent.OverheadLook)
local Style = require(script.Parent.Style)

local ATTR = Protocol.PlayerAttributes
local TITLES = Config.Social.titles
local TAG_NAME = "Encima"

local Overhead = {}

local guis: { [Player]: BillboardGui } = {}
local connections: { [Player]: { RBXScriptConnection } } = {}

local function build(player: Player, head: BasePart): () -> ()
	local gui = Instance.new("BillboardGui")
	gui.Name = TAG_NAME
	-- Medido en studs: se ve del tamaño del mundo, como un cartel sobre la cabeza.
	gui.Size = UDim2.fromScale(7, 2.7)
	gui.StudsOffset = Vector3.new(0, 2.9, 0)
	gui.LightInfluence = 0
	gui.ResetOnSpawn = false

	local top = Instance.new("Frame")
	top.BackgroundTransparency = 1
	top.Size = UDim2.fromScale(1, 0.38)
	top.Parent = gui
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0, 6)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = top
	local fang = Icons.view(top, "fang")
	fang.Size = UDim2.fromScale(0.16, 1)
	local square = Instance.new("UIAspectRatioConstraint")
	square.Parent = fang
	local kills = Style.text(top, "Kills", 80, Color3.fromRGB(255, 236, 200), 2.5)
	kills.TextXAlignment = Enum.TextXAlignment.Left
	kills.Size = UDim2.fromScale(0.2, 0.75)
	kills.LayoutOrder = 1
	local vip = Style.text(top, "VIP", 80, UIConfig.Colors.Coins, 2.5)
	vip.Text = "VIP"
	vip.Size = UDim2.fromScale(0.18, 0.7)
	vip.LayoutOrder = 2

	local title = Style.text(gui, "Titulo", 90, nil, 3)
	title.Position = UDim2.fromScale(0, 0.4)
	title.Size = UDim2.fromScale(1, 0.32)
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Parent = title
	local name = Style.text(gui, "Nombre", 70, nil, 2.5)
	name.Position = UDim2.fromScale(0, 0.73)
	name.Size = UDim2.fromScale(1, 0.25)
	name.Text = player.DisplayName

	gui.Adornee = head
	OverheadLook.applyQuality(gui)
	gui.Parent = head
	guis[player] = gui

	local shownIndex, shownKills = 0, -1
	return function()
		local power = player:GetAttribute(ATTR.Power)
		local index = OverheadLook.titleIndex(if type(power) == "number" then power else 0)
		if index ~= shownIndex then
			shownIndex = index
			title.Text = string.upper(TITLES[index].name)
			gradient.Color, gradient.Rotation = OverheadLook.gradient(index)
		end
		local value = player:GetAttribute(ATTR.Kills)
		local killCount = if type(value) == "number" then value else 0
		if killCount ~= shownKills then
			shownKills = killCount
			kills.Text = NumberFormat.short(killCount)
		end
		vip.Visible = Perks.hasPass(player, "VIP")
	end
end

local function watch(player: Player)
	local refresh: (() -> ())? = nil
	local function onCharacter(character: Model)
		local head = character:WaitForChild("Head", 10)
		local humanoid = character:WaitForChild("Humanoid", 10)
		if humanoid and humanoid:IsA("Humanoid") then
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
		if head and head:IsA("BasePart") then
			local update = build(player, head)
			refresh = update
			update()
		end
	end
	local list = { player.CharacterAdded:Connect(onCharacter) }
	connections[player] = list
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
	table.insert(
		list,
		player.AttributeChanged:Connect(function(attribute: string)
			if
				refresh
				and (
					attribute == ATTR.Power
					or attribute == ATTR.Kills
					or string.find(attribute, ATTR.PassPrefix, 1, true) == 1
				)
			then
				refresh()
			end
		end)
	)
end

function Overhead.start()
	Players.PlayerAdded:Connect(watch)
	Players.PlayerRemoving:Connect(function(player: Player)
		local list = connections[player]
		connections[player] = nil
		if list then
			for _, connection in list do
				connection:Disconnect()
			end
		end
		guis[player] = nil
	end)
	ClientSettings.onChanged(function(key: string)
		if key == "lowFx" then
			for _, gui in guis do
				OverheadLook.applyQuality(gui)
			end
		end
	end)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
end

return Overhead
