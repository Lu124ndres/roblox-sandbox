--!strict
--[[
	BridgeBoost

	El puente al volcán y el túnel hasta la cueva tienen "corriente": mientras
	el jugador camina por ahí va mucho más rápido (Config.Gameplay.bridge.walkSpeed), así llevar
	los peces al gigante y volver toma pocos segundos. La cámara se abre un
	poco para que se sienta la velocidad.

	Es solo movimiento del propio personaje (el cliente ya manda en su
	física); no da ninguna ventaja que el servidor tenga que validar.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)

local BOOST_SPEED = Config.Gameplay.bridge.walkSpeed
local FOV_BOOST = 10

local BridgeBoost = {}

function BridgeBoost.start()
	local player = Players.LocalPlayer
	local boosted = false
	local normalSpeed = 16
	local normalFov = 70

	local function setBoost(humanoid: Humanoid, on: boolean)
		if on == boosted then
			return
		end
		boosted = on
		local camera = Workspace.CurrentCamera
		if on then
			normalSpeed = humanoid.WalkSpeed
			normalFov = camera.FieldOfView
			humanoid.WalkSpeed = math.max(normalSpeed, BOOST_SPEED) -- nunca frena a nadie
		else
			humanoid.WalkSpeed = normalSpeed
		end
		local fov = if on then normalFov + FOV_BOOST else normalFov
		TweenService:Create(camera, TweenInfo.new(0.35), { FieldOfView = fov }):Play()
	end

	player.CharacterAdded:Connect(function()
		boosted = false
	end)

	RunService.Heartbeat:Connect(function()
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and root and root:IsA("BasePart") and humanoid.Health > 0 then
			local position = root.Position
			setBoost(humanoid, WorldZones.isOnBridge(position) or WorldZones.isInTunnel(position))
		end
	end)
end

return BridgeBoost
