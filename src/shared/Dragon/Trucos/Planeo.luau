--!strict
--[[
	Planeo: deja de aletear de a poco y planea largo rato con las alas
	extendidas, la nariz apenas abajo, mirando la lava de un lado al otro con la
	cabeza; al final vuelve a aletear.
]]

local C = require(script.Parent.Parent.Parent.Minotauro.Trucos.Curvas)

return table.freeze({
	name = "planeo",
	seconds = 6,
	events = {},
	pose = function(u: number, _L: number): { [string]: number }
		local glide = C.hold(u, 0, 0.15, 0.85, 1)
		local scan = math.sin(C.span(u, 0.15, 0.85) * math.pi * 2) * glide
		return {
			flap = 1 - 0.95 * glide,
			pitch = -0.05 * glide,
			speed = 1.1,
			look = 0.5 * scan,
			head = -0.2 * glide,
			tilt = 0.15 * scan,
		}
	end,
})
