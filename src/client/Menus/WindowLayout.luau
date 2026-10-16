--!strict
--[[
	WindowLayout

	Tamaño y escala de las ventanas (Window) y la forma "ancha" del táctil.
		fit      escala según el alto de la pantalla
		share    parte de la pantalla que puede ocupar (PC deja ver el juego)
		resize   acomoda la ventana y devuelve su escala: la de `fit`, pero sin
		         que el tope (maxSize, ya escalado) pase de `share`; si no, en
		         el teléfono se salía por abajo
		wide     en táctil (teléfono horizontal, tablet) las ventanas son anchas
		         y bajas: el contenido va en dos columnas
		size     elige el tope de PC o el ancho de táctil
		columns  divide el contenido en dos columnas (en PC, las dos son el
		         contenido entero, así cada ventana arma lo mismo)
]]

local Device = require(script.Parent.Parent.Interface.Device)

local REFERENCE_HEIGHT = 720 -- alto de pantalla (px) en que la ventana se ve a escala 1
local TOUCH_REFERENCE_HEIGHT = 480 -- en táctil, escala 1 ya en pantallas más bajas
local SCREEN_SHARE = Vector2.new(0.72, 0.8)
local TOUCH_SCREEN_SHARE = Vector2.new(0.96, 0.94)
local COLUMN_GAP = 16

local WindowLayout = {}

function WindowLayout.fit(): number
	local height = Device.viewport().Y
	if Device.touch() then
		return math.clamp(height / TOUCH_REFERENCE_HEIGHT, 0.8, 2)
	end
	return math.clamp(height / REFERENCE_HEIGHT, 0.6, 1.6)
end

function WindowLayout.share(): Vector2
	return if Device.touch() then TOUCH_SCREEN_SHARE else SCREEN_SHARE
end

-- `frameMax`: el tope del marco entero (panel + lo que sobresale el título).
function WindowLayout.resize(frame: Frame, screen: ScreenGui, frameMax: Vector2): number
	local share = WindowLayout.share()
	local area = screen.AbsoluteSize
	if area.X < 1 or area.Y < 1 then
		area = Device.viewport()
	end
	local fit =
		math.min(WindowLayout.fit(), share.X * area.X / frameMax.X, share.Y * area.Y / frameMax.Y)
	frame.Size = UDim2.fromScale(share.X / fit, share.Y / fit)
	frame.Position = UDim2.fromScale(0.5, if Device.touch() then 0.5 else 0.53)
	return fit
end

function WindowLayout.wide(): boolean
	return Device.touch()
end

function WindowLayout.size(desktop: Vector2, touch: Vector2): Vector2
	return if WindowLayout.wide() then touch else desktop
end

local function column(content: Frame, name: string, x: number, width: number): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundTransparency = 1
	frame.Position = UDim2.new(x, if x > 0 then COLUMN_GAP / 2 else 0, 0, 0)
	frame.Size = UDim2.new(width, -COLUMN_GAP / 2, 1, 0)
	frame.Parent = content
	return frame
end

-- `leftShare`: parte del ancho para la columna izquierda (0..1).
function WindowLayout.columns(content: Frame, leftShare: number): (Frame, Frame)
	if not WindowLayout.wide() then
		return content, content
	end
	return column(content, "Izquierda", 0, leftShare),
		column(content, "Derecha", leftShare, 1 - leftShare)
end

return WindowLayout
