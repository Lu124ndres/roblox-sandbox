--!strict
--[[
	Baile: se mece al ritmo, cabecea en cada golpe, flexiona las rodillas en cada
	tiempo (Cuerpo.plant lo baja de verdad), da pasitos alternados y mueve los
	brazos en círculos (adelante-atrás y afuera-adentro desfasados: arcos, no
	líneas). La cola y las orejas siguen con retraso por Resortes.
]]

local Pose = require(script.Parent.Parent.Pose)
local C = require(script.Parent.Curvas)

return {
	name = "baile",
	seconds = 4,
	events = { { at = 0.1, kind = "happy" } },
	pose = function(u: number): Pose.Pose
		local b = C.hold(u, 0, 0.08, 0.92, 1)
		local phase = u * math.pi * 8
		local beat = math.sin(phase)
		local bob = math.abs(beat)
		return {
			sway = 0.16 * beat * b,
			tilt = 0.25 * beat * b,
			lookPitch = 0.12 * (bob - 0.5) * b,
			armL = 0.9 * math.sin(phase) * b,
			armR = -0.9 * math.sin(phase) * b,
			outL = (0.35 + 0.25 * math.cos(phase)) * b,
			outR = (0.35 - 0.25 * math.cos(phase)) * b,
			elbowL = 0.6 * b,
			elbowR = 0.6 * b,
			legL = (0.25 * math.max(0, beat) + 0.3 * bob) * b,
			legR = (0.25 * math.max(0, -beat) + 0.3 * bob) * b,
			kneeL = (0.45 * math.max(0, beat) + 0.6 * bob) * b,
			kneeR = (0.45 * math.max(0, -beat) + 0.6 * bob) * b,
			jaw = 0.3 * b,
			earL = 0.2 * bob * b,
			earR = 0.2 * bob * b,
			tail1 = 0.5 * beat * b,
			tail2 = 0.6 * beat * b,
		}
	end,
}
