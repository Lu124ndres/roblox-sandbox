--!strict
--[[
	SandHabitat

	El hábitat completo del Minotauro (Workspace.Habitat.HabitatMinotauro, lo
	arma server/World/HabitatComplete) está modelado a ras de la arena del
	desierto. Sin arena quedaría flotando sobre el cuenco vacío y su centro
	chocaría con el santuario que sube en el descanso: aquí, en este cliente,
	baja con la arena y se esconde, como SandProps con los props sueltos.

	setDepth(d): la arena está d studs por debajo de su lugar final (0 = puesta,
	math.huge = no hay). Los primeros FOLLOW studs el hábitat baja con ella
	(BulkMoveTo de sus partes; sus fuegos con PivotTo); más abajo se esconde
	(LocalTransparencyModifier, sin PointLight ni Fire) y espera FOLLOW studs
	abajo. Al volver la arena aparece ahí y sube con ella.

	Sus fuegos son props aparte (Fuego<k>, hermanos del modelo en la carpeta) que
	enciende HabitatFx: se manejan aquí mientras el modelo del Minotauro está.
	owns(model) dice qué es de un hábitat completo, para que SandProps no lo suba.
]]

local Workspace = game:GetService("Workspace")

local NAME = "HabitatMinotauro"
local FIRE_NAME = "^Fuego%d+$" -- los props de fuego de HabitatComplete
local FIRE_ROOT = "Raiz"
local FOLLOW = 12 -- studs que baja con la arena antes de esconderse (y desde donde vuelve)

local SandHabitat = {}

local depth = math.huge
local model: Model? = nil
local parts: { BasePart } = {}
local frames: { CFrame } = {}
local lights: { PointLight } = {}
local fires: { [Model]: RBXScriptConnection } = {} -- cada fuego, con su DescendantAdded
-- Dónde los puso el servidor. Débil: si el streaming devuelve la misma instancia (movida
-- aquí), su lugar original sigue anotado.
local bases: { [Instance]: CFrame } = setmetatable({} :: any, { __mode = "k" })
local shown = true -- lo que se aplicó (el servidor lo crea visible)

-- ¿Es parte de un hábitat completo (el modelo o uno de sus fuegos)?
function SandHabitat.owns(child: Instance): boolean
	if child:GetAttribute("Completo") == true then
		return true
	end
	return string.match(child.Name, FIRE_NAME) ~= nil and child:FindFirstChild(FIRE_ROOT) ~= nil
end

local function baseOf(instance: PVInstance): CFrame
	local base = bases[instance]
	if not base then
		-- Las partes por su CFrame (BulkMoveTo mueve el CFrame): las MeshPart importadas
		-- traen PivotOffset y GetPivot daría otra altura.
		base = if instance:IsA("BasePart") then instance.CFrame else instance:GetPivot()
		bases[instance] = base
	end
	return base
end

local function lightFire(instance: Instance, on: boolean)
	if instance:IsA("Fire") then
		instance.Enabled = on
	end
end

local function setShown(value: boolean)
	shown = value
	local hidden = if value then 0 else 1
	for _, part in parts do
		part.LocalTransparencyModifier = hidden
	end
	for _, light in lights do
		light.Enabled = value
	end
	for fire in fires do
		for _, child in fire:GetDescendants() do
			lightFire(child, value)
		end
	end
end

-- Pone todo a la altura de la arena y lo muestra o esconde.
local function apply(force: boolean)
	if not model then
		return
	end
	local visible = depth <= FOLLOW
	if visible or force then
		local down = Vector3.new(0, math.min(depth, FOLLOW), 0)
		for i, part in parts do
			frames[i] = baseOf(part) - down
		end
		Workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
		for fire in fires do
			fire:PivotTo(baseOf(fire) - down)
		end
	end
	if visible ~= shown or force then
		setShown(visible)
	end
end

local function adopt(child: Model)
	model = child
	table.clear(parts)
	table.clear(frames)
	table.clear(lights)
	for _, item in child:GetDescendants() do
		if item:IsA("BasePart") then
			table.insert(parts, item)
			baseOf(item)
		elseif item:IsA("PointLight") then
			table.insert(lights, item)
		end
	end
	for fire in fires do
		baseOf(fire)
	end
	apply(true)
end

local function addFire(child: Model)
	if fires[child] then
		return
	end
	baseOf(child)
	-- HabitatFx crea su Fire cuando quiere (al llegar o al apagar el modo rápido).
	fires[child] = child.DescendantAdded:Connect(function(item: Instance)
		if model then
			lightFire(item, shown)
		end
	end)
	if model then
		apply(true)
	end
end

local function track(child: Instance)
	if not child:IsA("Model") or not child.Parent then
		return
	end
	if child.Name == NAME and child:GetAttribute("Completo") == true then
		adopt(child)
	elseif SandHabitat.owns(child) and child:GetAttribute("Completo") ~= true then
		addFire(child)
	end
end

local function untrack(child: Instance)
	if child == model then
		model = nil
		table.clear(parts)
		table.clear(frames)
		table.clear(lights)
	end
	if child:IsA("Model") and fires[child] then
		fires[child]:Disconnect()
		fires[child] = nil
	end
end

function SandHabitat.setDepth(value: number)
	if value == depth then
		return
	end
	depth = value
	apply(false)
end

-- folder: Workspace.Habitat (la espera SandProps). Con streaming el modelo llega entero
-- (Atomic) y puede irse y volver: se lo vuelve a buscar cada vez.
function SandHabitat.watch(folder: Instance)
	folder.ChildAdded:Connect(function(child: Instance)
		task.defer(track, child)
	end)
	folder.ChildRemoved:Connect(untrack)
	for _, child in folder:GetChildren() do
		track(child)
	end
end

return table.freeze(SandHabitat)
