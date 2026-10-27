--!strict
--[[
	HabitatPlacer

	Coloca un prop del hábitat (un Model de ServerStorage.Habitats.<GiantId>)
	en el cráter, como dice el contrato de hábitats (docs/tareas_claude_code.md):
		1. ScaleTo(escala).
		2. Rayos hacia abajo solo contra el terreno (sin el agua): en el centro y
		   en 4 puntos a probeFraction del ancho y del fondo. En la repisa se apoya
		   en el centro; en la ladera, en el punto más bajo (si no, flota).
		3. La base, sinkStuds más abajo; el frente (-Z) mira hacia afuera, a los
		   jugadores del borde, más el giro.
	Todo anclado. Solo choca la malla principal de los props con Colision = true.
	Los efectos de luz salen de aquí (PointLight en el Attachment Llama); el
	fuego y el latido del Neon son del cliente (Ambient/HabitatFx).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)

local HABITATS = Config.Habitats
local LIGHT = HABITATS.light
local CENTER = WorldZones.craterCenter

local HabitatPlacer = {}

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.IgnoreWater = true

-- El fondo es el terreno del lago y, del acantilado para afuera, la malla del volcán
-- (World/BlockVolcano): los rayos chocan con los dos.
local function grounds(): { Instance }
	local volcano = Workspace:FindFirstChild(Protocol.Map.BlockVolcano)
	return if volcano then { Workspace.Terrain, volcano } else { Workspace.Terrain }
end

-- Altura del terreno bajo (x, z), o nil si el rayo no encuentra nada.
local function groundAt(point: Vector3): number?
	local origin = Vector3.new(point.X, HABITATS.rayTopHeight, point.Z)
	rayParams.FilterDescendantsInstances = grounds()
	local hit = Workspace:Raycast(origin, Vector3.new(0, -HABITATS.rayLength, 0), rayParams)
	return if hit then hit.Position.Y else nil
end

-- Altura donde se apoya: el centro en la repisa, el punto más bajo en la ladera.
local function restingHeight(flat: CFrame, size: Vector3, onSlope: boolean): number?
	local px, pz = size.X * HABITATS.probeFraction, size.Z * HABITATS.probeFraction
	local center = groundAt(flat.Position)
	local lowest = center
	for _, offset in
		{
			Vector3.new(px, 0, 0),
			Vector3.new(-px, 0, 0),
			Vector3.new(0, 0, pz),
			Vector3.new(0, 0, -pz),
		}
	do
		local height = groundAt(flat * offset)
		if height and (lowest == nil or height < lowest) then
			lowest = height
		end
	end
	return if onSlope or center == nil then lowest else center
end

-- PointLight en el punto Llama para "fuego" (naranja si no trae ColorLuz) y "luz".
local function addLight(model: Model, effect: any, scale: number)
	if effect ~= "fuego" and effect ~= "luz" then
		return
	end
	local root = model.PrimaryPart
	local anchor = root and root:FindFirstChild("Llama")
	local color = model:GetAttribute("ColorLuz")
	if typeof(color) ~= "Color3" then
		if effect == "luz" then
			return -- una "luz" sin color no tiene qué mostrar
		end
		color = LIGHT.fireColor
	end
	local light = Instance.new("PointLight")
	light.Color = color :: Color3
	light.Brightness = LIGHT.brightness
	light.Range = math.min(LIGHT.range * scale, LIGHT.maxRange)
	light.Shadows = false
	light.Parent = if anchor and anchor:IsA("Attachment") then anchor else root
end

local function settle(model: Model, collides: boolean)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			local solid = collides and descendant == model.PrimaryPart
			descendant.Anchored = true
			descendant.CanCollide = solid
			descendant.CanQuery = solid
			descendant.CanTouch = false
		end
	end
end

-- Clona template según entry y lo deja en parent. Devuelve el Model, o nil si
-- cae en una zona libre o no hay terreno abajo.
function HabitatPlacer.place(template: Model, entry: Config.HabitatProp, parent: Instance): Model?
	local radius = entry.radio
	if radius < HABITATS.giantClearRadius or radius >= WorldLayout.craterCliffRadius then
		warn(`HabitatPlacer: {template.Name} a radio {radius} cae en una zona libre; se omite`)
		return nil
	end
	local model = template:Clone()
	if not model.PrimaryPart then
		model:Destroy()
		return nil
	end
	model:ScaleTo(entry.escala)
	local _, size = model:GetBoundingBox()
	local angle = math.rad(entry.angulo)
	local spot = CENTER + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
	local outward = Vector3.new(math.cos(angle), 0, math.sin(angle))
	local flat = CFrame.lookAt(spot, spot + outward) * CFrame.Angles(0, math.rad(entry.giro), 0)
	local height = restingHeight(flat, size, radius >= HABITATS.slopeRadius)
	if not height then
		warn(
			`HabitatPlacer: no hay terreno bajo {template.Name} (ángulo {entry.angulo}); se omite`
		)
		model:Destroy()
		return nil
	end
	settle(model, model:GetAttribute("Colision") == true)
	model:PivotTo(flat + Vector3.new(0, height - HABITATS.sinkStuds, 0))
	model:SetAttribute("Escala", entry.escala) -- el cliente escala el fuego con esto
	-- Con streaming, el cliente recibe el prop entero (Llama y Brillo incluidos) o nada.
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	addLight(model, model:GetAttribute("Efecto"), entry.escala)
	model.Parent = parent
	return model
end

return HabitatPlacer
