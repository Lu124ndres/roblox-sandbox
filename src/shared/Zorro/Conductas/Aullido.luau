--!strict
--[[
	Aullido (truco, aullar al cielo): se sienta, baja apenas la cabeza y toma aire
	(el pecho se hincha, las orejas van atrás), levanta el hocico al cielo y aúlla
	con los ojos cerrados: la boca tiembla con la voz y las colas se abren hacia
	arriba, quietas. Cierra la boca, baja la cabeza y se para. Solo el adulto y la
	forma final (pesos); la forma final aúlla más largo.
]]

local C = require(script.Parent.Curvas)
local Tipos = require(script.Parent.Parent.Tipos)

local conducta: Tipos.Conducta = {
	nombre = "aullido",
	tipo = "truco",
	pesos = { 0, 0, 1, 1.2 },
	quieto = true,
	eventos = { { at = 0.3, kind = "howl" } },
	duracion = function(etapa: number, r: number): number
		return 4 * C.pace(etapa) * C.entre(r, 1, 0.9, 1.2)
	end,
	pose = function(u: number, _etapa: number, r: number): Tipos.Pose
		local side = C.lado(r, 2)
		local sit = 0.8 * C.hold(u, 0.02, 0.15, 0.86, 0.98)
		local dip = C.bell(C.span(u, 0.1, 0.26))
		local inhale = C.hold(u, 0.12, 0.26, 0.3, 0.4)
		local up = C.hold(u, 0.22, 0.32, 0.78, 0.92)
		local voice = C.hold(u, 0.26, 0.32, 0.76, 0.86)
		local tremble = math.sin(u * 70) * 0.025 * voice
		local f = C.hold(u, 0.08, 0.26, 0.78, 0.95)
		return {
			sit = sit,
			breathe = 0.06 * inhale,
			lookPitch = -0.12 * dip + 0.7 * up + tremble,
			lookYaw = side * 0.15 * up,
			lookHold = C.hold(u, 0.08, 0.2, 0.85, 0.95),
			jaw = 0.75 * voice + 0.08 * math.sin(u * 30) * voice,
			eyesClosed = 0.6 * C.hold(u, 0.28, 0.36, 0.74, 0.84),
			earL = -0.5 * C.hold(u, 0.12, 0.26, 0.78, 0.92),
			earR = -0.42 * C.hold(u, 0.15, 0.28, 0.8, 0.94),
			tailFan = 0.9 * f,
			tailLift = 0.6 * f,
			tailCalm = -0.5 * f,
		}
	end,
}

return conducta
