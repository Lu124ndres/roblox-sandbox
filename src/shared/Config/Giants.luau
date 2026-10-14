--!strict
--[[
	Gigantes: la cadena del servidor, cuánta comida piden y cuánto miden.

	Comida para llenar la barra: FIJA (food), no cambia con los jugadores.
	Calibrada con lo que entrega un jugador (ver docs/balance.md): un novato
	~0.45 de comida/s y un pro (poder ~80K, caña 6, canasta 4) ~1.9/s, con
	~80 % del tiempo pescando o entregando. Con 50 jugadores:
		Orca          novatos ~7 min · pros ~1.5 min
		Minotauro     ~9 min · ~2 min
		Dragón marino ~12 min · ~3 min
		Zorro de agua ~15 min · ~3.5 min (ninguno pasa de 15 min)
	Solo se lleva la kill quien aportó al menos scaling.minKillShare de la barra.

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
			food = 8000,
			modelBase = "Orca",
			released = true,
			inRoulette = true,
		},
		{
			id = "Minotauro",
			displayName = "Minotauro",
			article = "el",
			multiplier = 3,
			food = 10000,
			modelBase = "Minotauro",
			released = true,
			inRoulette = false, -- falta su modelo (Meshy)
		},
		{
			id = "DragonMarino",
			displayName = "Dragón marino",
			article = "el",
			multiplier = 8,
			food = 13000,
			modelBase = "DragonMarino",
			released = false,
			inRoulette = false,
		},
		{
			id = "ZorroDeAgua",
			displayName = "Zorro de agua",
			article = "el",
			multiplier = 20,
			food = 16000,
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
		restSeconds = 120, -- máximo
		restBaseSeconds = 60,
		restPerPlayerSeconds = 1.2,
		restMinSeconds = 60,
		restTrainingMultiplier = 2,
		arrivalSeconds = 6,
	},
	scaling = {
		minKillShare = 0.005,
	},
	delivery = {
		stepSeconds = 0.25,
		maxDeliverySeconds = 4,
		broadcastSeconds = 0.25,
	},
}

return Giants
