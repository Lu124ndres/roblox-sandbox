--!strict
--[[
	Salto: se agacha con los brazos atrás (aplastarse), se estira al despegar con
	los brazos arriba (estirarse), encoge las piernas en lo alto, las estira para
	caer y al tocar el agua se aplasta otra vez y rebota. La altura sigue una
	parábola (arco); en el aire (air) Cuerpo.plant no apoya los pies.
]]

local Pose = require(script.Parent.Parent.Pose)
local C = require(script.Parent.Curvas)

return {
	name = "salto",
	seconds = 1.8,
	events = { { at = 0.78, kind = "land" } },
	pose = function(u: number): Pose.Pose
		local load = C.smooth(C.span(u, 0, 0.22)) * (1 - C.easeIn(C.span(u, 0.22, 0.3)))
		local air = C.smooth(C.span(u, 0.28, 0.32)) * (1 - C.smooth(C.span(u, 0.76, 0.8)))
		local launch = C.decay(u, 0.3, 14)
		local tuck = C.bell(C.span(u, 0.38, 0.7))
		local land = C.decay(u, 0.78, 10) * (1 - C.smooth(C.span(u, 0.92, 1)))
		local swing = C.bell(C.span(u, 0.24, 0.55))
		local leg = 0.6 * load + 0.5 * tuck - 0.1 * launch + 0.5 * land
		local knee = 1.1 * load + 0.9 * tuck + 1.0 * land
		return {
			air = air,
			dy = 0.32 * C.arc(C.span(u, 0.3, 0.78)),
			legL = leg,
			legR = leg,
			kneeL = knee,
			kneeR = knee,
			lean = -0.25 * load + 0.1 * launch - 0.05 * tuck - 0.2 * land,
			lookPitch = -0.2 * load + 0.25 * launch - 0.2 * land,
			armL = -0.5 * load + 1.1 * swing + 0.4 * land,
			armR = -0.5 * load + 1.1 * swing + 0.4 * land,
			outL = 1.1 * tuck + 0.3 * land,
			outR = 1.1 * tuck + 0.3 * land,
			elbowL = 0.3 * load + 0.4 * land,
			elbowR = 0.3 * load + 0.4 * land,
			jaw = 0.4 * tuck,
			earL = 0.5 * tuck,
			earR = 0.5 * tuck,
			tailUp = 0.3 * tuck,
		}
	end,
}
