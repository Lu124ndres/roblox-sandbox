--!strict
--[[
	Rebirth

	Renacer pide monedas Y poder (n = veces que ya renació):
		monedas = baseCoins x growth ^ n      (20K, 48K, 120K, 280K, 660K...)
		poder   = basePower x powerGrowth ^ n (3K, 7.8K, 20K, 53K, 140K...)
	Los primeros salen en un rato; como crecen más rápido que lo que se gana
	al renacer, cada uno cuesta más que el anterior. Se gana, para siempre,
	velocidad de alimentar: feedGrowth ^ renacimientos (x1.35 por vez: se
	nota, pero no duplica) sobre Giants.delivery.fishPerSecond. No da monedas
	ni poder.
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
}

local Rebirth: RebirthConfig = {
	baseCoins = 20000,
	growth = 2.4,
	basePower = 3000,
	powerGrowth = 2.6,
	feedGrowth = 1.35, -- +35 % de velocidad de alimentar por renacimiento
}

return Rebirth
