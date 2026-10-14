--!strict
--[[
	TrainingController

	Lado cliente del entrenamiento del jugador local: lo gira hacia el
	estanque al empezar, muestra "+N poder" flotando sobre su cabeza en cada
	tick y avisa si el estanque está bloqueado. El poder lo suma el servidor.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local Toasts = require(script.Parent.Parent.Toasts)
local Purchases = require(script.Parent.Parent.Menus.Purchases)

local COLORS = UIConfig.Colors

local TrainingController = {}

local function floatingGain(character: Model, text: string, color: Color3)
	local head = character:FindFirstChild("Head")
	if not head then
		return
	end
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(120, 40)
	billboard.StudsOffset = Vector3.new(math.random(-10, 10) / 10, 2.5, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.FontFace = UIConfig.Fonts.Title
	label.TextColor3 = color
	label.TextStrokeColor3 = COLORS.TextStroke
	label.TextStrokeTransparency = 0.1
	label.Parent = billboard
	billboard.Parent = head
	local info = TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService
		:Create(billboard, info, { StudsOffset = billboard.StudsOffset + Vector3.new(0, 3, 0) })
		:Play()
	local fade =
		TweenService:Create(label, info, { TextTransparency = 1, TextStrokeTransparency = 1 })
	fade.Completed:Once(function()
		billboard:Destroy()
	end)
	fade:Play()
end

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
			floatingGain(character, `+{NumberFormat.short(gained)} poder`, COLORS.Power)
			Sounds.play("PowerTick")
		end
	end)

	denied.OnClientEvent:Connect(function(status: unknown, required: unknown, pond: unknown)
		if status == "locked" and type(required) == "number" then
			toasts.show(
				`Llena {required} {if required == 1 then "monstruo" else "monstruos"} para abrirlo, o desbloquéalo con Robux`,
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
