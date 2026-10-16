--!strict
--[[
	Dragon/Trucos

	Los trucos del dragón, sincronizados por la hora del servidor (todos los
	ven a la vez). Cada `trickEvery` segundos puede empezar uno de los de su
	etapa (Dragon/Etapas). pose(u, L) da, para el avance u (0..1) y el largo L
	del dragón, lo que cambia del vuelo normal:
		rugido     se frena, se para en el aire con aletazos fuertes, levanta la
		           cabeza y ruge
		fuego      planea con la cabeza hacia la lava y echa fuego
		picada     pliega las alas y se tira en picada; abajo se recupera con
		           aletazos fuertes
		voltereta  una vuelta completa sobre su eje (la cría)
		planeo     alas extendidas sin aletear, largo rato
	events: momentos con sonido o efecto (roar, fire, whoosh).
]]

local Etapas = require(script.Parent.Etapas)

export type Pose = {
	speed: number?, -- multiplica la velocidad
	dy: number?, -- studs arriba/abajo del recorrido
	pitch: number?,
	roll: number?,
	flap: number?, -- multiplica la amplitud del aleteo (nil = la normal)
	fold: number?,
	jaw: number?,
	head: number?,
	hover: number?,
	fire: boolean?,
}
export type Trick = {
	name: string,
	seconds: number,
	events: { { at: number, kind: string } },
	pose: (u: number, L: number) -> Pose,
}

local function smooth(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end
local function span(u: number, a: number, b: number): number
	return math.clamp((u - a) / (b - a), 0, 1)
end
local function bell(t: number): number
	return math.sin(math.pi * math.clamp(t, 0, 1))
end

local TRICKS: { [string]: Trick } = {
	rugido = {
		name = "rugido",
		seconds = 4,
		events = { { at = 0.32, kind = "roar" } },
		pose = function(u: number, _L: number): Pose
			local b = bell(u)
			local open = bell(span(u, 0.25, 0.8))
			return {
				speed = 1 - 0.85 * b,
				hover = b,
				flap = 1 + 0.6 * b,
				pitch = 0.55 * b,
				head = 0.45 * open,
				jaw = open,
			}
		end,
	},
	fuego = {
		name = "fuego",
		seconds = 3.6,
		events = { { at = 0.22, kind = "fire" } },
		pose = function(u: number, _L: number): Pose
			local b = bell(u)
			local open = smooth(span(u, 0.15, 0.25)) * (1 - smooth(span(u, 0.85, 0.95)))
			return {
				flap = 1 - 0.7 * b,
				head = -0.45 * b,
				pitch = -0.12 * b,
				jaw = open,
				fire = u > 0.22 and u < 0.86,
			}
		end,
	},
	picada = {
		name = "picada",
		seconds = 4.2,
		events = { { at = 0.08, kind = "whoosh" }, { at = 0.55, kind = "flap" } },
		pose = function(u: number, L: number): Pose
			local dive = smooth(span(u, 0, 0.5))
			local pull = smooth(span(u, 0.5, 1))
			local depth = (25 + L * 0.4) * (dive - pull) -- baja y vuelve
			local fold = bell(span(u, 0.02, 0.55))
			return {
				dy = -depth,
				fold = fold,
				flap = if u < 0.5 then 0.15 else 1.6 * bell(span(u, 0.5, 1)) + 0.4,
				pitch = -0.75 * bell(span(u, 0, 0.55)) + 0.5 * bell(span(u, 0.45, 0.95)),
				speed = 1 + 0.8 * bell(u),
				head = 0.2 * bell(span(u, 0.5, 1)),
			}
		end,
	},
	voltereta = {
		name = "voltereta",
		seconds = 1.9,
		events = { { at = 0.1, kind = "whoosh" } },
		pose = function(u: number, _L: number): Pose
			return {
				roll = math.pi * 2 * smooth(u),
				flap = 0.4,
				fold = 0.35 * bell(u),
				dy = 3 * bell(u),
			}
		end,
	},
	planeo = {
		name = "planeo",
		seconds = 6,
		events = {},
		pose = function(u: number, _L: number): Pose
			return { flap = 1 - 0.95 * bell(u) ^ 0.5, pitch = -0.05 * bell(u), speed = 1.1 }
		end,
	},
}

local Trucos = {}

-- Truco que está haciendo ahora (o nil) y su avance 0..1.
function Trucos.current(now: number, profile: Etapas.Profile): (Trick?, number, number)
	local every = profile.trickEvery
	local slot = math.floor(now / every)
	local hash = (slot * 2654435761) % 1000 / 1000
	if hash < 0.22 then
		return nil, 0, slot -- este tramo sin truco
	end
	local trick = TRICKS[profile.tricks[slot % #profile.tricks + 1]]
	local start = slot * every + every * 0.25
	local u = (now - start) / trick.seconds
	if u < 0 or u > 1 then
		return nil, 0, slot
	end
	return trick, u, slot
end

return table.freeze(Trucos)
