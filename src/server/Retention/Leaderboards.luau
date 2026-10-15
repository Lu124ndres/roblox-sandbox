--!strict
--[[
	Leaderboards

	Ranking global de poder, de kills y de renacimientos (OrderedDataStore). Cada
	REFRESH_SECONDS se suben los valores de los jugadores conectados (solo
	los que ya cargaron sus datos y cuyo valor cambió desde la última
	escritura) y se leen los 10 mejores; el resultado se publica como JSON en atributos de
	ReplicatedStorage.Rankings (Poder, Kills y Renacimientos) para que los
	tableros de la entrada lo muestren. Sin DataStore (Studio sin publicar), muestra a los
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
-- Último valor escrito por tablero y jugador: si no cambió, no se gasta una escritura.
local BOARDS = { "Poder", "Kills", "Renacimientos" }
local lastWritten: { [string]: { [number]: number } } =
	{ Poder = {}, Kills = {}, Renacimientos = {} }

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
			Renacimientos = DataStoreService:GetOrderedDataStore("RankingRenacimientos"),
		}
	end)
	return if ok then result else nil
end

-- nil si sus datos todavía no cargaron: un 0 falso no se muestra ni se sube.
local function valueOf(player: Player, board: string): number?
	local save = PlayerData.read(player)
	if not save then
		return nil
	end
	local value = if board == "Poder"
		then save.power
		elseif board == "Kills" then save.kills
		else save.rebirths
	return math.floor(value)
end

local function localTop(board: string): { Entry }
	local list = {}
	for _, player in Players:GetPlayers() do
		local value = valueOf(player, board)
		if value then
			table.insert(list, { name = player.DisplayName, value = value })
		end
	end
	table.sort(list, function(a, b)
		return a.value > b.value
	end)
	return { table.unpack(list, 1, math.min(#list, TOP)) }
end

local function globalTop(store: OrderedDataStore, board: string): { Entry }?
	local written = lastWritten[board]
	for _, player in Players:GetPlayers() do
		local value = valueOf(player, board)
		local userId = player.UserId
		if value and written[userId] ~= value then
			local ok = pcall(function()
				store:SetAsync(tostring(userId), value)
			end)
			if ok then
				written[userId] = value
			end
		end
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
	for _, board in BOARDS do
		local list = if ordered then globalTop(ordered[board], board) else nil
		folder:SetAttribute(board, HttpService:JSONEncode(list or localTop(board)))
	end
end

function Leaderboards.init()
	folder.Parent = ReplicatedStorage
	Players.PlayerRemoving:Connect(function(player: Player)
		for _, written in lastWritten do
			written[player.UserId] = nil
		end
	end)
	task.spawn(function()
		while true do
			refresh()
			task.wait(if stores() then REFRESH_SECONDS else LOCAL_REFRESH_SECONDS)
		end
	end)
end

return Leaderboards
