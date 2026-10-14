--!strict
--[[
	Proximity

	Utilidades de distancia que usan los servicios para validar que un
	jugador está de verdad donde dice estar. El ProximityPrompt ya filtra
	por distancia, pero la validación del servidor no confía en nada.
]]

local Proximity = {}

function Proximity.getRoot(player: Player): BasePart?
	local character = player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

function Proximity.isNear(player: Player, target: BasePart, maxDistance: number): boolean
	local root = Proximity.getRoot(player)
	if not root then
		return false
	end
	return (root.Position - target.Position).Magnitude <= maxDistance
end

function Proximity.isNearPoint(player: Player, point: Vector3, maxDistance: number): boolean
	local root = Proximity.getRoot(player)
	return root ~= nil and (root.Position - point).Magnitude <= maxDistance
end

function Proximity.makePrompt(
	parent: BasePart,
	actionText: string,
	objectText: string,
	distance: number
): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = distance
	prompt.RequiresLineOfSight = false
	prompt.Parent = parent
	return prompt
end

return Proximity
