--!strict
--[[
	OrcaMotion/Steer

	El nado en el plano, en este cliente: la orca persigue un punto (su recorrido o la
	orilla de quien la alimenta) como un animal y no como una flecha:
		- siempre avanza hacia donde mira (no se desliza de costado), así que al cambiar
		  de meta dibuja un arco natural; si la meta le queda detrás, frena y gira;
		- un giro muy grande lo da por el lado que mira hacia la rampa (Path.door);
		- frena a tiempo para llegar a la orilla sin pasarse, y nunca sale del radio de
		  nado (no se mete en la roca);
		- al descansar (el plan flota quieto) mira como el plan y se deja llevar despacio.
	Cuando deja de comer vuelve sola a su recorrido con ese mismo nado, sin saltos.
	`turn` (rad/s) dobla la cola y la inclina en las curvas.
]]

local Path = require(script.Parent.Path)

local TURN_RATE = 1.1 -- rad/s como máximo
local TURN_GAIN = 4 -- 1/s: qué tan rápido alcanza el rumbo que quiere
local CHASE = 0.9 -- 1/s: cuánto corrige la distancia a la meta
local SPEED_UP, SLOW_DOWN = 1, 2 -- 1/s: qué tan rápido acelera y frena
local BRAKE = 4 -- studs/s²: frena a tiempo para no pasarse de una meta quieta
local STILL_GOAL = 0.5 -- studs/s: una meta más lenta que esto está quieta
local BIG_TURN = 2.2 -- rad: giros más grandes eligen el lado de la rampa
local SMALL_TURN = 1 -- rad: al quedar debajo de esto el giro grande terminó
local MIN_ALIGN = 0.2 -- mientras gira mucho avanza al menos esta parte
local MOVING = 0.3 -- studs/s: más lento que esto no cambia de rumbo por la velocidad
local ON_PLAN = 0.2 -- altos: descansando y así de cerca del plan, mira como el plan
local MIN_ON_PLAN = 2 -- studs
local ROUTE_SPEED = 1.5 -- veces el crucero: lo más rápido que nada su recorrido
local FEED_SPEED = 2.2 -- veces el crucero: lo más rápido que va a comer
local FEED_REACH = 0.92 -- parte del radio de nado a la que llega para comer
local FACE_CLOSE = 0.3 -- desde esta cercanía a la orilla mira hacia quien le da de comer
local IDLE_SPIN = 0.1 -- rad/s: las etapas enormes giran despacio en el centro

export type Steer = {
	position: Vector3, -- desde el centro del lago (Y = 0)
	velocity: Vector3,
	yaw: number,
	turn: number,
	speed: number, -- studs/s hacia adelante
	side: number, -- sentido de un giro grande en curso (0 = ninguno)
	fresh: boolean, -- recién creada: toma el rumbo y la velocidad del plan
}
-- Lo que persigue: el recorrido (Path.Sample sirve) o un punto quieto.
export type Plan = {
	position: Vector3,
	velocity: Vector3,
	heading: number?, -- rumbo del plan
	resting: boolean?,
}

local Steer = {}

function Steer.yawOf(direction: Vector3): number
	return math.atan2(-direction.X, -direction.Z) -- Angles(0, y, 0) mira a (-sin y, 0, -cos y)
end

local function forward(yaw: number): Vector3
	return Vector3.new(-math.sin(yaw), 0, -math.cos(yaw))
end

local function wrap(angle: number): number
	return (angle + math.pi) % (2 * math.pi) - math.pi
end

local function sign(x: number): number
	return if x < 0 then -1 else 1
end

function Steer.new(position: Vector3, velocity: Vector3): Steer
	return {
		position = position,
		velocity = velocity,
		yaw = if velocity.Magnitude > 0.5 then Steer.yawOf(velocity) else 0,
		turn = 0,
		speed = velocity.Magnitude,
		side = 0,
		fresh = true,
	}
end

-- Un giro grande va por el lado que mira hacia la rampa (y lo sigue hasta terminarlo).
local function chooseSide(steer: Steer, diff: number): number
	if math.abs(diff) > BIG_TURN then
		if steer.side == 0 then
			local other = diff - sign(diff) * 2 * math.pi
			local toDoor = Path.door() - steer.position
			toDoor = if toDoor.Magnitude > 0 then toDoor.Unit else Vector3.zero
			local a = forward(steer.yaw + diff / 2):Dot(toDoor)
			local b = forward(steer.yaw + other / 2):Dot(toDoor)
			steer.side = if a >= b then sign(diff) else sign(other)
		end
		if sign(diff) ~= steer.side then
			diff -= sign(diff) * 2 * math.pi
		end
	elseif math.abs(diff) < SMALL_TURN then
		steer.side = 0
	end
	return diff
end

-- goalVelocity: cómo se mueve la meta; face: hacia dónde mirar al llegar (o nil);
-- planYaw y near: descansando y a menos de `near` studs del plan, mira como el plan.
function Steer.update(
	steer: Steer,
	dt: number,
	goal: Vector3,
	goalVelocity: Vector3,
	maxSpeed: number,
	face: Vector3?,
	idleYaw: number?,
	planYaw: number?,
	near: number?
)
	local err = goal - steer.position
	local desired = goalVelocity + err * CHASE
	local cap = maxSpeed
	if goalVelocity.Magnitude < STILL_GOAL then
		cap = math.min(cap, math.sqrt(2 * BRAKE * err.Magnitude))
	end
	if desired.Magnitude > cap then
		desired = if cap > 0 then desired.Unit * cap else Vector3.zero
	end
	-- llegó a comer (mira a la orilla) o descansa: se deja llevar, aunque sea de costado
	local drift = face ~= nil or (planYaw ~= nil and err.Magnitude < (near or 0))

	local wantYaw = steer.yaw
	if face then
		wantYaw = Steer.yawOf(face)
	elseif drift and planYaw then
		wantYaw = planYaw
	elseif desired.Magnitude > MOVING then
		wantYaw = Steer.yawOf(desired)
	elseif idleYaw then
		wantYaw = idleYaw
	end
	local diff = chooseSide(steer, wrap(wantYaw - steer.yaw))
	local change = diff * (1 - math.exp(-dt * TURN_GAIN))
	change = math.clamp(change, -TURN_RATE * dt, TURN_RATE * dt)
	steer.yaw = wrap(steer.yaw + change)
	steer.turn += (change / dt - steer.turn) * (1 - math.exp(-dt * 4))

	if drift then -- se deja llevar hacia la meta
		steer.velocity += (desired - steer.velocity) * (1 - math.exp(-dt * SLOW_DOWN))
		steer.speed = math.max(0, steer.velocity:Dot(forward(steer.yaw)))
	else -- nada: siempre hacia adelante, más despacio mientras gira mucho
		local target = desired.Magnitude * math.clamp(math.cos(diff), MIN_ALIGN, 1)
		local rate = if target > steer.speed then SPEED_UP else SLOW_DOWN
		steer.speed += (target - steer.speed) * (1 - math.exp(-dt * rate))
		steer.velocity = forward(steer.yaw) * steer.speed
	end
	steer.position += steer.velocity * dt
end

-- Persigue su recorrido (`path`) o, si alguien le da de comer, la orilla hacia
-- `direction`. Devuelve qué tan cerca está de esa orilla (0..1). Las etapas enormes
-- (radius < 1) giran en el centro.
function Steer.follow(
	steer: Steer,
	dt: number,
	path: Plan,
	direction: Vector3?,
	radius: number,
	height: number,
	cruise: number,
	boost: number, -- el truco la apura o la frena
	now: number
): number
	if steer.fresh then -- quien entra a mitad de partida la ve ya nadando su recorrido
		steer.fresh = false
		steer.yaw = path.heading or steer.yaw
		steer.speed = path.velocity.Magnitude
	end
	local goal = if direction then direction * radius * FEED_REACH else path.position
	local close = if direction
		then math.clamp(1 - (goal - steer.position).Magnitude / height, 0, 1)
		else 0
	local resting = path.resting == true and direction == nil and radius >= 1
	Steer.update(
		steer,
		dt,
		goal,
		if direction then Vector3.zero else path.velocity * boost,
		cruise * boost * (if direction then FEED_SPEED else ROUTE_SPEED),
		if direction and close > FACE_CLOSE then direction else nil,
		if radius < 1 then now * IDLE_SPIN else nil,
		if resting then path.heading else nil,
		math.max(MIN_ON_PLAN, ON_PLAN * height)
	)
	local m = steer.position.Magnitude -- nunca contra la roca
	if m > radius and m > 0 then
		steer.position *= radius / m
	end
	return close
end

return table.freeze(Steer)
