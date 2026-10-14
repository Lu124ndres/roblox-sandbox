--!strict
--[[
	AbyssRescue

	El lago del cráter está rodeado de acantilados: quien cae ahí no puede
	salir nadando. Si el jugador local nada en el abismo unos segundos, la
	pantalla se oscurece y aparece de vuelta en la puerta del cráter.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)

local CHECK_SECONDS = 0.5
local SECONDS_BEFORE_RESCUE = 2.5

local AbyssRescue = {}

-- Sobre el anillo, frente a la puerta, mirando al gigante.
local function gatePosition(): CFrame
	local toIsland = Vector3.new(
		-math.cos(math.rad(WorldLayout.bridgeAngle)),
		0,
		-math.sin(math.rad(WorldLayout.bridgeAngle))
	)
	local spot = WorldZones.craterCenter
		+ toIsland * (WorldLayout.craterCliffRadius + 8)
		+ Vector3.new(0, WorldLayout.craterRimHeight + 4, 0)
	return CFrame.lookAt(
		spot,
		Vector3.new(WorldZones.craterCenter.X, spot.Y, WorldZones.craterCenter.Z)
	)
end

local function fade(screen: ScreenGui, transparency: number, seconds: number)
	local cover = screen:FindFirstChild("Cortina")
	if cover and cover:IsA("Frame") then
		local tween = TweenService:Create(
			cover,
			TweenInfo.new(seconds),
			{ BackgroundTransparency = transparency }
		)
		tween:Play()
		tween.Completed:Wait()
	end
end

function AbyssRescue.start(screen: ScreenGui)
	local cover = Instance.new("Frame")
	cover.Name = "Cortina"
	cover.Size = UDim2.fromScale(1, 1)
	cover.Position = UDim2.fromScale(0, 0)
	cover.BackgroundColor3 = Color3.new(0, 0, 0)
	cover.BackgroundTransparency = 1
	cover.ZIndex = 50
	cover.Parent = screen

	task.spawn(function()
		local swimming = 0
		while true do
			task.wait(CHECK_SECONDS)
			local character = Players.LocalPlayer.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local inAbyss = character ~= nil
				and humanoid ~= nil
				and WorldZones.distanceToCrater(character:GetPivot().Position) < WorldLayout.craterCliffRadius
				-- nadando (la guarida del descanso está apenas sobre el agua: ahí no se rescata)
				and (
					humanoid:GetState() == Enum.HumanoidStateType.Swimming
					or character:GetPivot().Position.Y < WorldLayout.waterLevel
				)
			swimming = if inAbyss then swimming + CHECK_SECONDS else 0
			if character and swimming >= SECONDS_BEFORE_RESCUE then
				swimming = 0
				fade(screen, 0, 0.4)
				character:PivotTo(gatePosition())
				task.wait(0.2)
				fade(screen, 1, 0.6)
			end
		end
	end)
end

return AbyssRescue
