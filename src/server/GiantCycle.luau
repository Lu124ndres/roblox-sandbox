--!strict
--[[
	GiantCycle

	Lo que pasa cuando la barra del gigante llega al 100 %:
		0. Kill: +1 a cada jugador que le dio de comer y sigue conectado.
		1. Despedida (farewell): los clientes lo ven saltar, girar y
		   sumergirse en el lago.
		2. Descanso (rest): emerge la guarida en el centro del lago (RestArena)
		   y durante restSeconds, cada segundo, todo jugador sobre ella gana
		   poder sin hacer nada:
		   powerPerTick x su mejor estanque desbloqueado x restTrainingMultiplier.
		   Se ve como en los estanques ("+N poder").
		3. Ruleta: el que alguien eligió con Robux o, si nadie, al azar entre
		   los gigantes con inRoulette (por ahora solo la Orca).
		4. Llegada (arriving): sale del agua con la barra en cero y, al
		   terminar, se le puede volver a dar de comer (feeding).
	Los peces que cada uno lleva en la canasta se conservan durante todo el ciclo.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local Perks = require(ReplicatedStorage.Shared.Perks)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local GiantService = require(script.Parent.GiantService)
local PlayerData = require(script.Parent.PlayerData)
local Milestones = require(script.Parent.Retention.Milestones)
local Proximity = require(script.Parent.Proximity)
local Remotes = require(script.Parent.Remotes)
local RestArena = require(script.Parent.RestArena)
local GiantChoice = require(script.Parent.Monetization.GiantChoice)

local CYCLE = Config.Giants.cycle
local TRAINING = Config.Gameplay.training

local GiantCycle = {}

local running = false
local rng = Random.new()

-- La ruleta: el que alguien eligió con Robux (GiantChoice) o, si nadie, al azar
-- entre los que pueden salir. Sin candidatos, vuelve el actual.
local function chooseNext(): Config.GiantDef
	local chosen = GiantChoice.take()
	if chosen then
		return chosen
	end
	local candidates = {}
	for _, def in Config.Giants.chain do
		if def.inRoulette then
			table.insert(candidates, def)
		end
	end
	if #candidates == 0 then
		return GiantService.getCurrent()
	end
	return candidates[rng:NextInteger(1, #candidates)]
end

local function restTick()
	for _, player in Players:GetPlayers() do
		local root = Proximity.getRoot(player)
		if root and PlayerData.isLoaded(player) and WorldZones.isInRestArena(root.Position) then
			local best = Perks.bestPondMultiplier(player)
			local rod = Upgrades.current(player, "Rod").value
			local gained = math.round(
				TRAINING.powerPerTick
					* best
					* CYCLE.restTrainingMultiplier
					* rod
					* Perks.powerMultiplier(player)
			)
			PlayerData.addPower(player, gained)
			Remotes.TrainingTick:FireClient(player, gained)
		end
	end
end

local function run()
	if running then
		return
	end
	running = true
	-- +1 kill a todos los que le dieron de comer y siguen en el servidor.
	local giantId = GiantService.getCurrent().id
	for _, userId in GiantService.getParticipants() do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			PlayerData.addKill(player, giantId)
			Milestones.killed(player)
		end
	end
	GiantService.setPhase("farewell", CYCLE.farewellSeconds)
	task.wait(CYCLE.farewellSeconds)

	GiantService.setPhase("rest", CYCLE.restSeconds)
	RestArena.show()
	local finish = os.clock() + CYCLE.restSeconds
	while os.clock() < finish do
		task.wait(TRAINING.tickSeconds)
		restTick()
	end

	RestArena.hide()
	GiantService.reset(chooseNext())
	GiantService.setPhase("arriving", CYCLE.arrivalSeconds)
	task.wait(CYCLE.arrivalSeconds)
	GiantService.setPhase("feeding")
	running = false
end

function GiantCycle.init(map: Instance)
	RestArena.init(map)
	GiantService.onFilled(run)
end

return GiantCycle
