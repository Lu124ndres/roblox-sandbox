--!strict
--[[
	GiantTemplates

	De dónde sale el modelo de cada etapa del gigante (<base>E1..E4 en
	GiantModelsFolder) y el marcador de primitivas cuando falta.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local GiantTemplates = {}

-- Marcador de primitivas y su alto base.
function GiantTemplates.placeholder(): (Model, number)
	local model = Instance.new("Model")
	local function ball(name: string, size: number, offset: Vector3, color: Color3)
		local part = Instance.new("Part")
		part.Name = name
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.one * size
		part.CFrame = CFrame.new(offset)
		part.Color = color
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.Parent = model
	end
	ball("Cuerpo", 4, Vector3.new(0, 2, 0), Color3.fromRGB(52, 66, 92))
	ball("Panza", 2.6, Vector3.new(0, 1.6, -0.9), Color3.fromRGB(244, 246, 250))
	ball("Aleta", 1.4, Vector3.new(0, 4.1, 0.4), Color3.fromRGB(52, 66, 92))
	model.WorldPivot = CFrame.new()
	return model, 4
end

-- Modelo de la etapa o, si falta, el de la etapa anterior más cercana.
function GiantTemplates.templateFor(folder: Instance, def: Config.GiantDef, stage: number): Model?
	for s = stage, 1, -1 do
		local template = folder:FindFirstChild(`{def.modelBase}E{s}`)
		if template and template:IsA("Model") then
			return template
		end
	end
	return nil
end

return GiantTemplates
