--!strict
--[[
	LairHabitat

	Sigue el hábitat completo de Blender del dragón en este cliente: el Model
	HabitatDragonMarino (atributo Completo) que server/World/HabitatComplete
	pone en Workspace.Habitat cuando el dragón es el gigante (puede llegar
	tarde, con streaming, o irse con el siguiente gigante). De cada MeshPart
	mira los atributos del JSON:
		sube         sube y baja con la lava (LairMeshes, lo mueve LairLift)
		soloConLava  se ve solo con la lava (LocalTransparencyModifier)
	El resto queda como lo pone el servidor.
		start()            empieza a mirar Workspace.Habitat
		complete()         ¿está el hábitat completo?
		onChange(fn)       fn(complete) cada vez que llega o se va
		setLava(on)        LavaLair: llegó o se fue la lava
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local LairMeshes = require(script.Parent.LairMeshes)

local MODEL = "HabitatDragonMarino" -- `Habitat<GiantId>` (HabitatComplete)

local LairHabitat = {}

local current: Model? = nil
local glowing: { BasePart } = {} -- las soloConLava
local lava = false
local listeners: { (boolean) -> () } = {}
local connections: { RBXScriptConnection } = {}

local function showGlow(part: BasePart)
	part.LocalTransparencyModifier = if lava then 0 else 1
end

-- Dónde reposan las que suben: todas las mallas comparten la caja, así que vale el
-- CFrame de una fija (el servidor no la mueve y este cliente tampoco).
local function restFrame(model: Model, part: BasePart): CFrame
	for _, child in model:GetChildren() do
		if child:IsA("BasePart") and child:GetAttribute("sube") ~= true then
			return child.CFrame
		end
	end
	return part.CFrame
end

local function addMesh(model: Model, child: Instance)
	if not child:IsA("BasePart") then
		return
	end
	if child:GetAttribute("sube") == true then
		LairMeshes.add(child, restFrame(model, child))
	elseif child:GetAttribute("soloConLava") == true and not table.find(glowing, child) then
		table.insert(glowing, child)
		showGlow(child)
	end
end

local function removeMesh(child: Instance)
	if not child:IsA("BasePart") then
		return
	end
	LairMeshes.remove(child)
	local i = table.find(glowing, child)
	if i then
		table.remove(glowing, i)
	end
end

local function notify(on: boolean)
	for _, fn in listeners do
		fn(on)
	end
end

local function detach()
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	LairMeshes.clear()
	table.clear(glowing)
	current = nil
	notify(false)
end

local function attach(model: Model)
	current = model
	for _, child in model:GetChildren() do
		addMesh(model, child)
	end
	table.insert(
		connections,
		model.ChildAdded:Connect(function(child: Instance)
			addMesh(model, child)
		end)
	)
	table.insert(connections, model.ChildRemoved:Connect(removeMesh))
	notify(true)
end

local function consider(child: Instance)
	if child.Name ~= MODEL or not child:IsA("Model") or child:GetAttribute("Completo") ~= true then
		return
	end
	if current then
		detach()
	end
	attach(child)
end

function LairHabitat.start()
	task.spawn(function()
		-- El servidor la crea después del terreno: sin plazo, como HabitatFx.
		local folder = Workspace:WaitForChild(Protocol.Map.Habitat, math.huge) :: Folder
		folder.ChildAdded:Connect(consider)
		folder.ChildRemoved:Connect(function(child: Instance)
			if child == current then
				detach()
			end
		end)
		for _, child in folder:GetChildren() do
			consider(child)
		end
	end)
end

function LairHabitat.complete(): boolean
	return current ~= nil
end

function LairHabitat.onChange(fn: (boolean) -> ())
	table.insert(listeners, fn)
end

function LairHabitat.setLava(on: boolean)
	lava = on
	for _, part in glowing do
		showGlow(part)
	end
end

return table.freeze(LairHabitat)
