--!strict
--[[
	OrcaMotion/Steer

	El nado en el plano: la orca persigue un punto (su recorrido o la orilla de
	quien la alimenta) con velocidad y giro limitados, así nunca se teletransporta
	ni gira de golpe. Mira hacia donde nada; cerca de la meta puede mirar hacia
	otro lado (la orilla). `turn` (rad/s) dobla la cola y la inclina en las curvas.
]]

local TURN_RATE = 1.1 -- rad/s como máximo
local CHASE = 0.9 -- qué tanto corrige la distancia a la meta (1/s)

export type Steer = {
	position: Vector3, -- desde el centro del lago (Y = 0)
	velocity: Vector3,
	yaw: number,
	turn: number,
}

local Steer = {}

function Steer.yawOf(direction: Vector3): number
	return math.atan2(-direction.X, -direction.Z) -- Angles(0, y, 0) mira a (-sin y, 0, -cos y)
end

local function wrap(angle: number): number
	return (angle + math.pi) % (2 * math.pi) - math.pi
end

function Steer.new(position: Vector3, velocity: Vector3): Steer
	return {
		position = position,
		velocity = velocity,
		yaw = if velocity.Magnitude > 0.5 then Steer.yawOf(velocity) else 0,
		turn = 0,
	}
end

-- goalVelocity: cómo se mueve la meta; face: hacia dónde mirar al llegar (o nil).
function Steer.update(
	steer: Steer,
	dt: number,
	goal: Vector3,
	goalVelocity: Vector3,
	maxSpeed: number,
	face: Vector3?,
	idleYaw: number?
)
	local wanted = goalVelocity + (goal - steer.position) * CHASE
	if wanted.Magnitude > maxSpeed then
		wanted = wanted.Unit * maxSpeed
	end
	steer.velocity = steer.velocity:Lerp(wanted, 1 - math.exp(-dt * 2.2))
	steer.position += steer.velocity * dt

	local wantYaw = steer.yaw
	if face then
		wantYaw = Steer.yawOf(face)
	elseif steer.velocity.Magnitude > 0.5 then
		wantYaw = Steer.yawOf(steer.velocity)
	elseif idleYaw then
		wantYaw = idleYaw
	end
	local change = wrap(wantYaw - steer.yaw) * (1 - math.exp(-dt * 2.5))
	change = math.clamp(change, -TURN_RATE * dt, TURN_RATE * dt)
	steer.yaw = wrap(steer.yaw + change)
	steer.turn += (change / dt - steer.turn) * (1 - math.exp(-dt * 4))
end

return table.freeze(Steer)
