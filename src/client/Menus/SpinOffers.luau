--!strict
--[[
	SpinOffers

	Ayudas para la ventana de la ruleta (SpinWindow), solo para mostrar:
		percent(index, hasSuperRod)  % de la casilla para este jugador: si ya tiene la
		                    caña suprema, esa casilla no sale (0 %) y su parte se reparte
		                    entre las demás, igual que el sorteo del servidor (SpinWheel)
		prizeText(p, prize) texto de la casilla: las de monedas con la cantidad de
		                    este jugador (RewardScale, igual que el servidor), el
		                    resto su `label`
		keys / offer(key)   productos de Robux Spin1 / Spin5 (+giros guardados) con
		                    la forma de RobuxOffers.Offer; se compran con
		                    Purchases.promptProduct(key)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local RewardScale = require(ReplicatedStorage.Shared.RewardScale)
local SPIN = require(ReplicatedStorage.Shared.Config.Spin)
local RobuxOffers = require(script.Parent.RobuxOffers)

local PRODUCTS = Config.Monetization.spinProducts

local SpinOffers = {}

SpinOffers.keys = { "Spin1", "Spin5" } -- en este orden en la ventana

-- Peso de una casilla para este jugador (la misma regla que server/Retention/SpinWheel).
local function weight(prize: SPIN.Prize, hasSuperRod: boolean): number
	return if prize.kind == "rod" and hasSuperRod then 0 else prize.weight
end

-- % de la casilla `index` para quien tiene (o no) la caña suprema.
function SpinOffers.percent(index: number, hasSuperRod: boolean): number
	local prize = SPIN.prizes[index]
	local total = 0
	for _, other in SPIN.prizes do
		total += weight(other, hasSuperRod)
	end
	if not prize or total <= 0 then
		return 0
	end
	return weight(prize, hasSuperRod) / total * 100
end

function SpinOffers.prizeText(player: Player, prize: SPIN.Prize): string
	if prize.kind == "coins" then
		local coins = RewardScale.share(player, prize.coins or 0, prize.share)
		return `{NumberFormat.short(coins)} monedas`
	end
	return prize.label
end

function SpinOffers.offer(key: string): () -> RobuxOffers.Offer
	local def = PRODUCTS[key]
	return function()
		local spins = if def then def.spins else 0
		return {
			title = if spins == 1 then "+1 giro" else `+{spins} giros`,
			description = "Giros de ruleta guardados: úsalos cuando quieras",
			key = key,
			isPass = false,
			robux = if def then def.robux else 0,
		}
	end
end

return SpinOffers
