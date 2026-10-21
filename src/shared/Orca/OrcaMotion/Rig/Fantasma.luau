--!strict
--[[
	OrcaMotion/Rig/Fantasma

	El nado del modelo viejo (tools/blender/rig_orca.py), el de la Orca
	fantasma: Raiz > Cola1..Cola4 y Raiz > Dorsal, sin la cola en el Pecho. Es
	la cuenta de antes, sin cambios: una onda que viaja de la cabeza a la cola y
	crece hacia la punta, las aletas de la cola como paleta contra la onda, la
	curva de la cola con retraso creciente hacia la punta, pectorales con látigo
	en el codo y la dorsal que se mece. Los campos nuevos de la pose (arch,
	flukes, bend, finIzq, finDer) se suman de forma sencilla; en 0 no cambian nada.
]]

local Resorte = require(script.Parent.Parent.Parent.Parent.Resorte)
local Huesos = require(script.Parent.Huesos)
local Tipos = require(script.Parent.Tipos)

type Rig = Tipos.Rig

local TAIL = { "Cola1", "Cola2", "Cola3", "Cola4" }
local TAIL_AMPLITUDE = { 0.05, 0.09, 0.14, 0.21 }
local TAIL_BEND = { 0.07, 0.1, 0.13, 0.15 }
local TAIL_LAG = 0.75 -- retraso de la onda entre huesos (rad)
local JAW_CLOSED, JAW_OPEN = -0.06, 0.5 -- radianes desde la pose del modelo (ya algo abierta)
local FLUKE_PADDLE = 0.32 -- cuánto se doblan las aletas de la cola contra la onda
local FLUKE_MAX = 0.4 -- tope (rad): la cría aletea fuerte y sobre la curva de la cola parecían un gancho
local SIDES = { "Izq", "Der" }
local FLUKES = { "AletaColaIzq", "AletaColaDer" }

local turnBone = Huesos.raw

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

return function(rig: Rig, pose: Tipos.Pose, dt: number)
	local effort, phase = pose.effort, pose.phase
	local bend = math.clamp(pose.turn, -1.2, 1.2)
	local hasChest = if rig.bones.Pecho then true else false
	local arch, extraBend = pose.arch or 0, pose.bend or 0
	-- Cola: onda que viaja hacia la punta; la curva llega más tarde cuanto más atrás.
	for index, name in TAIL do
		local wave = math.sin(phase - index * TAIL_LAG) * TAIL_AMPLITUDE[index] * effort
		local lift = -pose.tail * index / #TAIL * 0.55 -- cabeceo negativo = aletas arriba
		lift += arch / #TAIL -- lomo arriba: las puntas bajan (cabeceo +)
		local want = -bend * TAIL_BEND[index] - extraBend / #TAIL
		local curve = follow(rig, name, want, dt, 2.2 - index * 0.32, 0.7)
		turnBone(rig, name, wave + lift, curve, 0)
	end
	-- Aletas de la cola: paleta que va por detrás de la onda (la derivada) y se abre en la curva.
	local paddle = math.clamp(
		-FLUKE_PADDLE * effort * math.cos(phase - (#TAIL + 1) * TAIL_LAG) - (pose.flukes or 0),
		-FLUKE_MAX,
		FLUKE_MAX
	)
	local flukes = follow(rig, "Aletas", paddle, dt, 3.2, 0.5)
	for _, name in FLUKES do
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
	for _, s in SIDES do
		local axes = rig.axes[`Aleta{s}`]
		if axes then
			local side = axes.side
			local flap = pose.flap * 0.11 * math.sin(phase * 0.5 - 0.8)
			local steer = -side * bend * 0.12
			local wave = (if side > 0 then pose.waveDer else pose.waveIzq) or 0
			wave += (if s == "Izq" then pose.finIzq else pose.finDer) or 0
			local want = pose.fins + flap + steer + pitchLag + wave
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
