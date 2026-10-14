--!strict
--[[
	CodeList

	Códigos que se pueden canjear (solo en el servidor: el cliente no los
	ve). Clave en MAYÚSCULAS, sin espacios. `expires` (opcional) es la fecha
	unix en que deja de servir; se calcula, por ejemplo, en epochconverter.com.
	Para agregar uno: una línea más. Cada jugador canjea cada código una vez.
]]

export type Code = { coins: number?, boostMinutes: number?, expires: number? }

local CodeList: { [string]: Code } = {
	GIGANTES = { coins = 500 },
	ORCA = { boostMinutes = 15 },
	LANZAMIENTO = { coins = 1000, boostMinutes = 10 },
}

return CodeList
