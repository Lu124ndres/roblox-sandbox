--!strict
--[[
	Olfatear: levanta un poco la cabeza (anticipación) y la baja hasta el suelo
	doblando las rodillas e inclinándose; olfatea moviendo el hocico de un lado a
	otro con golpecitos hacia abajo (sniff), da un pasito para seguir el rastro y
	mueve la cola; al final levanta la cabeza de golpe con un resoplido (snort),
	sacude las orejas y se endereza.
]]

local C = require(script.Parent.Parent.Trucos.Curvas)
local Pose = require(script.Parent.Parent.Pose)
local Tipos = require(script.Parent.Tipos)

local EVENTS: { Tipos.Event } = {
	{ at = 0.26, kind = "sniff" },
	{ at = 0.42, kind = "sniff" },
	{ at = 0.58, kind = "sniff" },
	{ at = 0.78, kind = "snort" },
}

return table.freeze({
	name = "olfatear",
	seconds = 5.5,
	events = function(_ctx: Tipos.Ctx): { Tipos.Event }
		return EVENTS
	end,
	pose = function(u: number, _ctx: Tipos.Ctx): Pose.Pose
		local lift = C.hold(u, 0, 0.06, 0.08, 0.14)
		local down = C.hold(u, 0.08, 0.2, 0.76, 0.9)
		local sniff = math.max(0, math.sin(u * 70)) * C.hold(u, 0.2, 0.24, 0.66, 0.72)
		local snout = math.sin(u * 22) * C.hold(u, 0.2, 0.28, 0.66, 0.74)
		local step = C.bell(C.span(u, 0.44, 0.54))
		local snort = C.decay(u, 0.78, 25) * (1 - C.smooth(C.span(u, 0.9, 1)))
		return {
			lookPitch = 0.12 * lift - 0.35 * down - 0.06 * sniff + 0.3 * snort,
			lookYaw = 0.2 * snout,
			tilt = 0.08 * snout,
			lean = 0.05 * lift - 0.4 * down,
			legL = 0.45 * down,
			legR = 0.45 * down + 0.15 * step,
			kneeL = 0.9 * down,
			kneeR = 0.9 * down + 0.3 * step,
			armL = 0.3 * down,
			armR = 0.3 * down,
			elbowL = 0.4 * down,
			elbowR = 0.4 * down,
			outL = 0.15 * down,
			outR = 0.15 * down,
			jaw = 0.08 * sniff + 0.3 * snort,
			earL = 0.3 * down + 0.5 * snort,
			earR = 0.3 * down + 0.5 * snort,
			tail1 = 0.45 * math.sin(u * 30) * down,
			tailUp = 0.3 * down,
		}
	end,
} :: Tipos.Behavior)
