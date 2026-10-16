--!strict
--[[
	TrainingController

	Lado cliente del entrenamiento del jugador local: lo gira hacia el
	estanque al empezar, muestra "+N" grande sobre su cabeza en cada tick
	(GainPopup; en la pantalla, Effects/PowerGainFx) y avisa si el estanque
	está bloqueado. El poder lo suma el servidor.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local FishingPower = require(ReplicatedStorage.Shared.FishingPower)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local Toasts = require(script.Parent.Parent.Toasts)
local Purchases = require(script.Parent.Parent.Menus.Purchases)
local PowerGainFx = require(script.Parent.Parent.Effects.PowerGainFx)
local GainPopup = require(script.Parent.GainPopup)

local COLORS = UIConfig.Colors

local TrainingController = {}

local function facePond(player: Player, pond: number)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		local target = WorldZones.pondCenter(pond)
		local look = Vector3.new(target.X, root.Position.Y, target.Z)
		if (look - root.Position).Magnitude > 0.1 then
			root.CFrame = CFrame.lookAt(root.Position, look)
		end
	end
end

function TrainingController.start(toasts: Toasts.Toasts)
	local player = Players.LocalPlayer
	local remotes = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
	local tick = remotes:WaitForChild(Protocol.Remotes.TrainingTick) :: RemoteEvent
	local denied = remotes:WaitForChild(Protocol.Remotes.TrainingDenied) :: RemoteEvent

	player:GetAttributeChangedSignal(Protocol.PlayerAttributes.TrainingPond):Connect(function()
		local pond = player:GetAttribute(Protocol.PlayerAttributes.TrainingPond)
		if type(pond) == "number" and pond > 0 then
			facePond(player, pond)
			toasts.show("Entrenando... vuelve a apretar E o aléjate para parar", COLORS.TextMuted)
		end
	end)

	tick.OnClientEvent:Connect(function(gained: unknown)
		local character = player.Character
		if character and type(gained) == "number" then
			GainPopup.show(character, gained)
			Sounds.play("PowerTick")
			PowerGainFx.gain(gained)
		end
	end)

	denied.OnClientEvent:Connect(function(status: unknown, _required: unknown, pond: unknown)
		local def = if type(pond) == "number" then Config.Progression.ponds[pond] else nil
		if status == "locked" and def and def.robuxOnly then
			toasts.show(
				"Estanque sagrado x250: desbloquéalo con Robux para siempre",
				COLORS.Warning
			)
			Purchases.promptProduct(`Pond{pond}`)
		elseif status == "locked" and def then
			toasts.show(
				`Ábrelo con {FishingPower.pondRequirement(def)}, o desbloquéalo con Robux`,
				COLORS.Warning
			)
			if type(pond) == "number" then
				Purchases.promptProduct(`Pond{pond}`)
			end
		elseif status == "busy" then
			toasts.show("Termina de pescar antes de entrenar", COLORS.Warning)
		end
	end)
end

return TrainingController
