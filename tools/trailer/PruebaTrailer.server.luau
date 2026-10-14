--!strict
-- Prueba temporal: guion del tráiler (solo en Studio). Cambia el atributo
-- "TrailerEscena" de Workspace; el cliente (PruebaTrailer) mueve la cámara y
-- pone los textos. Imprime cuándo empieza cada escena para cortar el video.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
if not RunService:IsStudio() then
	return
end
local Config = require(ReplicatedStorage.Shared.Config)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local GiantService = require(script.Parent.GiantService)
local PlayerData = require(script.Parent.PlayerData)

Workspace:SetAttribute("HoraFija", 14.5) -- de día todo el tráiler
local player = Players.PlayerAdded:Wait()
while player:GetAttribute("DataLoaded") ~= true do
	task.wait(0.5)
end
PlayerData.takeFishBatch(player, 1000000, math.huge) -- canasta vacía (el guardado ya es real)
PlayerData.addCoins(player, 48250)
PlayerData.addPower(player, 25870)
PlayerData.setUpgrade(player, "Rod", 6)
PlayerData.setUpgrade(player, "Basket", 4)
PlayerData.setUpgrade(player, "Boots", 3)
task.wait(6)

local center = WorldZones.craterCenter
local startClock = 0
local function scene(index: number, name: string)
	Workspace:SetAttribute("TrailerEscena", index)
	print(`ESCENA {index} {name} t={string.format("%.2f", os.clock() - startClock)}`)
end
local function teleport(position: Vector3, lookAt: Vector3)
	local character = player.Character or player.CharacterAdded:Wait()
	local flatLook = Vector3.new(lookAt.X, position.Y, lookAt.Z)
	character:PivotTo(CFrame.lookAt(position, flatLook))
end
local function ground(x: number, z: number): Vector3
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { player.Character :: Model }
	params.FilterType = Enum.RaycastFilterType.Exclude
	local hit = Workspace:Raycast(Vector3.new(x, 200, z), Vector3.new(0, -400, 0), params)
	return Vector3.new(x, (if hit then hit.Position.Y else 10) + 3.5, z)
end

-- 0) Destello para sincronizar el corte.
startClock = os.clock()
scene(0, "destello")
task.wait(1.5)
-- 1) Pescar en la orilla.
local angle = math.rad(205)
local radius = (WorldLayout.fishingBandInner + WorldLayout.shoreRadius) / 2 + 2
local spot = ground(math.cos(angle) * radius, math.sin(angle) * radius)
teleport(spot, spot * 3)
task.wait(0.5)
scene(1, "pesca")
task.wait(10)
-- 2) Canasta llena.
local carga: { [string]: number } = { Sardina = 60, Anchoa = 50, Caballa = 30, PezPayaso = 10 }
for id, count in carga do
	PlayerData.addFish(player, id, count)
end
scene(2, "canasta")
task.wait(4)
-- 3) Al volcán por el puente.
local bridgeStart, bridgeEnd = WorldZones.bridgeEnds()
teleport(ground(bridgeStart.X, bridgeStart.Z), bridgeEnd)
task.wait(0.3)
scene(3, "volcan")
task.wait(6)
-- 4) Alimentar.
GiantService.reset(Config.Giants.chain[1])
local point = Workspace:WaitForChild("Isla"):FindFirstChild("PuntoDeAlimentar", true) :: BasePart
teleport(point.Position + Vector3.new(0, 4, 0), center)
task.wait(0.5)
scene(4, "alimenta")
task.wait(8)
-- 5) Crece.
scene(5, "crece")
task.wait(1)
GiantService.fill(0.3, player)
task.wait(3)
GiantService.fill(0.25, player)
task.wait(3)
-- 6) Con amigos.
scene(6, "amigos")
task.wait(6)
-- 7) Se enoja.
GiantService.setAnger(1)
scene(7, "enojo")
task.wait(7)
-- 8) Se llena: despedida y descanso en la guarida.
GiantService.setAnger(0)
GiantService.fill(1, player)
while GiantService.getPhase() ~= "rest" do
	task.wait(0.2)
end
task.wait(6)
teleport(
	Vector3.new(center.X, WorldLayout.restArenaTop + 5, center.Z),
	center + Vector3.new(0, 0, -50)
)
task.wait(0.5)
scene(8, "entrena")
task.wait(8)
-- 9) Final.
scene(9, "final")
task.wait(7)
scene(10, "fin")
