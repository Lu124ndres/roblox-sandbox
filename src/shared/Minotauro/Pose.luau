--!strict
--[[
	Minotauro/Pose

	La pose del minotauro como una tabla de números (radianes) que se suman:
	reposo (respira, se mece, mueve la cola y las orejas, mira alrededor),
	comer (se inclina hacia quien le da, estira los brazos, abre la boca y
	mastica), pasitos al girar y el truco del momento (Minotauro/Trucos).
		lean / sway / breathe     tronco: adelante (-) o atrás (+), de lado, respirar
		lookYaw / lookPitch / tilt cabeza: girar (+ a su izquierda), arriba/abajo, ladear
		jaw                        boca abierta (0..1)
		earL / earR                orejas arriba (+) o atrás (-)
		armL / outL / elbowL / elbowOutL   brazo: adelante, abierto al costado, codo
		                           doblado adelante, antebrazo hacia arriba (por lado L/R)
		legL / kneeL               pierna: muslo adelante, rodilla doblada (L/R)
		tail1..tail3 / tailUp      cola: de lado a lado y arriba
		faldonF / faldonL / faldonR faldón: el de adelante se levanta, los de los
		                           costados se abren (huesos opcionales del v2)
		dy                         salto (fracción del alto)
		air                        en el aire (0..1): Cuerpo.plant no apoya los pies
	apply() la pasa a los huesos con Rig.turn.
]]

local Etapas = require(script.Parent.Etapas)
local Rig = require(script.Parent.Rig)

export type Pose = { [string]: number }

local TAU = math.pi * 2

local Pose = {}

function Pose.add(into: Pose, from: Pose, k: number?)
	local weight = k or 1
	for key, value in from do
		into[key] = (into[key] or 0) + value * weight
	end
end

local function wave(t: number, period: number, offset: number?): number
	return math.sin(TAU * t / period + (offset or 0))
end

-- Un movimiento rápido cada `period` segundos (orejas que se sacuden).
local function flick(t: number, period: number): number
	local u = (t % period) / 0.35
	return if u < 1 then math.sin(math.pi * u) else 0
end

-- El ritmo de la respiración y la cola y cuánto se mece dependen de la etapa.
function Pose.idle(t: number, profile: Etapas.Profile): Pose
	local tail, breath, k = profile.tail, profile.breathe, profile.sway
	return {
		breathe = 0.035 * k * wave(t, breath),
		sway = 0.04 * k * wave(t, breath * 1.28),
		lookYaw = 0.35 * wave(t, 9),
		lookPitch = 0.05 * wave(t, 5.3),
		tilt = 0.1 * wave(t, 6.3),
		armL = 0.07 * k * wave(t, breath, 0.5),
		armR = 0.07 * k * wave(t, breath, 2.1),
		outL = 0.1,
		outR = 0.1,
		elbowL = 0.15,
		elbowR = 0.15,
		earL = 0.5 * flick(t, 3.7) + 0.05 * wave(t, 2.5),
		earR = 0.5 * flick(t + 1.3, 4.3) + 0.05 * wave(t, 2.7),
		tail1 = 0.3 * wave(t, tail),
		tail2 = 0.4 * wave(t, tail, -0.7),
		tail3 = 0.5 * wave(t, tail, -1.4),
	}
end

-- w: cuánto está comiendo (0..1); biting: justo cerró la boca en un pez.
function Pose.feeding(w: number, t: number, biting: boolean): Pose
	local chew = 0.5 + 0.5 * math.sin(t * 9)
	return {
		lean = -0.18 * w,
		lookPitch = -0.12 * w - (if biting then 0.15 else 0),
		lookYaw = -0.3 * w * wave(t, 9), -- deja de mirar alrededor
		armL = 0.6 * w,
		armR = 0.6 * w,
		outL = 0.15 * w,
		outR = 0.15 * w,
		elbowL = 0.7 * w,
		elbowR = 0.7 * w,
		jaw = if biting then 0 else w * (0.35 + 0.25 * chew),
		earL = 0.35 * w,
		earR = 0.35 * w,
		tail1 = 0.4 * w * wave(t, 0.5),
		tail2 = 0.5 * w * wave(t, 0.5, -0.7),
		tail3 = 0.6 * w * wave(t, 0.5, -1.4),
		tailUp = 0.3 * w,
	}
end

-- Caminar: las piernas se alternan (la que va adelante dobla la rodilla al
-- levantarse), los brazos van al revés que las piernas, el tronco se inclina un
-- poco, se mece y sube y baja con cada paso; la cola acompaña.
function Pose.walk(phase: number, amount: number): Pose
	local s, c = math.sin(phase), math.cos(phase)
	return {
		legL = 0.55 * s * amount,
		legR = -0.55 * s * amount,
		kneeL = 0.75 * math.max(0, c) * amount,
		kneeR = 0.75 * math.max(0, -c) * amount,
		armL = -0.45 * s * amount,
		armR = 0.45 * s * amount,
		elbowL = 0.25 * amount,
		elbowR = 0.25 * amount,
		lean = -0.07 * amount,
		sway = 0.05 * s * amount,
		dy = 0.012 * math.abs(c) * amount,
		tail1 = 0.25 * s * amount,
		tail2 = 0.3 * s * amount,
	}
end

-- Pasitos mientras gira en el lugar: un pie y después el otro.
function Pose.steps(phase: number, amount: number): Pose
	local left, right = math.max(0, math.sin(phase)), math.max(0, -math.sin(phase))
	return {
		legL = 0.45 * left * amount,
		kneeL = 0.7 * left * amount,
		legR = 0.45 * right * amount,
		kneeR = 0.7 * right * amount,
		sway = 0.06 * math.sin(phase) * amount,
		armL = -0.2 * math.sin(phase) * amount,
		armR = 0.2 * math.sin(phase) * amount,
	}
end

function Pose.apply(rig: Rig.Rig, p: Pose)
	local function v(key: string): number
		return p[key] or 0
	end
	local lean, breathe = v("lean"), v("breathe")
	Rig.turn(rig, "Cadera", 0, 0, v("sway"))
	Rig.turn(rig, "Columna", lean * 0.5 + breathe, 0, -v("sway") * 0.5)
	Rig.turn(rig, "Pecho", lean * 0.5 + breathe * 0.6, v("lookYaw") * 0.2, 0)
	Rig.turn(rig, "Cuello", v("lookPitch") * 0.4, v("lookYaw") * 0.35, v("tilt") * 0.3)
	Rig.turn(
		rig,
		"Cabeza",
		v("lookPitch") * 0.6 - breathe * 0.5,
		v("lookYaw") * 0.45,
		v("tilt") * 0.7
	)
	Rig.turn(rig, "Mandibula", -0.5 * math.clamp(v("jaw"), 0, 1.2), 0, 0)
	for _, s in { "L", "R" } do
		local lado = if s == "L" then "Izq" else "Der"
		local out = -(rig.side["Brazo" .. lado] or 0) -- abrir hacia afuera
		local earSide = -(rig.side["Oreja" .. lado] or 0)
		Rig.turn(rig, "Oreja" .. lado, 0, 0, v("ear" .. s) * earSide)
		Rig.turn(rig, "Brazo" .. lado, v("arm" .. s), 0, v("out" .. s) * out)
		Rig.turn(rig, "Antebrazo" .. lado, v("elbow" .. s), 0, v("elbowOut" .. s) * out)
		Rig.turn(rig, "Mano" .. lado, v("elbow" .. s) * 0.2, 0, 0)
		local knee = v("knee" .. s)
		Rig.turn(rig, "Muslo" .. lado, v("leg" .. s), 0, 0)
		Rig.turn(rig, "Pierna" .. lado, -knee, 0, 0)
		Rig.turn(rig, "Pie" .. lado, knee * 0.5 - v("leg" .. s) * 0.4, 0, 0)
		Rig.turn(rig, "Faldon" .. lado, 0, 0, v("faldon" .. s) * out)
	end
	Rig.turn(rig, "FaldonFrente", v("faldonF"), 0, 0)
	local up = v("tailUp")
	Rig.turn(rig, "Cola1", -up, v("tail1"), 0) -- la cola apunta atrás: cabeceo - la sube
	Rig.turn(rig, "Cola2", -up * 0.5, v("tail2"), 0)
	Rig.turn(rig, "Cola3", 0, v("tail3"), 0)
end

return table.freeze(Pose)
