--!strict
--[[
	FishingPower

	Qué hace el poder de pesca. Lo usan el servidor (para decidir) y el HUD
	(para mostrarlo), así que las fórmulas viven en un solo lugar. El poder es
	la FUERZA, como en «Construye la Pirámide»: cada rato de entrenamiento se
	nota en cuántos peces cargas.

		capacidad       = (carryCapacity + capacityPerRoot x sqrt(poder)) x canasta
		peces por pique = capacidad / lanzamientos para llenarla (menos con
		                  mejores cañas): la canasta se llena en 6 a 16 tiros
		velocidad       = 1 + sqrt(poder) / biteSpeedDivisor
		espera de pique = espera base / velocidad (nunca menos de minBiteDelaySeconds)

	coinScale: cada pez paga menos cuanto más cargas, para que una canasta
	llena pague lo mismo que con la fórmula vieja (raíz cuarta) y los precios
	de la tienda sigan sirviendo. La comida de los monstruos sí crece.
]]

local Config = require(script.Parent.Config)
local Upgrades = require(script.Parent.Upgrades)

local PROGRESSION = Config.Progression
local FISHING = Config.Gameplay.fishing
local CASTS = PROGRESSION.castsToFill
local LEGACY_STEP, LEGACY_EXPONENT = 1000, 0.25 -- fórmula vieja: solo para coinScale

local FishingPower = {}

local function root(power: number): number
	return math.sqrt(math.max(0, power))
end

local function number(player: Player, attribute: string): number
	local value = player:GetAttribute(attribute)
	return if type(value) == "number" then value else 0
end

function FishingPower.speed(power: number): number
	return 1 + root(power) / PROGRESSION.biteSpeedDivisor
end

function FishingPower.capacity(power: number, basketMultiplier: number?): number
	local base = FISHING.carryCapacity + PROGRESSION.capacityPerRoot * root(power)
	return math.floor(base * (basketMultiplier or 1))
end

-- Lanzamientos para llenar la canasta con la caña de nivel `rodLevel`.
function FishingPower.castsToFill(rodLevel: number): number
	return math.max(CASTS.min, CASTS.start - (rodLevel - 1) * CASTS.perRod)
end

function FishingPower.fishPerCatch(
	power: number,
	basketMultiplier: number?,
	rodLevel: number?
): number
	local capacity = FishingPower.capacity(power, basketMultiplier)
	return math.max(1, math.ceil(capacity / FishingPower.castsToFill(rodLevel or 1)))
end

-- Capacidad y peces por pique de un jugador (atributos que publica el servidor).
function FishingPower.playerCapacity(player: Player): number
	return FishingPower.capacity(number(player, "Power"), Upgrades.current(player, "Basket").value)
end

function FishingPower.playerFishPerCatch(player: Player): number
	return FishingPower.fishPerCatch(
		number(player, "Power"),
		Upgrades.current(player, "Basket").value,
		Upgrades.level(player, "Rod")
	)
end

-- Cuánto paga cada pez (0..1): una canasta llena paga como con la fórmula vieja.
function FishingPower.coinScale(power: number): number
	local legacyPerCatch = 1 + math.floor((math.max(0, power) / LEGACY_STEP) ^ LEGACY_EXPONENT)
	return math.min(1, FISHING.carryCapacity * legacyPerCatch / FishingPower.capacity(power))
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
