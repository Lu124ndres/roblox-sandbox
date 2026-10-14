--!strict
--[[
	IDs de los productos de Robux (Config.Monetization). Se crean en el
	Creator Hub → tu juego → Monetización → Productos de desarrollador, con el
	precio que dice el comentario, y el número que da Roblox va aquí. En 0 la
	tienda los muestra pero no deja comprarlos. Sección de Assets en su propio
	archivo para que ninguno pase de 200 líneas.
]]

local Products: { [string]: number } = {
	-- Poder x2^n (para siempre)
	Power1 = 3718588679, -- R$ 3   x2
	Power2 = 3718588802, -- R$ 7   x4
	Power3 = 3718589090, -- R$ 15  x8
	Power4 = 3718589478, -- R$ 29  x16
	Power5 = 3718589622, -- R$ 59  x32
	Power6 = 3718589864, -- R$ 99  x64
	Power7 = 3718590185, -- R$ 199 x128
	Power8 = 3718640116, -- R$ 349 x256
	Power9 = 3718640353, -- R$ 599 x512
	Power10 = 0, -- R$ 999 x1024
	-- Monedas x2^n (para siempre)
	Coins1 = 3718640414, -- R$ 3   x2
	Coins2 = 3718640488, -- R$ 7   x4
	Coins3 = 3718640898, -- R$ 15  x8
	Coins4 = 3718640974, -- R$ 29  x16
	Coins5 = 3718641084, -- R$ 59  x32
	Coins6 = 3718641162, -- R$ 99  x64
	Coins7 = 3718641221, -- R$ 199 x128
	Coins8 = 3718641364, -- R$ 349 x256
	Coins9 = 3718641436, -- R$ 599 x512
	Coins10 = 0, -- R$ 999 x1024
	-- Entrenamiento para todo el servidor, 15 min
	ServerBoost1 = 3718641640, -- R$ 15  x2
	ServerBoost2 = 3718641697, -- R$ 29  x4
	ServerBoost3 = 3718641786, -- R$ 59  x8
	ServerBoost4 = 3718641927, -- R$ 99  x16
	ServerBoost5 = 3718642036, -- R$ 199 x32
	ServerBoost6 = 3718642096, -- R$ 349 x64
	-- Llenar al monstruo actual
	Fill25 = 0, -- R$ 49
	Fill50 = 0, -- R$ 89
	Fill75 = 0, -- R$ 129
	-- Elegir el siguiente monstruo
	PackInicio = 0, -- R$ 49 (una sola vez)
	ChooseOrca = 3718642216, -- R$ 25
	ChooseOrcaFantasma = 0, -- R$ 149 (Halloween)
	ChooseMinotauro = 3718642266, -- R$ 49
	ChooseDragonMarino = 3718642325, -- R$ 79
	ChooseZorroDeAgua = 3718642377, -- R$ 99
	-- Estanques para siempre
	Pond2 = 0, -- R$ 25
	Pond3 = 0, -- R$ 49
	Pond4 = 0, -- R$ 79
	Pond5 = 0, -- R$ 129
	Pond6 = 0, -- R$ 199
	Pond7 = 0, -- R$ 299
	Pond8 = 0, -- R$ 449
	Pond9 = 0, -- R$ 649
	Pond10 = 0, -- R$ 999
	Pond11 = 3718642542, -- R$ 799 · estanque sagrado x250 (solo Robux)
	-- Regalar el pase VIP a otro jugador
	GiftVIP = 0, -- R$ 299
	-- MEJORAS en Robux (el nivel 1 es gratis): cañas
	Rod2 = 0, -- R$ 5
	Rod3 = 0, -- R$ 15
	Rod4 = 0, -- R$ 29
	Rod5 = 0, -- R$ 59
	Rod6 = 0, -- R$ 99
	Rod7 = 0, -- R$ 199
	Rod8 = 0, -- R$ 349
	Rod9 = 0, -- R$ 599
	Rod10 = 0, -- R$ 999
	-- canastas
	Basket2 = 0, -- R$ 9
	Basket3 = 0, -- R$ 25
	Basket4 = 0, -- R$ 49
	Basket5 = 0, -- R$ 129
	Basket6 = 0, -- R$ 299
	-- botas
	Boots2 = 0, -- R$ 5
	Boots3 = 0, -- R$ 19
	Boots4 = 0, -- R$ 39
	Boots5 = 0, -- R$ 79
	Boots6 = 0, -- R$ 199
}

return Products
