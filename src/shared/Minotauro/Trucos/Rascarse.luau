--!strict
--[[
	Rascarse: lleva la mano derecha a la cabeza (llega con un poco de rebote) y se
	rasca; la otra mano va a la cintura. A la mitad le da gusto: inclina la cabeza
	hacia la mano, entreabre la boca, mueve la cola y golpetea el suelo con el pie
	izquierdo, como un perro.
]]

local Pose = require(script.Parent.Parent.Pose)
local C = require(script.Parent.Curvas)

return {
	name = "rascarse",
	seconds = 3,
	events = {},
	pose = function(u: number): Pose.Pose
		local f = C.hold(u, 0.05, 0.25, 0.8, 0.97)
		local reach = C.overshoot(C.span(u, 0.05, 0.25)) * (1 - C.smooth(C.span(u, 0.8, 0.97)))
		local scratch = math.sin(u * 45) * f
		local relief = C.hold(u, 0.35, 0.45, 0.75, 0.85)
		local tap = math.max(0, math.sin(u * 40)) * relief
		return {
			armR = 1.6 * reach,
			outR = 0.7 * reach,
			elbowR = 1.7 * reach + 0.15 * scratch,
			outL = 0.5 * f,
			elbowOutL = -1.1 * f,
			tilt = -0.3 * f - 0.12 * relief,
			lookPitch = -0.1 * f,
			lookYaw = -0.15 * relief,
			earL = 0.3 * f,
			jaw = 0.15 * f + 0.15 * relief,
			legL = 0.18 * tap,
			kneeL = 0.35 * tap,
			tail1 = 0.4 * math.sin(u * 25) * relief,
		}
	end,
}
