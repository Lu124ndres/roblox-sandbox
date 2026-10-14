--!strict
--[[
	GiantChoice

	Productos Choose<idGigante>: el comprador elige qué monstruo sale después
	del próximo descanso, en vez de la ruleta. Si ya hay uno elegido, el
	nuevo espera su turno (fila): cada descanso usa la primera elección.
	La primera de la fila se publica en ReplicatedStorage.Impulsos para que
	la tienda y los avisos la muestren.

	Límite conocido: la fila vive solo en memoria. Si el servidor cierra con
	elecciones pendientes, se pierden (no hay campo de guardado para un
	crédito y una elección es un efecto del servidor, no del jugador). Al
	cerrar se deja constancia en la consola para poder compensar a mano.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Remotes = require(script.Parent.Parent.Remotes)

local ATTR = Protocol.BoostAttributes

type Choice = { def: Config.GiantDef, buyerName: string, buyerId: number }

local GiantChoice = {}

local queue: { Choice } = {}

game:BindToClose(function()
	for _, choice in queue do
		warn(
			`GiantChoice: elección sin usar al cerrar: {choice.def.id} de {choice.buyerName} ({choice.buyerId})`
		)
	end
end)

local function find(giantId: string): Config.GiantDef?
	for _, def in Config.Giants.chain do
		if def.id == giantId then
			return def
		end
	end
	return nil
end

local function publish()
	local folder = ReplicatedStorage:FindFirstChild(Protocol.BoostFolder)
	if not folder then
		return
	end
	local head = queue[1]
	folder:SetAttribute(ATTR.NextGiant, if head then head.def.id else "")
	folder:SetAttribute(ATTR.NextGiantBy, if head then head.buyerName else "")
	folder:SetAttribute(ATTR.ChoicesQueued, #queue)
end

-- Devuelve false si el gigante no existe o todavía no puede salir (sin modelo).
function GiantChoice.add(giantId: string, buyer: Player): boolean
	local def = find(giantId)
	if not def or not def.inRoulette then
		return false
	end
	table.insert(queue, { def = def, buyerName = buyer.DisplayName, buyerId = buyer.UserId })
	publish()
	Remotes.Notice:FireAllClients("choose", buyer.DisplayName, def.id)
	return true
end

-- La ruleta pregunta aquí primero: la elección más vieja (y quién la compró), o nil.
function GiantChoice.take(): (Config.GiantDef?, string?)
	local head = table.remove(queue, 1)
	publish()
	if not head then
		return nil, nil
	end
	return head.def, head.buyerName
end

return GiantChoice
