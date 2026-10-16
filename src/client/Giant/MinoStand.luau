--!strict
--[[
	MinoStand

	Une el minotauro (ReplicatedStorage.Shared.Minotauro) con el cliente: el
	módulo lo gira, lo anima y hace sus trucos; aquí sus eventos se vuelven
	sonidos y efectos del juego (respetan volumen, alcance y modo rápido):
		stomp  pisotón: golpe de agua, ola y temblor (más fuerte cerca)
		roar   rugido agudo de becerro y temblor
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
local VOICE = 1.35 -- el becerro ruge agudo

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
	local size = math.max(1, height / 12)
	if kind == "stomp" then
		Sounds.play("BigSplash", water, 1.2)
		Fx.splash(water, 1.5 * size)
		Fx.ring(water, height * 0.6, 1.2)
		shake(water, 0.5, 0.6)
	elseif kind == "roar" then
		Sounds.play("Roar", motion.top(), VOICE)
		shake(motion.top(), 0.35, 1.4)
	elseif kind == "land" then
		Sounds.play("BigSplash", water)
		Fx.splash(water, 2 * size)
		Fx.ring(water, height * 0.8, 1.4)
		shake(water, 0.4, 0.5)
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
