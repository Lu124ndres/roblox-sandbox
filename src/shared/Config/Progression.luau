--!strict
--[[
	Progresión: estanques de entrenamiento y poder de pesca.

	En un estanque se entrena sin hacer nada (AFK): cada segundo suma
	powerPerTick x multiplicador del estanque. Los mejores estanques piden un
	mínimo de poder. Valores propuestos, a ajustar: con el estanque anterior,
	desbloquear el siguiente toma de 2.5 a ~100 minutos (~5.5 h en total).

	El poder hace pescar MÁS y MÁS RÁPIDO (fórmulas en Shared/FishingPower):
		velocidad = 1 + sqrt(poder) / 40   -> 2,000: x2.1; 40,000: x6; 600,000: x20
		peces por pique = 1 + floor(sqrt(poder) / 60) -> 3,600: 2; 40,000: 4; 600,000: 13
	La espera hasta el pique nunca baja de minBiteDelaySeconds.
]]

local Types = require(script.Parent.Types)

local Progression: Types.ProgressionConfig = {
	ponds = {
		{ multiplier = 1, requiredPower = 0 },
		{ multiplier = 2, requiredPower = 150 },
		{ multiplier = 3, requiredPower = 600 },
		{ multiplier = 5, requiredPower = 2000 },
		{ multiplier = 8, requiredPower = 6000 },
		{ multiplier = 12, requiredPower = 15000 },
		{ multiplier = 20, requiredPower = 40000 },
		{ multiplier = 35, requiredPower = 100000 },
		{ multiplier = 60, requiredPower = 250000 },
		{ multiplier = 100, requiredPower = 600000 },
	},
	biteSpeedDivisor = 40,
	fishPerCatchDivisor = 60,
	minBiteDelaySeconds = 0.4,
}

return Progression
