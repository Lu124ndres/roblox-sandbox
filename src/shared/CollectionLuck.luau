--!strict
--[[
	CollectionLuck

	Suerte por secciones de la colección de peces: completar todas las
	especies de una rareza (pescar al menos una de cada) da para siempre la
	suerte de Config.Retention.collectionLuck. Se lee de los atributos
	Pez_<id>, que solo pone el servidor, así que servidor (Perks.luckBonus,
	Retention/Milestones) y cliente (la ventana Índice) calculan igual.
]]

local Config = require(script.Parent.Config)
local Protocol = require(script.Parent.Protocol)

local LUCK = Config.Retention.collectionLuck
local PREFIX = Protocol.PlayerAttributes.FishPrefix

local CollectionLuck = {}

-- Suerte que da completar la sección de esta rareza (0 si no da).
function CollectionLuck.value(rarityId: string): number
	return LUCK[rarityId] or 0
end

-- Especies descubiertas y total de la sección.
function CollectionLuck.progress(player: Player, rarityId: string): (number, number)
	local found, total = 0, 0
	for _, fish in Config.Economy.fish do
		if fish.rarity == rarityId and not fish.limited then
			total += 1
			local amount = player:GetAttribute(`{PREFIX}{fish.id}`)
			found += if type(amount) == "number" and amount > 0 then 1 else 0
		end
	end
	return found, total
end

function CollectionLuck.complete(player: Player, rarityId: string): boolean
	local found, total = CollectionLuck.progress(player, rarityId)
	return total > 0 and found >= total
end

-- Suerte de todas las secciones completas.
function CollectionLuck.bonus(player: Player): number
	local bonus = 0
	for _, rarity in Config.Economy.rarities do
		if CollectionLuck.complete(player, rarity.id) then
			bonus += CollectionLuck.value(rarity.id)
		end
	end
	return bonus
end

return CollectionLuck
