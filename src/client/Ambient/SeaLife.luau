--!strict
--[[
	SeaLife

	Vida del mar alrededor de la isla, toda local: las boyas se mecen, la
	espuma de la orilla va y viene como olas, el sol destella sobre el agua
	y de vez en cuando un pez salta fuera del agua.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local Assets = require(ReplicatedStorage.Shared.Assets)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local Fx = require(script.Parent.Parent.Effects.Fx)
local FishModel = require(script.Parent.Parent.Effects.FishModel)

local EFFECTS = UIConfig.Effects
local FOAM_TRAVEL_STUDS = 1.2 -- cuánto sube y baja la espuma sobre la arena
local FOAM_UPDATE_SECONDS = 1 / 20
local JUMP_FISH = { "Sardina", "Anchoa", "Caballa", "PezPayaso", "PargoRojo", "Atun" }

local SeaLife = {}

type Floating = { model: Model, base: CFrame, phase: number }
type Foam = { part: BasePart, base: CFrame, transparency: number, phase: number }

local function collectBuoys(folder: Instance): { Floating }
	local buoys = {}
	for index, child in folder:GetChildren() do
		if child:IsA("Model") then
			table.insert(buoys, { model = child, base = child:GetPivot(), phase = index * 1.3 })
		end
	end
	return buoys
end

local function collectFoam(folder: Instance): { Foam }
	local foam = {}
	for index, child in folder:GetChildren() do
		if child:IsA("BasePart") then
			table.insert(foam, {
				part = child,
				base = child.CFrame,
				transparency = child.Transparency,
				phase = index * 0.21,
			})
		end
	end
	return foam
end

local function animate(buoys: { Floating }, foam: { Foam })
	local elapsed, sinceFoam = 0, 0
	RunService.Heartbeat:Connect(function(dt: number)
		elapsed += dt
		for _, buoy in buoys do
			local t = elapsed + buoy.phase
			local bob = math.sin(t * 1.4) * EFFECTS.BuoyBobAmplitude
			buoy.model:PivotTo(
				buoy.base
					* CFrame.new(0, bob, 0)
					* CFrame.Angles(math.sin(t * 0.9) * 0.07, 0, math.sin(t * 1.1) * 0.07)
			)
		end
		sinceFoam += dt
		if sinceFoam < FOAM_UPDATE_SECONDS then
			return
		end
		sinceFoam = 0
		for _, piece in foam do
			local wave = math.sin(elapsed * 2 * math.pi / EFFECTS.FoamPulseSeconds + piece.phase)
			-- Las piezas miran hacia afuera (Z local): -Z es hacia la arena.
			piece.part.CFrame = piece.base * CFrame.new(0, 0, -wave * FOAM_TRAVEL_STUDS)
			piece.part.Transparency = piece.transparency
				+ (1 - piece.transparency) * (0.5 + 0.5 * wave) * 0.6
		end
	end)
end

-- Destellos del sol sobre el mar: un emisor plano del tamaño del océano visible.
local function sunGlints()
	local plane = Instance.new("Part")
	plane.Name = "DestellosDelSol"
	plane.Size =
		Vector3.new(WorldLayout.boundaryRadius * 2.4, 0.2, WorldLayout.boundaryRadius * 2.4)
	plane.CFrame = CFrame.new(0, WorldLayout.waterLevel + 0.3, 0)
	plane.Transparency = 1
	plane.Anchored = true
	plane.CanCollide = false
	plane.CanQuery = false
	plane.CanTouch = false
	plane.Parent = Workspace
	local glints = Instance.new("ParticleEmitter")
	glints.Texture = Assets.Particles.Sparkle
	glints.Shape = Enum.ParticleEmitterShape.Box
	glints.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	glints.Rate = 45
	glints.Lifetime = NumberRange.new(0.3, 0.7)
	glints.Speed = NumberRange.new(0)
	glints.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, 0.9),
		NumberSequenceKeypoint.new(1, 0),
	})
	glints.LightEmission = 1
	glints.Color = ColorSequence.new(Color3.fromRGB(255, 252, 230))
	glints.Parent = plane
end

local function jumpingFish()
	task.spawn(function()
		local rng = Random.new()
		while true do
			task.wait(rng:NextNumber(EFFECTS.JumpingFishMinSeconds, EFFECTS.JumpingFishMaxSeconds))
			local angle = rng:NextNumber(0, math.pi * 2)
			local radius = rng:NextNumber(WorldLayout.shoreRadius + 30, WorldLayout.shelfRadius)
			local from = Vector3.new(
				math.cos(angle) * radius,
				WorldLayout.waterLevel,
				math.sin(angle) * radius
			)
			local heading = rng:NextNumber(0, math.pi * 2)
			local to = from
				+ Vector3.new(math.cos(heading), 0, math.sin(heading)) * rng:NextNumber(6, 10)
			local fish =
				FishModel.build(JUMP_FISH[rng:NextInteger(1, #JUMP_FISH)], rng:NextNumber(1, 1.6))
			Fx.splash(from, 0.7)
			Sounds.play("Plop", from)
			FishModel.arc(fish, from, to, rng:NextNumber(3, 5), 0.9, function()
				Fx.splash(to, 0.8)
				Sounds.play("Plop", to)
				fish:Destroy()
			end)
		end
	end)
end

function SeaLife.start()
	sunGlints()
	jumpingFish()
	task.spawn(function()
		local map = Workspace:WaitForChild(Protocol.Map.Root, math.huge)
		local buoys = collectBuoys(map:WaitForChild(Protocol.Map.Buoys, math.huge))
		local foam = collectFoam(map:WaitForChild(Protocol.Map.Foam, math.huge))
		animate(buoys, foam)
	end)
end

return SeaLife
