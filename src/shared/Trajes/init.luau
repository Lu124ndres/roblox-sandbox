--!strict
--[[
	Trajes

	Los trajes de malla del personaje (modelos de Meshy con huesos, hechos con
	tools/blender/rig_traje.py). Todos los jugadores son Marinero; los pases
	ReyDelMar y DiosDelVolcan dan el suyo. Cada traje es un Model
	`Traje<clave>` en ServerStorage con una MeshPart y estos huesos:
		Raiz > Cadera > Pecho > Cabeza
		                Pecho > BrazoX > CodoX > ManoX     (X = Izq, Der)
		       Cadera > PiernaX > RodillaX > PieX
	El servidor lo suelda al personaje, que queda invisible (Social/MeshOutfit),
	y cada cliente mueve los huesos de todos copiando el esqueleto R15 o R6
	escondido (client/Trajes): así todos ven las mismas animaciones, las de
	Roblox y la pose de la caña. Cómo se mueve y brilla cada uno: Estilos/<clave>.
]]

local Tipos = require(script.Tipos)

export type BoneInfo = Tipos.BoneInfo
export type Context = Tipos.Context
export type Fx = Tipos.Fx
export type Style = Tipos.Style

local function limb(
	side: string,
	upper: string,
	lower: string,
	hand: string,
	r6: string,
	kind: string
): { BoneInfo }
	local parent = if kind == "arms" then "Pecho" else "Cadera"
	local names = if kind == "arms"
		then { "Brazo", "Codo", "Mano" }
		else { "Pierna", "Rodilla", "Pie" }
	return {
		{ name = names[1] .. side, parent = parent, parts = { upper, r6 }, limb = kind },
		{ name = names[2] .. side, parent = names[1] .. side, parts = { lower }, limb = kind },
		{ name = names[3] .. side, parent = names[2] .. side, parts = { hand } },
	}
end

-- En orden: cada hueso después de su padre.
local BONES: { BoneInfo } = {
	{ name = "Raiz", parts = { "HumanoidRootPart" } },
	{ name = "Cadera", parent = "Raiz", parts = { "LowerTorso", "Torso" } },
	{ name = "Pecho", parent = "Cadera", parts = { "UpperTorso", "Torso" } },
	{ name = "Cabeza", parent = "Pecho", parts = { "Head" } },
}
for _, list in
	{
		limb("Izq", "LeftUpperArm", "LeftLowerArm", "LeftHand", "Left Arm", "arms"),
		limb("Der", "RightUpperArm", "RightLowerArm", "RightHand", "Right Arm", "arms"),
		limb("Izq", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "Left Leg", "legs"),
		limb("Der", "RightUpperLeg", "RightLowerLeg", "RightFoot", "Right Leg", "legs"),
	}
do
	for _, info in list do
		table.insert(BONES, info)
	end
end

local Trajes = {}

Trajes.Bones = table.freeze(BONES)
Trajes.SAILOR = "Marinero"
Trajes.FOLDER = "Traje" -- Model dentro del personaje
Trajes.WELD = "TrajeSoldadura" -- Weld del traje al HumanoidRootPart
Trajes.CHOSEN = "TrajeElegido" -- atributo del jugador: traje que eligió en la vitrina
Trajes.EXTRA_HEIGHT = "TrajeAlto" -- atributo del personaje: studs que el traje pasa a la cabeza
Trajes.BONE_COUNT = "TrajeHuesos" -- atributo del Model del traje: huesos que trae la malla

function Trajes.countBones(mesh: MeshPart): number
	local count = 0
	for _, descendant in mesh:GetDescendants() do
		if descendant:IsA("Bone") then
			count += 1
		end
	end
	return count
end

function Trajes.templateName(key: string): string
	return `Traje{key}`
end

-- La MeshPart con huesos del traje.
function Trajes.mesh(model: Instance): MeshPart?
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("MeshPart") and descendant:FindFirstChildWhichIsA("Bone", true) then
			return descendant
		end
	end
	return nil
end

function Trajes.bones(mesh: MeshPart): { [string]: Bone }
	local found = {}
	for _, descendant in mesh:GetDescendants() do
		if descendant:IsA("Bone") then
			found[descendant.Name] = descendant
		end
	end
	return found
end

-- Marco del traje en reposo (en el mundo): en la Raiz, al nivel del piso, X a su
-- derecha, Y arriba y -Z al frente, como un personaje. Devuelve también el alto
-- de la cadera y el alto total (studs), medidos desde el piso.
function Trajes.measure(mesh: MeshPart): (CFrame, number, number)
	local bones = Trajes.bones(mesh)
	local root, head = bones.Raiz, bones.Cabeza
	local left, right, hip = bones.BrazoIzq, bones.BrazoDer, bones.PiernaIzq
	assert(
		root and head and left and right and hip,
		`Trajes: {mesh:GetFullName()} no tiene los huesos`
	)
	local origin = root.WorldPosition
	local up = (head.WorldPosition - origin).Unit
	local side = right.WorldPosition - left.WorldPosition
	side = (side - up * side:Dot(up)).Unit
	local frame = CFrame.fromMatrix(origin, side, up)
	local top = 0
	local half = mesh.Size / 2
	for _, corner in
		{
			Vector3.new(1, 1, 1),
			Vector3.new(1, 1, -1),
			Vector3.new(1, -1, 1),
			Vector3.new(1, -1, -1),
		}
	do
		for _, sign in { 1, -1 } do
			local point = mesh.CFrame:PointToWorldSpace(half * corner * sign)
			top = math.max(top, (point - origin):Dot(up))
		end
	end
	return frame, (hip.WorldPosition - origin):Dot(up), top
end

local styles: { [string]: Style } = {}
for _, module in script.Estilos:GetChildren() do
	if module:IsA("ModuleScript") then
		styles[module.Name] = (require :: any)(module)
	end
end

function Trajes.style(key: string): Style
	return styles[key] or styles[Trajes.SAILOR]
end

return table.freeze(Trajes)
