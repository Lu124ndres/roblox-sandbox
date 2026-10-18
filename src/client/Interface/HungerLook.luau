--!strict
--[[
	HungerLook

	Decorado del panel de hambre (HungerPanel), sin lógica, con las piezas de
	piedra de Interface/Kit (como la referencia del usuario):
		placa     panel de pizarra con borde biselado detrás de todo, un poco más
		          ancho que el panel, con una gema azul a cada lado
		medalla   círculo oscuro con aro de piedra detrás del retrato del monstruo;
		          el aro interior toma el color de la etapa (HungerBar lo cambia)
		hueco     la pista de la barra, hundida en la piedra
		brillo    franja clara arriba del relleno de la barra (se ve "de cristal")
		carne     ícono de carne a la izquierda dentro de la barra
]]

local Icons = require(script.Parent.Icons)
local Kit = require(script.Parent.Kit)

local rgb = Color3.fromRGB
local WHITE = Color3.new(1, 1, 1)

local HungerLook = {}

HungerLook.PAD = 10 -- cuánto sobresale la placa del panel por cada lado
HungerLook.GEM = 36 -- alto de las gemas de los costados
-- Cuánto sobresale todo (placa y media gema) por cada lado: HungerPanel lo deja libre.
HungerLook.OVERHANG = HungerLook.PAD + math.ceil(HungerLook.GEM * 0.4)
local PLATE_SLICE = 0.35 -- borde de la pizarra un poco más fino que en las ventanas

local function gradient(parent: Instance, top: Color3, bottom: Color3)
	local fill = Instance.new("UIGradient")
	fill.Rotation = 90
	fill.Color = ColorSequence.new(top, bottom)
	fill.Parent = parent
end

local function round(parent: GuiObject, radius: UDim)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius
	corner.Parent = parent
end

-- Placa de piedra detrás de todo, desde arriba hasta `bottom`. Las gemas van en un
-- marco aparte encima de todo (dentro de la placa quedarían debajo del retrato).
function HungerLook.plate(panel: Frame, bottom: number): Frame
	local pad = HungerLook.PAD
	local plate = Instance.new("Frame")
	plate.Name = "Placa"
	plate.BackgroundTransparency = 1
	plate.Position = UDim2.fromOffset(-pad, -pad + 2)
	plate.Size = UDim2.new(1, 2 * pad, 0, bottom + pad - 2)
	plate.ZIndex = 0
	plate.Parent = panel
	Kit.skin(plate, "panel").SliceScale = PLATE_SLICE
	local gems = Instance.new("Frame")
	gems.Name = "Gemas"
	gems.BackgroundTransparency = 1
	gems.Position = plate.Position
	gems.Size = plate.Size
	gems.ZIndex = 9
	gems.Interactable = false
	gems.Parent = panel
	Kit.gems(gems, HungerLook.GEM)
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
	gradient(medal, rgb(62, 68, 88), rgb(18, 20, 30))
	local rim = Instance.new("UIStroke")
	rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	rim.Color = WHITE
	rim.Thickness = 4
	rim.Parent = medal
	gradient(rim, rgb(206, 210, 222), rgb(86, 90, 104)) -- aro de piedra clara
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

-- La pista de la barra, hundida en la piedra. Devuelve el marco que recorta el
-- relleno (adentro del hueco, sin tapar su borde).
function HungerLook.hollow(track: Frame): Frame
	Kit.skin(track, "hondo")
	local clip = Instance.new("Frame")
	clip.Name = "Recorte"
	clip.BackgroundTransparency = 1
	clip.Position = UDim2.fromOffset(4, 4)
	clip.Size = UDim2.new(1, -8, 1, -8)
	clip.ClipsDescendants = true
	round(clip, UDim.new(0, 6))
	clip.Parent = track
	return clip
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
