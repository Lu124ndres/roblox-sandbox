--!strict
--[[
	GiantView

	Dibuja al gigante en el centro del Cráter del Abismo y lo hace reaccionar:
		- al comer: le llegan los peces volando (FeedThrow), gira hacia quien
		  lo alimentó, rebota, salpica, suelta corazones y hace "ñam";
		- al llenarse, en el descanso y al volver: GiantCycleFx;
		- al pasar de etapa: ruge, la cámara tiembla y crece hasta su nuevo
		  tamaño (3, 8, 15 y 25 veces un jugador) entre olas y espuma;
		- cada tanto: gruñe y echa un chorro de agua por el espiráculo.

	El servidor solo publica quién es, cuánto comió y en qué fase está
	(EstadoGigante y GiantFed). Todo el movimiento es local, a 60 fps.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local GiantStages = require(ReplicatedStorage.Shared.GiantStages)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local CameraShake = require(script.Parent.Parent.Effects.CameraShake)
local Fx = require(script.Parent.Parent.Effects.Fx)
local FeedThrow = require(script.Parent.FeedThrow)
local GiantBody = require(script.Parent.GiantBody)
local GiantCycleFx = require(script.Parent.GiantCycleFx)

local ATTR = Protocol.GiantAttributes
local EFFECTS = UIConfig.Effects

-- Centro del cráter, mirando hacia el puente (-Z). Sale del layout y no del
-- mapa para no depender de que la pieza ya haya llegado al cliente.
local CENTER = WorldZones.craterCenter
local BASE = CFrame.new(CENTER + Vector3.new(0, WorldLayout.pedestalTop, 0))
local GROWL_MIN_SECONDS, GROWL_MAX_SECONDS = 18, 40

local GiantView = {}

local defsById: { [string]: Config.GiantDef } = {}
for _, def in Config.Giants.chain do
	defsById[def.id] = def
end

local function waterAround(body: GiantBody.Body, spread: number): Vector3
	local angle = math.random() * math.pi * 2
	local radius = body.height() * spread
	return CENTER
		+ Vector3.new(math.cos(angle) * radius, WorldLayout.waterLevel, math.sin(angle) * radius)
end

local function hop(value: NumberValue, height: number, upSeconds: number)
	local up = TweenService:Create(
		value,
		TweenInfo.new(upSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Value = height }
	)
	local down = TweenService:Create(
		value,
		TweenInfo.new(upSeconds * 1.6, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
		{ Value = 0 }
	)
	up.Completed:Once(function()
		down:Play()
	end)
	up:Play()
end

-- Qué tan cerca está el jugador local del cráter (0 lejos, 1 adentro).
local function nearness(): number
	local character = Players.LocalPlayer.Character
	return if character then WorldZones.craterBlend(character:GetPivot().Position) else 0
end

local function onFed(body: GiantBody.Body, character: Model)
	body.lookAt(character:GetPivot().Position, EFFECTS.GiantAttentionSeconds)
	local scale = body.height() / GiantStages.heightFor(1)
	hop(body.lift, EFFECTS.GiantBounceHeight * scale, 0.18)
	local top = body.top()
	Sounds.play("Chomp", top)
	Fx.hearts(top, 4)
	Fx.sparkle(top, UIConfig.Colors.Coins, 16)
	for _ = 1, 3 do
		Fx.splash(waterAround(body, 0.3), 1.4 * math.sqrt(scale))
	end
end

-- Cambio de etapa: rugido, temblor y crecimiento entre olas.
local function onStage(body: GiantBody.Body, stage: number)
	local newHeight = GiantStages.heightFor(stage)
	local scale = newHeight / GiantStages.heightFor(1)
	Sounds.play("Roar", body.top())
	Sounds.play("OrcaCall", body.top(), 0.7)
	CameraShake.shake(0.6 + 0.4 * stage * nearness(), 2.4)
	hop(body.lift, newHeight * 0.12, 0.6)
	TweenService
		:Create(
			body.spin,
			TweenInfo.new(1.4, Enum.EasingStyle.Quad),
			{ Value = body.spin.Value + 360 }
		)
		:Play()
	body.setStage(stage)
	task.delay(1.2, function()
		local water = CENTER + Vector3.new(0, WorldLayout.waterLevel, 0)
		Sounds.play("BigSplash", water)
		Fx.splash(water, 3 + scale)
		for k = 1, 3 do
			Fx.ring(water, newHeight * (0.4 + k * 0.35), 1.2 + k * 0.4)
		end
		for _ = 1, 6 do
			Fx.splash(waterAround(body, 0.45), 1.5 + scale * 0.3)
		end
		Fx.sparkle(body.top(), UIConfig.Colors.Coins, 50)
		CameraShake.shake(0.4 * stage * nearness(), 1.2)
	end)
end

local function ambientLoop(getBody: () -> GiantBody.Body?)
	task.spawn(function()
		while true do
			task.wait(math.random(EFFECTS.SpoutMinSeconds, EFFECTS.SpoutMaxSeconds))
			local body = getBody()
			if body then
				local top = body.top()
				Fx.spout(top, math.max(1, body.height() / 15))
				Sounds.play("Spout", top)
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(math.random(GROWL_MIN_SECONDS, GROWL_MAX_SECONDS))
			local body = getBody()
			if body and nearness() > 0.2 then
				Sounds.play("Roar", body.top(), 0.8)
				CameraShake.shake(0.25 * nearness(), 0.8)
			end
		end
	end)
end

function GiantView.start()
	local stateFolder = ReplicatedStorage:WaitForChild(Protocol.GiantStateFolder)

	local body: GiantBody.Body? = nil
	local currentId: string? = nil
	local lastStage = 1

	local function refresh()
		local id = stateFolder:GetAttribute(ATTR.Id)
		local progress = stateFolder:GetAttribute(ATTR.Progress)
		if type(id) ~= "string" or type(progress) ~= "number" then
			return
		end
		local stage = GiantStages.stageFor(progress)
		if id ~= currentId then
			local def = defsById[id]
			if not def then
				return
			end
			if body then
				body.destroy()
			end
			currentId, lastStage = id, stage
			local spawned = GiantBody.spawn(def, BASE)
			spawned.setStage(stage, true)
			body = spawned
			return
		end
		if body and stage > lastStage then
			onStage(body, stage)
		end
		lastStage = stage
	end

	stateFolder.AttributeChanged:Connect(refresh)
	refresh()

	FeedThrow.listen(function()
		return if body then body.top() else nil
	end, function(character: Model)
		if body then
			onFed(body, character)
		end
	end)
	ambientLoop(function() -- sin gruñidos ni chorros mientras está sumergido
		return if body and body.model.Parent then body else nil
	end)
	GiantCycleFx.watch(function() -- despedida, descanso y llegada
		return body
	end)
end

return GiantView
