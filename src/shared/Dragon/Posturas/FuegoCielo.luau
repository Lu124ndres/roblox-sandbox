--!strict
--[[
	Fuego al cielo: toma aire (el pecho se hincha, la cabeza baja y va atrás,
	se agacha un poco: anticipación), lanza la cabeza hacia arriba y echa fuego
	al cielo (fireSky) moviéndola en un arco de lado a lado; el retroceso lo
	agacha. Cierra la boca, sacude la cabeza (el humo) y vuelve.
	fire > 0.5 enciende el chorro (Dragon/Fx lo lee en state.fire).
]]

local C = require(script.Parent.Parent.Parent.Minotauro.Trucos.Curvas)
local Tipos = require(script.Parent.Tipos)

local FIRE_ON, FIRE_OFF = 0.34, 0.76
local EVENTS: { Tipos.Event } = { { at = FIRE_ON, kind = "fireSky" } }

return table.freeze({
	name = "fuegoCielo",
	seconds = 4.4,
	events = function(_ctx: Tipos.Ctx): { Tipos.Event }
		return EVENTS
	end,
	pose = function(u: number, _ctx: Tipos.Ctx): Tipos.Pose
		local inhale = C.hold(u, 0.02, 0.26, 0.3, 0.34)
		local blast = C.overshoot(C.span(u, 0.3, 0.38)) * (1 - C.smooth(C.span(u, 0.78, 0.95)))
		local sweep = math.sin(C.span(u, FIRE_ON, FIRE_OFF) * math.pi * 2)
			* C.hold(u, 0.34, 0.4, 0.7, 0.76)
		local recoil = C.decay(u, FIRE_ON, 9)
		local shake = math.sin(u * 75) * C.hold(u, 0.8, 0.84, 0.9, 0.95)
		local mouth = C.hold(u, 0.3, 0.34, FIRE_OFF, 0.8)
		return {
			crouch = 0.25 * inhale + 0.3 * recoil,
			chest = 0.3 * inhale + 0.2 * blast,
			neck = -0.3 * inhale + 0.85 * blast,
			head = -0.35 * inhale + 0.8 * blast,
			look = 0.35 * sweep + 0.15 * shake,
			tilt = 0.15 * sweep,
			jaw = 1.1 * mouth,
			fire = if u > FIRE_ON and u < FIRE_OFF then 1 else 0,
			tuck = -0.35 * blast,
			spread = 0.3 * blast,
			tailUp = 0.35 * blast,
		}
	end,
} :: Tipos.Behavior)
