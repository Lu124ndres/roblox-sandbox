--!strict
--[[
	CycleView

	Avisos y ambiente del ciclo del gigante para el jugador local:
		- carteles al llenarse, al empezar el descanso y al llegar el siguiente;
		- "+1 Kill" cuando ayudó a llenar al monstruo;
		- la guarida del descanso emerge del lago (RestArena la sube) con una
		  ola y suben destellos: sobre ella se entrena solo (GiantCycle);
		- avisos al subir o bajar de la guarida y 10 s antes de que se hunda.
	El "+N poder" de cada segundo lo muestra TrainingController.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Assets = require(ReplicatedStorage.Shared.Assets)
local Config = require(ReplicatedStorage.Shared.Config)
local GiantPool = require(ReplicatedStorage.Shared.GiantPool)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local Fx = require(script.Parent.Parent.Effects.Fx)
local GiantName = require(script.Parent.Parent.GiantName)
local Toasts = require(script.Parent.Parent.Toasts)

local COLORS = UIConfig.Colors
local CYCLE = Config.Giants.cycle
local ATTR = Protocol.GiantAttributes
local CHECK_SECONDS = 0.5
local WARNING_SECONDS = 10
local CENTER = WorldZones.craterCenter

local CycleView = {}

-- Destellos que suben desde la guarida durante el descanso.
local function buildSparkles(): ParticleEmitter
	local radius = WorldLayout.restArenaRadius
	local disc = Instance.new("Part")
	disc.Name = "DestellosDescanso"
	disc.Shape = Enum.PartType.Cylinder
	disc.Size = Vector3.new(0.2, radius * 2, radius * 2)
	disc.CFrame = CFrame.new(CENTER + Vector3.new(0, WorldLayout.restArenaTop + 0.3, 0))
		* CFrame.Angles(0, 0, math.rad(90))
	disc.Transparency = 1
	disc.Anchored, disc.CanCollide, disc.CanQuery, disc.CanTouch = true, false, false, false
	local rising = Instance.new("ParticleEmitter")
	rising.Texture = Assets.Particles.Sparkle
	rising.Color = ColorSequence.new(COLORS.Power, COLORS.Coins)
	rising.LightEmission = 1
	rising.Size = NumberSequence.new(1.4, 0)
	rising.Lifetime = NumberRange.new(2.5, 4)
	rising.Speed = NumberRange.new(6, 12)
	rising.EmissionDirection = Enum.NormalId.Right -- el eje del disco apunta hacia arriba
	rising.Rate = 40
	rising.Enabled = false
	rising.Parent = disc
	disc.Parent = Workspace
	return rising
end

-- La guarida emerge del lago (la mueve el servidor): ola y onda al salir.
local function reveal()
	local water = CENTER + Vector3.new(0, WorldLayout.waterLevel, 0)
	Sounds.play("BigSplash", water)
	Fx.splash(water, 6)
	for k = 1, 3 do
		Fx.ring(water, WorldLayout.restArenaRadius * (0.6 + k * 0.4), 1 + k * 0.4)
	end
end

-- Cuánto dura este descanso (depende de cuántos jugadores hay): sale de PhaseEndsAt.
local function restLength(stateFolder: Instance): string
	local endsAt = stateFolder:GetAttribute(ATTR.PhaseEndsAt)
	local seconds = if type(endsAt) == "number"
		then math.max(1, math.round(endsAt - Workspace:GetServerTimeNow()))
		else CYCLE.restSeconds
	return if seconds % 60 == 0 then `{seconds // 60} min` else `{seconds} s`
end

function CycleView.start(toasts: Toasts.Toasts)
	local player = Players.LocalPlayer
	local stateFolder = ReplicatedStorage:WaitForChild(Protocol.GiantStateFolder)
	local sparkles = buildSparkles()
	local last: unknown = stateFolder:GetAttribute(ATTR.Phase)

	local function onPhase(announce: boolean)
		local phase = stateFolder:GetAttribute(ATTR.Phase)
		sparkles.Enabled = phase == "rest"
		if not announce then
			return
		end
		if phase == "rest" then
			reveal()
			Sounds.play("StageUp")
			toasts.banner(
				`¡Descanso! Toca IR A LA GUARIDA: entrenamiento x{GiantPool.restMultiplier()} por {restLength(
					stateFolder
				)}`,
				COLORS.Power
			)
		elseif phase == "arriving" then
			toasts.banner(`¡Llega {GiantName.current()}!`, COLORS.Feeding)
		elseif phase == "feeding" and last == "arriving" then
			toasts.show(`¡A pescar! {GiantName.current(true)} tiene hambre`, COLORS.Fishing)
		end
	end
	stateFolder:GetAttributeChangedSignal(ATTR.Phase):Connect(function()
		onPhase(true)
		last = stateFolder:GetAttribute(ATTR.Phase)
	end)
	onPhase(false)

	-- +1 Kill: este jugador ayudó a llenar al monstruo.
	local kills = player:GetAttribute(Protocol.PlayerAttributes.Kills)
	player:GetAttributeChangedSignal(Protocol.PlayerAttributes.Kills):Connect(function()
		local now = player:GetAttribute(Protocol.PlayerAttributes.Kills)
		if type(now) == "number" and type(kills) == "number" and now > kills then
			Sounds.play("LegendaryCatch")
			toasts.banner(`+1 Kill · {GiantName.current(true)}`, COLORS.Furious)
		end
		kills = now
	end)

	local inside, warned = false, false
	task.spawn(function()
		while true do
			task.wait(CHECK_SECONDS)
			local character = player.Character
			local resting = stateFolder:GetAttribute(ATTR.Phase) == "rest"
			local now = resting
				and character ~= nil
				and WorldZones.isInRestArena(character:GetPivot().Position)
			if now ~= inside and resting then
				if now then
					toasts.show("¡Entrenando en la guarida del volcán!", COLORS.Power)
				else
					toasts.show(
						"Saliste de la guarida: vuelve para seguir entrenando",
						COLORS.Warning
					)
				end
			end
			inside = now
			local endsAt = stateFolder:GetAttribute(ATTR.PhaseEndsAt)
			local left = if type(endsAt) == "number"
				then endsAt - Workspace:GetServerTimeNow()
				else math.huge
			if resting and left <= WARNING_SECONDS and not warned then
				warned = true
				toasts.banner(`¡La guarida se hunde en {WARNING_SECONDS} s!`, COLORS.Warning)
			elseif not resting then
				warned = false
			end
		end
	end)
end

return CycleView
