--!strict
--[[
	Reverencia (truco): la invitación a jugar. Baja el pecho con la cadera alta
	(bow), las colas arriba meneándose y la cara de juego (boca abierta, orejas
	adelante, una antes que la otra); rebota sobre las delanteras y ladea la
	cabeza mirando al jugador (no fija la mirada: deja que Mirada lo busque). Después
	pasa el peso adelante y estira las traseras (stretch) con los ojos
	entrecerrados, como un gato. La cría rebota mucho; la forma final no rebota y
	hace una reverencia lenta y digna.
]]

local C = require(script.Parent.Curvas)
local Tipos = require(script.Parent.Parent.Tipos)

local conducta: Tipos.Conducta = {
	nombre = "reverencia",
	tipo = "truco",
	pesos = { 1.2, 1, 0.7, 0.4 },
	quieto = true,
	eventos = { { at = 0.22, kind = "happy" }, { at = 0.32, kind = "yip" } },
	duracion = function(etapa: number, r: number): number
		return 3.6 * C.pace(etapa) * C.entre(r, 1, 0.9, 1.15)
	end,
	pose = function(u: number, etapa: number, r: number): Tipos.Pose
		local side = C.lado(r, 2)
		local play = C.hold(u, 0.04, 0.2, 0.5, 0.62)
		local bounces = C.veces(r, 3, 2, 4)
		local bounce = C.peso(etapa, 1, 0.8, 0.5, 0) * C.beat(u, 0.2, 0.5, bounces)
		local stretch = C.hold(u, 0.52, 0.64, 0.8, 0.93) * C.peso(etapa, 1, 1, 1, 0.8)
		local face = C.hold(u, 0.05, 0.18, 0.55, 0.66)
		return {
			bow = 0.85 * play * (1 + 0.08 * bounce),
			lookPitch = 0.3 * play + 0.15 * stretch,
			tilt = 0.18 * side * play * C.beat(u, 0.18, 0.55, 1.5),
			jaw = 0.35 * face + 0.08 * stretch,
			emoFeliz = 0.8 * face + 0.3 * stretch,
			earL = 0.5 * C.hold(u, 0.05, 0.14, 0.52, 0.64),
			earR = 0.5 * C.hold(u, 0.1, 0.2, 0.55, 0.66),
			tailWag = 1.4 * play,
			tailLift = 0.5 * play + 0.2 * stretch,
			stretch = stretch,
			lean = -0.15 * stretch,
			eyesClosed = 0.4 * C.hold(u, 0.6, 0.68, 0.8, 0.88),
		}
	end,
}

return conducta
