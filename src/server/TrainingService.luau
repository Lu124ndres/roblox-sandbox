--!strict
--[[
	TrainingService

	Zona de entrenamiento: 10 estanques alrededor del centro de la isla. Con
	el ProximityPrompt (E) el jugador se pone a pescar en el estanque sin hacer
	nada (AFK) y cada segundo gana poder de pesca: powerPerTick x multiplicador
	del estanque x su caña (tienda). Vuelve a apretar E, se aleja o se pone a pescar en el mar y
	deja de entrenar.

	Los estanques mejores piden un mínimo de poder (Config.Progression.ponds)
	o comprarlos con Robux; los pases y el x2 del servidor multiplican (Perks).
	Caben todos los que quieran en el mismo estanque (servidores de 40-50):
	cada uno lanza su corcho hacia el agua frente a él, no al mismo punto.
	El poder hace pescar más peces y más rápido (Shared/FishingPower).

	El servidor no confía en el ProximityPrompt: al empezar y en cada tick
	el jugador tiene que estar a promptDistanceStuds + PROMPT_SLACK_STUDS
	del estanque. Se puede empezar justo después de pescar (estados "caught"
	y "escaped": el pez de la mano aún se está mostrando).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local Perks = require(ReplicatedStorage.Shared.Perks)
local PlayerData = require(script.Parent.PlayerData)
local Quests = require(script.Parent.Retention.Quests)
local Milestones = require(script.Parent.Retention.Milestones)
local Proximity = require(script.Parent.Proximity)
local Remotes = require(script.Parent.Remotes)

type Session = { pond: number, origin: Vector3, part: BasePart }

local TRAINING = Config.Gameplay.training
local PONDS = Config.Progression.ponds
local ATTR = Protocol.PlayerAttributes
local PROMPT_SLACK_STUDS = 4 -- margen sobre el alcance del prompt (ping y borde del estanque)
-- Estados de pesca desde los que se puede empezar a entrenar.
local FREE_STATES: { [string]: boolean } = { idle = true, caught = true, escaped = true }

local TrainingService = {}

local sessions: { [Player]: Session } = {}

function TrainingService.isTraining(player: Player): boolean
	return sessions[player] ~= nil
end

function TrainingService.stop(player: Player)
	if not sessions[player] then
		return
	end
	sessions[player] = nil
	player:SetAttribute(ATTR.TrainingPond, 0)
	player:SetAttribute(ATTR.FishingState, "idle")
end

-- Punto del agua entre el jugador y el centro del estanque: cada quien pesca
-- frente a sí y los corchos no se amontonan en el centro.
local function targetFor(position: Vector3, pond: number): Vector3
	local center = WorldZones.pondCenter(pond)
	local offset = Vector3.new(position.X - center.X, 0, position.Z - center.Z)
	if offset.Magnitude < 0.5 then
		return center
	end
	return center + offset.Unit * WorldZones.pondRadius(pond) * 0.45
end

local function nearPond(player: Player, part: BasePart): boolean
	return Proximity.isNear(player, part, TRAINING.promptDistanceStuds + PROMPT_SLACK_STUDS)
end

local function start(player: Player, pond: number, part: BasePart)
	local root = Proximity.getRoot(player)
	if not root or not PlayerData.isLoaded(player) or not nearPond(player, part) then
		return
	end
	local def = PONDS[pond]
	if not Perks.pondOpen(player, pond) then
		Remotes.TrainingDenied:FireClient(player, "locked", def.requiredKills, pond)
		return
	end
	local state = player:GetAttribute(ATTR.FishingState)
	if state ~= nil and not FREE_STATES[state :: string] then
		Remotes.TrainingDenied:FireClient(player, "busy")
		return
	end
	sessions[player] = { pond = pond, origin = root.Position, part = part }
	player:SetAttribute(ATTR.TrainingPond, pond)
	player:SetAttribute(ATTR.FishingTarget, targetFor(root.Position, pond))
	player:SetAttribute(ATTR.FishingState, "training")
end

local function onPrompt(player: Player, pond: number, part: BasePart)
	local current = sessions[player]
	TrainingService.stop(player)
	if not current or current.pond ~= pond then
		start(player, pond, part)
	end
end

local function tick()
	for player, session in sessions do
		if
			not Proximity.isNearPoint(player, session.origin, TRAINING.maxDriftStuds)
			or not nearPond(player, session.part)
		then
			TrainingService.stop(player)
		else
			local rod = Upgrades.current(player, "Rod").value
			local gained = math.round(
				TRAINING.powerPerTick
					* PONDS[session.pond].multiplier
					* rod
					* Perks.powerMultiplier(player)
			)
			PlayerData.addPower(player, gained)
			Remotes.TrainingTick:FireClient(player, gained)
			Milestones.trained(player, session.pond)
			Quests.add(player, "train", TRAINING.tickSeconds)
		end
	end
end

function TrainingService.init(map: Instance)
	local count = 0
	for _, descendant in map:GetDescendants() do
		local index = descendant:GetAttribute(Protocol.Map.PondIndexAttribute)
		if
			descendant.Name == Protocol.Map.TrainingPond
			and descendant:IsA("BasePart")
			and type(index) == "number"
		then
			local def = PONDS[index]
			if def then
				local requirement = if def.robuxOnly
					then "Estanque sagrado · solo con Robux"
					elseif
						def.requiredKills > 0
					then `Requiere {def.requiredKills} {if def.requiredKills == 1
						then "monstruo llenado"
						else "monstruos llenados"}`
					else "Poder de pesca"
				local prompt = Proximity.makePrompt(
					descendant,
					`Entrenar x{def.multiplier}`,
					requirement,
					TRAINING.promptDistanceStuds
				)
				prompt.Triggered:Connect(function(player: Player)
					onPrompt(player, index, descendant)
				end)
				count += 1
			end
		end
	end
	assert(count > 0, "TrainingService: no hay estanques en el mapa")

	task.spawn(function()
		while true do
			task.wait(TRAINING.tickSeconds)
			tick()
		end
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		sessions[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		player:SetAttribute(ATTR.TrainingPond, 0)
	end
	Players.PlayerAdded:Connect(function(player: Player)
		player:SetAttribute(ATTR.TrainingPond, 0)
	end)
end

return TrainingService
