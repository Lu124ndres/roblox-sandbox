--!strict
--[[
	Overhead

	Lo que se ve sobre la cabeza de cada jugador (para todos):
		colmillo de monstruo con sus kills al lado (monstruos llenados) y "VIP" si lo tiene
		su título, según su poder (Config.Social.titles), con un degradado por rango
		su nombre
	Reemplaza el nombre de Roblox (se oculta en este cliente). Lee atributos
	que pone el servidor (Power, Kills, Pase_VIP).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Perks = require(ReplicatedStorage.Shared.Perks)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Icons = require(script.Parent.Icons)
local Style = require(script.Parent.Style)

local ATTR = Protocol.PlayerAttributes
local TITLES = Config.Social.titles
local TAG_NAME = "Encima"
local rgb = Color3.fromRGB

-- Degradado del texto de cada título (mismo orden que Config.Social.titles).
local TITLE_COLORS: { { Color3 } } = {
	{ rgb(200, 200, 200), rgb(150, 150, 150) }, -- Novato
	{ rgb(255, 255, 255), rgb(200, 220, 235) }, -- Aprendiz
	{ rgb(140, 255, 120), rgb(40, 190, 70) }, -- Pescador
	{ rgb(120, 245, 255), rgb(20, 170, 220) }, -- Marinero
	{ rgb(120, 170, 255), rgb(40, 80, 230) }, -- Capitán
	{ rgb(220, 140, 255), rgb(140, 50, 230) }, -- Almirante
	{ rgb(255, 200, 90), rgb(255, 110, 20) }, -- Domador de Bestias
	{ rgb(255, 90, 120), rgb(150, 20, 90) }, -- Señor del Abismo
	{ rgb(255, 240, 140), rgb(255, 170, 0) }, -- Rey de los Océanos
	{
		rgb(255, 80, 80),
		rgb(255, 220, 60),
		rgb(80, 255, 120),
		rgb(80, 160, 255),
		rgb(200, 90, 255),
	}, -- Dios del Mar
}

local Overhead = {}

local function titleIndex(power: number): number
	local index = 1
	for i, title in TITLES do
		if power >= title.power then
			index = i
		end
	end
	return index
end

local function sequence(colors: { Color3 }): ColorSequence
	local points = {}
	for i, color in colors do
		table.insert(points, ColorSequenceKeypoint.new((i - 1) / math.max(1, #colors - 1), color))
	end
	return ColorSequence.new(points)
end

local function build(player: Player, head: BasePart): () -> ()
	local gui = Instance.new("BillboardGui")
	gui.Name = TAG_NAME
	-- Medido en studs: se ve del tamaño del mundo, como un cartel sobre la cabeza.
	gui.Size = UDim2.fromScale(7, 2.7)
	gui.StudsOffset = Vector3.new(0, 2.9, 0)
	gui.MaxDistance = 120
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
	gui.Parent = head

	return function()
		local power = player:GetAttribute(ATTR.Power)
		local index = titleIndex(if type(power) == "number" then power else 0)
		title.Text = string.upper(TITLES[index].name)
		gradient.Color = sequence(TITLE_COLORS[index] or TITLE_COLORS[1])
		gradient.Rotation = if #(TITLE_COLORS[index] or {}) > 2 then 0 else 90
		local value = player:GetAttribute(ATTR.Kills)
		kills.Text = NumberFormat.short(if type(value) == "number" then value else 0)
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
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
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
end

function Overhead.start()
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
end

return Overhead
