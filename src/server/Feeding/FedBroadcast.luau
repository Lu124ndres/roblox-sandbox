--!strict
--[[
	FedBroadcast

	Lo que ven los clientes cuando alguien alimenta al gigante. En vez de un
	GiantFed por pez, junta lo entregado por cada jugador y lo manda en UN
	evento a lo sumo cada delivery.broadcastSeconds:

		GiantFed:FireAllClients({ { userId, count, fishId }, ... })

	fishId es la especie más rara de ese jugador en el lote (la que se dibuja
	volando). Es un RemoteEvent confiable: con 40-50 jugadores dando de comer
	a la vez el lote pasa del límite de ~900 bytes de UnreliableRemoteEvent.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local FishCatalog = require(ReplicatedStorage.Shared.FishCatalog)
local Remotes = require(script.Parent.Parent.Remotes)

type Pending = { count: number, fishId: string, level: number }

local DELIVERY = Config.Giants.delivery

local FedBroadcast = {}

local pending: { [number]: Pending } = {}
local scheduled = false
local lastFlush = 0

local function flush()
	scheduled = false
	lastFlush = os.clock()
	local batch = {}
	for userId, entry in pending do
		table.insert(batch, { userId = userId, count = entry.count, fishId = entry.fishId })
	end
	table.clear(pending)
	if #batch > 0 then
		Remotes.GiantFed:FireAllClients(batch)
	end
end

-- Anota `count` peces que `userId` entregó (fishId = la especie más rara del lote).
function FedBroadcast.add(userId: number, count: number, fishId: string)
	if count <= 0 then
		return
	end
	local _, level = FishCatalog.rarity(fishId)
	local entry = pending[userId]
	if not entry then
		pending[userId] = { count = count, fishId = fishId, level = level }
	else
		entry.count += count
		if level > entry.level then
			entry.fishId, entry.level = fishId, level
		end
	end
	if not scheduled then
		scheduled = true
		-- Si hace rato que no se manda nada (recién empezó a alimentar), sale ya: el
		-- primer pez vuela sin esperar. Después, a lo sumo uno cada broadcastSeconds.
		local wait = math.max(0, DELIVERY.broadcastSeconds - (os.clock() - lastFlush))
		if wait <= 0 then
			task.defer(flush)
		else
			task.delay(wait, flush)
		end
	end
end

return FedBroadcast
