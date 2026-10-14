--!strict
--[[
	Social: títulos sobre la cabeza, impulso de amigos, impulso personal y el
	regalo del grupo. (Los códigos viven en el servidor, en
	server/Retention/CodeList, para que nadie los lea desde el cliente.)

	Títulos: el más alto cuyo `power` ya alcanzó el jugador.
	Impulso de amigos: +perFriend por cada amigo de Roblox en el mismo
	servidor, hasta maxFriends; multiplica el poder y las monedas.
	Impulso personal: x`personalBoostMultiplier` de poder mientras dure (lo
	dan los códigos y el regalo del grupo; se suma el tiempo).
	Grupo: quien está en el grupo y juega `minutes` seguidos puede reclamar
	una vez `coins` y `boostMinutes` de impulso. Con groupId = 0 no se puede.
]]

export type TitleDef = { power: number, name: string }

export type SocialConfig = {
	titles: { TitleDef },
	friendBoost: { perFriend: number, maxFriends: number },
	personalBoostMultiplier: number,
	group: { groupId: number, minutes: number, coins: number, boostMinutes: number },
}

local Social: SocialConfig = {
	titles = {
		{ power = 0, name = "Novato" },
		{ power = 100, name = "Aprendiz" },
		{ power = 1000, name = "Pescador" },
		{ power = 5000, name = "Marinero" },
		{ power = 25000, name = "Capitán" },
		{ power = 100000, name = "Almirante" },
		{ power = 500000, name = "Domador de Bestias" },
		{ power = 5000000, name = "Señor del Abismo" },
		{ power = 100000000, name = "Rey de los Océanos" },
		{ power = 10000000000, name = "Dios del Mar" },
	},
	friendBoost = { perFriend = 0.1, maxFriends = 5 },
	personalBoostMultiplier = 2,
	-- groupId: el número del grupo de Roblox del juego (en su página: roblox.com/groups/<número>).
	group = { groupId = 0, minutes = 15, coins = 1500, boostMinutes = 15 },
}

return Social
