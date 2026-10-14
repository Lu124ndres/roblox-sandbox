--!strict
--[[
	GiantFood

	Cuánta comida pide un gigante según los jugadores ACTIVOS del servidor
	(pescaron en los últimos scaling.activeSeconds o llevan peces):

		total = clamp(loadsPerPlayer x comida media
		              x Σ base x (capacidad / base) ^ capacityExponent,
		              def.food, def.food x scaling.maxFoodFactor)

	base = la canasta inicial. Con capacityExponent < 1 la comida crece menos
	que la canasta: mejorarla sí acorta los viajes por monstruo.

	La comida media por pez sale de la tabla de Config (pesos de la tirada,
	sin la suerte de la caña). Sin nadie activo, el total es def.food. Así 50
	jugadores con canastas guardadas durante el descanso no lo llenan en
	segundos, y un servidor chico no espera para siempre.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local GiantStages = require(ReplicatedStorage.Shared.GiantStages)
local PlayerData = require(script.Parent.Parent.PlayerData)

local SCALING = Config.Giants.scaling
local FULL_CAP = 0.999

local GiantFood = {}

local function computeAverageFood(): number
	local weight, food = 0, 0
	for _, fish in Config.Economy.fish do
		weight += fish.weight
		food += fish.weight * fish.food
	end
	return if weight > 0 then food / weight else 1
end

GiantFood.averageFood = computeAverageFood()

-- Suma de las capacidades (amortiguadas) de los jugadores activos.
function GiantFood.activeCapacity(): number
	local base = Config.Gameplay.fishing.carryCapacity
	local sum = 0
	for _, player in Players:GetPlayers() do
		if PlayerData.isActive(player, SCALING.activeSeconds) then
			local capacity = math.max(PlayerData.getCapacity(player), base)
			sum += base * (capacity / base) ^ SCALING.capacityExponent
		end
	end
	return sum
end

-- Comida total que debería pedir `def` con los jugadores activos de ahora.
function GiantFood.target(def: Config.GiantDef): number
	local wanted = def.loadsPerPlayer * GiantFood.averageFood * GiantFood.activeCapacity()
	return math.ceil(math.clamp(wanted, def.food, def.food * SCALING.maxFoodFactor))
end

-- El total pasa de `total` a `target` conservando lo ya comido: la fracción
-- se reescala, sin bajar del inicio de la etapa actual (el gigante no encoge)
-- ni llegar a 1 (se llena con el próximo bocado, no solo).
function GiantFood.rescale(progress: number, total: number, target: number): (number, number)
	local floor = Config.Giants.stageThresholds[GiantStages.stageFor(progress)]
	return math.min(FULL_CAP, math.max(floor, progress * total / target)), target
end

return GiantFood
