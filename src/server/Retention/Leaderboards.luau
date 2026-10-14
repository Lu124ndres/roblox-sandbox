--!strict
--[[
	Leaderboards

	Ranking global de poder y de kills (OrderedDataStore). Cada
	REFRESH_SECONDS se suben los valores de los jugadores conectados y se
	leen los 10 mejores; el resultado se publica como JSON en atributos de
	ReplicatedStorage.Rankings (Poder y Kills) para que los tableros de la
	plaza lo muestren. Sin DataStore (Studio sin publicar), muestra a los
	jugadores de este servidor y se actualiza cada LOCAL_REFRESH_SECONDS.
]]

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerData = require(script.Parent.Parent.PlayerData)

local REFRESH_SECONDS = 120
local LOCAL_REFRESH_SECONDS = 10 -- sin DataStore no cuesta nada: se actualiza seguido
local TOP = 10

type Entry = { name: string, value: number }

local Leaderboards = {}

local folder = Instance.new("Folder")
folder.Name = "Rankings"

local names: { [number]: string } = {}

local function nameOf(userId: number): string
	if names[userId] then
		return names[userId]
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	names[userId] = if ok and type(name) == "string" then name else "?"
	return names[userId]
end

local function stores(): { [string]: OrderedDataStore }?
	if game.PlaceId == 0 then
		return nil
	end
	local ok, result = pcall(function()
		return {
			Poder = DataStoreService:GetOrderedDataStore("RankingPoder"),
			Kills = DataStoreService:GetOrderedDataStore("RankingKills"),
		}
	end)
	return if ok then result else nil
end

local function valueOf(player: Player, board: string): number
	local save = PlayerData.read(player)
	if not save then
		return 0
	end
	return if board == "Poder" then save.power else save.kills
end

local function localTop(board: string): { Entry }
	local list = {}
	for _, player in Players:GetPlayers() do
		table.insert(list, { name = player.DisplayName, value = valueOf(player, board) })
	end
	table.sort(list, function(a, b)
		return a.value > b.value
	end)
	return { table.unpack(list, 1, math.min(#list, TOP)) }
end

local function globalTop(store: OrderedDataStore, board: string): { Entry }?
	for _, player in Players:GetPlayers() do
		pcall(function()
			store:SetAsync(tostring(player.UserId), math.floor(valueOf(player, board)))
		end)
	end
	local ok, pages = pcall(function()
		return store:GetSortedAsync(false, TOP)
	end)
	if not ok then
		return nil
	end
	local list = {}
	for _, item in (pages :: DataStorePages):GetCurrentPage() do
		table.insert(list, { name = nameOf(tonumber(item.key) or 0), value = item.value })
	end
	return list
end

local function refresh()
	local ordered = stores()
	for _, board in { "Poder", "Kills" } do
		local list = if ordered then globalTop(ordered[board], board) else nil
		folder:SetAttribute(board, HttpService:JSONEncode(list or localTop(board)))
	end
end

function Leaderboards.init()
	folder.Parent = ReplicatedStorage
	task.spawn(function()
		while true do
			refresh()
			task.wait(if stores() then REFRESH_SECONDS else LOCAL_REFRESH_SECONDS)
		end
	end)
end

return Leaderboards
