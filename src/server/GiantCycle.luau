--!strict
--[[
	GiantCycle

	Lo que pasa cuando la barra del gigante llega al 100 % (o cuando se
	cansa de esperar: Feeding/GiantTimeout, tras cycle.maxFeedMinutes):
		0. Kill: +1 a cada jugador que sigue conectado y le dio algo, aunque
		   sea un pez (GiantRewards.payKills). Si se cansó, todos ven el aviso.
		1. Despedida (farewell): los clientes lo ven saltar, girar y
		   sumergirse en el lago.
		2. Descanso (rest): el volcán se vacía y la guarida queda en el fondo (RestArena)
		   y durante el descanso (más largo con más jugadores: restLength, y
		   con los minutos que alguien compre: Monetization/RestTime),
		   cada segundo, todo jugador sobre ella gana
		   poder sin hacer nada:
		   powerPerTick x su mejor estanque desbloqueado x el multiplicador del
		   monstruo que se llenó (Orca x2, Minotauro x4, Dragón x10, Zorro x20).
		   Se ve como en los estanques ("+N poder").
		3. Ruleta: el que alguien eligió con Robux o, si nadie, al azar entre
		   los que GiantPool.candidates da por disponibles (lanzados, con
		   inRoulette y en sus fechas) según su rouletteWeight.
		4. Llegada (arriving): sale del agua con la barra en cero y, al
		   terminar, se le puede volver a dar de comer (feeding).
	Los peces que cada uno lleva en la canasta se conservan durante todo el ciclo.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local GiantPool = require(ReplicatedStorage.Shared.GiantPool)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local GiantPublish = require(script.Parent.Feeding.GiantPublish)
local GiantRewards = require(script.Parent.GiantRewards)
local GiantTimeout = require(script.Parent.Feeding.GiantTimeout)
local GiantService = require(script.Parent.GiantService)
local RateLimit = require(script.Parent.RateLimit)
local Remotes = require(script.Parent.Remotes)
local RestArena = require(script.Parent.RestArena)
local GiantChoice = require(script.Parent.Monetization.GiantChoice)
local RestTime = require(script.Parent.Monetization.RestTime)

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
	local candidates, total = GiantPool.candidates()
	local roll = rng:NextNumber(0, total)
	for _, def in candidates do
		roll -= def.rouletteWeight
		if roll <= 0 then
			return def, ""
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

-- Despedida, descanso y llegada del siguiente. tired = se cansó de esperar (GiantTimeout).
local function cycle(tired: boolean)
	local current = GiantService.getCurrent()
	local paid = GiantRewards.payKills(current.id) -- +1 kill a los que le dieron algo
	if tired then
		for _, player in Players:GetPlayers() do
			Remotes.Notice:FireClient(
				player,
				"giantLeft",
				current.displayName,
				paid[player.UserId] == true
			)
		end
	end
	GiantService.setPhase("farewell", CYCLE.farewellSeconds)
	task.wait(CYCLE.farewellSeconds)

	-- El volcán se vacía; con la guarida a la vista se esperan unos segundos y
	-- recién ahí empieza a contar el descanso (DescansoDesde).
	local restSeconds = restLength()
	local delay = CYCLE.drainSeconds + CYCLE.restDelaySeconds
	GiantPublish.set(ATTRS.RestFrom, Workspace:GetServerTimeNow() + delay)
	GiantService.setPhase("rest", delay + restSeconds)
	RestArena.show()
	task.wait(delay)
	local finish = os.clock() + restSeconds
	skipRest = false
	while os.clock() < finish and not skipRest do
		task.wait(TRAINING.tickSeconds)
		GiantRewards.restTick()
		local extra = RestTime.take() -- descanso comprado con Robux (RestTime)
		if extra > 0 then
			finish += extra
			GiantService.setPhase("rest", finish - os.clock())
		end
	end

	RestArena.hide()
	-- La ruleta gira en todos los clientes (Giant/RouletteView) y luego llega.
	local nextDef, buyer = chooseNext()
	GiantPublish.set(ATTRS.RouletteResult, nextDef.id)
	GiantPublish.set(ATTRS.RouletteBy, buyer)
	GiantPublish.set(ATTRS.RouletteAt, Workspace:GetServerTimeNow())
	GiantService.setPhase("rest", CYCLE.rouletteSeconds + CYCLE.refillSeconds)
	task.wait(CYCLE.rouletteSeconds)
	-- Primero se llena el cráter (agua, lava o arena, según el que sale) y después llega.
	GiantPublish.set(ATTRS.Refilling, true)
	task.wait(CYCLE.refillSeconds)
	GiantPublish.set(ATTRS.Refilling, false)
	GiantService.reset(nextDef)
	GiantService.setPhase("arriving", CYCLE.arrivalSeconds)
	task.wait(CYCLE.arrivalSeconds)
	GiantService.setPhase("feeding")
end

-- Si algo falla a mitad del ciclo, el servidor no puede quedar sin monstruo:
-- se trae el siguiente y se vuelve a comer.
local function run(tired: boolean?)
	if running then
		return
	end
	running = true
	local ok, problem: any = pcall(cycle, tired == true)
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
	GiantTimeout.start(function()
		run(true)
	end)
end

return GiantCycle
