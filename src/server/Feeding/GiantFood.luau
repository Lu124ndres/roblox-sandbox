--!strict
--[[
	GiantFood

	Cuánta comida pide un monstruo al llegar (GiantService.reset): lo que el
	servidor puede darle por segundo, por sus targetMinutes (Config/Giants).
	Cada jugador cargado aporta su ritmo estimado con las mismas fórmulas que
	la pesca y la entrega (shared/FishingPower, shared/RebirthMath):

		ciclo  = lanzamientos para llenar la canasta x (pique medio + sizing.castOverheadSeconds)
		         + canasta / peces por segundo al entregar + sizing.tripSeconds
		ritmo  = canasta x comida media por pez / ciclo

	La suma se multiplica por sizing.activeShare (nadie pesca el 100 % del
	tiempo). Nunca baja de def.food: con el servidor vacío o solo novatos el
	monstruo sigue siendo una meta. Un novato solo llena la Orca en ~6-8 min;
	40 jugadores fuertes, en lo mismo, con una barra mucho más grande.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local FishingPower = require(ReplicatedStorage.Shared.FishingPower)
local Perks = require(ReplicatedStorage.Shared.Perks)
local RebirthMath = require(ReplicatedStorage.Shared.RebirthMath)
local PlayerData = require(script.Parent.Parent.PlayerData)

local SIZING = Config.Giants.sizing
local FISHING = Config.Gameplay.fishing
local AVERAGE_BITE = (FISHING.biteDelayMinSeconds + FISHING.biteDelayMaxSeconds) / 2

-- Comida media de un pez en la tirada sin suerte (los pesos de Config/Fish).
local AVERAGE_FOOD = (function(): number
	local weight, food = 0, 0
	for _, fish in Config.Economy.fish do
		weight += fish.weight
		food += fish.weight * fish.food
	end
	return food / math.max(weight, 1)
end)()

local GiantFood = {}

-- Comida por segundo que puede dar este jugador pescando y alimentando sin parar.
function GiantFood.playerRate(player: Player): number
	local power = PlayerData.getPower(player)
	local capacity = math.max(1, FishingPower.playerCapacity(player))
	local casts = math.ceil(capacity / FishingPower.playerFishPerCatch(player))
	local bite = math.max(FISHING.castSeconds + 0.1, FishingPower.biteDelay(AVERAGE_BITE, power))
		* Perks.biteDelayMultiplier(player)
	local deliver = capacity / RebirthMath.deliveryPerSecond(RebirthMath.count(player), capacity)
	local cycle = casts * (bite + SIZING.castOverheadSeconds) + deliver + SIZING.tripSeconds
	return capacity * AVERAGE_FOOD / cycle
end

-- Comida total para `def` con los jugadores que hay ahora.
function GiantFood.forGiant(def: Config.GiantDef): number
	local rate = 0
	for _, player in Players:GetPlayers() do
		if PlayerData.isLoaded(player) then
			rate += GiantFood.playerRate(player)
		end
	end
	local target = rate * SIZING.activeShare * def.targetMinutes * 60
	return math.max(def.food, math.floor(target))
end

return GiantFood
