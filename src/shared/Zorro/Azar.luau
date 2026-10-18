--!strict
--[[
	Zorro/Azar

	El azar del zorro: el mismo número para los mismos enteros en todos los
	clientes, sin estado (el hash de Minotauro/Azar, que ya usan el minotauro y el
	dragón). Lo que decide el cuerpo (lugar, conducta, su duración) y el parpadeo
	sale de aquí con la hora del servidor; así todos ven lo mismo sin red.
		unit(a, b?)              número en [0, 1) para el par (a, b)
		pick(n, a, b?)           índice entre 1 y n
		between(lo, hi, a, b?)   número entre lo y hi
]]

local Base = require(script.Parent.Parent.Minotauro.Azar)

local Azar = {}

Azar.unit = Base.unit
Azar.pick = Base.pick

function Azar.between(lo: number, hi: number, a: number, b: number?): number
	return lo + (hi - lo) * Base.unit(a, b)
end

return table.freeze(Azar)
