--!strict
--[[
	GiantPool

	Qué monstruos pueden salir ahora en la ruleta (y comprarse para el
	siguiente): los que tienen inRoulette y, si son de evento (season), solo
	entre sus fechas. Lo usan el servidor (GiantCycle, GiantChoice) y el
	cliente (RouletteView, RestChips).
]]

local Workspace = game:GetService("Workspace")

local Config = require(script.Parent.Config)

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

return GiantPool
