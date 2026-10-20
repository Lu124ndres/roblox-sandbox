--!strict
--[[
	Progresión: estanques de entrenamiento y poder de pesca.

	En un estanque se entrena sin hacer nada (AFK): cada tick suma
	powerPerTick x multiplicador del estanque x caña. Cada estanque se abre
	SOLO con monstruos llenados (requiredKills, para siempre: las kills no se
	pierden al renacer); el poder no abre estanques (pedido del usuario,
	2026-10-18). Un jugador que aporta a casi todos los monstruos suma ~3-4 kills en 45 min
	(un monstruo cada ~10-12 min con el descanso), así la tabla de abajo
	reparte los 10 estanques en ~4 semanas.

	El poder es la FUERZA (como en «Construye la Pirámide»): cuántos peces
	cargas (fórmulas en Shared/FishingPower):
		capacidad = (carryCapacity + capacityPerRoot x sqrt(poder)) x canasta
		            -> 1K: 83; 100K: 652; 1M: 2,020; 1B: 63K; 5B: 141K; 60T: 15.5M
		peces por pique = capacidad / lanzamientos para llenarla (castsToFill:
		            16 con la caña 1, 0.5 menos por cada caña, mínimo 6)
		velocidad = 1 + sqrt(poder) / 40 -> 2,000: x2.1; 40,000: x6; 600,000: x20
	La espera hasta el pique nunca baja de minBiteDelaySeconds: el poder y las
	cañas llegan hasta ahí y solo los pases (Monetization.passes, biteDelay)
	bajan de ese piso (pedido del usuario el 2026-10-20: que pagar se note).
]]

local Types = require(script.Parent.Types)

local Progression: Types.ProgressionConfig = {
	-- Curva para ~45 min al día con el diario (simulación de docs/balance.md):
	-- estanque 2 ~8 min, 3 ~30 min, 4 día 2, 5 día 3, 6 día 5, 7 día 7,
	-- 8 ~día 12, 9 ~día 19, 10 ~día 29. Las kills son el único camino (no se
	-- pierden al renacer), además de comprar el estanque con Robux.
	ponds = {
		{ multiplier = 1, requiredKills = 0 },
		{ multiplier = 1.5, requiredKills = 1 },
		{ multiplier = 2, requiredKills = 3 },
		{ multiplier = 3, requiredKills = 6 },
		{ multiplier = 4, requiredKills = 9 },
		{ multiplier = 6, requiredKills = 15 },
		{ multiplier = 8, requiredKills = 22 },
		{ multiplier = 12, requiredKills = 40 },
		{ multiplier = 16, requiredKills = 62 },
		{ multiplier = 25, requiredKills = 95 },
		{ multiplier = 50, requiredKills = 0, robuxOnly = true }, -- sagrado: x2 del 10
	},
	biteSpeedDivisor = 40,
	capacityPerRoot = 2,
	castsToFill = { start = 16, perRod = 0.5, min = 6 },
	minBiteDelaySeconds = 1.6, -- Rey del Mar x0.5 = 0.8 s; Dios del Volcán, lo que tarda el corcho (0.7 s)
	coinScale = { step = 1000, exponent = 0.5 }, -- canasta llena: 20 x (1 + sqrt(poder / 1000)) peces pagados
}

return Progression
