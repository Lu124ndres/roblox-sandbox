--!strict
--[[
	Admin/AdminFun

	Órdenes del panel para animar el servidor en vivo (el admin abuse de cada
	actualización). Como AdminWorld: reciben (valor, nombre del admin, admin)
	y el admin es nil si llegan desde otro servidor (Admin/AdminGlobal).
		announce   texto: cartel grande para todos (Notice "announce"); se
		           filtra con TextService antes de mostrarlo
		fishRain   n: a cada jugador n peces con mucha suerte (hasta llenar la canasta)
		giveCoins  n: monedas a cada jugador
		giveSpins  n: giros de ruleta a cada jugador
		fireworks  fuegos artificiales sobre cada jugador (Notice "fireworks")
		unban      UserId: le quita el baneo (Admin/AdminModeration)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local FishCatalog = require(ReplicatedStorage.Shared.FishCatalog)
local PlayerData = require(script.Parent.Parent.PlayerData)
local Remotes = require(script.Parent.Parent.Remotes)
local AdminPlayer = require(script.Parent.AdminPlayer)
local AdminWorld = require(script.Parent.AdminWorld)

local MAX_TEXT = 140
local RAIN_LUCK = 4 -- +400 %: casi todo sale raro o mejor
local MAX_RAIN = 500
local MAX_COINS = 1e9
local MAX_SPINS = 50
local rng = Random.new()

local AdminFun = {}

-- Texto del anuncio sin saltos de línea ni espacios de más, filtrado por Roblox como
-- texto de `fromUserId` para todos. Si el filtro falla, no se manda nada.
function AdminFun.filter(raw: unknown, fromUserId: number): string
	assert(type(raw) == "string", "falta el texto")
	local text = string.sub((string.gsub(raw, "%s+", " ")), 1, MAX_TEXT)
	assert(#string.gsub(text, " ", "") > 0, "falta el texto")
	local ok, result = pcall(function()
		local filtered = TextService:FilterStringAsync(text, fromUserId)
		return filtered:GetNonChatStringForBroadcastAsync()
	end)
	assert(ok and type(result) == "string", "no se pudo filtrar el texto")
	return result
end

local HANDLERS: { [string]: AdminWorld.Handler } = {
	announce = function(value, by, admin)
		local text = if admin then AdminFun.filter(value, admin.UserId) else value
		assert(type(text) == "string", "falta el texto")
		Remotes.Notice:FireAllClients("announce", by, text)
		return "Anuncio enviado"
	end,
	fishRain = function(value)
		local wanted = math.floor(AdminPlayer.number(value, 1, MAX_RAIN))
		local total = 0
		for _, player in Players:GetPlayers() do
			for _ = 1, wanted do
				if PlayerData.addFish(player, FishCatalog.roll(rng, RAIN_LUCK).id, 1) == 0 then
					break
				end
				total += 1
			end
		end
		return `Lluvia de peces: {total} en total`
	end,
	giveCoins = function(value)
		local amount = math.floor(AdminPlayer.number(value, 1, MAX_COINS))
		for _, player in Players:GetPlayers() do
			PlayerData.addCoins(player, amount, "admin")
		end
		return `+{amount} monedas a todos`
	end,
	giveSpins = function(value)
		local spins = math.floor(AdminPlayer.number(value, 1, MAX_SPINS))
		for _, player in Players:GetPlayers() do
			PlayerData.edit(player, function(save)
				save.spins += spins
			end)
		end
		return `+{spins} giros a todos`
	end,
	fireworks = function()
		Remotes.Notice:FireAllClients("fireworks")
		return "Fuegos artificiales"
	end,
	unban = function(value)
		local userId = math.floor(AdminPlayer.number(value, 1, 1e15))
		local ok, err = pcall(function()
			Players:UnbanAsync({ UserIds = { userId }, ApplyToUniverse = true })
		end)
		assert(ok, `no se pudo quitar el baneo: {err}`)
		return `Baneo quitado a {userId}`
	end,
}

AdminFun.HANDLERS = table.freeze(HANDLERS)

return table.freeze(AdminFun)
