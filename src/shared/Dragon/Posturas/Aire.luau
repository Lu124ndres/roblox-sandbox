--!strict
--[[
	Dragon/Posturas/Aire

	Las dos poses entre el aire y la roca (las usa Dragon/Conducta):
		landing(k)   la bajada hasta la roca (k: avance del tramo, 0..1): baja
		             planeando con poco aleteo y la cabeza mirando dónde va; al
		             final frena (anticipación del golpe): levanta el cuerpo,
		             ahueca las alas hacia adelante con aletazos fuertes, baja la
		             cola y estira las patas hacia la roca
		takeoff(t, crouch, bounce)  el despegue, en segundos desde que empieza:
		             se agacha abriendo las alas bien arriba (crouch segundos de
		             anticipación), salta estirándose con un aletazo enorme hacia
		             abajo (takeoff en `crouch`), recoge las patas y sube aleteando
		             fuerte con el cuerpo inclinado hacia arriba
	takeoff da lo que cambia de estar posado (Posturas.base pesa ground(t)):
	solo despliega las alas y suma el salto; landing es la pose de vuelo entera.
]]

local C = require(script.Parent.Parent.Parent.Minotauro.Trucos.Curvas)
local Tipos = require(script.Parent.Tipos)

local Aire = {}

function Aire.landing(k: number): Tipos.Pose
	local glide = C.smooth(C.span(k, 0.3, 0.5)) * (1 - C.smooth(C.span(k, 0.6, 0.7)))
	local flare = C.smooth(C.span(k, 0.6, 0.92))
	local legs = C.smooth(C.span(k, 0.68, 0.95))
	return {
		flap = 1 - 0.8 * glide + 0.8 * flare,
		pitch = -0.12 * glide + 0.5 * flare,
		spread = 0.5 * flare,
		cup = 0.6 * flare,
		head = -0.2 * glide - 0.25 * flare,
		neck = 0.15 * flare,
		tailDroop = 1.3 * flare,
		legs = legs,
		reach = legs,
		hover = flare,
	}
end

-- Cuánto pesa la pose de posado (Posturas.base) t segundos después de empezar.
function Aire.ground(t: number, crouch: number): number
	return 1 - C.smooth(C.span(t, crouch + 0.05, crouch + 0.9))
end

function Aire.takeoff(t: number, crouch: number, bounce: number): Tipos.Pose
	local load = C.smooth(C.span(t, 0, crouch)) * (1 - C.easeIn(C.span(t, crouch, crouch + 0.08)))
	local launch = C.decay(t, crouch, 5)
	local climb = C.smooth(C.span(t, crouch, crouch + 0.5))
		* (1 - C.smooth(C.span(t, crouch + 1.6, crouch + 3)))
	local airborne = 1 - Aire.ground(t, crouch)
	return {
		crouch = 0.85 * load - 0.6 * launch,
		tuck = -C.smooth(C.span(t, 0, crouch * 0.7)) * (1 - airborne),
		spread = 1.0 * load - 1.2 * launch * (0.8 + 0.2 * bounce),
		flap = if t < crouch then 0 else 1.3 + 0.5 * launch,
		pitch = -0.15 * load + 0.25 * climb,
		neck = -0.25 * load + 0.25 * launch,
		head = 0.2 * load - 0.1 * launch,
		tailUp = -0.3 * load + 0.3 * launch,
		jaw = 0.3 * launch,
		hover = 1 - C.smooth(C.span(t, crouch, crouch + 1.2)),
	}
end

return table.freeze(Aire)
