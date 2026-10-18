--!strict
--[[
	Perseguir su cola: se da cuenta de su cola (sorpresa, se mira atrás curvando el
	cuerpo: spine), se agacha y mueve la cadera, y la persigue dando de 1 a 3 vueltas
	en el lugar (el giro del cuerpo lo da Conductas/Giros a Rutina) con pasitos
	rápidos, el cuerpo curvado hacia la cola y tarascones al aire. No la alcanza:
	la cría se marea y se cae (lie), se levanta y sacude la cabeza; el joven se
	sienta y se queda mirándola con la cabeza ladeada. Las dos se quejan (whine).
	Solo la cría y el joven (pesos).
]]

local C = require(script.Parent.Curvas)
local Giros = require(script.Parent.Giros)
local Tipos = require(script.Parent.Parent.Tipos)

local A, B = Giros.PERSECUCION[1], Giros.PERSECUCION[2]
local STEPS_PER_LAP = 4

local conducta: Tipos.Conducta = {
	nombre = "persecucion",
	tipo = "postura",
	pesos = { 1.4, 0.8, 0, 0 },
	quieto = true,
	eventos = {
		{ at = 0.3, kind = "yip" },
		{ at = 0.5, kind = "yip" },
		{ at = 0.8, kind = "whine" },
	},
	duracion = function(etapa: number, r: number): number
		return (3 + 1.6 * Giros.vueltas(etapa, r)) * C.pace(etapa)
	end,
	pose = function(u: number, etapa: number, r: number): Tipos.Pose
		local side = C.lado(r, 2)
		local laps = Giros.vueltas(etapa, r)
		local notice = C.hold(u, 0.03, 0.12, 0.7, 0.78)
		local chase = C.hold(u, A - 0.04, A + 0.04, B - 0.04, B + 0.02)
		local phase = 2 * math.pi * STEPS_PER_LAP * laps * C.smooth(C.span(u, A, B))
		local stepA, stepB = math.max(0, math.sin(phase)), math.max(0, -math.sin(phase))
		local snap = math.max(0, C.beat(u, A + 0.04, B - 0.04, 2 + laps))
		local fall = if etapa <= 1 then C.hold(u, 0.73, 0.78, 0.86, 0.95) else 0
		local sitLook = if etapa <= 1 then 0 else C.hold(u, 0.73, 0.8, 0.88, 0.96)
		return {
			spine = side * (0.35 * notice + 0.45 * chase + 0.3 * sitLook),
			lookYaw = side * (0.6 * notice + 0.4 * chase + 0.4 * sitLook),
			lookPitch = -0.1 * chase,
			lookHold = C.hold(u, 0.03, 0.1, 0.9, 0.97),
			crouch = 0.3 * C.hold(u, 0.1, 0.16, 0.19, 0.24),
			sway = 0.04 * C.beat(u, 0.12, 0.22, 2) + 0.08 * side * fall,
			stepFL = 0.5 * stepA * chase,
			stepHR = 0.5 * stepA * chase,
			stepFR = 0.5 * stepB * chase,
			stepHL = 0.5 * stepB * chase,
			jaw = 0.4 * snap * chase,
			earL = 0.5 * notice,
			earR = 0.4 * notice,
			emoSorpresa = 0.4 * C.pulse(u, 0.07, 0.05) + 0.8 * C.pulse(u, 0.77, 0.04) * fall,
			emoFeliz = 0.6 * chase,
			lie = 0.9 * fall,
			sit = sitLook,
			tilt = 0.18 * side * sitLook + 0.12 * C.beat(u, 0.9, 0.98, 2) * (1 - sitLook),
			tailWag = 0.8 * notice,
			tailLift = 0.2 * notice,
			tailWrap = 0.6 * sitLook,
			tailSide = side,
		}
	end,
}

return conducta
