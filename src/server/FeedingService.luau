--!strict
--[[
	FeedingService

	Alimentar al gigante desde cualquier punto de la orilla del volcán: el
	borde del cráter y los muelles del abismo. En PC con E (o F) y en móvil
	con el botón Alimentar, el cliente manda FeedRequest. Los peces se
	entregan por lotes: un lote cada delivery.stepSeconds, y la canasta
	entera en a lo sumo delivery.maxDeliverySeconds sin importar su tamaño.
	Cada lote cobra sus monedas una vez (multiplicadas por el gigante actual)
	y avanza al gigante una vez. Antes de cada lote se valida en el servidor
	que el jugador siga en la orilla (WorldZones.isOnCraterShore). El poder de pesca ya rindió
	antes: hace pescar más peces y más rápido. Alimentar calma al gigante.
	Todo en el servidor.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local FishingPower = require(ReplicatedStorage.Shared.FishingPower)
local Perks = require(ReplicatedStorage.Shared.Perks)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local Basket = require(script.Parent.Feeding.Basket)
local GiantService = require(script.Parent.GiantService)
local PlayerData = require(script.Parent.PlayerData)
local Quests = require(script.Parent.Retention.Quests)
local Milestones = require(script.Parent.Retention.Milestones)
local Proximity = require(script.Parent.Proximity)
local RateLimit = require(script.Parent.RateLimit)
local Remotes = require(script.Parent.Remotes)

local FEEDING = Config.Gameplay.feeding
local DELIVERY = Config.Giants.delivery

local FeedingService = {}

local lastRequestAt: { [Player]: number } = {}
local streaming: { [Player]: boolean } = {} -- entregando peces ahora mismo

local function send(player: Player, status: Protocol.FeedStatus, fishCount: number, coins: number)
	Remotes.FeedResult:FireClient(player, status, fishCount, coins)
end

local function onShore(player: Player): boolean
	local root = Proximity.getRoot(player)
	return root ~= nil and WorldZones.isOnCraterShore(root.Position)
end

-- Entrega la canasta por lotes. Se corta si el jugador sale de la orilla, se
-- va o el gigante se llena; lo que quede sigue en la canasta. Devuelve
-- cuántos peces entregó y cuántas monedas cobró.
local function deliver(player: Player, total: number): (number, number)
	local steps = math.max(1, math.ceil(DELIVERY.maxDeliverySeconds / DELIVERY.stepSeconds))
	local perStep = math.max(1, math.ceil(total / steps))
	local fed, coins = 0, 0
	-- Con mucha fuerza se cargan muchos peces: cada uno paga menos (FishingPower.coinScale).
	local coinScale = FishingPower.coinScale(PlayerData.getPower(player))
	while GiantService.isFeeding() and player.Parent and onShore(player) do
		local taken, count, food, baseCoins =
			PlayerData.takeFishBatch(player, perStep, GiantService.remainingFood())
		if count == 0 then
			break
		end
		local earned = math.floor(
			baseCoins
				* coinScale
				* GiantService.getCurrent().multiplier
				* Perks.coinMultiplier(player)
		)
		GiantService.feed(food, player, count, Basket.rarest(taken))
		PlayerData.addCoins(player, earned)
		fed += count
		coins += earned
		task.wait(DELIVERY.stepSeconds)
	end
	return fed, coins
end

local function onFeed(player: Player)
	if streaming[player] then
		return
	end
	local now = os.clock()
	if now - (lastRequestAt[player] or 0) < FEEDING.requestCooldownSeconds then
		return
	end
	if not onShore(player) then
		return
	end
	lastRequestAt[player] = now
	if not GiantService.isFeeding() then
		send(player, if GiantService.getPhase() == "rest" then "resting" else "full", 0, 0)
		return
	end
	local total = PlayerData.getCarriedCount(player)
	if total == 0 then
		send(player, "empty", 0, 0)
		return
	end
	streaming[player] = true
	local ok, fed, coins = pcall(deliver, player, total)
	streaming[player] = nil
	if not ok then
		warn(`FeedingService: falló la entrega de {player.Name}: {fed}`)
		return
	end
	if player.Parent then
		send(player, "ok", fed, coins)
		Milestones.fed(player, fed)
		if fed > 0 then
			Quests.add(player, "feed", 1) -- cuenta entregas (viajes al volcán), no peces
		end
	end
end

function FeedingService.init()
	-- FeedRequest no lleva argumentos: el servidor mira dónde está el jugador.
	Remotes.FeedRequest.OnServerEvent:Connect(RateLimit.wrap("FeedRequest", 4, 6, onFeed))
	Players.PlayerRemoving:Connect(function(player: Player)
		lastRequestAt[player] = nil
		streaming[player] = nil
	end)
end

return FeedingService
