--!strict
--[[
	Minotauro/Rig

	Los huesos del minotauro (tools/blender/rig_minotauro_e1.py): Raiz > Cadera >
	Columna > Pecho > Cuello > Cabeza > Mandibula, Boca (punto) y Oreja<lado>;
	Pecho > Brazo/Antebrazo/Mano<lado>; Cadera > Muslo/Pierna/Pie<lado> y Cola1..3.
	Al enlazar se miden los ejes del CUERPO (derecha: del brazo izquierdo al
	derecho; arriba: de la cadera a la cabeza; adelante) y se pasan al espacio
	de cada hueso, así no importa cómo los orientó el importador. turn() gira un
	hueso con cabeceo (+ = la punta sube / el tronco se echa atrás / brazo y
	pierna van adelante), giro (+ = a su izquierda) y alabeo (+ = hacia su derecha).
	side: -1 lado izquierdo, +1 derecho, 0 al medio (para abrir brazos y orejas).
]]

export type Axes = { pitch: Vector3, yaw: Vector3, roll: Vector3 }
export type Rig = {
	model: Model,
	bones: { [string]: Bone },
	axes: { [string]: Axes },
	side: { [string]: number },
}

local Rig = {}

function Rig.bind(model: Model): Rig?
	local bones: { [string]: Bone } = {}
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("Bone") then
			bones[descendant.Name] = descendant
		end
	end
	local root, hip, head = bones.Raiz, bones.Cadera, bones.Cabeza
	local left, right = bones.BrazoIzq, bones.BrazoDer
	if not (root and hip and head and left and right) then
		return nil
	end
	local pivot = model:GetPivot()
	local function at(bone: Bone): Vector3
		return pivot:PointToObjectSpace(bone.WorldPosition)
	end
	local rightAxis = (at(right) - at(left)).Unit
	local up = at(head) - at(hip)
	up = (up - rightAxis * up:Dot(rightAxis)).Unit
	local forward = up:Cross(rightAxis).Unit
	local axes: { [string]: Axes } = {}
	local side: { [string]: number } = {}
	for name, bone in bones do
		local rest = (pivot:Inverse() * bone.WorldCFrame).Rotation -- sin Transform: reposo
		axes[name] = {
			pitch = rest:VectorToObjectSpace(rightAxis),
			yaw = rest:VectorToObjectSpace(up),
			roll = rest:VectorToObjectSpace(forward),
		}
		local offset = (at(bone) - at(root)):Dot(rightAxis)
		side[name] = if math.abs(offset) < 1e-3 then 0 else math.sign(offset)
	end
	return { model = model, bones = bones, axes = axes, side = side }
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
