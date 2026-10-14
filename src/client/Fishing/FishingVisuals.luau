--!strict
--[[
	FishingVisuals

	Dibuja la pesca de TODOS los jugadores a partir de su atributo
	FishingState (lo publica el servidor): saca la caña, lanza con un
	latigazo del brazo, el corcho vuela y cae, tiembla cuando pica, el pez
	salta del agua hasta el jugador o el corcho se hunde si se escapa.

	Todo es local y a 60 fps; el servidor solo dice en qué estado está cada
	jugador y dónde cae el corcho.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local Fx = require(script.Parent.Parent.Effects.Fx)
local ArmPose = require(script.Parent.ArmPose)
local Rod = require(script.Parent.Rod)
local RigParts = require(script.Parent.RigParts)

local ATTR = Protocol.PlayerAttributes

-- Ángulos del brazo (ver ArmPose): abajo, espera, atrás, latigazo, tirón.
local POSE = { rest = 0, hold = 60, windup = 150, whip = 72, pull = 118, slack = 35 }

type Rig = RigParts.Rig

local FishingVisuals = {}

local rigs: { [Player]: Rig } = {}

local function ensureRod(rig: Rig, character: Model)
	if not rig.pose then
		rig.pose = ArmPose.new(character)
	end
	if not rig.rod then
		local owner = Players:GetPlayerFromCharacter(character)
		rig.rod = Rod.attach(character, if owner then Upgrades.level(owner, "Rod") else 1)
		Sounds.play("RodOut", RigParts.headPosition(character))
		rig.follow = RunService.RenderStepped:Connect(function()
			if rig.rod then
				rig.rod.follow(if rig.pose then rig.pose.angle() else 60)
			end
		end)
	end
end

local function putAway(rig: Rig)
	RigParts.clearBobber(rig)
	RigParts.clearAlert(rig)
	local generation = rig.generation
	if rig.pose then
		rig.pose.shake(0)
		rig.pose.set(POSE.rest, 0.35)
	end
	task.delay(0.35, function()
		if rig.generation == generation then
			RigParts.dropRod(rig)
		end
	end)
end

local function apply(player: Player, rig: Rig)
	local character = player.Character
	local state = player:GetAttribute(ATTR.FishingState)
	local target = player:GetAttribute(ATTR.FishingTarget)
	if not character or typeof(target) ~= "Vector3" or state == "idle" or state == nil then
		rig.generation += 1
		putAway(rig)
		return
	end
	rig.generation += 1
	local generation = rig.generation
	ensureRod(rig, character)
	local pose = rig.pose

	if state == "casting" or (state == "training" and not rig.bobber) then
		-- Lanzar: brazo atrás, latigazo y el corcho vuela. Entrenar empieza igual.
		RigParts.clearBobber(rig)
		if pose then
			pose.shake(0)
			pose.set(POSE.windup, 0.22)
		end
		task.delay(0.24, function()
			if rig.generation ~= generation then
				return
			end
			if pose then
				pose.set(POSE.whip, 0.12, Enum.EasingStyle.Back)
				task.delay(0.5, function()
					if rig.generation == generation and state == "training" then
						pose.set(POSE.hold, 0.6, Enum.EasingStyle.Sine)
					end
				end)
			end
			local rod = rig.rod
			if rod then
				rod.trail.Enabled = true
				task.delay(0.35, function()
					rod.trail.Enabled = false
				end)
			end
			Sounds.play("Cast", RigParts.headPosition(character))
			RigParts.launch(rig, target, false)
		end)
	elseif state == "training" then
		if pose then
			pose.shake(0)
			pose.set(POSE.hold, 0.5, Enum.EasingStyle.Sine)
		end
	elseif state == "waiting" then
		if pose then
			pose.shake(0)
			pose.set(POSE.hold, 0.5, Enum.EasingStyle.Sine)
		end
		if not rig.bobber then
			RigParts.launch(rig, target, true) -- llegó tarde (entró al servidor a mitad de la pesca)
		end
	elseif state == "bite" then
		if not rig.bobber then
			RigParts.launch(rig, target, true)
		end
		if rig.bobber then
			rig.bobber.setMode("nibble")
		end
		if pose then
			pose.shake(4)
		end
		RigParts.showAlert(rig, character)
		Sounds.play("Bite", target)
		if rig.rod then
			Fx.sparkle(rig.rod.tip.WorldPosition, UIConfig.Colors.Coins, 10)
		end
	elseif state == "caught" then
		RigParts.clearAlert(rig)
		if pose then
			pose.shake(0)
			pose.set(POSE.pull, 0.16, Enum.EasingStyle.Back)
		end
		Sounds.play("Reel", RigParts.headPosition(character))
		RigParts.catchFish(rig, player, character, target)
	elseif state == "escaped" then
		RigParts.clearAlert(rig)
		if pose then
			pose.shake(0)
			pose.set(POSE.slack, 0.6, Enum.EasingStyle.Sine)
		end
		if rig.bobber then
			rig.bobber.setMode("sinking")
		end
		Sounds.play("Escape", target)
	end
end

local function track(player: Player)
	local rig: Rig = { generation = 0 }
	rigs[player] = rig
	player:GetAttributeChangedSignal(ATTR.FishingState):Connect(function()
		apply(player, rig)
	end)
	player.CharacterAdded:Connect(function()
		-- El personaje viejo se llevó la caña y el brazo; se empieza de cero.
		rig.generation += 1
		RigParts.clearBobber(rig)
		RigParts.clearAlert(rig)
		RigParts.dropRod(rig)
	end)
	if player:GetAttribute(ATTR.FishingState) ~= "idle" then
		apply(player, rig)
	end
end

function FishingVisuals.start()
	Players.PlayerAdded:Connect(track)
	Players.PlayerRemoving:Connect(function(player: Player)
		local rig = rigs[player]
		if rig then
			rig.generation += 1
			RigParts.clearBobber(rig)
			RigParts.clearAlert(rig)
			RigParts.dropRod(rig)
			rigs[player] = nil
		end
	end)
	for _, player in Players:GetPlayers() do
		track(player)
	end
end

return FishingVisuals
