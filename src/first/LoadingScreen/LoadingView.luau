--!strict
--[[
	LoadingView

	Arma la pantalla de carga (sin animarla: eso es LoadingFx). De atrás hacia
	adelante: el fondo de la isla con los gigantes de bloques, un oscurecido arriba
	y abajo para leer los textos, la capa de las chispas, el título dorado y, abajo
	al centro, el pez que nada sobre la punta de la barra, la barra de lava
	(LoadingParts.bar) con el porcentaje, el estado y el consejo. El botón SALTAR
	empieza escondido.
		build(playerGui) -> View
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LoadingArt = require(ReplicatedStorage.Shared.Assets.Loading)
local Look = require(ReplicatedStorage.Shared.UIConfig.Loading)
local BlockFish = require(script.Parent.BlockFish)
local LoadingParts = require(script.Parent.LoadingParts)

export type View = {
	gui: ScreenGui,
	root: CanvasGroup,
	background: ImageLabel,
	embers: Frame,
	title: TextLabel,
	titleGradient: UIGradient,
	fill: Frame,
	shine: Frame,
	percent: TextLabel,
	fish: Frame,
	status: TextLabel,
	tip: TextLabel,
	skip: TextButton,
}

local COLORS = Look.colors
local BAR_TOP = 30 -- arriba de la barra nada el pez
local BAR_HEIGHT = 40
local FISH_CELL = 4

local label = LoadingParts.label
local frame = LoadingParts.frame

-- Oscurece arriba (el título) y abajo (la barra) y deja ver el centro de la isla.
local function shade(root: GuiObject)
	local layer = frame("Sombra", root, 2, COLORS.Shade)
	layer.Size = UDim2.fromScale(1, 1)
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(0.3, 1),
		NumberSequenceKeypoint.new(0.55, 1),
		NumberSequenceKeypoint.new(1, 0.1),
	})
	gradient.Parent = layer
end

local function titles(root: GuiObject): (TextLabel, UIGradient)
	local title = label("Titulo", root, 5)
	title.AnchorPoint = Vector2.new(0.5, 0)
	title.Position = UDim2.fromScale(0.5, 0.05)
	title.Size = UDim2.fromScale(0.9, 0.13)
	title.Text = Look.title
	LoadingParts.maxTextSize(title, 96)
	local gradient = LoadingParts.gold(title, 4)
	local subtitle = label("Subtitulo", title, 5)
	subtitle.AnchorPoint = Vector2.new(0.5, 0)
	subtitle.Position = UDim2.fromScale(0.5, 1)
	subtitle.Size = UDim2.fromScale(0.6, 0.38)
	subtitle.Text = Look.subtitle
	subtitle.TextColor3 = COLORS.TextMuted
	LoadingParts.maxTextSize(subtitle, 32)
	return title, gradient
end

local LoadingView = {}

function LoadingView.build(playerGui: PlayerGui): View
	local gui = Instance.new("ScreenGui")
	gui.Name = "PantallaCarga"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 1000 -- encima de todo el HUD del juego
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local root = Instance.new("CanvasGroup")
	root.Name = "Raiz"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundColor3 = COLORS.Backdrop
	root.BorderSizePixel = 0
	root.Parent = gui

	local background = Instance.new("ImageLabel")
	background.Name = "Fondo"
	background.BackgroundTransparency = 1
	background.Image = LoadingArt.Background
	background.ImageTransparency = 1 -- aparece cuando llega; tamaño y encuadre: LoadingBackdrop
	background.ZIndex = 1
	background.Parent = root

	shade(root)
	local embers = frame("Chispas", root, 3, Color3.new())
	embers.BackgroundTransparency = 1
	embers.Size = UDim2.fromScale(1, 1)
	local title, titleGradient = titles(root)

	local panel = frame("Panel", root, 6, Color3.new())
	panel.BackgroundTransparency = 1
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.Position = UDim2.new(0.5, 0, 1, -36)
	panel.Size = UDim2.new(0.56, 0, 0, BAR_TOP + BAR_HEIGHT + 62)
	local width = Instance.new("UISizeConstraint")
	width.MinSize = Vector2.new(300, 0)
	width.MaxSize = Vector2.new(780, math.huge)
	width.Parent = panel

	local bar = LoadingParts.bar(panel, BAR_TOP, BAR_HEIGHT)
	local fish = BlockFish.build(bar.track, FISH_CELL, COLORS)
	fish.Position = UDim2.fromOffset(0, -4)
	local status = label("Estado", panel, 6)
	status.Position = UDim2.fromOffset(0, BAR_TOP + BAR_HEIGHT + 10)
	status.Size = UDim2.new(1, 0, 0, 26)
	LoadingParts.gold(status, 2)
	local tip = label("Consejo", panel, 6)
	tip.Position = UDim2.fromOffset(0, BAR_TOP + BAR_HEIGHT + 38)
	tip.Size = UDim2.new(1, 0, 0, 22)
	tip.TextColor3 = COLORS.TextMuted
	tip.FontFace = LoadingParts.BODY_FONT

	local skip = LoadingParts.skipButton(root)

	gui.Parent = playerGui
	return {
		gui = gui,
		root = root,
		background = background,
		embers = embers,
		title = title,
		titleGradient = titleGradient,
		fill = bar.fill,
		shine = bar.shine,
		percent = bar.percent,
		fish = fish,
		status = status,
		tip = tip,
		skip = skip,
	}
end

return table.freeze(LoadingView)
