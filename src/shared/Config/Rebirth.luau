--!strict
--[[
	Rebirth

	Renacer: con suficientes monedas (cost = baseCoins x growth ^ veces que ya
	renació) se reinicia el avance de esta vuelta y se gana un multiplicador
	para siempre: x(1 + bonusPerRebirth x renacimientos) de monedas y de poder.
	Se pierde: monedas, poder, mejoras de la tienda y la canasta.
	Se queda: kills (y los estanques que abren), colección, pases, compras con
	Robux, códigos, insignias y misiones.
]]

export type RebirthConfig = { baseCoins: number, growth: number, bonusPerRebirth: number }

local Rebirth: RebirthConfig = {
	baseCoins = 1000000,
	growth = 3,
	bonusPerRebirth = 0.5,
}

return Rebirth
