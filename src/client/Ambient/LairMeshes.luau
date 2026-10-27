--!strict
--[[
	LairMeshes

	Las mallas del hábitat completo del dragón que suben y bajan con la lava
	(atributo sube: los peñones, el nido y su lava y cristales). Son del
	servidor (Workspace.Habitat.HabitatDragonMarino, ver LairHabitat): no se
	reparentan, se mueven por CFrame solo en este cliente (BulkMoveTo) desde su
	lugar de reposo, que es donde quedan con la lava arriba, y se esconden con
	LocalTransparencyModifier mientras están hundidas.
		place(down, visible)  LairLift: cuánto bajarlas y si se ven (cada vez que se mueve)
		add(part, rest)       una malla nueva y su lugar de reposo
		remove(part) / clear()
]]

local Workspace = game:GetService("Workspace")

local LairMeshes = {}

local parts: { BasePart } = {}
local rest: { CFrame } = {}
local offset = Vector3.zero
local shown = false

local function show(part: BasePart)
	part.LocalTransparencyModifier = if shown then 0 else 1
end

local function move()
	if #parts == 0 then
		return
	end
	local frames = table.create(#parts)
	for i, cframe in rest do
		frames[i] = cframe - offset
	end
	Workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
end

function LairMeshes.place(down: Vector3, visible: boolean)
	offset = down
	if visible ~= shown then
		shown = visible
		for _, part in parts do
			show(part)
		end
	end
	move()
end

function LairMeshes.add(part: BasePart, restFrame: CFrame)
	if table.find(parts, part) then
		return
	end
	table.insert(parts, part)
	table.insert(rest, restFrame)
	show(part)
	move()
end

function LairMeshes.remove(part: BasePart)
	local i = table.find(parts, part)
	if i then
		table.remove(parts, i)
		table.remove(rest, i)
	end
end

function LairMeshes.clear()
	table.clear(parts)
	table.clear(rest)
end

return table.freeze(LairMeshes)
