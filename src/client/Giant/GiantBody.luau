--!strict
--[[
	GiantBody

	El cuerpo del gigante en el cliente y su movimiento continuo: crece
	hacia el alto de su etapa (GiantStages) y cambia al modelo de esa etapa
	(<base>E1..E4), respira, se mece en el agua y mira alrededor. Tiene un contorno rojo para verse amenazante, que late y
	se enciende más cuanto más enojado está (EstadoGigante.Anger). Expone
	"palancas" (salto, giro, atención) que usan las reacciones para animar
	momentos puntuales. Todo por CFrame y escala, sin rigs.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local GiantStages = require(ReplicatedStorage.Shared.GiantStages)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)

local EFFECTS = UIConfig.Effects
local TURN_SHARPNESS = 6 -- qué tan rápido gira hacia su objetivo (1/s)

export type Body = {
	model: Model,
	base: CFrame,
	lift: NumberValue, -- studs extra hacia arriba (saltos)
	spin: NumberValue, -- grados extra de giro (piruetas)
	setStage: (stage: number, instant: boolean?) -> (),
	lookAt: (position: Vector3, seconds: number) -> (),
	height: () -> number,
	top: () -> Vector3, -- punto sobre la cabeza
	destroy: () -> (),
}

local GiantBody = {}

local function placeholder(): (Model, number)
	local model = Instance.new("Model")
	local function ball(name: string, size: number, offset: Vector3, color: Color3)
		local part = Instance.new("Part")
		part.Name = name
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.one * size
		part.CFrame = CFrame.new(offset)
		part.Color = color
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.Parent = model
	end
	ball("Cuerpo", 4, Vector3.new(0, 2, 0), Color3.fromRGB(52, 66, 92))
	ball("Panza", 2.6, Vector3.new(0, 1.6, -0.9), Color3.fromRGB(244, 246, 250))
	ball("Aleta", 1.4, Vector3.new(0, 4.1, 0.4), Color3.fromRGB(52, 66, 92))
	model.WorldPivot = CFrame.new()
	return model, 4
end

local function angleTowards(from: Vector3, to: Vector3): number
	local d = to - from
	-- El modelo mira a -Z: Angles(0, y, 0) lo apunta a (-sin y, 0, -cos y).
	return math.deg(math.atan2(-d.X, -d.Z))
end

-- Modelo de la etapa o, si falta, el de la etapa anterior más cercana.
local function templateFor(folder: Instance, def: Config.GiantDef, stage: number): Model?
	for s = stage, 1, -1 do
		local template = folder:FindFirstChild(`{def.modelBase}E{s}`)
		if template and template:IsA("Model") then
			return template
		end
	end
	return nil
end

function GiantBody.spawn(def: Config.GiantDef, base: CFrame): Body
	local folder = ReplicatedStorage:WaitForChild(Protocol.GiantModelsFolder)
	-- Contenedor fijo: adentro va el modelo de la etapa actual, que cambia al crecer.
	local model = Instance.new("Model")
	model.Name = def.id
	model.WorldPivot = base
	model.Parent = Workspace
	local inner: Model? = nil
	local innerTemplate: Model? = nil
	local baseHeight = 1
	local function dress(stage: number)
		local template = templateFor(folder, def, stage)
		if inner and template == innerTemplate then
			return
		end
		innerTemplate = template
		local nextInner: Model
		if template then
			nextInner = template:Clone()
			local stored = nextInner:GetAttribute(Protocol.GiantModelAttributes.BaseHeight)
			baseHeight = if type(stored) == "number" then stored else nextInner:GetExtentsSize().Y
		else
			nextInner, baseHeight = placeholder()
		end
		nextInner:ScaleTo(model:GetScale())
		nextInner:PivotTo(model:GetPivot())
		if inner then
			inner:Destroy()
		end
		nextInner.Parent = model
		inner = nextInner
	end
	dress(1)

	-- Contorno rojo: se ve amenazante incluso a lo lejos y de noche.
	local outline = Instance.new("Highlight")
	outline.FillTransparency = 1
	outline.OutlineColor = Color3.fromRGB(255, 40, 40)
	outline.OutlineTransparency = 0.35
	outline.DepthMode = Enum.HighlightDepthMode.Occluded
	outline.Parent = model

	outline.FillColor = Color3.fromRGB(255, 20, 10)
	local stateFolder = ReplicatedStorage:WaitForChild(Protocol.GiantStateFolder)

	local lift, spin = Instance.new("NumberValue"), Instance.new("NumberValue")
	local currentHeight = GiantStages.heightFor(1)
	local targetHeight = currentHeight
	local yaw, attentionYaw, attentionUntil = 0, 0, 0
	local elapsed = 0

	local connection = RunService.RenderStepped:Connect(function(dt: number)
		elapsed += dt
		currentHeight += (targetHeight - currentHeight) * (1 - math.exp(
			-dt / EFFECTS.GiantGrowthSeconds
		))
		local breath = 1
			+ math.sin(elapsed * 2 * math.pi / (EFFECTS.GiantBobSeconds * 1.3))
				* EFFECTS.GiantBreath
		model:ScaleTo(currentHeight / baseHeight * breath)

		local idleYaw = math.sin(elapsed * 2 * math.pi / EFFECTS.GiantLookSeconds)
			* EFFECTS.GiantLookDegrees
		local wanted = if os.clock() < attentionUntil then attentionYaw else idleYaw
		local delta = (wanted - yaw + 180) % 360 - 180
		yaw += delta * (1 - math.exp(-dt * TURN_SHARPNESS))

		local bob = math.sin(elapsed * 2 * math.pi / EFFECTS.GiantBobSeconds)
			* EFFECTS.GiantBobAmplitude
		local value = stateFolder:GetAttribute(Protocol.GiantAttributes.Anger)
		local anger = if type(value) == "number" then value else 0
		local pulse = 0.5 + 0.5 * math.sin(elapsed * (3 + anger * 7))
		outline.OutlineTransparency = 0.35 * (1 - anger) * (1 - pulse * 0.4)
		outline.FillTransparency = 1 - anger * 0.35 * pulse
		-- Enojado se sacude más.
		local roll = math.sin(elapsed * 2 * math.pi / (EFFECTS.GiantBobSeconds * 1.7))
				* EFFECTS.GiantSwayDegrees
			+ math.sin(elapsed * 23) * anger * 2.5
		model:PivotTo(
			base
				* CFrame.new(0, bob + lift.Value, 0)
				* CFrame.Angles(0, math.rad(yaw + spin.Value), math.rad(roll))
		)
	end)

	return {
		model = model,
		base = base,
		lift = lift,
		spin = spin,
		setStage = function(stage: number, instant: boolean?)
			targetHeight = GiantStages.heightFor(stage)
			dress(stage) -- cada etapa puede tener su propio modelo (más grande y feroz)
			if instant then
				currentHeight = targetHeight
			end
		end,
		lookAt = function(position: Vector3, seconds: number)
			attentionYaw = angleTowards(base.Position, position)
			attentionUntil = os.clock() + seconds
		end,
		height = function(): number
			return currentHeight
		end,
		top = function(): Vector3
			return model:GetPivot().Position + Vector3.new(0, currentHeight * 0.92, 0)
		end,
		destroy = function()
			connection:Disconnect()
			lift:Destroy()
			spin:Destroy()
			model:Destroy()
		end,
	}
end

return GiantBody
