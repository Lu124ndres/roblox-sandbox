--!strict
--[[
	Overhead

	Lo que se ve sobre la cabeza de cada jugador (para todos):
		insignias con marco y fondo (OverheadBadges): monstruos llenados, VIP y Premium
		su título (atributo Titulo, por su poder máximo), con un degradado por
		rango; desde Dios del Mar el brillo recorre el texto
		su nombre
	Reemplaza el nombre de Roblox (se oculta en este cliente). Lee atributos
	que pone el servidor (Titulo, Kills, Pase_VIP). Con efectos reducidos se
	quitan los contornos UIStroke y se ve de más cerca.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Perks = require(ReplicatedStorage.Shared.Perks)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Titles = require(ReplicatedStorage.Shared.Titles)
local TextCase = require(ReplicatedStorage.Shared.TextCase)
local Trajes = require(ReplicatedStorage.Shared.Trajes)
local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)
local OverheadBadges = require(script.Parent.OverheadBadges)
local OverheadLook = require(script.Parent.OverheadLook)
local Style = require(script.Parent.Style)

local ATTR = Protocol.PlayerAttributes
local TAG_NAME = "Encima"

local Overhead = {}

local guis: { [Player]: BillboardGui } = {}
local shimmering: { [UIGradient]: boolean } = {} -- títulos cuyo brillo recorre el texto
local connections: { [Player]: { RBXScriptConnection } } = {}

local function build(player: Player, head: BasePart): () -> ()
	local gui = Instance.new("BillboardGui")
	gui.Name = TAG_NAME
	-- Medido en studs: se ve del tamaño del mundo, como un cartel sobre la cabeza.
	gui.Size = UDim2.fromScale(7, 2.7)
	gui.LightInfluence = 0
	gui.ResetOnSpawn = false

	local top = Instance.new("Frame")
	top.BackgroundTransparency = 1
	top.Size = UDim2.fromScale(1, 0.38)
	top.Name = "Insignias"
	top.Parent = gui
	local badges = OverheadBadges.build(top, player)

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
	local character = head.Parent :: Instance -- los trajes altos (Shared.Trajes) suben el cartel
	local function lift()
		local extra = character:GetAttribute(Trajes.EXTRA_HEIGHT)
		gui.StudsOffset = Vector3.new(0, 3.7 + (tonumber(extra) or 0), 0)
	end
	character:GetAttributeChangedSignal(Trajes.EXTRA_HEIGHT):Connect(lift)
	lift()
	guis[player] = gui

	local shownIndex, shownKills = 0, -1
	return function()
		local value = player:GetAttribute(ATTR.Title)
		local index = if type(value) == "number" then value else 1
		if index ~= shownIndex then
			shownIndex = index
			title.Text = TextCase.upper(Titles.name(index))
			gradient.Color, gradient.Rotation = OverheadLook.gradient(index)
			if OverheadLook.animated(index) then
				shimmering[gradient] = true
			else
				shimmering[gradient] = nil
			end
			gradient.Offset = Vector2.zero
		end
		local kills_ = player:GetAttribute(ATTR.Kills)
		local killCount = if type(kills_) == "number" then kills_ else 0
		if killCount ~= shownKills then
			shownKills = killCount
			badges.setKills(killCount)
		end
		badges.setVip(Perks.hasPass(player, "VIP"))
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
					attribute == ATTR.Title
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
		local gui = guis[player]
		local gradient = gui and gui:FindFirstChild("UIGradient", true)
		if gradient and gradient:IsA("UIGradient") then
			shimmering[gradient] = nil
		end
		guis[player] = nil
	end)
	-- Un solo bucle para todos los títulos con brillo (los de más rango).
	RunService.Heartbeat:Connect(function()
		local offset = Vector2.new(math.sin(os.clock() * 1.6) * 0.6, 0)
		for gradient in shimmering do
			if gradient.Parent then
				gradient.Offset = offset
			else
				shimmering[gradient] = nil
			end
		end
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
