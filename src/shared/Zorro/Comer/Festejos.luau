--!strict
--[[
	Zorro/Comer/Festejos

	Las celebraciones de los combos (peces seguidos, FedInfo.streak):
		cola     (5) reverencia de juego mirando su cola por encima del hombro y
		         la persigue: dos vueltas sobre sí a saltitos, tirando mordiscos al
		         aire; al parar queda mareado (se tambalea) y salen corazones
		carrera  (15) se agacha mirando hacia dónde va a salir y corre en círculo
		         por el lago, galopando y inclinado hacia adentro, con la estela de
		         agua detrás; frena derrapando y ladra
		gran     (30, y cada 30 más) la carrera y, de vuelta en su lugar, el salto
		         mortal con el aullido largo y los fuegos fatuos
	El círculo de la carrera se cierra en el mismo lugar y las vueltas son
	enteras: al terminar no queda corrido ni girado.
	Eventos: yip, swirl (remolino de agua), happy, dash, skid y los de Grandes.
]]

local Clip = require(script.Parent.Clip)
local Curvas = require(script.Parent.Curvas)
local Grandes = require(script.Parent.Grandes)
local Pose = require(script.Parent.Parent.Pose)

local span, smooth, bell, hold = Curvas.span, Curvas.smooth, Curvas.bell, Curvas.hold
local TAU = math.pi * 2

local function cola(u: number, ctx: Clip.Ctx): Pose.Pose
	local s = ctx.side
	local turn = smooth(span(u, 0.18, 0.86))
	local busy = bell(span(u, 0.18, 0.86))
	local phase = TAU * 2 * turn * 4 -- cuatro pasos por vuelta
	local trot = 0.7 * busy
	local dizzy = Curvas.decay(u, 0.86, 9) * (1 - smooth(span(u, 0.92, 1)))
	return {
		take = hold(u, 0, 0.1, 0.9, 1),
		bow = 0.8 * hold(u, 0, 0.1, 0.18, 0.3),
		spinY = s * TAU * 2 * turn,
		lookYaw = s * 1.1 * hold(u, 0.04, 0.18, 0.84, 0.95),
		tilt = 0.25 * s * hold(u, 0.04, 0.18, 0.84, 0.95) + 0.3 * dizzy * math.sin((u - 0.86) * 28),
		sway = 0.07 * dizzy * math.sin((u - 0.86) * 22),
		lookPitch = 0.2 * hold(u, 0, 0.1, 0.84, 0.95),
		jaw = 0.25 * busy * (0.5 + 0.5 * math.sin(phase * 0.5)),
		stepFL = trot * math.max(0, math.sin(phase)),
		stepHR = trot * math.max(0, math.sin(phase)),
		stepFR = trot * math.max(0, -math.sin(phase)),
		stepHL = trot * math.max(0, -math.sin(phase)),
		dy = 0.035 * busy * math.abs(math.sin(phase)),
		gait = phase,
		trail = busy,
		earL = 0.45 * hold(u, 0, 0.1, 0.84, 1),
		earR = 0.45 * hold(u, 0, 0.1, 0.84, 1),
		tailWag = 1.2 * hold(u, 0, 0.1, 0.9, 1),
		tailFan = 0.6 * busy,
		tailLift = 0.4 * hold(u, 0, 0.1, 0.9, 1),
	}
end

local function carrera(u: number, ctx: Clip.Ctx): Pose.Pose
	local s, r = ctx.side, ctx.radius
	local run = span(u, 0.12, 0.88)
	local a = TAU * smooth(run)
	local speed = bell(run)
	local load = bell(span(u, 0, 0.14))
	local skid = bell(span(u, 0.86, 0.96))
	local bark = bell(span(u, 0.9, 0.98))
	local p: Pose.Pose = {
		take = hold(u, 0, 0.08, 0.92, 1),
		runX = s * (r * math.cos(a) - r),
		runZ = -r * math.sin(a),
		spinY = s * a,
		crouch = 0.5 * load + 0.4 * skid,
		lean = 0.08 * load - 0.08 * speed + 0.15 * skid,
		sway = -0.12 * s * speed,
		lookYaw = s * (0.4 * load + 0.25 * speed),
		lookPitch = 0.3 * bark,
		jaw = 0.3 * speed + 0.6 * bark,
		earL = -0.5 * speed + 0.4 * bark,
		earR = -0.5 * speed + 0.4 * bark,
		tailLift = 0.25 * speed,
		tailFan = 0.3 * speed + 0.4 * bark,
		tailCalm = -0.4 * speed,
		tailWag = 1 * bark,
		trail = math.min(1, speed * 1.6),
	}
	return Clip.mix(p, Clip.gallop(a * math.max(3, r * 14), speed))
end

-- Primero la carrera (más rápida que la de 15) y después el salto mortal con su
-- aullido; sin soltar la pose de comer entre los dos (take sigue en 1).
local RUN_SECONDS = 3.2
local RUN_PART = RUN_SECONDS / (RUN_SECONDS + Grandes.mortal.seconds)
local function gran(u: number, ctx: Clip.Ctx): Pose.Pose
	local p = if u < RUN_PART
		then carrera(u / RUN_PART, ctx)
		else Grandes.mortal.pose((u - RUN_PART) / (1 - RUN_PART), ctx)
	p.take = hold(u, 0, 0.04, 0.97, 1)
	return p
end

local granEvents: { Clip.Event } = {}
for _, e in
	{ { at = 0.12, kind = "dash" }, { at = 0.5, kind = "yip" }, { at = 0.88, kind = "skid" } }
do
	table.insert(granEvents, { at = e.at * RUN_PART, kind = e.kind })
end
for _, e in Grandes.mortal.events do
	table.insert(
		granEvents,
		{ at = RUN_PART + e.at * (1 - RUN_PART), kind = e.kind, rare = e.rare }
	)
end

local CLIPS: { [string]: Clip.Clip } = {
	cola = {
		name = "cola",
		seconds = 2.8,
		events = {
			{ at = 0.18, kind = "swirl" },
			{ at = 0.3, kind = "yip" },
			{ at = 0.62, kind = "yip" },
			{ at = 0.9, kind = "happy" },
		},
		pose = cola,
	},
	carrera = {
		name = "carrera",
		seconds = 4,
		events = {
			{ at = 0.12, kind = "dash" },
			{ at = 0.5, kind = "yip" },
			{ at = 0.88, kind = "skid" },
			{ at = 0.92, kind = "yip" },
			{ at = 0.96, kind = "happy" },
		},
		pose = carrera,
	},
	gran = {
		name = "gran",
		seconds = RUN_SECONDS + Grandes.mortal.seconds,
		events = granEvents,
		pose = gran,
	},
}

return table.freeze(CLIPS)
