--!strict
--[[
	FishingStates

	Qué hace la caña de un jugador en cada FishingState (lo publica el
	servidor): casting (brazo atrás, latigazo y el corcho vuela), training,
	waiting, bite (el corcho mordisquea y sale el "!"), caught (tirón y el
	pez salta, ver CatchShow) y escaped (el corcho se hunde). idle guarda la
	caña. Lejos (Distance "far") no se dibuja nada salvo la captura, que
	decide sola qué mostrar.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local Fx = require(script.Parent.Parent.Effects.Fx)
local Distance = require(script.Parent.Parent.Effects.Distance)
local RigParts = require(script.Parent.RigParts)
local RodRig = require(script.Parent.RodRig)

local ATTR = Protocol.PlayerAttributes

type Rig = RigParts.Rig

local FishingStates = {}

-- Ángulos del brazo (ver ArmPose): abajo, espera, atrás, latigazo, tirón.
local POSE = { rest = 0, hold = 60, windup = 158, whip = 100, pull = 118, slack = 35 }
-- Lanzamiento: brazo atrás (despacio), pausa, latigazo al frente, el corcho sale a
-- mitad del latigazo y el brazo baja a la espera.
local CAST = { windup = 0.32, pause = 0.06, whip = 0.14, release = 0.07, settle = 0.5 }
FishingStates.POSE = POSE

-- Corcho (y sedal) con el detalle que toca a este jugador.
function FishingStates.launch(player: Player, rig: Rig, target: Vector3, floating: boolean)
	RigParts.launch(rig, target, floating)
	RodRig.applyTier(player, rig)
end

local function putAway(player: Player, rig: Rig)
	RigParts.clearBobber(rig)
	RigParts.clearAlert(rig)
	local generation = rig.generation
	if rig.pose then
		rig.pose.shake(0)
		rig.pose.set(POSE.rest, 0.35)
	end
	task.delay(0.35, function()
		if rig.generation == generation then
			RodRig.stow(player, rig)
		end
	end)
end

function FishingStates.apply(player: Player, rig: Rig)
	local character = player.Character
	local state = player:GetAttribute(ATTR.FishingState)
	local target = player:GetAttribute(ATTR.FishingTarget)
	if not character or typeof(target) ~= "Vector3" or state == "idle" or state == nil then
		rig.generation += 1
		putAway(player, rig)
		return
	end
	rig.generation += 1
	local generation = rig.generation
	local visible, built = RodRig.show(player, rig, character)
	if not visible then
		-- Lejos: nada de caña ni corcho; la captura decide sola qué mostrar.
		RigParts.clearBobber(rig)
		RigParts.clearAlert(rig)
		if state == "caught" then
			RigParts.catchFish(rig, player, character, target)
		end
		return
	end
	if built then
		Sounds.play("RodOut", RigParts.headPosition(character))
	end
	local pose = rig.pose

	if state == "casting" or (state == "training" and not rig.bobber) then
		-- Lanzar: brazo atrás, latigazo y el corcho vuela. Entrenar empieza igual.
		RigParts.clearBobber(rig)
		if pose then
			pose.shake(0)
			pose.set(POSE.windup, CAST.windup, Enum.EasingStyle.Sine)
		end
		task.delay(CAST.windup + CAST.pause, function()
			if rig.generation ~= generation then
				return
			end
			if pose then
				pose.set(POSE.whip, CAST.whip, Enum.EasingStyle.Quad)
				task.delay(CAST.whip + 0.12, function()
					if rig.generation == generation then
						pose.set(POSE.hold, CAST.settle, Enum.EasingStyle.Sine)
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
			task.delay(CAST.release, function()
				if rig.generation == generation then
					FishingStates.launch(player, rig, target, false)
				end
			end)
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
			FishingStates.launch(player, rig, target, true) -- llegó tarde (entró al servidor a mitad de la pesca)
		end
	elseif state == "bite" then
		if not rig.bobber then
			FishingStates.launch(player, rig, target, true)
		end
		if rig.bobber then
			rig.bobber.setMode("nibble")
		end
		if pose then
			pose.shake(4)
		end
		RigParts.showAlert(rig, character)
		Sounds.play("Bite", target)
		if rig.rod and Distance.tier(player) == "near" then
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

return FishingStates
