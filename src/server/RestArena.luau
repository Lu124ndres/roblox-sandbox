--!strict
--[[
	RestArena

	La guarida del descanso: plataforma con rampas desde la punta de cada
	muelle (world/GuaridaDescanso.model.json, en ServerStorage). Se clona UNA
	vez al empezar y queda guardada muy abajo del lago (sin crear ~85 piezas
	de golpe al llenar un monstruo). Al empezar el descanso aparece en su
	lugar con un solo movimiento, tapada por la ola que dibuja CycleView
	(antes subía en 30 pasos y mandaba ~85 piezas cada vez: trababa el juego).
	Al terminar, quien siga abajo sube a la punta del muelle más cercano y la
	guarida vuelve a guardarse. Las puntas de los muelles
	(atributo AbreEnDescanso) solo se abren mientras está arriba. enter()
	lleva a un jugador directo a la guarida (botón del descanso).
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
local RISE_SECONDS = 3 -- lo que tarda en subir en los clientes: luego se abren los muelles
local SINK_SECONDS = 2.5 -- lo que tarda en bajar en los clientes: luego se guarda

local RestArena = {}

local arena: Model
local final: CFrame
local up = false
local openings: { BasePart } = {}
local rng = Random.new()

local function setOpen(open: boolean)
	for _, wall in openings do
		wall.CanCollide = not open
	end
end

-- Punta del muelle más cercano a una posición, sobre la cubierta.
local function nearestPierTip(position: Vector3): CFrame
	local offset = position - WorldZones.craterCenter
	local angle = math.deg(math.atan2(offset.Z, offset.X))
	local step = 360 / WorldLayout.craterPierCount
	local pier = math.rad(math.round((angle - 22.5) / step) * step + 22.5)
	local spot = WorldZones.craterCenter
		+ Vector3.new(math.cos(pier), 0, math.sin(pier)) * (WorldLayout.craterPierTipRadius + 8)
		+ Vector3.new(0, WorldLayout.craterDeckHeight + 3, 0)
	return CFrame.lookAt(
		spot,
		Vector3.new(WorldZones.craterCenter.X, spot.Y, WorldZones.craterCenter.Z)
	)
end

function RestArena.init(map: Instance)
	local found = ServerStorage:WaitForChild(Protocol.Map.RestArena, 10)
	assert(found and found:IsA("Model"), "RestArena: falta ServerStorage.GuaridaDescanso")
	final = found:GetPivot()
	arena = found:Clone()
	arena.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	arena:PivotTo(final - Vector3.new(0, PARK_DEPTH, 0))
	arena.Parent = Workspace
	for _, descendant in map:GetDescendants() do
		if
			descendant:IsA("BasePart")
			and descendant:GetAttribute(Protocol.Map.RestOpening) == true
		then
			table.insert(openings, descendant)
		end
	end
	setOpen(false)
end

-- El monstruo fue derrotado: la guarida sube (un solo movimiento; los clientes la animan).
function RestArena.show()
	if up then
		return
	end
	up = true
	arena:PivotTo(final)
	task.delay(RISE_SECONDS, function()
		if up then
			setOpen(true) -- las rampas ya llegaron a la punta de los muelles
		end
	end)
end

-- Termina el descanso: todos arriba, se cierran los muelles y la guarida se guarda.
function RestArena.hide()
	if not up then
		return
	end
	up = false
	for _, player in Players:GetPlayers() do
		local root = Proximity.getRoot(player)
		local character = player.Character
		if root and character and WorldZones.isBelowPiers(root.Position) then
			character:PivotTo(nearestPierTip(root.Position))
		end
	end
	setOpen(false)
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
