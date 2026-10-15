--!strict
--[[
	FishShapesMore2

	Forma 3D de la tercera tanda de peces (Config/FishMore), con los mismos
	rasgos que FishShapes: tamaño, colores de lomo, panza y aletas, rayas,
	púas, espada, aletas altas, brillo y arcoíris.
]]

local rgb = Color3.fromRGB
local WHITE = rgb(240, 244, 248)

local FishShapesMore2: { [string]: any } = {
	Boqueron = {
		size = Vector3.new(0.35, 0.5, 1.5),
		body = rgb(150, 175, 200),
		belly = WHITE,
		fin = rgb(140, 160, 185),
		line = rgb(210, 230, 245),
	},
	PezGato = {
		size = Vector3.new(0.7, 0.6, 2),
		body = rgb(110, 92, 72),
		belly = rgb(220, 205, 180),
		fin = rgb(90, 75, 60),
	},
	PezMariposa = {
		size = Vector3.new(0.35, 1.2, 1.2),
		body = rgb(255, 220, 60),
		belly = rgb(255, 245, 200),
		fin = rgb(255, 190, 40),
		stripes = { color = rgb(30, 30, 35), count = 2, vertical = true },
		tallFins = true,
	},
	PezAngel = {
		size = Vector3.new(0.35, 1.4, 1.3),
		body = rgb(70, 120, 255),
		belly = rgb(255, 220, 80),
		fin = rgb(255, 200, 60),
		stripes = { color = rgb(150, 220, 255), count = 4, vertical = false },
		tallFins = true,
	},
	Morena = {
		size = Vector3.new(0.4, 0.55, 3.2),
		body = rgb(80, 130, 55),
		belly = rgb(200, 220, 120),
		fin = rgb(60, 100, 40),
		stripes = { color = rgb(40, 70, 30), count = 9, vertical = true },
	},
	PezNapoleon = {
		size = Vector3.new(1, 1.35, 2.4),
		body = rgb(50, 160, 150),
		belly = rgb(170, 230, 210),
		fin = rgb(40, 120, 140),
		stripes = { color = rgb(120, 220, 255), count = 6, vertical = false },
	},
	TiburonBlanco = {
		size = Vector3.new(1.1, 1.3, 3.8),
		body = rgb(130, 140, 155),
		belly = WHITE,
		fin = rgb(110, 120, 135),
		tallFins = true,
	},
	PezRemo = {
		size = Vector3.new(0.25, 0.8, 4.4),
		body = rgb(215, 225, 240),
		belly = WHITE,
		fin = rgb(240, 60, 70),
		stripes = { color = rgb(120, 140, 170), count = 8, vertical = true },
		tallFins = true,
	},
	PezDragon = {
		size = Vector3.new(0.7, 1.1, 2.6),
		body = rgb(220, 45, 40),
		belly = rgb(255, 200, 80),
		fin = rgb(255, 170, 40),
		spikes = rgb(255, 220, 120),
		tallFins = true,
		glow = rgb(255, 120, 60),
	},
	PezFenix = {
		size = Vector3.new(0.6, 1.1, 2.3),
		body = rgb(255, 130, 20),
		belly = rgb(255, 235, 120),
		fin = rgb(255, 70, 30),
		stripes = { color = rgb(255, 220, 90), count = 5, vertical = false },
		tallFins = true,
		glow = rgb(255, 180, 60),
	},
	PezEstelar = {
		size = Vector3.new(0.7, 1.05, 2.2),
		body = rgb(30, 40, 120),
		belly = rgb(120, 140, 255),
		fin = rgb(150, 200, 255),
		stripes = { color = WHITE, count = 7, vertical = true },
		tallFins = true,
		glow = rgb(170, 200, 255),
		rainbow = true,
	},
	PezCelestial = {
		size = Vector3.new(0.6, 1.2, 2.4),
		body = rgb(255, 245, 215),
		belly = WHITE,
		fin = rgb(255, 210, 90),
		stripes = { color = rgb(255, 200, 70), count = 4, vertical = false },
		tallFins = true,
		glow = rgb(255, 235, 160),
		rainbow = true,
	},
}

return FishShapesMore2
