--!strict
--[[
	LoadingParts

	Piezas de la pantalla de carga que arma LoadingView:
		label(nombre, padre, z) -> TextLabel   texto blanco escalable con contorno
		frame(nombre, padre, z, color) -> Frame
		gold(texto, grosor) -> UIGradient      el dorado de los títulos del juego
		maxTextSize(texto, tamaño)
		bar(padre, arriba, alto) -> Bar        hueco de piedra con canto dorado,
		                                        relleno de lava partido en bloques,
		                                        destello y porcentaje
		skipButton(padre) -> TextButton        SALTAR, escondido
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Look = require(ReplicatedStorage.Shared.UIConfig.Loading)

export type Bar = { track: Frame, fill: Frame, shine: Frame, percent: TextLabel }

local COLORS = Look.colors
-- Las mismas fuentes que UIConfig.Fonts (aquí todavía no se puede pedir UIConfig entero).
local TITLE_FONT = Font.fromEnum(Enum.Font.FredokaOne)
local BAR_BLOCKS = 20 -- la barra se ve partida en bloques, como los gigantes

local LoadingParts = {}

LoadingParts.TITLE_FONT = TITLE_FONT
LoadingParts.BODY_FONT = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)

function LoadingParts.label(name: string, parent: GuiObject, zIndex: number): TextLabel
	local text = Instance.new("TextLabel")
	text.Name = name
	text.BackgroundTransparency = 1
	text.FontFace = TITLE_FONT
	text.TextColor3 = COLORS.Text
	text.TextScaled = true
	text.ZIndex = zIndex
	local stroke = Instance.new("UIStroke")
	stroke.Color = COLORS.TextStroke
	stroke.Thickness = 2
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = text
	text.Parent = parent
	return text
end

function LoadingParts.frame(name: string, parent: GuiObject, zIndex: number, color: Color3): Frame
	local item = Instance.new("Frame")
	item.Name = name
	item.BorderSizePixel = 0
	item.BackgroundColor3 = color
	item.ZIndex = zIndex
	item.Parent = parent
	return item
end

function LoadingParts.gold(text: TextLabel, thickness: number): UIGradient
	local gradient = Instance.new("UIGradient")
	gradient.Color = Look.gold
	gradient.Rotation = 90
	gradient.Parent = text
	local stroke = text:FindFirstChildOfClass("UIStroke") :: UIStroke
	stroke.Color = COLORS.FrameDark
	stroke.Thickness = thickness
	return gradient
end

function LoadingParts.maxTextSize(text: TextLabel, size: number)
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = size
	limit.Parent = text
end

local function rounded(target: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = target
end

local function goldEdge(target: GuiObject)
	local edge = Instance.new("UIStroke")
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Color = COLORS.Frame
	edge.Thickness = 3
	edge.Parent = target
end

function LoadingParts.bar(parent: GuiObject, top: number, height: number): Bar
	local frame = LoadingParts.frame
	local track = frame("Barra", parent, 6, COLORS.Track)
	track.AnchorPoint = Vector2.new(0.5, 0)
	track.Position = UDim2.new(0.5, 0, 0, top)
	track.Size = UDim2.new(1, 0, 0, height)
	rounded(track, 6)
	goldEdge(track)

	local fill = frame("Lava", track, 7, Color3.new(1, 1, 1))
	fill.Size = UDim2.fromScale(0, 1)
	fill.ClipsDescendants = true
	rounded(fill, 6)
	local lava = Instance.new("UIGradient")
	lava.Color = Look.lava
	lava.Parent = fill
	-- Brillo de arriba, para que el relleno se vea con volumen.
	local gloss = frame("Brillo", fill, 8, Color3.new(1, 1, 1))
	gloss.BackgroundTransparency = 0.7
	gloss.Size = UDim2.fromScale(1, 0.3)
	-- Destello que cruza el relleno una y otra vez (lo mueve LoadingFx).
	local shine = frame("Destello", fill, 8, Color3.new(1, 1, 1))
	shine.BackgroundTransparency = 0.55
	shine.AnchorPoint = Vector2.new(0.5, 0.5)
	shine.Size = UDim2.new(0, 34, 2, 0)
	shine.Rotation = 20

	-- Ranuras fijas sobre la barra: la parten en bloques (lleno y vacío por igual).
	for index = 1, BAR_BLOCKS - 1 do
		local groove = frame("Ranura", track, 9, COLORS.TrackBlock)
		groove.BackgroundTransparency = 0.35
		groove.Position = UDim2.fromScale(index / BAR_BLOCKS, 0)
		groove.Size = UDim2.new(0, 2, 1, 0)
	end

	local percent = LoadingParts.label("Porcentaje", track, 11)
	percent.Size = UDim2.fromScale(1, 0.8)
	percent.AnchorPoint = Vector2.new(0.5, 0.5)
	percent.Position = UDim2.fromScale(0.5, 0.5)
	percent.Text = "0%"
	return { track = track, fill = fill, shine = shine, percent = percent }
end

function LoadingParts.skipButton(parent: GuiObject): TextButton
	local button = Instance.new("TextButton")
	button.Name = "Saltar"
	button.AnchorPoint = Vector2.new(1, 1)
	button.Position = UDim2.new(1, -24, 1, -24)
	button.Size = UDim2.fromOffset(160, 50)
	button.BackgroundColor3 = COLORS.Track
	button.FontFace = TITLE_FONT
	button.Text = "SALTAR »"
	button.TextScaled = true
	button.TextColor3 = COLORS.Frame
	button.ZIndex = 20
	button.Visible = false
	rounded(button, 8)
	goldEdge(button)
	local textEdge = Instance.new("UIStroke")
	textEdge.Color = COLORS.FrameDark
	textEdge.Thickness = 2
	textEdge.Parent = button
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.Parent = button
	button.Parent = parent
	return button
end

return table.freeze(LoadingParts)
