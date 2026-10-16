--!strict
--[[
	MeshKit

	Cambia una pieza de primitivas por la pieza 3D de Blender del mismo nombre
	en ReplicatedStorage.ModelosEquipo (tools/blender/equipo_base.py): mismo
	tamaño, lugar, color y material, y se lleva sus hijos (soldaduras, luces,
	attachments). Las piezas 3D miden 1 x 1 x 1 con el eje largo en X, como los
	cilindros de Roblox, así que entran justo en el lugar de la pieza vieja.
	Si el modelo no está, deja la pieza como estaba.
		MangoCorcho, CarreteBobina, CarretePlato, Anilla   la caña de la mano
		CajaRedondeada                                     cuerpo y borde de las canastas
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MeshKit = {}

local COPY = {
	"Size",
	"CFrame",
	"Color",
	"Material",
	"Transparency",
	"Reflectance",
	"Anchored",
	"CanCollide",
	"CanQuery",
	"CanTouch",
	"Massless",
	"CastShadow",
}

function MeshKit.swap(part: BasePart, name: string): BasePart
	local folder = ReplicatedStorage:FindFirstChild("ModelosEquipo")
	local template = folder and folder:FindFirstChild(name)
	if not template or not template:IsA("MeshPart") then
		return part
	end
	local mesh = template:Clone()
	mesh.Name = part.Name
	for _, property in COPY do
		(mesh :: any)[property] = (part :: any)[property]
	end
	for _, child in part:GetChildren() do
		child.Parent = mesh
		if child:IsA("JointInstance") then
			if child.Part0 == part then
				child.Part0 = mesh
			end
			if child.Part1 == part then
				child.Part1 = mesh
			end
		end
	end
	mesh.Parent = part.Parent
	part:Destroy()
	return mesh
end

return MeshKit
