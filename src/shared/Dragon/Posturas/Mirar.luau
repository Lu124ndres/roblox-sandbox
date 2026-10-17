--!strict
--[[
	Mirar: alza el cuello (atento), baja un poco la cabeza antes de cada giro
	(anticipación) y mira a un lado ladeando la cabeza con curiosidad, después al
	otro (el cuello llega primero y la cabeza después: Pose lo hace con resortes)
	y vuelve al frente. Empieza por el lado que dice la semilla.
]]

local C = require(script.Parent.Parent.Parent.Minotauro.Trucos.Curvas)
local Tipos = require(script.Parent.Tipos)

local NO_EVENTS: { Tipos.Event } = {}

return table.freeze({
	name = "mirar",
	seconds = 5.5,
	events = function(_ctx: Tipos.Ctx): { Tipos.Event }
		return NO_EVENTS
	end,
	pose = function(u: number, ctx: Tipos.Ctx): Tipos.Pose
		local side = if ctx.seed % 2 == 0 then 1 else -1
		local alert = C.hold(u, 0, 0.12, 0.85, 1)
		local first = C.overshoot(C.span(u, 0.12, 0.3)) * (1 - C.smooth(C.span(u, 0.45, 0.6)))
		local second = C.overshoot(C.span(u, 0.55, 0.72)) * (1 - C.smooth(C.span(u, 0.82, 0.97)))
		local dip = C.bell(C.span(u, 0.06, 0.14)) + C.bell(C.span(u, 0.48, 0.56))
		return {
			neck = 0.25 * alert,
			head = -0.15 * dip + 0.1 * alert,
			look = side * (1.0 * first - 1.0 * second),
			tilt = side * (0.25 * first + 0.25 * second),
			chest = 0.08 * alert,
		}
	end,
} :: Tipos.Behavior)
