--!strict
--[[
	HungerPanel

	Las piezas del panel de hambre (arriba al centro), sin lógica, compactas:
		[retrato]  Nombre ................ Etapa 1/4
		[retrato]  [ barra con la comida grande ]
		[retrato]  Calmada   [enojo]
		           +25%  +50%  +75%
	El retrato del monstruo (GiantPortrait) va a la izquierda; la fila del
	enojo (AngerMeter, y = ANGER_TOP) y los atajos para llenarlo (FillChips,
	y = CHIPS_TOP, que fija el alto del panel) usan las medidas de aquí.
	HungerBar llena las piezas con el estado del gigante.

	Si cabe, el panel sube a la barra de Roblox (entre sus botones y el borde
	derecho); si no (teléfonos), va justo debajo de ella.
	Ancho: hasta 400, pero nunca tanto como para pisar las columnas del HUD.
]]

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Ui = require(script.Parent.Parent.Ui)
local Device = require(script.Parent.Device)
local Layout = require(script.Parent.Layout)
local Style = require(script.Parent.Style)

local THRESHOLDS = Config.Giants.stageThresholds
local MAX_WIDTH = 400
local MIN_WIDTH = UIConfig.Spacing.HungerWidthMin
local SIDE_GAP = 24 -- aire entre el panel y cada columna
local TOPBAR_GAP = 12 -- aire entre los botones de la barra de Roblox y el panel

export type Parts = {
	panel: Frame,
	portrait: ViewportFrame,
	title: TextLabel,
	detail: TextLabel,
	amount: TextLabel,
	fill: Frame,
}

local HungerPanel = {}

HungerPanel.PORTRAIT = 62 -- lado del retrato
HungerPanel.LEFT = HungerPanel.PORTRAIT + 6 -- donde empiezan el nombre y la barra
HungerPanel.ANGER_TOP = 55
HungerPanel.CHIPS_TOP = 80

-- Ancho (antes de escalar) que cabe entre las dos columnas.
function HungerPanel.width(): number
	local scale = Layout.scale()
	local free = Device.viewport().X / scale - 2 * (Layout.statWidth() + SIDE_GAP)
	return math.clamp(math.floor(free), MIN_WIDTH, MAX_WIDTH)
end

-- Sube el panel a la barra de Roblox si no pisa los botones que hay en ella.
local function place(panel: Frame)
	local inset = GuiService.TopbarInset
	local bar = Layout.topBar()
	local list = bar:FindFirstChildOfClass("UIListLayout")
	local barRight = bar.AbsolutePosition.X + (if list then list.AbsoluteContentSize.X else 0)
	local left = (Device.viewport().X - panel.Size.X.Offset * Layout.scale()) / 2
	local fits = inset.Height > 0 and left > barRight + TOPBAR_GAP
	panel.Position = UDim2.new(0.5, 0, 0, if fits then -inset.Height + 4 else 6)
end

function HungerPanel.build(screen: ScreenGui): Parts
	local panel = Instance.new("Frame")
	panel.Name = "Hambre"
	panel.BackgroundTransparency = 1
	panel.AnchorPoint = Vector2.new(0.5, 0)
	panel.Size = UDim2.fromOffset(HungerPanel.width(), HungerPanel.CHIPS_TOP + 40)
	panel.Parent = screen
	Layout.scaleWith(panel)
	local function relayout()
		panel.Size = UDim2.fromOffset(HungerPanel.width(), panel.Size.Y.Offset)
		place(panel)
	end
	Layout.onScaleChanged(relayout) -- solo el ancho: el alto lo decide FillChips
	GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(relayout)
	local barList = Layout.topBar():FindFirstChildOfClass("UIListLayout")
	if barList then
		barList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(relayout)
	end
	relayout()

	local frame = Instance.new("Frame")
	frame.Name = "Retrato"
	frame.BackgroundColor3 = Color3.fromRGB(34, 36, 46)
	frame.Size = UDim2.fromOffset(HungerPanel.PORTRAIT, HungerPanel.PORTRAIT)
	Ui.corner(frame, 14)
	Style.border(frame, 3)
	Style.gradient(frame, Color3.fromRGB(90, 150, 210))
	frame.Parent = panel
	local portrait = Instance.new("ViewportFrame")
	portrait.Name = "Modelo"
	portrait.BackgroundTransparency = 1
	portrait.Size = UDim2.fromScale(1, 1)
	portrait.Ambient = Color3.fromRGB(205, 205, 215)
	portrait.LightColor = Color3.new(1, 1, 1)
	portrait.LightDirection = Vector3.new(-0.5, -1, 0.6)
	Ui.corner(portrait, 14)
	portrait.Parent = frame

	local left = HungerPanel.LEFT
	local title = Style.text(panel, "Nombre", 22)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Position = UDim2.fromOffset(left + 2, 0)
	title.Size = UDim2.new(0.62, -left, 0, 22)

	local detail = Style.text(panel, "Etapa", 18, Color3.fromRGB(255, 220, 70))
	detail.TextXAlignment = Enum.TextXAlignment.Right
	detail.AnchorPoint = Vector2.new(1, 0)
	detail.Position = UDim2.new(1, -4, 0, 2)
	detail.Size = UDim2.new(0.38, 0, 0, 18)

	local track = Instance.new("Frame")
	track.Name = "Pista"
	track.BackgroundColor3 = Color3.fromRGB(34, 36, 46)
	track.Position = UDim2.fromOffset(left, 22)
	track.Size = UDim2.new(1, -left, 0, 30)
	Ui.corner(track, 10)
	Style.border(track, 3)
	track.Parent = panel
	local clip = Instance.new("Frame")
	clip.Name = "Recorte"
	clip.BackgroundTransparency = 1
	clip.Size = UDim2.fromScale(1, 1)
	clip.ClipsDescendants = true
	clip.Parent = track
	Ui.corner(clip, 10)

	local fill = Instance.new("Frame")
	fill.Name = "Relleno"
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = UIConfig.HungerStageColors[1]
	Ui.corner(fill, 10)
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

	local amount = Style.text(track, "Cantidad", 26, nil, 2.5)
	amount.AnchorPoint = Vector2.new(0.5, 0.5)
	amount.Position = UDim2.fromScale(0.5, 0.5)
	amount.Size = UDim2.new(1, -12, 1, -4)
	amount.ZIndex = 4

	return {
		panel = panel,
		portrait = portrait,
		title = title,
		detail = detail,
		amount = amount,
		fill = fill,
	}
end

return HungerPanel
