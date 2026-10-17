--!strict
--[[
	Rugido: toma aire agachándose, con la cabeza abajo y los brazos recogidos
	(anticipación); revienta hacia atrás con la boca abierta, los brazos bien
	abiertos y la cola arriba (se pasa un poco y vuelve); sostiene el grito
	sacudiendo la cabeza y con el pecho agitado, y se suelta.
]]

local Pose = require(script.Parent.Parent.Pose)
local C = require(script.Parent.Curvas)

return {
	name = "rugido",
	seconds = 3.2,
	events = { { at = 0.25, kind = "roar" } },
	pose = function(u: number): Pose.Pose
		local gather = C.hold(u, 0, 0.18, 0.2, 0.27)
		local open = C.hold(u, 0.2, 0.28, 0.75, 0.92)
		local burst = C.overshoot(C.span(u, 0.2, 0.3)) * (1 - C.smooth(C.span(u, 0.75, 0.92)))
		local shake = math.sin(u * 60) * 0.05 * open
		local heave = math.sin(u * 22) * 0.04 * open
		return {
			lean = -0.12 * gather + 0.24 * burst + heave,
			lookPitch = -0.25 * gather + 0.45 * burst + shake,
			lookYaw = 0.12 * math.sin(u * 14) * open,
			jaw = 1.1 * open,
			armL = 0.2 * gather + 0.4 * open,
			armR = 0.2 * gather + 0.4 * open,
			outL = -0.1 * gather + 0.9 * burst,
			outR = -0.1 * gather + 0.9 * burst,
			elbowL = 0.9 * gather + 0.5 * open,
			elbowR = 0.9 * gather + 0.5 * open,
			legL = 0.3 * gather,
			legR = 0.3 * gather,
			kneeL = 0.6 * gather,
			kneeR = 0.6 * gather,
			earL = 0.3 * gather - 0.6 * open,
			earR = 0.3 * gather - 0.6 * open,
			tailUp = -0.2 * gather + 0.7 * burst,
		}
	end,
}
