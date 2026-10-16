--!strict
--[[
	RestArena

	El descanso es en el fondo del volcán. La guarida (world/GuaridaDescanso.model.json,
	en ServerStorage) llena el fondo de pared a pared y queda ENTERRADA
	(restArenaSink studs más abajo) mientras se alimenta al gigante. Al empezar el
	descanso sube a su lugar y se publica VolcanVacio = true: cada cliente vacía el
	lago (Ambient/CraterDrain, en Config.Giants.cycle.drainSeconds) y la ve subir
	desde el fondo (Ambient/GuaridaSube; aquí se mueve de una vez, allá se anima);
	el botón IR A LA GUARIDA (enter) deja al jugador sobre ella cuando ya no hay
	agua. Al terminar, quien siga dentro del volcán vuelve a la orilla, junto a
	la puerta donde llega el puente, y el agua sube de nuevo con el siguiente
	monstruo.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local GiantPublish = require(script.Parent.Feeding.GiantPublish)
local Proximity = require(script.Parent.Proximity)

local RestArena = {}

local SINK = Vector3.new(0, -WorldLayout.restArenaSink, 0)

local arena: Model? = nil
local up = false
local drainedAt = 0
local rng = Random.new()

-- Orilla junto a la puerta del puente, mirando al centro (un poco repartidos).
local function gateSpot(): CFrame
	local angle = math.rad(WorldLayout.bridgeAngle + 180) + rng:NextNumber(-0.12, 0.12)
	local spot = WorldZones.craterCenter
		+ Vector3.new(math.cos(angle), 0, math.sin(angle)) * (WorldLayout.craterCliffRadius + rng:NextNumber(
			6,
			14
		))
		+ Vector3.new(0, WorldLayout.craterRimHeight + 3, 0)
	return CFrame.lookAt(
		spot,
		Vector3.new(WorldZones.craterCenter.X, spot.Y, WorldZones.craterCenter.Z)
	)
end

function RestArena.init(_map: Instance)
	local found = ServerStorage:WaitForChild(Protocol.Map.RestArena, 10)
	assert(found and found:IsA("Model"), "RestArena: falta ServerStorage.GuaridaDescanso")
	local model = found:Clone()
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	model:PivotTo(model:GetPivot() + SINK) -- enterrada hasta el descanso
	model.Parent = Workspace
	arena = model
	GiantPublish.set(Protocol.GiantAttributes.Drained, false)
end

-- El monstruo fue derrotado: se vacía el volcán.
function RestArena.show()
	if up then
		return
	end
	up = true
	drainedAt = os.clock()
	if arena then
		arena:PivotTo(arena:GetPivot() - SINK) -- sube (los clientes lo animan)
	end
	GiantPublish.set(Protocol.GiantAttributes.Drained, true)
end

-- Termina el descanso: quien siga dentro vuelve a la orilla y el agua regresa.
function RestArena.hide()
	if not up then
		return
	end
	up = false
	for _, player in Players:GetPlayers() do
		local root = Proximity.getRoot(player)
		local character = player.Character
		if root and character and WorldZones.isInCraterPit(root.Position) then
			character:PivotTo(gateSpot())
		end
	end
	if arena then
		arena:PivotTo(arena:GetPivot() + SINK) -- se hunde otra vez
	end
	GiantPublish.set(Protocol.GiantAttributes.Drained, false)
end

-- Botón "Ir a la guarida": lo deja sobre ella, mirando al centro (si el agua
-- todavía está bajando, espera a que termine).
function RestArena.enter(player: Player): boolean
	if not up or not player.Character then
		return false
	end
	local wait = Config.Giants.cycle.drainSeconds - (os.clock() - drainedAt)
	task.delay(math.max(wait, 0), function()
		local character = player.Character
		if not up or not character then
			return
		end
		local angle = rng:NextNumber(0, math.pi * 2)
		local radius = rng:NextNumber(6, WorldLayout.restArenaRadius - 8)
		local spot = WorldZones.craterCenter
			+ Vector3.new(
				math.cos(angle) * radius,
				WorldLayout.restArenaTop + 4,
				math.sin(angle) * radius
			)
		character:PivotTo(
			CFrame.lookAt(
				spot,
				Vector3.new(WorldZones.craterCenter.X, spot.Y, WorldZones.craterCenter.Z)
			)
		)
	end)
	return true
end

return RestArena
