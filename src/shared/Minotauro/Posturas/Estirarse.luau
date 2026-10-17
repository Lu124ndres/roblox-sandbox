--!strict
--[[
	Estirarse: se encoge (rodillas, brazos recogidos, cabeza abajo: anticipación),
	se estira hacia atrás con el pecho afuera, los brazos abiertos hacia arriba y
	un bostezo con la boca bien abierta (yawn); se suelta sacudiendo la cabeza y
	los hombros y queda como estaba.
]]

local C = require(script.Parent.Parent.Trucos.Curvas)
local Pose = require(script.Parent.Parent.Pose)
local Tipos = require(script.Parent.Tipos)

local EVENTS: { Tipos.Event } = { { at = 0.3, kind = "yawn" } }

return table.freeze({
	name = "estirarse",
	seconds = 4.5,
	events = function(_ctx: Tipos.Ctx): { Tipos.Event }
		return EVENTS
	end,
	pose = function(u: number, _ctx: Tipos.Ctx): Pose.Pose
		local curl = C.hold(u, 0, 0.16, 0.18, 0.26)
		local reach = C.overshoot(C.span(u, 0.2, 0.4)) * (1 - C.smooth(C.span(u, 0.66, 0.84)))
		local open = C.hold(u, 0.24, 0.34, 0.6, 0.72)
		local shake = math.sin(u * 60) * C.hold(u, 0.7, 0.76, 0.86, 0.94)
		return {
			legL = 0.3 * curl,
			legR = 0.3 * curl,
			kneeL = 0.55 * curl,
			kneeR = 0.55 * curl,
			lean = -0.15 * curl + 0.3 * reach,
			lookPitch = -0.15 * curl + 0.4 * reach,
			lookYaw = 0.22 * shake,
			sway = 0.04 * shake,
			jaw = 1.2 * open,
			armL = 0.3 * curl + 0.5 * reach,
			armR = 0.3 * curl + 0.5 * reach,
			elbowL = 0.8 * curl,
			elbowR = 0.8 * curl,
			outL = -0.1 * curl + 1.5 * reach,
			outR = -0.1 * curl + 1.5 * reach,
			elbowOutL = 0.4 * reach,
			elbowOutR = 0.4 * reach,
			earL = 0.5 * reach,
			earR = 0.5 * reach,
			tailUp = 0.35 * reach,
		}
	end,
} :: Tipos.Behavior)
