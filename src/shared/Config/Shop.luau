--!strict
--[[
	Tienda de la cabaña: tres mejoras que se compran en orden, cada nivel más
	caro que el anterior. El nivel 1 de cada una es gratis (lo que tiene todo
	jugador nuevo). Qué significa `value` en cada categoría:

		Rod     multiplica el poder que se gana entrenando (estanques y descanso);
		        `luck` sube la probabilidad de los peces poco comunes o mejores
		        (peso x (1 + luck)).
		Basket  multiplica la capacidad de la canasta.
		Boots   velocidad al caminar (la normal de Roblox es 16).

	Precios propuestos: un jugador nuevo gana ~37 monedas/min con la Orca; la
	segunda caña llega en ~4 min y cada nivel cuesta 3-5 veces el anterior.
]]

local Types = require(script.Parent.Types)

local Shop: Types.ShopConfig = {
	Rod = {
		{ name = "Caña de bambú", price = 0, value = 1, luck = 0 },
		{ name = "Caña de madera", price = 150, value = 1.5, luck = 0.05 },
		{ name = "Caña de fibra", price = 750, value = 2, luck = 0.1 },
		{ name = "Caña de coral", price = 3000, value = 3, luck = 0.15 },
		{ name = "Caña de acero", price = 12000, value = 5, luck = 0.2 },
		{ name = "Caña dorada", price = 45000, value = 8, luck = 0.3 },
		{ name = "Caña de cristal", price = 150000, value = 12, luck = 0.4 },
		{ name = "Caña del abismo", price = 300000, value = 20, luck = 0.55 },
		{ name = "Caña volcánica", price = 800000, value = 35, luck = 0.75 },
		{ name = "Caña del leviatán", price = 2000000, value = 60, luck = 1 },
		{ name = "Caña de perlas", price = 5000000, value = 100, luck = 1.15 },
		{ name = "Caña de esmeralda", price = 12000000, value = 160, luck = 1.3 },
		{ name = "Caña de hielo eterno", price = 30000000, value = 250, luck = 1.5 },
		{ name = "Caña del kraken", price = 75000000, value = 400, luck = 1.7 },
		{ name = "Caña solar", price = 180000000, value = 650, luck = 1.9 },
		{ name = "Caña de obsidiana", price = 450000000, value = 1000, luck = 2.1 },
		{ name = "Caña de rubí", price = 1100000000, value = 1600, luck = 2.35 },
		{ name = "Caña de las tormentas", price = 2700000000, value = 2500, luck = 2.6 },
		{ name = "Caña del cosmos", price = 6500000000, value = 4000, luck = 2.8 },
		{ name = "Caña de Poseidón", price = 16000000000, value = 6500, luck = 3 },
	},
	Basket = {
		{ name = "Canasta de mimbre", price = 0, value = 1 },
		{ name = "Canasta reforzada", price = 300, value = 1.5 },
		{ name = "Cesta de pescador", price = 2000, value = 2 },
		{ name = "Baúl marino", price = 10000, value = 3 },
		{ name = "Red de arrastre", price = 60000, value = 5 },
		{ name = "Bodega del abismo", price = 350000, value = 8 },
		{ name = "Cofre de coral", price = 900000, value = 12 },
		{ name = "Barril pirata", price = 2500000, value = 18 },
		{ name = "Saco de cristal", price = 7000000, value = 26 },
		{ name = "Cofre volcánico", price = 20000000, value = 38 },
		{ name = "Jaula dorada", price = 60000000, value = 55 },
		{ name = "Tesoro del leviatán", price = 180000000, value = 80 },
		{ name = "Arca celestial", price = 550000000, value = 115 },
		{ name = "Bóveda infinita", price = 1600000000, value = 160 },
	},
	Boots = {
		{ name = "Sandalias", price = 0, value = 16 },
		{ name = "Botas de playa", price = 200, value = 18 },
		{ name = "Botas de marinero", price = 1200, value = 20 },
		{ name = "Botas veloces", price = 6000, value = 23 },
		{ name = "Botas del viento", price = 30000, value = 26 },
		{ name = "Botas del rayo", price = 150000, value = 30 },
		{ name = "Botas de coral", price = 400000, value = 32 },
		{ name = "Botas de explorador", price = 1200000, value = 34 },
		{ name = "Botas de hielo", price = 3500000, value = 36 },
		{ name = "Botas de lava", price = 10000000, value = 38 },
		{ name = "Botas de cristal", price = 30000000, value = 40 },
		{ name = "Botas del cometa", price = 90000000, value = 42 },
		{ name = "Botas del abismo", price = 270000000, value = 44 },
		{ name = "Botas de Hermes", price = 800000000, value = 46 },
	},
}

return Shop
