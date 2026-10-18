--!strict
--[[
	FeedPool

	Los peces que vuelan a la boca del gigante se reusan: armar un pez
	(FishModel.build, una docena de piezas, más su estela) en cada lanzamiento
	y destruirlo al llegar daba tirones con 10 peces por segundo. Acá quedan
	guardados por especie, escondidos lejos y con la estela apagada; `take`
	devuelve uno listo y `give` lo guarda otra vez. Solo efecto visual.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local FishCatalog = require(ReplicatedStorage.Shared.FishCatalog)
local FishModel = require(script.Parent.Parent.Effects.FishModel)
local FeedPop = require(script.Parent.FeedPop)

local SCALE = 1.4
local KEEP = 12 -- peces guardados por especie como mucho
local HIDDEN = CFrame.new(0, -2000, 0)

local FeedPool = {}

local pools: { [string]: { Model } } = {}
local folder = Instance.new("Folder")
folder.Name = "PecesVolando"
folder.Parent = Workspace

local function trailOf(model: Model): Trail?
	local body = model.PrimaryPart
	return body and body:FindFirstChildOfClass("Trail")
end

-- Un pez de la especie `fishId` (o una sardina si no existe), puesto en `at`.
function FeedPool.take(fishId: string, at: CFrame): Model
	local id = if FishCatalog.get(fishId) then fishId else "Sardina"
	local pool = pools[id]
	local model = pool and table.remove(pool)
	if not model then
		model = FishModel.build(id, SCALE)
		FeedPop.trail(model, FeedPop.color(id))
		model:SetAttribute("Especie", id)
		model.Parent = folder
	end
	model:PivotTo(at)
	local trail = trailOf(model)
	if trail then
		trail:Clear() -- sin la raya desde donde estaba escondido
		trail.Enabled = true
	end
	return model
end

-- Lo guarda para la próxima (o lo destruye si ya hay muchos de esa especie).
function FeedPool.give(model: Model)
	local id = model:GetAttribute("Especie")
	if type(id) ~= "string" then
		model:Destroy()
		return
	end
	local pool = pools[id] or {}
	pools[id] = pool
	if #pool >= KEEP then
		model:Destroy()
		return
	end
	local trail = trailOf(model)
	if trail then
		trail.Enabled = false
	end
	model:PivotTo(HIDDEN)
	table.insert(pool, model)
end

return FeedPool
