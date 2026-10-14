--!strict
--[[
	FriendBoost

	Cuenta cuántos amigos de Roblox tiene cada jugador en este servidor y lo
	publica en su atributo AmigosEnServidor; Perks lo convierte en el
	impulso de amigos (+10 % de poder y monedas por amigo, hasta 5). Se
	recalcula cuando alguien entra o sale. IsFriendsWith se consulta una
	sola vez por pareja.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Protocol = require(ReplicatedStorage.Shared.Protocol)

local ATTR = Protocol.PlayerAttributes.FriendsInServer

local FriendBoost = {}

local pairs_: { [string]: boolean } = {} -- "menor:mayor" -> son amigos

local function key(a: Player, b: Player): string
	local low, high = math.min(a.UserId, b.UserId), math.max(a.UserId, b.UserId)
	return `{low}:{high}`
end

local function areFriends(a: Player, b: Player): boolean
	local id = key(a, b)
	if pairs_[id] == nil then
		local ok, result = pcall(function()
			return a:IsFriendsWithAsync(b.UserId)
		end)
		pairs_[id] = ok and result == true
	end
	return pairs_[id]
end

local function recount()
	local players = Players:GetPlayers()
	for _, player in players do
		local count = 0
		for _, other in players do
			if other ~= player and other.Parent and areFriends(player, other) then
				count += 1
			end
		end
		if player.Parent then
			player:SetAttribute(ATTR, count)
		end
	end
end

function FriendBoost.init()
	Players.PlayerAdded:Connect(function(player: Player)
		player:SetAttribute(ATTR, 0)
		task.spawn(recount)
	end)
	Players.PlayerRemoving:Connect(function()
		task.defer(recount)
	end)
	task.spawn(recount)
end

return FriendBoost
