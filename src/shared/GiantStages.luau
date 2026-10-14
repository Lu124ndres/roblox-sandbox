--!strict
--[[
	GiantStages

	El gigante crece por etapas. La etapa sale del progreso de la barra
	(Config.Giants.stageThresholds marca dónde empieza cada una) y el alto de
	cada etapa es un múltiplo del alto de un jugador.
]]

local Config = require(script.Parent.Config)

local GIANTS = Config.Giants

local GiantStages = {}

GiantStages.count = #GIANTS.stageThresholds

-- Etapa actual (1..count) para un progreso de 0 a 1.
function GiantStages.stageFor(progress: number): number
	local stage = 1
	for index, threshold in GIANTS.stageThresholds do
		if progress >= threshold - 1e-6 then
			stage = index
		end
	end
	return stage
end

-- Alto en studs del gigante en una etapa.
function GiantStages.heightFor(stage: number): number
	local multiple = GIANTS.stageHeightsInPlayers[math.clamp(stage, 1, GiantStages.count)]
	return multiple * GIANTS.playerHeightStuds
end

-- Comida total que necesita un gigante para llenarse (1 si no existe).
function GiantStages.foodFor(giantId: string): number
	for _, def in GIANTS.chain do
		if def.id == giantId then
			return def.food
		end
	end
	return 1
end

return table.freeze(GiantStages)
