--!strict
--[[
	FishingService

	Pesca autoritativa. El cliente solo dice "recoger"; el servidor decide
	cuándo pica, si se llegó a tiempo y qué pez sale.

	Flujo por jugador:
		1. Pide lanzar (CastRequest) desde la playa; ShoreCast
		   valida el lugar y calcula dónde cae el corcho -> lanza ("casting").
		2. El corcho cae -> espera ("waiting"). Tras un tiempo aleatorio (más
		   corto con poder y con los pases con traje) pica ("bite"): ahí se
		   decide el pez y empieza el minijuego de recoger (ReelFight).
		3. Cada ReelIn es un toque que sube la barra; el pez la baja solo. Si
		   se llena, van a la carga tantos peces como dé su poder
		   (FishingPower.fishPerCatch). Los legendarios o mejores se anuncian
		   a todo el servidor.
		4. Si la barra se vacía, se acaba el tiempo o el jugador se aleja, el
		   pez se escapa. Nunca se pierde nada que ya se llevaba.

	Además del aviso privado al dueño (FishingUpdate), el estado se publica en
	atributos del jugador para que TODOS los clientes animen su caña, el
	corcho y el pez que salta (ver client/Fishing/FishingVisuals).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local FishCatalog = require(ReplicatedStorage.Shared.FishCatalog)
local FishingPower = require(ReplicatedStorage.Shared.FishingPower)
local LuckOdds = require(ReplicatedStorage.Shared.LuckOdds)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Perks = require(ReplicatedStorage.Shared.Perks)
local FishLanding = require(script.Parent.FishLanding)
local PlayerData = require(script.Parent.PlayerData)
local RateLimit = require(script.Parent.RateLimit)
local ReelFight = require(script.Parent.ReelFight)
local Remotes = require(script.Parent.Remotes)
local ShoreCast = require(script.Parent.ShoreCast)

type Session = {
	castFrom: Vector3,
	fight: ReelFight.Fight?, -- nil mientras espera; el minijuego al picar
	fish: Config.FishDef?,
	rarityIndex: number,
}

local CHECK_SECONDS = 0.25 -- cada cuánto se revisa si el pez ya se escapó
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

-- Mientras pelea: si la barra se vacía, se acaba el tiempo o se aleja, se escapa.
local function watchFight(player: Player, session: Session, fight: ReelFight.Fight)
	while sessions[player] == session do
		task.wait(CHECK_SECONDS)
		if sessions[player] ~= session then
			return
		elseif not ShoreCast.stillThere(player, session.castFrom) then
			endSession(player, "cancelled")
		elseif ReelFight.update(fight, os.clock()) then
			endSession(player, "escaped")
		end
	end
end

local function onBite(player: Player, session: Session)
	if sessions[player] ~= session then
		return -- la sesión terminó o fue reemplazada mientras esperaba
	end
	if not ShoreCast.stillThere(player, session.castFrom) then
		endSession(player, "cancelled")
		return
	end
	local fish = FishCatalog.roll(rng, LuckOdds.total(player)) -- la misma suerte que muestra el cliente
	local rarity, rarityIndex = FishCatalog.rarity(fish.id)
	local strength = ReelFight.strength(Upgrades.level(player, "Rod"), Perks.reelStrength(player))
	local fight = ReelFight.new(rarityIndex, strength, Perks.instantReel(player), os.clock())
	session.fight, session.fish, session.rarityIndex = fight, fish, rarityIndex
	setVisual(player, "bite")
	local params: { [string]: any } = ReelFight.params(fight)
	params.rarity = rarity.id
	send(player, "bite", params)
	task.spawn(watchFight, player, session, fight)
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

	local session: Session = { castFrom = castFrom, rarityIndex = 1 }
	sessions[player] = session
	player:SetAttribute(ATTR.FishingTarget, target)
	setVisual(player, "casting")
	send(player, "waiting", target)

	task.delay(FISHING.castSeconds, function()
		if sessions[player] == session and not session.fight then
			setVisual(player, "waiting")
		end
	end)
	local baseDelay = rng:NextNumber(FISHING.biteDelayMinSeconds, FISHING.biteDelayMaxSeconds)
	local delaySeconds = FishingPower.biteDelay(baseDelay, PlayerData.getPower(player))
		* Perks.biteDelayMultiplier(player)
	-- El corcho tiene que llegar al agua antes de que pique.
	task.delay(math.max(delaySeconds, FISHING.castSeconds + 0.1), onBite, player, session)
end

-- ReelIn es un toque y no lleva argumentos: cualquier cosa que mande el cliente se ignora.
local function onReelIn(player: Player)
	local session = sessions[player]
	local fight = session and session.fight
	local fish = session and session.fish
	if not session or not fight or not fish then
		return -- tocar antes de que pique no castiga: el botón ni siquiera se ve
	end
	local result = ReelFight.tap(fight, os.clock())
	if result == "caught" then
		local caught, detail = FishLanding.land(player, fish, session.rarityIndex)
		endSession(player, if caught then "caught" else "full", detail)
	elseif result == "escaped" then
		endSession(player, "escaped")
	end
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
	-- ReelFight ya limita los toques que cuentan; esto solo frena el abuso.
	Remotes.ReelIn.OnServerEvent:Connect(RateLimit.wrap("ReelIn", 30, 30, onReelIn))
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
