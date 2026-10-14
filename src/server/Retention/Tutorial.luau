--!strict
--[[
	Tutorial

	Misiones del primer minuto (Config.Retention.tutorial), en orden. Los
	servicios avisan qué hizo el jugador (Milestones) y aquí se cuenta si
	sirve para la misión actual. Cada misión paga sus monedas; al terminar
	todas, un premio extra y el logro "Tutorial". El paso se guarda; la
	cuenta dentro de un paso no (si sale a mitad, vuelve a contar).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local PlayerData = require(script.Parent.Parent.PlayerData)
local Remotes = require(script.Parent.Parent.Remotes)
local Badges = require(script.Parent.Badges)

local STEPS = Config.Retention.tutorial

local Tutorial = {}

local counts: { [Player]: number } = {}

-- El jugador hizo `amount` veces la acción `stepId`.
function Tutorial.progress(player: Player, stepId: string, amount: number)
	local save = PlayerData.read(player)
	if not save then
		return
	end
	local index = save.tutorial + 1
	local step = STEPS[index]
	if not step or step.id ~= stepId then
		return
	end
	local count = (counts[player] or 0) + amount
	counts[player] = count
	player:SetAttribute(Protocol.PlayerAttributes.TutorialCount, math.min(count, step.goal))
	if count < step.goal then
		return
	end
	counts[player] = 0
	player:SetAttribute(Protocol.PlayerAttributes.TutorialCount, 0)
	local finished = index >= #STEPS
	PlayerData.edit(player, function(data)
		data.tutorial = index
	end)
	PlayerData.addCoins(
		player,
		step.coins + (if finished then Config.Retention.tutorialBonus else 0)
	)
	Remotes.Notice:FireClient(player, "tutorial", index, step.coins)
	if finished then
		Badges.award(player, "Tutorial")
	end
end

function Tutorial.forget(player: Player)
	counts[player] = nil
end

return Tutorial
