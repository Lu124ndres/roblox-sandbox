--!strict
--[[
	Progresión: estanques de entrenamiento y poder de pesca.

	En un estanque se entrena sin hacer nada (AFK): cada segundo suma
	powerPerTick x multiplicador del estanque. Los mejores estanques piden un
	mínimo de poder. Valores propuestos, a ajustar: con el estanque anterior,
	desbloquear el siguiente toma de 2.5 a ~100 minutos (~5.5 h en total).

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
		{ multiplier = 1, requiredKills = 0 },
		{ multiplier = 2, requiredKills = 1 },
		{ multiplier = 3, requiredKills = 2 },
		{ multiplier = 5, requiredKills = 4 },
		{ multiplier = 8, requiredKills = 7 },
		{ multiplier = 12, requiredKills = 12 },
		{ multiplier = 20, requiredKills = 20 },
		{ multiplier = 35, requiredKills = 35 },
		{ multiplier = 60, requiredKills = 60 },
		{ multiplier = 100, requiredKills = 100 },
		{ multiplier = 250, requiredKills = 0, robuxOnly = true }, -- sagrado, en el centro
	},
	biteSpeedDivisor = 40,
	capacityPerRoot = 2,
	castsToFill = { start = 16, perRod = 0.5, min = 6 },
	minBiteDelaySeconds = 0.4,
}

return Progression
