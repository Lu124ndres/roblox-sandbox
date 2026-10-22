--!strict
--[[
	Social: títulos sobre la cabeza, impulso de amigos, impulso personal y el
	regalo del grupo. (Los códigos viven en el servidor, en
	server/Retention/CodeList, para que nadie los lea desde el cliente.)

	Títulos: el más alto cuyas `kills` (monstruos llenados) ya alcanzó el
	jugador. Las kills no se pierden al renacer: el título nunca baja.
	Impulso de amigos: +perFriend por cada amigo de Roblox en el mismo
	servidor, hasta maxFriends; multiplica el poder y las monedas.
	Impulso personal: x`personalBoostMultiplier` de poder mientras dure (lo
	dan los códigos y el regalo del grupo; se suma el tiempo).
	Grupo: quien está en el grupo y juega `minutes` seguidos puede reclamar,
	en el letrero de la plaza, +`luck` de suerte para siempre (va con los
	impulsos de abajo a la izquierda). Con groupId = 0 no se puede.
	Invitar (referral): un jugador nuevo que entra por la invitación de otro
	gana newCoins y newBoostMinutes; quien lo invitó, si está en el servidor,
	inviterCoins e inviterBoostMinutes (server/Social/Referrals).
]]

export type TitleDef = { kills: number, name: string }

export type SocialConfig = {
	titles: { TitleDef },
	friendBoost: { perFriend: number, maxFriends: number },
	personalBoostMultiplier: number,
	premiumMultiplier: number,
	group: { groupId: number, minutes: number, luck: number },
	referral: {
		newCoins: number,
		newBoostMinutes: number,
		inviterCoins: number,
		inviterBoostMinutes: number,
	},
}

local Social: SocialConfig = {
	titles = {
		{ kills = 0, name = "Novato" },
		{ kills = 1, name = "Aprendiz" },
		{ kills = 3, name = "Pescador" },
		{ kills = 5, name = "Marinero" },
		{ kills = 10, name = "Capitán" },
		{ kills = 20, name = "Almirante" },
		{ kills = 35, name = "Domador de Bestias" },
		{ kills = 50, name = "Señor del Abismo" },
		{ kills = 75, name = "Rey de los Océanos" },
		{ kills = 100, name = "Dios del Mar" },
		{ kills = 150, name = "Titán de las Mareas" },
		{ kills = 200, name = "Señor de las Tormentas" },
		{ kills = 300, name = "Devorador de Leviatanes" },
		{ kills = 400, name = "Emperador del Abismo" },
		{ kills = 500, name = "Guardián de los Siete Mares" },
		{ kills = 650, name = "Coloso Abisal" },
		{ kills = 800, name = "Dios de los Maremotos" },
		{ kills = 1000, name = "Soberano Eterno" },
		{ kills = 1250, name = "Avatar del Océano" },
		{ kills = 1500, name = "Leyenda Inmortal" },
		{ kills = 2000, name = "Destructor de Mundos" },
		{ kills = 2500, name = "Dios Primordial" },
		{ kills = 3000, name = "Omnipotente" },
		{ kills = 4000, name = "El Infinito" },
		{ kills = 5000, name = "Más Allá del Infinito" },
	},

	friendBoost = { perFriend = 0.1, maxFriends = 5 },
	personalBoostMultiplier = 2,
	-- Roblox Premium: multiplica el poder y las monedas (y lleva el ícono de Premium encima).
	premiumMultiplier = 1.1,
	-- groupId: el número del grupo de Roblox del juego (en su página: roblox.com/groups/<número>).
	-- luck: se suma a la de la caña (0.1 = +10 %).
	group = { groupId = 0, minutes = 15, luck = 0.1 },
	-- Invitar: si un jugador NUEVO entra por la invitación de alguien, los dos ganan.
	referral = {
		newCoins = 1000,
		newBoostMinutes = 15,
		inviterCoins = 2500,
		inviterBoostMinutes = 30,
	},
}

return Social
