--!strict
--[[
	Bostezo: baja apenas la cabeza y toma aire (el pecho sube), después la levanta
	abriendo la boca despacio hasta el todo, con los ojos cerrados y las orejas
	atrás (una más que la otra); en el punto más abierto tiembla. Cierra la boca con
	un chasquido, sacude un poco la cabeza y se relame. Con sueño (emoSueno) de
	principio a fin; la forma final lo hace más lento y más seguido (pesos).
]]

local C = require(script.Parent.Curvas)
local Tipos = require(script.Parent.Parent.Tipos)

local conducta: Tipos.Conducta = {
	nombre = "bostezo",
	tipo = "postura",
	pesos = { 0.8, 0.8, 1, 1.3 },
	quieto = true,
	eventos = { { at = 0.2, kind = "yawn" } },
	duracion = function(etapa: number, r: number): number
		return 3.2 * C.pace(etapa) * C.entre(r, 1, 0.9, 1.15)
	end,
	pose = function(u: number, _etapa: number, r: number): Tipos.Pose
		local side = C.lado(r, 2)
		local wide = C.entre(r, 3, 0.8, 0.95)
		local inhale = C.hold(u, 0.02, 0.18, 0.4, 0.6)
		local dip = C.bell(C.span(u, 0.03, 0.18))
		local up = C.hold(u, 0.15, 0.38, 0.62, 0.8)
		local open = C.hold(u, 0.15, 0.4, 0.58, 0.7)
		local tremble = 0.03 * math.sin(u * 90) * C.hold(u, 0.38, 0.42, 0.55, 0.58)
		local snap = C.pulse(u, 0.72, 0.03)
		local smack = C.pulse(u, 0.82, 0.04)
		local sleepy = C.hold(u, 0.05, 0.25, 0.85, 0.98)
		return {
			breathe = 0.05 * inhale,
			lean = 0.05 * inhale,
			lookPitch = -0.08 * dip + 0.3 * up + tremble,
			lookHold = 0.8 * C.hold(u, 0.05, 0.2, 0.7, 0.85),
			jaw = wide * open + tremble - 0.06 * snap + 0.1 * smack,
			eyesClosed = 0.8 * C.hold(u, 0.2, 0.32, 0.6, 0.72),
			emoSueno = 0.8 * sleepy,
			earL = -0.5 * C.hold(u, 0.18, 0.35, 0.6, 0.75),
			earR = -0.4 * C.hold(u, 0.22, 0.38, 0.62, 0.78),
			tilt = 0.08 * side * up + 0.1 * C.beat(u, 0.72, 0.86, 2),
			tailCalm = -0.3 * sleepy,
		}
	end,
}

return conducta
