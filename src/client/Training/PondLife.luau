--!strict
--[[
	PondLife

	Lo que se mueve en los estanques temáticos (las piezas vienen del mapa,
	tools/estanques):
		Koi           nada en círculo alrededor del centro de su estanque
		              (atributos Radio y Fase: dónde empezó)
		RocaFlotante  sube y baja despacio, cada una a su ritmo, y gira un poco
		Cascada       bruma donde el chorro cae al agua
	Solo se mueve lo que está cerca de la cámara (PondAnimateDistance). Es solo
	decoración: no cambia nada del juego.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Assets = require(ReplicatedStorage.Shared.Assets)
local Performance = require(ReplicatedStorage.Shared.UIConfig.Performance)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local FxQuality = require(script.Parent.Parent.Settings.FxQuality)

local ANIMATE_DISTANCE = Performance.PondAnimateDistance
local KOI_SPEED = 1.8 -- studs por segundo
local ROCK_BOB = 0.7 -- studs que sube y baja una roca
local ROCK_SPIN = 0.12 -- radianes por segundo

type Swimmer = { model: Model, center: Vector3, radius: number, start: number, offset: CFrame }
type Floater = { model: Model, base: CFrame, phase: number }

local PondLife = {}

-- Marco de nado en el ángulo `angle` (radianes): en la orilla del círculo, mirando hacia
-- donde avanza (sentido antihorario visto desde arriba, como lo arma tools/estanques).
local function swimFrame(center: Vector3, radius: number, angle: number): CFrame
	local position = center + Vector3.new(math.cos(angle), 0, math.sin(angle)) * radius
	local ahead = Vector3.new(-math.sin(angle), 0, math.cos(angle))
	return CFrame.lookAt(position, position + ahead)
end

local function swimmer(model: Model): Swimmer?
	local radius, phase = model:GetAttribute("Radio"), model:GetAttribute("Fase")
	if type(radius) ~= "number" or type(phase) ~= "number" or radius <= 0 then
		return nil
	end
	local start = math.rad(phase)
	local pivot = model:GetPivot()
	local center = pivot.Position - Vector3.new(math.cos(start), 0, math.sin(start)) * radius
	local offset = swimFrame(center, radius, start):Inverse() * pivot
	return { model = model, center = center, radius = radius, start = start, offset = offset }
end

local function mist(waterfall: BasePart)
	local foot = Instance.new("Attachment")
	foot.Name = "PieCascada"
	foot.Position = Vector3.new(0, 0, waterfall.Size.Z / 2) -- el chorro baja por su +Z
	foot.Parent = waterfall
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = Assets.Particles.Mist
	emitter.Color = ColorSequence.new(Color3.fromRGB(235, 248, 255))
	emitter.LightEmission = 0.3
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Size = NumberSequence.new(1.5, 4.5)
	emitter.Lifetime = NumberRange.new(1.6, 2.6)
	emitter.Speed = NumberRange.new(0.8, 2)
	emitter.SpreadAngle = Vector2.new(180, 40)
	emitter.Acceleration = Vector3.new(0, 1, 0)
	emitter.Rate = 7
	emitter.Parent = foot
	FxQuality.scaleEmitter(emitter)
end

function PondLife.start()
	local map = Workspace:WaitForChild(Protocol.Map.Root)
	local swimmers: { Swimmer } = {}
	local floaters: { Floater } = {}
	for _, descendant in map:GetDescendants() do
		if descendant:IsA("Model") and string.match(descendant.Name, "^Koi%d+$") then
			local fish = swimmer(descendant)
			if fish then
				table.insert(swimmers, fish)
			end
		elseif descendant:IsA("Model") and string.match(descendant.Name, "^RocaFlotante%d+$") then
			table.insert(floaters, {
				model = descendant,
				base = descendant:GetPivot(),
				phase = #floaters * 2.1,
			})
		elseif descendant.Name == "Cascada" and descendant:IsA("BasePart") then
			mist(descendant)
		end
	end

	RunService.RenderStepped:Connect(function()
		local eye = Workspace.CurrentCamera.CFrame.Position
		local t = os.clock()
		for _, fish in swimmers do
			if (eye - fish.center).Magnitude < ANIMATE_DISTANCE then
				local angle = fish.start + t * KOI_SPEED / fish.radius
				fish.model:PivotTo(swimFrame(fish.center, fish.radius, angle) * fish.offset)
			end
		end
		for _, rock in floaters do
			if (eye - rock.base.Position).Magnitude < ANIMATE_DISTANCE then
				local lift = math.sin(t * 0.8 + rock.phase) * ROCK_BOB
				rock.model:PivotTo(
					rock.base
						* CFrame.new(0, lift, 0)
						* CFrame.Angles(0, t * ROCK_SPIN + rock.phase, 0)
				)
			end
		end
	end)
end

return PondLife
