--!strict
--[[
	SandProps

	Los props del hábitat (Workspace.Habitat, HabitatService) los apoya el
	servidor en el fondo del cráter, que con agua queda bajo la superficie. En
	el desierto la arena llega hasta waterLevel y los dejaría enterrados: aquí
	se suben, en este cliente, para que queden sobre la arena (hundidos
	SINK studs, como semienterrados), y bajan con ella cuando se va.

	setDepth(d): la arena está d studs por debajo de su lugar final (0 = puesta,
	math.huge = no hay). Cada prop sube lo que le falta para quedar sobre la
	arena en el punto más bajo de su base (SandShape.lowest: no flota en una
	loma). Los que el servidor puso más arriba (en la ladera) no se mueven.
	Se mueven con PivotTo: el fuego de HabitatFx va dentro del modelo y los sigue.
	Los de un hábitat completo (atributo Completo y sus fuegos) no: ya están a
	ras de la arena y los baja y esconde SandHabitat, que se engancha aquí.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local SandHabitat = require(script.Parent.SandHabitat)
local SandShape = require(script.Parent.SandShape)

local SINK = 1.2 -- studs que la base queda bajo la arena
local PROBE = 0.3 -- como Config.Habitats.probeFraction: puntos a 0.3 del ancho y del fondo

local SandProps = {}

type Prop = { base: CFrame, rest: number } -- rest: alto de la arena donde se apoya
local props: { [Model]: Prop } = {}
local depth = math.huge

local function apply(model: Model, prop: Prop)
	local lift = math.max(prop.rest - depth - SINK - prop.base.Y, 0)
	model:PivotTo(prop.base + Vector3.new(0, lift, 0))
end

local function track(child: Instance)
	if not child:IsA("Model") then
		return
	end
	if props[child] or SandHabitat.owns(child) then
		return -- el hábitat completo y sus fuegos los mueve SandHabitat
	end
	local base = child:GetPivot()
	local _, size = child:GetBoundingBox()
	local rest = SandShape.lowest(base, size.X * PROBE, size.Z * PROBE)
	local prop = { base = base, rest = rest }
	props[child] = prop
	if depth < math.huge then
		apply(child, prop)
	end
end

function SandProps.setDepth(value: number)
	if value == depth then
		return
	end
	depth = value
	for model, prop in props do
		apply(model, prop)
	end
end

function SandProps.start()
	task.spawn(function()
		-- El servidor la crea después del terreno (unos segundos): sin plazo.
		local folder = Workspace:WaitForChild(Protocol.Map.Habitat, math.huge)
		folder.ChildAdded:Connect(function(child: Instance)
			-- Con streaming el prop llega entero (Atomic); un cuadro después ya tiene todo.
			task.defer(track, child)
		end)
		folder.ChildRemoved:Connect(function(child: Instance)
			if child:IsA("Model") then
				props[child] = nil
			end
		end)
		for _, child in folder:GetChildren() do
			track(child)
		end
		SandHabitat.watch(folder)
	end)
end

return table.freeze(SandProps)
