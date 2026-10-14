--!strict
--[[
	FishingController

	La pesca del jugador local: muestra el botón Pescar cuando está en la
	orilla o en un muelle, lo gira hacia el agua al lanzar, muestra el botón
	TIRA cuando pica y los avisos de resultado. No decide nada: solo pide
	CastRequest y ReelIn; el servidor valida. La caña, el corcho y el pez los
	dibuja FishingVisuals para todos los jugadores.

	En PC: E (o F) para lanzar y E (o Espacio) para recoger. Consola: X y A.
]]

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local GiantName = require(script.Parent.Parent.GiantName)
local Toasts = require(script.Parent.Parent.Toasts)
local CatchCard = require(script.Parent.CatchCard)
local FishingButtons = require(script.Parent.FishingButtons)

local COLORS = UIConfig.Colors
local CAST_ACTION = "LanzarSedal"
local REEL_ACTION = "RecogerSedal"
local CHECK_SECONDS = 0.2 -- cada cuánto se revisa si el jugador está en la orilla

local FishingController = {}

-- Misma idea que ShoreCast en el servidor, solo para mostrar el botón.
local function canFishHere(player: Player): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
		return false
	end
	if humanoid:GetState() == Enum.HumanoidStateType.Swimming then
		return false
	end
	local position = root.Position
	local radius = WorldZones.distanceToIsland(position)
	return radius >= WorldLayout.fishingBandInner
		and radius <= WorldLayout.fishingBandOuter
		and position.Y >= WorldLayout.waterLevel
		and WorldZones.distanceToCrater(position) >= WorldLayout.craterBaseRadius
		and not WorldZones.isOnBridge(position)
end

local function faceWater(player: Player, target: Vector3)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		local look = Vector3.new(target.X, root.Position.Y, target.Z)
		if (look - root.Position).Magnitude > 0.1 then
			root.CFrame = CFrame.lookAt(root.Position, look)
		end
	end
end

function FishingController.start(screen: ScreenGui, toasts: Toasts.Toasts)
	local player = Players.LocalPlayer
	local remotes = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
	local fishingUpdate = remotes:WaitForChild(Protocol.Remotes.FishingUpdate) :: RemoteEvent
	local castRequest = remotes:WaitForChild(Protocol.Remotes.CastRequest) :: RemoteEvent
	local reelIn = remotes:WaitForChild(Protocol.Remotes.ReelIn) :: RemoteEvent

	local castButton = FishingButtons.cast(screen)
	local card = CatchCard.mount(screen)
	local biteButton, timer = FishingButtons.bite(screen)
	local busy = false -- entre pedir el lanzamiento y conocer el resultado

	local function cast()
		if busy or not castButton.Visible then
			return
		end
		busy = true
		castButton.Visible = false
		Sounds.play("Click")
		castRequest:FireServer()
		task.delay(1.5, function()
			-- Si el servidor no aceptó (por ejemplo, saltando), se libera el botón.
			if busy and player:GetAttribute(Protocol.PlayerAttributes.FishingState) == "idle" then
				busy = false
			end
		end)
	end

	local function hideBite()
		biteButton.Visible = false
		ContextActionService:UnbindAction(REEL_ACTION)
	end

	local function reel()
		if not biteButton.Visible then
			return
		end
		hideBite()
		Sounds.play("Click")
		reelIn:FireServer()
	end

	local function showBite(windowSeconds: number)
		biteButton.Visible = true
		timer.Size = UDim2.new(1, 0, 0, 10)
		local info = TweenInfo.new(windowSeconds, Enum.EasingStyle.Linear)
		TweenService:Create(timer, info, { Size = UDim2.fromOffset(0, 10) }):Play()
		ContextActionService:BindActionAtPriority(
			REEL_ACTION,
			function(_, inputState: Enum.UserInputState)
				if inputState == Enum.UserInputState.Begin then
					reel()
				end
				return Enum.ContextActionResult.Sink
			end,
			false,
			Enum.ContextActionPriority.High.Value,
			Enum.KeyCode.Space,
			Enum.KeyCode.E,
			Enum.KeyCode.ButtonA
		)
	end

	castButton.Activated:Connect(cast)
	biteButton.Activated:Connect(reel)
	ContextActionService:BindAction(CAST_ACTION, function(_, inputState: Enum.UserInputState)
		if inputState == Enum.UserInputState.Begin and castButton.Visible then
			cast()
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.E, Enum.KeyCode.F, Enum.KeyCode.ButtonX)

	task.spawn(function()
		while true do
			castButton.Visible = not busy and canFishHere(player)
			task.wait(CHECK_SECONDS)
		end
	end)

	fishingUpdate.OnClientEvent:Connect(function(state: unknown, detail: unknown)
		if state == "waiting" and typeof(detail) == "Vector3" then
			faceWater(player, detail)
			toasts.show("Espera a que pique...", COLORS.TextMuted)
			return
		elseif state == "bite" then
			showBite(
				if type(detail) == "number"
					then detail
					else Config.Gameplay.fishing.reelWindowSeconds
			)
			return
		end
		hideBite()
		busy = false
		if state == "caught" then
			local info = if type(detail) == "table" then detail :: { [string]: any } else nil
			if info and type(info.id) == "string" and type(info.count) == "number" then
				card.show(info.id, info.count)
			end
		elseif state == "escaped" then
			toasts.show("Se escapó. ¡Inténtalo otra vez!", COLORS.Warning)
		elseif state == "cancelled" then
			toasts.show("Te alejaste del agua", COLORS.Warning)
		elseif state == "full" then
			toasts.show(`Carga llena: ¡lleva tus peces a {GiantName.current()}!`, COLORS.Feeding)
		end
	end)
end

return FishingController
