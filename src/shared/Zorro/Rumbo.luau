--!strict
--[[
	Zorro/Rumbo

	Dónde está y hacia dónde mira el cuerpo en cada cuadro (en este cliente):
		- sin nada que lo saque de la rutina, es el plan (Zorro/Rutina): el mismo
		  en todos los clientes;
		- con una meta (`goal`: ir a la orilla de quien le da de comer, volver al
		  centro con el lago vacío o quedarse quieto evolucionando) camina hasta
		  ahí por su cuenta: acelera, frena al llegar, gira antes de echar a andar
		  (no camina de costado) y al final mira hacia `face`;
		- cuando la meta se va, vuelve caminando a donde el plan dice que está ya
		  y, al alcanzarlo, se pega a él (la fase de los pasos se acomoda de a poco).
		  También vuelve caminando si el plan salta (otra etapa: otros lugares).
	weight (0..1) es cuánto manda la rutina: las conductas se suman con ese peso
	(se apagan rápido al salir y entran despacio al volver).
]]

local Habitos = require(script.Parent.Habitos)
local Lugares = require(script.Parent.Rutina.Lugares)
local Rutina = require(script.Parent.Rutina)

export type Meta = {
	point: Vector3?, -- adónde ir (nil: se queda donde está)
	face: number?, -- rumbo al llegar (nil: el que trae)
	hurry: number, -- multiplica la velocidad de paseo
}
export type Rumbo = {
	started: boolean,
	free: boolean,
	pos: Vector3,
	yaw: number,
	speed: number,
	phase: number,
	offset: number, -- fase propia menos la del plan (se va a cero)
	weight: number,
}
export type Paso = {
	position: Vector3,
	yaw: number,
	walk: number,
	walkPhase: number,
	turning: number,
	weight: number,
	floe: boolean,
	giro: number, -- rad/s
}

local TAU = math.pi * 2
local JUMP = 0.08 -- altos: si el plan salta más que esto, vuelve caminando
local JOIN = 0.03 -- altos: más cerca que esto del plan, se pega a él
local JOIN_YAW = 0.12 -- rad
local NEAR = 0.3 -- altos: más cerca que esto del plan, se funde con él
local MERGE = 3 -- 1/s: qué tan rápido se funde
local BRAKE = 1.2 -- 1/s: cerca de la meta quiere ir a BRAKE × distancia
local ACCEL = 2.5 -- 1/s
local LEAVE, ENTER = 5, 1.5 -- 1/s: qué tan rápido se apagan y entran las conductas
local SYNC = 2 -- 1/s: cómo se acomoda la fase al plan

local Rumbo = {}

local function wrap(a: number): number
	return (a + math.pi) % TAU - math.pi
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

function Rumbo.new(): Rumbo
	return {
		started = false,
		free = false,
		pos = Vector3.zero,
		yaw = 0,
		speed = 0,
		phase = 0,
		offset = 0,
		weight = 1,
	}
end

-- Camina por su cuenta hacia `point` y gira hacia `face` al llegar.
local function walkTo(
	r: Rumbo,
	point: Vector3,
	face: number?,
	top: number,
	giro: number,
	dt: number
): (number, number)
	local delta = flat(point - r.pos)
	local distance = delta.Magnitude
	local target = face or r.yaw
	local want = if distance > 0.3 then math.min(top, distance * BRAKE) else 0
	if distance > 0.3 then
		target = math.atan2(-delta.X, -delta.Z)
		-- No camina de costado: frena mientras gira hacia donde va.
		want *= math.clamp(1 - math.abs(wrap(target - r.yaw)) / 1.2, 0, 1)
	end
	local turn = math.clamp(wrap(target - r.yaw) * 3, -giro, giro) * dt
	r.yaw += turn
	r.speed += (want - r.speed) * (1 - math.exp(-dt * ACCEL))
	if distance > 0.05 and r.speed > 0.01 then
		r.pos += delta.Unit * math.min(r.speed * dt, distance)
	end
	return math.clamp(r.speed / top, 0, 1), math.clamp(math.abs(turn / dt) / giro, 0, 1)
end

function Rumbo.step(
	r: Rumbo,
	plan: Rutina.Plan,
	meta: Meta?,
	height: number,
	etapa: number,
	dt: number
): Paso
	local habito = Habitos.de(etapa)
	local stride = habito.zancada * height
	if not r.started then -- recién lo ve: donde los demás ya lo ven
		r.started, r.pos, r.yaw = true, plan.position, plan.yaw
	end
	local lastYaw = r.yaw
	local gap = flat(plan.position - r.pos).Magnitude
	if meta or gap > JUMP * height then
		r.free = true
	end
	local walk, turning
	if r.free then
		local point = if meta then meta.point else plan.position
		local face = if meta then meta.face else plan.yaw
		local top = habito.velocidad * height * (if meta then meta.hurry else 1.3)
		local before = r.pos
		if not meta and gap < NEAR * height then
			-- Ya casi está: se funde con el plan (que puede ir caminando).
			local k = 1 - math.exp(-dt * MERGE)
			r.pos = r.pos:Lerp(plan.position, k)
			r.yaw += wrap(plan.yaw - r.yaw) * k
			walk, turning = math.max(plan.walk, math.clamp(r.speed / top, 0, 1)), plan.turning
			r.speed *= 1 - k
		else
			walk, turning = walkTo(r, point or r.pos, face, top, habito.giro, dt)
		end
		r.phase += flat(r.pos - before).Magnitude / stride * TAU
		r.weight *= math.exp(-dt * LEAVE)
		if not meta and gap < JOIN * height and math.abs(wrap(plan.yaw - r.yaw)) < JOIN_YAW then
			r.free = false
			r.offset = wrap(r.phase - plan.walkPhase)
		end
	else
		r.pos, r.yaw = plan.position, plan.yaw
		r.speed = plan.walk * habito.velocidad * height
		r.offset *= math.exp(-dt * SYNC)
		r.phase = plan.walkPhase + r.offset
		walk, turning = plan.walk, plan.turning
		r.weight += (1 - r.weight) * (1 - math.exp(-dt * ENTER))
	end
	local y, floe = Lugares.ground(r.pos)
	return {
		position = Vector3.new(r.pos.X, y, r.pos.Z),
		yaw = r.yaw,
		walk = walk,
		walkPhase = r.phase,
		turning = turning,
		weight = r.weight,
		floe = floe,
		giro = wrap(r.yaw - lastYaw) / dt,
	}
end

return table.freeze(Rumbo)
