--!strict
--[[
	Fuego en el aire: toma aire echando la cabeza atrás y arriba con el pecho
	hinchado (anticipación), deja de aletear para planear, lanza la cabeza hacia
	la lava y echa fuego (fire) barriendo de lado a lado en arco; el retroceso
	le levanta un poco la nariz. Cierra la boca y sigue.
]]

local C = require(script.Parent.Parent.Parent.Minotauro.Trucos.Curvas)

local ON, OFF = 0.22, 0.86

return table.freeze({
	name = "fuego",
	seconds = 3.6,
	events = { { at = ON, kind = "fire" } },
	pose = function(u: number, _L: number): { [string]: number }
		local glide = C.bell(u)
		local inhale = C.hold(u, 0, 0.16, 0.19, 0.24)
		local blast = C.overshoot(C.span(u, 0.2, 0.3)) * (1 - C.smooth(C.span(u, 0.84, 0.97)))
		local sweep = math.sin(C.span(u, ON, OFF) * math.pi * 2) * C.hold(u, ON, 0.3, 0.78, OFF)
		local recoil = C.decay(u, ON, 8)
		return {
			flap = 1 - 0.7 * glide,
			pitch = 0.08 * inhale - 0.12 * blast + 0.08 * recoil,
			neck = 0.2 * inhale - 0.2 * blast,
			head = 0.25 * inhale - 0.5 * blast,
			chest = 0.25 * inhale,
			look = 0.35 * sweep,
			tilt = 0.12 * sweep,
			jaw = C.hold(u, 0.18, ON, OFF - 0.02, OFF + 0.04),
			fire = if u > ON and u < OFF then 1 else 0,
		}
	end,
})
