--!strict
--[[
	OrcaMotion/Rig

	Anima los huesos de la orca (los arma tools/blender/rig_orca.py):
		Raiz > Cabeza > Mandibula, Boca, Espiraculo
		Raiz > Cola1 > Cola2 > Cola3 > Cola4   (Cola4 = aletas de la cola)
		Raiz > AletaIzq, AletaDer, Dorsal
	Con Bone.Transform, sin AnimationController. El nado es una onda que viaja
	de la cabeza a la cola y crece hacia la punta (como una orca de verdad: la
	cabeza casi quieta, las aletas de la cola barriendo arriba y abajo); el
	cuerpo y la cabeza compensan un poco, las pectorales aletean con retraso y
	en las curvas la cola se dobla hacia adentro. Al enlazar se miden los ejes
	del modelo (frente -Z, arriba Y) en el espacio de cada hueso: así no importa
	cómo los orientó el exportador. Boca, Espiraculo y Dorsal no deforman: son
	puntos para los peces, el chorro y la luz de la aleta.
]]

export type Axes = { pitch: Vector3, yaw: Vector3, roll: Vector3, side: number }
export type Rig = {
	bones: { [string]: Bone },
	axes: { [string]: Axes },
	center: number, -- alto del hueso Raiz sobre la base, en altos del modelo
}
export type Pose = {
	phase: number, -- fase del aleteo (rad)
	effort: number, -- 0..2: qué tan fuerte aletea
	turn: number, -- rad/s del giro
	jaw: number, -- 0 cerrada .. 1.2 muy abierta
	fins: number, -- + pegadas abajo, - abiertas
	flap: number, -- aleteo de las pectorales
	head: number, -- cabeza arriba (rad)
	tail: number, -- curva extra de la cola (+ = aletas arriba)
}

local TAIL = { "Cola1", "Cola2", "Cola3", "Cola4" }
local TAIL_AMPLITUDE = { 0.06, 0.1, 0.15, 0.24 }
local TAIL_BEND = { 0.07, 0.1, 0.13, 0.15 }
local TAIL_LAG = 0.7 -- retraso de la onda entre huesos (rad)
local JAW_CLOSED, JAW_OPEN = -0.06, 0.5 -- radianes desde la pose del modelo (ya algo abierta)

local Rig = {}

function Rig.bind(model: Model): Rig?
	local bones: { [string]: Bone } = {}
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("Bone") then
			bones[descendant.Name] = descendant
		end
	end
	local root = bones.Raiz
	if not root then
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
	local size = model:GetExtentsSize().Y
	local center = pivot:PointToObjectSpace(root.WorldPosition).Y / math.max(size, 0.01)
	return { bones = bones, axes = axes, center = math.clamp(center, 0.2, 0.7) }
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

function Rig.apply(rig: Rig, pose: Pose)
	local bend = math.clamp(pose.turn, -1.2, 1.2)
	for index, name in TAIL do
		local wave = math.sin(pose.phase - index * TAIL_LAG) * TAIL_AMPLITUDE[index] * pose.effort
		-- Cabeceo + baja la punta: "aletas arriba" es cabeceo negativo.
		local lift = -pose.tail * index / #TAIL * 0.55
		turnBone(rig, name, wave + lift, -bend * TAIL_BEND[index], 0)
	end
	turnBone(rig, "Raiz", -0.03 * pose.effort * math.sin(pose.phase + 0.9), 0, 0)
	turnBone(
		rig,
		"Cabeza",
		pose.head + 0.025 * pose.effort * math.sin(pose.phase + math.pi + 0.4),
		bend * 0.18,
		0
	)
	-- Abrir es bajar la punta de la mandíbula: cabeceo negativo.
	turnBone(rig, "Mandibula", -(JAW_CLOSED + (JAW_OPEN - JAW_CLOSED) * pose.jaw), 0, 0)
	for _, name in { "AletaIzq", "AletaDer" } do
		local axes = rig.axes[name]
		if axes then
			-- Aletean con retraso; en la curva la de adentro baja (timón).
			local flap = pose.flap * 0.11 * math.sin(pose.phase * 0.5 - 0.8)
			local steer = -axes.side * bend * 0.12
			-- Mismo ángulo hacia abajo en las dos: el eje largo va con signo opuesto.
			turnBone(rig, name, 0, 0, -axes.side * (pose.fins + flap + steer))
		end
	end
end

-- Posición actual (con la animación) de un hueso; nil si el modelo no lo tiene.
function Rig.point(rig: Rig?, name: string): Vector3?
	local bone = rig and rig.bones[name]
	return if bone then bone.TransformedWorldCFrame.Position else nil
end

return table.freeze(Rig)
