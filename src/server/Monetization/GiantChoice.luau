--!strict
--[[
	GiantChoice

	Productos Choose<idGigante>: el comprador elige qué monstruo sale después
	del próximo descanso, en vez de la ruleta. Si ya hay uno elegido, el
	nuevo espera su turno (fila): cada descanso usa la primera elección.
	La primera de la fila se publica en ReplicatedStorage.Impulsos para que
	la tienda y los avisos la muestren.

	La fila vive en memoria, pero cada elección está anotada como crédito en el
	guardado del comprador (Monetization/ServerCredits) hasta que se usa: si el
	servidor cierra o el comprador sale antes, se vuelve a poner en fila en el
	servidor donde entre (Grants.restore).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local GiantPool = require(ReplicatedStorage.Shared.GiantPool)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Remotes = require(script.Parent.Parent.Remotes)
local ServerCredits = require(script.Parent.ServerCredits)

local ATTR = Protocol.BoostAttributes

type Choice = { def: Config.GiantDef, buyer: Player, buyerName: string, buyerId: number }

local GiantChoice = {}

local queue: { Choice } = {}

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
	if not def or not GiantPool.available(def) then
		return false
	end
	table.insert(
		queue,
		{ def = def, buyer = buyer, buyerName = buyer.DisplayName, buyerId = buyer.UserId }
	)
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
	ServerCredits.consume(head.buyer, `Choose{head.def.id}`)
	return head.def, head.buyerName
end

-- Si el comprador sale, su elección deja la fila: el crédito viaja en su guardado.
game:GetService("Players").PlayerRemoving:Connect(function(player: Player)
	for index = #queue, 1, -1 do
		if queue[index].buyer == player then
			table.remove(queue, index)
		end
	end
	publish()
end)

return GiantChoice
