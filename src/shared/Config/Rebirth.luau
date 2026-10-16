--!strict
--[[
	Rebirth

	Renacer pide monedas Y poder (n = veces que ya renació):
		monedas = baseCoins x growth ^ n      (40K, 110K, 310K, 880K, 2.5M...)
		poder   = basePower x powerGrowth ^ n (3K, 9K, 27K, 81K, 240K...)
	Los primeros salen en un rato; como crecen más rápido que lo que se gana
	al renacer, cada uno cuesta más que el anterior. Se gana, para siempre:
		velocidad de alimentar  feedGrowth ^ renacimientos (x1.35 por vez)
		                        sobre Giants.delivery.fishPerSecond
		monedas y poder         bonusGrowth ^ renacimientos (+25 % por vez,
		                        se multiplica: x1.25, x1.56, x1.95...)
	Se pierde: monedas, poder, mejoras de la tienda y la canasta.
	Se queda: kills (y los estanques que abren), colección, pases, compras con
	Robux, códigos, insignias y misiones.
]]

export type RebirthConfig = {
	baseCoins: number,
	growth: number,
	basePower: number,
	powerGrowth: number,
	feedGrowth: number,
	bonusGrowth: number,
}

local Rebirth: RebirthConfig = {
	baseCoins = 40000,
	growth = 2.8, -- 2.4 hasta el 2026-10-16: ~2 renacimientos por día la primera semana
	basePower = 3000,
	powerGrowth = 3,
	feedGrowth = 1.35, -- +35 % de velocidad de alimentar por renacimiento
	bonusGrowth = 1.25, -- +25 % de monedas y poder por renacimiento (para siempre)
}

return Rebirth
