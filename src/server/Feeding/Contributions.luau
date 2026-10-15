--!strict
--[[
	Contributions

	Cuánta comida aportó cada jugador (por userId) al gigante actual, peces y
	llenados con Robux. Al llenarse, la kill es para quien aportó al menos
	scaling.minKillShare de la barra O una canasta suya casi llena
	(BASKET_SHARE de su capacidad, contando 1 de comida por pez): con barras
	de millones, un novato que entrega su canasta completa también cuenta.
	Tirar un pez no alcanza.

	publish: cada PUBLISH_SECONDS como mucho, el top 3 (atributo TopAportes
	del gigante, JSON [{n = nombre, s = fracción}]) y el aporte de cada uno
	(atributo Aporte del jugador, fracción de la barra) para la fila de
	aportes del panel (client/Interface/ShareLine).
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local FishingPower = require(ReplicatedStorage.Shared.FishingPower)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local GiantPublish = require(script.Parent.GiantPublish)

local SCALING = Config.Giants.scaling
local BASKET_SHARE = 0.8
local PUBLISH_SECONDS = 1
local TOP = 3

local Contributions = {}

local foodByUser: { [number]: number } = {}
local lastPublish = 0
local pending = false

function Contributions.add(userId: number, food: number)
	foodByUser[userId] = (foodByUser[userId] or 0) + math.max(0, food)
end

-- Gigante nuevo: nadie aportó nada todavía.
function Contributions.reset()
	table.clear(foodByUser)
	for _, player in Players:GetPlayers() do
		player:SetAttribute(Protocol.PlayerAttributes.Share, 0)
	end
	GiantPublish.set(Protocol.GiantAttributes.TopShares, "[]")
end

-- userIds que se llevan la kill (ver arriba).
function Contributions.participants(totalFood: number): { number }
	local needed = SCALING.minKillShare * totalFood
	local list = {}
	for userId, food in foodByUser do
		local player = Players:GetPlayerByUserId(userId)
		local basket = if player
			then FishingPower.playerCapacity(player) * BASKET_SHARE
			else math.huge
		if food >= math.min(needed, basket) then
			table.insert(list, userId)
		end
	end
	return list
end

local function publishNow(totalFood: number)
	lastPublish = os.clock()
	local ranking = {}
	for userId, food in foodByUser do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			local share = food / math.max(totalFood, 1)
			player:SetAttribute(Protocol.PlayerAttributes.Share, share)
			table.insert(ranking, { n = player.DisplayName, s = share })
		end
	end
	table.sort(ranking, function(a, b)
		return a.s > b.s
	end)
	local top = {}
	for index = 1, math.min(TOP, #ranking) do
		top[index] = ranking[index]
	end
	GiantPublish.set(Protocol.GiantAttributes.TopShares, HttpService:JSONEncode(top))
end

-- Publica el top y los aportes, a lo sumo cada PUBLISH_SECONDS (el último gana).
function Contributions.publish(totalFood: number)
	local wait = PUBLISH_SECONDS - (os.clock() - lastPublish)
	if wait <= 0 then
		publishNow(totalFood)
	elseif not pending then
		pending = true
		task.delay(wait, function()
			pending = false
			publishNow(totalFood)
		end)
	end
end

return Contributions
