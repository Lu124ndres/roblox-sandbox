--!strict
--[[
	BridgeBoost

	El puente al volcán tiene "corriente": mientras el jugador camina sobre
	él va mucho más rápido (Config.Gameplay.bridge.walkSpeed), así llevar
	los peces al gigante y volver toma pocos segundos. La cámara se abre un
	poco para que se sienta la velocidad, y las flechas turquesa del piso
	(carpeta "Corriente" del mapa) se encienden en una onda que avanza.

	Es solo movimiento del propio personaje (el cliente ya manda en su
	física); no da ninguna ventaja que el servidor tenga que validar.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)

local BOOST_SPEED = Config.Gameplay.bridge.walkSpeed
local FOV_BOOST = 10
local WAVE_SPEED = 6 -- flechas por segundo que avanza la onda
local WAVE_LENGTH = 5 -- cada cuántas flechas se repite la onda

local BridgeBoost = {}

local function arrowsOf(map: Instance): { { part: BasePart, index: number } }
	local folder = map:FindFirstChild("Corriente", true)
	local arrows = {}
	if not folder then
		return arrows
	end
	for _, child in folder:GetChildren() do
		local index = tonumber(string.match(child.Name, "^Flecha(%d+)_"))
		if child:IsA("BasePart") and index then
			table.insert(arrows, { part = child, index = index })
		end
	end
	return arrows
end

function BridgeBoost.start()
	local player = Players.LocalPlayer
	local map = Workspace:WaitForChild(Protocol.Map.Root)
	local arrows = arrowsOf(map)
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
			humanoid.WalkSpeed = BOOST_SPEED
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
			setBoost(humanoid, WorldZones.isOnBridge(root.Position))
		end

		local wave = os.clock() * WAVE_SPEED
		for _, arrow in arrows do
			local phase = (arrow.index - wave) % WAVE_LENGTH
			arrow.part.Transparency = if phase < 1 then 0 else 0.55 + phase * 0.07
		end
	end)
end

return BridgeBoost
