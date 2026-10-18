--!strict
--[[
	GuideArrow

	Las flechas de la guía del tutorial (como las de los simuladores): planas,
	amarillas, con contorno negro (un solo Highlight para todas) para que se
	vean sobre el pasto, la arena, el mar y la piedra del volcán.
		shape   arma una flecha plana (cuerpo y punta) dentro de un modelo
		pose    la pone en un CFrame (apunta hacia su LookVector) con una
		        transparencia (para que aparezcan y se vayan suave)
	Las mueve GuidePath por el camino.
	Solo existen en este cliente: no hay nada puesto en el mapa.
]]

local Workspace = game:GetService("Workspace")

local COLOR = Color3.fromRGB(255, 214, 30)
local THICK = 0.35 -- plana, como las de los simuladores

export type Shape = { { part: BasePart, offset: CFrame } }

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

-- Una flecha de `scale` dentro de `parent`; apunta hacia -Z.
function GuideArrow.shape(parent: Instance, name: string, scale: number): Shape
	return {
		{
			part = piece(`{name}Cuerpo`, Vector3.new(1.4 * scale, THICK, 2.8 * scale), parent),
			offset = CFrame.new(0, 0, 1.4 * scale),
		},
		{
			part = piece(`{name}Punta`, Vector3.new(2.5 * scale, THICK, 2.5 * scale), parent),
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

return GuideArrow
