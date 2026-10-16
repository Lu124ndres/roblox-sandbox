--!strict
--[[
	GiantTimeout

	Si el monstruo lleva Config.Giants.cycle.maxFeedMinutes comiendo sin
	llenarse (contando solo el tiempo con jugadores en el servidor), se cansa
	y se va: GiantCycle hace la despedida, paga la kill a todos los que le
	dieron algo y sigue con el descanso y la ruleta, como si se hubiera llenado.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local GiantService = require(script.Parent.Parent.GiantService)

local CHECK_SECONDS = 1

local GiantTimeout = {}

function GiantTimeout.start(onTimeout: () -> ())
	local limit = Config.Giants.cycle.maxFeedMinutes * 60
	local fed = 0 -- segundos comiendo con gente en el servidor
	task.spawn(function()
		while true do
			task.wait(CHECK_SECONDS)
			if GiantService.getPhase() ~= "feeding" or GiantService.isFull() then
				fed = 0
			elseif #Players:GetPlayers() > 0 then
				fed += CHECK_SECONDS
				if fed >= limit then
					fed = 0
					task.spawn(onTimeout)
				end
			end
		end
	end)
end

return GiantTimeout
