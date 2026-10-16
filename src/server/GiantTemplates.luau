--!strict
--[[
	GiantTemplates

	Publica los modelos de los gigantes para que los clientes los dibujen y
	animen localmente (60 fps, sin depender de la red). Cada gigante puede
	tener un modelo por etapa en ServerStorage: <modelBase>E1 .. E4 (por
	ejemplo MinotauroE3). Aquí se copian a ReplicatedStorage.ModelosGigantes
	ya preparados: anclados, sin colisión, con el pivote en la base y su alto
	a escala 1 guardado en un atributo. Pueden tener varias MeshParts (cuerpo,
	cuernos, armadura...).

	Si falta el modelo de una etapa, el cliente usa el de la etapa anterior;
	si no hay ninguno, usa la orca teñida (o un marcador si tampoco hay orca).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Dragon = require(ReplicatedStorage.Shared.Dragon)
local GiantStages = require(ReplicatedStorage.Shared.GiantStages)
local Protocol = require(ReplicatedStorage.Shared.Protocol)

local GiantTemplates = {}

local function prepare(name: string): Model?
	local template = ServerStorage:FindFirstChild(name)
	if not template or not template:IsA("Model") then
		return nil
	end
	local model = template:Clone()
	model:ScaleTo(1)
	if not model:FindFirstChildWhichIsA("BasePart", true) then
		warn(`GiantTemplates: {name} no tiene piezas`)
		model:Destroy()
		return nil
	end
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
		end
	end
	-- La pieza más grande (el cuerpo) manda la orientación: la caja se mide en sus
	-- ejes y el pivote va en la base, al centro, para crecer hacia arriba. El
	-- modelo tiene que llegar parado (Y arriba): ver docs/blender-pipeline.md.
	local main: BasePart? = nil
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			local volume = descendant.Size.X * descendant.Size.Y * descendant.Size.Z
			if not main or volume > main.Size.X * main.Size.Y * main.Size.Z then
				main = descendant
			end
		end
	end
	model.PrimaryPart = main
	local box, size = model:GetBoundingBox()
	if main and main:FindFirstChildWhichIsA("Bone", true) then
		-- Con huesos (orca) el importador gira el pivote y la caja lo sigue: se usa la pieza.
		box, size = main.CFrame, main.Size
	end
	-- El frente del gigante es -Z del pivote. Si el modelo llegó mirando a otro lado,
	-- el atributo GiroY (grados) en el modelo de ServerStorage lo corrige.
	local turn = template:GetAttribute(Protocol.GiantModelAttributes.Turn)
	local spin = if type(turn) == "number" then math.rad(turn) else 0
	local pivot = box * CFrame.new(0, -size.Y / 2, 0) * CFrame.Angles(0, spin, 0)
	model.WorldPivot = pivot
	if main then
		main.PivotOffset = main.CFrame:ToObjectSpace(pivot) -- con PrimaryPart manda su PivotOffset
	end
	-- Los que vuelan (con alas) se miden a lo largo: su largo es Dragon.LENGTH x el alto de la etapa.
	local flies = model:FindFirstChild("AlaIzq1", true) ~= nil
	local base = if flies then math.max(size.X, size.Y, size.Z) / Dragon.LENGTH else size.Y
	model:SetAttribute(Protocol.GiantModelAttributes.BaseHeight, base)
	model.Name = name
	return model
end

function GiantTemplates.publish()
	local folder = Instance.new("Folder")
	folder.Name = Protocol.GiantModelsFolder
	for _, def in Config.Giants.chain do
		local found = 0
		for stage = 1, GiantStages.count do
			local model = prepare(`{def.modelBase}E{stage}`)
			if model then
				model.Parent = folder
				found += 1
			end
		end
		if found == 0 and def.released then
			warn(
				`GiantTemplates: no hay modelos "{def.modelBase}E1..E4" en ServerStorage; el cliente usará la orca teñida`
			)
		end
	end
	folder.Parent = ReplicatedStorage
end

return GiantTemplates
