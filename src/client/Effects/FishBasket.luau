--!strict
--[[
	FishBasket

	Canasta en la espalda de cada jugador (su estilo cambia con la canasta
	comprada, ver BasketBuilder) que se va llenando con los peces que lleva (atributo CarriedFish frente a su capacidad, que sale
	de su poder). Llena, el borde brilla coral: es hora de ir al volcán. Así
	todos ven de un vistazo quién viene cargado. Solo decorado: piezas sin
	masa ni colisión soldadas al torso.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local FishingPower = require(ReplicatedStorage.Shared.FishingPower)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local BasketBuilder = require(script.Parent.BasketBuilder)

local ATTR = Protocol.PlayerAttributes
local SLOTS = BasketBuilder.SLOTS -- colas de pez visibles cuando está llena

type Basket = BasketBuilder.Basket

local FishBasket = {}

local function level(player: Player): number
	local value = player:GetAttribute(ATTR.Basket)
	return if type(value) == "number" then value else 1
end

local function refresh(player: Player, basket: Basket, previous: number)
	local carried = player:GetAttribute(ATTR.CarriedFish)
	local count = if type(carried) == "number" then carried else 0
	local capacity = FishingPower.playerCapacity(player)
	local fill = math.clamp(count / capacity, 0, 1)
	local shown = if count > 0 then math.max(1, math.ceil(fill * SLOTS)) else 0
	for index, tail in basket.tails do
		tail.Transparency = if index <= shown then 0 else 1
	end
	local full = count >= capacity
	local glows = level(player) >= 6 -- la bodega del abismo siempre brilla
	basket.rim.Material = if full then Enum.Material.Neon else basket.rimMaterial
	basket.rim.Color = if full then UIConfig.Colors.Feeding else basket.rimColor
	basket.light.Color = if full then UIConfig.Colors.Feeding else Color3.fromRGB(170, 70, 255)
	basket.light.Enabled = full or glows
	if count > previous then -- botecito al guardar un pez
		local size = basket.root.Size
		basket.root.Size = size * 1.12
		TweenService:Create(basket.root, UIConfig.Tweens.Pop, { Size = size }):Play()
	end
end

local function track(player: Player)
	local basket: Basket? = nil
	local last = 0
	local function update()
		if basket then
			refresh(player, basket, last)
		end
		local carried = player:GetAttribute(ATTR.CarriedFish)
		last = if type(carried) == "number" then carried else 0
	end
	local function rebuild(character: Model?)
		if basket then
			basket.folder:Destroy()
			basket = nil
		end
		if character then
			basket = BasketBuilder.build(character, level(player))
			last = 0
			update()
		end
	end
	local function onCharacter(character: Model)
		character:WaitForChild("HumanoidRootPart", 10)
		rebuild(character)
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
	player:GetAttributeChangedSignal(ATTR.CarriedFish):Connect(update)
	player:GetAttributeChangedSignal(ATTR.Power):Connect(update)
	player:GetAttributeChangedSignal(ATTR.Basket):Connect(function()
		rebuild(player.Character) -- compró otra canasta: cambia de estilo
	end)
end

function FishBasket.start()
	Players.PlayerAdded:Connect(track)
	for _, player in Players:GetPlayers() do
		track(player)
	end
end

return FishBasket
