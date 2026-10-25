--!strict
--[[
	Bot (pruebas con varios clientes)

	Juega solo, por los mismos remotes que un jugador: pesca en la playa hasta
	llenar la canasta, la lleva al cráter y alimenta al gigante, y a veces
	entrena en un estanque. Sirve para probar en Studio (Prueba → Servidor
	local con N clientes) la barra compartida, varios en un estanque, los
	ataques del gigante y el rendimiento con el servidor lleno.

	Cada bot elige sus lugares según su número de jugador (Player1, Player2...)
	para no amontonarse. Escribe en el Output con el prefijo [Bot N].
	Solo corre en Studio; se mete con tools/bots/preparar.lua y se borra después.
	No es parte del juego.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

if not RunService:IsStudio() then
	return
end

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)

local ATTR = Protocol.PlayerAttributes
local FISH_SECONDS = 70 -- tope de tiempo pescando antes de ir a alimentar igual
local FEED_SECONDS = 35 -- tope de tiempo alimentando
local TRAIN_SECONDS = 20
local TRAIN_CHANCE = 0.3

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
local fishing = remotes:WaitForChild(Protocol.Remotes.FishingUpdate) :: RemoteEvent
local cast = remotes:WaitForChild(Protocol.Remotes.CastRequest) :: RemoteEvent
local reel = remotes:WaitForChild(Protocol.Remotes.ReelIn) :: RemoteEvent
local feed = remotes:WaitForChild(Protocol.Remotes.FeedRequest) :: RemoteEvent
local buy = remotes:WaitForChild(Protocol.Remotes.BuyUpgrade) :: RemoteEvent
local shopResult = remotes:WaitForChild(Protocol.Remotes.ShopResult) :: RemoteEvent

local number = tonumber(string.match(player.Name, "%d+")) or 1
local random = Random.new(number * 7919)
local tag = `[Bot {number}]`

local function log(text: string)
	print(`{tag} {text}`)
end

local function root(): BasePart?
	local character = player.Character
	local part = character and character:FindFirstChild("HumanoidRootPart")
	return if part and part:IsA("BasePart") then part else nil
end

local function carried(): number
	local value = player:GetAttribute(ATTR.CarriedFish)
	return if type(value) == "number" then value else 0
end

-- Con streaming, lo que está lejos no existe en este cliente: se pide antes de ir.
local function streamAround(x: number, z: number)
	pcall(function()
		player:RequestStreamAroundAsync(Vector3.new(x, 40, z))
	end)
end

local function floorAt(x: number, z: number, top: number): number?
	streamAround(x, z)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Instance }
	local hit = Workspace:Raycast(Vector3.new(x, top, z), Vector3.new(0, -top - 200, 0), params)
	return if hit then hit.Position.Y else nil
end

local function place(position: Vector3, lookAt: Vector3)
	local character = player.Character
	if not character then
		return
	end
	character:PivotTo(CFrame.lookAt(position, Vector3.new(lookAt.X, position.Y, lookAt.Z)))
end

-- Pescar: lanza, recoge cuando pica (como tocar TIRA rápido) y vuelve a lanzar.
local fishingNow = false
local basketFull = false
fishing.OnClientEvent:Connect(function(state: unknown)
	if not fishingNow then
		return
	end
	if state == "bite" then
		task.spawn(function()
			for _ = 1, 25 do
				reel:FireServer()
				task.wait(0.12)
				if player:GetAttribute(ATTR.FishingState) ~= "bite" then
					break
				end
			end
		end)
	elseif state == "full" then
		basketFull = true
	elseif state == "caught" or state == "escaped" then
		task.delay(random:NextNumber(0.5, 1.2), function()
			if fishingNow and not basketFull then
				cast:FireServer()
			end
		end)
	end
end)

local function goFish()
	local angle = math.rad(WorldLayout.spawnAngle + (number - 1) * 23 + random:NextNumber(-6, 6))
	local outward = Vector3.new(math.cos(angle), 0, math.sin(angle))
	local spot = outward * (WorldLayout.shoreRadius - Config.Retention.tutorialShoreInset)
	local y = floorAt(spot.X, spot.Z, 120) or WorldLayout.plateauHeight
	place(Vector3.new(spot.X, y + 3, spot.Z), Vector3.new(spot.X, 0, spot.Z) + outward * 50)
	task.wait(0.6)
	fishingNow, basketFull = true, false
	local before = carried()
	cast:FireServer()
	local started = os.clock()
	while not basketFull and os.clock() - started < FISH_SECONDS do
		task.wait(1)
		if player:GetAttribute(ATTR.FishingState) == "idle" and os.clock() - started > 3 then
			cast:FireServer() -- por si un lanzamiento se perdió
		end
	end
	fishingNow = false
	log(
		`pescó {carried() - before} (lleva {carried()}){if basketFull
			then ", canasta llena"
			else ""}`
	)
end

-- Un punto del paseo del cráter, repartido por número de bot, mirando al gigante.
local function craterSpot(): Vector3
	local door = WorldZones.craterDoor()
	local offset = (Vector3.new(door.X, 0, door.Z) - WorldZones.craterCenter).Unit
	local a = math.rad((number - 1) * 14 - 50 + random:NextNumber(-4, 4))
	local turned = Vector3.new(
		offset.X * math.cos(a) - offset.Z * math.sin(a),
		0,
		offset.X * math.sin(a) + offset.Z * math.cos(a)
	)
	local spot = WorldZones.craterCenter
		+ turned * (WorldLayout.craterCliffRadius + WorldLayout.craterWalkWidth * 0.45)
	local y = floorAt(spot.X, spot.Z, WorldLayout.craterDeckHeight + 30)
		or WorldLayout.craterDeckHeight
	return Vector3.new(spot.X, y + 3, spot.Z)
end

local function goFeed()
	if carried() == 0 then
		return
	end
	place(craterSpot(), WorldZones.craterCenter)
	task.wait(0.5)
	local before = carried()
	feed:FireServer(true)
	local started = os.clock()
	local lastCount, lastChange = carried(), os.clock()
	while carried() > 0 and os.clock() - started < FEED_SECONDS do
		task.wait(0.5)
		if carried() ~= lastCount then
			lastCount, lastChange = carried(), os.clock()
		elseif os.clock() - lastChange > 2 then
			-- No entrega (el servidor aún lo veía en otro lado, o el gigante evolucionaba):
			-- suelta y vuelve a apretar, como un jugador.
			feed:FireServer(false)
			task.wait(0.6)
			feed:FireServer(true)
			lastChange = os.clock()
		end
	end
	feed:FireServer(false)
	log(`alimentó {before - carried()} (quedan {carried()})`)
end

-- El aviso va en una pieza hija del estanque (CentroEntrenar); el índice, en el estanque.
local function pondOf(prompt: Instance): number?
	local pond = prompt:FindFirstAncestor(Protocol.Map.TrainingPond)
	local index = pond and pond:GetAttribute(Protocol.Map.PondIndexAttribute)
	return if type(index) == "number" then index else nil
end

local function pondPrompt(index: number): ProximityPrompt?
	for _, descendant in Workspace:GetDescendants() do
		if descendant:IsA("ProximityPrompt") and pondOf(descendant) == index then
			return descendant
		end
	end
	return nil
end

local function goTrain()
	local pond = WorldZones.pondCenter(1)
	streamAround(pond.X, pond.Z)
	local prompt: ProximityPrompt? = nil
	for _ = 1, 10 do -- el estanque llega con el streaming
		prompt = pondPrompt(1)
		if prompt then
			break
		end
		task.wait(0.5)
	end
	local anchor = prompt and prompt.Parent
	if not prompt or not anchor or not anchor:IsA("Attachment") then
		log("no encontré el estanque 1")
		return
	end
	-- Cada bot en su lado del estanque, a 10 studs del centro (el aviso alcanza 22).
	local center = anchor.WorldPosition
	local a = math.rad(number * 37)
	local x, z = center.X + math.cos(a) * 10, center.Z + math.sin(a) * 10
	local y = floorAt(x, z, center.Y + 40) or center.Y
	place(Vector3.new(x, y + 3, z), center)
	task.wait(1.5) -- que el servidor lo vea ahí y el aviso aparezca
	prompt:InputHoldBegin()
	task.wait(0.1)
	prompt:InputHoldEnd()
	task.wait(1.5)
	local training = player:GetAttribute(ATTR.TrainingPond)
	if training == 0 or training == nil then
		log("no pudo empezar a entrenar")
		return
	end
	log(`entrena en el estanque {training} por {TRAIN_SECONDS} s`)
	task.wait(TRAIN_SECONDS)
end

while
	player:GetAttribute(ATTR.DataLoaded) ~= true
	or Workspace:GetAttribute(Protocol.WorldReadyAttribute) ~= true
do
	task.wait(1)
end
task.wait(3 + number * 0.7) -- que no arranquen todos en el mismo cuadro
log("empieza")

-- Compra lo que le alcance (como en MEJORAS): una mejora por categoría y vuelta.
local bought = 0
shopResult.OnClientEvent:Connect(function(status: unknown, category: unknown, level: unknown)
	if status == "ok" then
		bought += 1
		log(`compró {category} nivel {level}`)
	end
end)
local function goShop()
	for _, category in { "Rod", "Basket", "Boots" } do
		buy:FireServer(category)
		task.wait(1.6) -- el servidor acepta 4 pedidos cada 6 s
	end
end

local function tutorialStep(): number
	local value = player:GetAttribute(ATTR.Tutorial)
	return if type(value) == "number" then value else 0
end

local cycle = 0
while player.Parent do
	if root() then
		cycle += 1
		local ok, err = pcall(function()
			goFish()
			goFeed()
			-- Paso 3 del tutorial (entrenar): va sí o sí; si no, a veces.
			if tutorialStep() == 2 or random:NextNumber() < TRAIN_CHANCE then
				goTrain()
			end
			goShop()
			if cycle % 3 == 0 then
				log(`vuelta {cycle}: tutorial {tutorialStep()}/4, {bought} compras`)
			end
		end)
		if not ok then
			log(`error en la vuelta {cycle}: {err}`)
			task.wait(3)
		end
	else
		task.wait(1)
	end
end
