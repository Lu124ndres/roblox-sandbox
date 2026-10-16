--!strict
--[[
	Progresión: estanques de entrenamiento y poder de pesca.

	En un estanque se entrena sin hacer nada (AFK): cada tick suma
	powerPerTick x multiplicador del estanque x caña. Cada estanque se abre
	con monstruos llenados (requiredKills, para siempre) O con poder
	(requiredPower; el poder se reinicia al renacer, las kills no). Con la
	caña al día, entrenar en el anterior lleva ~10-25 min hasta el poder del
	siguiente; con kills, un monstruo sale cada ~6-25 min.

	El poder es la FUERZA (como en «Construye la Pirámide»): cuántos peces
	cargas (fórmulas en Shared/FishingPower):
		capacidad = (carryCapacity + capacityPerRoot x sqrt(poder)) x canasta
		            -> 1K: 83; 100K: 652; 1M: 2,020; 1B: 63K; 5B: 141K; 60T: 15.5M
		peces por pique = capacidad / lanzamientos para llenarla (castsToFill:
		            16 con la caña 1, 0.5 menos por cada caña, mínimo 6)
		velocidad = 1 + sqrt(poder) / 40 -> 2,000: x2.1; 40,000: x6; 600,000: x20
	La espera hasta el pique nunca baja de minBiteDelaySeconds.
]]

local Types = require(script.Parent.Types)

local Progression: Types.ProgressionConfig = {
	ponds = {
		{ multiplier = 1, requiredKills = 0, requiredPower = 0 },
		{ multiplier = 2, requiredKills = 1, requiredPower = 2000 },
		{ multiplier = 3, requiredKills = 2, requiredPower = 8000 },
		{ multiplier = 5, requiredKills = 3, requiredPower = 25000 },
		{ multiplier = 8, requiredKills = 5, requiredPower = 75000 },
		{ multiplier = 12, requiredKills = 8, requiredPower = 200000 },
		{ multiplier = 20, requiredKills = 12, requiredPower = 600000 },
		{ multiplier = 35, requiredKills = 18, requiredPower = 2000000 },
		{ multiplier = 60, requiredKills = 25, requiredPower = 6000000 },
		{ multiplier = 100, requiredKills = 35, requiredPower = 20000000 },
		{ multiplier = 250, requiredKills = 0, requiredPower = 0, robuxOnly = true }, -- sagrado, en el centro
	},
	biteSpeedDivisor = 40,
	capacityPerRoot = 2,
	castsToFill = { start = 16, perRod = 0.5, min = 6 },
	minBiteDelaySeconds = 0.4,
	coinScale = { step = 1000, exponent = 0.5 }, -- canasta llena: 20 x (1 + sqrt(poder / 1000)) peces pagados
}

return Progression
