--!strict
--[[
	Centinela: mira el suelo, se sienta erguido (sit) con las colas envolviendo las
	patas y vigila: la cabeza alta pasa de un punto a otro (2 o 3, del azar), con
	una pausa en cada uno, un parpadeo al cambiar y las orejas atentas que se
	sacuden sueltas. Deja la mitad de la mirada al jugador (lookHold 0.5). Al final
	vuelve la cabeza al frente y se para. Desde el joven; la forma final se queda
	más tiempo.
]]

local C = require(script.Parent.Curvas)
local Tipos = require(script.Parent.Parent.Tipos)

local SCAN_A, SCAN_B = 0.14, 0.84
local TURN = 0.3 -- parte de cada tramo en que gira la cabeza al punto nuevo

local function duracion(etapa: number, r: number): number
	return C.entre(r, 1, 6, 10) * C.peso(etapa, 1, 1, 1.1, 1.4)
end

-- Hacia dónde mira en el tramo u (rad, + a su izquierda) y si recién cambió.
local function scan(u: number, r: number): (number, number)
	local k = C.veces(r, 3, 2, 3)
	local p = C.span(u, SCAN_A, SCAN_B) * k
	local i = math.min(math.floor(p), k - 1)
	local function target(n: number): number
		return if n < 0 then 0 else C.entre(r, 10 + n, -0.8, 0.8)
	end
	local turn = C.smooth((p - i) / TURN)
	local blink = C.pulse(p - i, 0.08, 0.06)
	return target(i - 1) + (target(i) - target(i - 1)) * turn, blink
end

local conducta: Tipos.Conducta = {
	nombre = "centinela",
	tipo = "postura",
	pesos = { 0, 0.8, 1.2, 1.4 },
	quieto = true,
	eventos = {},
	duracion = duracion,
	pose = function(u: number, _etapa: number, r: number): Tipos.Pose
		local side = C.lado(r, 2)
		local sit = C.hold(u, 0.02, 0.1, 0.88, 0.98)
		local watch = C.hold(u, 0.1, SCAN_A, SCAN_B, 0.92)
		local yaw, blink = scan(u, r)
		local flick = C.pulse(u, C.entre(r, 5, 0.3, 0.7), 0.015)
		return {
			sit = sit,
			lean = 0.08 * sit,
			lookPitch = -0.15 * C.pulse(u, 0.04, 0.04) + 0.12 * sit,
			lookYaw = yaw * watch,
			lookHold = 0.5 * watch,
			blink = blink * watch,
			earL = 0.5 * sit + 0.25 * flick,
			earR = 0.45 * sit,
			earTipR = 0.4 * flick,
			tailWrap = sit,
			tailSide = side,
			tailAlert = 0.15 * sit,
			tailCalm = -0.4 * sit,
		}
	end,
}

return conducta
