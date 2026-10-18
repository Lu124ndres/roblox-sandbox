--!strict
--[[
	PondSignView

	El cartel flotante de un estanque de entrenamiento (un BillboardGui medido en
	studs), sin placa de fondo para que se vea el jardín detrás:
		nombre          "Estanque de Bambú", blanco con un toque del color del estanque
		multiplicador   el ícono de poder y "x3" enorme, del color del estanque
		                (degradado claro → color) con contorno marrón oscuro
		cápsula         cerrado: calavera y "4/15" (monstruos llenados: solo se abre así);
		                el sagrado: Robux "Pase sagrado"; abierto: "¡Abierto! Entrenar"
		                en verde
	Los contornos y el borde de la cápsula siguen al alto del cartel en pantalla
	(se mide en studs, así que sus píxeles cambian con la distancia).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage.Shared.Assets)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Kit = require(script.Parent.Parent.Interface.Kit)

export type State = "open" | "locked" | "robux"
export type View = {
	set: (state: State, kills: string) -> (),
	show: (visible: boolean) -> (),
}

local SIZE = Vector2.new(15, 7.5) -- studs
local SACRED_SCALE = 1.25
local WHITE = Color3.new(1, 1, 1)
local PILL = Color3.fromRGB(26, 20, 30)
local OPEN = Color3.fromRGB(60, 168, 84)
-- Grosor de cada contorno como fracción del alto del cartel en pantalla.
local STROKE_SHARE = { name = 0.02, big = 0.032, small = 0.014, pill = 0.012 }

local PondSignView = {}

type Strokes = { [UIStroke]: number }

local function label(
	parent: Instance,
	name: string,
	color: Color3,
	kind: string,
	strokes: Strokes
): TextLabel
	local text = Instance.new("TextLabel")
	text.Name = name
	text.BackgroundTransparency = 1
	text.FontFace = UIConfig.Fonts.Title
	text.TextScaled = true
	text.TextColor3 = color
	local stroke = Instance.new("UIStroke")
	stroke.Color = Kit.GOLD_OUTLINE
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = text
	strokes[stroke] = STROKE_SHARE[kind]
	text.Parent = parent
	return text
end

-- Ícono cuadrado dentro de una fila (alto relativo a la fila).
local function icon(parent: Instance, kind: string, order: number): GuiObject
	local view = Icons.view(parent, kind)
	view.LayoutOrder = order
	view.Size = UDim2.fromScale(0.14, 0.9)
	local square = Instance.new("UIAspectRatioConstraint")
	square.DominantAxis = Enum.DominantAxis.Height
	square.Parent = view
	return view
end

local function pill(root: Frame, color: Color3, strokes: Strokes): (Frame, UIStroke)
	local frame = Instance.new("Frame")
	frame.Name = "Capsula"
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = UDim2.fromScale(0.5, 0.72)
	frame.Size = UDim2.fromScale(0.9, 0.25)
	frame.BackgroundColor3 = PILL
	frame.BackgroundTransparency = 0.18
	frame.Parent = root
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = frame
	strokes[stroke] = STROKE_SHARE.pill
	local row = Instance.new("UIListLayout")
	row.FillDirection = Enum.FillDirection.Horizontal
	row.HorizontalAlignment = Enum.HorizontalAlignment.Center
	row.VerticalAlignment = Enum.VerticalAlignment.Center
	row.SortOrder = Enum.SortOrder.LayoutOrder
	row.Padding = UDim.new(0.015, 0)
	row.Parent = frame
	return frame, stroke
end

-- `multiplier` es el texto grande ("x3"); el cartel arranca cerrado hasta el primer `set`.
function PondSignView.build(
	anchor: Attachment,
	index: number,
	sacred: boolean,
	multiplier: string
): View
	local strokes: Strokes = {}
	local base = UIConfig.PondColors[index] or UIConfig.Colors.Text
	local h, s = base:ToHSV()
	local color = Color3.fromHSV(h, math.max(s, 0.65), 1) -- vivo, como los simuladores
	local scale = if sacred then SACRED_SCALE else 1
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromScale(SIZE.X * scale, SIZE.Y * scale)
	billboard.MaxDistance = 110
	billboard.LightInfluence = 0
	billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	billboard.Adornee = anchor
	billboard.Parent = anchor
	local root = Instance.new("Frame")
	root.Name = "Cartel"
	root.BackgroundTransparency = 1
	root.Size = UDim2.fromScale(1, 1)
	root.Parent = billboard

	local name = label(root, "Nombre", WHITE:Lerp(color, 0.25), "name", strokes)
	name.Size = UDim2.fromScale(1, 0.2)
	name.Text = UIConfig.PondNames[index] or `Estanque {index}`
	local big = label(root, "Multiplicador", WHITE, "big", strokes)
	big.Position = UDim2.fromScale(0, 0.18)
	big.Size = UDim2.fromScale(1, 0.52)
	big.Text = multiplier
	local fill = Instance.new("UIGradient")
	fill.Rotation = 90
	fill.Color = ColorSequence.new(color:Lerp(WHITE, 0.55), color)
	fill.Parent = big
	local power = Icons.view(root, "crystal")
	power.AnchorPoint = Vector2.new(1, 0.5)

	local capsule, border = pill(root, color, strokes)
	local skull = icon(capsule, "skull", 1)
	local kills = label(capsule, "Kills", WHITE, "small", strokes)
	kills.LayoutOrder, kills.Size = 2, UDim2.fromScale(0.4, 0.72)
	local robux = Instance.new("ImageLabel")
	robux.Name = "Robux"
	robux.BackgroundTransparency = 1
	robux.Image = Assets.UI.RobuxIcon
	robux.ImageColor3 = Color3.fromRGB(140, 255, 160) -- el ícono viene gris
	robux.LayoutOrder, robux.Size = 6, UDim2.fromScale(0.12, 0.7)
	local robuxSquare = Instance.new("UIAspectRatioConstraint")
	robuxSquare.DominantAxis = Enum.DominantAxis.Height
	robuxSquare.Parent = robux
	robux.Parent = capsule
	local note = label(capsule, "Nota", WHITE, "small", strokes)
	note.LayoutOrder, note.Size = 7, UDim2.fromScale(0.8, 0.7)
	local locked = { skull, kills }

	-- Contornos al alto en pantalla y el ícono de poder pegado a la izquierda del "x3".
	local function fit()
		local height = root.AbsoluteSize.Y
		for stroke, share in strokes do
			stroke.Thickness = math.clamp(height * share, 1, 10)
		end
		local side = height * 0.34
		power.Size = UDim2.fromOffset(side, side)
		power.Position = UDim2.new(0.5, -big.TextBounds.X / 2 - side * 0.05, 0.44, 0)
	end
	root:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	big:GetPropertyChangedSignal("TextBounds"):Connect(fit)

	local function set(state: State, killsText: string)
		for _, item in locked do
			item.Visible = state == "locked"
		end
		robux.Visible = state == "robux"
		note.Visible = state ~= "locked"
		note.Text = if state == "open" then "¡Abierto! Entrenar" else "Pase sagrado"
		note.Size = UDim2.fromScale(if state == "robux" then 0.62 else 0.84, 0.7)
		kills.Text = killsText
		capsule.BackgroundColor3 = if state == "open" then OPEN else PILL
		border.Color = if state == "open" then Color3.fromRGB(170, 255, 170) else color
		big.TextTransparency = if state == "open" then 0 else 0.1
	end

	return {
		set = function(state: State, killsText: string)
			set(state, killsText)
			fit()
		end,
		show = function(visible: boolean)
			billboard.Enabled = visible
		end,
	}
end

return PondSignView
