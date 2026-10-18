--!strict
--[[
	Zorro/Rumbo

	Hacia dónde gira el cuerpo del zorro: hacia quien le da de comer o, cada tanto,
	a otro lado del lago (sale de la hora del servidor: todos los clientes lo ven
	igual). Lo reemplaza Zorro/Rutina en la ola 3 (de frente a la rampa, témpanos).
]]

local TURN_SPEED = 0.8 -- rad/s como mucho al darse vuelta
local LOOK_EVERY = 18 -- segundos entre vueltas para mirar a otro lado

local Rumbo = {}

function Rumbo.towards(d: Vector3): number
	return math.atan2(-d.X, -d.Z) -- Angles(0, y, 0) mira a (-sin y, 0, -cos y)
end

-- Devuelve el rumbo nuevo, cuánto giró por segundo y cuánto está girando (0..1).
function Rumbo.step(
	yaw: number,
	direction: Vector3?,
	now: number,
	dt: number
): (number, number, number)
	local target: number
	if direction then
		target = Rumbo.towards(direction)
	else
		local slot = math.floor(now / LOOK_EVERY)
		target = ((slot * 2654435761) % 1000) / 1000 * math.pi * 2
	end
	local delta = (target - yaw + math.pi) % (math.pi * 2) - math.pi
	local turn = math.clamp(delta * 2.5, -TURN_SPEED, TURN_SPEED) * dt
	local rate = turn / dt
	return yaw + turn, rate, math.clamp(math.abs(rate) / TURN_SPEED * 1.5, 0, 1)
end

return table.freeze(Rumbo)
