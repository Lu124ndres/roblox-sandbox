--!strict
--[[
	GiantEyes/Medidas

	Las cuentas de un ojo, sin partes ni estado. De los datos de Blender
	(UIConfig.GiantEyesData) al espacio de la MeshPart:
		Blender (x, y, z) -> Roblox (-x, z, y)   (rotación propia: no espeja)
		local = ((p - centro de la caja) / tamaño de la caja) * MeshPart.Size
	Blender: x = izquierda del personaje, -y = frente, z = arriba. Roblox, en la
	MeshPart: -X = izquierda, -Z = frente, +Y = arriba.
	El marco del ojo mira hacia afuera (LookVector = normal), con UpVector = el
	"arriba" del ojo y RightVector = normal x arriba: la derecha del ojo vista
	desde adentro. Es un marco propio en los dos lados, así que la pupila se corre
	hacia el jugador sin cambiar signos por lado.
	Las capas (tapa y pupila) salen de la cara del ojo hacia afuera, separadas
	por Gap: ninguna cara queda en el plano de otra.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Data = require(ReplicatedStorage.Shared.UIConfig.GiantEyesData)
local Settings = require(ReplicatedStorage.Shared.UIConfig.GiantEyes)

export type Capas = {
	side: number, -- studs: el lado menor del ojo
	depth: number, -- studs de la cara del ojo al centro de la pupila
	limit: Vector2, -- studs: cuánto se puede correr la pupila (ancho, alto)
	pupil: Vector3, -- tamaño de la pupila
	cover: Vector3, -- tamaño de la tapa
	coverAt: CFrame, -- la tapa en el espacio del ojo
}

export type Hallado = {
	entry: Data.ModelEyes,
	look: Settings.Look,
	bone: Bone,
	part: BasePart, -- la MeshPart que lleva el hueso
	color: Color3, -- de la pupila, en esta etapa
}

local Medidas = {}

-- Lo que hace falta para las pupilas de un modelo de etapa, o nil si no le tocan:
-- sin datos con su nombre, sin aspecto para su base, sin requiresBone (la orca
-- vieja), sin el hueso o sin una BasePart arriba del hueso.
function Medidas.find(inner: Model): Hallado?
	local entry = Data[inner.Name]
	if not entry or #entry.eyes == 0 then
		return nil
	end
	local base, stage = string.match(inner.Name, "^(.-)E(%d+)$")
	local look = if base then Settings.Looks[base] else nil
	if not look then
		return nil
	end
	local required = entry.requiresBone
	if required then
		local mark = inner:FindFirstChild(required, true)
		if not (mark and mark:IsA("Bone")) then
			return nil
		end
	end
	local bone = inner:FindFirstChild(entry.bone, true)
	if not (bone and bone:IsA("Bone")) then
		return nil
	end
	local part = bone:FindFirstAncestorWhichIsA("BasePart")
	if not part then
		return nil
	end
	local stageColors = look.stageColors
	local color = (stageColors and stageColors[tonumber(stage) or 0]) or look.color
	return { entry = entry, look = look, bone = bone, part = part, color = color }
end

function Medidas.toRoblox(v: Vector3): Vector3
	return Vector3.new(-v.X, v.Z, v.Y)
end

-- Centro de la caja de la malla (ejes de Roblox, BU) y la escala por eje hasta la
-- MeshPart de ahora (studs por BU).
function Medidas.box(entry: Data.ModelEyes, partSize: Vector3): (Vector3, Vector3)
	local a, b = Medidas.toRoblox(entry.boundsMin), Medidas.toRoblox(entry.boundsMax)
	local box = b - a
	local size = Vector3.new(
		math.max(math.abs(box.X), 1e-6),
		math.max(math.abs(box.Y), 1e-6),
		math.max(math.abs(box.Z), 1e-6)
	)
	return (a + b) / 2, partSize / size
end

-- El marco del ojo en el espacio de la MeshPart y su ancho y alto en studs, o nil
-- si los datos no forman un plano (normal nula o "arriba" paralelo a la normal).
function Medidas.frame(eye: Data.Eye, center: Vector3, k: Vector3): (CFrame?, number, number)
	local n0, up0 = Medidas.toRoblox(eye.normal), Medidas.toRoblox(eye.up)
	if n0.Magnitude < 1e-6 or up0.Magnitude < 1e-6 then
		return nil, 0, 0
	end
	-- Con escala desigual por eje, las normales se escalan al revés que las direcciones.
	local n = (n0 / k).Unit
	local upScaled = up0 * k
	local flat = upScaled - n * upScaled:Dot(n)
	local across = n0:Cross(up0)
	if flat.Magnitude < 1e-6 or across.Magnitude < 1e-6 then
		return nil, 0, 0
	end
	local up = flat.Unit
	local position = (Medidas.toRoblox(eye.center) - center) * k
	local width = eye.size.X * (across.Unit * k).Magnitude
	local height = eye.size.Y * (up0.Unit * k).Magnitude
	return CFrame.fromMatrix(position, n:Cross(up), up, -n), width, height
end

-- El hueso en la pose de bind, en el espacio de su MeshPart: el producto de los CFrame de la
-- cadena. Bone.WorldCFrame no sirve: ya incluye los Transform de la animación (medido en Play).
function Medidas.bindInPart(bone: Bone): CFrame
	local cf = bone.CFrame
	local parent = bone.Parent
	while parent and parent:IsA("Bone") do
		cf = parent.CFrame * cf
		parent = parent.Parent
	end
	return cf
end

-- Tamaños y distancias de la tapa y la pupila de un ojo de width x height studs.
function Medidas.layers(look: Settings.Look, width: number, height: number, covered: boolean): Capas
	local side = math.min(width, height)
	local gap = Settings.Gap * side
	local coverThick = Settings.CoverThickness * side
	local pupilSide = look.size * side
	local pupilThick = look.thickness * side
	local base = if covered then gap + coverThick else 0 -- la pupila va sobre la tapa
	return {
		side = side,
		depth = base + gap + pupilThick / 2,
		limit = Vector2.new(
			math.max(0, math.min(look.travel * width, width - pupilSide) / 2),
			math.max(0, math.min(look.travel * height, height - pupilSide) / 2)
		),
		pupil = Vector3.new(pupilSide, pupilSide, pupilThick),
		cover = Vector3.new(width, height, coverThick),
		coverAt = CFrame.new(0, 0, -(gap + coverThick / 2)),
	}
end

return table.freeze(Medidas)
