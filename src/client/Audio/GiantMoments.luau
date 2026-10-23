--!strict
--[[
	GiantMoments

	La voz de cada gigante en los momentos de su ciclo, que antes sonaban
	igual para todos (el mismo rugido): llega, se despide, tiene hambre, se
	enfurece, se calma y evoluciona (la orca; los demás evolucionan con su
	pose y sus propias recetas). Las capas de cada momento están en
	GiantMomentRecipes, por edad: la cría suena a cría y la etapa final suma
	lo grave. Dentro de cada edad el tono baja un poco por etapa (AGE_PITCH).

	Sin lugar (top = nil) suena para todos sin posición, como los avisos del
	panel de hambre.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GiantStages = require(ReplicatedStorage.Shared.GiantStages)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local GiantMomentRecipes = require(script.Parent.GiantMomentRecipes)
local Sounds = require(script.Parent.Sounds)
-- Cargan los volúmenes y alcances de las claves de cada especie (Sounds.define).
require(script.Parent.OrcaVoces)
require(script.Parent.MinoVoces)
require(script.Parent.DragonVoces)
require(script.Parent.ZorroVoces)

type Layer = GiantMomentRecipes.Layer

local AGE_PITCH = { 1.1, 1, 1.05, 0.92 } -- E1 más agudo que E2; E4 más grave que E3

local GiantMoments = {}

local function plays(layer: Layer, stage: number): boolean
	local age = layer.age
	if age == "young" then
		return stage <= 2
	elseif age == "adult" then
		return stage >= 3
	elseif age == "final" then
		return stage >= GiantStages.count
	end
	return true
end

-- El gigante de ahora y su etapa (EstadoGigante).
function GiantMoments.current(): (string, number)
	local state = ReplicatedStorage:FindFirstChild(Protocol.GiantStateFolder)
	local id = state and state:GetAttribute(Protocol.GiantAttributes.Id)
	local progress = state and state:GetAttribute(Protocol.GiantAttributes.Progress)
	local stage = GiantStages.stageFor(if type(progress) == "number" then progress else 0)
	return if type(id) == "string" then id else "default", stage
end

-- Suena el momento de este gigante. top: su cabeza; water: el agua (o el
-- suelo) debajo. Sin top, todo sin posición.
function GiantMoments.play(
	moment: string,
	giantId: string,
	stage: number,
	top: Vector3?,
	water: Vector3?
)
	local recipes = GiantMomentRecipes[giantId] or GiantMomentRecipes.default
	local recipe = recipes[moment] or GiantMomentRecipes.default[moment]
	if not recipe then
		return
	end
	local tone = AGE_PITCH[math.clamp(stage, 1, #AGE_PITCH)]
	for _, layer in recipe do
		if plays(layer, stage) then
			local position = if top and layer.at == "water" then water or top else top
			local pitch = (layer.pitch or 1) * tone
			if layer.delay then
				task.delay(layer.delay, Sounds.play, layer.key, position, pitch, layer.volume)
			else
				Sounds.play(layer.key, position, pitch, layer.volume)
			end
		end
	end
end

-- El momento del gigante actual (para los avisos sin cuerpo a mano).
function GiantMoments.playCurrent(moment: string, top: Vector3?, water: Vector3?)
	local id, stage = GiantMoments.current()
	GiantMoments.play(moment, id, stage, top, water)
end

return table.freeze(GiantMoments)
