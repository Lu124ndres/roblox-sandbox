--!strict
--[[
	Gigantes: la cadena del servidor, cuánta comida piden y cuánto miden.

	food = comida total para llenar la barra. Es FIJA: no cambia con la
	cantidad de jugadores ni con su poder. La dificultad la pone cada gigante:
	la Orca es la más fácil y cada uno pide mucho más que el anterior (x6, x5,
	x4), así los siguientes necesitan jugadores con más poder. Ver
	docs/alcance.md, "Calibración".

	Crecen por etapas: cada etapa empieza en stageThresholds[i] de la barra y
	mide stageHeightsInPlayers[i] veces el alto de un jugador. Con un jugador
	de 5.5 studs: 16.5, 44, 82.5 y 165 studs.

	Enojo: si nadie le da de comer en graceSeconds, se enoja poco a poco
	(0 -> 1 en rampSeconds). Desde angryThreshold la barra baja sola (nunca por
	debajo del inicio de la etapa actual: no encoge). Furioso (1) lanza
	Salpicones cada attackIntervalSeconds con telegraphSeconds de aviso. El
	golpe solo empuja: nunca se pierde nada. Un solo bocado lo calma.

	Ciclo: al llenarse se despide (farewellSeconds) y empieza el descanso
	(restSeconds): en el centro del lago emerge la guarida del descanso y
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
			food = 2500,
			modelBase = "Orca",
			released = true,
			inRoulette = true,
		},
		{
			id = "Minotauro",
			displayName = "Minotauro",
			article = "el",
			multiplier = 3,
			food = 15000,
			modelBase = "Minotauro",
			released = true,
			inRoulette = false, -- falta su modelo (Meshy)
		},
		{
			id = "DragonMarino",
			displayName = "Dragón marino",
			article = "el",
			multiplier = 8,
			food = 75000,
			modelBase = "DragonMarino",
			released = false,
			inRoulette = false,
		},
		{
			id = "ZorroDeAgua",
			displayName = "Zorro de agua",
			article = "el",
			multiplier = 20,
			food = 300000,
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
		restSeconds = 120,
		restTrainingMultiplier = 2,
		arrivalSeconds = 6,
	},
}

return Giants
