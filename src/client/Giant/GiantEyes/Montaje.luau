--!strict
--[[
	GiantEyes/Montaje

	Las partes de las pupilas de un modelo de etapa y dónde van. Al armarse mide
	cada ojo en el espacio de la MeshPart (GiantEyes/Medidas) y lo pasa al del
	hueso que lo lleva, con la pose de bind:
		offset = bind(hueso, en la MeshPart):Inverse() * ojo local
	Cada cuadro: ojo = hueso.TransformedWorldCFrame * offset. Si la MeshPart
	cambia de tamaño (ScaleTo, crecimiento), vuelve a medir todo.
	Las partes van en una carpeta dentro del modelo de la etapa: se van con él.
	Nunca crea partes por cuadro y solo mueve las que cambiaron.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Data = require(ReplicatedStorage.Shared.UIConfig.GiantEyesData)
local Settings = require(ReplicatedStorage.Shared.UIConfig.GiantEyes)
local Medidas = require(script.Parent.Medidas)

export type Ojo = {
	eye: Data.Eye,
	offset: CFrame, -- el ojo en el espacio del hueso (pose de bind)
	capas: Medidas.Capas?, -- nil hasta la primera medida válida
	cover: Part?,
	pupil: Part,
}

export type Montaje = {
	entry: Data.ModelEyes,
	look: Settings.Look,
	bone: Bone,
	part: BasePart,
	folder: Folder,
	ojos: { Ojo },
	size: Vector3, -- MeshPart.Size de la última medida
	minSide: number, -- studs: el lado menor del ojo más chico
	frames: { CFrame }, -- reusadas en cada cuadro
	moveParts: { BasePart },
	moveTo: { CFrame },
}

local Montaje = {}

-- Nace dentro de la malla (at): escondida hasta que la primera medida la ubique.
local function newPart(name: string, color: Color3, material: Enum.Material, at: CFrame): Part
	local part = Instance.new("Part")
	part.Name = name
	part.CFrame = at
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Massless = true
	part.Color = color
	part.Material = material
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

-- Mide (o vuelve a medir) los ojos con el tamaño actual de la MeshPart.
local function measure(m: Montaje)
	local part = m.part
	local center, k = Medidas.box(m.entry, part.Size)
	local toBone = Medidas.bindInPart(m.bone):Inverse() -- de la MeshPart al hueso, en bind
	m.size = part.Size
	m.minSide = math.huge
	for _, ojo in m.ojos do
		local frame, width, height = Medidas.frame(ojo.eye, center, k)
		if frame then
			local cover = ojo.cover
			local capas = Medidas.layers(m.look, width, height, cover ~= nil)
			ojo.offset = toBone * frame
			ojo.capas = capas
			ojo.pupil.Size = capas.pupil
			if cover then
				cover.Size = capas.cover
			end
			m.minSide = math.min(m.minSide, capas.side)
		end
	end
end

-- Arma las pupilas de un modelo de etapa, o nil si no le tocan (Medidas.find).
function Montaje.build(inner: Model): Montaje?
	local found = Medidas.find(inner)
	if not found then
		return nil
	end
	local entry, look, part, color = found.entry, found.look, found.part, found.color
	local cover = entry.cover
	local folder = Instance.new("Folder")
	folder.Name = "Pupilas"
	local ojos: { Ojo } = {}
	for i, eye in entry.eyes do
		if Medidas.frame(eye, Vector3.zero, Vector3.one) == nil then
			continue -- datos que no forman un plano: ese ojo se queda sin pupila
		end
		table.insert(ojos, {
			eye = eye,
			offset = CFrame.identity,
			capas = nil,
			cover = if cover
				then newPart(`Tapa{i}`, cover, look.coverMaterial, part.CFrame)
				else nil,
			pupil = newPart(`Pupila{i}`, color, look.material, part.CFrame),
		})
	end
	local m: Montaje = {
		entry = entry,
		look = look,
		bone = found.bone,
		part = part,
		folder = folder,
		ojos = ojos,
		size = part.Size,
		minSide = math.huge,
		frames = {},
		moveParts = {},
		moveTo = {},
	}
	measure(m)
	if m.minSide == math.huge then -- ningún ojo con datos válidos
		folder:Destroy()
		return nil
	end
	for _, ojo in ojos do
		ojo.pupil.Parent = folder
		local coverPart = ojo.cover
		if coverPart then
			coverPart.Parent = folder
		end
	end
	folder.Parent = inner
	return m
end

-- Sigue a la malla: si cambió de tamaño (ScaleTo), vuelve a medir. Devuelve dónde
-- están los ojos este cuadro, en el orden de m.ojos (la tabla se reusa).
function Montaje.eyes(m: Montaje): { CFrame }
	if m.part.Size ~= m.size then
		measure(m)
	end
	local head = m.bone.TransformedWorldCFrame
	for i, ojo in m.ojos do
		m.frames[i] = head * ojo.offset
	end
	return m.frames
end

local function put(m: Montaje, part: BasePart, cf: CFrame)
	if not part.CFrame:FuzzyEq(cf, Settings.MoveEpsilon) then
		table.insert(m.moveParts, part)
		table.insert(m.moveTo, cf)
	end
end

-- Escribe solo los CFrame que cambiaron. shifts: corrimiento de cada pupila (-1..1).
function Montaje.place(m: Montaje, frames: { CFrame }, shifts: { Vector2 })
	table.clear(m.moveParts)
	table.clear(m.moveTo)
	for i, ojo in m.ojos do
		local eye, capas = frames[i], ojo.capas
		if eye and capas then
			local shift = shifts[i] or Vector2.zero
			local cover = ojo.cover
			if cover then
				put(m, cover, eye * capas.coverAt)
			end
			local x, y = shift.X * capas.limit.X, shift.Y * capas.limit.Y
			put(m, ojo.pupil, eye * CFrame.new(x, y, -capas.depth))
		end
	end
	if #m.moveParts > 0 then
		Workspace:BulkMoveTo(m.moveParts, m.moveTo, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

function Montaje.setHidden(m: Montaje, hidden: boolean)
	local transparency = if hidden then 1 else 0
	for _, ojo in m.ojos do
		ojo.pupil.Transparency = transparency
		local cover = ojo.cover
		if cover then
			cover.Transparency = transparency
		end
	end
end

function Montaje.destroy(m: Montaje)
	m.folder:Destroy()
end

return table.freeze(Montaje)
