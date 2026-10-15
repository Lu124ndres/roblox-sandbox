--!strict
--[[
	DailyReward

	Recompensa diaria con racha de 7 días (Config.Retention.daily). Se cobra
	una vez por día UTC con ClaimDaily; el servidor decide si toca. Si el
	último cobro fue ayer, la racha sube; si no, vuelve al día 1. Después del
	día 7 se repite el premio del día 7. El cliente ve la racha y el último
	día cobrado en los atributos DailyStreak y DailyDay.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Perks = require(ReplicatedStorage.Shared.Perks)
local RewardScale = require(ReplicatedStorage.Shared.RewardScale)
local PlayerData = require(script.Parent.Parent.PlayerData)
local RateLimit = require(script.Parent.Parent.RateLimit)
local Remotes = require(script.Parent.Parent.Remotes)

local DAILY = Config.Retention.daily

local DailyReward = {}

function DailyReward.today(): number
	return math.floor(os.time() / 86400)
end

local function claim(player: Player)
	local save = PlayerData.read(player)
	local today = DailyReward.today()
	if not save or save.daily.lastDay == today then
		return -- ya cobró hoy (o no cargó)
	end
	local streak = if save.daily.lastDay == today - 1 then save.daily.streak + 1 else 1
	local day = math.min(streak, #DAILY)
	local coins = RewardScale.share(player, DAILY[day], Config.Retention.dailyShare[day])
		* Perks.dailyMultiplier(player)
	PlayerData.edit(player, function(data)
		data.daily.lastDay = today
		data.daily.streak = streak
	end)
	PlayerData.addCoins(player, coins)
	Remotes.Notice:FireClient(player, "daily", streak, coins)
end

function DailyReward.init()
	Remotes.ClaimDaily.OnServerEvent:Connect(RateLimit.wrap("ClaimDaily", 1, 2, claim))
end

return DailyReward
