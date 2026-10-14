--!strict
--[[
	Progresión: estanques de entrenamiento y poder de pesca.

	En un estanque se entrena sin hacer nada (AFK): cada segundo suma
	powerPerTick x multiplicador del estanque. Los mejores estanques piden un
	mínimo de poder. Valores propuestos, a ajustar: con el estanque anterior,
	desbloquear el siguiente toma de 2.5 a ~100 minutos (~5.5 h en total).

	El poder hace pescar MÁS y MÁS RÁPIDO (fórmulas en Shared/FishingPower):
		velocidad = 1 + sqrt(poder) / 40   -> 2,000: x2.1; 40,000: x6; 600,000: x20
		peces por pique = 1 + floor(log10(1 + poder / 1000)) -> 9,000: 2; 99,000: 3;
		                  999,000: 4 (crece despacio: la comida de los monstruos es fija)
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
	},
	biteSpeedDivisor = 40,
	fishPerCatchStep = 1000,
	minBiteDelaySeconds = 0.4,
}

return Progression
