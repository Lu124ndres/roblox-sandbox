--!strict
--[[
	PlayerCollision

	Los avatares no chocan entre sí: con 40-50 jugadores en los estanques,
	el puente o la guarida del descanso, empujarse estorba más de lo que
	aporta. Se registra el grupo de colisión Jugadores (no colisiona consigo
	mismo, sí con todo lo demás) y cada BasePart del personaje entra en él,
	también las que aparecen después (accesorios, herramientas).
]]

local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

local GROUP = "Jugadores"

local PlayerCollision = {}

local function assign(instance: Instance)
	if instance:IsA("BasePart") then
		instance.CollisionGroup = GROUP
	end
end

local function onCharacter(character: Model)
	for _, descendant in character:GetDescendants() do
		assign(descendant)
	end
	-- La conexión muere con el personaje (Destroy al reaparecer o salir).
	character.DescendantAdded:Connect(assign)
end

local function onPlayer(player: Player)
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		onCharacter(player.Character)
	end
end

function PlayerCollision.init()
	if not PhysicsService:IsCollisionGroupRegistered(GROUP) then
		PhysicsService:RegisterCollisionGroup(GROUP)
	end
	PhysicsService:CollisionGroupSetCollidable(GROUP, GROUP, false)
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
end

return PlayerCollision
