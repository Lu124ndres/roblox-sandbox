--!strict
--[[
	IceHabitat

	El hábitat completo de Blender del zorro (server/World/HabitatComplete):
	el Model Workspace.Habitat.HabitatZorroDeAgua, con Completo = true. Si está,
	reemplaza la orilla de primitivas (IceShore) y las luces de la orilla (IceAir).
	Llega por streaming (Atomic) y puede llegar tarde o irse con el gigante:
	watch() avisa cada vez que aparece o desaparece.
		model()     el Model, si está en este cliente
		floating()  sus mallas con flota = true (la banquisa: sube y baja con el
		            lago, IceLift)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Protocol = require(ReplicatedStorage.Shared.Protocol)

local MODEL_NAME = "HabitatZorroDeAgua"
local COMPLETE = "Completo" -- atributo del modelo (HabitatComplete)
local FLOATS = "flota" -- atributo de cada malla (del JSON del hábitat)

local IceHabitat = {}

local function isHabitat(child: Instance): boolean
	return child.Name == MODEL_NAME and child:IsA("Model") and child:GetAttribute(COMPLETE) == true
end

function IceHabitat.model(): Model?
	local folder = Workspace:FindFirstChild(Protocol.Map.Habitat)
	if not folder then
		return nil
	end
	for _, child in folder:GetChildren() do
		if isHabitat(child) then
			return child :: Model
		end
	end
	return nil
end

function IceHabitat.floating(model: Model): { BasePart }
	local list: { BasePart } = {}
	for _, child in model:GetChildren() do
		if child:IsA("BasePart") and child:GetAttribute(FLOATS) == true then
			table.insert(list, child)
		end
	end
	return list
end

-- changed() cada vez que el hábitat completo aparece o se va (dura todo el juego,
-- como el cliente: no hace falta desconectar).
function IceHabitat.watch(changed: () -> ())
	task.spawn(function()
		local folder = Workspace:WaitForChild(Protocol.Map.Habitat, math.huge) -- llega después del terreno
		local function check(child: Instance)
			if child.Name == MODEL_NAME then
				if child.Parent == folder then -- por si sus mallas llegan después
					child.ChildAdded:Connect(changed)
				end
				changed()
			end
		end
		folder.ChildAdded:Connect(check)
		folder.ChildRemoved:Connect(check)
		local present = folder:FindFirstChild(MODEL_NAME)
		if present then
			present.ChildAdded:Connect(changed)
		end
		changed()
	end)
end

return table.freeze(IceHabitat)
