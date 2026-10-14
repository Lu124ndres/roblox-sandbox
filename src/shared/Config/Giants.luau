--!strict
--[[
	Gigantes: la cadena del servidor, cuánta comida piden y cuánto miden.

	Comida para llenar la barra: FIJA (food), no cambia con los jugadores, y
	crece con el multiplicador: food = 14.5K x raíz(multiplicador / 2). Un
	novato da ~0.45 de comida/s y un pro (poder ~80K, caña 6, canasta 4)
	~1.9/s. Con 45 novatos y 5 pros (~30/s):
		Orca          ~8 min   (novatos solos ~11)
		Minotauro     ~11 min  (novatos solos ~15)
		Dragón marino ~18 min  (novatos solos ~24)
		Zorro de agua ~26 min  (novatos solos ~34)
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
	su mejor estanque desbloqueado. Quien le dio de comer suma +1 kill. Al terminar
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
			food = 14500,
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
			food = 20500,
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
			food = 32400,
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
			food = 45900,
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
			food = 25100,
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
		restSeconds = 120, -- máximo
		restBaseSeconds = 60,
		restPerPlayerSeconds = 1.2,
		restMinSeconds = 60,
		restTrainingMultiplier = 2,
		arrivalSeconds = 6,
		rouletteSeconds = 6,
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
