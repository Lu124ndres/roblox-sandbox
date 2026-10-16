--!strict
--[[
	Gigantes: la cadena del servidor, cuánta comida piden y cuánto miden.

	Comida para llenar la barra: se calcula al llegar cada monstruo según
	quiénes están en el servidor (server/Feeding/GiantFood): lo que el
	servidor come por segundo (cada jugador según su canasta, su poder y sus
	renacimientos, x sizing.activeShare) por targetMinutes. Así tarda lo
	mismo con 1 novato que con 40 fuertes: Orca ~6 min, Minotauro ~10, Orca
	fantasma ~10, Dragón ~15, Zorro ~25. `food` es el mínimo (servidor vacío).
	Si no se llena en cycle.maxFeedMinutes, se cansa y se va: la kill es igual
	para todos los que le dieron algo (con un pez basta; Feeding/Contributions).

	delivery: se alimenta manteniendo E: fishPerSecond peces por segundo sin
	renacer (x Rebirth.feedGrowth por renacimiento) o, si es más rápido, la
	canasta llena en basketSeconds (RebirthMath.deliveryPerSecond), en pasos
	de stepSeconds.
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
			food = 400, -- mínimo
			targetMinutes = 6,
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
			food = 600,
			targetMinutes = 10,
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
			food = 900,
			targetMinutes = 15,
			modelBase = "DragonMarino",
			rouletteWeight = 15,
			released = true,
			inRoulette = true,
			lava = true, -- vuela sobre el volcán con el cráter lleno de lava (CraterDrain)
		},
		{
			id = "ZorroDeAgua",
			displayName = "Zorro de agua",
			article = "el",
			multiplier = 20,
			food = 1500,
			targetMinutes = 25,
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
			food = 600,
			targetMinutes = 10,
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
		drainSeconds = 8, -- el agua del volcán baja hasta el fondo al empezar el descanso
		refillSeconds = 6, -- y vuelve a subir con el siguiente monstruo
		maxFeedMinutes = 20, -- si no se llena en esto, se va (y paga la kill igual)
	},
	delivery = {
		stepSeconds = 0.25,
		fishPerSecond = 6, -- un pez cada 0.17 s sin renacer (al principio no se siente lento)
		minSoloSeconds = 180, -- una persona sola tarda al menos esto en llenar un monstruo
		broadcastSeconds = 0.25,
		basketSeconds = 5, -- una canasta llena se vacía en 5 s como mucho
	},
	sizing = {
		activeShare = 0.6, -- el resto del tiempo entrena, compra o pasea
		castOverheadSeconds = 1.6, -- lanzar + recoger (~1 s) + volver a lanzar
		tripSeconds = 12, -- orilla -> volcán -> orilla (el puente lleva rápido)
	},
}

return Giants
