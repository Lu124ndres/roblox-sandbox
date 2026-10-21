--!strict
--[[
	RouletteParts

	Las piezas de la ruleta de monstruos (RouletteView las anima): fondo
	oscuro, panel con borde dorado, tira de tarjetas, marco dorado del
	centro con flechas, texto del resultado y pie. card() arma una tarjeta
	(color e ícono del monstruo, nombre y probabilidad).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Layout = require(script.Parent.Parent.Interface.Layout)
local ShopParts = require(script.Parent.Parent.Interface.ShopParts)
local Style = require(script.Parent.Parent.Interface.Style)
local Ui = require(script.Parent.Parent.Ui)
local GiantPortrait = require(script.Parent.GiantPortrait)

local CARDS = Style.PALETTE.Cards
local CELL, GAP, STRIP_WIDTH, STRIP_HEIGHT = 130, 10, 680, 150
local CELLS = 42
local GOLD = Color3.fromRGB(255, 205, 60)
local COLORS: { [string]: Color3 } = {
	Orca = CARDS.Blue,
	Minotauro = CARDS.Red,
	DragonMarino = CARDS.Green,
	ZorroDeAgua = CARDS.Cyan,
	OrcaFantasma = CARDS.Purple,
}

export type Parts = {
	shade: Frame,
	panel: Frame,
	track: Frame,
	result: TextLabel,
	footer: TextLabel,
	pop: UIScale,
}

local RouletteParts = {}

RouletteParts.CELL, RouletteParts.GAP = CELL, GAP
RouletteParts.STRIP_WIDTH, RouletteParts.CELLS = STRIP_WIDTH, CELLS
RouletteParts.GOLD, RouletteParts.COLORS = GOLD, COLORS

function RouletteParts.card(parent: Instance, index: number, def: Config.GiantDef, percent: string)
	local box = Instance.new("Frame")
	box.Position = UDim2.fromOffset((index - 1) * (CELL + GAP), 8)
	box.Size = UDim2.fromOffset(CELL, STRIP_HEIGHT - 16)
	Ui.corner(box, 14)
	Style.border(box, 3)
	ShopParts.sunburst(box, COLORS[def.id] or CARDS.Orange)
	box.Parent = parent
	local image = Instance.new("ImageLabel")
	image.BackgroundTransparency = 1
	image.ScaleType = Enum.ScaleType.Fit
	image.Position = UDim2.fromOffset(12, 6)
	image.Size = UDim2.fromOffset(CELL - 24, STRIP_HEIGHT - 66)
	Icons.paint(image, GiantPortrait.iconFor(def.id))
	image.Parent = box
	local name = Style.text(box, "Nombre", 18, nil, 2)
	name.Text = def.displayName
	name.Position = UDim2.fromOffset(4, STRIP_HEIGHT - 60)
	name.Size = UDim2.fromOffset(CELL - 8, 22)
	local chance = Style.text(box, "Probabilidad", 20, GOLD, 2.5)
	chance.Text = percent
	chance.Position = UDim2.fromOffset(4, STRIP_HEIGHT - 40)
	chance.Size = UDim2.fromOffset(CELL - 8, 22)
	-- Multiplicador del monstruo (monedas por pez y guarida del descanso).
	local multiplier = ShopParts.tag(box, `x{def.multiplier}`, CARDS.Green)
	local tag = multiplier.Parent :: Frame
	tag.Position = UDim2.fromOffset(-6, -4)
	tag.Size = UDim2.fromOffset(46, 26)
end

-- Pantalla propia encima del HUD y de la barra de botones, sin zonas seguras:
-- dentro de Juego el fondo oscuro quedaba cortado arriba y junto al notch.
local function fullScreen(screen: ScreenGui): ScreenGui
	local gui = Ui.screen("RuletaMonstruos", screen.Parent :: Instance, screen.DisplayOrder + 1)
	gui.IgnoreGuiInset = true
	gui.ScreenInsets = Enum.ScreenInsets.None
	gui.ClipToDeviceSafeArea = false
	return gui
end

function RouletteParts.build(screen: ScreenGui): Parts
	local gui = fullScreen(screen)
	local shade = Instance.new("Frame")
	shade.Name = "FondoRuleta"
	shade.BackgroundColor3 = Color3.new(0, 0, 0)
	shade.BackgroundTransparency = 0.45
	shade.BorderSizePixel = 0
	shade.Size = UDim2.fromScale(1, 1)
	shade.Visible = false
	shade.Parent = gui
	local panel = Ui.panel("Ruleta", gui)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromOffset(STRIP_WIDTH + 40, 330)
	panel.Visible = false
	panel.ZIndex = 2
	Ui.corner(panel, 22)
	Style.gradient(panel, Color3.fromRGB(40, 30, 70))
	Style.border(panel, 6)
	local stroke = panel:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = GOLD
	end
	Layout.scaleWith(panel)
	local title = Style.text(panel, "Titulo", 46, GOLD, 4)
	title.Text = "¡RULETA DE MONSTRUOS!"
	title.Position = UDim2.fromOffset(0, 8)
	title.Size = UDim2.new(1, 0, 0, 50)
	local strip = Instance.new("Frame")
	strip.Name = "Tira"
	strip.BackgroundColor3 = Color3.fromRGB(18, 16, 30)
	strip.ClipsDescendants = true
	strip.Position = UDim2.fromOffset(20, 66)
	strip.Size = UDim2.fromOffset(STRIP_WIDTH, STRIP_HEIGHT)
	Ui.corner(strip, 14)
	strip.Parent = panel
	local track = Instance.new("Frame")
	track.BackgroundTransparency = 1
	track.Size = UDim2.fromOffset((CELL + GAP) * CELLS, STRIP_HEIGHT)
	track.Parent = strip
	local frameBox = Instance.new("Frame") -- marco dorado del centro
	frameBox.BackgroundTransparency = 1
	frameBox.AnchorPoint = Vector2.new(0.5, 0.5)
	frameBox.Position = UDim2.new(0.5, 0, 0, 66 + STRIP_HEIGHT / 2)
	frameBox.Size = UDim2.fromOffset(CELL + 12, STRIP_HEIGHT + 6)
	frameBox.ZIndex = 5
	Ui.corner(frameBox, 16)
	Ui.stroke(frameBox, GOLD, 6, 0)
	frameBox.Parent = panel
	for _, arrowY in { 50, 66 + STRIP_HEIGHT - 4 } do
		local arrow = Style.text(panel, "Flecha", 34, GOLD, 3)
		arrow.Text = if arrowY == 50 then "▼" else "▲"
		arrow.AnchorPoint = Vector2.new(0.5, 0)
		arrow.Position = UDim2.new(0.5, 0, 0, arrowY)
		arrow.Size = UDim2.fromOffset(40, 30)
		arrow.ZIndex = 6
	end
	local result = Style.text(panel, "Resultado", 40, nil, 4)
	result.Position = UDim2.fromOffset(10, 230)
	result.Size = UDim2.new(1, -20, 0, 46)
	local footer = Style.text(panel, "Pie", 20, UIConfig.Colors.TextMuted, 2)
	footer.Position = UDim2.fromOffset(10, 280)
	footer.Size = UDim2.new(1, -20, 0, 26)
	local pop = Instance.new("UIScale")
	pop.Parent = result

	return {
		shade = shade,
		panel = panel,
		track = track,
		result = result,
		footer = footer,
		pop = pop,
	}
end

return RouletteParts
