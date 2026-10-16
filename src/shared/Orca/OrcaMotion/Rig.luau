--!strict
--[[
	OrcaMotion/Rig

	Anima los huesos de la orca (los arma tools/blender/rig_orca.py):
		Raiz > Pecho > Cabeza > Mandibula        (Boca, Espiraculo: puntos)
		Pecho > AletaIzq > AletaIzq2   (y Der)   pectorales con codo
		Raiz > Dorsal
		Raiz > Cola1 > ... > Cola4 > AletaColaIzq, AletaColaDer
	Con Bone.Transform, sin AnimationController. El nado es una onda que viaja
	de la cabeza a la cola y crece hacia la punta (la cabeza casi quieta, las
	aletas de la cola barriendo); las aletas de la cola se doblan contra la onda
	como una paleta. Todo lo que cuelga va con resortes (Resorte): la cola se
	dobla en las curvas con retraso creciente hacia la punta, las pectorales
	tienen látigo en el codo y la dorsal se mece por inercia. Los modelos viejos
	(sin Pecho ni codos) usan lo que tengan. Al enlazar se miden los ejes del
	modelo (frente -Z, arriba Y) en el espacio de cada hueso.
]]

local Resorte = require(script.Parent.Parent.Parent.Resorte)

export type Axes = { pitch: Vector3, yaw: Vector3, roll: Vector3, side: number }
export type Rig = {
	bones: { [string]: Bone },
	axes: { [string]: Axes },
	center: number, -- alto del hueso Raiz sobre la base, en altos del modelo
	springs: { [string]: Resorte.Resorte },
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
	pitchSpeed: number?, -- rad/s del cabeceo del cuerpo (las aletas lo siguen tarde)
	rollSpeed: number?, -- rad/s del alabeo (la dorsal se mece)
}

local TAIL = { "Cola1", "Cola2", "Cola3", "Cola4" }
local TAIL_AMPLITUDE = { 0.05, 0.09, 0.14, 0.21 }
local TAIL_BEND = { 0.07, 0.1, 0.13, 0.15 }
local TAIL_LAG = 0.75 -- retraso de la onda entre huesos (rad)
local JAW_CLOSED, JAW_OPEN = -0.06, 0.5 -- radianes desde la pose del modelo (ya algo abierta)
local FLUKE_PADDLE = 0.32 -- cuánto se doblan las aletas de la cola contra la onda

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
	return { bones = bones, axes = axes, center = math.clamp(center, 0.2, 0.7), springs = {} }
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

local function follow(
	rig: Rig,
	name: string,
	target: number,
	dt: number,
	hz: number,
	damping: number
): number
	return Resorte.step(Resorte.get(rig.springs, name, target), target, dt, hz, damping)
end

function Rig.apply(rig: Rig, pose: Pose, dt: number)
	local effort, phase = pose.effort, pose.phase
	local bend = math.clamp(pose.turn, -1.2, 1.2)
	local hasChest = rig.bones.Pecho ~= nil
	-- Cola: onda que viaja hacia la punta; la curva llega más tarde cuanto más atrás.
	for index, name in TAIL do
		local wave = math.sin(phase - index * TAIL_LAG) * TAIL_AMPLITUDE[index] * effort
		local lift = -pose.tail * index / #TAIL * 0.55 -- cabeceo negativo = aletas arriba
		local curve = follow(rig, name, -bend * TAIL_BEND[index], dt, 2.2 - index * 0.32, 0.7)
		turnBone(rig, name, wave + lift, curve, 0)
	end
	-- Aletas de la cola: paleta que va por detrás de la onda (la derivada) y se abre en la curva.
	local paddle = -FLUKE_PADDLE * effort * math.cos(phase - (#TAIL + 1) * TAIL_LAG)
	local flukes = follow(rig, "Aletas", paddle, dt, 3.2, 0.5)
	for _, name in { "AletaColaIzq", "AletaColaDer" } do
		local axes = rig.axes[name]
		if axes then
			turnBone(rig, name, flukes, 0, axes.side * bend * 0.06)
		end
	end
	-- Tronco y cabeza: compensan la onda (la cabeza va firme) y miran hacia la curva.
	turnBone(rig, "Raiz", -0.03 * effort * math.sin(phase + 0.9), 0, 0)
	local look = follow(rig, "Mirada", bend, dt, 1.4, 0.9)
	if hasChest then
		turnBone(rig, "Pecho", 0.02 * effort * math.sin(phase + math.pi), look * 0.08, 0)
	end
	local headWave = 0.025 * effort * math.sin(phase + math.pi + 0.4)
	turnBone(rig, "Cabeza", pose.head + headWave, look * (if hasChest then 0.12 else 0.18), 0)
	-- Abrir es bajar la punta de la mandíbula: cabeceo negativo.
	local jaw = follow(rig, "Mandibula", pose.jaw, dt, 6, 0.75)
	turnBone(rig, "Mandibula", -(JAW_CLOSED + (JAW_OPEN - JAW_CLOSED) * jaw), 0, 0)

	-- Pectorales: aletean con retraso, timonean en la curva y se levantan al
	-- picar (siguen al cuerpo tarde); el codo repite el gesto más tarde (látigo).
	local pitchLag = math.clamp(pose.pitchSpeed or 0, -2, 2) * 0.12
	for _, s in { "Izq", "Der" } do
		local axes = rig.axes[`Aleta{s}`]
		if axes then
			local side = axes.side
			local flap = pose.flap * 0.11 * math.sin(phase * 0.5 - 0.8)
			local steer = -side * bend * 0.12
			local want = pose.fins + flap + steer + pitchLag
			local root = follow(rig, `Aleta{s}`, want, dt, 2.6, 0.55)
			-- Mismo ángulo hacia abajo en las dos: el eje largo va con signo opuesto.
			turnBone(rig, `Aleta{s}`, 0, 0, -side * root)
			local elbow = follow(rig, `Aleta{s}2`, want * 0.5, dt, 1.7, 0.45)
			turnBone(rig, `Aleta{s}2`, 0, 0, -side * elbow)
		end
	end
	-- Dorsal: se mece hacia afuera en las curvas y con el bamboleo, y rebota.
	local sway = bend * 0.18 - math.clamp(pose.rollSpeed or 0, -3, 3) * 0.06
	turnBone(rig, "Dorsal", 0, 0, follow(rig, "Dorsal", sway, dt, 1.3, 0.3))
end

-- Posición actual (con la animación) de un hueso; nil si el modelo no lo tiene.
function Rig.point(rig: Rig?, name: string): Vector3?
	local bone = rig and rig.bones[name]
	return if bone then bone.TransformedWorldCFrame.Position else nil
end

return table.freeze(Rig)
