--!strict
--[[
	FeedController

	Alimentar desde cualquier punto de la orilla del volcán (el borde del
	cráter, marcado con una línea coral, y los muelles del abismo). Cuando el
	jugador está ahí y lleva peces aparece el botón Alimentar (E o F en PC, X
	en consola). Solo pide FeedRequest: el servidor valida dónde está y cuánto
	lleva, y FeedFeedback muestra el resultado.
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
local RETRY_SECONDS = 0.6 -- tras pedir, el botón se esconde un momento

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
	local waitUntil = 0
	local wasThere = false

	local function feed()
		if not button.Visible then
			return
		end
		button.Visible = false
		waitUntil = os.clock() + RETRY_SECONDS
		Sounds.play("Click")
		feedRequest:FireServer()
	end

	button.Activated:Connect(feed)
	-- Se registra después de la pesca: F alimenta aquí y lanza en la playa.
	ContextActionService:BindAction(FEED_ACTION, function(_, inputState: Enum.UserInputState)
		if inputState == Enum.UserInputState.Begin and button.Visible then
			feed()
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.E, Enum.KeyCode.F, Enum.KeyCode.ButtonX)

	task.spawn(function()
		while true do
			local phase = stateFolder:GetAttribute(Protocol.GiantAttributes.Phase)
			local feeding = phase == nil or phase == "feeding"
			local there = feeding and onShore(player) and carrying(player) > 0
			button.Visible = there and os.clock() >= waitUntil
			if there and not wasThere then
				toasts.show(
					`Alimenta a {GiantName.current()} desde cualquier punto de la orilla`,
					UIConfig.Colors.Feeding
				)
			end
			wasThere = there
			task.wait(CHECK_SECONDS)
		end
	end)
end

return FeedController
