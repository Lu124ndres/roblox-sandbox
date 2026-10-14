--!strict
--[[
	FishGlow

	Brillos de los peces raros: destellos del color de su rareza alrededor
	del cuerpo (épicos o mejores) y el cambio de color sin fin del mítico.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Assets = require(ReplicatedStorage.Shared.Assets)

local FishGlow = {}

function FishGlow.aura(body: BasePart, color: Color3, scale: number)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = Assets.Particles.Sparkle
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 1
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.3, 0.5 * scale),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Lifetime = NumberRange.new(0.5, 0.9)
	emitter.Speed = NumberRange.new(1, 3)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rate = 14
	emitter.Parent = body
end

-- Arcoíris: cuerpo y aletas cambian de tono hasta que el pez se destruye.
function FishGlow.rainbow(model: Model)
	local pieces = {}
	for _, child in model:GetChildren() do
		if
			child:IsA("BasePart") and (child.Name == "Cuerpo" or string.find(child.Name, "Aleta"))
		then
			table.insert(pieces, child)
		end
	end
	local connection = RunService.Heartbeat:Connect(function()
		local hue = (os.clock() * 0.4) % 1
		for index, piece in pieces do
			piece.Color = Color3.fromHSV((hue + index * 0.07) % 1, 0.65, 1)
		end
	end)
	model.Destroying:Once(function()
		connection:Disconnect()
	end)
end

return FishGlow
