--!strict
--[[
	WindowTitle

	Título de una ventana (Window): letras doradas enormes, un poco inclinadas,
	con cristales oscuros a cada lado (Interface/Kit). El tamaño de la letra se
	elige midiendo el texto, para que título y gemas quepan en `room` (unidades
	de la ventana, que luego escala su UIScale; así las gemas quedan pegadas al
	texto en cualquier pantalla).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local TextCase = require(ReplicatedStorage.Shared.TextCase)
local Kit = require(script.Parent.Parent.Interface.Kit)
local Style = require(script.Parent.Parent.Interface.Style)

local MAX_TEXT = 56
local MIN_TEXT = 24
local GEM = 40 -- alto de las gemas
local SIDE = 24 -- espacio a cada lado del texto (donde va media gema)
local LEFT = 30 -- dónde queda el centro de la gema izquierda
local MEASURE = Enum.Font.FredokaOne -- la de UIConfig.Fonts.Title

local WindowTitle = {}

-- `room`: ancho disponible para título y gemas; `height`: alto de la franja.
function WindowTitle.make(parent: Instance, title: string, room: number, height: number): Frame
	local text = TextCase.upper(title)
	local wide = TextService:GetTextSize(text, MAX_TEXT, MEASURE, Vector2.new(4096, 4096)).X
	local size =
		math.clamp(math.floor(MAX_TEXT * (room - SIDE * 2) / math.max(wide, 1)), MIN_TEXT, MAX_TEXT)
	-- Con holgura: si el texto mide justo lo medido, cualquier diferencia de redondeo corta
	-- la última letra ("TIEND").
	local width = TextService:GetTextSize(text, size, MEASURE, Vector2.new(4096, 4096)).X
		+ size * 0.35

	local holder = Instance.new("Frame")
	holder.Name = "Encabezado"
	holder.BackgroundTransparency = 1
	holder.Position = UDim2.fromOffset(LEFT, 0)
	holder.Size = UDim2.fromOffset(width + SIDE * 2, height)
	holder.Rotation = -2
	holder.ZIndex = 3
	holder.Parent = parent

	local heading = Style.text(holder, "Titulo", MAX_TEXT, nil, 4.5)
	heading.Text = text
	heading.TextScaled = false
	heading.TextWrapped = false
	heading.TextSize = size
	heading.Position = UDim2.fromOffset(SIDE, 0)
	heading.Size = UDim2.new(1, -SIDE * 2, 1, 0)
	Kit.gold(heading)
	local stroke = heading:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Thickness = 4.5
	end
	Kit.crystals(holder, GEM * 1.3)
	return holder
end

return WindowTitle
