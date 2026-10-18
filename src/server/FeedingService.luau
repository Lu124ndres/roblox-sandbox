--!strict
--[[
	FeedingService

	Alimentar al gigante desde cualquier punto de la orilla del volcán (el
	borde del cráter, con su paseo de obsidiana). Se alimenta MIENTRAS se
	mantiene E (o F) o el botón Alimentar: el cliente manda FeedRequest(true)
	al apretar y FeedRequest(false) al soltar; al soltar se corta. Los peces salen
	parejos, delivery.fishPerSecond por segundo (x1.35 por renacimiento) o, si es
	más rápido, la canasta llena en delivery.basketSeconds (RebirthMath.
	deliveryPerSecond), y su comida entra a la barra al mismo tiempo (la barra sube a
	la par de los peces, pedido del usuario). Cada lote suma a la misión "food" el %
	de la barra que aportó.
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
local RebirthMath = require(ReplicatedStorage.Shared.RebirthMath)
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
local holding: { [Player]: boolean } = {} -- mantiene apretado alimentar

local function send(player: Player, status: Protocol.FeedStatus, fishCount: number, coins: number)
	Remotes.FeedResult:FireClient(player, status, fishCount, coins)
end

local function onShore(player: Player): boolean
	local root = Proximity.getRoot(player)
	return root ~= nil and WorldZones.isOnCraterShore(root.Position)
end

-- Entrega peces mientras el jugador mantiene apretado: salen de la canasta al ritmo de
-- RebirthMath.deliveryPerSecond (renacimientos o canasta llena en basketSeconds), parejos,
-- y su comida entra a la barra en el mismo momento. No se sacan más peces de los que le
-- faltan a la etapa (si evoluciona, espera y sigue). Se corta si suelta, sale de la orilla,
-- se va, se vacía la canasta o el gigante se llena (si evoluciona, espera). Devuelve
-- cuántos peces entregó y cuántas monedas cobró.
local function deliver(player: Player): (number, number)
	local fed, coins = 0, 0
	-- Con mucha fuerza se cargan muchos peces: cada uno paga menos (FishingPower.coinScale).
	local coinScale = FishingPower.coinScale(PlayerData.getPower(player))
	local speed = Perks.feedMultiplier(player) -- pases: Rey del Mar x2, Dios del Volcán x4
	local perSecond = speed
		* RebirthMath.deliveryPerSecond(RebirthMath.count(player), PlayerData.getCapacity(player))
	local fishCredit = 1 -- el primer pez sale al apretar
	local last = os.clock()
	while
		(GiantService.isFeeding() or GiantService.isEvolving())
		and player.Parent
		and holding[player]
		and onShore(player)
	do
		local now = os.clock()
		local dt = now - last
		last = now
		if GiantService.isEvolving() then
			task.wait(DELIVERY.stepSeconds)
			continue
		end
		-- Lo que se junta mientras no alcanza para un pez se guarda (hasta 1 s).
		fishCredit = math.min(fishCredit + perSecond * dt, math.max(1, perSecond))
		local count = math.floor(fishCredit)
		local room = GiantService.remainingFood()
		if count >= 1 and room > 0 then
			local taken, took, food, baseCoins = PlayerData.takeFishBatch(player, count, room)
			if took == 0 then
				break -- canasta vacía
			end
			fishCredit -= took
			local earned = math.floor(
				baseCoins
					* coinScale
					* GiantService.getCurrent().multiplier
					* Perks.coinMultiplier(player)
			)
			GiantService.feed(food, player, took, Basket.rarest(taken))
			PlayerData.addCoins(player, earned)
			Quests.add(player, "food", food / GiantService.getFood() * 100)
			fed += took
			coins += earned
		elseif PlayerData.getCarriedCount(player) == 0 then
			break
		end
		task.wait(DELIVERY.stepSeconds)
	end
	return fed, coins
end

local function onFeed(player: Player, hold: unknown)
	if hold == false then
		holding[player] = nil -- soltó: la entrega se corta en el próximo lote
		return
	end
	holding[player] = true
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
		local status: Protocol.FeedStatus = if GiantService.isEvolving()
			then "evolving"
			elseif GiantService.getPhase() == "rest" then "resting"
			else "full"
		send(player, status, 0, 0)
		return
	end
	if PlayerData.getCarriedCount(player) == 0 then
		send(player, "empty", 0, 0)
		return
	end
	streaming[player] = true
	local ok, fed, coins = pcall(deliver, player)
	streaming[player] = nil
	if not ok then
		warn(`FeedingService: falló la entrega de {player.Name}: {fed}`)
		return
	end
	if player.Parent and fed > 0 then
		send(player, "ok", fed, coins)
		Milestones.fed(player, fed)
		if PlayerData.getCarriedCount(player) == 0 then
			Quests.add(player, "feed", 1) -- cuenta canastas vaciadas (viajes al volcán), no toques
		end
	end
end

function FeedingService.init()
	-- FeedRequest(mantiene: boolean): el servidor mira dónde está el jugador.
	Remotes.FeedRequest.OnServerEvent:Connect(RateLimit.wrap("FeedRequest", 4, 6, onFeed))
	Players.PlayerRemoving:Connect(function(player: Player)
		lastRequestAt[player] = nil
		streaming[player] = nil
		holding[player] = nil
	end)
end

return FeedingService
