--!strict
--[[
	CodeList

	Códigos que se pueden canjear (solo en el servidor: el cliente no los
	ve). Clave en MAYÚSCULAS, sin espacios. `expires` (opcional) es la fecha
	unix en que deja de servir; se calcula, por ejemplo, en epochconverter.com.
	Para agregar uno: una línea más. Cada jugador canjea cada código una vez.
	`aliasOf`: otro nombre del mismo código (el juego se publica en inglés y
	en español); cuenta como ese código, así no se cobra dos veces.
	`likes`: código de la meta de likes (Social/LikeGoal). No sirve hasta que el
	juego llega a esos likes, y entonces sale en el letrero de la plaza.
	`unlocked`: lo abre a mano si la lectura de likes falla.
]]

export type Code = {
	coins: number?,
	boostMinutes: number?,
	expires: number?,
	aliasOf: string?,
	likes: number?,
	unlocked: boolean?,
}

local CodeList: { [string]: Code } = {
	GIGANTES = { coins = 500 },
	ORCA = { boostMinutes = 15 },
	LANZAMIENTO = { coins = 1000, boostMinutes = 10 },
	HALLOWEEN = { coins = 3000, boostMinutes = 30, expires = 1793664000 }, -- hasta el 3 de noviembre
	-- Meta de likes de la actualización del 31 de octubre (hasta el 3 de noviembre).
	ESQUELETO = { coins = 5000, boostMinutes = 30, expires = 1793664000, likes = 50 },
	-- En inglés (Feed the Giants). ORCA y HALLOWEEN sirven igual en los dos idiomas.
	GIANTS = { aliasOf = "GIGANTES" },
	LAUNCH = { aliasOf = "LANZAMIENTO" },
	SKELETON = { aliasOf = "ESQUELETO" },
}

return CodeList
