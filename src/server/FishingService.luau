--!strict
--[[
	FishingService

	Pesca autoritativa. El cliente solo dice "recoger"; el servidor decide
	cuándo pica, si se llegó a tiempo y qué pez sale.

	Flujo por jugador:
		1. Pide lanzar (CastRequest) desde la orilla o un muelle; ShoreCast
		   valida el lugar y calcula dónde cae el corcho -> lanza ("casting").
		2. El corcho cae -> espera ("waiting"). Tras un tiempo aleatorio pica
		   ("bite") y el dueño ve el botón TIRA.
		3. El cliente manda ReelIn. Si llega dentro de la ventana (más un margen
		   por ping), se tira un pez de la tabla y van a la carga del jugador
		   tantos como dé su poder (FishingPower.fishPerCatch).
	El poder también acorta la espera hasta el pique (FishingPower.biteDelay).
		4. Si no llega, o el jugador se aleja, el pez se escapa. Nunca se pierde
		   nada que ya se llevaba.

	Además del aviso privado al dueño (FishingUpdate), el estado se publica en
	atributos del jugador para que TODOS los clientes animen su caña, el
	corcho y el pez que salta (ver client/Fishing/FishingVisuals).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local FishCatalog = require(ReplicatedStorage.Shared.FishCatalog)
local FishingPower = require(ReplicatedStorage.Shared.FishingPower)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Perks = require(ReplicatedStorage.Shared.Perks)
local PlayerData = require(script.Parent.PlayerData)
local Milestones = require(script.Parent.Retention.Milestones)
local RateLimit = require(script.Parent.RateLimit)
local Remotes = require(script.Parent.Remotes)
local ShoreCast = require(script.Parent.ShoreCast)

type Phase = "waiting" | "bite"
type Session = {
	castFrom: Vector3,
	phase: Phase,
	biteAt: number, -- os.clock() del momento en que picó
}

local FISHING = Config.Gameplay.fishing
local ATTR = Protocol.PlayerAttributes

local FishingService = {}

local sessions: { [Player]: Session } = {}
local lastCastAt: { [Player]: number } = {}
local rng = Random.new()

local function send(player: Player, state: Protocol.FishingState, detail: any?)
	Remotes.FishingUpdate:FireClient(player, state, detail)
end

local function setVisual(player: Player, state: Protocol.FishingVisualState)
	player:SetAttribute(ATTR.FishingState, state)
end

-- Muestra el resultado un momento y luego guarda la caña, si no volvió a lanzar.
local function showResult(player: Player, state: Protocol.FishingVisualState)
	setVisual(player, state)
	task.delay(FISHING.resultHoldSeconds, function()
		if not sessions[player] and player:GetAttribute(ATTR.FishingState) == state then
			setVisual(player, "idle")
		end
	end)
end

local function endSession(player: Player, state: Protocol.FishingState, detail: any?)
	sessions[player] = nil
	send(player, state, detail)
	showResult(player, if state == "caught" then "caught" else "escaped")
end

local function onBite(player: Player, session: Session)
	if sessions[player] ~= session then
		return -- la sesión terminó o fue reemplazada mientras esperaba
	end
	if not ShoreCast.stillThere(player, session.castFrom) then
		endSession(player, "cancelled")
		return
	end
	session.phase = "bite"
	session.biteAt = os.clock()
	setVisual(player, "bite")
	send(player, "bite", FISHING.reelWindowSeconds)

	task.delay(FISHING.reelWindowSeconds + FISHING.latencyGraceSeconds, function()
		if sessions[player] == session then
			endSession(player, "escaped")
		end
	end)
end

local function startCast(player: Player)
	if sessions[player] or player:GetAttribute(ATTR.FishingState) == "training" then
		return
	end
	if not PlayerData.isLoaded(player) then
		return -- sus datos aún no cargan: lo que pesque no tendría dónde guardarse
	end
	local now = os.clock()
	if now - (lastCastAt[player] or 0) < FISHING.castCooldownSeconds then
		return
	end
	local castFrom, target = ShoreCast.resolve(player)
	if not castFrom or not target then
		return
	end
	if not PlayerData.hasRoom(player) then
		send(player, "full", PlayerData.getCapacity(player))
		return
	end
	lastCastAt[player] = now

	local session: Session = { castFrom = castFrom, phase = "waiting", biteAt = 0 }
	sessions[player] = session
	player:SetAttribute(ATTR.FishingTarget, target)
	setVisual(player, "casting")
	send(player, "waiting", target)

	task.delay(FISHING.castSeconds, function()
		if sessions[player] == session and session.phase == "waiting" then
			setVisual(player, "waiting")
		end
	end)
	local baseDelay = rng:NextNumber(FISHING.biteDelayMinSeconds, FISHING.biteDelayMaxSeconds)
	local delaySeconds = FishingPower.biteDelay(baseDelay, PlayerData.getPower(player))
	-- El corcho tiene que llegar al agua antes de que pique.
	task.delay(math.max(delaySeconds, FISHING.castSeconds + 0.1), onBite, player, session)
end

-- ReelIn no lleva argumentos: cualquier cosa que mande el cliente se ignora.
local function onReelIn(player: Player)
	local session = sessions[player]
	if not session or session.phase ~= "bite" then
		return -- tirar antes de que pique no castiga: el botón ni siquiera se ve
	end
	if os.clock() - session.biteAt > FISHING.reelWindowSeconds + FISHING.latencyGraceSeconds then
		endSession(player, "escaped")
		return
	end
	local fish =
		FishCatalog.roll(rng, (Upgrades.current(player, "Rod").luck or 0) + Perks.luckBonus(player))
	local count = FishingPower.fishPerCatch(PlayerData.getPower(player))
	local before = PlayerData.read(player)
	local firstTime = before ~= nil and (before.species[fish.id] or 0) == 0
	local added = PlayerData.addFish(player, fish.id, count)
	if added == 0 then
		endSession(player, "full", PlayerData.getCapacity(player))
		return
	end
	player:SetAttribute(ATTR.FishingCatch, fish.id)
	player:SetAttribute(ATTR.FishingCatchCount, added)
	Milestones.caught(player, fish.id, added, firstTime)
	endSession(player, "caught", { id = fish.id, count = added })
end

-- Un ataque alcanzó al jugador: si estaba esperando o le picaba, ese pez se
-- escapa. Lo que lleva en la canasta no se toca.
function FishingService.interrupt(player: Player)
	if sessions[player] then
		endSession(player, "escaped")
	end
end

function FishingService.init()
	-- CastRequest no lleva argumentos: el servidor mira dónde está el jugador.
	Remotes.CastRequest.OnServerEvent:Connect(RateLimit.wrap("CastRequest", 4, 6, startCast))
	Remotes.ReelIn.OnServerEvent:Connect(RateLimit.wrap("ReelIn", 6, 8, onReelIn))
	Players.PlayerAdded:Connect(function(player: Player)
		setVisual(player, "idle")
	end)
	for _, player in Players:GetPlayers() do
		setVisual(player, "idle")
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		sessions[player] = nil
		lastCastAt[player] = nil
	end)
end

return FishingService
