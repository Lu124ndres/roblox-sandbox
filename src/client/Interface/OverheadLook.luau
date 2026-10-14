--!strict
--[[
	OverheadLook

	Aspecto del cartel sobre la cabeza (Overhead): el degradado de cada
	título según el poder y la calidad con efectos reducidos (sin UIStroke
	y visible de más cerca, UIConfig.Performance).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Performance = require(ReplicatedStorage.Shared.UIConfig.Performance)
local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)

local TITLES = Config.Social.titles
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

function OverheadLook.titleIndex(power: number): number
	local index = 1
	for i, title in TITLES do
		if power >= title.power then
			index = i
		end
	end
	return index
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

return OverheadLook
