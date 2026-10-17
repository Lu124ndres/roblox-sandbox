--!strict
--[[
	Voltereta (la cría): se ladea un poco al revés y encoge las alas
	(anticipación), da una vuelta entera sobre su eje (rápido en el medio, lento
	al entrar y al salir), se pasa un poco y vuelve tambaleando (rebote).
]]

local C = require(script.Parent.Parent.Parent.Minotauro.Trucos.Curvas)

return table.freeze({
	name = "voltereta",
	seconds = 1.9,
	events = { { at = 0.15, kind = "whoosh" } },
	pose = function(u: number, _L: number): { [string]: number }
		local counter = C.bell(C.span(u, 0, 0.18))
		local spin = C.smooth(C.span(u, 0.14, 0.78))
		local settle = C.span(u, 0.78, 1)
		local wobble = math.sin(settle * math.pi * 2.5) * (1 - settle) * C.span(u, 0.76, 0.8)
		return {
			roll = -0.25 * counter + math.pi * 2 * spin + 0.25 * wobble,
			flap = 0.4,
			fold = 0.15 * counter + 0.35 * C.bell(C.span(u, 0.14, 0.78)),
			dy = 3 * C.bell(u),
			head = 0.15 * C.bell(C.span(u, 0.1, 0.8)),
			tailUp = 0.2 * counter,
		}
	end,
})
