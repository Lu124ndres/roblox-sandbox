--!strict
--[[
	RestArena

	La guarida del descanso: plataforma con rampas desde la punta de cada
	muelle (world/GuaridaDescanso.model.json, en ServerStorage). No existe en
	el mapa mientras el monstruo vive: al derrotarlo se clona hundida en el
	lago y emerge (riseSeconds); al terminar el descanso, quien siga abajo
	sube a la punta del muelle más cercano, la guarida se hunde y se borra.
	Las puntas de los muelles (atributo AbreEnDescanso) solo se abren
	mientras está arriba.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local Proximity = require(script.Parent.Proximity)

local SINK_DEPTH = 16 -- studs bajo su lugar final cuando está hundida
local RISE_SECONDS = 3
local SINK_SECONDS = 2.5

local RestArena = {}

local template: Model
local current: Model? = nil
local openings: { BasePart } = {}

local function setOpen(open: boolean)
	for _, wall in openings do
		wall.CanCollide = not open
	end
end

-- Mueve la guarida de "from" a "to" (desplazamientos verticales) con suavidad.
local function slide(model: Model, final: CFrame, from: number, to: number, seconds: number)
	local elapsed = 0
	while elapsed < seconds and model.Parent do
		elapsed += RunService.Heartbeat:Wait()
		local t = math.min(elapsed / seconds, 1)
		local eased = 1 - (1 - t) ^ 3
		model:PivotTo(final + Vector3.new(0, from + (to - from) * eased, 0))
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
	template = found
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

-- El monstruo fue derrotado: la guarida emerge del lago.
function RestArena.show()
	if current then
		return
	end
	local model = template:Clone()
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	local final = template:GetPivot()
	model:PivotTo(final - Vector3.new(0, SINK_DEPTH, 0))
	model.Parent = Workspace
	current = model
	task.spawn(function()
		slide(model, final, -SINK_DEPTH, 0, RISE_SECONDS)
		if current == model then
			setOpen(true) -- las rampas ya llegaron a la punta de los muelles
		end
	end)
end

-- Termina el descanso: todos arriba, se cierran los muelles y la guarida se hunde.
function RestArena.hide()
	local model = current
	if not model then
		return
	end
	current = nil
	for _, player in Players:GetPlayers() do
		local root = Proximity.getRoot(player)
		local character = player.Character
		if root and character and WorldZones.isBelowPiers(root.Position) then
			character:PivotTo(nearestPierTip(root.Position))
		end
	end
	setOpen(false)
	task.spawn(function()
		slide(model, template:GetPivot(), 0, -SINK_DEPTH, SINK_SECONDS)
		model:Destroy()
	end)
end

return RestArena
