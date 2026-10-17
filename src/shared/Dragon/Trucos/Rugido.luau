--!strict
--[[
	Rugido en el aire: se frena y se para con aletazos fuertes (hover); baja la
	cabeza y mete el pecho juntando aire (anticipación), la lanza hacia arriba
	con la boca bien abierta (roar), ruge sacudiendo la cabeza y vuelve
	pasándose un poco antes de seguir.
]]

local C = require(script.Parent.Parent.Parent.Minotauro.Trucos.Curvas)

return table.freeze({
	name = "rugido",
	seconds = 4,
	events = { { at = 0.32, kind = "roar" } },
	pose = function(u: number, _L: number): { [string]: number }
		local brake = C.bell(u)
		local gather = C.hold(u, 0.05, 0.24, 0.27, 0.32)
		local roar = C.overshoot(C.span(u, 0.3, 0.4)) * (1 - C.smooth(C.span(u, 0.74, 0.92)))
		local shake = math.sin(u * 50) * C.hold(u, 0.4, 0.45, 0.68, 0.75)
		return {
			speed = 1 - 0.85 * brake,
			hover = brake,
			flap = 1 + 0.6 * brake,
			pitch = 0.5 * brake - 0.1 * gather + 0.15 * roar,
			neck = -0.2 * gather + 0.5 * roar,
			head = -0.3 * gather + 0.4 * roar + 0.06 * shake,
			look = 0.12 * shake,
			chest = -0.1 * gather + 0.2 * roar,
			jaw = 0.1 * gather + 1.1 * roar,
			tailUp = -0.2 * gather + 0.4 * roar,
		}
	end,
})
