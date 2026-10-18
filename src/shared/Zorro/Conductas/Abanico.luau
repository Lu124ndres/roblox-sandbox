--!strict
--[[
	Abanico (truco, lucirse): toma aire y saca pecho, abre las colas como un abanico
	(Colas lo abre en cascada del centro hacia afuera y las hace brillar), con las
	orejas paradas y cara de orgullo; gira la cabeza despacio para mostrarse de
	perfil y vuelve. Cierra el abanico y suelta el aire. Desde el joven; la forma
	final lo abre más.
]]

local C = require(script.Parent.Curvas)
local Tipos = require(script.Parent.Parent.Tipos)

local conducta: Tipos.Conducta = {
	nombre = "abanico",
	tipo = "truco",
	pesos = { 0, 0.8, 1, 1.3 },
	quieto = true,
	eventos = { { at = 0.22, kind = "fan" } },
	duracion = function(etapa: number, r: number): number
		return 4.2 * C.pace(etapa) * C.entre(r, 1, 0.9, 1.1)
	end,
	pose = function(u: number, etapa: number, r: number): Tipos.Pose
		local side = C.lado(r, 2)
		local inhale = C.hold(u, 0.01, 0.12, 0.82, 0.96)
		local f = C.hold(u, 0.08, 0.25, 0.8, 0.97)
		local profile = C.bell(C.span(u, 0.28, 0.78))
		return {
			breathe = 0.04 * inhale,
			lean = 0.06 * inhale,
			lookPitch = 0.12 * inhale,
			lookYaw = side * 0.25 * profile,
			tilt = side * 0.08 * profile,
			lookHold = 0.6 * profile,
			earL = 0.4 * C.hold(u, 0.08, 0.2, 0.8, 0.95),
			earR = 0.4 * C.hold(u, 0.12, 0.24, 0.82, 0.97),
			emoFeliz = 0.6 * f,
			tailFan = C.peso(etapa, 1.2, 1.3, 1.4, 1.5) * f,
			tailLift = 0.5 * f,
			tailCalm = 0.8 * f,
		}
	end,
}

return conducta
