--!strict
--[[
	FishCatalog

	Búsquedas sobre la tabla de peces de Config: por id, su rareza (y el
	nivel de esa rareza, 1 = común) y la tirada ponderada. La usan el
	servidor (qué pez sale, cuánto rinde) y el cliente (nombres y colores).
	Los limitados (Config/FishLimited) solo salen en sus fechas y quedan
	fuera de la colección: `collectible` es la lista que cuenta para ella.
]]

local Workspace = game:GetService("Workspace")

local Config = require(script.Parent.Config)

local ECONOMY = Config.Economy

local FishCatalog = {}

local byId: { [string]: Config.FishDef } = {}
local collectible: { Config.FishDef } = {}
local totalWeight = 0 -- de la colección; un limitado se suma solo a sí mismo en chance
for _, fish in ECONOMY.fish do
	byId[fish.id] = fish
	if not fish.limited then
		table.insert(collectible, fish)
		totalWeight += fish.weight
	end
end

-- Los peces que cuentan para la colección, sus hitos y la suerte por sección.
FishCatalog.collectible = table.freeze(collectible)

local rarityIndex: { [string]: number } = {}
for index, rarity in ECONOMY.rarities do
	rarityIndex[rarity.id] = index
end

function FishCatalog.get(fishId: string): Config.FishDef?
	return byId[fishId]
end

-- Rareza del pez y su nivel (1 = común ... #rarities = la más rara).
function FishCatalog.rarity(fishId: string): (Config.RarityDef, number)
	local fish = byId[fishId]
	local index = if fish then rarityIndex[fish.rarity] or 1 else 1
	return ECONOMY.rarities[index], index
end

-- Rareza por su id (nil si no existe).
function FishCatalog.rarityById(rarityId: string): Config.RarityDef?
	local index = rarityIndex[rarityId]
	return if index then ECONOMY.rarities[index] else nil
end

-- ¿Es un pez limitado (fuera de la colección)?
function FishCatalog.isLimited(fishId: string): boolean
	local fish = byId[fishId]
	return fish ~= nil and fish.limited ~= nil
end

-- ¿Puede picar ahora? Los limitados, solo entre sus fechas (hora del servidor).
function FishCatalog.available(fish: Config.FishDef): boolean
	local limited = fish.limited
	if not limited then
		return true
	end
	local now = Workspace:GetServerTimeNow()
	return now >= limited.from and now < limited.to
end

-- Probabilidad (0..1) de que salga este pez en una tirada.
function FishCatalog.chance(fishId: string): number
	local fish = byId[fishId]
	if not fish then
		return 0
	end
	return fish.weight / (totalWeight + if fish.limited then fish.weight else 0)
end

-- Peso de un pez en la tirada: la suerte multiplica todo lo que no es común; un limitado
-- fuera de sus fechas pesa 0. La misma cuenta para sortear y para mostrar probabilidades.
local function weightOf(fish: Config.FishDef, boost: number): number
	if not FishCatalog.available(fish) then
		return 0
	end
	return if (rarityIndex[fish.rarity] or 1) > 1 then fish.weight * boost else fish.weight
end

-- Probabilidad (0 a 100) de cada rareza con esta suerte, de común a la más rara.
function FishCatalog.rarityChances(luck: number?): { { id: string, name: string, chance: number } }
	local boost = 1 + math.max(0, luck or 0)
	local byRarity: { [string]: number } = {}
	local total = 0
	for _, fish in ECONOMY.fish do
		local weight = weightOf(fish, boost)
		byRarity[fish.rarity] = (byRarity[fish.rarity] or 0) + weight
		total += weight
	end
	local result = {}
	for _, rarity in ECONOMY.rarities do
		local weight = byRarity[rarity.id] or 0
		local chance = if total > 0 then weight / total * 100 else 0
		table.insert(result, { id = rarity.id, name = rarity.displayName, chance = chance })
	end
	return result
end

-- Tirada ponderada. luck (de la caña y los extras) sube el peso de todo lo que no es común.
function FishCatalog.roll(rng: Random, luck: number?): Config.FishDef
	local boost = 1 + math.max(0, luck or 0)
	local total = 0
	for _, fish in ECONOMY.fish do
		total += weightOf(fish, boost)
	end
	local roll = rng:NextNumber(0, total)
	for _, fish in ECONOMY.fish do
		local weight = weightOf(fish, boost)
		roll -= weight
		if weight > 0 and roll <= 0 then
			return fish
		end
	end
	return collectible[#collectible]
end

return FishCatalog
