--!strict
--[[
	RestDawn

	Al llenar al monstruo (despedida y descanso) el ambiente se aclara como
	si saliera el sol; al llegar el siguiente vuelve el cielo de la hora.
	blend() va de 0 a 1 suavemente: SkyCycle lo mezcla con SkyMoods.dawn.
	Lee la fase que publica el servidor (EstadoGigante.Phase).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Protocol = require(ReplicatedStorage.Shared.Protocol)

local RISE_PER_SECOND = 0.3 -- el sol tarda ~3 s en salir
local FALL_PER_SECOND = 0.2

local RestDawn = {}

local blend = 0

function RestDawn.blend(): number
	return blend
end

function RestDawn.start()
	local state: Instance? = nil
	task.spawn(function()
		state = ReplicatedStorage:WaitForChild(Protocol.GiantStateFolder)
	end)
	RunService.Heartbeat:Connect(function(dt: number)
		local phase = if state then state:GetAttribute(Protocol.GiantAttributes.Phase) else nil
		local target = if phase == "farewell" or phase == "rest" then 1 else 0
		if blend < target then
			blend = math.min(target, blend + RISE_PER_SECOND * dt)
		elseif blend > target then
			blend = math.max(target, blend - FALL_PER_SECOND * dt)
		end
	end)
end

return RestDawn
