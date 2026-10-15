--!strict
--[[
	GiantFill

	Productos que llenan al monstruo actual (25 %, 50 %, 75 % o entero). Si se
	compra mientras no está comiendo (despedida, descanso, llegada), queda en
	fila y se aplica en cuanto vuelva a comer: la compra nunca se pierde.
	Quien compra cuenta como participante (se lleva la kill si lo llena); si
	ya se fue del servidor, la comida se aplica igual.

	Límite conocido: la fila vive solo en memoria. Al cerrar el servidor
	(BindToClose) se aplica de inmediato lo que quepa si el monstruo está
	comiendo; si está descansando, lo que quede en fila se pierde (no hay
	campo de guardado para un crédito pendiente). Las recompensas de una kill
	causada en ese cierre pueden no alcanzar a guardarse, porque SaveService
	guarda a todos en paralelo.
]]

local Remotes = require(script.Parent.Parent.Remotes)
local GiantService = require(script.Parent.Parent.GiantService)

local CHECK_SECONDS = 1

type Pending = { fraction: number, buyer: Player }

local GiantFill = {}

local queue: { Pending } = {}

local function apply(item: Pending): boolean
	if not GiantService.fill(item.fraction, item.buyer) then
		return false
	end
	Remotes.Notice:FireAllClients("fill", item.buyer.DisplayName, math.round(item.fraction * 100))
	return true
end

function GiantFill.add(fraction: number, buyer: Player)
	local item = { fraction = fraction, buyer = buyer }
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

-- Cierre del servidor: aplica en orden mientras el monstruo siga comiendo.
local function flush()
	while queue[1] and GiantService.isFeeding() and apply(queue[1]) do
		table.remove(queue, 1)
	end
	if #queue > 0 then
		warn(`GiantFill: {#queue} llenado(s) en fila sin aplicar al cerrar el servidor`)
	end
end

function GiantFill.init()
	game:BindToClose(flush)
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
