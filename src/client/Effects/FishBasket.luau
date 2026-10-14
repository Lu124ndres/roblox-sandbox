--!strict
--[[
	FishBasket

	Canasta en la espalda de cada jugador (su estilo cambia con la canasta
	comprada, ver BasketBuilder) que se va llenando con los peces que lleva (atributo CarriedFish frente a su capacidad, que sale
	de su poder). Llena, el borde brilla coral: es hora de ir al volcán. Así
	todos ven de un vistazo quién viene cargado. Solo decorado: piezas sin
	masa ni colisión soldadas al torso.

	Detalle por distancia (Effects/Distance): de los otros jugadores a media
	distancia o más lejos se quitan los adornos, y la luz solo se enciende
	de cerca. Las conexiones de cada jugador se cortan cuando se va.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local FishingPower = require(ReplicatedStorage.Shared.FishingPower)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local BasketBuilder = require(script.Parent.BasketBuilder)
local Distance = require(script.Parent.Distance)

local ATTR = Protocol.PlayerAttributes
local SLOTS = BasketBuilder.SLOTS -- colas de pez visibles cuando está llena

type Basket = BasketBuilder.Basket

type Tracked = {
	basket: Basket?,
	full: boolean, -- llena (el borde brilla)
	connections: { RBXScriptConnection },
}

local FishBasket = {}

local tracked: { [Player]: Tracked } = {}

local function level(player: Player): number
	local value = player:GetAttribute(ATTR.Basket)
	return if type(value) == "number" then value else 1
end

-- Adornos y luz según la distancia (el jugador local siempre "near").
local function applyTier(player: Player, entry: Tracked)
	local basket = entry.basket
	if not basket then
		return
	end
	local near = Distance.tier(player) == "near"
	basket.trim.Parent = if near then basket.folder else nil
	local glows = level(player) >= 6 -- la bodega del abismo siempre brilla
	basket.light.Enabled = near and (entry.full or glows)
end

local function refresh(player: Player, entry: Tracked, previous: number)
	local basket = entry.basket
	if not basket then
		return
	end
	local carried = player:GetAttribute(ATTR.CarriedFish)
	local count = if type(carried) == "number" then carried else 0
	local capacity = FishingPower.playerCapacity(player)
	local fill = math.clamp(count / capacity, 0, 1)
	local shown = if count > 0 then math.max(1, math.ceil(fill * SLOTS)) else 0
	for index, tail in basket.tails do
		tail.Transparency = if index <= shown then 0 else 1
	end
	local full = count >= capacity
	entry.full = full
	basket.rim.Material = if full then Enum.Material.Neon else basket.rimMaterial
	basket.rim.Color = if full then UIConfig.Colors.Feeding else basket.rimColor
	basket.light.Color = if full then UIConfig.Colors.Feeding else Color3.fromRGB(170, 70, 255)
	applyTier(player, entry)
	if count > previous then -- botecito al guardar un pez
		local size = basket.root.Size
		basket.root.Size = size * 1.12
		TweenService:Create(basket.root, UIConfig.Tweens.Pop, { Size = size }):Play()
	end
end

local function track(player: Player)
	local entry: Tracked = { full = false, connections = {} }
	tracked[player] = entry
	local last = 0
	local function update()
		refresh(player, entry, last)
		local carried = player:GetAttribute(ATTR.CarriedFish)
		last = if type(carried) == "number" then carried else 0
	end
	local function rebuild(character: Model?)
		if entry.basket then
			entry.basket.folder:Destroy()
			entry.basket.trim:Destroy() -- por si estaba sin padre
			entry.basket = nil
		end
		if character and tracked[player] == entry then
			entry.basket = BasketBuilder.build(character, level(player))
			last = 0
			update()
		end
	end
	local function onCharacter(character: Model)
		character:WaitForChild("HumanoidRootPart", 10)
		rebuild(character)
	end
	local connections = entry.connections
	table.insert(connections, player.CharacterAdded:Connect(onCharacter))
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
	table.insert(connections, player:GetAttributeChangedSignal(ATTR.CarriedFish):Connect(update))
	table.insert(connections, player:GetAttributeChangedSignal(ATTR.Power):Connect(update))
	table.insert(
		connections,
		player:GetAttributeChangedSignal(ATTR.Basket):Connect(function()
			rebuild(player.Character) -- compró otra canasta: cambia de estilo
		end)
	)
end

function FishBasket.start()
	Players.PlayerAdded:Connect(track)
	Players.PlayerRemoving:Connect(function(player: Player)
		local entry = tracked[player]
		tracked[player] = nil
		if entry then
			for _, connection in entry.connections do
				connection:Disconnect()
			end
			if entry.basket then
				entry.basket.trim:Destroy()
				entry.basket.folder:Destroy()
				entry.basket = nil
			end
		end
	end)
	Distance.onChanged(function(player: Player)
		local entry = tracked[player]
		if entry then
			applyTier(player, entry)
		end
	end)
	for _, player in Players:GetPlayers() do
		track(player)
	end
end

return FishBasket
