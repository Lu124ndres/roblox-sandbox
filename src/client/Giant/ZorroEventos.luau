--!strict
--[[
	ZorroEventos

	Los eventos del zorro de agua (Zorro: state.events) vueltos sonido, efectos y
	temblor de cámara. Lo llama ZorroStand cada cuadro con los eventos nuevos:
		howl    aullido (voz por etapa), ondas en el agua y temblor
		fan     abanico de colas: el silbido y destellos cian en las puntas
		crouch  se agacha para saltar: el agua se agita
		land    cae del salto: salpicón (ZorroAgua), ondas y temblor
		shake   se sacude: gotas por todo el cuerpo (ZorroAgua)
		happy   reverencia de juego: corazones
		orbs    fuegos fatuos: orbes de agua que suben a su alrededor
	Los que tienen receta en ZorroVoces (step, yip, pounce, yawn, sniff, splash, bite…)
	suenan con ella; los demás son de su animación al comer (ZorroComerFx).
	Con el hábitat de hielo (CraterMode "ice") el chapoteo pasa a crujido de hielo.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Capas = require(ReplicatedStorage.Shared.Zorro.Comer.Capas)
local Zorro = require(ReplicatedStorage.Shared.Zorro)
local CraterMode = require(script.Parent.Parent.Ambient.CraterMode)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local ZorroVoces = require(script.Parent.Parent.Audio.ZorroVoces)
local CameraShake = require(script.Parent.Parent.Effects.CameraShake)
local Fx = require(script.Parent.Parent.Effects.Fx)
local ZorroAgua = require(script.Parent.Parent.Effects.ZorroAgua)
local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)
local ZorroComerFx = require(script.Parent.ZorroComerFx)
local ZorroFx = require(script.Parent.ZorroFx)

local SHAKE_REACH = 260
local CYAN = Color3.fromRGB(110, 255, 240)

local ZorroEventos = {}

local function shake(position: Vector3, magnitude: number, seconds: number)
	local character = Players.LocalPlayer.Character
	if not character then
		return
	end
	local near = 1 - (character:GetPivot().Position - position).Magnitude / SHAKE_REACH
	if near > 0 then
		CameraShake.shake(magnitude * near, seconds)
	end
end

function ZorroEventos.play(
	motion: Zorro.Motion,
	fx: ZorroFx.ZorroFx?,
	agua: ZorroAgua.Agua?,
	event: Zorro.Event
)
	local kind = event.kind
	local height = motion.state.height
	local water = motion.water()
	local voz: ZorroVoces.Info = {
		stage = Capas.stageFor(height),
		head = motion.top(),
		ground = water,
		body = motion.point("Pecho"),
		ice = CraterMode.get() == "ice",
	}
	if kind == "howl" then
		ZorroVoces.event("howl", voz)
		for k = 1, 3 do
			task.delay(k * 0.35, Fx.ring, water, height * (0.5 + k * 0.3), 1.6)
		end
		shake(motion.top(), 0.35, 1.6)
	elseif kind == "fan" then
		ZorroVoces.event("fan", voz)
		local rig = motion.state.rig
		for _, tail in (if rig then rig.tails else {}) do
			local tip = motion.point(tail.tip)
			if tip then
				Fx.sparkle(tip, CYAN, 8)
			end
		end
	elseif kind == "crouch" then
		ZorroVoces.event("crouch", voz)
		Fx.ring(water, height * 0.4, 0.8)
	elseif kind == "land" then
		ZorroVoces.event("land", voz)
		Fx.ring(water, height * 0.9, 1.5)
		shake(water, 0.5, 0.6)
	elseif kind == "shake" then
		ZorroVoces.event("shake", voz)
	elseif kind == "happy" then
		ZorroVoces.event("happy", voz)
		Fx.hearts(motion.top(), 5)
	elseif kind == "orbs" then
		if fx then
			Sounds.play("CoinPop", motion.top(), 0.6)
			ZorroFx.orbs(fx, motion, math.max(1, math.round(6 * ClientSettings.fxScale())))
			Fx.sparkle(motion.top(), CYAN, 20)
		end
	elseif ZorroVoces.has(kind) then
		ZorroVoces.event(kind, voz)
	else
		ZorroComerFx.play(motion, event)
	end
	if agua then
		agua.burst(kind, water)
	end
end

return table.freeze(ZorroEventos)
