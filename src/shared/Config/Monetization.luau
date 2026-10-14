--!strict
--[[
	Monetización. Los IDs reales se crean en el Creator Hub con el juego
	publicado: pases en Assets.GamePasses y productos en Assets.Products
	(mismas claves que aquí). `robux` son los precios a poner al crearlos; la
	tienda muestra el precio real de Roblox cuando el ID existe.

	Mejoras que se acumulan (productos, una por nivel, cada una más cara):
		Power<n>  todo el poder que gana x2^n   (x2, x4, x8...)
		Coins<n>  monedas por alimentar y descubrir peces x2^n
	x2 del servidor (ServerBoost<n>): dura `minutes`. Si alguien compra
	mientras está activo, el tiempo vuelve a `minutes` y sube a x2^n. Al
	vencer vuelve a x1 y la próxima compra es el nivel 1 otra vez.
	Pase VIP: etiqueta, suerte extra y premio diario x2.
	Pases con traje (como el Faraón de «Construye la Pirámide»): se ven en el
	personaje (`outfit`, ver server/Social/Outfits) y pescan más rápido:
		ReyDelMar      pica 2 veces más rápido, recoge con x2 de fuerza, x2 kills
		DiosDelVolcan  pica 3 veces más rápido, recoge de un toque, x2 kills
	Si tiene los dos, de cada ventaja vale la mejor.
	Fill25/50/75: llena esa parte de la barra del monstruo actual.
	Choose<idGigante>: elige el monstruo que sale después del descanso.
	Pond2..Pond10: desbloquea ese estanque para siempre. Pond11: el estanque
	sagrado del centro (x250), que solo se abre así.
	Rod<n>, Basket<n>, Boots<n>: el nivel n de MEJORAS sin juntar monedas
	(upgradeRobux[categoría][n]; el 1 es el gratis).
	Gift<pase>: regalar un pase a otro jugador (los pases no se pueden
	regalar directo en Roblox, así que es un producto con el mismo precio).
	Regalos: Power<n>, Coins<n>, Pond<n> y Gift<pase> se pueden comprar para
	otro jugador del servidor (botón rosa); lo recibe él.
]]

export type PassDef = {
	name: string,
	description: string,
	robux: number,
	luck: number?, -- se suma a la suerte de la caña
	dailyMultiplier: number?,
	biteDelay: number?, -- multiplica la espera hasta que pica (0.5 = el doble de rápido)
	reelStrength: number?, -- multiplica la fuerza de cada toque al recoger
	instantReel: boolean?, -- un toque basta para sacar cualquier pez
	kills: number?, -- kills por cada monstruo llenado
	outfit: string?, -- traje que se ve en el personaje (Social/Outfits)
}

export type LevelDef = {
	name: string, -- "Poder", "Monedas"
	description: string,
	robux: { number }, -- precio de cada nivel; nivel n = x2^n
}

export type FillDef = { name: string, fraction: number, robux: number, order: number }

export type MonetizationConfig = {
	levels: { [string]: LevelDef }, -- claves: "Power", "Coins"
	levelOrder: { string },
	passes: { [string]: PassDef },
	passOrder: { string },
	serverBoost: { name: string, minutes: number, robux: { number } },
	fills: { [string]: FillDef },
	chooseGiant: { [string]: number }, -- precio por id de gigante
	pondRobux: { [number]: number }, -- precio de cada estanque (2..11)
	upgradeRobux: { [string]: { number } }, -- MEJORAS en Robux: Rod/Basket/Boots, por nivel
	passGifts: { [string]: number }, -- precio del producto Gift<pase>
	-- Pack de inicio (producto PackInicio): una sola vez, mucho valor por poco.
	starterPack: { robux: number, coins: number, boostMinutes: number, rod: number, basket: number },
	sellPonds: boolean, -- vender estanques con Robux (false: se abren solo con kills)
	receiptHistory: number, -- cuántas compras recientes se recuerdan por jugador
}

local Monetization: MonetizationConfig = {
	levels = {
		Power = {
			name = "Poder",
			description = "Todo el poder que ganas, para siempre.",
			robux = { 3, 7, 15, 29, 59, 99, 199, 349, 599, 999 },
		},
		Coins = {
			name = "Monedas",
			description = "Todas las monedas que ganas, para siempre.",
			robux = { 3, 7, 15, 29, 59, 99, 199, 349, 599, 999 },
		},
	},
	levelOrder = { "Power", "Coins" },
	passes = {
		VIP = {
			name = "VIP",
			description = "Etiqueta dorada, +20% suerte y premio diario x2.",
			robux = 299,
			luck = 0.2,
			dailyMultiplier = 2,
		},
		ReyDelMar = {
			name = "Rey del Mar",
			description = "Traje de rey. Pican 2 veces más rápido, recoges con x2 de fuerza y x2 kills.",
			robux = 149,
			biteDelay = 0.5,
			reelStrength = 2,
			kills = 2,
			outfit = "ReyDelMar",
		},
		DiosDelVolcan = {
			name = "Dios del Volcán",
			description = "Traje de fuego. Pican 3 veces más rápido, sacas cualquier pez de un toque y x2 kills.",
			robux = 399,
			biteDelay = 1 / 3,
			instantReel = true,
			kills = 2,
			outfit = "DiosDelVolcan",
		},
	},
	passOrder = { "DiosDelVolcan", "ReyDelMar", "VIP" },
	serverBoost = {
		name = "Entrenamiento para todos",
		minutes = 15,
		robux = { 15, 29, 59, 99, 199, 349 }, -- x2, x4, x8, x16, x32, x64
	},
	fills = {
		Fill25 = { name = "Llenar 25%", fraction = 0.25, robux = 49, order = 1 },
		Fill50 = { name = "Llenar 50%", fraction = 0.5, robux = 89, order = 2 },
		Fill75 = { name = "Llenar 75%", fraction = 0.75, robux = 129, order = 3 },
	},
	chooseGiant = {
		Orca = 25,
		Minotauro = 49,
		DragonMarino = 79,
		ZorroDeAgua = 99,
		OrcaFantasma = 149,
	},
	pondRobux = {
		[2] = 25,
		[3] = 49,
		[4] = 79,
		[5] = 129,
		[6] = 199,
		[7] = 299,
		[8] = 449,
		[9] = 649,
		[10] = 999,
		[11] = 799, -- estanque sagrado x250 (solo Robux)
	},
	upgradeRobux = {
		Rod = { 0, 5, 15, 29, 59, 99, 199, 349, 599, 999 },
		Basket = { 0, 9, 25, 49, 129, 299 },
		Boots = { 0, 5, 19, 39, 79, 199 },
	},
	passGifts = { VIP = 299 },
	starterPack = { robux = 49, coins = 15000, boostMinutes = 60, rod = 4, basket = 3 },
	sellPonds = false,
	receiptHistory = 50,
}

return Monetization
