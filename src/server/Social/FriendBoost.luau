--!strict
--[[
	FriendBoost

	Cuenta cuántos amigos de Roblox tiene cada jugador en este servidor y lo
	publica en su atributo AmigosEnServidor; Perks lo convierte en el
	impulso de amigos (Config.Social.friendBoost: tanto por amigo, con tope).

	Al entrar alguien se pide UNA vez su lista de amigos (GetFriendsAsync,
	por páginas, con reintentos) y se cruza con quienes están presentes. Las
	parejas viven en un conjunto simétrico: al salir alguien se quitan las
	suyas y se recuenta solo a sus amigos. Una pareja cuenta si aparece en la
	lista de cualquiera de los dos, así que si la lista de uno falla, la del
	otro la cubre. Los fallos nunca se guardan como "no son amigos".
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Protocol = require(ReplicatedStorage.Shared.Protocol)

local ATTR = Protocol.PlayerAttributes.FriendsInServer
local ATTEMPTS = 3
local BACKOFF_SECONDS = 1 -- espera tras el 1.er fallo; se duplica en cada reintento
local MAX_PAGES = 30 -- tope de páginas por lista (cuentas con miles de amigos)

type IdSet = { [number]: boolean }

local FriendBoost = {}

local present: { [number]: Player } = {} -- UserId -> sesión actual (descarta respuestas viejas)
local friendLists: { [number]: IdSet } = {} -- solo las listas que sí se pudieron leer
local links: { [number]: IdSet } = {} -- parejas de amigos presentes, en los dos sentidos

-- Llama a fn con reintentos y espera creciente. Devuelve nil si nunca funcionó.
local function retry(fn: () -> any): any
	for attempt = 1, ATTEMPTS do
		local ok, result = pcall(fn)
		if ok then
			return result
		end
		if attempt < ATTEMPTS then
			task.wait(BACKOFF_SECONDS * 2 ^ (attempt - 1))
		end
	end
	return nil
end

-- Ids de los amigos de un usuario, o nil si Roblox no respondió.
local function fetchFriends(userId: number): IdSet?
	local pages: FriendPages? = retry(function()
		return Players:GetFriendsAsync(userId)
	end)
	if not pages then
		return nil
	end
	local ids: IdSet = {}
	for _ = 1, MAX_PAGES do
		for _, item in pages:GetCurrentPage() do
			if type(item.Id) == "number" then
				ids[item.Id] = true
			end
		end
		if pages.IsFinished then
			break
		end
		local advanced = retry(function()
			pages:AdvanceToNextPageAsync()
			return true
		end)
		if not advanced then
			break -- lo leído hasta aquí sigue siendo cierto
		end
	end
	return ids
end

local function publish(userId: number)
	local player = present[userId]
	if not player then
		return
	end
	local own: IdSet = links[userId] or {}
	local count = 0
	for _ in own do
		count += 1
	end
	player:SetAttribute(ATTR, count)
end

local function listed(owner: number, friend: number): boolean
	local list = friendLists[owner]
	return list ~= nil and list[friend] == true
end

-- Une al usuario con cada presente que figure en la lista de alguno de los dos.
local function linkPresent(userId: number)
	local own = links[userId]
	if not own then
		return
	end
	for otherId in present do
		if otherId ~= userId and not own[otherId] then
			if listed(userId, otherId) or listed(otherId, userId) then
				own[otherId] = true
				local theirs = links[otherId]
				if theirs then
					theirs[userId] = true
				end
				publish(otherId)
			end
		end
	end
	publish(userId)
end

local function onJoin(player: Player)
	local userId = player.UserId
	present[userId] = player
	links[userId] = {}
	player:SetAttribute(ATTR, 0)
	linkPresent(userId) -- con las listas de quienes ya estaban
	local list = fetchFriends(userId)
	if present[userId] ~= player then
		return -- se fue (o volvió a entrar) mientras se pedía la lista
	end
	if list then
		friendLists[userId] = list
		linkPresent(userId)
	end
end

local function onLeave(player: Player)
	local userId = player.UserId
	if present[userId] ~= player then
		return
	end
	present[userId] = nil
	friendLists[userId] = nil
	local own: IdSet = links[userId] or {}
	links[userId] = nil
	for otherId in own do
		local theirs = links[otherId]
		if theirs then
			theirs[userId] = nil
		end
		publish(otherId)
	end
end

function FriendBoost.init()
	Players.PlayerAdded:Connect(onJoin)
	Players.PlayerRemoving:Connect(onLeave)
	for _, player in Players:GetPlayers() do
		task.spawn(onJoin, player)
	end
end

return FriendBoost
