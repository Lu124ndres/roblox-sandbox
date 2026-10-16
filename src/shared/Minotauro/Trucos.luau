--!strict
--[[
	Minotauro/Trucos

	Los trucos del minotauro, sincronizados por la hora del servidor (todos los
	ven a la vez): cada EVERY segundos puede empezar uno. pose(u) da, para el
	avance u (0..1), lo que se suma a su pose (Minotauro/Pose):
		pisoton   levanta una pata y la estampa: ola y temblor
		rugido    se echa atrás, abre los brazos y ruge con la boca abierta
		musculo   saca músculo con los dos brazos y brilla
		baile     saltitos de lado a lado moviendo los brazos, feliz
		rascarse  se rasca la cabeza entre los cuernos
		salto     se agacha y salta; al caer, salpica
	events: momentos con sonido o efecto (stomp, roar, flex, happy, land).
]]

local Pose = require(script.Parent.Pose)

export type Trick = {
	name: string,
	seconds: number,
	events: { { at: number, kind: string } },
	pose: (u: number) -> Pose.Pose,
}

local EVERY = 11 -- segundos entre trucos
local ORDER = { "pisoton", "rugido", "baile", "musculo", "rascarse", "salto", "pisoton", "baile" }

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
-- Sube en [a, b], se queda, y baja en [c, d].
local function hold(u: number, a: number, b: number, c: number, d: number): number
	return smooth(span(u, a, b)) * (1 - smooth(span(u, c, d)))
end

local TRICKS: { [string]: Trick } = {
	pisoton = {
		name = "pisoton",
		seconds = 2.4,
		events = { { at = 0.52, kind = "stomp" } },
		pose = function(u: number): Pose.Pose
			local up = smooth(span(u, 0.05, 0.45)) * (1 - smooth(span(u, 0.45, 0.52)))
			local b = hold(u, 0.05, 0.3, 0.75, 1)
			return {
				legR = 1.0 * up,
				kneeR = 1.2 * up,
				sway = -0.12 * up,
				lean = -0.12 * up + 0.08 * bell(span(u, 0.52, 0.8)),
				outL = 0.5 * b,
				outR = 0.5 * b,
				lookPitch = -0.2 * b,
				earL = -0.3 * b,
				earR = -0.3 * b,
			}
		end,
	},
	rugido = {
		name = "rugido",
		seconds = 3.2,
		events = { { at = 0.25, kind = "roar" } },
		pose = function(u: number): Pose.Pose
			local open = hold(u, 0.12, 0.28, 0.75, 0.92)
			local shake = math.sin(u * 60) * 0.04 * open
			return {
				lean = 0.22 * open,
				lookPitch = 0.45 * open + shake,
				jaw = 1.1 * open,
				outL = 0.9 * open,
				outR = 0.9 * open,
				armL = 0.4 * open,
				armR = 0.4 * open,
				elbowL = 0.5 * open,
				elbowR = 0.5 * open,
				earL = -0.6 * open,
				earR = -0.6 * open,
				tailUp = 0.6 * open,
			}
		end,
	},
	musculo = {
		name = "musculo",
		seconds = 3.4,
		events = { { at = 0.3, kind = "flex" } },
		pose = function(u: number): Pose.Pose
			local f = hold(u, 0.05, 0.25, 0.8, 0.97)
			local pump = 0.12 * math.sin(u * 28) * f
			return {
				outL = 1.25 * f,
				outR = 1.25 * f,
				elbowOutL = 1.5 * f + pump,
				elbowOutR = 1.5 * f - pump,
				lean = 0.08 * f,
				lookYaw = 0.5 * math.sin(u * math.pi * 2) * f,
				tilt = 0.15 * f,
				jaw = 0.25 * f,
			}
		end,
	},
	baile = {
		name = "baile",
		seconds = 4,
		events = { { at = 0.1, kind = "happy" } },
		pose = function(u: number): Pose.Pose
			local b = hold(u, 0, 0.1, 0.9, 1)
			local beat = math.sin(u * math.pi * 8)
			return {
				dy = 0.05 * math.abs(beat) * b,
				sway = 0.16 * beat * b,
				tilt = 0.25 * beat * b,
				armL = 0.9 * beat * b,
				armR = -0.9 * beat * b,
				outL = 0.35 * b,
				outR = 0.35 * b,
				elbowL = 0.6 * b,
				elbowR = 0.6 * b,
				legL = 0.25 * math.max(0, beat) * b,
				kneeL = 0.4 * math.max(0, beat) * b,
				legR = 0.25 * math.max(0, -beat) * b,
				kneeR = 0.4 * math.max(0, -beat) * b,
				jaw = 0.3 * b,
				tail1 = 0.5 * beat * b,
				tail2 = 0.6 * beat * b,
			}
		end,
	},
	rascarse = {
		name = "rascarse",
		seconds = 3,
		events = {},
		pose = function(u: number): Pose.Pose
			local f = hold(u, 0.05, 0.25, 0.8, 0.97)
			local scratch = 0.15 * math.sin(u * 45) * f
			return {
				armR = 1.6 * f,
				outR = 0.7 * f,
				elbowR = 1.7 * f + scratch,
				tilt = -0.3 * f,
				lookPitch = -0.1 * f,
				earL = 0.3 * f,
				jaw = 0.15 * f,
			}
		end,
	},
	salto = {
		name = "salto",
		seconds = 1.8,
		events = { { at = 0.78, kind = "land" } },
		pose = function(u: number): Pose.Pose
			local crouch = bell(span(u, 0, 0.3)) + 0.6 * bell(span(u, 0.76, 0.95))
			local air = bell(span(u, 0.28, 0.78))
			return {
				dy = 0.32 * air,
				legL = 0.5 * crouch + 0.3 * air,
				legR = 0.5 * crouch + 0.3 * air,
				kneeL = 0.8 * crouch + 0.5 * air,
				kneeR = 0.8 * crouch + 0.5 * air,
				lean = -0.2 * crouch + 0.1 * air,
				outL = 1.1 * air,
				outR = 1.1 * air,
				armL = 0.5 * air,
				armR = 0.5 * air,
				jaw = 0.4 * air,
				earL = 0.5 * air,
				earR = 0.5 * air,
			}
		end,
	},
}

local Trucos = {}

-- Truco que está haciendo ahora (o nil), su avance 0..1 y el tramo (para los eventos).
function Trucos.current(now: number): (Trick?, number, number)
	local slot = math.floor(now / EVERY)
	local hash = (slot * 2654435761) % 1000 / 1000
	if hash < 0.2 then
		return nil, 0, slot -- este tramo sin truco
	end
	local trick = TRICKS[ORDER[slot % #ORDER + 1]]
	local u = (now - slot * EVERY - EVERY * 0.3) / trick.seconds
	if u < 0 or u > 1 then
		return nil, 0, slot
	end
	return trick, u, slot
end

return table.freeze(Trucos)
