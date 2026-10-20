--!strict
--[[
	CycleView

	Avisos y ambiente del ciclo del gigante para el jugador local:
		- carteles al llenarse, al empezar el descanso y al llegar el siguiente;
		- "+1 Kill" (o "+N Kills" con un pase) cuando ayudó a llenar al monstruo;
		- en el descanso el volcán se vacía (CraterDrain) y la guarida queda en
		  el fondo, con destellos: sobre ella se entrena solo (GiantCycle);
		- avisos al entrar o salir de la guarida y 10 s antes de que vuelva
		  el agua (RestArena regresa a la orilla a los que sigan adentro).
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
local FxQuality = require(script.Parent.Parent.Settings.FxQuality)
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
	FxQuality.scaleEmitter(rising)
	rising.Enabled = false
	rising.Parent = disc
	disc.Parent = Workspace
	return rising
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
		if not announce then
			return
		end
		if phase == "rest" then
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

	-- Destellos solo mientras el volcán está vacío.
	local function onDrained()
		sparkles.Enabled = stateFolder:GetAttribute(ATTR.Drained) == true
	end
	stateFolder:GetAttributeChangedSignal(ATTR.Drained):Connect(onDrained)
	onDrained()

	-- +N Kills: este jugador ayudó a llenar al monstruo (N con los pases con traje). Solo con
	-- los datos ya cargados: al entrar, Kills pasa de 0 a lo guardado y no es una kill nueva.
	local kills = player:GetAttribute(Protocol.PlayerAttributes.Kills)
	player:GetAttributeChangedSignal(Protocol.PlayerAttributes.Kills):Connect(function()
		local now = player:GetAttribute(Protocol.PlayerAttributes.Kills)
		local loaded = player:GetAttribute(Protocol.PlayerAttributes.DataLoaded) == true
		if loaded and type(now) == "number" and type(kills) == "number" and now > kills then
			Sounds.play("LegendaryCatch")
			local gained = now - kills
			toasts.banner(
				`+{gained} {if gained == 1 then "Kill" else "Kills"} · {GiantName.current(true)}`,
				COLORS.Furious
			)
		end
		kills = now
	end)

	local inside, warned = false, false
	task.spawn(function()
		while true do
			task.wait(CHECK_SECONDS)
			local character = player.Character
			local resting = stateFolder:GetAttribute(ATTR.Drained) == true
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
				toasts.banner(`¡El agua vuelve al volcán en {WARNING_SECONDS} s!`, COLORS.Warning)
			elseif not resting then
				warned = false
			end
		end
	end)
end

return CycleView
