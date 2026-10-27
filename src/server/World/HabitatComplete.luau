--!strict
--[[
	HabitatComplete

	El hábitat completo de un gigante: una escena entera de Blender
	(tools/blender/habitat_<id>.py, docs/contrato_habitat_completo.md) en vez de
	props sueltos. Las MeshPart viven en ServerStorage.HabitatsCompletos.<GiantId>
	(importadas en el .rbxl) y sus datos en HabitatData/<GiantId>.json (los deja el
	script de Blender): todas comparten una caja centrada en el eje del cráter, así
	que cada una se pone con Size = la caja y el centro en (cráter, centroY).
		mallas   nombre y brillo (Color3 en [r, g, b]: va en Neon, sin textura)
		luces    PointLight en un punto (relativo al centro del cráter)
		fuegos   un prop "fuego" de HabitatFx en un punto (lo enciende el cliente)
	Las mallas no chocan. El modelo lleva Efecto = "brillo": el Neon late
	(Ambient/HabitatFx). Los demás campos sueltos (números, textos o sí/no) pasan
	como atributos: los de cada malla a la MeshPart (sube y soloConLava del
	dragón, flota del zorro) y los de arriba al modelo (lava): el cliente de cada
	hábitat mueve o esconde con eso lo que sube y baja con el relleno.
		has(giantId) -> boolean
		build(giantId, parent) -> Model?
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)

local LIBRARY = "HabitatsCompletos"
local DATA = script.Parent:FindFirstChild("HabitatData") -- carpeta de Rojo (un .json por gigante)
local CENTER = WorldZones.craterCenter
local FIRE_SCALE = Config.Habitats.fire.size -- un fuego de `tam` studs es Escala = tam / size

type Mesh = { nombre: string, brillo: { number }?, [string]: any }
type Light = { pos: { number }, color: { number }, rango: number }
type Fire = { pos: { number }, tam: number }
type Data = {
	ancho: number,
	alto: number,
	centroY: number,
	mallas: { Mesh },
	luces: { Light }?,
	fuegos: { Fire }?,
}

local HabitatComplete = {}

-- Los campos sueltos (sin los que ya se usan) como atributos de la instancia.
local function copyExtras(from: { [string]: any }, to: Instance, skip: { [string]: boolean })
	for key, value in from do
		local kind = type(value)
		if not skip[key] and (kind == "number" or kind == "string" or kind == "boolean") then
			to:SetAttribute(key, value)
		end
	end
end

local MESH_KEYS = { nombre = true, brillo = true }
local DATA_KEYS = { ancho = true, alto = true, centroY = true }

local function dataFor(giantId: string): Data?
	local module = DATA and DATA:FindFirstChild(giantId)
	if not module or not module:IsA("ModuleScript") then
		return nil
	end
	return (require :: any)(module) :: Data
end

local function templatesFor(giantId: string): Instance?
	local library = ServerStorage:FindFirstChild(LIBRARY)
	return library and library:FindFirstChild(giantId)
end

local function rgb(values: { number }): Color3
	return Color3.fromRGB(values[1], values[2], values[3])
end

local function at(pos: { number }): Vector3
	return CENTER + Vector3.new(pos[1], pos[2], pos[3])
end

local function holder(name: string, position: Vector3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = Vector3.one
	part.CFrame = CFrame.new(position)
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide, part.CanQuery, part.CanTouch = false, false, false
	return part
end

-- ¿Tiene ese gigante datos y mallas de hábitat completo?
function HabitatComplete.has(giantId: string): boolean
	return dataFor(giantId) ~= nil and templatesFor(giantId) ~= nil
end

function HabitatComplete.build(giantId: string, parent: Instance): Model?
	local data, templates = dataFor(giantId), templatesFor(giantId)
	if not data or not templates then
		return nil
	end
	local model = Instance.new("Model")
	model.Name = `Habitat{giantId}`
	model:SetAttribute("Efecto", "brillo")
	model:SetAttribute("Completo", true)
	copyExtras(data :: any, model, DATA_KEYS)
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	local size = Vector3.new(data.ancho, data.alto, data.ancho)
	-- Importar 3D deja cada malla girada 180° sobre su centro (como el volcán, docs/setup.md).
	local frame = CFrame.new(CENTER.X, data.centroY, CENTER.Z) * CFrame.Angles(0, math.pi, 0)
	for _, entry in data.mallas do
		local template = templates:FindFirstChild(entry.nombre)
		if not template or not template:IsA("MeshPart") then
			warn(`HabitatComplete: falta {entry.nombre} en ServerStorage.{LIBRARY}.{giantId}`)
			continue
		end
		local mesh = template:Clone()
		mesh.Size = size
		mesh.CFrame = frame
		mesh.Anchored = true
		mesh.CanCollide, mesh.CanQuery, mesh.CanTouch = false, false, false
		if entry.brillo then
			mesh.Material = Enum.Material.Neon
			mesh.Color = rgb(entry.brillo)
			mesh.TextureID = "" -- el Neon se ve del color de la pieza
		end
		copyExtras(entry, mesh, MESH_KEYS)
		mesh.Parent = model
	end
	for k, light in data.luces or {} do
		local part = holder(`Luz{k}`, at(light.pos))
		local point = Instance.new("PointLight")
		point.Color = rgb(light.color)
		point.Range = light.rango
		point.Brightness = Config.Habitats.light.brightness
		point.Shadows = false
		point.Parent = part
		part.Parent = model
	end
	model.Parent = parent
	-- Cada fuego es un prop "fuego" aparte: HabitatFx los busca entre los hijos de la carpeta.
	for k, fire in data.fuegos or {} do
		local prop = Instance.new("Model")
		prop.Name = `Fuego{k}`
		local root = holder("Raiz", at(fire.pos))
		local anchor = Instance.new("Attachment")
		anchor.Name = "Llama"
		anchor.Parent = root
		root.Parent = prop
		prop.PrimaryPart = root
		prop:SetAttribute("Efecto", "fuego")
		prop:SetAttribute("Escala", fire.tam / FIRE_SCALE)
		prop.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
		prop.Parent = parent
	end
	return model
end

return HabitatComplete
