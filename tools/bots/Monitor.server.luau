--!strict
--[[
	Monitor (pruebas con varios clientes)

	Cada 15 s escribe en el Output del servidor cómo va la prueba con bots:
	el gigante (fase, barra, etapa, enojo), cuántos jugadores hay y, de cada
	uno, peces en la canasta, monedas, poder, kills, estanque y su aporte.
	Solo corre en Studio; se mete con tools/bots/preparar.lua y se borra después.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

if not RunService:IsStudio() then
	return
end

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local GiantStages = require(ReplicatedStorage.Shared.GiantStages)

local ATTR = Protocol.PlayerAttributes
local GIANT = Protocol.GiantAttributes
local EVERY = 15

local state = ReplicatedStorage:WaitForChild(Protocol.GiantStateFolder)

local function num(instance: Instance, name: string): number
	local value = instance:GetAttribute(name)
	return if type(value) == "number" then value else 0
end

local started = os.clock()
while true do
	task.wait(EVERY)
	local progress = num(state, GIANT.Progress)
	local lines = {
		string.format(
			"[Monitor %ds] %s %s: barra %.1f%% (etapa %d), enojo %.2f, %d jugadores",
			os.clock() - started,
			tostring(state:GetAttribute(GIANT.Id)),
			tostring(state:GetAttribute(GIANT.Phase)),
			progress * 100,
			GiantStages.stageFor(progress),
			num(state, GIANT.Anger),
			#Players:GetPlayers()
		),
	}
	for _, player in Players:GetPlayers() do
		table.insert(
			lines,
			string.format(
				"   %s: canasta %d, monedas %d, poder %d, kills %d, estanque %d, aporte %.1f%%",
				player.Name,
				num(player, ATTR.CarriedFish),
				num(player, ATTR.Coins),
				num(player, ATTR.Power),
				num(player, ATTR.Kills),
				num(player, ATTR.TrainingPond),
				num(player, ATTR.Share) * 100
			)
		)
	end
	print(table.concat(lines, "\n"))
end
