--!strict
--[[
	FeedController

	Alimentar desde cualquier punto de la orilla del volcán (el borde del
	cráter, marcado con una línea coral sobre el paseo). Cuando el
	jugador está ahí y lleva peces aparece el botón Alimentar (E o F en PC, X
	en consola): se alimenta MIENTRAS se mantiene apretado. Solo avisa
	FeedRequest(true) al apretar y FeedRequest(false) al soltar: el servidor
	valida dónde está y cuánto lleva, y FeedFeedback muestra el resultado.
]]

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local FishingButtons = require(script.Parent.Parent.Fishing.FishingButtons)
local GiantName = require(script.Parent.Parent.GiantName)
local Toasts = require(script.Parent.Parent.Toasts)

local FEED_ACTION = "Alimentar"
local CHECK_SECONDS = 0.2

local FeedController = {}

local function onShore(player: Player): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
		return false
	end
	return WorldZones.isOnCraterShore(root.Position)
end

local function carrying(player: Player): number
	local value = player:GetAttribute(Protocol.PlayerAttributes.CarriedFish)
	return if type(value) == "number" then value else 0
end

function FeedController.start(screen: ScreenGui, toasts: Toasts.Toasts)
	local player = Players.LocalPlayer
	local remotes = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
	local feedRequest = remotes:WaitForChild(Protocol.Remotes.FeedRequest) :: RemoteEvent
	local stateFolder = ReplicatedStorage:WaitForChild(Protocol.GiantStateFolder)
	local button = FishingButtons.feed(screen)
	local holding = false
	local wasThere = false

	-- Se alimenta mientras se mantiene apretado (E, F, X o el botón); al soltar, para.
	local function startFeed()
		if holding or not button.Visible then
			return
		end
		holding = true
		Sounds.play("Click")
		feedRequest:FireServer(true)
	end
	local function stopFeed()
		if holding then
			holding = false
			feedRequest:FireServer(false)
		end
	end

	button.MouseButton1Down:Connect(startFeed)
	button.MouseButton1Up:Connect(stopFeed)
	button.InputEnded:Connect(function(input: InputObject)
		if
			input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1
		then
			stopFeed()
		end
	end)
	-- Se registra después de la pesca: F alimenta aquí y lanza en la playa.
	ContextActionService:BindAction(FEED_ACTION, function(_, inputState: Enum.UserInputState)
		if inputState == Enum.UserInputState.Begin and button.Visible then
			startFeed()
			return Enum.ContextActionResult.Sink
		elseif inputState ~= Enum.UserInputState.Begin and holding then
			stopFeed()
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.E, Enum.KeyCode.F, Enum.KeyCode.ButtonX)

	task.spawn(function()
		while true do
			local phase = stateFolder:GetAttribute(Protocol.GiantAttributes.Phase)
			local feeding = phase == nil or phase == "feeding"
			local there = feeding and onShore(player) and carrying(player) > 0
			button.Visible = there
			if not there then
				stopFeed()
			end
			if there and not wasThere then
				toasts.show(
					`Mantén E (o el botón) para alimentar a {GiantName.current()}`,
					UIConfig.Colors.Feeding
				)
			end
			wasThere = there
			task.wait(CHECK_SECONDS)
		end
	end)
end

return FeedController
