--!strict
--[[
	Zorro/Trucos

	Los trucos del zorro de agua, sincronizados por la hora del servidor (todos los
	ven a la vez): cada EVERY segundos puede empezar uno. pose(u) da, para el avance
	u (0..1), lo que se suma a su pose (Zorro/Pose):
		aullido    se sienta un poco hacia atrás, levanta la cabeza y aúlla con las
		           colas abiertas hacia arriba
		abanico    abre las nueve colas como un abanico y las hace brillar
		salto      se agacha, salta y cae salpicando
		sacudida   se sacude el agua de todo el cuerpo
		reverencia baja el pecho con la cadera alta y menea las colas (quiere jugar)
		fuegos     llama a los fuegos fatuos: orbes de agua que suben a su alrededor
	events: momentos con sonido o efecto (howl, fan, crouch, land, shake, happy, orbs).
]]

local Pose = require(script.Parent.Pose)

export type Trick = {
	name: string,
	seconds: number,
	events: { { at: number, kind: string } },
	pose: (u: number) -> Pose.Pose,
}

local EVERY = 13 -- segundos entre trucos
local ORDER =
	{ "abanico", "aullido", "reverencia", "fuegos", "sacudida", "salto", "abanico", "aullido" }

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
	aullido = {
		name = "aullido",
		seconds = 3.6,
		events = { { at = 0.28, kind = "howl" } },
		pose = function(u: number): Pose.Pose
			local f = hold(u, 0.08, 0.26, 0.78, 0.95)
			local tremble = math.sin(u * 70) * 0.025 * f
			return {
				crouch = 0.25 * f,
				lean = 0.18 * f,
				lookPitch = 0.75 * f + tremble,
				lookYaw = -0.3 * f,
				jaw = 0.85 * f,
				earL = -0.5 * f,
				earR = -0.5 * f,
				tailFan = 0.9 * f,
				tailLift = 0.6 * f,
				tailCalm = -0.5 * f,
			}
		end,
	},
	abanico = {
		name = "abanico",
		seconds = 4.2,
		events = { { at = 0.22, kind = "fan" } },
		pose = function(u: number): Pose.Pose
			local f = hold(u, 0.05, 0.25, 0.8, 0.98)
			return {
				tailFan = 1.4 * f,
				tailLift = 0.5 * f,
				tailCalm = 0.8 * f,
				lean = 0.06 * f,
				lookPitch = 0.12 * f,
				earL = 0.4 * f,
				earR = 0.4 * f,
			}
		end,
	},
	salto = {
		name = "salto",
		seconds = 2.2,
		events = { { at = 0.2, kind = "crouch" }, { at = 0.74, kind = "land" } },
		pose = function(u: number): Pose.Pose
			local crouch = bell(span(u, 0, 0.32)) + 0.7 * bell(span(u, 0.72, 0.95))
			local air = bell(span(u, 0.3, 0.74))
			return {
				dy = 0.35 * air,
				crouch = 0.6 * crouch - 0.35 * air,
				lean = -0.12 * crouch
					+ 0.1 * math.sin(math.pi * span(u, 0.3, 0.74) - math.pi / 2) * air,
				stepFL = 0.7 * air,
				stepFR = 0.7 * air,
				stepHL = 0.5 * air,
				stepHR = 0.5 * air,
				tailLift = -0.15 * air + 0.3 * crouch, -- en el aire las colas apenas bajan (no tocan el agua)
				earL = -0.4 * air,
				earR = -0.4 * air,
				jaw = 0.3 * air,
			}
		end,
	},
	sacudida = {
		name = "sacudida",
		seconds = 2.4,
		events = { { at = 0.3, kind = "shake" } },
		pose = function(u: number): Pose.Pose
			local f = hold(u, 0.1, 0.25, 0.75, 0.95)
			return {
				shake = f,
				crouch = 0.1 * f,
				lookPitch = -0.1 * f,
				tailWag = 1.2 * f,
				earL = -0.3 * f,
				earR = -0.3 * f,
			}
		end,
	},
	reverencia = {
		name = "reverencia",
		seconds = 3.4,
		events = { { at = 0.25, kind = "happy" } },
		pose = function(u: number): Pose.Pose
			local f = hold(u, 0.05, 0.25, 0.8, 0.97)
			local bounce = 0.5 + 0.5 * math.sin(u * math.pi * 6)
			return {
				bow = 0.9 * f * (0.85 + 0.15 * bounce),
				lookPitch = 0.35 * f,
				tilt = 0.25 * f * math.sin(u * math.pi * 3),
				jaw = 0.35 * f,
				earL = 0.5 * f,
				earR = 0.5 * f,
				tailWag = 1.4 * f,
				tailLift = 0.4 * f,
			}
		end,
	},
	fuegos = {
		name = "fuegos",
		seconds = 4,
		events = { { at = 0.2, kind = "orbs" }, { at = 0.55, kind = "orbs" } },
		pose = function(u: number): Pose.Pose
			local f = hold(u, 0.05, 0.22, 0.82, 0.98)
			local look = math.sin(u * math.pi * 2)
			return {
				crouch = 0.18 * f,
				lookPitch = 0.4 * f,
				lookYaw = 0.5 * look * f,
				tailFan = 0.7 * f,
				tailLift = 0.3 * f,
				tailCalm = 1.2 * f,
				earL = 0.3 * f,
				earR = 0.3 * f,
				jaw = 0.2 * f,
			}
		end,
	},
}

local Trucos = {}

-- Truco que está haciendo ahora (o nil), su avance 0..1 y el tramo (para los eventos).
function Trucos.current(now: number): (Trick?, number, number)
	local slot = math.floor(now / EVERY)
	local hash = (slot * 2654435761) % 1000 / 1000
	if hash < 0.15 then
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
