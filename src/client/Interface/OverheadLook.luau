--!strict
--[[
	OverheadLook

	Aspecto del cartel sobre la cabeza (Overhead): el degradado de cada
	título según el poder y la calidad con efectos reducidos (sin UIStroke
	y visible de más cerca, UIConfig.Performance).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Performance = require(ReplicatedStorage.Shared.UIConfig.Performance)
local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)

local rgb = Color3.fromRGB

-- Degradado del texto de cada título (mismo orden que Config.Social.titles).
local TITLE_COLORS: { { Color3 } } = {
	{ rgb(200, 200, 200), rgb(150, 150, 150) }, -- Novato
	{ rgb(255, 255, 255), rgb(200, 220, 235) }, -- Aprendiz
	{ rgb(140, 255, 120), rgb(40, 190, 70) }, -- Pescador
	{ rgb(120, 245, 255), rgb(20, 170, 220) }, -- Marinero
	{ rgb(120, 170, 255), rgb(40, 80, 230) }, -- Capitán
	{ rgb(220, 140, 255), rgb(140, 50, 230) }, -- Almirante
	{ rgb(255, 200, 90), rgb(255, 110, 20) }, -- Domador de Bestias
	{ rgb(255, 90, 120), rgb(150, 20, 90) }, -- Señor del Abismo
	{ rgb(255, 240, 140), rgb(255, 170, 0) }, -- Rey de los Océanos
	{
		rgb(255, 80, 80),
		rgb(255, 220, 60),
		rgb(80, 255, 120),
		rgb(80, 160, 255),
		rgb(200, 90, 255),
	}, -- Dios del Mar
	-- Desde aquí, tres colores o más: el brillo recorre el texto (Overhead).
	{ rgb(120, 255, 240), rgb(20, 140, 255), rgb(120, 255, 240) }, -- Titán de las Mareas
	{ rgb(230, 240, 255), rgb(120, 140, 255), rgb(255, 255, 120) }, -- Señor de las Tormentas
	{ rgb(90, 255, 160), rgb(0, 120, 90), rgb(255, 240, 120) }, -- Devorador de Leviatanes
	{ rgb(255, 90, 200), rgb(110, 20, 160), rgb(255, 215, 90) }, -- Emperador del Abismo
	{ rgb(60, 220, 255), rgb(255, 255, 255), rgb(0, 110, 255), rgb(255, 255, 255) }, -- Guardián de los Siete Mares
	{ rgb(255, 150, 60), rgb(255, 60, 30), rgb(255, 220, 90), rgb(255, 60, 30) }, -- Coloso Abisal
	{ rgb(0, 255, 255), rgb(0, 80, 255), rgb(140, 0, 255), rgb(0, 255, 255) }, -- Dios de los Maremotos
	{ rgb(255, 255, 255), rgb(255, 210, 60), rgb(255, 255, 255), rgb(255, 160, 0) }, -- Soberano Eterno
	{ rgb(0, 255, 200), rgb(0, 140, 255), rgb(255, 255, 255), rgb(0, 255, 200) }, -- Avatar del Océano
	{ rgb(255, 60, 60), rgb(255, 200, 0), rgb(255, 255, 255), rgb(255, 60, 60) }, -- Leyenda Inmortal
	{ rgb(190, 90, 255), rgb(255, 40, 120), rgb(255, 170, 0), rgb(190, 90, 255) }, -- Destructor de Mundos
	{
		rgb(255, 255, 255),
		rgb(120, 255, 255),
		rgb(255, 120, 255),
		rgb(255, 255, 120),
		rgb(255, 255, 255),
	}, -- Dios Primordial
	{
		rgb(255, 0, 0),
		rgb(255, 160, 0),
		rgb(255, 255, 0),
		rgb(0, 255, 0),
		rgb(0, 160, 255),
		rgb(170, 0, 255),
	}, -- Omnipotente
	{
		rgb(255, 255, 255),
		rgb(160, 170, 200),
		rgb(255, 255, 255),
		rgb(160, 170, 200),
		rgb(255, 255, 255),
	}, -- El Infinito
	{
		rgb(255, 255, 255),
		rgb(255, 0, 200),
		rgb(0, 255, 255),
		rgb(255, 255, 0),
		rgb(255, 255, 255),
	}, -- Más Allá del Infinito
}

local OverheadLook = {}

-- Efectos reducidos: sin UIStroke (el borde simple del texto es más barato) y de más cerca.
function OverheadLook.applyQuality(gui: BillboardGui)
	local low = ClientSettings.get("lowFx")
	gui.MaxDistance = if low
		then Performance.OverheadLowFxDistance
		else Performance.OverheadDistance
	for _, descendant in gui:GetDescendants() do
		if descendant:IsA("UIStroke") then
			descendant.Enabled = not low
			local label = descendant.Parent
			if label and label:IsA("TextLabel") then
				label.TextStrokeTransparency = if low then 0.4 else 1
			end
		end
	end
end

local function sequence(colors: { Color3 }): ColorSequence
	local points = {}
	for i, color in colors do
		table.insert(points, ColorSequenceKeypoint.new((i - 1) / math.max(1, #colors - 1), color))
	end
	return ColorSequence.new(points)
end

-- Degradado del título y su giro (los de muchos colores van de lado a lado).
function OverheadLook.gradient(index: number): (ColorSequence, number)
	local colors = TITLE_COLORS[index] or TITLE_COLORS[1]
	return sequence(colors), if #colors > 2 then 0 else 90
end

-- ¿El brillo recorre el texto? (los de tres colores o más: Dios del Mar y siguientes)
function OverheadLook.animated(index: number): boolean
	local colors = TITLE_COLORS[index] or TITLE_COLORS[1]
	return #colors > 2
end

-- Color principal de un título (para el aviso de título nuevo).
function OverheadLook.mainColor(index: number): Color3
	local colors = TITLE_COLORS[index] or TITLE_COLORS[1]
	return colors[1]
end

return OverheadLook
