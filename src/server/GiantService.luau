--!strict
--[[
	GiantService

	Estado del gigante actual: quién es, cuánta hambre le queda y cuándo se
	llena, publicado en ReplicatedStorage.EstadoGigante (Feeding/GiantPublish;
	Progress con freno, al instante al cruzar una etapa o llenarse).

	El hambre es un progreso (0..1): cada lote avanza comida / total. El total
	(atributo Food) se calcula al llegar según el servidor (Feeding/GiantFood). Lo comido se anuncia
	por lotes (Feeding/FedBroadcast) y se anota por jugador (Contributions).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local GiantStages = require(ReplicatedStorage.Shared.GiantStages)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Contributions = require(script.Parent.Feeding.Contributions)
local FedBroadcast = require(script.Parent.Feeding.FedBroadcast)
local GiantFood = require(script.Parent.Feeding.GiantFood)
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
local evolvingUntil = 0 -- os.clock(): hasta entonces evoluciona y no come

local function publish()
	GiantPublish.set(ATTR.Id, currentDef.id)
	GiantPublish.set(ATTR.DisplayName, currentDef.displayName)
	GiantPublish.set(ATTR.Article, currentDef.article)
	GiantPublish.set(ATTR.Multiplier, currentDef.multiplier)
	GiantPublish.set(ATTR.Food, totalFood)
	GiantPublish.set(ATTR.Anger, GiantAnger.get())
	GiantPublish.set(ATTR.Phase, phase)
	GiantPublish.set(ATTR.PhaseEndsAt, phaseEndsAt)
	GiantPublish.set(ATTR.EvolvingUntil, 0)
	GiantPublish.progress(progress, true)
end

function GiantService.init(map: Instance)
	local anchor = map:FindFirstChild(Protocol.Map.GiantAnchor, true)
	assert(anchor and anchor:IsA("BasePart"), "GiantService: falta la guarida")
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

-- Comida total que pide la barra del monstruo actual.
function GiantService.getFood(): number
	return totalFood
end

function GiantService.isFull(): boolean
	return progress >= 1
end

-- Evolucionando: acaba de llenar un cuarto de barra y no come por unos segundos.
function GiantService.isEvolving(): boolean
	return os.clock() < evolvingUntil
end

-- Solo en la fase "feeding" y sin evolucionar se le puede dar de comer (y puede enojarse).
function GiantService.isFeeding(): boolean
	return phase == "feeding" and progress < 1 and not GiantService.isEvolving()
end

-- Fin de la etapa actual (0.25, 0.5, 0.75 o 1).
local function stageEnd(): number
	return GIANTS.stageThresholds[GiantStages.stageFor(progress) + 1] or 1
end

-- Comida que le falta para terminar la etapa (FeedingService no saca más peces que esto).
function GiantService.remainingFood(): number
	return math.max(0, (stageEnd() - progress) * totalFood)
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

-- Llega un gigante con su comida (GiantFood) y la barra en cero (o en la etapa `stage`: admin).
function GiantService.reset(def: Config.GiantDef, stage: number?)
	currentDef = def
	progress = GIANTS.stageThresholds[stage or 1] or 0
	totalFood = GiantFood.forGiant(def)
	evolvingUntil = 0
	GiantAnger.calm()
	Contributions.reset()
	publish()
end

-- Quienes le dieron algo (se llevan la kill; con un pez basta).
function GiantService.getParticipants(): { number }
	return Contributions.participants()
end

-- Enojo (GiantMood lo decide; Feeding/GiantAnger). calm = enojo a cero y hambre de nuevo.
GiantService.getAnger = GiantAnger.get
GiantService.setAnger = GiantAnger.set
GiantService.calm = GiantAnger.calm
GiantService.secondsSinceFed = GiantAnger.secondsSinceFed

-- Avanza la barra (fracción de la comida total) y avisa si se llenó. Comiendo
-- peces no pasa del fin de la etapa (capped); al cruzar una etapa evoluciona.
local function advance(fraction: number, userId: number, food: number, capped: boolean)
	local stageBefore = GiantStages.stageFor(progress)
	local limit = if capped then stageEnd() else 1
	progress = math.min(limit, progress + fraction)
	if progress >= limit - FULL_EPSILON then
		progress = limit
	end
	if progress < 1 and GiantStages.stageFor(progress) > stageBefore then
		local seconds = GIANTS.cycle.evolveSeconds
		evolvingUntil = os.clock() + seconds
		GiantPublish.set(ATTR.EvolvingUntil, Workspace:GetServerTimeNow() + seconds)
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

-- Suma al gigante actual: `count` peces que se ven volar (fishId = la especie más rara,
-- para el efecto) y `food` de comida que entra a la barra. El servidor ya validó quién y
-- cuánto.
function GiantService.feed(food: number, feeder: Player, count: number, fishId: string)
	if not GiantService.isFeeding() then
		return
	end
	FedBroadcast.add(feeder.UserId, count, fishId)
	if food > 0 then
		advance(food / totalFood, feeder.UserId, food, true)
	end
end

-- Robux o ruleta: llena esa parte de la barra (false si no come; GiantFill espera).
function GiantService.fill(fraction: number, buyer: Player): boolean
	if fraction <= 0 or not GiantService.isFeeding() then
		return false
	end
	advance(fraction, buyer.UserId, fraction * totalFood, false)
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
