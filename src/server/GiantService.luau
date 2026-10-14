--!strict
--[[
	GiantService

	Estado del gigante actual del servidor: quién es, cuánta hambre le queda
	y cuándo se llena. Publica ese estado como atributos de la carpeta
	ReplicatedStorage.EstadoGigante; los clientes dibujan y animan al gigante
	con esos datos (ver client/Giant/GiantView).

	El hambre se guarda como progreso (0..1): cada bocado avanza
	comida / def.food. La comida total de cada gigante es fija (no cambia con
	los jugadores conectados ni con su poder); la Orca es la más fácil.

	Hito H1: solo la Orca. Al llenarse queda satisfecha; la despedida y el
	paso al Minotauro son el hito H2.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local GiantStages = require(ReplicatedStorage.Shared.GiantStages)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Remotes = require(script.Parent.Remotes)

local GIANTS = Config.Giants
local ATTR = Protocol.GiantAttributes

local GiantService = {}

local stateFolder = Instance.new("Folder")
stateFolder.Name = Protocol.GiantStateFolder

local currentDef: Config.GiantDef
local progress = 0
local anger = 0
local lastFedAt = os.clock()
local center = Vector3.zero
local phase: Protocol.GiantPhase = "feeding"
local phaseEndsAt = 0
local filledListeners: { () -> () } = {}
local participants: { [number]: boolean } = {} -- userIds que le dieron de comer a este gigante

local function publish()
	stateFolder:SetAttribute(ATTR.Id, currentDef.id)
	stateFolder:SetAttribute(ATTR.DisplayName, currentDef.displayName)
	stateFolder:SetAttribute(ATTR.Article, currentDef.article)
	stateFolder:SetAttribute(ATTR.Multiplier, currentDef.multiplier)
	stateFolder:SetAttribute(ATTR.Progress, progress)
	stateFolder:SetAttribute(ATTR.Anger, anger)
	stateFolder:SetAttribute(ATTR.Phase, phase)
	stateFolder:SetAttribute(ATTR.PhaseEndsAt, phaseEndsAt)
end

function GiantService.init(map: Instance)
	local anchor = map:FindFirstChild(Protocol.Map.GiantAnchor, true)
	assert(
		anchor and anchor:IsA("BasePart"),
		"GiantService: falta la guarida del gigante en el mapa"
	)
	center = anchor.Position
	currentDef = GIANTS.chain[1]
	progress = 0
	publish()
	stateFolder.Parent = ReplicatedStorage
end

function GiantService.getCurrent(): Config.GiantDef
	return currentDef
end

-- Centro de la laguna: FeedingService valida distancias contra este punto.
function GiantService.getCenter(): Vector3
	return center
end

function GiantService.isFull(): boolean
	return progress >= 1
end

-- Solo en la fase "feeding" se le puede dar de comer (y puede enojarse).
function GiantService.isFeeding(): boolean
	return phase == "feeding" and progress < 1
end

function GiantService.getPhase(): Protocol.GiantPhase
	return phase
end

-- Cambia de fase; seconds = cuánto dura (para la cuenta regresiva de los clientes).
function GiantService.setPhase(nextPhase: Protocol.GiantPhase, seconds: number?)
	phase = nextPhase
	phaseEndsAt = if seconds then Workspace:GetServerTimeNow() + seconds else 0
	publish()
end

-- GiantCycle se entera aquí de que la barra llegó al 100 %.
function GiantService.onFilled(listener: () -> ())
	table.insert(filledListeners, listener)
end

-- Llega un gigante nuevo (o vuelve el mismo) con la barra en cero.
function GiantService.reset(def: Config.GiantDef)
	currentDef = def
	progress = 0
	anger = 0
	lastFedAt = os.clock()
	participants = {}
	publish()
end

-- Quienes le dieron de comer al gigante actual (para repartir las kills al llenarse).
function GiantService.getParticipants(): { number }
	local list = {}
	for userId in participants do
		table.insert(list, userId)
	end
	return list
end

-- Avanza la barra (fracción de la comida total) y avisa si se llenó.
local function advance(fraction: number, feeder: Player)
	progress = math.min(1, progress + fraction)
	participants[feeder.UserId] = true
	lastFedAt = os.clock()
	anger = 0
	publish()
	if progress >= 1 then
		for _, listener in filledListeners do
			task.spawn(listener)
		end
	end
end

-- Suma comida al gigante actual. El servidor ya validó quién y cuánto.
function GiantService.feed(food: number, feeder: Player, fishId: string)
	if food <= 0 or not GiantService.isFeeding() then
		return
	end
	Remotes.GiantFed:FireAllClients(feeder.UserId, food, fishId)
	advance(food / currentDef.food, feeder)
end

-- Compra con Robux: llena esa parte de la barra de una vez (1 = entero).
-- Devuelve false si ahora no está comiendo (GiantFill lo deja para después).
function GiantService.fill(fraction: number, buyer: Player): boolean
	if fraction <= 0 or not GiantService.isFeeding() then
		return false
	end
	advance(fraction, buyer)
	return true
end

-- Reinicia la cuenta del enojo (servidor vacío o gigante lleno).
function GiantService.calm()
	lastFedAt = os.clock()
	GiantService.setAnger(0)
end

-- Segundos desde el último bocado (GiantMood decide el enojo con esto).
function GiantService.secondsSinceFed(): number
	return os.clock() - lastFedAt
end

function GiantService.getAnger(): number
	return anger
end

function GiantService.setAnger(value: number)
	value = math.clamp(value, 0, 1)
	if value ~= anger then
		anger = value
		publish()
	end
end

-- Hambre que vuelve: la barra baja, pero nunca por debajo del inicio de la
-- etapa actual (el gigante no encoge).
function GiantService.starve(fraction: number)
	if fraction <= 0 or GiantService.isFull() then
		return
	end
	local floor = GIANTS.stageThresholds[GiantStages.stageFor(progress)]
	local nextProgress = math.max(floor, progress - fraction)
	if nextProgress ~= progress then
		progress = nextProgress
		publish()
	end
end

return GiantService
