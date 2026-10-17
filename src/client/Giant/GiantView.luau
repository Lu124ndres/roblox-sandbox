--!strict
--[[
	GiantView

	Dibuja al gigante en el centro del Cráter del Abismo y lo hace reaccionar:
		- al comer: le llegan los peces volando (FeedThrow), gira hacia quien
		  lo alimentó y rebota (la orca muerde), salpica, suelta corazones;
		- al llenarse, en el descanso y al volver: GiantCycleFx;
		- al pasar de etapa: evoluciona (GiantEvolution: carga, estallido con el
		  cambio de modelo y calma) y crece (3, 8, 15, 30 jugadores);
		- cada tanto: gruñe y echa un chorro (la orca, al respirar). Todo local.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local FishCatalog = require(ReplicatedStorage.Shared.FishCatalog)
local GiantStages = require(ReplicatedStorage.Shared.GiantStages)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local CameraShake = require(script.Parent.Parent.Effects.CameraShake)
local Fx = require(script.Parent.Parent.Effects.Fx)
local GroundFx = require(script.Parent.Parent.Effects.GroundFx)
local FeedThrow = require(script.Parent.FeedThrow)
local GiantBody = require(script.Parent.GiantBody)
local FedInfo = require(script.Parent.FedInfo)
local GiantCycleFx = require(script.Parent.GiantCycleFx)
local GiantEvolution = require(script.Parent.GiantEvolution)

local ATTR, EFFECTS = Protocol.GiantAttributes, UIConfig.Effects

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
	return body.water() + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
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

local streak, lastFed = 0, -math.huge

local function onFed(body: GiantBody.Body, character: Model, fishId: string)
	local from = character:GetPivot().Position
	body.lookAt(from, EFFECTS.GiantAttentionSeconds)
	local scale = body.height() / GiantStages.heightFor(1)
	streak = if os.clock() - lastFed > FedInfo.STREAK_GAP then 1 else streak + 1
	lastFed = os.clock()
	if body.swims then
		local _, rarity = FishCatalog.rarity(fishId)
		local isLocal = character == Players.LocalPlayer.Character
		body.fed({
			from = from,
			fishId = fishId,
			rarity = rarity,
			isLocal = isLocal,
			streak = streak,
		})
	else
		hop(body.lift, EFFECTS.GiantBounceHeight * scale, 0.18)
	end
	local top = body.mouth()
	Sounds.play("Chomp", top)
	Fx.hearts(top, 4)
	Fx.sparkle(top, UIConfig.Colors.Coins, 16)
	for _ = 1, if body.flies then 0 else 3 do
		GroundFx.splash(waterAround(body, 0.3), 1.4 * math.sqrt(scale))
	end
end

local function ambientLoop(getBody: () -> GiantBody.Body?)
	task.spawn(function()
		while true do
			task.wait(math.random(EFFECTS.SpoutMinSeconds, EFFECTS.SpoutMaxSeconds))
			local body = getBody()
			if body and not body.swims then -- la orca echa el chorro al salir a respirar (OrcaFx)
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
			if body and not body.swims and nearness() > 0.2 then -- los animados rugen con su voz
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
	local evolution: GiantEvolution.Handle? = nil -- la evolución en curso

	local function refresh()
		local id = stateFolder:GetAttribute(ATTR.Id)
		local progress = stateFolder:GetAttribute(ATTR.Progress)
		if type(id) ~= "string" or type(progress) ~= "number" then
			return
		end
		local stage = GiantStages.stageFor(progress)
		if id ~= currentId or stage < lastStage then -- otro monstruo, o volvió a empezar
			local def = defsById[id]
			if not def then
				return
			end
			if evolution then
				evolution.cancel()
				evolution = nil
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
			if evolution then
				evolution.finish() -- otra antes de terminar (admin): la anterior se aplica ya
			end
			evolution = GiantEvolution.begin(body, defsById[id], stage)
		end
		lastStage = stage
	end

	stateFolder.AttributeChanged:Connect(refresh)
	refresh()

	FeedThrow.listen(function()
		return if body then body.mouth() else nil
	end, function(character: Model, fishId: string)
		if body then
			onFed(body, character, fishId)
		end
	end, function()
		return if body then body.height() else 20 -- tamaño de la onda al morder
	end)
	ambientLoop(function() -- sin gruñidos ni chorros mientras está sumergido
		return if body and body.model.Parent then body else nil
	end)
	GiantCycleFx.watch(function() -- despedida, descanso y llegada
		return body
	end)
end

return GiantView
