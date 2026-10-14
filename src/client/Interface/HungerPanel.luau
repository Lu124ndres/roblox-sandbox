--!strict
--[[
	HungerPanel

	Las piezas del panel de hambre (arriba al centro), sin lógica: el nombre a
	la izquierda, la etapa a la derecha, la barra con sus marcas de etapa y la
	cantidad grande encima. HungerBar las llena con el estado del gigante.
	Debajo quedan huecos para la fila del enojo (AngerMeter, y = 78) y los
	atajos para llenarlo (FillChips, y = 114, que fija el alto del panel).

	Ancho: hasta 440, pero nunca tanto como para pisar las columnas del HUD.
	El panel va centrado, así que se deja libre el ancho de la columna
	izquierda (la más ancha) más un margen a cada lado.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Ui = require(script.Parent.Parent.Ui)
local Device = require(script.Parent.Device)
local Layout = require(script.Parent.Layout)
local Style = require(script.Parent.Style)

local THRESHOLDS = Config.Giants.stageThresholds
local MAX_WIDTH = 440
local MIN_WIDTH = UIConfig.Spacing.HungerWidthMin
local SIDE_GAP = 24 -- aire entre el panel y cada columna
local START_HEIGHT = 150 -- FillChips lo ajusta a lo que miden sus botones

export type Parts = {
	panel: Frame,
	title: TextLabel,
	detail: TextLabel,
	amount: TextLabel,
	fill: Frame,
}

local HungerPanel = {}

-- Ancho (antes de escalar) que cabe entre las dos columnas.
function HungerPanel.width(): number
	local scale = Layout.scale()
	local free = Device.viewport().X / scale - 2 * (Layout.statWidth() + SIDE_GAP)
	return math.clamp(math.floor(free), MIN_WIDTH, MAX_WIDTH)
end

function HungerPanel.build(screen: ScreenGui): Parts
	local panel = Instance.new("Frame")
	panel.Name = "Hambre"
	panel.BackgroundTransparency = 1
	panel.AnchorPoint = Vector2.new(0.5, 0)
	panel.Position = UDim2.new(0.5, 0, 0, 8)
	panel.Size = UDim2.fromOffset(HungerPanel.width(), START_HEIGHT)
	panel.Parent = screen
	Layout.scaleWith(panel)
	-- Solo el ancho: el alto lo decide FillChips.
	Layout.onScaleChanged(function()
		panel.Size = UDim2.fromOffset(HungerPanel.width(), panel.Size.Y.Offset)
	end)

	local title = Style.text(panel, "Nombre", 28)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Size = UDim2.new(0.62, 0, 0, 30)

	local detail = Style.text(panel, "Etapa", 22, Color3.fromRGB(255, 220, 70))
	detail.TextXAlignment = Enum.TextXAlignment.Right
	detail.AnchorPoint = Vector2.new(1, 0)
	detail.Position = UDim2.new(1, -4, 0, 4)
	detail.Size = UDim2.new(0.38, 0, 0, 24)
	detail.Rotation = 4

	local track = Instance.new("Frame")
	track.Name = "Pista"
	track.BackgroundColor3 = Color3.fromRGB(34, 36, 46)
	track.Position = UDim2.fromOffset(0, 32)
	track.Size = UDim2.new(1, 0, 0, 42)
	Ui.corner(track, 12)
	Style.border(track, 4)
	track.Parent = panel
	local clip = Instance.new("Frame")
	clip.Name = "Recorte"
	clip.BackgroundTransparency = 1
	clip.Size = UDim2.fromScale(1, 1)
	clip.ClipsDescendants = true
	clip.Parent = track
	Ui.corner(clip, 12)

	local fill = Instance.new("Frame")
	fill.Name = "Relleno"
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = UIConfig.HungerStageColors[1]
	Ui.corner(fill, 12)
	Style.gradient(fill, Color3.new(1, 1, 1))
	fill.Parent = clip

	for index = 2, #THRESHOLDS do
		local tick = Instance.new("Frame")
		tick.Name = `Marca{index}`
		tick.BackgroundColor3 = Style.OUTLINE
		tick.BackgroundTransparency = 0.3
		tick.BorderSizePixel = 0
		tick.AnchorPoint = Vector2.new(0.5, 0)
		tick.Position = UDim2.fromScale(THRESHOLDS[index], 0)
		tick.Size = UDim2.new(0, 3, 1, 0)
		tick.ZIndex = 2
		tick.Parent = clip
	end

	local amount = Style.text(track, "Cantidad", 34, nil, 3)
	amount.AnchorPoint = Vector2.new(0.5, 0.5)
	amount.Position = UDim2.fromScale(0.5, 0.5)
	amount.Size = UDim2.new(1, -16, 1, -4)
	amount.ZIndex = 4

	return { panel = panel, title = title, detail = detail, amount = amount, fill = fill }
end

return HungerPanel
