--!strict
--[[
	Sacudida (truco): se sacude el agua de la cabeza a la cola, como un perro. Se
	planta (se agacha un poco, echa las orejas atrás y cierra los ojos), sacude la
	cabeza en círculos con las orejas flojas, después todo el cuerpo (shake) y al
	final la onda llega a las colas (meneo fuerte). La cría queda mareada: se
	tambalea y vuelve a apoyar una pata; la forma final se sacude más lento y con
	menos fuerza. Termina contento.
]]

local C = require(script.Parent.Curvas)
local Tipos = require(script.Parent.Parent.Tipos)

local conducta: Tipos.Conducta = {
	nombre = "sacudida",
	tipo = "truco",
	pesos = { 1, 1, 0.9, 0.7 },
	quieto = true,
	eventos = { { at = 0.3, kind = "shake" } },
	duracion = function(etapa: number, r: number): number
		return 2.4 * C.pace(etapa) * C.entre(r, 1, 0.9, 1.1)
	end,
	pose = function(u: number, etapa: number, r: number): Tipos.Pose
		local f = C.hold(u, 0.02, 0.15, 0.8, 0.95)
		local n = C.peso(etapa, 5, 4, 4, 3)
		local head = C.hold(u, 0.15, 0.2, 0.4, 0.47)
		local phase = 2 * math.pi * n * C.span(u, 0.15, 0.47) * C.entre(r, 2, 0.9, 1.1)
		local body = C.hold(u, 0.3, 0.38, 0.65, 0.78) * C.peso(etapa, 1, 1, 0.9, 0.8)
		local tail = C.hold(u, 0.5, 0.58, 0.8, 0.92)
		local squeeze = C.hold(u, 0.14, 0.22, 0.7, 0.8)
		local dizzy = C.peso(etapa, 1, 0.5, 0, 0) * C.bell(C.span(u, 0.74, 0.96))
		local happy = C.hold(u, 0.74, 0.82, 0.9, 0.99)
		local flop = math.sin(phase)
		return {
			crouch = 0.12 * f,
			lookPitch = -0.1 * f,
			tilt = 0.2 * head * flop,
			lookYaw = 0.2 * head * math.cos(phase),
			lookHold = f,
			jaw = 0.1 * head * math.abs(flop),
			shake = body,
			earL = -0.3 * f + 0.3 * head * flop,
			earR = -0.3 * f - 0.3 * head * math.sin(phase + 0.8),
			earTipL = 0.6 * head * math.sin(phase + 1.2),
			earTipR = -0.6 * head * math.sin(phase + 2),
			eyesClosed = 0.8 * squeeze,
			tailWag = 1.4 * tail,
			sway = 0.06 * dizzy * math.sin(u * 40),
			stepFR = 0.4 * dizzy,
			emoFeliz = 0.5 * happy,
		}
	end,
}

return conducta
