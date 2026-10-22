--!strict
--[[
	Tienda de la cabaña: tres mejoras que se compran en orden, cada nivel más
	caro que el anterior. El nivel 1 de cada una es gratis (lo que tiene todo
	jugador nuevo). Qué significa `value` en cada categoría:

		Rod     suerte: sube la probabilidad de los peces poco comunes o mejores
		        (peso x (1 + value)). Desde el 2026-10-21 la caña ya no multiplica
		        el poder al entrenar (pedido del usuario, sin compensar).
		Basket  multiplica la capacidad de la canasta.
		Boots   velocidad al caminar: se empieza en 22 (más que los 16 de Roblox) y
		        llega a 100; el puente al volcán va a 56 si las botas van más lento.

	Precios: un jugador nuevo gana ~200 monedas/min pescando con la Orca (más
	con poder, canasta y monstruos mejores; ver docs/balance.md); la segunda
	caña llega en el primer minuto y cada nivel cuesta 2.5-4 veces el anterior.
	Desde el 2026-10-21 cada mejora tiene 40 niveles; los nuevos siguen la curva: x2.5
	por caña y x2.8 por canasta y botas. La velocidad de las botas sube parejo de
	52 (nivel 14) a 100 (nivel 40).
]]

local Types = require(script.Parent.Types)

local Shop: Types.ShopConfig = {
	Rod = {
		{ name = "Caña de bambú", price = 0, value = 0 },
		{ name = "Caña de madera", price = 150, value = 0.05 },
		{ name = "Caña de fibra", price = 750, value = 0.1 },
		{ name = "Caña de coral", price = 3000, value = 0.15 },
		{ name = "Caña de acero", price = 12000, value = 0.2 },
		{ name = "Caña dorada", price = 45000, value = 0.3 },
		{ name = "Caña de cristal", price = 150000, value = 0.4 },
		{ name = "Caña del abismo", price = 300000, value = 0.55 },
		{ name = "Caña volcánica", price = 800000, value = 0.75 },
		{ name = "Caña del leviatán", price = 2e6, value = 1 },
		{ name = "Caña de perlas", price = 5e6, value = 1.15 },
		{ name = "Caña de esmeralda", price = 12e6, value = 1.3 },
		{ name = "Caña de hielo eterno", price = 30e6, value = 1.5 },
		{ name = "Caña del kraken", price = 75e6, value = 1.7 },
		{ name = "Caña solar", price = 180e6, value = 1.9 },
		{ name = "Caña de obsidiana", price = 450e6, value = 2.1 },
		{ name = "Caña de rubí", price = 1.1e9, value = 2.35 },
		{ name = "Caña de las tormentas", price = 2.7e9, value = 2.6 },
		{ name = "Caña del cosmos", price = 6.5e9, value = 2.8 },
		{ name = "Caña de Poseidón", price = 16e9, value = 3 },
		{ name = "Caña de jade", price = 40e9, value = 3.3 },
		{ name = "Caña de zafiro", price = 100e9, value = 3.6 },
		{ name = "Caña de la aurora", price = 250e9, value = 3.9 },
		{ name = "Caña del dragón", price = 620e9, value = 4.2 },
		{ name = "Caña de amatista", price = 1.6e12, value = 4.6 },
		{ name = "Caña del eclipse", price = 3.9e12, value = 5 },
		{ name = "Caña de diamante", price = 9.8e12, value = 5.4 },
		{ name = "Caña del fénix", price = 24e12, value = 5.8 },
		{ name = "Caña lunar", price = 61e12, value = 6.3 },
		{ name = "Caña del trueno", price = 150e12, value = 6.8 },
		{ name = "Caña de plasma", price = 380e12, value = 7.3 },
		{ name = "Caña de la nebulosa", price = 950e12, value = 7.9 },
		{ name = "Caña del tritón", price = 2.4e15, value = 8.5 },
		{ name = "Caña galáctica", price = 6e15, value = 9.2 },
		{ name = "Caña de los titanes", price = 15e15, value = 10 },
		{ name = "Caña del vacío", price = 37e15, value = 10.8 },
		{ name = "Caña estelar", price = 93e15, value = 11.7 },
		{ name = "Caña de los dioses", price = 230e15, value = 12.6 },
		{ name = "Caña del infinito", price = 580e15, value = 13.6 },
		{ name = "Caña eterna", price = 1.5e18, value = 15 },
	},
	Basket = {
		{ name = "Canasta de mimbre", price = 0, value = 1 },
		{ name = "Canasta reforzada", price = 300, value = 1.5 },
		{ name = "Cesta de pescador", price = 2000, value = 2 },
		{ name = "Baúl marino", price = 10000, value = 3 },
		{ name = "Red de arrastre", price = 60000, value = 5 },
		{ name = "Bodega del abismo", price = 350000, value = 8 },
		{ name = "Cofre de coral", price = 900000, value = 12 },
		{ name = "Barril pirata", price = 2.5e6, value = 18 },
		{ name = "Saco de cristal", price = 7e6, value = 26 },
		{ name = "Cofre volcánico", price = 20e6, value = 38 },
		{ name = "Jaula dorada", price = 60e6, value = 55 },
		{ name = "Tesoro del leviatán", price = 180e6, value = 80 },
		{ name = "Arca celestial", price = 550e6, value = 115 },
		{ name = "Bóveda infinita", price = 1.6e9, value = 160 },
		{ name = "Cofre de jade", price = 4.5e9, value = 220 },
		{ name = "Canasta de zafiro", price = 13e9, value = 300 },
		{ name = "Arcón de la aurora", price = 35e9, value = 400 },
		{ name = "Nido del dragón", price = 98e9, value = 530 },
		{ name = "Cofre de amatista", price = 280e9, value = 700 },
		{ name = "Bolsa del eclipse", price = 770e9, value = 920 },
		{ name = "Cofre de diamante", price = 2.2e12, value = 1200 },
		{ name = "Cesta del fénix", price = 6e12, value = 1550 },
		{ name = "Baúl lunar", price = 17e12, value = 2000 },
		{ name = "Cofre del trueno", price = 47e12, value = 2600 },
		{ name = "Cápsula de plasma", price = 130e12, value = 3400 },
		{ name = "Bolsa de la nebulosa", price = 370e12, value = 4400 },
		{ name = "Red del tritón", price = 1e15, value = 5700 },
		{ name = "Bodega galáctica", price = 2.9e15, value = 7400 },
		{ name = "Arcón de los titanes", price = 8.2e15, value = 9600 },
		{ name = "Cofre del vacío", price = 23e15, value = 12500 },
		{ name = "Cesta estelar", price = 64e15, value = 16000 },
		{ name = "Tesoro de los dioses", price = 180e15, value = 21000 },
		{ name = "Saco del infinito", price = 500e15, value = 27000 },
		{ name = "Cofre del sol negro", price = 1.4e18, value = 35000 },
		{ name = "Arcón del kraken rey", price = 3.9e18, value = 45000 },
		{ name = "Cofre de la supernova", price = 11e18, value = 58000 },
		{ name = "Bodega del leviatán", price = 31e18, value = 75000 },
		{ name = "Cofre del firmamento", price = 86e18, value = 97000 },
		{ name = "Cofre del origen", price = 240e18, value = 125000 },
		{ name = "Bóveda eterna", price = 670e18, value = 160000 },
	},
	Boots = {
		{ name = "Sandalias", price = 0, value = 22 },
		{ name = "Botas de playa", price = 200, value = 24 },
		{ name = "Botas de marinero", price = 1200, value = 26 },
		{ name = "Botas veloces", price = 6000, value = 29 },
		{ name = "Botas del viento", price = 30000, value = 32 },
		{ name = "Botas del rayo", price = 150000, value = 35 },
		{ name = "Botas de coral", price = 400000, value = 38 },
		{ name = "Botas de explorador", price = 1.2e6, value = 40 },
		{ name = "Botas de hielo", price = 3.5e6, value = 42 },
		{ name = "Botas de lava", price = 10e6, value = 44 },
		{ name = "Botas de cristal", price = 30e6, value = 46 },
		{ name = "Botas del cometa", price = 90e6, value = 48 },
		{ name = "Botas del abismo", price = 270e6, value = 50 },
		{ name = "Botas de Hermes", price = 800e6, value = 52 },
		{ name = "Botas de jade", price = 2.2e9, value = 54 },
		{ name = "Botas de zafiro", price = 6.3e9, value = 56 },
		{ name = "Botas de la aurora", price = 18e9, value = 58 },
		{ name = "Botas del dragón", price = 49e9, value = 59 },
		{ name = "Botas de amatista", price = 140e9, value = 61 },
		{ name = "Botas del eclipse", price = 390e9, value = 63 },
		{ name = "Botas de diamante", price = 1.1e12, value = 65 },
		{ name = "Botas del fénix", price = 3e12, value = 67 },
		{ name = "Botas lunares", price = 8.5e12, value = 69 },
		{ name = "Botas del trueno", price = 24e12, value = 70 },
		{ name = "Botas de plasma", price = 66e12, value = 72 },
		{ name = "Botas de la nebulosa", price = 190e12, value = 74 },
		{ name = "Botas del tritón", price = 520e12, value = 76 },
		{ name = "Botas galácticas", price = 1.5e15, value = 78 },
		{ name = "Botas de los titanes", price = 4.1e15, value = 80 },
		{ name = "Botas del vacío", price = 11e15, value = 82 },
		{ name = "Botas estelares", price = 32e15, value = 83 },
		{ name = "Botas de los dioses", price = 90e15, value = 85 },
		{ name = "Botas del infinito", price = 250e15, value = 87 },
		{ name = "Botas del sol negro", price = 700e15, value = 89 },
		{ name = "Botas del kraken rey", price = 2e18, value = 91 },
		{ name = "Botas de la supernova", price = 5.5e18, value = 93 },
		{ name = "Botas del leviatán", price = 15e18, value = 94 },
		{ name = "Botas del firmamento", price = 43e18, value = 96 },
		{ name = "Botas del origen", price = 120e18, value = 98 },
		{ name = "Botas eternas", price = 340e18, value = 100 },
	},
}

return Shop
