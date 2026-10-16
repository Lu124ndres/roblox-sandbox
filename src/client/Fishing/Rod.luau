--!strict
--[[
	Rod

	Caña de pescar en la mano del personaje. El modelo lo arma RodBuilder
	según la caña comprada (cada nivel con su estilo). Sale de la mano derecha y se orienta con
	el cuerpo del personaje, no con la mano: cada avatar orienta su mano
	distinto, pero todos saben dónde es "adelante".

	Todas las piezas van soldadas al mango y el mango, con una sola Weld, a
	la HumanoidRootPart: mover la caña es cambiar el C0 de esa Weld (una
	escritura por cuadro en vez de ~30 PivotTo), y entre actualizaciones la
	caña sigue al cuerpo sola.

	Es local: cada cliente dibuja las cañas de todos los jugadores a partir
	de su atributo FishingState (ver FishingVisuals y RodRig).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trajes = require(ReplicatedStorage.Shared.Trajes)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local FxQuality = require(script.Parent.Parent.Settings.FxQuality)
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
	look: number, -- nivel de caña con que se armó (para saber si se puede reutilizar)
	follow: (armDegrees: number) -> (), -- coloca la caña según el ángulo del brazo
	setDetail: (full: boolean) -> (), -- apaga partículas y luces de los adornos
}

-- Suelda cada pieza al mango con su posición de armado y las suelta del mundo.
local function weldTo(model: Model, grip: BasePart)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.Massless = true
			descendant.CanCollide = false
			if descendant ~= grip then
				local weld = Instance.new("Weld")
				weld.Part0 = grip
				weld.Part1 = descendant
				weld.C0 = grip.CFrame:ToObjectSpace(descendant.CFrame)
				weld.Parent = descendant
			end
		end
	end
end

-- tier = nivel de la caña comprada (UIConfig.RodLooks).
function Rod.attach(character: Model, tier: number): Rod?
	local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not hand or not hand:IsA("BasePart") or not root or not root:IsA("BasePart") then
		return nil
	end
	local looks = UIConfig.RodLooks
	local look = math.clamp(tier, 1, #looks)
	local built = RodBuilder.build(looks[look])
	local model, tip, trail, grip = built.model, built.tip, built.trail, built.grip
	-- El modelo se arma con el pivote en el origen: el mango queda en grip.CFrame respecto de él.
	local gripOffset = grip.CFrame
	weldTo(model, grip)
	local hold = Instance.new("Weld")
	hold.Name = "AgarreCana"
	hold.Part0 = root
	hold.Part1 = grip
	hold.C1 = gripOffset:Inverse()
	hold.Parent = grip
	local dropR6 = if hand.Name == "Right Arm" then R6_HAND_DROP else 0
	-- Con traje de malla la caña sale de la mano del traje (el cuerpo está escondido).
	local costume: Instance? = nil
	local costumeHand: Bone? = nil
	local function handPoint(): Vector3
		local current = character:FindFirstChild(Trajes.FOLDER)
		if current ~= costume then
			costume = current
			local mesh = current and Trajes.mesh(current)
			costumeHand = if mesh then Trajes.bones(mesh).ManoDer else nil
		end
		if costumeHand then
			return costumeHand.TransformedWorldCFrame.Position
		end
		return (hand :: BasePart).Position - (hand :: BasePart).CFrame.UpVector * dropR6
	end

	local function follow(armDegrees: number)
		if not hand.Parent then
			return
		end
		local elevation = math.rad(armDegrees + ARM_TO_ROD_DEGREES)
		local origin = root.CFrame:PointToObjectSpace(handPoint())
		-- En el espacio del personaje: adelante es -Z y arriba es +Y.
		local direction = Vector3.new(0, math.sin(elevation), -math.cos(elevation))
		hold.C0 = CFrame.lookAt(origin, origin + direction)
	end

	local emitters: { ParticleEmitter } = {}
	local lights: { Light } = {}
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			FxQuality.scaleEmitter(descendant)
			table.insert(emitters, descendant)
		elseif descendant:IsA("Light") then
			table.insert(lights, descendant)
		end
	end
	local function setDetail(full: boolean)
		for _, emitter in emitters do
			emitter.Enabled = full
		end
		for _, light in lights do
			light.Enabled = full
		end
	end

	follow(0)
	model.Parent = character
	return {
		model = model,
		tip = tip,
		trail = trail,
		look = look,
		follow = follow,
		setDetail = setDetail,
	}
end

return Rod
