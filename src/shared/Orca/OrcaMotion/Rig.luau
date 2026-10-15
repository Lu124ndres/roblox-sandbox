--!strict
--[[
	OrcaMotion/Rig

	Anima los huesos del modelo de la orca (los arma tools/blender/rig_orca.py):
		Raiz > Cabeza > Mandibula, Boca, Espiraculo
		Raiz > Cola1 > Cola2 > Cola3      (aletas de la cola al final)
		Raiz > AletaIzq, AletaDer, Dorsal
	Con Bone.Transform, sin AnimationController. Al enlazar se miden los ejes del
	modelo (frente -Z, arriba Y) en el espacio de cada hueso: así no importa cómo
	los orientó el exportador. Boca, Espiraculo y Dorsal no deforman: son puntos
	para los peces, el chorro y la luz de la aleta.
]]

export type Axes = { pitch: Vector3, yaw: Vector3, roll: Vector3, side: number }
export type Rig = {
	bones: { [string]: Bone },
	axes: { [string]: Axes },
}

local TAIL = { "Cola1", "Cola2", "Cola3" }
local TAIL_AMPLITUDE = { 0.1, 0.16, 0.26 }
local TAIL_BEND = { 0.1, 0.14, 0.18 }
local JAW_CLOSED, JAW_OPEN = -0.08, 0.55 -- radianes desde la pose del modelo (ya algo abierta)

local Rig = {}

function Rig.bind(model: Model): Rig?
	local bones: { [string]: Bone } = {}
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("Bone") then
			bones[descendant.Name] = descendant
		end
	end
	if not bones.Raiz then
		return nil
	end
	local pivot = model:GetPivot()
	local axes: { [string]: Axes } = {}
	for name, bone in bones do
		-- WorldCFrame no incluye Transform: es la pose de reposo.
		local rest = (pivot:Inverse() * bone.WorldCFrame).Rotation
		axes[name] = {
			pitch = rest:VectorToObjectSpace(Vector3.xAxis),
			yaw = rest:VectorToObjectSpace(Vector3.yAxis),
			roll = rest:VectorToObjectSpace(Vector3.zAxis),
			side = math.sign(pivot:PointToObjectSpace(bone.WorldPosition).X),
		}
	end
	return { bones = bones, axes = axes }
end

-- Gira un hueso: cabeceo (+ = punta arriba), giro (+ = a la izquierda) y
-- alabeo alrededor del eje largo del modelo.
local function turnBone(rig: Rig, name: string, pitch: number, yaw: number, roll: number)
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

-- phase: fase del aleteo (rad); effort: 0..1.5 qué tan fuerte aletea; turn: rad/s
-- del giro (dobla cola y cabeza hacia la curva); jaw: 0 cerrada .. 1 abierta;
-- fins: + aletas pegadas abajo, - abiertas; headPitch: cabeza arriba (rad).
function Rig.apply(
	rig: Rig,
	phase: number,
	effort: number,
	turn: number,
	jaw: number,
	fins: number,
	headPitch: number
)
	local bend = math.clamp(turn, -1.2, 1.2)
	for index, name in TAIL do
		local wave = math.sin(phase - index * 0.8) * TAIL_AMPLITUDE[index] * effort
		-- En una curva la cola se dobla hacia adentro (giro a la izquierda: cola a la izquierda).
		turnBone(rig, name, wave, -bend * TAIL_BEND[index], 0)
	end
	-- El cuerpo y la cabeza acompañan el aleteo un poquito, al revés que la cola.
	turnBone(rig, "Raiz", -0.03 * effort * math.sin(phase + 0.6), 0, 0)
	turnBone(rig, "Cabeza", headPitch + 0.04 * effort * math.sin(phase + math.pi), bend * 0.15, 0)
	-- Abrir es bajar la punta de la mandíbula: cabeceo negativo.
	turnBone(rig, "Mandibula", -(JAW_CLOSED + (JAW_OPEN - JAW_CLOSED) * jaw), 0, 0)
	local flap = 0.12 * math.sin(phase * 0.5) * effort + fins
	for _, name in { "AletaIzq", "AletaDer" } do
		local axes = rig.axes[name]
		if axes then
			-- Mismo ángulo hacia abajo en las dos: el eje largo va con signo opuesto.
			turnBone(rig, name, 0, 0, -axes.side * flap)
		end
	end
end

-- Posición actual (con la animación) de un hueso; nil si el modelo no lo tiene.
function Rig.point(rig: Rig?, name: string): Vector3?
	local bone = rig and rig.bones[name]
	return if bone then bone.TransformedWorldCFrame.Position else nil
end

return table.freeze(Rig)
