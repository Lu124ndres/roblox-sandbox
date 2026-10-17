--!strict
--[[
	Brinco (la cría): se agacha con las alas arriba (anticipación), salta en
	puntas con un aletazo (estirarse), en el aire encoge las patas, cae
	aplastándose (land) y rebota. La altura es una parábola (hop, en largos del
	dragón); Dragon/Posado no deja que las patas atraviesen la roca.
]]

local C = require(script.Parent.Parent.Parent.Minotauro.Trucos.Curvas)
local Tipos = require(script.Parent.Tipos)

local EVENTS: { Tipos.Event } = { { at = 0.3, kind = "flap" }, { at = 0.72, kind = "land" } }

return table.freeze({
	name = "brinco",
	seconds = 1.7,
	events = function(_ctx: Tipos.Ctx): { Tipos.Event }
		return EVENTS
	end,
	pose = function(u: number, ctx: Tipos.Ctx): Tipos.Pose
		local bounce = ctx.profile.bounce
		local load = C.smooth(C.span(u, 0, 0.24)) * (1 - C.easeIn(C.span(u, 0.24, 0.3)))
		local launch = C.decay(u, 0.3, 12)
		local air = C.smooth(C.span(u, 0.28, 0.34)) * (1 - C.smooth(C.span(u, 0.66, 0.72)))
		local land = C.decay(u, 0.72, 9) * (1 - C.smooth(C.span(u, 0.9, 1)))
		local rebound = C.bell(C.span(u, 0.8, 0.95)) * bounce
		return {
			hop = 0.12 * C.arc(C.span(u, 0.3, 0.72)) + 0.015 * rebound,
			crouch = 0.8 * load - 0.5 * launch + 0.4 * air + 0.9 * land - 0.2 * rebound,
			neck = -0.2 * load + 0.25 * launch - 0.2 * land,
			head = 0.2 * air,
			tuck = -0.8 * (load + air) - 0.4 * land,
			spread = 0.7 * load - 0.9 * launch + 0.2 * air + 0.3 * land,
			jaw = 0.4 * air,
			tailUp = 0.3 * load + 0.4 * air - 0.3 * land,
		}
	end,
} :: Tipos.Behavior)
