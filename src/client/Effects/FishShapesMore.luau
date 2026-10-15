--!strict
--[[
	FishShapesMore

	Forma 3D de los peces nuevos (Config/FishMore), con los mismos rasgos que
	FishShapes (que los junta con los suyos): tamaño, colores de lomo, panza
	y aletas, rayas, púas, espada, aletas altas, brillo y arcoíris.
]]

local rgb = Color3.fromRGB
local WHITE = rgb(240, 244, 248)

local FishShapesMore: { [string]: any } = {
	Arenque = {
		size = Vector3.new(0.45, 0.65, 1.8),
		body = rgb(120, 160, 190),
		belly = WHITE,
		fin = rgb(110, 140, 170),
		line = rgb(200, 220, 240),
	},
	Lenguado = { -- pez plano
		size = Vector3.new(1.3, 0.3, 1.6),
		body = rgb(150, 120, 90),
		belly = rgb(235, 225, 210),
		fin = rgb(130, 100, 75),
	},
	PezCirujano = {
		size = Vector3.new(0.5, 1, 1.5),
		body = rgb(40, 110, 230),
		belly = rgb(90, 160, 255),
		fin = rgb(255, 220, 40),
		stripes = { color = rgb(20, 30, 80), count = 2, vertical = false },
	},
	PezLoro = {
		size = Vector3.new(0.6, 0.95, 1.8),
		body = rgb(40, 200, 170),
		belly = rgb(150, 240, 210),
		fin = rgb(255, 110, 180),
		stripes = { color = rgb(255, 150, 200), count = 4, vertical = true },
	},
	PezLeon = {
		size = Vector3.new(0.6, 0.95, 1.6),
		body = rgb(230, 90, 60),
		belly = rgb(255, 220, 200),
		fin = rgb(240, 120, 90),
		stripes = { color = WHITE, count = 6, vertical = true },
		spikes = rgb(255, 230, 220),
		tallFins = true,
	},
	Barracuda = {
		size = Vector3.new(0.45, 0.6, 2.8),
		body = rgb(150, 165, 180),
		belly = WHITE,
		fin = rgb(90, 100, 120),
		stripes = { color = rgb(70, 80, 100), count = 7, vertical = true },
	},
	Mantarraya = { -- ancha y plana
		size = Vector3.new(2.4, 0.3, 1.6),
		body = rgb(40, 50, 75),
		belly = WHITE,
		fin = rgb(30, 40, 60),
	},
	TiburonMartillo = {
		size = Vector3.new(0.9, 1.1, 3.2),
		body = rgb(110, 125, 140),
		belly = rgb(230, 235, 240),
		fin = rgb(90, 105, 120),
		tallFins = true,
	},
	PezVela = {
		size = Vector3.new(0.6, 1, 2.8),
		body = rgb(30, 70, 170),
		belly = rgb(210, 225, 245),
		fin = rgb(60, 120, 255),
		sword = 1.8,
		tallFins = true,
	},
	Celacanto = {
		size = Vector3.new(0.9, 1.2, 2.4),
		body = rgb(50, 70, 140),
		belly = rgb(120, 150, 210),
		fin = rgb(70, 100, 180),
		stripes = { color = rgb(230, 240, 255), count = 5, vertical = false },
		glow = rgb(120, 180, 255),
	},
	PezCristal = {
		size = Vector3.new(0.55, 1, 1.9),
		body = rgb(160, 240, 255),
		belly = WHITE,
		fin = rgb(110, 220, 255),
		tallFins = true,
		glow = rgb(140, 255, 255),
	},
	PezGalaxia = {
		size = Vector3.new(0.65, 1, 2.1),
		body = rgb(70, 30, 150),
		belly = rgb(200, 150, 255),
		fin = rgb(255, 120, 230),
		stripes = { color = rgb(255, 255, 255), count = 6, vertical = false },
		tallFins = true,
		glow = rgb(200, 120, 255),
		rainbow = true,
	},
}

return FishShapesMore
