--!strict
--[[
	Dragon/Vuelo

	El recorrido del dragón sobre el cráter, igual en todos los clientes (sale
	de la hora del servidor): vueltas alrededor del centro que se abren y se
	cierran, subiendo y bajando en olas largas. El tamaño del dragón cambia la
	vuelta (los grandes giran más abierto, más alto y más rápido): route() la
	arma para una etapa y sample() da dónde va y a qué velocidad en un momento.
	hermite() es el tramo suave entre dos puntos con sus velocidades (al
	posarse y al despegar, Dragon/Rutina): sale y llega tangente a cada uno.
]]

local Vuelo = {}

export type Sample = { position: Vector3, velocity: Vector3 }
export type Route = {
	center: Vector3,
	radius: number, -- vuelta
	base: number, -- altura media
	swing: number, -- cuánto sube y baja
	speed: number, -- studs/s
}

-- Lpath: largo del dragón de la etapa (fijo: la vuelta no salta al crecer).
function Vuelo.route(
	center: Vector3,
	Lpath: number,
	speedK: number,
	rim: number,
	lake: number
): Route
	return {
		center = center,
		radius = math.clamp(lake * 0.6 - Lpath * 0.2, 25, 130),
		base = rim + 16 + Lpath * 0.3,
		swing = 10 + Lpath * 0.12,
		speed = (20 + Lpath * 0.3) * speedK,
	}
end

local function at(now: number, r: Route, angular: number): Vector3
	local angle = now * angular
	local radius = r.radius * (1 + 0.16 * math.sin(now * 0.21) + 0.07 * math.sin(now * 0.77 + 1.3))
	local y = r.base + r.swing * (0.6 * math.sin(now * 0.19) + 0.4 * math.sin(now * 0.53 + 0.7))
	return Vector3.new(
		r.center.X + math.cos(angle) * radius,
		y,
		r.center.Z + math.sin(angle) * radius
	)
end

function Vuelo.sample(now: number, r: Route): Sample
	local angular = r.speed / math.max(r.radius, 1)
	local p = at(now, r, angular)
	local ahead = at(now + 0.05, r, angular)
	local behind = at(now - 0.05, r, angular)
	return { position = p, velocity = (ahead - behind) / 0.1 }
end

-- De p0 (velocidad v0) a p1 (v1) en `seconds`; k: avance 0..1.
function Vuelo.hermite(
	p0: Vector3,
	v0: Vector3,
	p1: Vector3,
	v1: Vector3,
	seconds: number,
	k: number
): Sample
	k = math.clamp(k, 0, 1)
	local m0, m1 = v0 * seconds, v1 * seconds
	local k2, k3 = k * k, k * k * k
	local position = p0 * (2 * k3 - 3 * k2 + 1)
		+ m0 * (k3 - 2 * k2 + k)
		+ p1 * (-2 * k3 + 3 * k2)
		+ m1 * (k3 - k2)
	local slope = p0 * (6 * k2 - 6 * k)
		+ m0 * (3 * k2 - 4 * k + 1)
		+ p1 * (-6 * k2 + 6 * k)
		+ m1 * (3 * k2 - 2 * k)
	return { position = position, velocity = slope / math.max(seconds, 1e-3) }
end

return table.freeze(Vuelo)
