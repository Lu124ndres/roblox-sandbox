--!strict
--[[
	DragonFly

	Une el dragón (ReplicatedStorage.Shared.Dragon) con el cliente: Dragon lo
	hace volar y anima sus huesos, Dragon.Fx pone fuego, rugidos y aletazos
	con los sonidos, destellos y temblor de cámara del juego (más fuerte
	cuanto más cerca). Solo vuelan los modelos con alas (hueso AlaIzq1).
	Misma forma que OrcaSwim para que GiantBody use uno u otro.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Dragon = require(ReplicatedStorage.Shared.Dragon)
local DragonFx = require(ReplicatedStorage.Shared.Dragon.Fx)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local CameraShake = require(script.Parent.Parent.Effects.CameraShake)
local Fx = require(script.Parent.Parent.Effects.Fx)
local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)
local OrcaSwim = require(script.Parent.OrcaSwim)

local SHAKE_REACH = 260

local DragonFly = {}

local hooks: DragonFx.Hooks = {
	play = Sounds.play,
	sparkle = Fx.sparkle,
	shake = function(position: Vector3, magnitude: number, seconds: number)
		local character = Players.LocalPlayer.Character
		if not character then
			return
		end
		local near = 1 - (character:GetPivot().Position - position).Magnitude / SHAKE_REACH
		if near > 0 then
			CameraShake.shake(magnitude * near, seconds)
		end
	end,
	fxScale = ClientSettings.fxScale,
}

function DragonFly.attach(template: Model?, center: Vector3): OrcaSwim.Swim?
	if not template or not template:FindFirstChild("AlaIzq1", true) then
		return nil
	end
	local motion = Dragon.new(center)
	local fx = DragonFx.new(motion, hooks)
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
			fx.step(dt)
			return pivot
		end,
		top = motion.top,
		mouth = motion.mouth,
		water = motion.water,
		bite = motion.bite,
		destroy = function()
			motion.destroy()
			fx.destroy()
		end,
	}
end

return table.freeze(DragonFly)
