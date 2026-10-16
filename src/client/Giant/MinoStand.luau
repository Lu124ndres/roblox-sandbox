--!strict
--[[
	MinoStand

	Une el minotauro (ReplicatedStorage.Shared.Minotauro) con el cliente: el
	módulo lo gira, lo anima y hace sus trucos; aquí sus eventos se vuelven
	sonidos y efectos del juego (respetan volumen, alcance y modo rápido). La
	voz y la fuerza salen de la etapa (Minotauro/Etapas):
		stomp  pisotón: golpe de agua, ola y temblor (más fuerte cerca)
		roar   rugido (agudo en el becerro, grave en la forma final) y temblor
		land   cae de un salto: salpica
		flex   destellos dorados alrededor
		happy  corazones sobre la cabeza
	Solo los modelos con huesos de minotauro (OrejaIzq y BrazoIzq, sin alas).
	Misma forma que OrcaSwim para que GiantBody use uno u otro.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Minotauro = require(ReplicatedStorage.Shared.Minotauro)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local CameraShake = require(script.Parent.Parent.Effects.CameraShake)
local Fx = require(script.Parent.Parent.Effects.Fx)
local OrcaSwim = require(script.Parent.OrcaSwim)

local SHAKE_REACH = 240

local MinoStand = {}

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

local function play(motion: Minotauro.Motion, kind: string)
	local height = motion.state.height
	local water = motion.water()
	local profile = motion.state.profile
	local force = profile.stomp
	local size = math.max(1, height / 12) * force
	if kind == "stomp" then
		Sounds.play("BigSplash", water, 1.3 - 0.15 * force)
		Fx.splash(water, 1.5 * size)
		Fx.ring(water, height * 0.6 * force, 1.2)
		shake(water, 0.5 * force, 0.6)
	elseif kind == "roar" then
		Sounds.play("Roar", motion.top(), profile.voice)
		shake(motion.top(), 0.35 / profile.voice, 1.4)
	elseif kind == "land" then
		Sounds.play("BigSplash", water)
		Fx.splash(water, 2 * size)
		Fx.ring(water, height * 0.8 * force, 1.4)
		shake(water, 0.4 * force, 0.5)
	elseif kind == "flex" then
		Fx.sparkle(motion.top(), UIConfig.Colors.Coins, 24)
	elseif kind == "happy" then
		Fx.hearts(motion.top(), 5)
	end
end

function MinoStand.attach(template: Model?, center: Vector3): OrcaSwim.Swim?
	if
		not template
		or not template:FindFirstChild("OrejaIzq", true)
		or not template:FindFirstChild("BrazoIzq", true)
		or template:FindFirstChild("AlaIzq1", true)
	then
		return nil
	end
	local motion = Minotauro.new(center)
	return {
		step = function(
			dt: number,
			height: number,
			lift: number,
			spin: number,
			anger: number,
			inner: Model?
		)
			local pivot = motion.step(
				dt,
				{ height = height, lift = lift, spin = spin, anger = anger, inner = inner }
			)
			local events = motion.state.events
			if #events > 0 then
				motion.state.events = {}
				for _, event in events do
					play(motion, event.kind)
				end
			end
			return pivot
		end,
		top = motion.top,
		mouth = motion.mouth,
		water = motion.water,
		bite = motion.bite,
		destroy = motion.destroy,
	}
end

return table.freeze(MinoStand)
