--!strict
--[[
	Rod

	Caña de pescar en la mano del personaje. El modelo lo arma RodBuilder
	según la caña comprada (cada nivel con su estilo). Sale de la mano derecha y se orienta con
	el cuerpo del personaje, no con la mano: cada avatar orienta su mano
	distinto, pero todos saben dónde es "adelante".

	Es local: cada cliente dibuja las cañas de todos los jugadores a partir
	de su atributo FishingState (ver FishingVisuals).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local RodBuilder = require(script.Parent.RodBuilder)

local Rod = {}

-- La caña sube con el brazo: con el brazo a 60 grados (pose de espera) queda a
-- 25 grados sobre la horizontal; con el brazo atrás (150) apunta hacia atrás.
local ARM_TO_ROD_DEGREES = -35
local R6_HAND_DROP = 0.9 -- en R6 la mano es el extremo del brazo

export type Rod = {
	model: Model,
	tip: Attachment,
	trail: Trail, -- estela de la punta; se enciende durante el latigazo
	follow: (armDegrees: number) -> (), -- coloca la caña según el ángulo del brazo
}

-- tier = nivel de la caña comprada (UIConfig.RodLooks).
function Rod.attach(character: Model, tier: number): Rod?
	local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not hand or not hand:IsA("BasePart") or not root or not root:IsA("BasePart") then
		return nil
	end
	local looks = UIConfig.RodLooks
	local built = RodBuilder.build(looks[math.clamp(tier, 1, #looks)])
	local model, tip, trail = built.model, built.tip, built.trail
	model.Parent = character
	local dropR6 = if hand.Name == "Right Arm" then R6_HAND_DROP else 0

	local function follow(armDegrees: number)
		if not hand.Parent then
			return
		end
		local elevation = math.rad(armDegrees + ARM_TO_ROD_DEGREES)
		local origin = hand.Position - hand.CFrame.UpVector * dropR6
		-- En el espacio del personaje: adelante es -Z y arriba es +Y.
		local direction = root.CFrame:VectorToWorldSpace(
			Vector3.new(0, math.sin(elevation), -math.cos(elevation))
		)
		model:PivotTo(CFrame.lookAt(origin, origin + direction))
	end
	follow(0)
	return { model = model, tip = tip, trail = trail, follow = follow }
end

return Rod
