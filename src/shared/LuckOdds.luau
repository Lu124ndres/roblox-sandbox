--!strict
--[[
	LuckOdds

	La suerte de pesca de un jugador y lo que significa en números: la política de
	Roblox pide explicar con números los modificadores de probabilidad que se venden
	(el VIP, las cañas de Robux, el pack de inicio) y mostrarlos mientras estén
	activos. El servidor sortea con `total` (FishingService) y el cliente muestra lo
	mismo, así el número que se ve es el del sorteo.
		total(player)          suerte de ahora: la de su caña (x3 con la caña
		                       suprema) + pases, grupo, colección y eventos
		withRod(player, level) la suerte si tuviera la caña `level` (nunca baja)
		withPass(player, key)  la suerte con ese pase (igual si ya lo tiene)
		chances(luck)          % de cada rareza con esa suerte (FishCatalog)
		text(chance)           "0.64 %": dos decimales, o los que hagan falta para no
		                       mostrar 0 en lo muy raro
]]

local Config = require(script.Parent.Config)
local FishCatalog = require(script.Parent.FishCatalog)
local Perks = require(script.Parent.Perks)
local Upgrades = require(script.Parent.Upgrades)

local PASSES = Config.Monetization.passes

local LuckOdds = {}

function LuckOdds.total(player: Player): number
	return Upgrades.rodLuck(player) + Perks.luckBonus(player)
end

function LuckOdds.withRod(player: Player, level: number): number
	return LuckOdds.total(player) - Upgrades.rodLuck(player) + Upgrades.rodLuckAt(player, level)
end

function LuckOdds.withPass(player: Player, key: string): number
	local pass = PASSES[key]
	if not pass or not pass.luck or Perks.hasPass(player, key) then
		return LuckOdds.total(player)
	end
	return LuckOdds.total(player) + pass.luck
end

function LuckOdds.chances(luck: number): { { id: string, name: string, chance: number } }
	return FishCatalog.rarityChances(luck)
end

function LuckOdds.text(chance: number): string
	if chance <= 0 then
		return "0 %"
	elseif chance >= 0.01 then
		return `{string.format("%.2f", chance)} %`
	end
	return `{string.format("%.3f", chance)} %`
end

return LuckOdds
