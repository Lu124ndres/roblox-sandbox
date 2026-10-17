--!strict
--[[
	Rugir al cielo: baja la cabeza y se agacha juntando aire (anticipación,
	~25 %), se echa atrás de golpe con el pecho arriba, el cuello y la cabeza al
	cielo, las alas medio abiertas y la boca bien abierta (roar), ruge sacudiendo
	la cabeza y vuelve pasándose un poco (rebote).
]]

local C = require(script.Parent.Parent.Parent.Minotauro.Trucos.Curvas)
local Tipos = require(script.Parent.Tipos)

local EVENTS: { Tipos.Event } = { { at = 0.3, kind = "roar" } }

return table.freeze({
	name = "rugir",
	seconds = 3.8,
	events = function(_ctx: Tipos.Ctx): { Tipos.Event }
		return EVENTS
	end,
	pose = function(u: number, _ctx: Tipos.Ctx): Tipos.Pose
		local gather = C.hold(u, 0, 0.2, 0.24, 0.3)
		local roar = C.overshoot(C.span(u, 0.27, 0.36)) * (1 - C.smooth(C.span(u, 0.74, 0.94)))
		local shake = math.sin(u * 60) * C.hold(u, 0.36, 0.42, 0.66, 0.74)
		return {
			crouch = 0.4 * gather - 0.15 * roar,
			neck = -0.35 * gather + 0.75 * roar,
			head = -0.4 * gather + 0.55 * roar + 0.06 * shake,
			chest = -0.1 * gather + 0.3 * roar,
			look = 0.1 * shake,
			jaw = 0.1 * gather + 1.1 * roar,
			tuck = -0.6 * roar,
			spread = 0.45 * roar,
			tailUp = -0.2 * gather + 0.5 * roar,
		}
	end,
} :: Tipos.Behavior)
