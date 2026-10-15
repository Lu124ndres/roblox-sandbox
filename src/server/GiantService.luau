--!strict
--[[
	GiantService

	Estado del gigante actual: quién es, cuánta hambre le queda y cuándo se
	llena, publicado en ReplicatedStorage.EstadoGigante (Feeding/GiantPublish;
	Progress con freno, al instante al cruzar una etapa o llenarse).

	El hambre es un progreso (0..1): cada lote avanza comida / total. El total
	(atributo Food) es la comida fija de cada gigante (Config). Lo comido se anuncia
	por lotes (Feeding/FedBroadcast) y se anota por jugador (Contributions).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local GiantStages = require(ReplicatedStorage.Shared.GiantStages)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Contributions = require(script.Parent.Feeding.Contributions)
local FedBroadcast = require(script.Parent.Feeding.FedBroadcast)
local GiantAnger = require(script.Parent.Feeding.GiantAnger)
local GiantPublish = require(script.Parent.Feeding.GiantPublish)

local GIANTS = Config.Giants
local ATTR = Protocol.GiantAttributes
local FULL_EPSILON = 1e-9 -- error de coma flotante que ya cuenta como lleno

local GiantService = {}

local currentDef: Config.GiantDef
local progress = 0
local totalFood = 1
local center = Vector3.zero
local phase: Protocol.GiantPhase = "feeding"
local phaseEndsAt = 0
local filledListeners: { () -> () } = {}

local function publish()
	GiantPublish.set(ATTR.Id, currentDef.id)
	GiantPublish.set(ATTR.DisplayName, currentDef.displayName)
	GiantPublish.set(ATTR.Article, currentDef.article)
	GiantPublish.set(ATTR.Multiplier, currentDef.multiplier)
	GiantPublish.set(ATTR.Food, totalFood)
	GiantPublish.set(ATTR.Anger, GiantAnger.get())
	GiantPublish.set(ATTR.Phase, phase)
	GiantPublish.set(ATTR.PhaseEndsAt, phaseEndsAt)
	GiantPublish.progress(progress, true)
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
	totalFood = currentDef.food
	publish()
	GiantPublish.show()
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

-- Comida que le falta para llenarse (FeedingService no saca más peces que esto).
function GiantService.remainingFood(): number
	return math.max(0, (1 - progress) * totalFood)
end

function GiantService.getPhase(): Protocol.GiantPhase
	return phase
end

-- Cambia de fase; seconds = cuánto dura (para la cuenta regresiva de los clientes).
function GiantService.setPhase(nextPhase: Protocol.GiantPhase, seconds: number?)
	phase = nextPhase
	phaseEndsAt = if seconds then Workspace:GetServerTimeNow() + seconds else 0
	GiantPublish.set(ATTR.Phase, phase)
	GiantPublish.set(ATTR.PhaseEndsAt, phaseEndsAt)
end

-- GiantCycle se entera aquí de que la barra llegó al 100 %.
function GiantService.onFilled(listener: () -> ())
	table.insert(filledListeners, listener)
end

-- Llega un gigante nuevo (o vuelve el mismo) con la barra en cero y su comida fija.
function GiantService.reset(def: Config.GiantDef)
	currentDef = def
	progress = 0
	totalFood = def.food
	GiantAnger.calm()
	Contributions.reset()
	publish()
end

-- Quienes le dieron algo (se llevan la kill; con un pez basta).
function GiantService.getParticipants(): { number }
	return Contributions.participants()
end

-- Enojo (GiantMood lo decide; ver Feeding/GiantAnger). calm = enojo a cero y
-- la cuenta del hambre empieza de nuevo (servidor vacío, gigante lleno, comió).
GiantService.getAnger = GiantAnger.get
GiantService.setAnger = GiantAnger.set
GiantService.calm = GiantAnger.calm
GiantService.secondsSinceFed = GiantAnger.secondsSinceFed

-- Avanza la barra (fracción de la comida total) y avisa si se llenó.
local function advance(fraction: number, userId: number, food: number)
	local stageBefore = GiantStages.stageFor(progress)
	progress = math.min(1, progress + fraction)
	if progress >= 1 - FULL_EPSILON then
		progress = 1
	end
	Contributions.add(userId, food)
	Contributions.publish(totalFood)
	GiantAnger.calm()
	GiantPublish.progress(progress, progress >= 1 or GiantStages.stageFor(progress) > stageBefore)
	if progress >= 1 then
		for _, listener in filledListeners do
			task.spawn(listener)
		end
	end
end

-- Suma un lote al gigante actual: `count` peces con `food` de comida en total
-- (fishId = la especie más rara, para el efecto). El servidor ya validó quién y cuánto.
function GiantService.feed(food: number, feeder: Player, count: number, fishId: string)
	if food <= 0 or not GiantService.isFeeding() then
		return
	end
	FedBroadcast.add(feeder.UserId, count, fishId)
	advance(food / totalFood, feeder.UserId, food)
end

-- Compra con Robux: llena esa parte de la barra de una vez (1 = entero).
-- Devuelve false si ahora no está comiendo (GiantFill lo deja para después).
function GiantService.fill(fraction: number, buyer: Player): boolean
	if fraction <= 0 or not GiantService.isFeeding() then
		return false
	end
	advance(fraction, buyer.UserId, fraction * totalFood)
	return true
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
		GiantPublish.progress(progress, false)
	end
end

return GiantService
