--!strict
--[[
	TrainingPonds

	Los prompts de los estanques de entrenamiento: uno solo por estanque, en el
	centro de sus piezas (el sagrado tiene cuatro, una por esquina, y antes cada
	una tenía su prompt: el aviso saltaba de una a otra). El alcance llega a la
	pieza más lejana + promptDistanceStuds. Llevan el atributo Flotante: el
	cliente dibuja la placa flotando sobre el centro del estanque también en
	táctil (Interface/PromptView).
		build(map, onPrompt) -> { [indice]: { center, reach } }
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local FishingPower = require(ReplicatedStorage.Shared.FishingPower)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Proximity = require(script.Parent.Proximity)

export type Pond = { center: Vector3, reach: number }

local TRAINING = Config.Gameplay.training
local PONDS = Config.Progression.ponds

local TrainingPonds = {}

local function requirement(def: Config.PondDef): string
	return if def.robuxOnly
		then "Estanque sagrado · solo con Robux"
		elseif def.requiredKills > 0 then `Requiere {FishingPower.pondRequirement(def)}`
		else "Poder de pesca"
end

local function prompt(index: number, parts: { BasePart }, onPrompt: (Player, number) -> ()): Pond
	local def = PONDS[index]
	local center = Vector3.zero
	for _, part in parts do
		center += part.Position / #parts
	end
	local spread = 0
	for _, part in parts do
		spread = math.max(spread, (part.Position - center).Magnitude)
	end
	local pond = { center = center, reach = TRAINING.promptDistanceStuds + spread }
	local anchor = Instance.new("Attachment")
	anchor.Name = "CentroEntrenar"
	anchor.Parent = parts[1]
	anchor.WorldPosition = center
	local made =
		Proximity.makePrompt(anchor, `Entrenar x{def.multiplier}`, requirement(def), pond.reach)
	made:SetAttribute(Protocol.Map.PromptFloatAttribute, true)
	made.Triggered:Connect(function(player: Player)
		onPrompt(player, index)
	end)
	return pond
end

function TrainingPonds.build(map: Instance, onPrompt: (Player, number) -> ()): { [number]: Pond }
	local partsByPond: { [number]: { BasePart } } = {}
	for _, descendant in map:GetDescendants() do
		local index = descendant:GetAttribute(Protocol.Map.PondIndexAttribute)
		if
			descendant.Name == Protocol.Map.TrainingPond
			and descendant:IsA("BasePart")
			and type(index) == "number"
			and PONDS[index]
		then
			partsByPond[index] = partsByPond[index] or {}
			table.insert(partsByPond[index], descendant)
		end
	end
	local ponds = {}
	for index, parts in partsByPond do
		ponds[index] = prompt(index, parts, onPrompt)
	end
	return ponds
end

return TrainingPonds
