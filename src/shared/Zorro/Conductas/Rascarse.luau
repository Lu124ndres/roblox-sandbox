--!strict
--[[
	Rascarse: se sienta, carga el peso en el otro lado y sube la pata de atrás a la
	oreja (scratch, del lado scratchSide); la cabeza se ladea y gira hacia la pata
	para que llegue (mira lo que hace) y la oreja rascada se echa atrás y tiembla
	con cada golpe. Se rasca de 3 a 6 veces (scratchBeat, rápido) con los ojos
	entrecerrados de gusto, baja la pata y se para. La cría no llega a la oreja:
	baja más la cabeza y se tambalea; la forma final no se rasca (pesos).
	Sentado, las colas envuelven las patas del lado de la pata que no rasca.
]]

local C = require(script.Parent.Curvas)
local Tipos = require(script.Parent.Parent.Tipos)

local function tiempos(etapa: number, r: number)
	local pace = C.pace(etapa)
	local n = C.veces(r, 1, 3, 6)
	local stroke = C.peso(etapa, 0.2, 0.22, 0.26, 0.3) * C.entre(r, 3, 0.9, 1.1)
	local sit, reach, lower = 0.55 * pace, 0.4 * pace, 0.35 * pace
	local a = sit
	local b = a + reach
	local c = b + n * stroke
	local d = c + lower
	return n, a, b, c, d, d + 0.5 * pace
end

local function duracion(etapa: number, r: number): number
	local _, _, _, _, _, total = tiempos(etapa, r)
	return total
end

local conducta: Tipos.Conducta = {
	nombre = "rascarse",
	tipo = "postura",
	pesos = { 1.2, 1, 0.7, 0 },
	quieto = true,
	eventos = {},
	duracion = duracion,
	pose = function(u: number, etapa: number, r: number): Tipos.Pose
		local n, a, b, c, d, total = tiempos(etapa, r)
		local s = u * total
		local side = C.lado(r, 2)
		local reachMore = 1 -- Pose ya lleva la cabeza a la pata (valores por etapa, zorro_v2_poses)
		local sit = C.smooth(C.span(s, 0, a)) * (1 - C.smooth(C.span(s, d, total)))
		local reach = C.smooth(C.span(s, a * 0.7, b)) * (1 - C.smooth(C.span(s, c, d)))
		local beat = C.beat(s, b, c, n) * reach
		local relief = C.hold(s, b, b + 0.3, c - 0.1, d)
		local wobble = C.peso(etapa, 0.04, 0.015, 0, 0) * beat
		local scratched = -0.35 * reach + 0.12 * beat
		local other = 0.15 * reach
		return {
			sit = sit,
			scratch = reach,
			scratchSide = side,
			scratchBeat = beat,
			sway = 0.05 * side * reach + wobble,
			tilt = -side * (0.16 * reach + 0.03 * beat),
			lookYaw = side * 0.28 * reachMore * reach,
			lookPitch = -0.12 * reachMore * reach,
			lookHold = reach,
			earL = if side > 0 then scratched else other,
			earR = if side > 0 then other else scratched,
			earTipL = if side > 0 then 0.4 * beat else 0,
			earTipR = if side > 0 then 0 else 0.4 * beat,
			emoFeliz = 0.7 * relief,
			jaw = 0.12 * relief,
			tailWrap = 0.7 * sit,
			tailSide = -side,
		}
	end,
}

return conducta
