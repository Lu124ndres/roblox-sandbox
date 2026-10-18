--!strict
--[[
	Salto en picada (truco; el "salto" de los trucos viejos): caza como un zorro en
	la nieve. Oye algo adelante: para las orejas (una antes que la otra), ladea la
	cabeza a un lado y al otro y mira el punto. Se agacha y mueve la cadera (carga),
	salta en arco estirado (pounce) y cae de hocico con las delanteras juntas,
	salpicando. Saca la cabeza, la sacude y queda contento. La cría salta más alto y
	queda con la cola arriba y la cara metida en el agua (bow) un momento, sorprendida;
	el adulto salta más bajo y seguro; la forma final no lo hace.
]]

local C = require(script.Parent.Curvas)
local Tipos = require(script.Parent.Parent.Tipos)

local TAKEOFF, LAND = 0.32, 0.64

local conducta: Tipos.Conducta = {
	nombre = "salto",
	tipo = "truco",
	pesos = { 1.3, 1.1, 0.8, 0 },
	quieto = true,
	eventos = {
		{ at = 0.2, kind = "crouch" },
		{ at = TAKEOFF, kind = "pounce" },
		{ at = LAND, kind = "land" },
	},
	duracion = function(etapa: number, r: number): number
		return 2.6 * C.pace(etapa) * C.entre(r, 3, 0.95, 1.1)
	end,
	pose = function(u: number, etapa: number, r: number): Tipos.Pose
		local side = C.lado(r, 2)
		local high = C.peso(etapa, 0.42, 0.36, 0.28, 0.2) * C.entre(r, 1, 0.9, 1.1)
		local listen = C.hold(u, 0.02, 0.1, 0.3, 0.36)
		local load = C.hold(u, 0.14, 0.28, TAKEOFF - 0.01, TAKEOFF + 0.03)
		local air = C.span(u, TAKEOFF, LAND)
		local flying = C.bell(air)
		local stretched = C.hold(u, 0.36, 0.5, LAND - 0.02, 0.7)
		local dive = C.hold(u, 0.45, 0.58, 0.68, 0.8)
		local absorb = C.bell(C.span(u, LAND - 0.01, 0.8))
		local faceIn = C.peso(etapa, 0.4, 0.3, 0.15, 0) * C.hold(u, LAND, 0.68, 0.76, 0.86)
		local after = C.hold(u, 0.78, 0.84, 0.9, 0.98)
		local curious = C.bell(C.span(u, 0.03, 0.13)) - C.bell(C.span(u, 0.12, 0.22))
		return {
			earL = 0.6 * C.hold(u, 0.02, 0.09, 0.3, 0.36) - 0.3 * flying,
			earR = 0.6 * C.hold(u, 0.06, 0.13, 0.3, 0.36) - 0.3 * flying,
			tilt = 0.18 * side * curious + 0.2 * C.beat(u, 0.8, 0.92, 3),
			lookPitch = -0.3 * listen - 0.55 * dive + 0.15 * after,
			lookHold = C.hold(u, 0.02, 0.1, 0.8, 0.9),
			crouch = 0.7 * load - 0.3 * flying + 0.4 * absorb,
			sway = 0.04 * C.beat(u, 0.22, 0.31, 3),
			dy = high * C.arc(air),
			pounce = stretched,
			lean = 0.12 * C.bell(C.span(u, 0.3, 0.45)) - 0.25 * dive,
			stepHL = 0.3 * flying,
			stepHR = 0.3 * flying,
			bow = faceIn,
			jaw = 0.25 * after,
			tailAlert = 0.4 * C.hold(u, 0.05, 0.15, 0.3, 0.36),
			tailLift = 0.3 * load - 0.15 * flying + 0.3 * faceIn,
			emoSorpresa = C.peso(etapa, 0.7, 0.4, 0, 0) * C.pulse(u, 0.7, 0.08),
			emoFeliz = 0.6 * after,
		}
	end,
}

return conducta
