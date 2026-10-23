--!strict
--[[
	GiantCycleFx

	Animaciones del ciclo del gigante, según EstadoGigante.Phase:
		farewell  se llenó: salta girando y se zambulle en el lago con
		          una ola enorme; después desaparece.
		rest      no está (el que entra a mitad del descanso tampoco lo ve). Cada
		          GUARD_SECONDS se revisa que siga hundido: un cuerpo creado tarde
		          o un salto de mordida o de evolución lo devolvían a su lugar.
		arriving  sale del fondo del lago con su tamaño de etapa 1, ruge y
		          levanta olas.
		feeding   está en su lugar.
	Todo con las palancas de GiantBody (lift y spin) y efectos locales. La voz
	de cada gigante al llegar (de cría): Audio/GiantMoments.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local GiantMoments = require(script.Parent.Parent.Audio.GiantMoments)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local CameraShake = require(script.Parent.Parent.Effects.CameraShake)
local Fx = require(script.Parent.Parent.Effects.Fx)
local GroundFx = require(script.Parent.Parent.Effects.GroundFx)
local CraterMode = require(script.Parent.Parent.Ambient.CraterMode)
local GiantBody = require(script.Parent.GiantBody)

local HIDDEN_DEPTH = 3 -- alturas del gigante bajo el agua mientras no está
local GUARD_SECONDS = 0.5

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

-- Llegada y despedida: ola en el agua, nube de arena en el desierto del minotauro.
local function wave(water: Vector3, height: number, strength: number)
	GroundFx.impact(water, 3 + strength, height * 0.65)
	if not CraterMode.isSand() then
		for k = 2, 4 do
			Fx.ring(water, height * (0.35 + k * 0.3), 1 + k * 0.35)
		end
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
	-- La fanfarria y su voz al irse se cambiaron por una cortinilla suave (pedido del usuario el
	-- 2026-10-23); sin variar el tono, que es música.
	Sounds.play("GiantDefeat", nil, 1, 1, true)
	Fx.sparkle(body.top(), UIConfig.Colors.Coins, 60)
	tween(body.spin, body.spin.Value + 720, 1.8, Enum.EasingStyle.Quad)
	local up = tween(body.lift, height * 0.5, 1, Enum.EasingStyle.Quad)
	up.Completed:Once(function()
		local dive =
			tween(body.lift, -height * 1.4, 1.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.5, wave, body.water(), height, 3)
		dive.Completed:Once(function()
			hide(body)
		end)
	end)
end

local function arrive(body: GiantBody.Body)
	body.setStage(1, true)
	local height = body.height()
	body.lift.Value = -height * 1.4
	local water = body.water()
	local id = GiantMoments.current()
	task.delay(0.6, function()
		wave(water, height, 2)
		GiantMoments.play("arrive", id, 1, water + Vector3.new(0, height, 0), water)
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
	task.spawn(function()
		while true do
			task.wait(GUARD_SECONDS)
			local body = getBody()
			local phase = stateFolder:GetAttribute(Protocol.GiantAttributes.Phase)
			if body and phase == "rest" and body.lift.Value > -body.height() * 2 then
				hide(body)
			end
		end
	end)
end

return GiantCycleFx
