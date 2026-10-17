--!strict
--[[
	Minotauro/Comer/Gustos

	Lo que hace con un pez raro (rarity: 3 raro, 4 épico, 5 legendario y más). Cada
	una empieza con "glow" (le brillan los ojos del color de la rareza: MinoStand
	le agrega la rareza al evento) y es más grande cuanto más raro:
		brillo  raro: se queda helado de sorpresa (orejas paradas, boca abierta, la
		        cabeza atrás) y después festeja con los dos puños chicos, rebotando
		        en las rodillas y con la cola arriba (yum)
		alegria épico: se agacha y salta de alegría con los brazos en V (joy:
		        corazones); al caer se aplasta y rebota (hop: polvito). Sin salto (la
		        forma final) rebota en el lugar con los brazos arriba
		dorado  legendario o mítico: saca músculo como el truco (Trucos/Musculo,
		        con sus destellos dorados: flex), ruge de gusto con la cabeza atrás
		        (cheer) y al final revienta en oro (goldburst)
]]

local C = require(script.Parent.Parent.Trucos.Curvas)
local Pose = require(script.Parent.Parent.Pose)
local Musculo = require(script.Parent.Parent.Trucos.Musculo)
local Tipos = require(script.Parent.Tipos)

local brillo: Tipos.Move = {
	name = "brillo",
	seconds = 1.4,
	prio = 2,
	takes = 0.8,
	events = { { at = 0.05, kind = "glow" }, { at = 0.36, kind = "yum" } },
	pose = function(u: number, _ctx: Tipos.Ctx): Pose.Pose
		local shock = C.overshoot(C.span(u, 0.02, 0.14)) * (1 - C.smooth(C.span(u, 0.26, 0.36)))
		local cheer = C.hold(u, 0.3, 0.42, 0.82, 1)
		local bounce = math.max(0, math.sin(C.span(u, 0.36, 0.86) * math.pi * 4)) * cheer
		local fists = 1.3 * cheer + 0.15 * bounce
		return {
			lookPitch = 0.25 * shock + 0.12 * cheer - 0.05 * bounce,
			lean = 0.1 * shock + 0.05 * cheer,
			jaw = 0.75 * shock + 0.3 * cheer,
			earL = 0.55 * shock + 0.35 * cheer,
			earR = 0.55 * shock + 0.35 * cheer,
			armL = 0.2 * shock + 0.65 * cheer,
			armR = 0.2 * shock + 0.65 * cheer,
			outL = 0.35 * shock + 0.35 * cheer,
			outR = 0.35 * shock + 0.35 * cheer,
			elbowL = fists,
			elbowR = fists,
			legL = 0.12 * bounce,
			legR = 0.12 * bounce,
			kneeL = 0.35 * bounce,
			kneeR = 0.35 * bounce,
			tilt = 0.15 * math.sin(u * 14) * cheer,
			tail1 = 0.6 * math.sin(u * 34) * cheer,
			tailUp = 0.5 * cheer,
		}
	end,
}

local alegria: Tipos.Move = {
	name = "alegria",
	seconds = 1.6,
	prio = 2,
	takes = 0.95,
	events = {
		{ at = 0.04, kind = "glow" },
		{ at = 0.3, kind = "joy" },
		{ at = 0.66, kind = "hop" },
	},
	pose = function(u: number, ctx: Tipos.Ctx): Pose.Pose
		local load = C.smooth(C.span(u, 0, 0.24)) * (1 - C.easeIn(C.span(u, 0.24, 0.3)))
		local up = C.overshoot(C.span(u, 0.28, 0.4)) * (1 - C.smooth(C.span(u, 0.75, 0.98)))
		local flight = C.span(u, 0.3, 0.66)
		local air = ctx.hop
			* C.smooth(C.span(u, 0.29, 0.32))
			* (1 - C.smooth(C.span(u, 0.64, 0.67)))
		local tuck = ctx.hop * C.bell(C.span(u, 0.38, 0.6))
		local land = C.decay(u, 0.66, 11) * (1 - C.smooth(C.span(u, 0.85, 1)))
		local stomp = (1 - ctx.hop) * math.max(0, math.sin(flight * math.pi * 3)) -- sin salto
		local knee = 1.1 * load + 0.8 * tuck + 0.9 * land + 0.5 * stomp
		return {
			air = air,
			dy = 0.16 * ctx.hop * C.arc(flight),
			legL = 0.55 * load + 0.45 * tuck + 0.45 * land + 0.25 * stomp,
			legR = 0.55 * load + 0.45 * tuck + 0.45 * land + 0.25 * stomp,
			kneeL = knee,
			kneeR = knee,
			lean = -0.22 * load + 0.12 * up - 0.18 * land,
			lookPitch = -0.15 * load + 0.35 * up - 0.15 * land,
			armL = -0.4 * load + 2.3 * up,
			armR = -0.4 * load + 2.3 * up,
			outL = 0.55 * up,
			outR = 0.55 * up,
			elbowL = 0.3 * load + 0.25 * up,
			elbowR = 0.3 * load + 0.25 * up,
			jaw = 0.7 * up,
			earL = 0.6 * up,
			earR = 0.6 * up,
			tailUp = 0.6 * up,
		}
	end,
}

local MUSCLE = 0.8 -- avance del truco Musculo que usa (deja afuera su final lento)

local dorado: Tipos.Move = {
	name = "dorado",
	seconds = 2.6,
	prio = 2,
	takes = 1,
	events = {
		{ at = 0.03, kind = "glow" },
		{ at = 0.3, kind = "flex" },
		{ at = 0.55, kind = "cheer" },
		{ at = 0.8, kind = "goldburst" },
	},
	pose = function(u: number, _ctx: Tipos.Ctx): Pose.Pose
		local out = Musculo.pose(math.min(1, u * MUSCLE))
		local fade = 1 - C.smooth(C.span(u, 0.85, 1))
		for key, value in out do
			out[key] = value * fade
		end
		local roar = C.hold(u, 0.52, 0.6, 0.78, 0.92)
		local shake = math.sin(u * 70) * 0.05 * roar
		Pose.add(out, {
			lookPitch = 0.4 * roar + shake,
			lean = 0.12 * roar,
			jaw = 0.9 * roar,
			earL = -0.4 * roar,
			earR = -0.4 * roar,
			tailUp = 0.6 * roar,
		})
		return out
	end,
}

return table.freeze({
	brillo = table.freeze(brillo),
	alegria = table.freeze(alegria),
	dorado = table.freeze(dorado),
})
