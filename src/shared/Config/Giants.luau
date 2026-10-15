--!strict
--[[
	Gigantes: la cadena del servidor, cuánta comida piden y cuánto miden.

	Comida para llenar la barra: FIJA (food), no cambia con los jugadores, y
	escalonada como las pirámides de «Construye la Pirámide» (Básica → Gema):
	Orca 500K, Minotauro 2.5M, Orca fantasma 5M, Dragón 12M, Zorro 50M. Con
	el poder como fuerza (shared/FishingPower), un novato lleva ~1-4K de comida
	por viaje y uno con 1B de poder ~1.4M: la Orca es difícil solo con
	novatos y rápida con un par de fuertes; el Zorro necesita un servidor fuerte.
	Kill: para todos los que le dieron algo (con un pez basta; Feeding/Contributions).

	delivery: se alimenta manteniendo E: fishPerSecond peces por segundo sin
	renacer (x Rebirth.feedGrowth por renacimiento), en pasos de stepSeconds.
	Tope por persona: nunca más de 1/minSoloSeconds de la barra por segundo
	(una sola persona tarda al menos 5 min; varios, menos). Los lotes se
	anuncian a los clientes y el progreso se publica a lo sumo cada broadcastSeconds.

	Crecen por etapas: cada etapa empieza en stageThresholds[i] de la barra y
	mide stageHeightsInPlayers[i] veces el alto de un jugador. Con un jugador
	de 5.5 studs: 16.5, 44, 82.5 y 165 studs.

	Enojo: si nadie le da de comer en graceSeconds, se enoja poco a poco
	(0 -> 1 en rampSeconds). Desde angryThreshold la barra baja sola (nunca por
	debajo del inicio de la etapa actual: no encoge). Furioso (1) lanza
	Salpicones cada attackIntervalSeconds con telegraphSeconds de aviso. El
	golpe solo empuja: nunca se pierde nada. Un solo bocado lo calma.

	Ciclo: al llenarse se despide (farewellSeconds) y empieza el descanso:
	clamp(restBaseSeconds + restPerPlayerSeconds x jugadores, restMinSeconds,
	restSeconds) segundos (restSeconds es el máximo). En el centro del lago emerge la guarida del descanso y
	todo el que esté sobre ella gana poder solo, a su mejor estanque
	desbloqueado x el multiplicador del monstruo que se llenó. Quien le dio de comer suma +1 kill. Al terminar
	gira la ruleta (rouletteSeconds, todos la ven): sale el que alguien compró o,
	si nadie, uno al azar entre los inRoulette según rouletteWeight (Orca 50 %,
	Minotauro 30 %, Dragón 15 %, Zorro 5 %), y llega (arrivalSeconds).
]]

local Types = require(script.Parent.Types)

local Giants: Types.GiantsConfig = {
	chain = {
		{
			id = "Orca",
			displayName = "Orca",
			article = "la",
			multiplier = 2,
			food = 500000,
			modelBase = "Orca",
			rouletteWeight = 50,
			released = true,
			inRoulette = true,
		},
		{
			id = "Minotauro",
			displayName = "Minotauro",
			article = "el",
			multiplier = 4,
			food = 2500000,
			modelBase = "Minotauro",
			rouletteWeight = 30,
			released = true,
			inRoulette = true, -- sin modelo de Meshy aún: usa la orca teñida (GiantTemplates)
		},
		{
			id = "DragonMarino",
			displayName = "Dragón marino",
			article = "el",
			multiplier = 10,
			food = 12000000,
			modelBase = "DragonMarino",
			rouletteWeight = 15,
			released = false,
			inRoulette = true,
		},
		{
			id = "ZorroDeAgua",
			displayName = "Zorro de agua",
			article = "el",
			multiplier = 20,
			food = 50000000,
			modelBase = "ZorroDeAgua",
			rouletteWeight = 5,
			released = false,
			inRoulette = true,
		},
		{
			-- Evento de Halloween: del 17 de octubre al 3 de noviembre de 2026 (UTC).
			id = "OrcaFantasma",
			displayName = "Orca fantasma",
			article = "la",
			multiplier = 6,
			food = 5000000,
			modelBase = "OrcaFantasma",
			rouletteWeight = 35,
			released = true,
			inRoulette = true,
			season = { from = 1792195200, to = 1793664000 },
		},
	},
	stageThresholds = { 0, 0.25, 0.5, 0.75 },
	playerHeightStuds = 5.5,
	stageHeightsInPlayers = { 3, 8, 15, 30 },
	anger = {
		graceSeconds = 45,
		smallServerPlayers = 3,
		smallServerGraceSeconds = 150,
		rampSeconds = 60,
		angryThreshold = 0.5,
		hungerDecayPerSecond = 0.0005, -- fracción de la barra: ~8 min para perder una etapa entera
		attackIntervalSeconds = 9,
		telegraphSeconds = 3,
		attackRadiusStuds = 18,
		hitMarginStuds = 2, -- se perdona el borde del círculo (ping)
		attackRangeStuds = 260, -- solo apunta a jugadores a esta distancia del cráter
		knockbackSpeed = 70,
	},
	cycle = {
		farewellSeconds = 7,
		evolveSeconds = 3, -- al llenar cada cuarto de barra evoluciona y no come
		restSeconds = 120, -- máximo
		restBaseSeconds = 60,
		restPerPlayerSeconds = 1.2,
		restMinSeconds = 60,
		arrivalSeconds = 6,
		rouletteSeconds = 6,
	},
	delivery = {
		stepSeconds = 0.25,
		fishPerSecond = 3, -- un pez cada 0.33 s sin renacer
		minSoloSeconds = 300, -- una persona sola tarda al menos esto en llenar un monstruo
		broadcastSeconds = 0.25,
	},
}

return Giants
