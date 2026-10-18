--!strict
--[[
	Zorro/Pose

	La pose del zorro como una tabla de números (radianes o 0..1) que se suman:
	reposo, comer, la conducta y los pasos. apply() la reparte en los huesos:
		lean / sway / breathe      tronco: adelante (-) o atrás (+), de lado, respirar
		lookYaw / lookPitch / tilt cabeza: girar (+ a su izquierda), arriba/abajo, ladear
		                           (+ a su derecha)
		jaw / earL / earR          boca abierta (0..1); orejas paradas (+) o atrás (-)
		bow / crouch               reverencia (el pecho baja); agacharse (para saltar)
		stepFL/FR/HL/HR            levanta cada pata (0..1): delantera/trasera, Izq/Der
		sit / lie                  sentado erguido; echado, la panza sobre las patas
		curl / curlSide            enroscado (encima de lie) hacia su izquierda (+1) o
		                           derecha (-1): el lomo se curva, la nariz va a la cola
		scratch / scratchSide /    se rasca (desde sentado) con la trasera de ese lado;
		scratchBeat                el latido (-1..1) lo da la conducta
		pawL / pawR                la delantera de ese lado sube al hocico (lamerse)
		stretch / spine            estira las traseras atrás; curva el cuerpo de lado
		walk / walkPhase           cuánto camina y la fase del paso (recorrido /
		                           (Habitos.zancada x alto) x 2π): secuencia lateral
		pounce                     picada en el aire (el dy lo pone la conducta)
		shake / dy                 sacudida (0..1); salto (fracción del alto)
		tail*                      pedidos a Zorro/Colas (Colas/Traduccion): apply() no
		                           toca las colas
	La base baja Pose.drop(pose, etapa) (fracción del alto): quien pone el pivote la
	resta y las patas (Zorro/Patas) la usan para dejar los pies en el piso. Las cuentas
	del tronco están en Pose/Tronco y los números medidos, en Patas/Ajustes.
]]

local Ajustes = require(script.Parent.Patas.Ajustes)
local Cara = require(script.Parent.Cara)
local Habitos = require(script.Parent.Habitos)
local Patas = require(script.Parent.Patas)
local Rig = require(script.Parent.Rig)
local Tipos = require(script.Parent.Tipos)
local Tronco = require(script.Tronco)

export type Pose = { [string]: number }

local TAU = math.pi * 2

local Pose = {}

-- Cuánto baja la base al agacharse (fracción del alto, por crouch). Lo usan
-- Colas/Traduccion y Rutina/Cuadro (mejor: Pose.drop, que lo incluye).
Pose.CROUCH_DROP = 0.035
-- Sentado y echado en la etapa 3 (sit = 1, lie = 1). Cada etapa tiene el suyo
-- (Patas/Ajustes): lo exacto es Pose.drop(pose, etapa).
Pose.SIT_DROP = Ajustes.etapas[3].sitDrop
Pose.LIE_DROP = Ajustes.etapas[3].lieDrop

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

-- Cuánto baja la base (fracción del alto): agacharse, sentarse o echarse (con las patas
-- plegadas, medido por etapa), estirarse y caminar (un poco más bajo, y otro poco con
-- cada mano que pisa). Siempre un poco (SETTLE): las patas quedan apenas dobladas.
function Pose.drop(p: Pose, etapa: number): number
	local A = Ajustes.etapa(etapa)
	local walk = math.clamp(p.walk or 0, 0, 1)
	local body =
		math.max(math.clamp(p.sit or 0, 0, 1) * A.sitDrop, math.clamp(p.lie or 0, 0, 1) * A.lieDrop)
	local bob = Ajustes.BOB * walk * (0.5 + 0.5 * math.cos(2 * (p.walkPhase or 0) - math.pi))
	return Ajustes.SETTLE
		+ (p.crouch or 0) * Pose.CROUCH_DROP
		+ body
		+ math.clamp(p.stretch or 0, 0, 1) * Ajustes.STRETCH_DROP
		+ Ajustes.WALK_DROP * walk
		+ bob
end

-- turn: rad/s del giro del cuerpo (las orejas lo siguen tarde). La cabeza llega antes que
-- el cuello (hace de ojos). Las patas las escribe Zorro/Patas y la cara Zorro/Cara.
function Pose.apply(rig: Rig.Rig, p: Pose, turn: number, ctx: Tipos.Contexto)
	local dt = ctx.dt
	local A = Ajustes.etapa(ctx.etapa)
	local tr = Tronco.compute(p, A, Habitos.de(ctx.etapa).zancada, ctx.now)
	local quiver, breathe = tr.quiver, p.breathe or 0
	Rig.turn(rig, "Cadera", tr.cadera[1], tr.cadera[2], tr.cadera[3])
	Rig.turn(rig, "Columna", tr.columna[1], tr.columna[2], tr.columna[3])
	Rig.turn(rig, "Pecho", tr.pecho[1], tr.pecho[2], tr.pecho[3])
	local yaw = Rig.follow(rig, "Mirar", tr.yaw, dt, 1.2, 0.8)
	local yawHead = Rig.follow(rig, "MirarCabeza", tr.yaw, dt, 2.4, 0.85)
	local pitch = Rig.follow(rig, "Cabecear", tr.pitch, dt, 1.6, 0.8)
	local pitchHead = Rig.follow(rig, "CabecearCabeza", tr.pitch, dt, 2.6, 0.85)
	Rig.turn(rig, "Cuello1", pitch * 0.25, yaw * 0.2, tr.tilt * 0.2 - quiver * 0.5)
	Rig.turn(rig, "Cuello2", pitch * 0.25, yaw * 0.25, tr.tilt * 0.3)
	Rig.turn(
		rig,
		"Cabeza",
		pitchHead * 0.5 - breathe * 0.4,
		yawHead * 0.55,
		tr.tilt * 0.5 + quiver * 0.4
	)
	Rig.turn(rig, "Mandibula", -0.6 * math.clamp((p.jaw or 0) + tr.jaw, -0.1, 1.1), 0, 0)
	for _, s in { "Izq", "Der" } do
		local side = -(rig.side[`Oreja{s}`] or 0)
		local want = (p[if s == "Izq" then "earL" else "earR"] or 0) + tr.ears - turn * 0.1
		local ear = Rig.follow(rig, `Oreja{s}`, want, dt, 4, 0.4)
		Rig.turn(rig, `Oreja{s}`, -ear * 0.6, 0, ear * 0.3 * side + quiver * side)
	end
	Patas.apply(rig, p, ctx.height, {
		hip = tr.cadera[1],
		spine = tr.columna[1],
		chest = tr.pecho[1],
		drop = Pose.drop(p, ctx.etapa),
		legs = tr.legs,
		etapa = A,
	})
	Cara.apply(rig, p, ctx) -- Cara mira ctx.detail: lejos deja los párpados abiertos
end

return table.freeze(Pose)
