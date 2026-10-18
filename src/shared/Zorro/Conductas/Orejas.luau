--!strict
--[[
	Mover cada oreja por su lado: escucha alrededor sin mover el cuerpo. Una oreja se
	echa atrás (oye algo detrás) y vuelve adelante; la otra va por su cuenta, con
	otro ritmo, y las puntas dan sacudidas sueltas. La cabeza apenas acompaña hacia
	la oreja que escucha atrás. Se puede hacer caminando (no es quieto). La
	elige cualquier etapa; la forma final, más lento.
]]

local C = require(script.Parent.Curvas)
local Tipos = require(script.Parent.Parent.Tipos)

local conducta: Tipos.Conducta = {
	nombre = "orejas",
	tipo = "postura",
	pesos = { 1, 1, 1, 1 },
	quieto = false,
	eventos = {},
	duracion = function(etapa: number, r: number): number
		return 3.2 * C.pace(etapa) * C.entre(r, 1, 0.85, 1.25)
	end,
	pose = function(u: number, _etapa: number, r: number): Tipos.Pose
		local side = C.lado(r, 2)
		local shift = 0.06 * C.azar(r, 3) -- la otra oreja no va al compás
		local first = -0.55 * C.hold(u, 0.08, 0.18, 0.38, 0.48)
			+ 0.45 * C.hold(u, 0.5, 0.58, 0.7, 0.8)
		local other = 0.5 * C.hold(u, 0.2 + shift, 0.3 + shift, 0.55, 0.65)
			- 0.4 * C.hold(u, 0.68, 0.76, 0.86, 0.95)
		local tipFirst = 0.5 * C.pulse(u, 0.45, 0.03) - 0.4 * C.pulse(u, 0.85, 0.03)
		local tipOther = 0.5 * C.pulse(u, 0.62 + shift, 0.03)
		return {
			earL = if side > 0 then first else other,
			earR = if side > 0 then other else first,
			earTipL = if side > 0 then tipFirst else tipOther,
			earTipR = if side > 0 then tipOther else tipFirst,
			lookYaw = side * 0.12 * C.hold(u, 0.1, 0.2, 0.4, 0.5),
			tilt = -side * 0.05 * C.hold(u, 0.1, 0.2, 0.4, 0.5),
		}
	end,
}

return conducta
