--!strict
--[[
	GiantCycleFx

	Animaciones del ciclo del gigante, según EstadoGigante.Phase:
		farewell  se llenó: ruge, salta girando y se zambulle en el lago con
		          una ola enorme; después desaparece.
		rest      no está (el que entra a mitad del descanso tampoco lo ve).
		arriving  sale del fondo del lago con su tamaño de etapa 1, ruge y
		          levanta olas.
		feeding   está en su lugar.
	Todo con las palancas de GiantBody (lift y spin) y efectos locales.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local CameraShake = require(script.Parent.Parent.Effects.CameraShake)
local Fx = require(script.Parent.Parent.Effects.Fx)
local GiantBody = require(script.Parent.GiantBody)

local WATER = WorldZones.craterCenter + Vector3.new(0, WorldLayout.waterLevel, 0)
local HIDDEN_DEPTH = 3 -- alturas del gigante bajo el agua mientras no está

local GiantCycleFx = {}

local function tween(
	value: NumberValue,
	target: number,
	seconds: number,
	style: Enum.EasingStyle,
	direction: Enum.EasingDirection?
): Tween
	local info = TweenInfo.new(seconds, style, direction or Enum.EasingDirection.Out)
	local animation = TweenService:Create(value, info, { Value = target })
	animation:Play()
	return animation
end

local function wave(height: number, strength: number)
	Sounds.play("BigSplash", WATER)
	Fx.splash(WATER, 3 + strength)
	for k = 1, 4 do
		Fx.ring(WATER, height * (0.35 + k * 0.3), 1 + k * 0.35)
	end
	CameraShake.shake(0.5 + strength * 0.2, 1.4)
end

-- Se esconde hundiéndolo muy abajo, sin sacarlo del Workspace: quitar y volver
-- a poner un modelo tan grande hacía que el juego se trabara al llenarse.
local function hide(body: GiantBody.Body)
	body.lift.Value = -body.height() * HIDDEN_DEPTH
end

local function farewell(body: GiantBody.Body)
	local height = body.height()
	Sounds.play("Roar", body.top())
	Sounds.play("StageUp")
	Fx.sparkle(body.top(), UIConfig.Colors.Coins, 60)
	tween(body.spin, body.spin.Value + 720, 1.8, Enum.EasingStyle.Quad)
	local up = tween(body.lift, height * 0.5, 1, Enum.EasingStyle.Quad)
	up.Completed:Once(function()
		local dive =
			tween(body.lift, -height * 1.4, 1.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.5, wave, height, 3)
		dive.Completed:Once(function()
			hide(body)
		end)
	end)
end

local function arrive(body: GiantBody.Body)
	body.setStage(1, true)
	local height = body.height()
	body.lift.Value = -height * 1.4
	Sounds.play("OrcaCall", WATER, 0.8)
	task.delay(0.6, function()
		wave(height, 2)
		Sounds.play("Roar", WATER)
		tween(body.lift, 0, 1.6, Enum.EasingStyle.Back)
		tween(body.spin, body.spin.Value + 360, 1.6, Enum.EasingStyle.Quad)
	end)
end

-- getBody devuelve el cuerpo actual (puede cambiar cuando llega otro gigante).
function GiantCycleFx.watch(getBody: () -> GiantBody.Body?)
	local stateFolder = ReplicatedStorage:WaitForChild(Protocol.GiantStateFolder)
	local last: unknown = stateFolder:GetAttribute(Protocol.GiantAttributes.Phase)
	local function apply(animate: boolean)
		local body = getBody()
		local phase = stateFolder:GetAttribute(Protocol.GiantAttributes.Phase)
		if not body then
			return
		end
		if phase == "farewell" and animate then
			farewell(body)
		elseif phase == "farewell" or phase == "rest" then
			hide(body)
		elseif phase == "arriving" and animate then
			arrive(body)
		elseif body.lift.Value < -body.height() * 2 then
			body.lift.Value = 0 -- estaba escondido (entró a mitad del ciclo)
		end
	end
	stateFolder:GetAttributeChangedSignal(Protocol.GiantAttributes.Phase):Connect(function()
		local phase = stateFolder:GetAttribute(Protocol.GiantAttributes.Phase)
		if phase ~= last then
			last = phase
			apply(true)
		end
	end)
	task.defer(apply, false) -- quien entra a mitad del ciclo ve el estado sin animación
end

return GiantCycleFx
