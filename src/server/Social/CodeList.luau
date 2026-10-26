--!strict
--[[
	CodeList

	Códigos que se pueden canjear (solo en el servidor: el cliente no los
	ve). Clave en MAYÚSCULAS, sin espacios. `expires` (opcional) es la fecha
	unix en que deja de servir; se calcula, por ejemplo, en epochconverter.com.
	Para agregar uno: una línea más. Cada jugador canjea cada código una vez.
	`aliasOf`: otro nombre del mismo código (el juego se publica en inglés y
	en español); cuenta como ese código, así no se cobra dos veces.
]]

export type Code = { coins: number?, boostMinutes: number?, expires: number?, aliasOf: string? }

local CodeList: { [string]: Code } = {
	GIGANTES = { coins = 500 },
	ORCA = { boostMinutes = 15 },
	LANZAMIENTO = { coins = 1000, boostMinutes = 10 },
	HALLOWEEN = { coins = 3000, boostMinutes = 30, expires = 1793664000 }, -- hasta el 3 de noviembre
	-- Meta de 50 likes de la actualización del 31 de octubre: se publica al llegar a la meta.
	ESQUELETO = { coins = 5000, boostMinutes = 30, expires = 1793664000 }, -- hasta el 3 de noviembre
	-- En inglés (Feed the Giants). ORCA y HALLOWEEN sirven igual en los dos idiomas.
	GIANTS = { aliasOf = "GIGANTES" },
	LAUNCH = { aliasOf = "LANZAMIENTO" },
	SKELETON = { aliasOf = "ESQUELETO" },
}

return CodeList
