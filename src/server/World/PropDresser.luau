--!strict
--[[
	PropDresser

	Viste el mapa con los modelos 3D de Blender (ServerStorage.PropsMapa, de
	tools/blender/props_mapa.py). tools/generar_isla.py deja en cada palmera,
	arbusto, roca, cresta del volcán y estanque una pieza invisible "Ancla" con:
		Prop       nombre del MeshPart en PropsMapa (Palmera2, Roca1, BordeEstanque...)
		Ajuste     "alto" (escala pareja por el alto del Ancla, apoyado en su base),
		           "ancho" (escala pareja por el ancho) o "caja" (toma el tamaño del Ancla)
		Reemplaza  prefijos de nombre, separados por coma, de las piezas de primitivas
		           que el modelo reemplaza (se borran: el modelo 3D las sustituye)
		Brillo     (opcional, Color3) el modelo va en Neon de ese color: la lava del
		           arco del volcán brilla sola, sin depender de cómo se importó
	Si PropsMapa no está (o le falta ese modelo), el mapa queda con las primitivas.
]]

local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local PropDresser = {}

local function startsWithAny(name: string, prefixes: { string }): boolean
	for _, prefix in prefixes do
		if prefix ~= "" and string.sub(name, 1, #prefix) == prefix then
			return true
		end
	end
	return false
end

local function place(anchor: BasePart, template: MeshPart): MeshPart
	local mesh = template:Clone()
	local fit = anchor:GetAttribute("Ajuste")
	local base = anchor.CFrame * CFrame.new(0, -anchor.Size.Y / 2, 0) -- centro de la base
	if fit == "caja" then
		mesh.Size = anchor.Size
		mesh.CFrame = anchor.CFrame
	else
		local ratio = if fit == "ancho"
			then anchor.Size.X / template.Size.X
			else anchor.Size.Y / template.Size.Y
		mesh.Size = template.Size * ratio
		mesh.PivotOffset = CFrame.new(template.PivotOffset.Position * ratio)
		mesh:PivotTo(base)
	end
	mesh.Name = anchor:GetAttribute("Prop") :: string
	local glow = anchor:GetAttribute("Brillo")
	if typeof(glow) == "Color3" then
		mesh.Material = Enum.Material.Neon
		mesh.Color = glow
		mesh.TextureID = "" -- el Neon se ve del color de la pieza
	end
	mesh.Parent = anchor.Parent
	return mesh
end

function PropDresser.dress(root: Instance?)
	local props = ServerStorage:FindFirstChild("PropsMapa")
	local world = root or Workspace:FindFirstChild("Isla")
	if not props or not world then
		return
	end
	local dressed = 0
	for _, anchor in world:GetDescendants() do
		local name = anchor:GetAttribute("Prop")
		if not anchor:IsA("BasePart") or type(name) ~= "string" then
			continue
		end
		local template = props:FindFirstChild(name)
		if not template or not template:IsA("MeshPart") then
			continue
		end
		local parent = anchor.Parent
		local list = anchor:GetAttribute("Reemplaza")
		if parent and type(list) == "string" then
			local prefixes = string.split(list, ",")
			for _, sibling in parent:GetChildren() do
				if sibling ~= anchor and startsWithAny(sibling.Name, prefixes) then
					sibling:Destroy()
				end
			end
		end
		place(anchor, template)
		anchor:Destroy()
		dressed += 1
	end
	print(`PropDresser: {dressed} modelos 3D en el mapa`)
end

return PropDresser
