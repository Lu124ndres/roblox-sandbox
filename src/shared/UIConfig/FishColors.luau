--!strict
--[[
	Colores de los peces y de las rarezas (sección de UIConfig en su propio
	archivo). Color principal de cada pez por id de Config.Economy.fish: lo
	usan los avisos; el modelo 3D completo vive en client/Effects/FishShapes.
]]

local FishColors = {
	Fish = {
		Sardina = Color3.fromRGB(176, 196, 214),
		Anchoa = Color3.fromRGB(140, 176, 200),
		Caballa = Color3.fromRGB(96, 170, 214),
		PezPayaso = Color3.fromRGB(255, 132, 40),
		PargoRojo = Color3.fromRGB(230, 80, 80),
		PezGlobo = Color3.fromRGB(255, 196, 84),
		Atun = Color3.fromRGB(70, 96, 150),
		PezEspada = Color3.fromRGB(90, 120, 190),
		RapeAbisal = Color3.fromRGB(110, 70, 120),
		PezLuna = Color3.fromRGB(200, 205, 225),
		PezDorado = Color3.fromRGB(255, 200, 40),
		PezArcoiris = Color3.fromRGB(255, 110, 200),
		Arenque = Color3.fromRGB(150, 185, 210),
		Lenguado = Color3.fromRGB(170, 140, 105),
		PezCirujano = Color3.fromRGB(40, 110, 230),
		PezLoro = Color3.fromRGB(40, 200, 170),
		PezLeon = Color3.fromRGB(230, 90, 60),
		Barracuda = Color3.fromRGB(150, 165, 180),
		Mantarraya = Color3.fromRGB(70, 85, 120),
		TiburonMartillo = Color3.fromRGB(130, 145, 160),
		PezVela = Color3.fromRGB(50, 100, 220),
		Celacanto = Color3.fromRGB(90, 120, 210),
		PezCristal = Color3.fromRGB(150, 240, 255),
		PezGalaxia = Color3.fromRGB(150, 80, 255),
	} :: { [string]: Color3 },

	-- Por id de rareza: cartel, borde de la tarjeta, haz de luz y destellos.
	Rarity = {
		Comun = Color3.fromRGB(220, 226, 232),
		PocoComun = Color3.fromRGB(110, 226, 120),
		Raro = Color3.fromRGB(80, 170, 255),
		Epico = Color3.fromRGB(190, 100, 255),
		Legendario = Color3.fromRGB(255, 196, 40),
		Mitico = Color3.fromRGB(255, 80, 190),
	} :: { [string]: Color3 },
}

return FishColors
