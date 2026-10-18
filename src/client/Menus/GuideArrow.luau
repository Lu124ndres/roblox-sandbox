--!strict
--[[
	GuideArrow

	Las flechas de la guía del tutorial (como las de los simuladores): gruesas,
	amarillas, con contorno negro (un solo Highlight para todas) para que se
	vean sobre el pasto, la arena, el mar y la piedra del volcán.
		shape   arma una flecha (cuerpo y punta) dentro de un modelo
		pose    la pone en un CFrame (apunta hacia su LookVector)
		new     la flecha que flota junto al jugador, a la altura del pecho, lo
		        sigue y apunta hacia el camino (GuidePath); gira suave, sin
		        sacudirse cuando el camino cambia
	Solo existen en este cliente: no hay nada puesto en el mapa.
]]

local Workspace = game:GetService("Workspace")

local COLOR = Color3.fromRGB(255, 214, 30)
local DISTANCE = 5.5 -- studs delante del jugador: no la tapa el cuerpo
local HEIGHT = 1.3 -- respecto del centro del cuerpo: a la altura del pecho
local BOB = 0.35
local NUDGE = 0.5 -- cuánto empuja hacia adelante y vuelve
local TURN = 6 -- qué tan rápido gira hacia la dirección nueva (por segundo)

export type Shape = { { part: BasePart, offset: CFrame } }
export type Arrow = {
	place: (root: Vector3, direction: Vector3, t: number, dt: number) -> (),
	show: (visible: boolean) -> (),
}

local GuideArrow = {}

local group: Model? = nil

-- El modelo que guarda todas las flechas, con un solo contorno negro.
function GuideArrow.group(): Model
	if group then
		return group
	end
	local model = Instance.new("Model")
	model.Name = "FlechasGuia"
	local outline = Instance.new("Highlight")
	outline.FillTransparency = 1
	outline.OutlineColor = Color3.fromRGB(20, 14, 6)
	outline.OutlineTransparency = 0
	outline.DepthMode = Enum.HighlightDepthMode.Occluded
	outline.Adornee = model
	outline.Parent = model
	model.Parent = Workspace
	group = model
	return model
end

local function piece(name: string, size: Vector3, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = COLOR
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide, part.CanQuery, part.CanTouch = false, false, false
	part.CastShadow = false
	part.Transparency = 1
	part.Parent = parent
	return part
end

-- Una flecha de `scale` (1 = la del jugador) dentro de `parent`; apunta hacia -Z.
function GuideArrow.shape(parent: Instance, name: string, scale: number): Shape
	return {
		{
			part = piece(`{name}Cuerpo`, Vector3.new(1.4, 0.7, 2.8) * scale, parent),
			offset = CFrame.new(0, 0, 1.4 * scale),
		},
		{
			part = piece(`{name}Punta`, Vector3.new(2.5, 0.7, 2.5) * scale, parent),
			offset = CFrame.new(0, 0, -0.45 * scale) * CFrame.Angles(0, math.rad(45), 0),
		},
	}
end

function GuideArrow.pose(shape: Shape, frame: CFrame, transparency: number)
	for _, item in shape do
		item.part.CFrame = frame * item.offset
		item.part.Transparency = transparency
	end
end

function GuideArrow.new(): Arrow
	local shape = GuideArrow.shape(GuideArrow.group(), "Jugador", 1)
	local visible = false
	local heading: Vector3? = nil

	local function show(on: boolean)
		if on ~= visible then
			visible = on
			if not on then
				for _, item in shape do
					item.part.Transparency = 1
				end
				heading = nil
			end
		end
	end

	local function place(root: Vector3, direction: Vector3, t: number, dt: number)
		local flat = Vector3.new(direction.X, 0, direction.Z)
		if flat.Magnitude < 1e-3 then
			return
		end
		-- Gira suave hacia la dirección nueva: no salta cuando el camino se recalcula.
		local target = flat.Unit
		local current = heading or target
		local turned = current:Lerp(target, math.clamp(dt * TURN, 0, 1))
		heading = if turned.Magnitude > 1e-3 then turned.Unit else target
		local forward = heading :: Vector3
		local push = (math.sin(t * 5) * 0.5 + 0.5) * NUDGE
		local position = root
			+ forward * (DISTANCE + push)
			+ Vector3.new(0, HEIGHT + math.sin(t * 2.4) * BOB, 0)
		GuideArrow.pose(shape, CFrame.lookAt(position, position + forward), 0)
	end

	return { place = place, show = show }
end

return GuideArrow
