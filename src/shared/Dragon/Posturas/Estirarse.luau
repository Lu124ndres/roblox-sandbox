--!strict
--[[
	Estirarse: se encoge (agachado, cuello abajo, alas apretadas: anticipación),
	se estira en puntas con el pecho afuera, despliega las dos alas bien arriba y
	bosteza (stretch), las sacude y las vuelve a plegar asentándose.
]]

local C = require(script.Parent.Parent.Parent.Minotauro.Trucos.Curvas)
local Tipos = require(script.Parent.Tipos)

local EVENTS: { Tipos.Event } = { { at = 0.24, kind = "stretch" } }

return table.freeze({
	name = "estirarse",
	seconds = 4.8,
	events = function(_ctx: Tipos.Ctx): { Tipos.Event }
		return EVENTS
	end,
	pose = function(u: number, _ctx: Tipos.Ctx): Tipos.Pose
		local curl = C.hold(u, 0, 0.14, 0.16, 0.26)
		local open = C.overshoot(C.span(u, 0.2, 0.42)) * (1 - C.smooth(C.span(u, 0.68, 0.9)))
		local yawn = C.hold(u, 0.3, 0.4, 0.55, 0.66)
		local shake = math.sin(u * 70) * C.hold(u, 0.6, 0.64, 0.7, 0.76)
		local settle = C.bell(C.span(u, 0.86, 1))
		return {
			crouch = 0.45 * curl - 0.35 * open + 0.25 * settle,
			neck = -0.35 * curl + 0.45 * open,
			head = -0.25 * curl + 0.35 * yawn,
			chest = -0.1 * curl + 0.25 * open,
			tuck = -1 * open,
			spread = 1.1 * open - 0.15 * curl,
			wingL = 0.12 * shake,
			wingR = -0.12 * shake,
			jaw = 1.1 * yawn,
			tailUp = 0.4 * open,
		}
	end,
} :: Tipos.Behavior)
