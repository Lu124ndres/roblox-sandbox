--!strict
--[[
	Ladear la cabeza, curioso: oye algo (las orejas se paran, una antes que la otra,
	con un poco de sorpresa), mira hacia ahí y ladea la cabeza; a veces la ladea al
	otro lado, como preguntando. Las colas se quedan quietas y atentas mientras
	escucha. La cría ladea más; la forma final no lo hace (pesos).
]]

local C = require(script.Parent.Curvas)
local Tipos = require(script.Parent.Parent.Tipos)

local conducta: Tipos.Conducta = {
	nombre = "ladear",
	tipo = "postura",
	pesos = { 1.2, 1, 0.7, 0 },
	quieto = true,
	eventos = {},
	duracion = function(etapa: number, r: number): number
		return 3 * C.pace(etapa) * C.entre(r, 1, 0.85, 1.3)
	end,
	pose = function(u: number, etapa: number, r: number): Tipos.Pose
		local side = C.lado(r, 2)
		local twice = C.azar(r, 4) > 0.35
		local amount = C.peso(etapa, 0.2, 0.2, 0.18, 0.16)
		local first = if twice
			then C.hold(u, 0.12, 0.22, 0.42, 0.52)
			else C.hold(u, 0.12, 0.24, 0.72, 0.86)
		local second = if twice then C.hold(u, 0.5, 0.6, 0.76, 0.86) else 0
		local attend = C.hold(u, 0.04, 0.14, 0.82, 0.96)
		local flick = C.pulse(u, 0.3 + 0.3 * C.azar(r, 5), 0.04)
		return {
			earL = 0.5 * C.hold(u, 0.03, 0.12, 0.84, 0.96) + 0.15 * amount * side * first,
			earR = 0.45 * C.hold(u, 0.08, 0.16, 0.82, 0.94) - 0.15 * amount * side * first,
			earTipL = 0.3 * flick,
			emoSorpresa = 0.35 * C.pulse(u, 0.09, 0.07),
			lookYaw = C.lado(r, 3) * C.entre(r, 6, 0.1, 0.35) * attend,
			lookPitch = -0.08 * attend,
			lookHold = 0.7 * attend,
			tilt = amount * side * (first - 0.9 * second),
			tailAlert = 0.2 * attend,
			tailCalm = -0.4 * attend,
		}
	end,
}

return conducta
