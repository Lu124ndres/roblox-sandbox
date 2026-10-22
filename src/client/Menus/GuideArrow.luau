--!strict
--[[
	GuideArrow

	Las flechas de la guía del tutorial (como las de los simuladores,
	referencias/Ejemplo.mp4): chevrones planos verde neón pegados al suelo,
	con contorno negro (un solo Highlight para todas) para que se vean sobre
	el pasto, la arena, el mar y la piedra del volcán.
		shape   arma un chevrón plano (dos barras en V) dentro de un modelo
		pose    la pone en un CFrame (apunta hacia su LookVector) con una
		        transparencia (para que aparezcan y se vayan suave)
	Las mueve GuidePath por el camino.
	Solo existen en este cliente: no hay nada puesto en el mapa.
]]

local Workspace = game:GetService("Workspace")

local COLOR = Color3.fromRGB(70, 235, 90)
local THICK = 0.2 -- plana, pegada al suelo
local BAR = 0.75 -- ancho de cada barra del chevrón
local LENGTH = 2.6 -- largo de cada barra

export type Shape = { { part: BasePart, offset: CFrame } }

local GuideArrow = {}

GuideArrow.COLOR = COLOR -- lo comparten el anillo del destino y la flecha del velo

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
	part.Material = Enum.Material.Neon
	part.Anchored = true
	part.CanCollide, part.CanQuery, part.CanTouch = false, false, false
	part.CastShadow = false
	part.Transparency = 1
	part.Parent = parent
	return part
end

-- Un chevrón de `scale` dentro de `parent`, con la punta en el origen hacia -Z.
function GuideArrow.shape(parent: Instance, name: string, scale: number): Shape
	local shape: Shape = {}
	for side, sign in { Izq = -1, Der = 1 } do
		local back = Vector3.new(sign, 0, 1).Unit -- de la punta hacia atrás y al costado
		local center = back * LENGTH * scale / 2
		table.insert(shape, {
			part = piece(`{name}{side}`, Vector3.new(BAR * scale, THICK, LENGTH * scale), parent),
			offset = CFrame.lookAt(center, center + back),
		})
	end
	return shape
end

function GuideArrow.pose(shape: Shape, frame: CFrame, transparency: number)
	for _, item in shape do
		item.part.CFrame = frame * item.offset
		item.part.Transparency = transparency
	end
end

return GuideArrow
