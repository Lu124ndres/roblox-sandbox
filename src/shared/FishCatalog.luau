--!strict
--[[
	FishCatalog

	Búsquedas sobre la tabla de peces de Config: por id, su rareza (y el
	nivel de esa rareza, 1 = común) y la tirada ponderada. La usan el
	servidor (qué pez sale, cuánto rinde) y el cliente (nombres y colores).
]]

local Config = require(script.Parent.Config)

local ECONOMY = Config.Economy

local FishCatalog = {}

local byId: { [string]: Config.FishDef } = {}
local totalWeight = 0
for _, fish in ECONOMY.fish do
	byId[fish.id] = fish
	totalWeight += fish.weight
end

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

-- Probabilidad (0..1) de que salga este pez en una tirada.
function FishCatalog.chance(fishId: string): number
	local fish = byId[fishId]
	return if fish then fish.weight / totalWeight else 0
end

-- Tirada ponderada. luck (de la caña) sube el peso de todo lo que no es común.
function FishCatalog.roll(rng: Random, luck: number?): Config.FishDef
	local boost = 1 + math.max(0, luck or 0)
	local function weightOf(fish: Config.FishDef): number
		return if (rarityIndex[fish.rarity] or 1) > 1 then fish.weight * boost else fish.weight
	end
	local total = 0
	for _, fish in ECONOMY.fish do
		total += weightOf(fish)
	end
	local roll = rng:NextNumber(0, total)
	for _, fish in ECONOMY.fish do
		roll -= weightOf(fish)
		if roll <= 0 then
			return fish
		end
	end
	return ECONOMY.fish[#ECONOMY.fish]
end

return FishCatalog
