--!strict
--[[
	Lighthouse

	Hace girar el haz del faro. De día casi no se ve; al atardecer y de
	noche barre el mar como un faro de verdad.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local SkyCycle = require(script.Parent.SkyCycle)

local DAY_TRANSPARENCY = 0.95
local NIGHT_TRANSPARENCY = 0.55

local Lighthouse = {}

function Lighthouse.start()
	task.spawn(function()
		local map = Workspace:WaitForChild(Protocol.Map.Root, math.huge)
		local tower = map:WaitForChild(Protocol.Map.Lighthouse, math.huge)
		local beam = tower:WaitForChild(Protocol.Map.LighthouseBeam, math.huge)
		if not beam:IsA("BasePart") then
			return
		end
		-- El haz nace en la lámpara: su centro está a medio largo de ella.
		local halfLength = beam.Size.X / 2
		local lamp = beam.Position - beam.CFrame.RightVector * halfLength
		local degreesPerSecond = 360 / UIConfig.Effects.LighthouseTurnSeconds
		local angle = 0
		RunService.Heartbeat:Connect(function(dt: number)
			angle = (angle + degreesPerSecond * dt) % 360
			beam.CFrame = CFrame.new(lamp)
				* CFrame.Angles(0, math.rad(angle), math.rad(-4))
				* CFrame.new(halfLength, 0, 0)
			local night = SkyCycle.nightness(SkyCycle.currentHour())
			beam.Transparency = DAY_TRANSPARENCY + (NIGHT_TRANSPARENCY - DAY_TRANSPARENCY) * night
		end)
	end)
end

return Lighthouse
