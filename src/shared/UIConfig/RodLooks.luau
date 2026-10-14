--!strict
--[[
	Cómo se ve cada caña de la tienda (mismo orden que Config.Shop.Rod):
	color de la vara y de los detalles, material, si brilla y su estilo, que
	agrega adornos propios (los arma client/Fishing/RodBuilder):
		bambu      nudos cada pocos centímetros
		madera     veta de madera y amarres de hilo
		fibra      carbono oscuro con amarres de colores
		coral      ramitas de coral y una perla
		acero      metal brillante
		dorada     oro con gemas en el mango
		cristal    vara de vidrio con núcleo brillante y destellos
		abismo     vetas moradas que brillan y estela de humo
		volcanica  roca con grietas de lava y chispas
		leviatan   escamas y aletas, burbujas en la punta
	De la 11 a la 20 reusan esos estilos con colores y materiales nuevos
	(perlas, esmeralda, hielo, kraken, sol, obsidiana, rubí, tormentas,
	cosmos y Poseidón).
]]

export type RodStyle =
	"bambu"
	| "madera"
	| "fibra"
	| "coral"
	| "acero"
	| "dorada"
	| "cristal"
	| "abismo"
	| "volcanica"
	| "leviatan"

export type RodLook = {
	blank: Color3,
	accent: Color3,
	material: Enum.Material,
	glow: boolean,
	style: RodStyle,
}

local rgb = Color3.fromRGB
local M = Enum.Material

local RodLooks: { RodLook } = {
	{
		blank = rgb(206, 182, 112),
		accent = rgb(120, 90, 50),
		material = M.Wood,
		glow = false,
		style = "bambu",
	},
	{
		blank = rgb(124, 80, 46),
		accent = rgb(230, 200, 130),
		material = M.Wood,
		glow = false,
		style = "madera",
	},
	{
		blank = rgb(30, 34, 44),
		accent = rgb(255, 196, 84),
		material = M.SmoothPlastic,
		glow = false,
		style = "fibra",
	},
	{
		blank = rgb(255, 128, 112),
		accent = rgb(255, 236, 220),
		material = M.SmoothPlastic,
		glow = false,
		style = "coral",
	},
	{
		blank = rgb(170, 178, 192),
		accent = rgb(70, 80, 96),
		material = M.Metal,
		glow = false,
		style = "acero",
	},
	{
		blank = rgb(255, 186, 40),
		accent = rgb(255, 250, 220),
		material = M.Foil,
		glow = false,
		style = "dorada",
	},
	{
		blank = rgb(170, 235, 255),
		accent = rgb(255, 255, 255),
		material = M.Glass,
		glow = true,
		style = "cristal",
	},
	{
		blank = rgb(46, 22, 72),
		accent = rgb(190, 100, 255),
		material = M.SmoothPlastic,
		glow = true,
		style = "abismo",
	},
	{
		blank = rgb(52, 34, 30),
		accent = rgb(255, 120, 30),
		material = M.CrackedLava,
		glow = true,
		style = "volcanica",
	},
	{
		blank = rgb(24, 120, 140),
		accent = rgb(120, 255, 220),
		material = M.SmoothPlastic,
		glow = true,
		style = "leviatan",
	},
	{
		blank = rgb(250, 244, 236),
		accent = rgb(255, 190, 220),
		material = M.SmoothPlastic,
		glow = false,
		style = "coral",
	},
	{
		blank = rgb(30, 160, 90),
		accent = rgb(200, 255, 210),
		material = M.Glass,
		glow = true,
		style = "cristal",
	},
	{
		blank = rgb(200, 240, 255),
		accent = rgb(120, 200, 255),
		material = M.Ice,
		glow = true,
		style = "cristal",
	},
	{
		blank = rgb(60, 20, 70),
		accent = rgb(255, 80, 200),
		material = M.SmoothPlastic,
		glow = true,
		style = "leviatan",
	},
	{
		blank = rgb(255, 220, 90),
		accent = rgb(255, 140, 40),
		material = M.Neon,
		glow = true,
		style = "dorada",
	},
	{
		blank = rgb(20, 18, 24),
		accent = rgb(160, 120, 255),
		material = M.Glass,
		glow = true,
		style = "abismo",
	},
	{
		blank = rgb(170, 20, 40),
		accent = rgb(255, 200, 200),
		material = M.Glass,
		glow = true,
		style = "cristal",
	},
	{
		blank = rgb(50, 60, 90),
		accent = rgb(120, 220, 255),
		material = M.Metal,
		glow = true,
		style = "acero",
	},
	{
		blank = rgb(20, 16, 60),
		accent = rgb(255, 255, 255),
		material = M.Neon,
		glow = true,
		style = "abismo",
	},
	{
		blank = rgb(10, 90, 150),
		accent = rgb(255, 220, 90),
		material = M.Foil,
		glow = true,
		style = "leviatan",
	},
}

return RodLooks
