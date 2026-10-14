--!strict
--[[
	FishingVisuals

	Dibuja la pesca de TODOS los jugadores a partir de su atributo
	FishingState (lo publica el servidor): saca la caña, lanza con un
	latigazo del brazo, el corcho vuela y cae, tiembla cuando pica, el pez
	salta del agua hasta el jugador o el corcho se hunde si se escapa (cada
	estado en FishingStates; aquí se sigue a los jugadores y su distancia).

	Todo es local; el servidor solo dice en qué estado está cada jugador y
	dónde cae el corcho. El detalle baja con la distancia (RodRig): lejos no
	se dibuja ni caña ni corcho, y al volver a verse se saca todo sin repetir
	el lanzamiento.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Distance = require(script.Parent.Parent.Effects.Distance)
local FishingStates = require(script.Parent.FishingStates)
local RigParts = require(script.Parent.RigParts)
local RodRig = require(script.Parent.RodRig)

local ATTR = Protocol.PlayerAttributes

local POSE = FishingStates.POSE

type Rig = RigParts.Rig

local FishingVisuals = {}

local rigs: { [Player]: Rig } = {}
local connections: { [Player]: { RBXScriptConnection } } = {}

-- Cambió de nivel de detalle: lejos se guarda todo; al volver a verse se
-- saca la caña sin sonido y el corcho ya flotando.
local function retier(player: Player, tier: Distance.Tier)
	local rig = rigs[player]
	local state = player:GetAttribute(ATTR.FishingState)
	local character = player.Character
	local target = player:GetAttribute(ATTR.FishingTarget)
	if
		not rig
		or not character
		or typeof(target) ~= "Vector3"
		or state == "idle"
		or state == nil
	then
		return
	end
	if tier == "far" then
		rig.generation += 1
		RigParts.clearBobber(rig)
		RigParts.clearAlert(rig)
		RodRig.stow(player, rig)
		return
	end
	if not rig.rod then
		RodRig.show(player, rig, character)
		if rig.pose then
			rig.pose.set(POSE.hold, 0.3, Enum.EasingStyle.Sine)
		end
		if not rig.bobber and (state == "waiting" or state == "bite" or state == "training") then
			FishingStates.launch(player, rig, target, true)
		end
		if state == "bite" and rig.bobber then
			rig.bobber.setMode("nibble")
		end
	end
	RodRig.applyTier(player, rig)
end

local function release(player: Player, rig: Rig, leaving: boolean?)
	rig.generation += 1
	RigParts.clearBobber(rig)
	RigParts.clearAlert(rig)
	RodRig.release(player, rig, leaving)
end

local function track(player: Player)
	local rig: Rig = { generation = 0 }
	rigs[player] = rig
	connections[player] = {
		player:GetAttributeChangedSignal(ATTR.FishingState):Connect(function()
			FishingStates.apply(player, rig)
		end),
		-- El personaje viejo se llevó la caña y el brazo; se empieza de cero.
		player.CharacterAdded:Connect(function()
			release(player, rig)
		end),
	}
	if player:GetAttribute(ATTR.FishingState) ~= "idle" then
		FishingStates.apply(player, rig)
	end
end

function FishingVisuals.start()
	Players.PlayerAdded:Connect(track)
	Players.PlayerRemoving:Connect(function(player: Player)
		local list = connections[player]
		connections[player] = nil
		if list then
			for _, connection in list do
				connection:Disconnect()
			end
		end
		local rig = rigs[player]
		if rig then
			release(player, rig, true)
			rigs[player] = nil
		end
	end)
	Distance.onChanged(retier)
	for _, player in Players:GetPlayers() do
		track(player)
	end
end

return FishingVisuals
