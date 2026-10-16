--!strict
--[[
	HungerLook

	Decorado del panel de hambre (HungerPanel), sin lógica:
		placa     fondo azul noche con degradado y marco dorado detrás de todo
		medalla   círculo con aro dorado detrás del retrato del monstruo; el aro
		          interior toma el color de la etapa (HungerBar lo cambia)
		brillo    franja clara arriba del relleno de la barra (se ve "de cristal")
		carne     ícono de carne a la izquierda dentro de la barra
]]

local Icons = require(script.Parent.Icons)

local rgb = Color3.fromRGB
local WHITE = Color3.new(1, 1, 1)

local HungerLook = {}

local function gradient(parent: Instance, top: Color3, bottom: Color3, rotation: number?)
	local fill = Instance.new("UIGradient")
	fill.Rotation = rotation or 90
	fill.Color = ColorSequence.new(top, bottom)
	fill.Parent = parent
end

local function round(parent: GuiObject, radius: UDim)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius
	corner.Parent = parent
end

local function goldStroke(parent: GuiObject, thickness: number): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = WHITE
	stroke.Thickness = thickness
	stroke.Parent = parent
	gradient(stroke, rgb(255, 238, 150), rgb(196, 118, 14))
	return stroke
end

-- Placa detrás del nombre, la barra y la fila del enojo (de `left` a la derecha).
function HungerLook.plate(panel: Frame, left: number, height: number): Frame
	local plate = Instance.new("Frame")
	plate.Name = "Placa"
	plate.BackgroundColor3 = WHITE
	plate.BorderSizePixel = 0
	plate.Position = UDim2.fromOffset(left, -5)
	plate.Size = UDim2.new(1, -left + 6, 0, height + 8)
	plate.ZIndex = 0
	round(plate, UDim.new(0, 16))
	gradient(plate, rgb(46, 60, 128), rgb(14, 18, 44))
	goldStroke(plate, 3)
	local shine = Instance.new("Frame")
	shine.Name = "Brillo"
	shine.BackgroundColor3 = WHITE
	shine.BackgroundTransparency = 0.88
	shine.BorderSizePixel = 0
	shine.Position = UDim2.fromScale(0.03, 0.04)
	shine.Size = UDim2.fromScale(0.94, 0.22)
	shine.ZIndex = 0
	round(shine, UDim.new(0, 10))
	shine.Parent = plate
	plate.Parent = panel
	return plate
end

-- Medalla redonda del retrato. Devuelve el aro interior (color de la etapa).
function HungerLook.medal(panel: Frame, size: number): UIStroke
	local medal = Instance.new("Frame")
	medal.Name = "Medalla"
	medal.AnchorPoint = Vector2.new(0.5, 0.5)
	medal.Position = UDim2.fromOffset(size / 2, size / 2)
	medal.Size = UDim2.fromOffset(size + 2, size + 2)
	medal.BackgroundColor3 = WHITE
	medal.ZIndex = 2
	round(medal, UDim.new(1, 0))
	gradient(medal, rgb(70, 140, 220), rgb(16, 30, 80))
	goldStroke(medal, 4)
	local ring = Instance.new("Frame")
	ring.Name = "Aro"
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.fromScale(0.5, 0.5)
	ring.Size = UDim2.new(1, -8, 1, -8)
	ring.BackgroundTransparency = 1
	ring.ZIndex = 2
	round(ring, UDim.new(1, 0))
	local stage = Instance.new("UIStroke")
	stage.Color = rgb(110, 200, 255)
	stage.Thickness = 3
	stage.Transparency = 0.15
	stage.Parent = ring
	ring.Parent = medal
	medal.Parent = panel
	return stage
end

-- Brillo arriba del relleno de la barra.
function HungerLook.shine(fill: Frame)
	local shine = Instance.new("Frame")
	shine.Name = "Brillo"
	shine.BackgroundColor3 = WHITE
	shine.BackgroundTransparency = 0.7
	shine.BorderSizePixel = 0
	shine.Position = UDim2.fromScale(0, 0.1)
	shine.Size = UDim2.fromScale(1, 0.3)
	round(shine, UDim.new(0, 6))
	shine.Parent = fill
end

-- Carne a la izquierda dentro de la barra (lo que se le da de comer).
function HungerLook.meat(track: Frame)
	local meat = Icons.view(track, "meat")
	meat.AnchorPoint = Vector2.new(0.5, 0.5)
	meat.Position = UDim2.new(0, 14, 0.5, 0)
	meat.Size = UDim2.fromOffset(34, 34)
	meat.ZIndex = 5
end

return HungerLook
