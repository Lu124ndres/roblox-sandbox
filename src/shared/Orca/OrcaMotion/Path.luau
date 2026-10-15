--!strict
--[[
	OrcaMotion/Path

	El recorrido de la orca dentro del lago del cráter como función de la hora
	del servidor (Workspace:GetServerTimeNow()): todos los clientes la ven en el
	mismo lugar sin mandar nada por la red.
		- Nada en vueltas que cambian solas de radio y de ritmo (parece al azar).
		- Cada BREATH_SECONDS baja un poco y vuelve a subir a respirar.
		- En algunos tramos de BREACH_SLOT segundos salta fuera del agua con un
		  giro completo (breach). Qué tramos y cuándo sale de un hash del tramo.
	Las alturas son del centro del cuerpo respecto al agua (negativo = hundida).
]]

local BREATH_SECONDS = 16
local BREACH_SLOT = 26
local BREACH_CHANCE = 0.55 -- tramos con salto
local BREACH_SECONDS = 3.6
local DIVE_END, AIR_END = 0.22, 0.82 -- partes del salto: tomar impulso, en el aire, volver a entrar

export type Sample = {
	position: Vector3, -- desde el centro del lago (Y = 0)
	velocity: Vector3,
	depth: number,
	breath: number, -- 0..1 del ciclo de respirar (0 = en la superficie)
	breach: number, -- -1 sin salto; 0..1 avance del salto
}

local Path = {}

local function hash(n: number): number
	local x = math.sin(n * 12.9898 + 78.233) * 43758.5453
	return x - math.floor(x)
end

local function smooth(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

-- Radio en que puede nadar sin que la cabeza toque el acantilado (el cuerpo
-- mide ~1.5 veces el alto del modelo). Las etapas grandes casi no se mueven.
function Path.radius(lakeRadius: number, height: number): number
	return math.max(0, lakeRadius - height * 0.9 - 4)
end

-- Velocidad de crucero en studs/s: las más grandes avanzan más rápido.
function Path.speed(height: number): number
	return 8 + 0.15 * height
end

local function point(t: number, radius: number, speed: number): Vector3
	if radius < 1 then
		return Vector3.zero
	end
	local omega = math.min(speed / (radius * 0.62), 0.35)
	local angle = omega * t + 0.9 * math.sin(t * 0.071)
	local r = radius * (0.62 + 0.28 * math.sin(t * 0.113 + 1.7) + 0.08 * math.sin(t * 0.31))
	return Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
end

local function breachProgress(t: number): number
	local slot = math.floor(t / BREACH_SLOT)
	if hash(slot) > BREACH_CHANCE then
		return -1
	end
	local start = slot * BREACH_SLOT + 3 + hash(slot + 0.5) * (BREACH_SLOT - BREACH_SECONDS - 4)
	local u = (t - start) / BREACH_SECONDS
	return if u >= 0 and u < 1 then u else -1
end

function Path.sample(t: number, radius: number, speed: number, height: number): Sample
	local position = point(t, radius, speed)
	local breath = (t % BREATH_SECONDS) / BREATH_SECONDS
	return {
		position = position,
		velocity = (point(t + 0.25, radius, speed) - position) / 0.25,
		depth = -height * (0.05 + 0.15 * math.sin(math.pi * breath) ^ 2), -- el lomo casi siempre se ve
		breath = breath,
		breach = breachProgress(t),
	}
end

-- Pose del salto en el avance u (0..1): altura del centro, cabeceo (+ = nariz
-- arriba) y giro sobre su eje. `from` es la altura de crucero al empezar.
function Path.breachPose(u: number, height: number, from: number): (number, number, number)
	local apex = height * math.clamp(1.15 - height / 200, 0.35, 1)
	local exit = -0.15 * height
	if u < DIVE_END then
		-- Se hunde tomando impulso y apunta la nariz hacia arriba.
		local a = u / DIVE_END
		local low = -0.45 * height
		local depth = if a < 0.6
			then from + (low - from) * smooth(a / 0.6)
			else low + (exit - low) * smooth((a - 0.6) / 0.4)
		local pitch = if a < 0.6
			then -0.35 * math.sin(math.pi * a / 0.6)
			else 0.95 * smooth((a - 0.6) / 0.4)
		return depth, pitch, 0
	elseif u < AIR_END then
		-- En el aire: parábola, la nariz pasa de arriba a abajo y da una vuelta.
		local b = (u - DIVE_END) / (AIR_END - DIVE_END)
		return exit + (apex - exit) * 4 * b * (1 - b), 0.95 - 2 * b, math.pi * 2 * smooth(b)
	end
	-- Entra al agua de cabeza y se endereza.
	local c = (u - AIR_END) / (1 - AIR_END)
	return exit + (from - 0.2 * height - exit) * smooth(c), -1.05 * (1 - smooth(c)), 0
end

return table.freeze(Path)
