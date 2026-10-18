--!strict
--[[
	ShoreCast

	Decide si un jugador puede pescar desde donde está y dónde cae su corcho.
	Se pesca desde cualquier punto de la playa de la isla principal (no hay
	muelles): basta con estar entre fishingBandInner y fishingBandOuter del
	centro, de pie (no nadando) y a la altura de la arena o de la cubierta.
	En el cráter del gigante no se pesca.

	El corcho cae hacia donde mira el jugador si mira al mar; si no, hacia
	afuera de la isla. Nunca cae en la arena: se empuja hasta el agua.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local Proximity = require(script.Parent.Proximity)

local FISHING = Config.Gameplay.fishing
local MIN_WATER_MARGIN = 6 -- studs mar adentro desde la línea de la orilla
local FACING_THRESHOLD = 0.2 -- qué tanto tiene que mirar hacia afuera

local ShoreCast = {}

local function flat(vector: Vector3): Vector3
	return Vector3.new(vector.X, 0, vector.Z)
end

-- Devuelve la posición desde donde lanza y el punto del agua, o nil si no puede.
function ShoreCast.resolve(player: Player): (Vector3?, Vector3?)
	local root = Proximity.getRoot(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then
		return nil, nil
	end
	local state = humanoid:GetState()
	if state == Enum.HumanoidStateType.Swimming or state == Enum.HumanoidStateType.Freefall then
		return nil, nil
	end
	local position = root.Position
	local radial = flat(position)
	if
		radial.Magnitude < WorldLayout.fishingBandInner
		or radial.Magnitude > WorldLayout.fishingBandOuter
	then
		return nil, nil
	end
	if
		position.Y < WorldLayout.waterLevel
		or WorldZones.distanceToCrater(position) < WorldLayout.craterBaseRadius
		or WorldZones.isOnBridge(position) -- desde el puente no se pesca
	then
		return nil, nil
	end

	local outward = radial.Unit
	local facing = flat(root.CFrame.LookVector)
	local direction = if facing.Magnitude > 0.01
			and facing.Unit:Dot(outward) > FACING_THRESHOLD
		then facing.Unit
		else outward
	local target = flat(position) + direction * FISHING.castDistanceStuds
	local minimumRadius = WorldLayout.shoreRadius + MIN_WATER_MARGIN
	if target.Magnitude < minimumRadius then
		target += outward * (minimumRadius - target.Magnitude)
	end
	return position, Vector3.new(target.X, WorldLayout.waterLevel, target.Z)
end

-- Sigue cerca del lugar desde donde lanzó.
function ShoreCast.stillThere(player: Player, castFrom: Vector3): boolean
	local root = Proximity.getRoot(player)
	return root ~= nil and (root.Position - castFrom).Magnitude <= FISHING.maxDriftStuds
end

return ShoreCast
