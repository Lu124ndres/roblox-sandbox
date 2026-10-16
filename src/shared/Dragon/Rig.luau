--!strict
--[[
	Dragon/Rig

	Los huesos del dragón (tools/blender/rig_dragon.py) y sus ejes. El modelo
	llega en pose de vuelo (cola estirada, patas recogidas); las alas, en
	planeo (los modelos nuevos) o arriba (los viejos): `neutral` mide cuánto hay
	que bajar cada una para que queden en planeo, así sirve cualquiera de los dos
	(por lado: en algunos modelos el cuerpo está algo torcido y un ala queda más
	alta que la otra). Al
	enlazar se miden los ejes del CUERPO con los huesos: adelante (de la cadera
	a la cabeza), derecha (de la raíz del ala izquierda a la derecha) y arriba,
	y se pasan al espacio de cada hueso: así no importa cómo los orientó el
	exportador. turn() gira un hueso con cabeceo (+ = punta arriba), giro
	(+ = a la izquierda) y alabeo alrededor del eje largo del cuerpo.
]]

local Resorte = require(script.Parent.Parent.Resorte)

export type Axes = { pitch: Vector3, yaw: Vector3, roll: Vector3 }
export type Rig = {
	model: Model,
	bones: { [string]: Bone },
	axes: { [string]: Axes },
	side: { [string]: number }, -- +1 lado derecho, -1 izquierdo, 0 al medio
	right: Vector3, -- ejes del cuerpo en el espacio del pivote
	up: Vector3,
	root: Bone,
	neutral: { [string]: number }, -- por lado (Izq/Der): cuánto bajar el ala para planear (rad)
	springs: { [string]: Resorte.Resorte }, -- inercia de cola, cuello y alas (Pose)
}

local DIHEDRAL = 0.1 -- al planear las alas quedan apenas arriba de la horizontal (rad)

local Rig = {}

function Rig.bind(model: Model): Rig?
	local bones: { [string]: Bone } = {}
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("Bone") then
			bones[descendant.Name] = descendant
		end
	end
	local root, head, hip = bones.Raiz, bones.Cabeza, bones.Cadera
	local left, rightWing = bones.AlaIzq1, bones.AlaDer1
	if not (root and head and hip and left and rightWing) then
		return nil
	end
	local pivot = model:GetPivot()
	local function at(bone: Bone): Vector3
		return pivot:PointToObjectSpace(bone.WorldPosition)
	end
	local forward = (at(head) - at(hip)).Unit
	local right = (at(rightWing) - at(left)).Unit
	local up = right:Cross(forward).Unit
	right = forward:Cross(up).Unit
	local axes: { [string]: Axes } = {}
	local side: { [string]: number } = {}
	for name, bone in bones do
		local rest = (pivot:Inverse() * bone.WorldCFrame).Rotation -- sin Transform: reposo
		axes[name] = {
			pitch = rest:VectorToObjectSpace(right),
			yaw = rest:VectorToObjectSpace(up),
			roll = rest:VectorToObjectSpace(forward),
		}
		local offset = (at(bone) - at(root)):Dot(right)
		side[name] = if math.abs(offset) < 1e-3 then 0 else math.sign(offset)
	end
	-- Ángulo del ala en reposo sobre la horizontal: del hombro a la mano.
	local neutral: { [string]: number } = {}
	for _, s in { "Izq", "Der" } do
		local hand = bones[`Ala{s}3`] or bones[`Ala{s}2`]
		local span = if hand then at(hand) - at(bones[`Ala{s}1`]) else Vector3.zero
		local elevation = if span.Magnitude > 1e-3
			then math.asin(math.clamp(span.Unit:Dot(up), -1, 1))
			else 0
		neutral[s] = elevation - DIHEDRAL
	end
	return {
		model = model,
		bones = bones,
		axes = axes,
		side = side,
		right = right,
		up = up,
		root = root,
		neutral = neutral,
		springs = {},
	}
end

-- Marco del cuerpo en el espacio del pivote: en la raíz, X derecha, Y arriba, -Z adelante.
function Rig.frame(rig: Rig): CFrame
	local pivot = rig.model:GetPivot()
	return CFrame.fromMatrix(pivot:PointToObjectSpace(rig.root.WorldPosition), rig.right, rig.up)
end

function Rig.turn(rig: Rig, name: string, pitch: number, yaw: number, roll: number)
	local bone, axes = rig.bones[name], rig.axes[name]
	if not bone or not axes then
		return
	end
	local transform = CFrame.fromAxisAngle(axes.pitch, pitch)
	if yaw ~= 0 then
		transform *= CFrame.fromAxisAngle(axes.yaw, yaw)
	end
	if roll ~= 0 then
		transform *= CFrame.fromAxisAngle(axes.roll, roll)
	end
	bone.Transform = transform
end

function Rig.point(rig: Rig?, name: string): Vector3?
	local bone = rig and rig.bones[name]
	return if bone then bone.TransformedWorldCFrame.Position else nil
end

return table.freeze(Rig)
