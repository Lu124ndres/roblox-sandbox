--!strict
--[[
	IDs de los productos de Robux (Config.Monetization). Se crean en el
	Creator Hub → tu juego → Monetización → Productos de desarrollador, con el
	precio que dice el comentario, y el número que da Roblox va aquí. En 0 la
	tienda los muestra pero no deja comprarlos. Los 70 existen desde el
	2026-10-19 (ver docs/productos.md). Sección de Assets en su propio
	archivo para que ninguno pase de 200 líneas.
]]

local Products: { [string]: number } = {
	-- Poder x2^n (para siempre)
	Power1 = 3718588679, -- R$ 3   x2
	Power2 = 3718588802, -- R$ 7   x4
	Power3 = 3718589090, -- R$ 15  x8
	Power4 = 3718589478, -- R$ 32  x16
	Power5 = 3718589622, -- R$ 76  x32
	Power6 = 3718589864, -- R$ 128  x64
	Power7 = 3718590185, -- R$ 229 x128
	Power8 = 3718640196, -- R$ 599 x256
	Power9 = 3718640353, -- R$ 999 x512
	Power10 = 3720099091, -- R$ 1300 x1024
	-- Monedas x2^n (para siempre)
	Coins1 = 3718640414, -- R$ 3   x2
	Coins2 = 3718640488, -- R$ 7   x4
	Coins3 = 3718640898, -- R$ 15  x8
	Coins4 = 3718640974, -- R$ 32  x16
	Coins5 = 3718641084, -- R$ 76  x32
	Coins6 = 3718641162, -- R$ 128  x64
	Coins7 = 3718641221, -- R$ 229 x128
	Coins8 = 3718641364, -- R$ 599 x256
	Coins9 = 3718641436, -- R$ 999 x512
	Coins10 = 3720099352, -- R$ 1300 x1024
	-- Entrenamiento para todo el servidor, 15 min
	ServerBoost1 = 3718641640, -- R$ 60  x2
	ServerBoost2 = 3718641697, -- R$ 129  x4
	ServerBoost3 = 3718641786, -- R$ 239  x8
	ServerBoost4 = 3718641927, -- R$ 416  x16
	ServerBoost5 = 3718642036, -- R$ 678 x32
	ServerBoost6 = 3718642096, -- R$ 880 x64
	-- Llenar al monstruo actual
	Fill25 = 3720099484, -- R$ 49
	Fill50 = 3720099519, -- R$ 89
	Fill75 = 3720099544, -- R$ 129
	-- Elegir el siguiente monstruo
	PackInicio = 3720099575, -- R$ 19 (una sola vez)
	ChooseOrca = 3718642216, -- R$ 25
	ChooseOrcaFantasma = 3720099604, -- R$ 149 (Halloween)
	ChooseMinotauro = 3718642266, -- R$ 99
	ChooseDragonMarino = 3718642325, -- R$ 265
	ChooseZorroDeAgua = 3718642377, -- R$ 408
	-- Más descanso en el volcán (+1 min para todo el servidor)
	RestTime = 3720099638, -- R$ 25
	-- Estanques para siempre
	Pond2 = 3720100313, -- R$ 25
	Pond3 = 3720100398, -- R$ 49
	Pond4 = 3720102255, -- R$ 79
	Pond5 = 3720102649, -- R$ 129
	Pond6 = 3720102696, -- R$ 199
	Pond7 = 3720102741, -- R$ 299
	Pond8 = 3720102805, -- R$ 449
	Pond9 = 3720102892, -- R$ 649
	Pond10 = 3720102941, -- R$ 999
	Pond11 = 3718642542, -- R$ 1300 · estanque sagrado x250 (solo Robux)
	-- Giros de la ruleta (guardados)
	Spin1 = 3720102974, -- R$ 24  +1 giro
	Spin5 = 3720103018, -- R$ 80  +5 giros
	-- Regalar un pase a otro jugador
	GiftVIP = 3720103057, -- R$ 299
	GiftReyDelMar = 3720103257, -- R$ 149
	GiftDiosDelVolcan = 3720103306, -- R$ 858
	-- MEJORAS en Robux (el nivel 1 es gratis): cañas
	Rod2 = 3720103346, -- R$ 5
	Rod3 = 3720103386, -- R$ 15
	Rod4 = 3720103425, -- R$ 29
	Rod5 = 3720103460, -- R$ 59
	Rod6 = 3720103651, -- R$ 99
	Rod7 = 3720103684, -- R$ 199
	Rod8 = 3720103728, -- R$ 349
	Rod9 = 3720103769, -- R$ 599
	Rod10 = 3720103796, -- R$ 999
	-- canastas
	Basket2 = 3720103835, -- R$ 9
	Basket3 = 3720104011, -- R$ 25
	Basket4 = 3720104056, -- R$ 49
	Basket5 = 3720104096, -- R$ 129
	Basket6 = 3720104141, -- R$ 299
	-- botas
	Boots2 = 3720104189, -- R$ 5
	Boots3 = 3720104237, -- R$ 19
	Boots4 = 3720104375, -- R$ 39
	Boots5 = 3720104441, -- R$ 79
	Boots6 = 3720104467, -- R$ 199
}

return Products
