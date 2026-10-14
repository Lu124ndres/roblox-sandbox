--!strict
--[[
	FeedingService

	Alimentar al gigante desde cualquier punto de la orilla del volcán: el
	borde del cráter y los muelles del abismo. En PC con E (o F) y en móvil
	con el botón Alimentar, el cliente manda FeedRequest. Los peces se
	entregan de 1 en 1 (cada uno vuela a la boca y paga sus monedas).
	Siempre se valida en el servidor que el jugador esté en la orilla
	(WorldZones.isOnCraterShore). El jugador entrega todos los peces que lleva; el gigante recibe su comida y el jugador cobra
	monedas (multiplicadas por el gigante actual). El poder de pesca ya rindió
	antes: hace pescar más peces y más rápido. Alimentar calma al gigante.
	Todo en el servidor.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local FishCatalog = require(ReplicatedStorage.Shared.FishCatalog)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Perks = require(ReplicatedStorage.Shared.Perks)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local GiantService = require(script.Parent.GiantService)
local PlayerData = require(script.Parent.PlayerData)
local Milestones = require(script.Parent.Retention.Milestones)
local Proximity = require(script.Parent.Proximity)
local RateLimit = require(script.Parent.RateLimit)
local Remotes = require(script.Parent.Remotes)

local FEEDING = Config.Gameplay.feeding

local FeedingService = {}

local lastRequestAt: { [Player]: number } = {}
local streaming: { [Player]: boolean } = {} -- entregando peces ahora mismo

local function send(player: Player, status: Protocol.FeedStatus, fishCount: number, coins: number)
	Remotes.FeedResult:FireClient(player, status, fishCount, coins)
end

local function onFeed(player: Player)
	if streaming[player] then
		return
	end
	local now = os.clock()
	if now - (lastRequestAt[player] or 0) < FEEDING.requestCooldownSeconds then
		return
	end
	local root = Proximity.getRoot(player)
	if not root or not WorldZones.isOnCraterShore(root.Position) then
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

	-- De 1 en 1: cada pez sale de la canasta, llega al gigante y paga sus monedas.
	-- Se corta si el jugador sale de la orilla o el gigante se llena; lo que
	-- quede sigue en la canasta.
	streaming[player] = true
	local interval = math.clamp(
		FEEDING.streamSeconds / total,
		FEEDING.minFishIntervalSeconds,
		FEEDING.maxFishIntervalSeconds
	)
	local fed, coins = 0, 0
	while GiantService.isFeeding() and player.Parent do
		local here = Proximity.getRoot(player)
		if not here or not WorldZones.isOnCraterShore(here.Position) then
			break
		end
		local fishId = PlayerData.takeFish(player)
		local fish = if fishId then FishCatalog.get(fishId) else nil
		if not fishId or not fish then
			break
		end
		local earned = math.floor(
			fish.coins * GiantService.getCurrent().multiplier * Perks.coinMultiplier(player)
		)
		GiantService.feed(fish.food, player, fishId)
		PlayerData.addCoins(player, earned)
		fed += 1
		coins += earned
		task.wait(interval)
	end
	streaming[player] = nil
	if player.Parent then
		send(player, "ok", fed, coins)
		Milestones.fed(player, fed)
	end
end

function FeedingService.init()
	-- FeedRequest no lleva argumentos: el servidor mira dónde está el jugador.
	Remotes.FeedRequest.OnServerEvent:Connect(RateLimit.wrap("FeedRequest", 4, 6, onFeed))
	Players.PlayerRemoving:Connect(function(player: Player)
		lastRequestAt[player] = nil
	end)
end

return FeedingService
