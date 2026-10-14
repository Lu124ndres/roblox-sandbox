--!strict
--[[
	Grants

	Qué entrega cada producto de Robux (claves de Assets.Products). Devuelve
	si se entregó y, para lo que es del jugador (no del servidor), el nombre
	de lo que recibió ("Poder x8", "Estanque x5", "VIP", "Caña dorada"), que
	Receipts usa para el aviso propio o el del regalo.

		Fill25/50/75      llenar al monstruo actual (avisa GiantFill)
		Choose<gigante>   elegir el siguiente monstruo (avisa GiantChoice)
		ServerBoost<n>    entrenamiento para todos (avisa ServerBoost)
		Power<n>/Coins<n> sube esa mejora a x2^n (o un nivel más si ya lo tenía)
		Pond<n>           estanque abierto para siempre
		Rod/Basket/Boots<n>  nivel n de MEJORAS (nunca baja)
		Gift<pase>        el pase, regalado (queda en el guardado)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local PlayerData = require(script.Parent.Parent.PlayerData)
local GiantChoice = require(script.Parent.GiantChoice)
local GiantFill = require(script.Parent.GiantFill)
local Passes = require(script.Parent.Passes)
local ServerBoost = require(script.Parent.ServerBoost)

local MONETIZATION = Config.Monetization
local PONDS = Config.Progression.ponds

local Grants = {}

local function raiseLevel(player: Player, key: string, bought: number): string
	local def = MONETIZATION.levels[key]
	local level = 0
	PlayerData.edit(player, function(save)
		level = math.min(math.max(save.levels[key] + 1, bought), #def.robux)
		save.levels[key] = level
	end)
	return `{def.name} x{2 ^ level}`
end

local function unlockPond(player: Player, pond: number): string
	PlayerData.edit(player, function(save)
		save.ponds[tostring(pond)] = true
	end)
	return `Estanque x{PONDS[pond].multiplier}`
end

local function raiseUpgrade(player: Player, category: Upgrades.Category, bought: number): string
	local level = math.max(Upgrades.level(player, category), bought)
	PlayerData.setUpgrade(player, category, level)
	return Upgrades.list(category)[level].name
end

local function giftPass(player: Player, key: string): string
	PlayerData.edit(player, function(save)
		save.gifts[key] = true
	end)
	Passes.grant(player, key)
	return MONETIZATION.passes[key].name
end

-- Entrega `key` a `player`. (ok, nombre de lo recibido si es algo propio).
function Grants.grant(player: Player, key: string): (boolean, string?)
	local fill = MONETIZATION.fills[key]
	if fill then
		GiantFill.add(fill.fraction, player)
		return true, nil
	end
	local giantId = string.match(key, "^Choose(.+)$")
	if giantId then
		return GiantChoice.add(giantId, player), nil
	end
	local pass = string.match(key, "^Gift(%a+)$")
	if pass and MONETIZATION.passGifts[pass] and MONETIZATION.passes[pass] then
		return true, giftPass(player, pass)
	end
	local name, number = string.match(key, "^(%a+)(%d+)$")
	local n = tonumber(number)
	if not name or not n then
		return false, nil
	end
	if name == "ServerBoost" and MONETIZATION.serverBoost.robux[n] then
		ServerBoost.add(player)
		return true, nil
	elseif MONETIZATION.levels[name] and MONETIZATION.levels[name].robux[n] then
		return true, raiseLevel(player, name, n)
	elseif name == "Pond" and PONDS[n] then
		return true, unlockPond(player, n)
	elseif Upgrades.isCategory(name) and n >= 2 and Upgrades.list(name :: any)[n] then
		return true, raiseUpgrade(player, name :: any, n)
	end
	return false, nil
end

-- ¿Este producto se puede regalar a otro jugador? (lo del servidor, no).
function Grants.giftable(key: string): boolean
	local pass = string.match(key, "^Gift(%a+)$")
	if pass then
		return MONETIZATION.passGifts[pass] ~= nil
	end
	local name, number = string.match(key, "^(%a+)(%d+)$")
	return (name == "Power" or name == "Coins" or name == "Pond") and tonumber(number) ~= nil
end

return Grants
