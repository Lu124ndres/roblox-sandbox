--!strict
--[[
	Pisotón: levanta la pata derecha echándose atrás y abriendo los brazos
	(anticipación), la sostiene temblando, la estampa de golpe (el impacto va sin
	suavizar) y el golpe lo hace agacharse con las dos rodillas, bajar la cabeza y
	abrir la boca; después se endereza. El muslo llega a 1.0 rad (57°): con el
	faldón del v2 es mejor que 55° (docs/decisiones.md, 2026-10-16).
]]

local Pose = require(script.Parent.Parent.Pose)
local C = require(script.Parent.Curvas)

return {
	name = "pisoton",
	seconds = 2.4,
	events = { { at = 0.52, kind = "stomp" } },
	pose = function(u: number): Pose.Pose
		local up = C.smooth(C.span(u, 0.05, 0.3)) * (1 - C.easeIn(C.span(u, 0.44, 0.52)))
		local back = C.hold(u, 0.05, 0.3, 0.44, 0.52)
		local hit = C.decay(u, 0.52, 9) * (1 - C.smooth(C.span(u, 0.85, 1)))
		local arms = C.hold(u, 0.05, 0.3, 0.75, 1)
		local tremble = math.sin(u * 90) * 0.03 * C.hold(u, 0.3, 0.33, 0.42, 0.44)
		return {
			legR = 1.0 * up + 0.4 * hit,
			kneeR = 1.2 * up + 0.8 * hit,
			legL = 0.4 * hit,
			kneeL = 0.8 * hit,
			sway = -0.12 * up,
			lean = 0.1 * back - 0.22 * hit + tremble,
			lookPitch = 0.15 * back - 0.35 * hit,
			armL = 0.3 * back - 0.2 * hit,
			armR = 0.3 * back - 0.2 * hit,
			outL = 0.6 * arms,
			outR = 0.6 * arms,
			elbowL = 0.4 * back,
			elbowR = 0.4 * back,
			jaw = 0.5 * hit,
			earL = -0.3 * arms,
			earR = -0.3 * arms,
			tailUp = 0.4 * back,
		}
	end,
}
