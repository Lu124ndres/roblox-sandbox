--!strict
--[[
	Lamerse la pata: se sienta, levanta una delantera hacia el hocico (pawL/pawR), la
	huele y baja la cabeza a la pata (mira lo que hace). Se lame de 4 a 8 veces: la
	boca se abre un poco y la cabeza cabecea hacia la pata en cada lengüetazo, con
	los ojos entrecerrados. Al final mira la pata un momento, la baja y se para.
	Las colas envuelven las patas del otro lado.
]]

local C = require(script.Parent.Curvas)
local Tipos = require(script.Parent.Parent.Tipos)

local function tiempos(etapa: number, r: number)
	local pace = C.pace(etapa)
	local n = C.veces(r, 1, 4, 8)
	local lick = C.peso(etapa, 0.34, 0.38, 0.44, 0.52) * C.entre(r, 3, 0.9, 1.15)
	local a = 0.5 * pace -- sentado
	local b = a + 0.45 * pace -- la pata arriba
	local c = b + n * lick -- termina de lamer
	local d = c + 0.5 * pace -- la mira y la baja
	return n, a, b, c, d, d + 0.5 * pace
end

local function duracion(etapa: number, r: number): number
	local _, _, _, _, _, total = tiempos(etapa, r)
	return total
end

local conducta: Tipos.Conducta = {
	nombre = "lamerse",
	tipo = "postura",
	pesos = { 0.8, 0.9, 1, 1 },
	quieto = true,
	eventos = { { at = 0.14, kind = "sniff" } },
	duracion = duracion,
	pose = function(u: number, etapa: number, r: number): Tipos.Pose
		local n, a, b, c, d, total = tiempos(etapa, r)
		local s = u * total
		local side = C.lado(r, 2)
		local sit = C.smooth(C.span(s, 0, a)) * (1 - C.smooth(C.span(s, d, total)))
		local lift = C.smooth(C.span(s, a * 0.6, b)) * (1 - C.smooth(C.span(s, c + 0.25, d)))
		local licking = C.hold(s, b - 0.1, b + 0.1, c - 0.1, c + 0.15)
		local lick = math.max(0, C.beat(s, b, c, n)) * licking
		return {
			sit = sit,
			pawL = if side > 0 then lift else 0,
			pawR = if side > 0 then 0 else lift,
			lookPitch = -0.32 * lift - 0.06 * lick,
			lookYaw = side * 0.15 * lift,
			tilt = -side * 0.1 * lift,
			lookHold = lift,
			jaw = 0.12 * licking + 0.18 * lick,
			eyesClosed = 0.35 * licking,
			emoFeliz = 0.3 * lift,
			earL = -0.1 * lift + (if side > 0 then 0.05 * lick else 0),
			earR = -0.1 * lift + (if side > 0 then 0 else 0.05 * lick),
			tailWrap = 0.8 * sit,
			tailSide = -side,
		}
	end,
}

return conducta
