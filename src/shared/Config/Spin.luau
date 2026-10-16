--!strict
--[[
	Spin

	Ruleta (server/Retention/SpinWheel), como la de los simuladores: 8
	casillas con su probabilidad a la vista (`weight` suma 100, así cada peso
	es su %). Un giro GRATIS cada `cooldownHours` horas (save.spinAt) y giros
	guardados (save.spins) que se ganan jugando (`playSpins`), con el diario
	(Config.Retention.dailySpins), en la propia ruleta o con Robux (Spin1/Spin5).
	Premios por `kind`:
		coins      lo mayor entre `coins` y `share` x el precio de la siguiente
		           caña (shared/RewardScale); el premio mayor es 1 caña entera
		boost      `minutes` de impulso personal (x2 poder)
		fill       llena `fraction` de la barra del monstruo actual para todos;
		           si no está comiendo, paga `share` en monedas
		spins      +`spins` giros guardados
		coinBoost  `minutes` de x`coinBoostMultiplier` monedas (save.coinBoostUntil)
	`label` es el texto corto de la casilla e `icon` un nombre de
	client/Interface/Icons. La ventana (client/Menus/SpinWindow) los muestra.
]]

export type PrizeKind = "coins" | "boost" | "fill" | "spins" | "coinBoost"

export type Prize = {
	kind: PrizeKind,
	weight: number, -- todas suman 100: es el % de la casilla
	label: string,
	icon: string,
	coins: number?,
	share: number?,
	minutes: number?,
	fraction: number?,
	spins: number?,
}

export type SpinConfig = {
	cooldownHours: number, -- cada cuánto hay un giro gratis
	spinSeconds: number, -- lo que gira la ventana antes de mostrar el premio
	coinBoostMultiplier: number, -- premio coinBoost: monedas x esto mientras dure
	-- Por jugar: +1 giro guardado cada `everyMinutes` conectado, hasta `maxPerSession` por sesión
	playSpins: { everyMinutes: number, maxPerSession: number },
	prizes: { Prize }, -- en el orden de las casillas de la ventana
}

local Spin: SpinConfig = {
	cooldownHours = 6,
	spinSeconds = 2.6,
	coinBoostMultiplier = 2,
	playSpins = { everyMinutes = 15, maxPerSession = 4 },
	prizes = {
		{
			kind = "coins",
			weight = 30,
			label = "Monedas",
			icon = "coin",
			coins = 300,
			share = 0.05,
		},
		{ kind = "boost", weight = 20, label = "10 min x2 poder", icon = "bolt", minutes = 10 },
		{ kind = "spins", weight = 8, label = "+1 giro", icon = "ticket", spins = 1 },
		{
			kind = "coins",
			weight = 15,
			label = "Cofre de monedas",
			icon = "chest",
			coins = 1500,
			share = 0.2,
		},
		{
			kind = "coins",
			weight = 2,
			label = "¡JACKPOT!",
			icon = "crown",
			coins = 10000,
			share = 1,
		},
		{
			kind = "fill",
			weight = 10,
			label = "Llena 5% del monstruo",
			icon = "orca",
			fraction = 0.05,
			share = 0.12,
		},
		{
			kind = "coinBoost",
			weight = 5,
			label = "15 min x2 monedas",
			icon = "giftPink",
			minutes = 15,
		},
		{ kind = "boost", weight = 10, label = "30 min x2 poder", icon = "crystal", minutes = 30 },
	},
}

return table.freeze(Spin)
