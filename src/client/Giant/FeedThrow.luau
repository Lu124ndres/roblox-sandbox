--!strict
--[[
	FeedThrow

	Cuando alguien alimenta al gigante, todos ven sus peces volar en arco
	desde el jugador hasta la boca. El servidor manda un GiantFed cada ~0.25 s
	con un lote: { { userId, count, fishId }, ... } (uno por jugador; fishId =
	la especie más rara que entregó). Por cada jugador se dibujan a lo sumo
	MAX_PER_FEEDER peces, y en total no vuelan más de MAX_FLIGHTS a la vez
	(MAX_FLIGHTS_LOW_FX con efectos reducidos). Los de jugadores a más de
	MAX_CAMERA_STUDS de la cámara no se dibujan. Los del jugador local se ven
	siempre. Al llegar se llama onArrive: ahí el gigante muerde (GiantView).
	Solo efecto visual.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local FishCatalog = require(ReplicatedStorage.Shared.FishCatalog)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local FishModel = require(script.Parent.Parent.Effects.FishModel)
local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)
local FeedFlights = require(script.Parent.FeedFlights)
local FeedPop = require(script.Parent.FeedPop)

local EFFECTS = UIConfig.Effects
local BITE_SECONDS = 0.45
local MAX_PER_FEEDER = 3 -- peces dibujados por jugador en cada lote
local MAX_FLIGHTS = 20 -- vuelos a la vez en todo el servidor
local MAX_FLIGHTS_LOW_FX = 6
local MAX_CAMERA_STUDS = 250 -- más lejos de la cámara no se dibuja
local STAGGER_SECONDS = 0.08 -- separación entre los peces de un mismo lote

local FeedThrow = {}

local rng = Random.new()
local queued = 0 -- vuelos programados que todavía no despegan

-- Un pez (de la especie entregada) vuela girando desde la mano hasta la boca
-- (target se pide cada cuadro: la boca de la orca se mueve).
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
	Sounds.play("Whoosh", from, rng:NextNumber(0.9, 1.15))
	local model = FishModel.build(if FishCatalog.get(fishId) then fishId else "Sardina", 1.4)
	local color = FeedPop.color(fishId)
	FeedPop.trail(model, color)
	model.Parent = Workspace
	local spread = Vector3.new(rng:NextNumber(-2, 2), 0, rng:NextNumber(-2, 2))
	local start = from + Vector3.new(0, 2, 0)
	local function aim(): Vector3
		return target() + spread
	end
	FeedFlights.launch(model, start, aim, height, EFFECTS.FeedThrowSeconds, 1, function()
		model:Destroy()
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

-- Escucha GiantFed (un lote cada ~0.25 s). getMouth da la boca del gigante (nil
-- si aún no existe). El gigante reacciona a lo sumo cada BITE_SECONDS: con
-- muchos peces seguidos se ve una mordida tras otra, no una ráfaga de efectos.
function FeedThrow.listen(
	getMouth: () -> Vector3?,
	onArrive: (character: Model) -> (),
	getSize: () -> number
)
	local remotes = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
	local giantFed = remotes:WaitForChild(Protocol.Remotes.GiantFed) :: RemoteEvent
	local lastBite = 0

	local function launch(character: Model, fishId: string)
		local mouth = getMouth()
		if not mouth or not character.Parent then
			return
		end
		local last: Vector3 = mouth
		local function target(): Vector3
			last = getMouth() or last
			return last
		end
		local isLocal = character == Players.LocalPlayer.Character
		FeedThrow.throw(character:GetPivot().Position, target, fishId, function()
			if os.clock() - lastBite >= BITE_SECONDS then
				lastBite = os.clock()
				onArrive(character)
			end
		end, isLocal, getSize())
	end

	local function show(entry: { [any]: any })
		local userId, count, fishId = entry.userId, entry.count, entry.fishId
		if type(userId) ~= "number" or type(count) ~= "number" or type(fishId) ~= "string" then
			return
		end
		local feeder = Players:GetPlayerByUserId(userId)
		local character = feeder and feeder.Character
		if not feeder or not character then
			return
		end
		local isLocal = feeder == Players.LocalPlayer
		if not isLocal and tooFar(character:GetPivot().Position) then
			return
		end
		for index = 1, math.clamp(math.floor(count), 0, MAX_PER_FEEDER) do
			if not isLocal and FeedFlights.count() + queued >= maxFlights() then
				return
			end
			queued += 1
			task.delay((index - 1) * STAGGER_SECONDS, function()
				queued -= 1
				launch(character, fishId)
			end)
		end
	end

	giantFed.OnClientEvent:Connect(function(batch: unknown)
		if type(batch) ~= "table" or not getMouth() then
			return
		end
		for _, entry in batch :: { any } do
			if type(entry) == "table" then
				show(entry)
			end
		end
	end)
end

return FeedThrow
