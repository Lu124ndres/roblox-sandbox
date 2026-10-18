--!strict
--[[
	Zorro/Conductas/Giros

	Las conductas que dan vueltas con todo el cuerpo (perseguir su cola). Una
	conducta solo suma claves a la pose y nunca gira al zorro: el rumbo es de
	Zorro/Rutina. Por eso el giro va aparte: Giros.de(nombre) da, si la conducta gira,
	la función (u, etapa, r) -> rad que Rutina suma al rumbo con que la empezó
	(+ a su izquierda, como lookYaw). Empieza y termina en vueltas enteras: al
	terminar queda mirando a donde miraba (de frente al público).
]]

local C = require(script.Parent.Curvas)

local Giros = {}

-- Ventana de la persecución (fracciones de la conducta): da vueltas entre a y b.
Giros.PERSECUCION = table.freeze({ 0.2, 0.72 })

-- Cuántas vueltas da: la cría hasta tres, el joven hasta dos.
function Giros.vueltas(etapa: number, r: number): number
	return C.veces(r, 1, 1, if etapa <= 1 then 3 else 2)
end

function Giros.persecucion(u: number, etapa: number, r: number): number
	local a, b = Giros.PERSECUCION[1], Giros.PERSECUCION[2]
	return C.lado(r, 2) * 2 * math.pi * Giros.vueltas(etapa, r) * C.smooth(C.span(u, a, b))
end

local POR_NOMBRE: { [string]: (u: number, etapa: number, r: number) -> number } = {
	persecucion = Giros.persecucion,
}

function Giros.de(nombre: string): ((u: number, etapa: number, r: number) -> number)?
	return POR_NOMBRE[nombre]
end

return table.freeze(Giros)
