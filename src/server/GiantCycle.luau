--!strict
--[[
	GiantCycle

	Lo que pasa cuando la barra del gigante llega al 100 %:
		0. Kill: +1 a cada jugador que sigue conectado y aportó al menos
		   scaling.minKillShare de la barra (GiantService.getParticipants).
		1. Despedida (farewell): los clientes lo ven saltar, girar y
		   sumergirse en el lago.
		2. Descanso (rest): emerge la guarida en el centro del lago (RestArena)
		   y durante el descanso (más largo con más jugadores: restLength),
		   cada segundo, todo jugador sobre ella gana
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
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local Perks = require(ReplicatedStorage.Shared.Perks)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local GiantPublish = require(script.Parent.Feeding.GiantPublish)
local GiantService = require(script.Parent.GiantService)
local PlayerData = require(script.Parent.PlayerData)
local Milestones = require(script.Parent.Retention.Milestones)
local Proximity = require(script.Parent.Proximity)
local RateLimit = require(script.Parent.RateLimit)
local Remotes = require(script.Parent.Remotes)
local RestArena = require(script.Parent.RestArena)
local GiantChoice = require(script.Parent.Monetization.GiantChoice)

local CYCLE = Config.Giants.cycle
local ATTRS = Protocol.GiantAttributes
local TRAINING = Config.Gameplay.training

local GiantCycle = {}

local running = false
local rng = Random.new()
local skipRest = false -- el panel de administrador corta el descanso
local forcedNext: Config.GiantDef? = nil -- y elige el siguiente (aunque no esté en la ruleta)

-- La ruleta: el que eligió el panel de administrador, el que alguien compró
-- (GiantChoice) o, si nadie, uno al azar entre los que pueden salir según su
-- peso. Devuelve también quién lo compró ("" si salió al azar).
local function chooseNext(): (Config.GiantDef, string)
	local forced = forcedNext
	if forced then
		forcedNext = nil
		return forced, ""
	end
	local chosen, buyer = GiantChoice.take()
	if chosen then
		return chosen, buyer or ""
	end
	local total = 0
	for _, def in Config.Giants.chain do
		total += if def.inRoulette then def.rouletteWeight else 0
	end
	local roll = rng:NextNumber(0, total)
	for _, def in Config.Giants.chain do
		if def.inRoulette then
			roll -= def.rouletteWeight
			if roll <= 0 then
				return def, ""
			end
		end
	end
	return GiantService.getCurrent(), ""
end

-- Descanso: restBaseSeconds + restPerPlayerSeconds por jugador conectado,
-- entre restMinSeconds y restSeconds (más gente = más tiempo en la guarida).
local function restLength(): number
	local seconds = CYCLE.restBaseSeconds + CYCLE.restPerPlayerSeconds * #Players:GetPlayers()
	return math.clamp(seconds, CYCLE.restMinSeconds, CYCLE.restSeconds)
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

-- Despedida, descanso y llegada del siguiente.
local function cycle()
	-- +1 kill a los que aportaron lo suficiente y siguen en el servidor.
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

	local restSeconds = restLength()
	GiantService.setPhase("rest", restSeconds)
	RestArena.show()
	local finish = os.clock() + restSeconds
	skipRest = false
	while os.clock() < finish and not skipRest do
		task.wait(TRAINING.tickSeconds)
		restTick()
	end

	RestArena.hide()
	-- La ruleta gira en todos los clientes (Giant/RouletteView) y luego llega.
	local nextDef, buyer = chooseNext()
	GiantPublish.set(ATTRS.RouletteResult, nextDef.id)
	GiantPublish.set(ATTRS.RouletteBy, buyer)
	GiantPublish.set(ATTRS.RouletteAt, Workspace:GetServerTimeNow())
	GiantService.setPhase("rest", CYCLE.rouletteSeconds)
	task.wait(CYCLE.rouletteSeconds)
	GiantService.reset(nextDef)
	GiantService.setPhase("arriving", CYCLE.arrivalSeconds)
	task.wait(CYCLE.arrivalSeconds)
	GiantService.setPhase("feeding")
end

-- Si algo falla a mitad del ciclo, el servidor no puede quedar sin monstruo:
-- se trae el siguiente y se vuelve a comer.
local function run()
	if running then
		return
	end
	running = true
	local ok, problem: any = pcall(cycle)
	if not ok then
		warn(`GiantCycle: falló el ciclo ({problem}); se trae el siguiente monstruo`)
		pcall(RestArena.hide)
		pcall(function()
			GiantService.reset((chooseNext()))
			GiantService.setPhase("feeding")
		end)
	end
	running = false
end

-- Panel de administrador: termina el descanso ya y elige el siguiente monstruo.
function GiantCycle.skipRest()
	skipRest = true
end

function GiantCycle.setNext(def: Config.GiantDef)
	forcedNext = def
end

function GiantCycle.init(map: Instance)
	RestArena.init(map)
	-- Botón "Ir a la guarida" del descanso.
	Remotes.RestEnter.OnServerEvent:Connect(
		RateLimit.wrap("RestEnter", 1, 2, function(player: Player)
			if GiantService.getPhase() == "rest" then
				RestArena.enter(player)
			end
		end)
	)
	GiantService.onFilled(run)
end

return GiantCycle
