--!strict
--[[
	TutorialCamera

	Al novato el servidor lo pasa de la plaza a la playa mirando al mar
	(Retention/TutorialSpawn), pero la cámara de Roblox conserva hacia dónde
	miraba: quedaba de frente al personaje, con el mar a sus espaldas. Cuando
	el personaje salta lejos de golpe en sus primeros segundos y todavía no
	hizo ningún paso del tutorial, la cámara se pone detrás de él, mirando
	hacia donde mira.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Protocol = require(ReplicatedStorage.Shared.Protocol)

local JUMP = 40 -- studs en un cuadro: lo movió el servidor
local WATCH_SECONDS = 40 -- tiempo después de aparecer en que se espera el salto
local BACK, UP = 14, 5 -- dónde queda la cámara respecto del personaje

local TutorialCamera = {}

local function watch(player: Player, character: Model)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root or not root:IsA("BasePart") then
		return
	end
	local last = root.Position
	local started = os.clock()
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function()
		if root.Parent == nil or os.clock() - started > WATCH_SECONDS then
			connection:Disconnect()
			return
		end
		local now = root.Position
		local jumped = (now - last).Magnitude > JUMP
		last = now
		if not jumped or player:GetAttribute(Protocol.PlayerAttributes.Tutorial) ~= 0 then
			return
		end
		connection:Disconnect()
		local look = root.CFrame.LookVector
		local camera = Workspace.CurrentCamera
		camera.CFrame = CFrame.lookAt(now - look * BACK + Vector3.new(0, UP, 0), now + look * 10)
	end)
end

function TutorialCamera.start()
	local player = Players.LocalPlayer
	player.CharacterAdded:Connect(function(character: Model)
		watch(player, character)
	end)
	if player.Character then
		task.spawn(watch, player, player.Character)
	end
end

return TutorialCamera
