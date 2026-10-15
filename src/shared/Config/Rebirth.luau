--!strict
--[[
	Rebirth

	Renacer: con suficientes monedas (cost = baseCoins x growth ^ veces que ya
	renació) se reinicia el avance de esta vuelta y se gana, para siempre,
	velocidad de alimentar: feedGrowth ^ renacimientos veces más peces por
	segundo (Giants.delivery.fishPerSecond sin renacer). No da monedas ni poder.
	Se pierde: monedas, poder, mejoras de la tienda y la canasta.
	Se queda: kills (y los estanques que abren), colección, pases, compras con
	Robux, códigos, insignias y misiones.
]]

export type RebirthConfig = { baseCoins: number, growth: number, feedGrowth: number }

local Rebirth: RebirthConfig = {
	baseCoins = 1000000,
	growth = 3,
	feedGrowth = 2, -- x2 de velocidad de alimentar por renacimiento
}

return Rebirth
