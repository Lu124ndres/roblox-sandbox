--!strict
--[[
	Gigantes: la cadena del servidor, cuánta comida piden y cuánto miden.

	Comida para llenar la barra: crece con los jugadores ACTIVOS (pescaron en
	los últimos scaling.activeSeconds o llevan peces), así 50 jugadores con
	canastas llenas no lo llenan en segundos:
		total = clamp(loadsPerPlayer x comida media por pez
		              x Σ base x (capacidad / base) ^ capacityExponent,
		              food, food x scaling.maxFoodFactor)     (base = canasta inicial)
	food es el MÍNIMO (y el total si no hay nadie activo). loadsPerPlayer =
	canastas llenas que cada jugador activo tiene que entregar. El total se
	ajusta mientras come (sube si llegan jugadores, baja si se van) sin
	que el gigante encoja ni se llene solo. Solo se
	lleva la kill quien aportó al menos scaling.minKillShare de la barra.

	delivery: cada entrega dura a lo sumo maxDeliverySeconds, en pasos de
	stepSeconds (cada paso es un lote de peces). Los lotes se anuncian a los
	clientes y el progreso se publica a lo sumo cada broadcastSeconds.

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
	todo el que esté sobre ella gana poder solo, a restTrainingMultiplier x
	su mejor estanque desbloqueado. Quien le dio de comer suma +1 kill. Al terminar, la
	ruleta elige al siguiente entre los que tienen inRoulette (los que ya tienen
	sus modelos en ServerStorage) y llega (arrivalSeconds).
]]

local Types = require(script.Parent.Types)

local Giants: Types.GiantsConfig = {
	chain = {
		{
			id = "Orca",
			displayName = "Orca",
			article = "la",
			multiplier = 1,
			food = 300, -- mínimo
			loadsPerPlayer = 1.5,
			modelBase = "Orca",
			released = true,
			inRoulette = true,
		},
		{
			id = "Minotauro",
			displayName = "Minotauro",
			article = "el",
			multiplier = 3,
			food = 2000, -- mínimo
			loadsPerPlayer = 3,
			modelBase = "Minotauro",
			released = true,
			inRoulette = false, -- falta su modelo (Meshy)
		},
		{
			id = "DragonMarino",
			displayName = "Dragón marino",
			article = "el",
			multiplier = 8,
			food = 10000, -- mínimo
			loadsPerPlayer = 5,
			modelBase = "DragonMarino",
			released = false,
			inRoulette = false,
		},
		{
			id = "ZorroDeAgua",
			displayName = "Zorro de agua",
			article = "el",
			multiplier = 20,
			food = 40000, -- mínimo
			loadsPerPlayer = 8,
			modelBase = "ZorroDeAgua",
			released = false,
			inRoulette = false,
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
		hungerDecayPerSecond = 0.002, -- fracción de la barra: ~2 min para perder una etapa entera
		attackIntervalSeconds = 9,
		telegraphSeconds = 3,
		attackRadiusStuds = 18,
		hitMarginStuds = 2, -- se perdona el borde del círculo (ping)
		attackRangeStuds = 260, -- solo apunta a jugadores a esta distancia del cráter
		knockbackSpeed = 70,
	},
	cycle = {
		farewellSeconds = 7,
		restSeconds = 120, -- máximo
		restBaseSeconds = 60,
		restPerPlayerSeconds = 1.2,
		restMinSeconds = 60,
		restTrainingMultiplier = 2,
		arrivalSeconds = 6,
	},
	scaling = {
		activeSeconds = 180,
		maxFoodFactor = 100,
		minKillShare = 0.005,
		recomputeSeconds = 2,
		capacityExponent = 0.6, -- canasta x10 => la comida pide ~x4: mejorar sí acorta los viajes
	},
	delivery = {
		stepSeconds = 0.25,
		maxDeliverySeconds = 4,
		broadcastSeconds = 0.25,
	},
}

return Giants
