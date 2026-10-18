--!strict
--[[
	Zorro/Pose

	La pose del zorro como una tabla de números (radianes o 0..1) que se suman:
	reposo, comer, pasos y el truco del momento (Zorro/Trucos). apply() la reparte
	en los huesos:
		lean / sway / breathe      tronco: adelante (-) o atrás (+), de lado, respirar
		lookYaw / lookPitch / tilt cabeza: girar (+ a su izquierda), arriba/abajo, ladear
		jaw                        boca abierta (0..1)
		earL / earR                orejas paradas (+) o echadas atrás (-)
		bow                        reverencia: el pecho baja, la cadera queda alta
		crouch                     se agacha con las cuatro patas (para saltar)
		stepFL/FR/HL/HR            levanta cada pata (0..1): delantera/trasera, Izq/Der
		tailFan / tailLift         colas: más abiertas / más arriba
		tailWag                    colas: meneo rápido de contento
		tailCalm                   colas: cuánto ondulan en reposo (1 = normal)
		tailAlert / tailWrap /     colas: alerta, envolver las patas (sentado),
		tailCurl / tailSide        enroscarse (dormido) y hacia qué lado
		shake                      sacudida de todo el cuerpo (0..1)
		dy                         salto (fracción del alto)
	apply() NO toca las colas: las claves tail* son un pedido que Zorro/init pasa
	a Zorro/Colas (Colas/Traduccion), el único que escribe los huesos Cola*_*.
]]

local Rig = require(script.Parent.Rig)

export type Pose = { [string]: number }

local TAU = math.pi * 2
-- La reverencia dobla las delanteras (por bow): con menos, el pecho baja y las manos
-- se hunden en el agua (medido en tools/blender/zorro_v2_poses.py).
local BOW_BEND = 1.5

local Pose = {}

-- Cuánto baja la base al agacharse (fracción del alto, por crouch): lo que acortan las
-- patas dobladas. Lo usan Zorro/init y Colas/Traduccion.
Pose.CROUCH_DROP = 0.035

function Pose.add(into: Pose, from: Pose, k: number?)
	local weight = k or 1
	for key, value in from do
		into[key] = (into[key] or 0) + value * weight
	end
end

local function wave(t: number, period: number, offset: number?): number
	return math.sin(TAU * t / period + (offset or 0))
end

-- Un movimiento corto cada `period` segundos (una oreja que se sacude).
local function flick(t: number, period: number): number
	local u = (t % period) / 0.3
	return if u < 1 then math.sin(math.pi * u) else 0
end

function Pose.idle(t: number): Pose
	-- El peso pasa de un lado al otro despacio; el pecho respira; mira alrededor.
	return {
		breathe = 0.03 * wave(t, 3.6),
		sway = 0.035 * wave(t, 7.3),
		lean = 0.02 * wave(t, 9.1, 1),
		lookYaw = 0.32 * wave(t, 11) + 0.08 * wave(t, 3.7),
		lookPitch = 0.06 * wave(t, 6.1),
		tilt = 0.12 * wave(t, 8.3, 0.6),
		earL = 0.45 * flick(t, 4.1) + 0.05 * wave(t, 2.9),
		earR = 0.45 * flick(t + 1.7, 5.3) + 0.05 * wave(t, 3.1),
		tailCalm = 1,
		jaw = 0.04 + 0.03 * wave(t, 3.6),
	}
end

-- w: cuánto está comiendo (0..1); biting: justo cerró la boca en un pez.
function Pose.feeding(w: number, t: number, biting: boolean): Pose
	local chew = 0.5 + 0.5 * math.sin(t * 8)
	return {
		bow = 0.35 * w,
		lean = -0.12 * w,
		lookPitch = -0.28 * w - (if biting then 0.1 else 0),
		lookYaw = -0.32 * w * wave(t, 11), -- deja de mirar alrededor
		jaw = if biting then -0.04 else w * (0.45 + 0.35 * chew),
		earL = 0.35 * w,
		earR = 0.35 * w,
		tailWag = 0.8 * w,
		tailLift = 0.15 * w,
	}
end

-- Pasos al girar en el lugar: pares cruzados (delantera izq. con trasera der.).
function Pose.steps(phase: number, amount: number): Pose
	local a, b = math.max(0, math.sin(phase)), math.max(0, -math.sin(phase))
	return {
		stepFL = a * amount,
		stepHR = a * amount,
		stepFR = b * amount,
		stepHL = b * amount,
		sway = 0.04 * math.sin(phase) * amount,
	}
end

local function leg(
	rig: Rig.Rig,
	front: boolean,
	s: string,
	lift: number,
	bend: number,
	swing: number
)
	if front then
		Rig.turn(rig, `Hombro{s}`, swing * 0.4, 0, 0)
		Rig.turn(rig, `Brazo{s}`, 0.35 * lift + swing * 0.6 - bend * 0.5, 0, 0)
		Rig.turn(rig, `Antebrazo{s}`, -1.1 * lift + bend * 0.9, 0, 0)
		Rig.turn(rig, `Mano{s}`, -0.8 * lift - bend * 0.4, 0, 0)
	else
		Rig.turn(rig, `Muslo{s}`, 0.3 * lift + swing * 0.5 + bend * 0.5, 0, 0)
		Rig.turn(rig, `Pierna{s}`, -0.4 * lift - bend * 0.9, 0, 0)
		Rig.turn(rig, `Tobillo{s}`, 0.7 * lift + bend * 0.8, 0, 0)
		Rig.turn(rig, `Pie{s}`, -0.5 * lift - bend * 0.4, 0, 0)
	end
end

-- turn: rad/s del giro del cuerpo (las orejas lo siguen tarde).
function Pose.apply(rig: Rig.Rig, p: Pose, t: number, turn: number, dt: number)
	local function v(key: string): number
		return p[key] or 0
	end
	local shake = v("shake")
	local quiver = math.sin(t * 38) * 0.22 * shake
	local lean, breathe, bow, crouch = v("lean"), v("breathe"), v("bow"), v("crouch")
	-- Tronco: la reverencia baja el pecho; la sacudida rota todo el cuerpo rápido.
	Rig.turn(rig, "Cadera", -bow * 0.2 + crouch * 0.05, 0, v("sway") + quiver)
	Rig.turn(rig, "Columna", lean * 0.4 + breathe - bow * 0.25, 0, -v("sway") * 0.4 - quiver * 0.8)
	Rig.turn(rig, "Pecho", lean * 0.4 + breathe * 0.7 - bow * 0.2, v("lookYaw") * 0.1, quiver * 0.6)
	local yaw = Rig.follow(rig, "Mirar", v("lookYaw"), dt, 1.6, 0.7)
	local pitch = Rig.follow(rig, "Cabecear", v("lookPitch") + bow * 0.5, dt, 2, 0.75)
	Rig.turn(rig, "Cuello1", pitch * 0.35, yaw * 0.3, v("tilt") * 0.2 - quiver * 0.5)
	Rig.turn(rig, "Cuello2", pitch * 0.3, yaw * 0.3, v("tilt") * 0.3)
	Rig.turn(rig, "Cabeza", pitch * 0.35 - breathe * 0.4, yaw * 0.4, v("tilt") * 0.5 + quiver * 0.4)
	Rig.turn(rig, "Mandibula", -0.6 * math.clamp(v("jaw"), -0.1, 1.1), 0, 0)
	for _, s in { "Izq", "Der" } do
		local side = -(rig.side[`Oreja{s}`] or 0)
		local ear = Rig.follow(
			rig,
			`Oreja{s}`,
			v(if s == "Izq" then "earL" else "earR") - turn * 0.1,
			dt,
			4,
			0.4
		)
		Rig.turn(rig, `Oreja{s}`, -ear * 0.6, 0, ear * 0.3 * side + quiver * side)
	end
	-- Patas: la reverencia dobla las de adelante; agacharse, las cuatro.
	leg(rig, true, "Izq", v("stepFL"), bow * BOW_BEND + crouch, 0)
	leg(rig, true, "Der", v("stepFR"), bow * BOW_BEND + crouch, 0)
	leg(rig, false, "Izq", v("stepHL"), crouch - bow * 0.15, 0)
	leg(rig, false, "Der", v("stepHR"), crouch - bow * 0.15, 0)
end

return table.freeze(Pose)
