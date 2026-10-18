--!strict
--[[
	HungerPanel

	Las piezas del panel de hambre (arriba al centro), sin lógica, compactas,
	sobre una placa de piedra con una gema a cada lado (decorado en HungerLook):
		<>[retrato]  Nombre ................ Etapa 1/4  <>
		<>[retrato]  [ barra con la comida grande ]    <>
		<>[retrato]  Calmada   [enojo]                 <>
		             +25%  +50%  +75%   (cuelgan del borde de abajo)
	El nombre y la etapa van en dorado y la barra en un hueco de la piedra.
	El retrato del monstruo (GiantPortrait, su ícono) va a la izquierda; la fila del
	enojo (AngerMeter, y = ANGER_TOP) y los atajos para llenarlo (FillChips,
	y = CHIPS_TOP, que fija el alto del panel) usan las medidas de aquí.
	HungerBar llena las piezas con el estado del gigante.

	Si cabe, el panel sube a la barra de Roblox (entre sus botones y los
	nuestros, que van en la esquina derecha); si no (teléfonos), va justo
	debajo de ella.
	Ancho: hasta 400, pero nunca tanto como para pisar las columnas del HUD (ni
	con lo que sobresalen la placa y las gemas, HungerLook.OVERHANG).
]]

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Ui = require(script.Parent.Parent.Ui)
local Device = require(script.Parent.Device)
local Layout = require(script.Parent.Layout)
local HungerLook = require(script.Parent.HungerLook)
local Kit = require(script.Parent.Kit)
local Style = require(script.Parent.Style)

local MAX_WIDTH = 400
local MIN_WIDTH = UIConfig.Spacing.HungerWidthMin
local SIDE_GAP = 24 -- aire entre el panel y cada columna
local TOPBAR_GAP = 12 -- aire entre los botones de la barra de Roblox y el panel
local OVERHANG = HungerLook.OVERHANG

export type Parts = {
	panel: Frame,
	portrait: ImageLabel,
	title: TextLabel,
	detail: TextLabel,
	amount: TextLabel,
	fill: Frame,
	ring: UIStroke, -- aro de la medalla del retrato (color de la etapa)
}

local HungerPanel = {}

HungerPanel.PORTRAIT = 62 -- lado del retrato
HungerPanel.LEFT = HungerPanel.PORTRAIT + 6 -- donde empiezan el nombre y la barra
HungerPanel.ANGER_TOP = 55
HungerPanel.CHIPS_TOP = 80
HungerPanel.OVERHANG = OVERHANG -- lo que sobresalen la placa y las gemas por cada lado
local PLATE_BOTTOM = HungerPanel.CHIPS_TOP + 10 -- los atajos de llenar cuelgan del borde

-- Ancho (antes de escalar) que cabe entre las dos columnas.
function HungerPanel.width(): number
	local scale = Layout.scale()
	local free = Device.viewport().X / scale - 2 * (Layout.statWidth() + SIDE_GAP + OVERHANG)
	return math.clamp(math.floor(free), MIN_WIDTH, MAX_WIDTH)
end

-- Sube el panel a la barra de Roblox si cabe entre sus botones (izquierda) y los
-- nuestros (esquina derecha).
local function place(panel: Frame)
	local inset = GuiService.TopbarInset
	local bar = Layout.topBar()
	local list = bar:FindFirstChildOfClass("UIListLayout")
	local barLeft = bar.AbsolutePosition.X
		+ bar.AbsoluteSize.X
		- (if list then list.AbsoluteContentSize.X else 0)
	local scale = Layout.scale()
	local width = panel.Size.X.Offset * scale
	local left = (Device.viewport().X - width) / 2
	local gap = TOPBAR_GAP + OVERHANG * scale
	local fits = inset.Height > 0 and left > inset.Min.X + gap and left + width < barLeft - gap
	panel.Position = UDim2.new(0.5, 0, 0, if fits then -inset.Height + 8 else 10)
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

	HungerLook.plate(panel, PLATE_BOTTOM)
	local ring = HungerLook.medal(panel, HungerPanel.PORTRAIT)
	-- Ícono del monstruo, un poco más grande que su medalla para que resalte.
	local portrait = Instance.new("ImageLabel")
	portrait.Name = "Retrato"
	portrait.BackgroundTransparency = 1
	portrait.ScaleType = Enum.ScaleType.Fit
	portrait.AnchorPoint = Vector2.new(0.5, 0.5)
	portrait.Position = UDim2.fromOffset(HungerPanel.PORTRAIT / 2, HungerPanel.PORTRAIT / 2)
	portrait.Size = UDim2.fromOffset(HungerPanel.PORTRAIT + 10, HungerPanel.PORTRAIT + 10)
	portrait.ZIndex = 3
	portrait.Parent = panel

	local left = HungerPanel.LEFT
	local title = Style.text(panel, "Nombre", 22)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Position = UDim2.fromOffset(left + 4, 0)
	title.Size = UDim2.new(0.62, -left, 0, 22)
	Kit.gold(title)

	local detail = Style.text(panel, "Etapa", 18)
	detail.TextXAlignment = Enum.TextXAlignment.Right
	detail.AnchorPoint = Vector2.new(1, 0)
	detail.Position = UDim2.new(1, -4, 0, 2)
	detail.Size = UDim2.new(0.38, 0, 0, 18)
	Kit.gold(detail)

	local track = Instance.new("Frame")
	track.Name = "Pista"
	track.Position = UDim2.fromOffset(left, 22)
	track.Size = UDim2.new(1, -left, 0, 30)
	track.Parent = panel
	local clip = HungerLook.hollow(track)

	local fill = Instance.new("Frame")
	fill.Name = "Relleno"
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = UIConfig.HungerStageColors[1]
	Ui.corner(fill, 6)
	Style.gradient(fill, Color3.new(1, 1, 1))
	HungerLook.shine(fill)
	fill.Parent = clip
	HungerLook.meat(track)

	local amount = Style.text(track, "Cantidad", 26, nil, 2.5)
	amount.AnchorPoint = Vector2.new(0.5, 0.5)
	amount.Position = UDim2.new(0.5, 12, 0.5, 0) -- deja lugar a la carne
	amount.Size = UDim2.new(1, -36, 1, -4)
	amount.ZIndex = 4

	return {
		panel = panel,
		portrait = portrait,
		title = title,
		detail = detail,
		amount = amount,
		fill = fill,
		ring = ring,
	}
end

return HungerPanel
