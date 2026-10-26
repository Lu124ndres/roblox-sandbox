--!strict
--[[
	ServerCredits

	Las compras para todo el servidor (Choose<gigante>, Fill<n>) esperan en una
	fila en memoria hasta que se pueden aplicar. Para que no se pierdan si el
	servidor cierra antes (riesgo visto el 2026-10-26), cada una se anota en
	el guardado de quien pagó (save.serverCredits) al entregarse y se borra
	cuando de verdad se aplica (GiantChoice.take, GiantFill). Si el comprador
	sale con algo en la fila, se quita de la fila y el crédito viaja con él:
	al entrar a otro servidor se vuelve a poner en fila (Grants.restore, desde
	Receipts). El crédito es la única verdad; la fila solo refleja a los que
	están en este servidor.
]]

local PlayerData = require(script.Parent.Parent.PlayerData)

local ServerCredits = {}

function ServerCredits.add(player: Player, key: string)
	PlayerData.edit(player, function(save)
		table.insert(save.serverCredits, key)
	end)
end

-- Ya se aplicó: se borra uno con esa clave (si el comprador sigue aquí).
function ServerCredits.consume(player: Player, key: string)
	if not player.Parent then
		return
	end
	PlayerData.edit(player, function(save)
		local index = table.find(save.serverCredits, key)
		if index then
			table.remove(save.serverCredits, index)
		end
	end)
end

-- Las que tiene pendientes al entrar (copia).
function ServerCredits.pending(player: Player): { string }
	local save = PlayerData.read(player)
	return if save then table.clone(save.serverCredits) else {}
end

return ServerCredits
