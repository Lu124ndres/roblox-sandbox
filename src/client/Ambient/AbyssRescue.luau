--!strict
--[[
	AbyssRescue

	El lago del cráter está rodeado de acantilados: quien cae ahí no puede
	salir nadando. Si el jugador local nada en el abismo unos segundos, la
	pantalla se oscurece y aparece de vuelta en la puerta del cráter.
	En el descanso el volcán está vacío (CraterDrain): caminar en el fondo
	no cuenta, solo nadar. Con el desierto del minotauro (CraterMode "sand")
	se puede caminar por la arena un rato (SECONDS_ON_SAND), pero tampoco hay
	por dónde subir: después también se lo rescata.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local CraterMode = require(script.Parent.CraterMode)

local CHECK_SECONDS = 0.5
local SECONDS_BEFORE_RESCUE = 2.5
local SECONDS_ON_SAND = 6 -- en la arena se puede pasear un poco antes del rescate
local SAND_CEILING = WorldLayout.craterRimHeight - 6 -- más abajo, dentro del pozo

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
		local stateFolder = ReplicatedStorage:WaitForChild(Protocol.GiantStateFolder)
		local swimming = 0
		while true do
			task.wait(CHECK_SECONDS)
			local character = Players.LocalPlayer.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local drained = stateFolder:GetAttribute(Protocol.GiantAttributes.Drained) == true
			local position = if character then character:GetPivot().Position else Vector3.zero
			local inPit = character ~= nil
				and humanoid ~= nil
				and WorldZones.distanceToCrater(position) < WorldLayout.craterCliffRadius
			local swims = humanoid ~= nil and humanoid:GetState() == Enum.HumanoidStateType.Swimming
			-- nadando (o bajo el agua, si el volcán está lleno)
			local inAbyss = inPit
				and (swims or (not drained and position.Y < WorldLayout.waterLevel))
			-- parado en la arena del desierto, abajo del borde
			local onSand = inPit
				and not drained
				and CraterMode.isSand()
				and position.Y < SAND_CEILING
			swimming = if inAbyss or onSand then swimming + CHECK_SECONDS else 0
			local limit = if inAbyss then SECONDS_BEFORE_RESCUE else SECONDS_ON_SAND
			if character and swimming >= limit then
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
