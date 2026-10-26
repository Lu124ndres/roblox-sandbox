--!strict
--[[
	Collection

	Hitos de la colección de peces (Config.Retention.collectionMilestone):
	cada `every` especies descubiertas hay un premio de monedas que crece con
	el hito y con el avance (shared/RewardScale); la última (todas) paga
	collectionBonus. Lo usan el servidor (Retention/Milestones, paga) y la
	ventana de la colección (client/Menus/FishDex, muestra el siguiente).
]]

local Config = require(script.Parent.Config)
local FishCatalog = require(script.Parent.FishCatalog)
local RewardScale = require(script.Parent.RewardScale)

local MILESTONE = Config.Retention.collectionMilestone
local TOTAL = #FishCatalog.collectible -- sin los limitados

local Collection = {}

Collection.total = TOTAL

-- ¿Descubrir la especie número `found` da premio? (6, 12, 18... y la última)
function Collection.isMilestone(found: number): boolean
	return found > 0 and (found % MILESTONE.every == 0 or found == TOTAL)
end

-- Siguiente hito después de `found` especies (nil si ya tiene todas).
function Collection.nextMilestone(found: number): number?
	if found >= TOTAL then
		return nil
	end
	return math.min(TOTAL, (found // MILESTONE.every + 1) * MILESTONE.every)
end

-- Monedas del hito `found` para este jugador (sin el multiplicador de monedas).
function Collection.reward(player: Player, found: number): number
	if found >= TOTAL then
		return Config.Retention.collectionBonus
	end
	local step = found // MILESTONE.every
	return RewardScale.share(player, MILESTONE.coins * step, MILESTONE.share)
end

return Collection
