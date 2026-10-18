--!strict
--[[
	Probar el hielo: con el peso atrás y un poco agachado, mira el hielo con las
	orejas adelante y las colas bajas, levanta una delantera (pawL/pawR) y lo toca
	dos veces con cuidado (splash: con el hábitat de hielo suena a crujido). Se
	asusta: la cría da un brinquito atrás con sorpresa y orejas atrás; el joven solo
	se sorprende un poco. Los dos se quejan, sacuden la pata fría y bajan a olerlo.
	Solo la cría y el joven (pesos).
]]

local C = require(script.Parent.Curvas)
local Tipos = require(script.Parent.Parent.Tipos)

local TAP_A, TAP_B = 0.2, 0.5 -- dos toques: tocan el hielo en 0.3125 y 0.4625

local conducta: Tipos.Conducta = {
	nombre = "hielo",
	tipo = "postura",
	pesos = { 1.2, 0.8, 0, 0 },
	quieto = true,
	eventos = {
		{ at = 0.3125, kind = "splash" },
		{ at = 0.4625, kind = "splash" },
		{ at = 0.56, kind = "whine" },
		{ at = 0.7, kind = "sniff" },
	},
	duracion = function(etapa: number, r: number): number
		return 4.4 * C.pace(etapa) * C.entre(r, 1, 0.9, 1.2)
	end,
	pose = function(u: number, etapa: number, r: number): Tipos.Pose
		local side = C.lado(r, 2)
		local wary = C.hold(u, 0.03, 0.15, 0.6, 0.72)
		local look = C.hold(u, 0.02, 0.12, 0.8, 0.92)
		local raised = C.hold(u, 0.12, 0.2, 0.62, 0.72)
		local tap = C.beat(u, TAP_A, TAP_B, 2) * C.entre(r, 3, 0.8, 1)
		local shakePaw = C.beat(u, 0.58, 0.68, 3)
		local scare = C.peso(etapa, 1, 0.3, 0.3, 0.3)
		local hop = if etapa <= 1 then C.arc(C.span(u, 0.52, 0.6)) else 0
		local startle = C.pulse(u, 0.55, 0.05)
		local sniff = C.hold(u, 0.64, 0.7, 0.78, 0.86)
		local paw = raised * (0.45 + 0.25 * tap + 0.15 * shakePaw)
		return {
			lean = 0.1 * wary - 0.06 * sniff,
			crouch = 0.2 * wary,
			lookPitch = -0.45 * look - 0.15 * sniff,
			lookYaw = side * 0.1 * look,
			lookHold = look,
			pawL = if side > 0 then paw else 0,
			pawR = if side > 0 then 0 else paw,
			dy = 0.05 * hop,
			emoSorpresa = scare * startle,
			earL = 0.5 * C.hold(u, 0.02, 0.1, 0.5, 0.56) - 0.5 * scare * startle,
			earR = 0.45 * C.hold(u, 0.05, 0.14, 0.5, 0.56) - 0.4 * scare * startle,
			tailAlert = 0.3 * wary,
			tailLift = -0.15 * wary + 0.3 * scare * startle,
		}
	end,
}

return conducta
