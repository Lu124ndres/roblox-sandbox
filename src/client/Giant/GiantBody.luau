--!strict
--[[
	GiantBody: el gigante en el cliente crece hacia el alto de su etapa con el
	modelo de esa etapa (<base>E1..E4), respira, se mece y mira alrededor, con un
	contorno que late con el enojo (GiantOutline). "Palancas": salto, giro, atención.
	ScaleTo solo al cambiar la escala más de GiantScaleStep. Con huesos: la orca nada
	(OrcaSwim), el dragón vuela (DragonFly), el minotauro y el zorro se animan (*Stand).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local GiantStages = require(ReplicatedStorage.Shared.GiantStages)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Performance = require(ReplicatedStorage.Shared.UIConfig.Performance)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local FxQuality = require(script.Parent.Parent.Settings.FxQuality)
local GiantOutline = require(script.Parent.GiantOutline)
local OrcaSwim = require(script.Parent.OrcaSwim)
local DragonFly = require(script.Parent.DragonFly)
local MinoStand = require(script.Parent.MinoStand)
local ZorroStand = require(script.Parent.ZorroStand)
local GiantTemplates = require(script.Parent.GiantTemplates)
local EFFECTS, TURN_SHARPNESS = UIConfig.Effects, 6 -- giro hacia su objetivo (1/s)

export type Body = {
	model: Model,
	base: CFrame,
	lift: NumberValue, -- studs extra hacia arriba (saltos)
	spin: NumberValue, -- grados extra de giro (piruetas)
	setStage: (stage: number, instant: boolean?) -> (),
	lookAt: (position: Vector3, seconds: number) -> (),
	height: () -> number,
	top: () -> Vector3, -- punto sobre la cabeza
	mouth: () -> Vector3, -- adonde vuelan los peces
	water: () -> Vector3, -- el agua justo bajo el gigante
	fed: (info: OrcaSwim.FedInfo) -> (), -- le llegó un pez: su animación especial al comer
	swims: boolean, -- se anima solo (orca, dragón, minotauro): muerde en vez de saltar
	flies: boolean, -- vuela (dragón): sin salpicaduras al comer
	destroy: () -> (),
}

local GiantBody = {}

local function angleTowards(from: Vector3, to: Vector3): number
	local d = to - from -- el modelo mira a -Z: Angles(0, y, 0) apunta a (-sin y, 0, -cos y)
	return math.deg(math.atan2(-d.X, -d.Z))
end

function GiantBody.spawn(def: Config.GiantDef, base: CFrame): Body
	local folder = ReplicatedStorage:WaitForChild(Protocol.GiantModelsFolder) -- adentro: la etapa actual
	local model = Instance.new("Model")
	model.Name = def.id
	model.WorldPivot = base
	model.Parent = Workspace
	local inner: Model? = nil
	local innerTemplate: Model? = nil
	local baseHeight = 1
	local shownScale = 0 -- última escala pasada a ScaleTo
	local function dress(stage: number)
		local template, tint = GiantTemplates.templateFor(folder, def, stage)
		if inner and template == innerTemplate then
			return
		end
		innerTemplate = template
		local nextInner: Model
		if template then
			nextInner = template:Clone()
			if tint then
				GiantTemplates.tint(nextInner, tint)
			end
			local stored = nextInner:GetAttribute(Protocol.GiantModelAttributes.BaseHeight)
			baseHeight = if type(stored) == "number" then stored else nextInner:GetExtentsSize().Y
		else
			nextInner, baseHeight = GiantTemplates.placeholder()
		end
		nextInner:ScaleTo(model:GetScale())
		nextInner:PivotTo(model:GetPivot())
		FxQuality.scaleAll(nextInner)
		if inner then
			inner:Destroy()
		end
		nextInner.Parent = model
		inner = nextInner
		shownScale = 0 -- otro alto base: hay que reescalar
	end
	dress(1)
	local first = GiantTemplates.templateFor(folder, def, 1)
	local swim = OrcaSwim.attach(first, base.Position)
		or DragonFly.attach(first, base.Position)
		or ZorroStand.attach(first, base.Position) -- antes que el minotauro: también tiene orejas y brazos
		or MinoStand.attach(first, base.Position)
	local outline = GiantOutline.attach(model)
	local stateFolder = ReplicatedStorage:WaitForChild(Protocol.GiantStateFolder)
	local lift, spin = Instance.new("NumberValue"), Instance.new("NumberValue")
	local currentHeight = GiantStages.heightFor(1)
	local targetHeight = currentHeight
	local yaw, attentionYaw, attentionUntil = 0, 0, 0
	local elapsed = 0

	local function updateScale(dt: number)
		currentHeight += (targetHeight - currentHeight) * (1 - math.exp(
			-dt / EFFECTS.GiantGrowthSeconds
		))
		if math.abs(targetHeight - currentHeight) < targetHeight * Performance.GiantScaleStep then
			currentHeight = targetHeight -- ya casi llegó: se termina de golpe
		end
		local scale = currentHeight / baseHeight
		local change = if shownScale > 0 then math.abs(scale / shownScale - 1) else math.huge
		if
			change > Performance.GiantScaleStep or (currentHeight == targetHeight and change > 0)
		then
			model:ScaleTo(scale)
			shownScale = scale
		end
	end

	local connection = RunService.RenderStepped:Connect(function(dt: number)
		elapsed += dt
		updateScale(dt)
		outline(dt, elapsed)
		local anger = tonumber(stateFolder:GetAttribute(Protocol.GiantAttributes.Anger)) or 0
		if swim then
			model:PivotTo(swim.step(dt, currentHeight, lift.Value, spin.Value, anger, inner))
			return
		end

		local idleYaw = math.sin(elapsed * 2 * math.pi / EFFECTS.GiantLookSeconds)
			* EFFECTS.GiantLookDegrees
		local wanted = if os.clock() < attentionUntil then attentionYaw else idleYaw
		local delta = (wanted - yaw + 180) % 360 - 180
		yaw += delta * (1 - math.exp(-dt * TURN_SHARPNESS))

		-- Respirar: sube y baja un poquito en vez de reescalar todo el modelo.
		local breath = math.sin(elapsed * 2 * math.pi / (EFFECTS.GiantBobSeconds * 1.3))
			* EFFECTS.GiantBreath
			* currentHeight
			* Performance.GiantBreathLift
		local bob = math.sin(elapsed * 2 * math.pi / EFFECTS.GiantBobSeconds)
				* EFFECTS.GiantBobAmplitude
			+ breath
		local roll = math.sin(elapsed * 2 * math.pi / (EFFECTS.GiantBobSeconds * 1.7))
				* EFFECTS.GiantSwayDegrees
			+ math.sin(elapsed * 23) * anger * 2.5 -- enojado se sacude más
		model:PivotTo(
			base
				* CFrame.new(0, bob + lift.Value, 0)
				* CFrame.Angles(0, math.rad(yaw + spin.Value), math.rad(roll))
		)
	end)

	local function top(): Vector3
		return model:GetPivot().Position + Vector3.new(0, currentHeight * 0.92, 0)
	end

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
		top = if swim then swim.top else top,
		mouth = if swim then swim.mouth else top,
		water = if swim
			then swim.water
			else function(): Vector3
				return Vector3.new(base.X, WorldLayout.waterLevel, base.Z)
			end,
		fed = if swim then swim.fed else function(_: OrcaSwim.FedInfo) end,
		swims = swim ~= nil,
		flies = first ~= nil and first:FindFirstChild("AlaIzq1", true) ~= nil,
		destroy = function()
			connection:Disconnect()
			if swim then
				swim.destroy()
			end
			lift:Destroy()
			spin:Destroy()
			model:Destroy()
		end,
	}
end

return GiantBody
