--!strict
--[[
	Dragon/Vuelo

	El recorrido del dragón sobre el cráter, igual en todos los clientes (sale
	de la hora del servidor): vueltas alrededor del centro que se abren y se
	cierran, subiendo y bajando en olas largas. El tamaño del dragón cambia la
	vuelta (los grandes giran más abierto, más alto y más rápido).
]]

local Vuelo = {}

export type Sample = { position: Vector3, velocity: Vector3 }

local function at(
	now: number,
	center: Vector3,
	radius: number,
	base: number,
	swing: number,
	angular: number
): Vector3
	local angle = now * angular
	local r = radius * (1 + 0.16 * math.sin(now * 0.21) + 0.07 * math.sin(now * 0.77 + 1.3))
	local y = base + swing * (0.6 * math.sin(now * 0.19) + 0.4 * math.sin(now * 0.53 + 0.7))
	return Vector3.new(center.X + math.cos(angle) * r, y, center.Z + math.sin(angle) * r)
end

-- radius: vuelta; base: altura media; swing: cuánto sube y baja; speed: studs/s.
function Vuelo.sample(
	now: number,
	center: Vector3,
	radius: number,
	base: number,
	swing: number,
	speed: number
): Sample
	local angular = speed / math.max(radius, 1)
	local p = at(now, center, radius, base, swing, angular)
	local ahead = at(now + 0.05, center, radius, base, swing, angular)
	local behind = at(now - 0.05, center, radius, base, swing, angular)
	return { position = p, velocity = (ahead - behind) / 0.1 }
end

return table.freeze(Vuelo)
