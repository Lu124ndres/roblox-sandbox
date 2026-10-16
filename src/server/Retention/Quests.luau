--!strict
--[[
	Quests

	Misiones diarias (Config/Quests). Cada día UTC salen `perDay` misiones
	de la lista, iguales para todos (sorteadas con el día como semilla). El
	avance vive en el guardado (save.quests, SaveExtra) y se reinicia al
	cambiar el día. Los sistemas avisan con Quests.add(jugador, tipo,
	cantidad); al llegar a la meta se paga sola (monedas x RewardScale, sin el
	multiplicador de monedas de Robux, e impulso de poder) y, con las tres,
	el cofre. Además sale una EXTRA (QUESTS.extra, llenar monstruos) que paga
	igual pero el cofre no la pide: se puede jugar solo. El cliente ve todo en
	el atributo Misiones (JSON), que se publica a lo sumo cada segundo.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local QUESTS = require(ReplicatedStorage.Shared.Config.Quests)
local RewardScale = require(ReplicatedStorage.Shared.RewardScale)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local SaveExtra = require(script.Parent.Parent.Save.SaveExtra)
local PlayerData = require(script.Parent.Parent.PlayerData)
local Remotes = require(script.Parent.Parent.Remotes)
local Rewards = require(script.Parent.Parent.Social.Rewards)

local PUBLISH_SECONDS = 1

local Quests = {}

local dirty: { [Player]: boolean } = {}

local function today(): number
	return os.time() // 86400
end

-- Las misiones de un día (las mismas para todos): perDay de la lista y, al
-- final, una extra que no cuenta para el cofre (índice > perDay).
local function todays(day: number): { QUESTS.QuestDef }
	local pool = table.clone(QUESTS.pool)
	local rng = Random.new(day * 7919 + 13)
	for index = #pool, 2, -1 do
		local other = rng:NextInteger(1, index)
		pool[index], pool[other] = pool[other], pool[index]
	end
	local list = { table.unpack(pool, 1, math.min(QUESTS.perDay, #pool)) }
	if #QUESTS.extra > 0 then
		table.insert(list, QUESTS.extra[rng:NextInteger(1, #QUESTS.extra)])
	end
	return list
end

local function coinsFor(player: Player, coins: number): number
	return math.floor(coins * RewardScale.of(player))
end

local function ensure(save: any)
	if save.quests.day ~= today() then
		save.quests = SaveExtra.quests()
		save.quests.day = today()
	end
end

local function pay(player: Player, title: string, coins: number, boostMinutes: number?)
	local reward = {
		coins = coinsFor(player, coins),
		boostMinutes = boostMinutes,
	}
	Rewards.give(player, reward)
	local text = Rewards.describe(reward, Config.Social.personalBoostMultiplier)
	Remotes.Notice:FireClient(player, "quest", title, text)
end

-- Avance de las misiones del día de tipo `kind` (ver Config/Quests).
function Quests.add(player: Player, kind: string, amount: number)
	local save = PlayerData.read(player) :: any -- Quests es dueño de save.quests
	if not save or amount <= 0 then
		return
	end
	ensure(save)
	local state = save.quests
	local list = todays(state.day)
	for _, quest in list do
		if quest.kind == kind and not state.done[quest.id] then
			state.progress[quest.id] =
				math.min(quest.goal, (state.progress[quest.id] or 0) + amount)
			if state.progress[quest.id] >= quest.goal then
				state.done[quest.id] = true
				pay(player, quest.text, quest.coins, quest.boostMinutes)
			end
			dirty[player] = true
		end
	end
	if not state.bonus then
		local all = true
		for index, quest in list do
			all = all and (index > QUESTS.perDay or state.done[quest.id] == true)
		end
		if all then
			state.bonus = true
			pay(player, "¡Cofre de misiones!", QUESTS.bonus.coins, QUESTS.bonus.boostMinutes)
		end
	end
end

local function publish(player: Player)
	local save = PlayerData.read(player) :: any
	if not save then
		return
	end
	ensure(save)
	local list = {}
	for index, quest in todays(save.quests.day) do
		table.insert(list, {
			text = quest.text,
			kind = quest.kind,
			progress = save.quests.progress[quest.id] or 0,
			goal = quest.goal,
			done = save.quests.done[quest.id] == true,
			coins = coinsFor(player, quest.coins),
			boost = quest.boostMinutes or 0,
			extra = index > QUESTS.perDay,
		})
	end
	player:SetAttribute(
		Protocol.PlayerAttributes.Quests,
		HttpService:JSONEncode({
			day = save.quests.day,
			list = list,
			bonus = save.quests.bonus,
			bonusCoins = coinsFor(player, QUESTS.bonus.coins),
		})
	)
end

function Quests.init()
	Players.PlayerRemoving:Connect(function(player: Player)
		dirty[player] = nil
	end)
	task.spawn(function()
		local lastDay = today()
		while true do
			task.wait(PUBLISH_SECONDS)
			local newDay = today() ~= lastDay
			lastDay = today()
			for _, player in Players:GetPlayers() do
				local loaded = PlayerData.isLoaded(player)
				if
					loaded
					and (
						dirty[player]
						or newDay
						or player:GetAttribute(Protocol.PlayerAttributes.Quests) == nil
					)
				then
					dirty[player] = nil
					publish(player)
				end
			end
		end
	end)
end

return Quests
