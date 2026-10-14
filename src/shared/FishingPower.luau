--!strict
--[[
	FishingPower

	Qué hace el poder de pesca. Lo usan el servidor (para decidir) y el HUD
	(para mostrarlo), así que las fórmulas viven en un solo lugar:

		velocidad      = 1 + sqrt(poder) / biteSpeedDivisor
		espera de pique = espera base / velocidad (nunca menos de minBiteDelaySeconds)
		peces por pique = 1 + floor(log10(1 + poder / fishPerCatchStep))
		capacidad       = carryCapacity x peces por pique x canasta (tienda)

	La capacidad crece con los peces por pique para que un jugador fuerte no
	tenga que ir al volcán cada dos lanzamientos.
]]

local Config = require(script.Parent.Config)
local Upgrades = require(script.Parent.Upgrades)

local PROGRESSION = Config.Progression
local FISHING = Config.Gameplay.fishing

local FishingPower = {}

local function root(power: number): number
	return math.sqrt(math.max(0, power))
end

function FishingPower.speed(power: number): number
	return 1 + root(power) / PROGRESSION.biteSpeedDivisor
end

function FishingPower.fishPerCatch(power: number): number
	return 1 + math.floor(math.log10(1 + math.max(0, power) / PROGRESSION.fishPerCatchStep))
end

function FishingPower.capacity(power: number, basketMultiplier: number?): number
	return math.floor(
		FISHING.carryCapacity * FishingPower.fishPerCatch(power) * (basketMultiplier or 1)
	)
end

-- Capacidad de un jugador con su poder y su canasta (atributos que publica el servidor).
function FishingPower.playerCapacity(player: Player): number
	local power = player:GetAttribute("Power")
	local basket = Upgrades.current(player, "Basket")
	return FishingPower.capacity(if type(power) == "number" then power else 0, basket.value)
end

-- Espera hasta el pique para una tirada base (en segundos) de la tabla.
function FishingPower.biteDelay(baseSeconds: number, power: number): number
	return math.max(PROGRESSION.minBiteDelaySeconds, baseSeconds / FishingPower.speed(power))
end

-- Multiplicador del mejor estanque que se abre con `kills` monstruos llenados.
function FishingPower.bestPondMultiplier(kills: number): number
	local best = 1
	for _, pond in PROGRESSION.ponds do
		if kills >= pond.requiredKills then
			best = math.max(best, pond.multiplier)
		end
	end
	return best
end

return FishingPower
