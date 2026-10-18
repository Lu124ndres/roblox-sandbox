--!strict
--[[
	Fuegos fatuos (truco): mira el agua y se agacha un poco, llama a los orbes de
	agua (orbs) y los sigue con la mirada mientras suben y le dan la vuelta, con
	sorpresa al primero y contento después; las colas se abren y ondulan más. No
	está en el catálogo de la biblia: es el truco mágico del zorro de agua, más del
	adulto y de la forma final (pesos).
]]

local C = require(script.Parent.Curvas)
local Tipos = require(script.Parent.Parent.Tipos)

local conducta: Tipos.Conducta = {
	nombre = "fuegos",
	tipo = "truco",
	pesos = { 0.3, 0.5, 0.8, 1.1 },
	quieto = true,
	eventos = { { at = 0.2, kind = "orbs" }, { at = 0.55, kind = "orbs" } },
	duracion = function(etapa: number, r: number): number
		return 4 * C.pace(etapa) * C.entre(r, 1, 0.9, 1.15)
	end,
	pose = function(u: number, _etapa: number, r: number): Tipos.Pose
		local side = C.lado(r, 2)
		local f = C.hold(u, 0.05, 0.22, 0.82, 0.98)
		local down = C.bell(C.span(u, 0.02, 0.18))
		local follow = math.sin(2 * math.pi * C.span(u, 0.2, 0.85))
		local happy = C.hold(u, 0.3, 0.4, 0.8, 0.95)
		return {
			crouch = 0.18 * f,
			lookPitch = -0.15 * down + 0.4 * C.hold(u, 0.15, 0.3, 0.8, 0.96),
			lookYaw = side * 0.5 * follow * f,
			lookHold = f,
			emoSorpresa = 0.6 * C.pulse(u, 0.22, 0.06),
			emoFeliz = 0.6 * happy,
			jaw = 0.2 * f,
			earL = 0.3 * f,
			earR = 0.3 * C.hold(u, 0.08, 0.25, 0.84, 0.98),
			tailFan = 0.7 * f,
			tailLift = 0.3 * f,
			tailCalm = 1.2 * f,
		}
	end,
}

return conducta
