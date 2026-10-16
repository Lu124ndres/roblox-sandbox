--!strict
--[[
	RetentionBonus

	Ventajas por volver y por la ruleta, leídas de atributos que solo pone el
	servidor (servidor y cliente calculan igual; Perks las multiplica):
		DailyStreak / DailyDay   racha del diario: +perDay de monedas y poder
		                         por día seguido, hasta maxDays (Config.Retention.streakBonus).
		                         Si el último cobro fue antes de ayer, la racha
		                         ya se cortó y no da nada hasta que vuelva a cobrar.
		MonedasX2Hasta           premio coinBoost de la ruleta: x coinBoostMultiplier monedas
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local SPIN = require(ReplicatedStorage.Shared.Config.Spin)

local ATTR = Protocol.PlayerAttributes
local STREAK = Config.Retention.streakBonus

local RetentionBonus = {}

local function number(player: Player, attribute: string): number
	local value = player:GetAttribute(attribute)
	return if type(value) == "number" then value else 0
end

-- Día UTC (mismo cálculo que server/Retention/DailyReward).
function RetentionBonus.today(): number
	return math.floor(Workspace:GetServerTimeNow() / 86400)
end

-- Días de racha que cuentan hoy (0 si se cortó: el último cobro fue antes de ayer).
function RetentionBonus.streakDays(player: Player): number
	if number(player, ATTR.DailyDay) < RetentionBonus.today() - 1 then
		return 0
	end
	return number(player, ATTR.DailyStreak)
end

-- Fracción extra por una racha de `days` días (0.1 por día, hasta 1 = +100%).
function RetentionBonus.streakBonus(days: number): number
	return math.min(math.max(days, 0), STREAK.maxDays) * STREAK.perDay
end

-- x(1 + bonus de racha): se aplica a las monedas y al poder.
function RetentionBonus.streakMultiplier(player: Player): number
	return 1 + RetentionBonus.streakBonus(RetentionBonus.streakDays(player))
end

-- Segundos que le quedan al x2 monedas de la ruleta (0 = no tiene).
function RetentionBonus.coinBoostSeconds(player: Player): number
	return math.max(0, number(player, ATTR.CoinBoostUntil) - Workspace:GetServerTimeNow())
end

function RetentionBonus.coinMultiplier(player: Player): number
	local boost = if RetentionBonus.coinBoostSeconds(player) > 0
		then SPIN.coinBoostMultiplier
		else 1
	return RetentionBonus.streakMultiplier(player) * boost
end

function RetentionBonus.powerMultiplier(player: Player): number
	return RetentionBonus.streakMultiplier(player)
end

return RetentionBonus
