--!strict
--[[
	GiantFill

	Productos que llenan al monstruo actual (25 %, 50 %, 75 % o entero). Si se
	compra mientras no está comiendo (despedida, descanso, llegada), queda en
	fila y se aplica en cuanto vuelva a comer: la compra nunca se pierde.
	Quien compra cuenta como participante (se lleva la kill si lo llena); si
	ya se fue del servidor, la comida se aplica igual.

	La fila vive en memoria, pero cada llenado está anotado como crédito en el
	guardado del comprador (Monetization/ServerCredits) hasta que se aplica: si
	el servidor cierra o el comprador sale antes, se vuelve a poner en fila en
	el servidor donde entre (Grants.restore). Al cerrar no se aplica nada: el
	guardado del cierre ya lleva el crédito y aplicarlo ahí lo duplicaría.
]]

local Players = game:GetService("Players")

local Remotes = require(script.Parent.Parent.Remotes)
local GiantService = require(script.Parent.Parent.GiantService)
local ServerCredits = require(script.Parent.ServerCredits)

local CHECK_SECONDS = 1

type Pending = { fraction: number, buyer: Player, key: string }

local GiantFill = {}

local queue: { Pending } = {}

local function apply(item: Pending): boolean
	if not GiantService.fill(item.fraction, item.buyer) then
		return false
	end
	ServerCredits.consume(item.buyer, item.key)
	Remotes.Notice:FireAllClients("fill", item.buyer.DisplayName, math.round(item.fraction * 100))
	return true
end

-- `key`: el producto (Fill25...), para borrar su crédito al aplicarlo.
function GiantFill.add(fraction: number, buyer: Player, key: string)
	local item = { fraction = fraction, buyer = buyer, key = key }
	local waiting = #queue > 0
	if waiting or not apply(item) then
		table.insert(queue, item)
		Remotes.Notice:FireClient(
			buyer,
			"purchase",
			if waiting and GiantService.isFeeding()
				then "Hay otro llenado antes que el tuyo: va justo después"
				else "El monstruo no está comiendo ahora: se llenará en cuanto vuelva a comer"
		)
	end
end

function GiantFill.init()
	-- Si el comprador sale, su llenado deja la fila: el crédito viaja en su guardado.
	Players.PlayerRemoving:Connect(function(player: Player)
		for index = #queue, 1, -1 do
			if queue[index].buyer == player then
				table.remove(queue, index)
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(CHECK_SECONDS)
			-- Uno por vez: si uno lo llena, el resto espera al siguiente monstruo.
			if queue[1] and GiantService.isFeeding() and apply(queue[1]) then
				table.remove(queue, 1)
			end
		end
	end)
end

return GiantFill
