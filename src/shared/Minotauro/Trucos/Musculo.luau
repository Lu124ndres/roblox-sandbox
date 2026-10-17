--!strict
--[[
	Músculo: junta los brazos adelante agachándose un poco (anticipación), los
	sube de golpe a la pose de bíceps (se pasa y vuelve) y bombea un brazo y
	después el otro, mirando el que bombea y rebotando en las rodillas.
]]

local Pose = require(script.Parent.Parent.Pose)
local C = require(script.Parent.Curvas)

return {
	name = "musculo",
	seconds = 3.4,
	events = { { at = 0.3, kind = "flex" } },
	pose = function(u: number): Pose.Pose
		local gather = C.hold(u, 0.02, 0.14, 0.15, 0.24)
		local f = C.overshoot(C.span(u, 0.17, 0.3)) * (1 - C.smooth(C.span(u, 0.8, 0.97)))
		local beat = math.sin(u * 28)
		local pumpL = math.max(0, beat) * f
		local pumpR = math.max(0, -beat) * f
		local bounce = pumpL + pumpR
		return {
			armL = 0.35 * gather,
			armR = 0.35 * gather,
			outL = -0.15 * gather + 1.25 * f,
			outR = -0.15 * gather + 1.25 * f,
			elbowL = 0.9 * gather,
			elbowR = 0.9 * gather,
			elbowOutL = 1.4 * f + 0.25 * pumpL,
			elbowOutR = 1.4 * f + 0.25 * pumpR,
			lean = -0.08 * gather + 0.1 * f,
			lookYaw = 0.45 * (pumpL - pumpR),
			tilt = 0.12 * (pumpL - pumpR),
			jaw = 0.25 * f,
			legL = 0.25 * gather + 0.2 * bounce,
			legR = 0.25 * gather + 0.2 * bounce,
			kneeL = 0.5 * gather + 0.4 * bounce,
			kneeR = 0.5 * gather + 0.4 * bounce,
		}
	end,
}
