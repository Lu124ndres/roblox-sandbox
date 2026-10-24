--!strict
--[[
	Textos (tráiler)

	Las frases grandes del video, como en referencias/Ejemplo.mp4: blancas con
	borde oscuro, arriba, entran palabra por palabra con un rebote, se quedan
	un momento y se van solas para dejar ver el juego. El título del final va
	en dorado, abajo y en dos líneas. Solo lo usa Director.client.
]]

local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local FONT = Font.new("rbxasset://fonts/families/LuckiestGuy.json")
local GOLD = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 246, 170)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 208, 72)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(226, 120, 28)),
})
local WORD_GAP = 0.11 -- segundos entre palabra y palabra
local POP = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local OUT = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

export type Opciones = {
	y: number, -- centro vertical (fracción de la pantalla)
	alto: number, -- alto de la letra (fracción del alto de la pantalla)
	dorado: boolean?,
	dura: number?, -- segundos en pantalla antes de irse (nil: se queda)
}

local Textos = {}

local current: Frame? = nil

local function clear()
	if current then
		current:Destroy()
		current = nil
	end
end

local function word(
	text: string,
	size: number,
	gold: boolean,
	order: number
): (TextLabel, UIScale, UIStroke)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.AutomaticSize = Enum.AutomaticSize.XY
	label.Size = UDim2.new()
	label.FontFace = FONT
	label.TextSize = size
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = text
	label.LayoutOrder = order
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = math.max(3, size * 0.075)
	stroke.Color = if gold then Color3.fromRGB(58, 26, 6) else Color3.fromRGB(16, 12, 20)
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = label
	if gold then
		local gradient = Instance.new("UIGradient")
		gradient.Color = GOLD
		gradient.Rotation = 90
		gradient.Parent = label
	end
	local scale = Instance.new("UIScale")
	scale.Scale = 0
	scale.Parent = label
	return label, scale, stroke
end

-- Muestra `texto` ("\n" parte en líneas) y devuelve enseguida.
function Textos.mostrar(gui: ScreenGui, texto: string, opciones: Opciones)
	clear()
	local camera = Workspace.CurrentCamera :: Camera
	local size = math.floor(camera.ViewportSize.Y * opciones.alto)
	local gold = opciones.dorado == true
	local box = Instance.new("Frame")
	box.Name = "Frase"
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	box.Position = UDim2.fromScale(0.5, opciones.y)
	box.Size = UDim2.fromScale(0.96, 0)
	box.AutomaticSize = Enum.AutomaticSize.Y
	box.BackgroundTransparency = 1
	box.Rotation = if gold then 0 else math.random(-2, 2)
	local rows = Instance.new("UIListLayout")
	rows.HorizontalAlignment = Enum.HorizontalAlignment.Center
	rows.SortOrder = Enum.SortOrder.LayoutOrder
	rows.Padding = UDim.new(0, -math.floor(size * 0.12))
	rows.Parent = box

	local pieces: { { TextLabel | UIScale | UIStroke } } = {}
	local order = 0
	for lineIndex, line in string.split(texto, "\n") do
		local row = Instance.new("Frame")
		row.BackgroundTransparency = 1
		row.AutomaticSize = Enum.AutomaticSize.XY
		row.Size = UDim2.new()
		row.LayoutOrder = lineIndex
		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.Padding = UDim.new(0, math.floor(size * 0.28))
		layout.Parent = row
		for _, text in string.split(line, " ") do
			order += 1
			local label, scale, stroke = word(text, size, gold, order)
			label.Parent = row
			table.insert(pieces, { label, scale, stroke })
		end
		row.Parent = box
	end
	box.Parent = gui
	current = box

	task.spawn(function()
		for _, piece in pieces do
			if current ~= box then
				return
			end
			TweenService:Create(piece[2] :: UIScale, POP, { Scale = 1 }):Play()
			task.wait(WORD_GAP)
		end
		if not opciones.dura then
			return
		end
		task.wait(opciones.dura)
		if current ~= box then
			return
		end
		for _, piece in pieces do
			TweenService:Create(piece[1] :: TextLabel, OUT, { TextTransparency = 1 }):Play()
			TweenService:Create(piece[3] :: UIStroke, OUT, { Transparency = 1 }):Play()
			TweenService:Create(piece[2] :: UIScale, OUT, { Scale = 1.15 }):Play()
		end
		task.wait(OUT.Time)
		if current == box then
			clear()
		end
	end)
end

Textos.limpiar = clear

return Textos
