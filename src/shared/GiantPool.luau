--!strict
--[[
	GiantPool

	Qué monstruos pueden salir ahora en la ruleta (y comprarse para el
	siguiente): los que tienen inRoulette y, si son de evento (season), solo
	entre sus fechas. Lo usan el servidor (GiantCycle, GiantChoice) y el
	cliente (RouletteView, RestChips). restMultiplier: cuánto multiplica el
	entrenamiento de la guarida en el descanso (el del monstruo que se llenó).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(script.Parent.Config)
local Protocol = require(script.Parent.Protocol)

local GiantPool = {}

function GiantPool.available(def: Config.GiantDef): boolean
	if not def.inRoulette then
		return false
	end
	local season = def.season
	if season then
		local now = Workspace:GetServerTimeNow()
		return now >= season.from and now < season.to
	end
	return true
end

-- Los que pueden salir ahora y la suma de sus pesos.
function GiantPool.candidates(): ({ Config.GiantDef }, number)
	local list, total = {}, 0
	for _, def in Config.Giants.chain do
		if GiantPool.available(def) then
			table.insert(list, def)
			total += def.rouletteWeight
		end
	end
	return list, total
end

-- En el cliente: el multiplicador del monstruo actual, que durante el descanso
-- sigue siendo el que se llenó (el siguiente se publica al terminar la ruleta).
function GiantPool.restMultiplier(): number
	local state = ReplicatedStorage:FindFirstChild(Protocol.GiantStateFolder)
	local value = state and state:GetAttribute(Protocol.GiantAttributes.Multiplier)
	return if type(value) == "number" then value else Config.Giants.chain[1].multiplier
end

return GiantPool
