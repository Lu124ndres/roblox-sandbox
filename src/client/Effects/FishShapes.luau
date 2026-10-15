--!strict
--[[
	FishShapes

	Cómo se ve cada pez en 3D (FishModel lo arma con primitivas): tamaño del
	cuerpo (ancho, alto, largo), colores de lomo, panza y aletas, y rasgos
	propios. Los rasgos:
		stripes   bandas verticales (pez payaso) o rayas del lomo (caballa)
		line      línea plateada a lo largo del costado (anchoa)
		spikes    púas (pez globo)
		finlets   aletitas amarillas hacia la cola (atún)
		sword     espada en la nariz, largo en studs (pez espada)
		lure      farolito colgando de la frente (rape abisal)
		tallFins  aletas altas arriba y abajo (pargo, pez luna)
		glow      brilla con luz propia (legendarios)
		rainbow   cambia de color sin parar (mítico)
]]

export type Shape = {
	size: Vector3,
	body: Color3,
	belly: Color3,
	fin: Color3,
	stripes: { color: Color3, count: number, vertical: boolean }?,
	line: Color3?,
	spikes: Color3?,
	finlets: Color3?,
	sword: number?,
	lure: Color3?,
	tallFins: boolean?,
	glow: Color3?,
	rainbow: boolean?,
}

local rgb = Color3.fromRGB
local WHITE = rgb(240, 244, 248)

local FishShapes: { [string]: Shape } = {
	Sardina = {
		size = Vector3.new(0.45, 0.6, 1.7),
		body = rgb(150, 176, 200),
		belly = WHITE,
		fin = rgb(120, 140, 160),
	},
	Anchoa = {
		size = Vector3.new(0.35, 0.45, 1.5),
		body = rgb(110, 150, 180),
		belly = WHITE,
		fin = rgb(100, 130, 150),
		line = rgb(225, 235, 245),
	},
	Caballa = {
		size = Vector3.new(0.55, 0.8, 2),
		body = rgb(60, 140, 190),
		belly = rgb(225, 235, 240),
		fin = rgb(40, 90, 130),
		stripes = { color = rgb(25, 60, 100), count = 5, vertical = false },
	},
	PezPayaso = {
		size = Vector3.new(0.55, 0.85, 1.5),
		body = rgb(255, 132, 40),
		belly = rgb(255, 170, 90),
		fin = rgb(255, 120, 30),
		stripes = { color = WHITE, count = 3, vertical = true },
	},
	PargoRojo = {
		size = Vector3.new(0.6, 1, 1.9),
		body = rgb(225, 75, 75),
		belly = rgb(255, 180, 170),
		fin = rgb(200, 55, 60),
		tallFins = true,
	},
	PezGlobo = {
		size = Vector3.new(1.3, 1.3, 1.4),
		body = rgb(255, 196, 84),
		belly = rgb(255, 240, 200),
		fin = rgb(230, 160, 60),
		spikes = rgb(200, 140, 50),
	},
	Atun = {
		size = Vector3.new(0.9, 1.1, 2.8),
		body = rgb(45, 65, 115),
		belly = rgb(220, 225, 235),
		fin = rgb(60, 80, 130),
		finlets = rgb(255, 210, 60),
	},
	PezEspada = {
		size = Vector3.new(0.7, 0.9, 3),
		body = rgb(80, 110, 180),
		belly = rgb(220, 230, 240),
		fin = rgb(60, 85, 150),
		sword = 2.2,
		tallFins = true,
	},
	RapeAbisal = {
		size = Vector3.new(1.2, 1, 1.6),
		body = rgb(90, 60, 100),
		belly = rgb(140, 100, 140),
		fin = rgb(70, 45, 80),
		lure = rgb(160, 255, 235),
	},
	PezLuna = {
		size = Vector3.new(0.5, 2, 1.9),
		body = rgb(190, 196, 220),
		belly = WHITE,
		fin = rgb(160, 168, 196),
		tallFins = true,
		glow = rgb(200, 220, 255),
	},
	PezDorado = {
		size = Vector3.new(0.6, 0.9, 1.9),
		body = rgb(255, 170, 0),
		belly = rgb(255, 214, 90),
		fin = rgb(235, 130, 10),
		tallFins = true,
		glow = rgb(255, 210, 90),
	},
	PezArcoiris = {
		size = Vector3.new(0.6, 0.9, 2),
		body = rgb(255, 110, 200),
		belly = WHITE,
		fin = rgb(120, 200, 255),
		tallFins = true,
		glow = rgb(255, 160, 230),
		rainbow = true,
	},
}

-- Los peces nuevos de la colección (Config/FishMore).
for _, more in { require(script.Parent.FishShapesMore), require(script.Parent.FishShapesMore2) } do
	for id, shape in more do
		FishShapes[id] = shape :: Shape
	end
end

return FishShapes
