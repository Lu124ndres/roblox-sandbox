--!strict
--[[
	Dragon/Rumbo

	Lleva al dragón hacia su meta con un resorte (sin tirones aunque la meta
	salte) y calcula su orientación: mira hacia donde vuela (o hacia quien le
	da de comer, o adonde mira posado), cabecea al subir y bajar, se ladea en
	las curvas como un avión y suma el giro de los trucos (la voltereta da la
	vuelta entera). pin manda sobre el resorte (pinW 0..1): al bajar a la roca,
	posado y al despegar, la rutina dice exactamente dónde está (todos lo ven
	en el mismo lugar) y el resorte queda ahí, así al soltarlo no salta.
]]

export type Rumbo = {
	position: Vector3?,
	velocity: Vector3,
	yaw: number,
	pitch: number,
	roll: number,
	yawRate: number,
	climb: number, -- -1 bajando .. 1 subiendo
}
export type Input = {
	goal: Vector3,
	flow: Vector3, -- velocidad del recorrido (la sigue además de la meta)
	feeding: number, -- 0..1
	face: Vector3?, -- hacia dónde mirar al comer
	facing: number?, -- yaw posado (manda)
	bank: number,
	pitch: number, -- de la pose
	roll: number?, -- del truco (manda)
	pin: Vector3?,
	pinVelocity: Vector3,
	pinW: number,
}

local Rumbo = {}

local function yawOf(d: Vector3): number
	return math.atan2(-d.X, -d.Z)
end
local function wrap(a: number): number
	return (a + math.pi) % (2 * math.pi) - math.pi
end
local function ease(dt: number, rate: number): number
	return 1 - math.exp(-dt * rate)
end

function Rumbo.new(): Rumbo
	return {
		position = nil,
		velocity = Vector3.zero,
		yaw = 0,
		pitch = 0,
		roll = 0,
		yawRate = 0,
		climb = 0,
	}
end

function Rumbo.update(r: Rumbo, dt: number, input: Input)
	local w = input.feeding
	local first = r.position == nil
	if first then
		r.position, r.velocity =
			input.pin or input.goal, if input.pin then input.pinVelocity else input.flow
	end
	local p = r.position :: Vector3
	local stiff = 2 * math.pi * (0.55 + 0.4 * w)
	local flow = input.flow * (1 - w)
	r.velocity += (stiff * stiff * (input.goal - p) - 1.8 * stiff * (r.velocity - flow)) * dt
	r.position = p + r.velocity * dt
	local pin = input.pin
	if pin and input.pinW > 0 then
		r.position = (r.position :: Vector3):Lerp(pin, input.pinW)
		r.velocity = r.velocity:Lerp(input.pinVelocity, input.pinW)
	end

	local flat = Vector3.new(r.velocity.X, 0, r.velocity.Z)
	local wantYaw = if flat.Magnitude > 2 then yawOf(flat) else r.yaw
	if input.face then
		wantYaw += wrap(yawOf(input.face) - wantYaw) * w
	end
	if input.facing then
		wantYaw = input.facing
	end
	if first then
		r.yaw = wantYaw
	end
	local turn = wrap(wantYaw - r.yaw)
	r.yaw += turn * ease(dt, 3)
	r.yawRate += (turn * 3 - r.yawRate) * ease(dt, 4)
	r.climb = math.clamp(r.velocity.Y / math.max(flat.Magnitude, 4), -1, 1)
	local wantPitch = r.climb * 0.6 * (1 - w) + 0.35 * w + input.pitch
	r.pitch += (wantPitch - r.pitch) * ease(dt, 4)
	local wantRoll = math.clamp(r.yawRate * input.bank * 0.5, -0.8, 0.8) * (1 - w) -- se ladea hacia la curva
	if input.roll then
		r.roll = wantRoll + input.roll
	else
		r.roll = wrap(r.roll)
		r.roll += (wantRoll - r.roll) * ease(dt, 3)
	end
end

return table.freeze(Rumbo)
