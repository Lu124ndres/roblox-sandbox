--!strict
--[[
	RestArena

	La guarida del descanso: un círculo grande con muro bajo en el centro del
	lago (world/GuaridaDescanso.model.json, en ServerStorage); se llega con el
	botón IR A LA GUARIDA (enter), no hay rampas. Se clona UNA
	vez al empezar y queda guardada muy abajo del lago (sin crear ~85 piezas
	de golpe al llenar un monstruo). Al empezar el descanso aparece en su
	lugar con un solo movimiento, tapada por la ola que dibuja CycleView
	(antes subía en 30 pasos y mandaba ~85 piezas cada vez: trababa el juego).
	Al terminar, quien siga abajo sube al punto más cercano del borde del
	cráter y la guarida vuelve a guardarse.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local Proximity = require(script.Parent.Proximity)

local PARK_DEPTH = 120 -- studs bajo su lugar mientras está guardada (bajo el fondo del lago)
local SINK_SECONDS = 2.5 -- lo que tarda en bajar en los clientes: luego se guarda

local RestArena = {}

local arena: Model
local final: CFrame
local up = false
local rng = Random.new()

-- Punto del borde del cráter más cercano a una posición, sobre el paseo.
local function nearestShore(position: Vector3): CFrame
	local offset = position - WorldZones.craterCenter
	local angle = math.atan2(offset.Z, offset.X)
	local spot = WorldZones.craterCenter
		+ Vector3.new(math.cos(angle), 0, math.sin(angle)) * (WorldLayout.craterCliffRadius + 6)
		+ Vector3.new(0, WorldLayout.craterRimHeight + 3, 0)
	return CFrame.lookAt(
		spot,
		Vector3.new(WorldZones.craterCenter.X, spot.Y, WorldZones.craterCenter.Z)
	)
end

function RestArena.init(_map: Instance)
	local found = ServerStorage:WaitForChild(Protocol.Map.RestArena, 10)
	assert(found and found:IsA("Model"), "RestArena: falta ServerStorage.GuaridaDescanso")
	final = found:GetPivot()
	arena = found:Clone()
	arena.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	arena:PivotTo(final - Vector3.new(0, PARK_DEPTH, 0))
	arena.Parent = Workspace
end

-- El monstruo fue derrotado: la guarida sube (un solo movimiento; los clientes la animan).
function RestArena.show()
	if up then
		return
	end
	up = true
	arena:PivotTo(final)
end

-- Termina el descanso: todos arriba, al borde, y la guarida se guarda.
function RestArena.hide()
	if not up then
		return
	end
	up = false
	for _, player in Players:GetPlayers() do
		local root = Proximity.getRoot(player)
		local character = player.Character
		if root and character and WorldZones.isInCraterPit(root.Position) then
			character:PivotTo(nearestShore(root.Position))
		end
	end
	task.delay(SINK_SECONDS, function()
		if not up then
			arena:PivotTo(final - Vector3.new(0, PARK_DEPTH, 0))
		end
	end)
end

-- Botón "Ir a la guarida": lo deja sobre la plataforma, mirando al centro.
function RestArena.enter(player: Player): boolean
	local character = player.Character
	if not up or not character then
		return false
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
	return true
end

return RestArena
