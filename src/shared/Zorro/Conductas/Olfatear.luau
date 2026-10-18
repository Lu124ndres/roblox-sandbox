--!strict
--[[
	Olfatear el suelo y seguir un rastro: baja el hocico casi al agua (el pecho baja
	un poco), olfatea rápido (cabeceos cortos) y mueve la cabeza de un lado al otro
	siguiendo el rastro, con las orejas adelante y las colas bajas y tensas. Al
	terminar levanta la cabeza y mira hacia donde iba el rastro. Se hace caminando
	(no es quieto): Rutina pone el paso (walk) y esto la cabeza.
]]

local C = require(script.Parent.Curvas)
local Tipos = require(script.Parent.Parent.Tipos)

local conducta: Tipos.Conducta = {
	nombre = "olfatear",
	tipo = "postura",
	pesos = { 1, 1, 0.8, 0 },
	quieto = false,
	eventos = {
		{ at = 0.15, kind = "sniff" },
		{ at = 0.45, kind = "sniff" },
		{ at = 0.72, kind = "sniff" },
	},
	duracion = function(etapa: number, r: number): number
		return 4.5 * C.pace(etapa) * C.entre(r, 1, 0.85, 1.3)
	end,
	pose = function(u: number, _etapa: number, r: number): Tipos.Pose
		local side = C.lado(r, 2)
		local down = C.hold(u, 0.04, 0.16, 0.8, 0.92)
		local sweeps = C.entre(r, 3, 1, 2)
		local trail = math.sin(2 * math.pi * sweeps * C.span(u, 0.1, 0.85) + C.entre(r, 4, 0, 3))
		local sniff = C.beat(u, 0.15, 0.8, C.veces(r, 5, 10, 14))
		local up = C.hold(u, 0.84, 0.9, 0.94, 0.99)
		return {
			lookPitch = -0.55 * down + 0.04 * sniff * down + 0.1 * up,
			lookYaw = 0.3 * down * trail + side * 0.3 * up,
			lookHold = C.hold(u, 0.04, 0.14, 0.88, 0.97),
			bow = 0.15 * down,
			lean = -0.08 * down,
			breathe = 0.02 * sniff * down,
			earL = 0.4 * C.hold(u, 0.03, 0.12, 0.8, 0.9),
			earR = 0.4 * C.hold(u, 0.06, 0.16, 0.82, 0.92),
			tailLift = -0.1 * down,
			tailAlert = 0.15 * down,
			tailCalm = -0.3 * down,
		}
	end,
}

return conducta
