--!strict
--[[
	Origen

	De dónde llegó un jugador, para separar en el embudo de inicio a los que
	entraron por un anuncio. Cada campaña de Ads Manager lleva un launch data
	propio que empieza con "ad_" (por ejemplo ad_prueba o ad_engagement), y
	Roblox lo pega a la URL de entrada. Va en el campo personalizado 1 del
	paso 1 del embudo: los filtros del embudo solo miran el primer paso.
	El launch data viaja en la URL y se puede compartir, así que es una señal
	aproximada, no un conteo exacto (los números exactos están en Ads Manager).
]]

local AD_PREFIX = "ad_"
local MAX_LENGTH = 40 -- launch data más largo que esto no es de una campaña nuestra

local Origen = {}

function Origen.of(player: Player): string
	local ok, data = pcall(function()
		return player:GetJoinData()
	end)
	local launch = if ok and type(data) == "table" then (data :: any).LaunchData else nil
	if
		type(launch) == "string"
		and #launch <= MAX_LENGTH
		and string.sub(launch, 1, #AD_PREFIX) == AD_PREFIX
		and string.match(launch, "^[%w_]+$") ~= nil
	then
		return `Origen - {launch}`
	end
	return "Origen - Organico"
end

return Origen
