--!strict
--[[
	Rewards

	Premios de códigos y del regalo del grupo: monedas y minutos de impulso
	personal de poder (x Config.Social.personalBoostMultiplier). Si ya tenía
	impulso, los minutos se suman al que le queda.
]]

local PlayerData = require(script.Parent.Parent.PlayerData)

export type Reward = { coins: number?, boostMinutes: number? }

local Rewards = {}

-- source: de dónde vienen las monedas, para la telemetría ("misiones", "ruleta"...).
function Rewards.give(player: Player, reward: Reward, source: string?)
	if reward.coins and reward.coins > 0 then
		PlayerData.addCoins(player, reward.coins, source)
	end
	local minutes = reward.boostMinutes
	if minutes and minutes > 0 then
		PlayerData.edit(player, function(save)
			save.boostUntil = math.max(save.boostUntil, os.time()) + math.floor(minutes * 60)
		end)
	end
end

-- "+500 monedas y 15 min de x2 poder" (para los avisos).
function Rewards.describe(reward: Reward, multiplier: number): string
	local parts = {}
	if reward.coins and reward.coins > 0 then
		table.insert(parts, `+{reward.coins} monedas`)
	end
	if reward.boostMinutes and reward.boostMinutes > 0 then
		table.insert(parts, `{reward.boostMinutes} min de x{multiplier} poder`)
	end
	return table.concat(parts, " y ")
end

return Rewards
