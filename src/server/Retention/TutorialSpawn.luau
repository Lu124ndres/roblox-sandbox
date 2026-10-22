--!strict
--[[
	TutorialSpawn

	El novato (sin ningún paso del tutorial hecho) no aparece en la plaza sino
	en la playa, frente al mar y ya dentro de la franja de pesca: lo primero
	que se le pide es pescar y así puede hacerlo apenas entra, sin dar la
	vuelta (antes la orilla quedaba 110 studs a sus espaldas). Los demás siguen
	apareciendo en la plaza.

	La playa queda en el ángulo de la aparición (WorldLayout.spawnAngle), a
	Config.Retention.tutorialShoreInset de la orilla hacia tierra; la altura
	sale de un rayo al suelo.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local PlayerData = require(script.Parent.Parent.PlayerData)

local LOAD_TIMEOUT = 15 -- segundos que espera los datos antes de dejarlo en la plaza
local MAX_WANDER = 30 -- si ya se alejó tanto de donde apareció, no se lo mueve
local RAY_TOP = 120 -- desde dónde baja el rayo al suelo

local TutorialSpawn = {}

-- Punto de la playa frente al mar y hacia dónde mira (afuera de la isla).
local function beach(): CFrame
	local angle = math.rad(WorldLayout.spawnAngle)
	local outward = Vector3.new(math.cos(angle), 0, math.sin(angle))
	local spot = outward * (WorldLayout.shoreRadius - Config.Retention.tutorialShoreInset)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local characters = {} -- los personajes no cuentan como suelo
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(characters, player.Character)
		end
	end
	params.FilterDescendantsInstances = characters
	local hit = Workspace:Raycast(
		spot + Vector3.new(0, RAY_TOP, 0),
		Vector3.new(0, -RAY_TOP * 2, 0),
		params
	)
	local ground = if hit then hit.Position.Y else WorldLayout.plateauHeight
	local position = Vector3.new(spot.X, ground + 3, spot.Z)
	return CFrame.lookAt(position, position + outward)
end

local function isNewcomer(player: Player): boolean
	local save = PlayerData.read(player)
	return save ~= nil and save.tutorial == 0
end

-- Espera los datos (el primer personaje aparece antes de que carguen) y, si es
-- novato y sigue donde apareció, lo pasa a la playa.
local function place(player: Player, character: Model, root: BasePart)
	local appearedAt = root.Position
	local waited = 0
	while not PlayerData.isLoaded(player) and waited < LOAD_TIMEOUT do
		waited += task.wait(0.2)
	end
	if character.Parent == nil or player.Character ~= character or not isNewcomer(player) then
		return
	end
	if (root.Position - appearedAt).Magnitude > MAX_WANDER then
		return
	end
	character:PivotTo(beach())
end

local function track(player: Player)
	player.CharacterAdded:Connect(function(character: Model)
		local root = character:WaitForChild("HumanoidRootPart", 10)
		if root and root:IsA("BasePart") then
			place(player, character, root)
		end
	end)
end

function TutorialSpawn.init()
	Players.PlayerAdded:Connect(track)
	for _, player in Players:GetPlayers() do
		track(player)
	end
end

return TutorialSpawn
