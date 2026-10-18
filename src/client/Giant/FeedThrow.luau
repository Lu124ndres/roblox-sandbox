--!strict
--[[
	FeedThrow

	Cuando alguien alimenta al gigante, todos ven sus peces volar en arco
	desde el jugador hasta la boca. El servidor manda un GiantFed cada ~0.15 s
	con un lote: { { userId, count, fishId }, ... } (uno por jugador; fishId =
	la especie más rara que entregó).

	Para que se sienta fluido (pedido del usuario: «que no se trabe»), los
	peces de cada lote no salen juntos: entran a la fila de ese jugador y un
	solo bucle los suelta a intervalos parejos, repartidos hasta el lote
	siguiente. Así se ve un chorro continuo y no ráfagas con huecos. Los
	modelos se reusan (FeedPool) y el «fiu» de cada lanzamiento no se repite
	más de una vez cada WHOOSH_GAP.

	Por jugador se dibujan a lo sumo MAX_QUEUED peces pendientes; en total no
	vuelan más de MAX_FLIGHTS a la vez (MAX_FLIGHTS_LOW_FX con efectos
	reducidos). Los de jugadores a más de MAX_CAMERA_STUDS de la cámara no se
	dibujan; los del jugador local se ven siempre. Al llegar se llama onArrive:
	ahí el gigante muerde (GiantView). Solo efecto visual.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)
local FeedFlights = require(script.Parent.FeedFlights)
local FeedPool = require(script.Parent.FeedPool)
local FeedPop = require(script.Parent.FeedPop)

local EFFECTS = UIConfig.Effects
local BITE_SECONDS = 0.45
local MAX_QUEUED = 10 -- peces pendientes por jugador (el resto se cuenta pero no se dibuja)
local MAX_FLIGHTS = 24 -- vuelos a la vez en todo el servidor
local MAX_FLIGHTS_LOW_FX = 8
local MAX_CAMERA_STUDS = 250 -- más lejos de la cámara no se dibuja
local SPREAD_SECONDS = 0.16 -- los peces de un lote se reparten en este tiempo (~ entre lotes)
local MIN_GAP, MAX_GAP = 0.045, 0.16
local WHOOSH_GAP = 0.09

local FeedThrow = {}

type Feeder =
	{ character: Model, fishId: string, pending: number, nextAt: number, isLocal: boolean }

local rng = Random.new()
local lastWhoosh = 0

-- Un pez (de la especie entregada) vuela girando desde la mano hasta la boca
-- (target se pide cada cuadro: la boca del gigante se mueve).
function FeedThrow.throw(
	from: Vector3,
	target: () -> Vector3,
	fishId: string,
	onArrive: () -> (),
	isLocal: boolean?,
	size: number?
)
	local distance = (target() - from).Magnitude
	local height = math.clamp(distance * 0.3, 6, 40)
	local now = os.clock()
	if now - lastWhoosh >= WHOOSH_GAP then
		lastWhoosh = now
		Sounds.play("Whoosh", from, rng:NextNumber(0.9, 1.15))
	end
	local start = from + Vector3.new(0, 2, 0)
	local model = FeedPool.take(fishId, CFrame.new(start))
	local spread = Vector3.new(rng:NextNumber(-2, 2), 0, rng:NextNumber(-2, 2))
	local function aim(): Vector3
		return target() + spread
	end
	local color = FeedPop.color(fishId)
	FeedFlights.launch(model, start, aim, height, EFFECTS.FeedThrowSeconds, 1, function()
		FeedPool.give(model)
		FeedPop.chomp(aim(), color, size or 20, isLocal == true)
		onArrive()
	end)
end

local function maxFlights(): number
	return if ClientSettings.get("lowFx") then MAX_FLIGHTS_LOW_FX else MAX_FLIGHTS
end

local function tooFar(position: Vector3): boolean
	local camera = Workspace.CurrentCamera
	return camera ~= nil and (camera.CFrame.Position - position).Magnitude > MAX_CAMERA_STUDS
end

-- Escucha GiantFed. getMouth da la boca del gigante (nil si aún no existe). El
-- gigante reacciona a lo sumo cada BITE_SECONDS: con muchos peces seguidos se ve
-- una mordida tras otra, no una ráfaga de efectos.
function FeedThrow.listen(
	getMouth: () -> Vector3?,
	onArrive: (character: Model, fishId: string) -> (),
	getSize: () -> number
)
	local remotes = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
	local giantFed = remotes:WaitForChild(Protocol.Remotes.GiantFed) :: RemoteEvent
	local lastBite = 0
	local feeders: { [number]: Feeder } = {}

	local function launch(feeder: Feeder)
		local mouth = getMouth()
		local character = feeder.character
		if not mouth or not character.Parent then
			return
		end
		local last: Vector3 = mouth
		local function target(): Vector3
			last = getMouth() or last
			return last
		end
		local fishId = feeder.fishId
		FeedThrow.throw(character:GetPivot().Position, target, fishId, function()
			if os.clock() - lastBite >= BITE_SECONDS then
				lastBite = os.clock()
				onArrive(character, fishId)
			end
		end, feeder.isLocal, getSize())
	end

	local function add(entry: { [any]: any })
		local userId, count, fishId = entry.userId, entry.count, entry.fishId
		if type(userId) ~= "number" or type(count) ~= "number" or type(fishId) ~= "string" then
			return
		end
		local player = Players:GetPlayerByUserId(userId)
		local character = player and player.Character
		if not player or not character then
			return
		end
		local isLocal = player == Players.LocalPlayer
		if not isLocal and tooFar(character:GetPivot().Position) then
			return
		end
		local feeder = feeders[userId]
		if not feeder then
			feeder = {
				character = character,
				fishId = fishId,
				pending = 0,
				nextAt = 0,
				isLocal = isLocal,
			}
			feeders[userId] = feeder
		end
		feeder.character, feeder.fishId = character, fishId
		feeder.pending = math.min(feeder.pending + math.max(0, math.floor(count)), MAX_QUEUED)
	end

	giantFed.OnClientEvent:Connect(function(batch: unknown)
		if type(batch) ~= "table" or not getMouth() then
			return
		end
		for _, entry in batch :: { any } do
			if type(entry) == "table" then
				add(entry)
			end
		end
	end)

	-- Un solo bucle suelta los peces de cada fila, parejos: lo pendiente se reparte en
	-- SPREAD_SECONDS (lo que tarda en llegar el lote siguiente).
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		for userId, feeder in feeders do
			if feeder.pending <= 0 then
				feeders[userId] = nil
			elseif now >= feeder.nextAt then
				if feeder.isLocal or FeedFlights.count() < maxFlights() then
					launch(feeder)
				end
				feeder.pending -= 1
				local gap =
					math.clamp(SPREAD_SECONDS / math.max(feeder.pending, 1), MIN_GAP, MAX_GAP)
				feeder.nextAt = now + gap
			end
		end
	end)
end

return FeedThrow
