--!strict
--[[
	Director (tráiler, servidor)

	El guion del video de la página del juego (como referencias/Ejemplo.mp4):
	pocas frases grandes, cortes secos y el gigante creciendo al final. Prepara
	al jugador (canasta vacía, mejoras), pone al Zorro de Agua y va cambiando
	Workspace.TrailerEscena con los tiempos de cada escena; el cliente
	(Director.client) mueve al jugador, la cámara y los textos.

	En Studio el guardado es real: se toma una copia de los datos del jugador
	al empezar y se devuelve tal cual al terminar. Imprime cuándo empieza cada
	escena. Solo corre en Studio; se mete a mano con tools/trailer/preparar.lua
	y se borra después. No es parte del juego.
]]

local HttpService = game:GetService("HttpService")
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
local Server = script.Parent:WaitForChild("Server")
local GiantCycle = require(Server.GiantCycle)
local GiantService = require(Server.GiantService)
local PlayerData = require(Server.PlayerData)

local ATTR = Protocol.PlayerAttributes
local DAY = 13
local GIANT = "ZorroDeAgua"

Workspace:SetAttribute("HoraFija", DAY)
Workspace:SetAttribute("TrailerEscena", "")
local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
while player:GetAttribute(ATTR.DataLoaded) ~= true do
	task.wait(0.5)
end
task.wait(8) -- el terreno y los modelos del mapa

local backup = PlayerData.snapshot(player)
local function restore()
	if not backup then
		return
	end
	PlayerData.edit(player, function(save)
		for key in save do
			(save :: any)[key] = nil
		end
		for key, value in backup :: any do
			(save :: any)[key] = value
		end
	end)
end

-- Un jugador que ya lleva un rato y terminó el tutorial (sin guías en pantalla).
PlayerData.edit(player, function(save)
	save.tutorial = math.max(save.tutorial, 4)
end)
-- En el video en inglés, la interfaz del juego también (ClientSettings relee el atributo).
if Workspace:GetAttribute("TrailerIdioma") == "en" then
	local raw = player:GetAttribute(ATTR.Settings)
	local ok, settings =
		pcall(HttpService.JSONDecode, HttpService, if type(raw) == "string" then raw else "{}")
	local merged = if ok and type(settings) == "table" then settings else {}
	merged.english, merged.langChosen = true, true
	player:SetAttribute(ATTR.Settings, HttpService:JSONEncode(merged))
end
PlayerData.takeFishBatch(player, math.huge, math.huge)
PlayerData.setUpgrade(player, "Rod", 4)
PlayerData.setUpgrade(player, "Basket", 3)
PlayerData.setUpgrade(player, "Boots", 3)

local function giantDef(): Config.GiantDef
	for _, def in Config.Giants.chain do
		if def.id == GIANT then
			return def
		end
	end
	return Config.Giants.chain[1]
end

-- Un punto del paseo del cráter a `degrees` de la puerta (el rayo baja desde poco más
-- arriba del paseo: más alto pegaría en el techo de la cueva).
local function ringSpot(degrees: number): Vector3
	local door = WorldZones.craterDoor()
	local offset = (Vector3.new(door.X, 0, door.Z) - WorldZones.craterCenter).Unit
	local a = math.rad(degrees)
	local turned = Vector3.new(
		offset.X * math.cos(a) - offset.Z * math.sin(a),
		0,
		offset.X * math.sin(a) + offset.Z * math.cos(a)
	)
	local spot = WorldZones.craterCenter
		+ turned * (WorldLayout.craterCliffRadius + WorldLayout.craterWalkWidth * 0.45)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Instance }
	local top = WorldLayout.craterDeckHeight + 30
	local hit = Workspace:Raycast(Vector3.new(spot.X, top, spot.Z), Vector3.new(0, -60, 0), params)
	return Vector3.new(
		spot.X,
		(if hit then hit.Position.Y else WorldLayout.craterDeckHeight) + 3,
		spot.Z
	)
end

-- Cuatro jugadores de colores a los costados del punto, mirando al gigante (quietos).
local COLORS = {
	Color3.fromRGB(226, 60, 60),
	Color3.fromRGB(60, 120, 226),
	Color3.fromRGB(90, 200, 80),
	Color3.fromRGB(240, 200, 60),
}
local function spawnFriends(spot: Vector3): { Model }
	local toCenter =
		Vector3.new(WorldZones.craterCenter.X - spot.X, 0, WorldZones.craterCenter.Z - spot.Z).Unit
	local side = Vector3.new(-toCenter.Z, 0, toCenter.X)
	local friends = {}
	for i, color in COLORS do
		local desc = Instance.new("HumanoidDescription")
		desc.HeadColor = Color3.fromRGB(255, 204, 153)
		desc.TorsoColor, desc.LeftArmColor, desc.RightArmColor = color, color, color
		desc.LeftLegColor, desc.RightLegColor =
			Color3.fromRGB(40, 50, 80), Color3.fromRGB(40, 50, 80)
		local ok, model = pcall(
			Players.CreateHumanoidModelFromDescription,
			Players,
			desc,
			Enum.HumanoidRigType.R15
		)
		if ok and model then
			local slot = if i <= 2 then i - 3 else i - 2
			local pos = spot + side * (slot * 4) - toCenter * (math.abs(slot) * 1.3)
			model:PivotTo(CFrame.lookAt(pos, pos + toCenter))
			for _, part in model:GetDescendants() do
				if part:IsA("BasePart") then
					part.Anchored = true
				end
			end
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			end
			model.Name = `TrailerAmigo{i}`
			model.Parent = Workspace
			table.insert(friends, model)
		else
			warn("no pude crear un amigo:", model)
		end
	end
	return friends
end

local function fillBasket(total: number, batches: number, seconds: number)
	local species = { "Sardina", "Anchoa", "Caballa", "PezPayaso", "PargoRojo" }
	for k = 1, batches do
		PlayerData.addFish(player, species[(k % #species) + 1], math.floor(total / batches))
		task.wait(seconds / batches)
	end
end

if not GiantService.isFeeding() then
	GiantCycle.skipRest()
	task.wait(Config.Giants.cycle.arrivalSeconds + 1)
end
GiantService.reset(giantDef(), 2)
task.wait(4)

local startClock = os.clock()
local function scene(name: string, seconds: number)
	Workspace:SetAttribute("TrailerEscena", name)
	print(`ESCENA {name} t={string.format("%.2f", os.clock() - startClock)}`)
	task.wait(seconds)
end

scene("destello", 0.6)
scene("pesca", 6.5)
task.spawn(fillBasket, 90, 10, 2.4)
scene("canasta", 3)
scene("puente", 3.4)
scene("alimenta", 5.5)
scene("entrena", 4)
scene("mejoras", 2.8)
fillBasket(90, 1, 0)
local friendSpot = ringSpot(18)
Workspace:SetAttribute("TrailerPunto", friendSpot)
local friends = spawnFriends(friendSpot)
scene("amigos", 5)
for _, model in friends do
	model:Destroy()
end

-- El gigante vuelve a la etapa 1 y evoluciona tres veces seguidas (como al llenar cada cuarto).
GiantService.reset(giantDef(), 1)
task.delay(1.6, GiantService.fill, 0.25, player)
task.delay(4.9, GiantService.fill, 0.25, player)
task.delay(8.2, GiantService.fill, 0.25, player)
scene("crece", 11.5)

scene("titulo", 5.5)
scene("fin", 0.8)
scene("destello", 0.6)
print(`FIN t={string.format("%.2f", os.clock() - startClock)}`)
Workspace:SetAttribute("TrailerEscena", "listo")
Workspace:SetAttribute("TrailerPunto", nil)
Workspace:SetAttribute("HoraFija", nil)
restore()
print("datos del jugador restaurados")
