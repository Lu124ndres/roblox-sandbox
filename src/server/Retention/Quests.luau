--!strict
--[[
	Quests

	Misiones diarias (Config/Quests; cuáles tocan hoy: QuestDay). El avance
	vive en el guardado (save.quests, SaveExtra). Los sistemas avisan con
	Quests.add(jugador, tipo, cantidad); al llegar a la meta queda cumplida y
	se avisa, pero no se paga sola: se reclama en la ventana MISIONES con
	QuestClaim(index) (pedido del usuario el 2026-10-23). index 1..n es la
	misión de ese lugar en la lista de hoy y 0 el cofre, que se reclama con
	las perDay cumplidas (la EXTRA paga igual pero el cofre no la pide). Paga
	monedas x RewardScale, sin el multiplicador de monedas de Robux, e
	impulso de poder. El cliente ve todo en el atributo Misiones (JSON), que
	se publica a lo sumo cada segundo.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local QUESTS = require(ReplicatedStorage.Shared.Config.Quests)
local RewardScale = require(ReplicatedStorage.Shared.RewardScale)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local PlayerData = require(script.Parent.Parent.PlayerData)
local RateLimit = require(script.Parent.Parent.RateLimit)
local Remotes = require(script.Parent.Parent.Remotes)
local Rewards = require(script.Parent.Parent.Social.Rewards)
local QuestDay = require(script.Parent.QuestDay)

local PUBLISH_SECONDS = 1
local CHEST = 0 -- el índice de QuestClaim que reclama el cofre
local READY_TEXT = "reclámala en MISIONES"

local Quests = {}

local dirty: { [Player]: boolean } = {}

local function coinsFor(player: Player, coins: number): number
	return math.floor(coins * RewardScale.of(player))
end

local function pay(player: Player, title: string, coins: number, boostMinutes: number?)
	local reward = {
		coins = coinsFor(player, coins),
		boostMinutes = boostMinutes,
	}
	Rewards.give(player, reward, "misiones")
	local text = Rewards.describe(reward, Config.Social.personalBoostMultiplier)
	Remotes.Notice:FireClient(player, "questClaimed", title, text)
end

-- Avance de las misiones del día de tipo `kind` (ver Config/Quests).
function Quests.add(player: Player, kind: string, amount: number)
	local save = PlayerData.read(player) :: any -- Quests es dueño de save.quests
	if not save or amount ~= amount or amount <= 0 or amount == math.huge then
		return -- NaN o infinito dejarían el avance roto
	end
	QuestDay.ensure(save)
	local state = save.quests
	local list = QuestDay.list(state.day)
	local finished = false
	for _, quest in list do
		if quest.kind == kind and not state.done[quest.id] then
			state.progress[quest.id] =
				math.min(quest.goal, (state.progress[quest.id] or 0) + amount)
			if state.progress[quest.id] >= quest.goal then
				state.done[quest.id] = true
				finished = true
				Remotes.Notice:FireClient(player, "quest", quest.text, READY_TEXT)
			end
			dirty[player] = true
		end
	end
	if finished and not state.bonus and QuestDay.allDone(state, list) then
		Remotes.Notice:FireClient(player, "quest", "¡Cofre de misiones!", READY_TEXT)
	end
end

-- QuestClaim(index): cobrar una misión cumplida o el cofre. Todo se valida aquí.
local function claim(player: Player, index: unknown)
	if type(index) ~= "number" or index % 1 ~= 0 then
		return
	end
	local save = PlayerData.read(player) :: any
	if not save then
		return
	end
	QuestDay.ensure(save) -- si cambió el día, lo de ayer ya no se cobra
	local state = save.quests
	local list = QuestDay.list(state.day)
	if index == CHEST then
		if state.bonus or not QuestDay.allDone(state, list) then
			return
		end
		state.bonus = true
		pay(player, "¡Cofre de misiones!", QUESTS.bonus.coins, QUESTS.bonus.boostMinutes)
	else
		local quest = list[index]
		if not quest or not state.done[quest.id] or state.claimed[quest.id] then
			return
		end
		state.claimed[quest.id] = true
		pay(player, quest.text, quest.coins, quest.boostMinutes)
	end
	dirty[player] = true
end

local function publish(player: Player)
	local save = PlayerData.read(player) :: any
	if not save then
		return
	end
	QuestDay.ensure(save)
	local state = save.quests
	local list = {}
	for index, quest in QuestDay.list(state.day) do
		table.insert(list, {
			text = quest.text,
			kind = quest.kind,
			progress = state.progress[quest.id] or 0,
			goal = quest.goal,
			done = state.done[quest.id] == true,
			claimed = state.claimed[quest.id] == true,
			coins = coinsFor(player, quest.coins),
			boost = quest.boostMinutes or 0,
			extra = index > QUESTS.perDay,
		})
	end
	player:SetAttribute(
		Protocol.PlayerAttributes.Quests,
		HttpService:JSONEncode({
			day = state.day,
			list = list,
			bonus = state.bonus,
			bonusCoins = coinsFor(player, QUESTS.bonus.coins),
		})
	)
end

function Quests.init()
	Remotes.QuestClaim.OnServerEvent:Connect(RateLimit.wrap("QuestClaim", 3, 5, claim))
	Players.PlayerRemoving:Connect(function(player: Player)
		dirty[player] = nil
	end)
	task.spawn(function()
		local lastDay = QuestDay.today()
		while true do
			task.wait(PUBLISH_SECONDS)
			local newDay = QuestDay.today() ~= lastDay
			lastDay = QuestDay.today()
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
