--!strict
--[[
	GiantStages

	El gigante crece por etapas. La etapa sale del progreso de la barra
	(Config.Giants.stageThresholds marca dónde empieza cada una) y el alto de
	cada etapa es un múltiplo del alto de un jugador. Dentro de una etapa
	sigue creciendo con la barra (heightAt, Config.Giants.growth).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(script.Parent.Config)
local Protocol = require(script.Parent.Protocol)

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

-- Alto en studs según el avance de la barra. Dentro de una etapa crece de su alto
-- hacia el de la siguiente (growth.towardNext del camino); la última, hasta
-- growth.finalHeightInPlayers. Crece en proporción (cada pez lo agranda el mismo
-- tanto por ciento), que se ve parejo tanto de cría como de gigante. Con `stage`, no
-- pasa del tope de esa etapa: el último estirón llega con la evolución.
function GiantStages.heightAt(progress: number, stage: number?): number
	local s = math.clamp(stage or GiantStages.stageFor(progress), 1, GiantStages.count)
	local thresholds = GIANTS.stageThresholds
	local from, to = thresholds[s], thresholds[s + 1] or 1
	local t = math.clamp((progress - from) / math.max(to - from, 1e-6), 0, 1)
	local start = GiantStages.heightFor(s)
	local goal = if s < GiantStages.count
		then start + (GiantStages.heightFor(s + 1) - start) * GIANTS.growth.towardNext
		else GIANTS.growth.finalHeightInPlayers * GIANTS.playerHeightStuds
	return start * (goal / start) ^ t
end

-- Comida total que necesita un gigante para llenarse. Si es el gigante actual,
-- la que publica el servidor (atributo Food de EstadoGigante); si no, la de
-- Config (1 si no existe).
function GiantStages.foodFor(giantId: string): number
	local state = ReplicatedStorage:FindFirstChild(Protocol.GiantStateFolder)
	local food = state and state:GetAttribute(Protocol.GiantAttributes.Food)
	if
		state
		and state:GetAttribute(Protocol.GiantAttributes.Id) == giantId
		and type(food) == "number"
	then
		return food
	end
	for _, def in GIANTS.chain do
		if def.id == giantId then
			return def.food
		end
	end
	return 1
end

return table.freeze(GiantStages)
