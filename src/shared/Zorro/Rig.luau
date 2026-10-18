--!strict
--[[
	Zorro/Rig

	Los huesos del zorro de agua (tools/blender/rig_zorro_e4_code.py):
		Raiz > Cadera > Columna > Pecho > Cuello1 > Cuello2 > Cabeza > Mandibula,
		       Boca (punto), OrejaIzq, OrejaDer
		Pecho > Hombro > Brazo > Antebrazo > Mano    (Izq/Der)
		Cadera > Muslo > Pierna > Tobillo > Pie      (Izq/Der)
		Cadera > Cola<n>_1 > _2 > ... > _<tramos>    (n = 1..9; 4 tramos en el
		         zorro actual, 5 en el v2)
	Detalle opcional (v2): OrejaPunta{l} (hija de Oreja) y Parpado{l}. Ningún
	módulo los exige: turn() salta los huesos que el modelo no tiene.
	Al enlazar se miden los ejes del CUERPO (derecha: de un hombro al otro; arriba:
	la vertical del modelo; adelante) y se pasan al espacio de cada hueso: así no
	importa cómo los orientó el importador. turn() gira un hueso con cabeceo
	(+ = la punta sube / la pata va adelante), giro (+ = a su izquierda) y alabeo
	(alrededor del eje largo del cuerpo). side: -1 izquierda, +1 derecha, 0 al medio.
	tails: las colas que tiene el modelo, de izquierda a derecha, con su lado (-1..1),
	cuántos tramos tiene (segments, contando _1, _2… mientras existan) y el
	nombre del último (tip). rest y frame: el reposo de cada hueso y los ejes del
	cuerpo en el espacio del pivote (los usa Zorro/Colas para medir).
]]

local Resorte = require(script.Parent.Parent.Resorte)

export type Axes = { pitch: Vector3, yaw: Vector3, roll: Vector3 }
export type Tail = { prefix: string, side: number, segments: number, tip: string }
export type Frame = { right: Vector3, up: Vector3, forward: Vector3 }
export type Rig = {
	model: Model,
	bones: { [string]: Bone },
	axes: { [string]: Axes },
	side: { [string]: number },
	tails: { Tail },
	rest: { [string]: CFrame }, -- reposo de cada hueso en el espacio del pivote
	frame: Frame,
	springs: { [string]: Resorte.Resorte },
}

local MAX_TAILS = 12 -- se buscan Cola1..Cola12 (la forma final tiene 9)

local Rig = {}

function Rig.bind(model: Model): Rig?
	local bones: { [string]: Bone } = {}
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("Bone") then
			bones[descendant.Name] = descendant
		end
	end
	local root, left, right = bones.Raiz, bones.HombroIzq, bones.HombroDer
	if not (root and left and right and bones.Cabeza and bones.Cola1_1) then
		return nil
	end
	local pivot = model:GetPivot()
	local function at(bone: Bone): Vector3
		return pivot:PointToObjectSpace(bone.WorldPosition)
	end
	local rightAxis = at(right) - at(left)
	rightAxis = Vector3.new(rightAxis.X, 0, rightAxis.Z).Unit -- el zorro está parado: horizontal
	local up = Vector3.yAxis
	local forward = up:Cross(rightAxis).Unit
	local axes: { [string]: Axes } = {}
	local side: { [string]: number } = {}
	local rests: { [string]: CFrame } = {}
	for name, bone in bones do
		rests[name] = pivot:Inverse() * bone.WorldCFrame -- sin Transform: reposo
		local rest = rests[name].Rotation
		axes[name] = {
			pitch = rest:VectorToObjectSpace(rightAxis),
			yaw = rest:VectorToObjectSpace(up),
			roll = rest:VectorToObjectSpace(forward),
		}
		local offset = (at(bone) - at(root)):Dot(rightAxis)
		side[name] = if math.abs(offset) < 1e-3 then 0 else math.sign(offset)
	end
	-- Colas: su lado según hacia dónde se abre la punta (-1 izquierda .. 1 derecha),
	-- medido del primer tramo al último.
	local tails: { Tail } = {}
	local spread = 0
	for n = 1, MAX_TAILS do
		local segments = 0
		while bones[`Cola{n}_{segments + 1}`] do
			segments += 1
		end
		if segments >= 2 then
			local first, last = bones[`Cola{n}_1`], bones[`Cola{n}_{segments}`]
			local lateral = (at(last) - at(first)):Dot(rightAxis)
			spread = math.max(spread, math.abs(lateral))
			table.insert(
				tails,
				{ prefix = `Cola{n}_`, side = lateral, segments = segments, tip = last.Name }
			)
		end
	end
	for _, tail in tails do
		tail.side = if spread > 0 then tail.side / spread else 0
	end
	table.sort(tails, function(a, b)
		return a.side < b.side
	end)
	return {
		model = model,
		bones = bones,
		axes = axes,
		side = side,
		tails = tails,
		rest = rests,
		frame = { right = rightAxis, up = up, forward = forward },
		springs = {},
	}
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

-- Un valor que sigue a su objetivo con inercia (colas, orejas, cabeza).
function Rig.follow(
	rig: Rig,
	key: string,
	target: number,
	dt: number,
	hz: number,
	damping: number
): number
	return Resorte.step(Resorte.get(rig.springs, key, target), target, dt, hz, damping)
end

function Rig.point(rig: Rig?, name: string): Vector3?
	local bone = rig and rig.bones[name]
	return if bone then bone.TransformedWorldCFrame.Position else nil
end

return table.freeze(Rig)
