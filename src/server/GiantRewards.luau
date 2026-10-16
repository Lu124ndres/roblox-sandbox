--!strict
--[[
	GiantRewards

	Lo que gana el servidor con cada monstruo (GiantCycle lo llama):
		payKills  +1 kill a cada jugador conectado que le dio algo (aunque sea
		          un pez), también si se cansó de esperar y se fue
		restTick  en el descanso, todo el que esté sobre la guarida gana poder:
		          powerPerTick x su mejor estanque x el multiplicador del
		          monstruo que se llenó x su caña x sus multiplicadores
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Perks = require(ReplicatedStorage.Shared.Perks)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local GiantService = require(script.Parent.GiantService)
local PlayerData = require(script.Parent.PlayerData)
local Milestones = require(script.Parent.Retention.Milestones)
local Proximity = require(script.Parent.Proximity)
local Quests = require(script.Parent.Retention.Quests)
local Remotes = require(script.Parent.Remotes)

local TRAINING = Config.Gameplay.training

local GiantRewards = {}

-- Kills para los que aportaron y siguen en el servidor. Devuelve sus userIds.
function GiantRewards.payKills(giantId: string): { [number]: boolean }
	local paid: { [number]: boolean } = {}
	for _, userId in GiantService.getParticipants() do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			PlayerData.addKill(player, giantId)
			Milestones.killed(player)
			Quests.add(player, "kill", 1)
			paid[userId] = true
		end
	end
	return paid
end

function GiantRewards.restTick()
	for _, player in Players:GetPlayers() do
		local root = Proximity.getRoot(player)
		if root and PlayerData.isLoaded(player) and WorldZones.isInRestArena(root.Position) then
			local best = Perks.bestPondMultiplier(player)
			local rod = Upgrades.current(player, "Rod").value
			local gained = math.round(
				TRAINING.powerPerTick
					* best
					* GiantService.getCurrent().multiplier
					* rod
					* Perks.powerMultiplier(player)
			)
			PlayerData.addPower(player, gained)
			Remotes.TrainingTick:FireClient(player, gained)
			Quests.add(player, "train", TRAINING.tickSeconds)
		end
	end
end

return GiantRewards
