--!strict
--[[
	GiantTemplates

	De dónde sale el modelo de cada etapa del gigante (<base>E1..E4 en
	GiantModelsFolder). Si un gigante todavía no tiene modelo (Meshy), usa
	el de la Orca teñido con su color (tint); si tampoco hay, el marcador de
	primitivas.
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

-- Color con que se tiñe la Orca cuando hace de otro gigante sin modelo.
local STAND_IN_TINTS: { [string]: Color3 } = {
	Minotauro = Color3.fromRGB(160, 95, 50),
	DragonMarino = Color3.fromRGB(60, 200, 110),
	ZorroDeAgua = Color3.fromRGB(70, 150, 255),
	OrcaFantasma = Color3.fromRGB(170, 110, 255), -- Halloween
}

local function ownTemplate(folder: Instance, base: string, stage: number): Model?
	for s = stage, 1, -1 do
		local template = folder:FindFirstChild(`{base}E{s}`)
		if template and template:IsA("Model") then
			return template
		end
	end
	return nil
end

-- Modelo de la etapa (o de la anterior más cercana). Sin modelo propio, el de
-- la Orca: el segundo valor es el color con que hay que teñirlo (nil = propio).
function GiantTemplates.templateFor(
	folder: Instance,
	def: Config.GiantDef,
	stage: number
): (Model?, Color3?)
	local own = ownTemplate(folder, def.modelBase, stage)
	if own then
		return own, nil
	end
	local orca = ownTemplate(folder, Config.Giants.chain[1].modelBase, stage)
	return orca, if orca then STAND_IN_TINTS[def.id] or Color3.new(1, 1, 1) else nil
end

-- Tiñe un modelo prestado (Highlight de relleno, sin contorno).
function GiantTemplates.tint(model: Model, color: Color3)
	local paint = Instance.new("Highlight")
	paint.Name = "Tinte"
	paint.FillColor = color
	paint.FillTransparency = 0.4
	paint.OutlineTransparency = 1
	paint.DepthMode = Enum.HighlightDepthMode.Occluded
	paint.Parent = model
end

return GiantTemplates
