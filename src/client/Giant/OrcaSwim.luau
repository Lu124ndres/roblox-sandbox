--!strict
--[[
	OrcaSwim

	Une los dos módulos de la orca (ReplicatedStorage.Shared.Orca) con el
	cliente: OrcaMotion la mueve y anima sus huesos, OrcaFx pone sonidos y
	efectos. A OrcaFx le da los sonidos, salpicaduras y destellos del juego
	(respetan volumen, alcance y modo rápido) y el temblor de cámara, más
	fuerte cuanto más cerca está el jugador local. Solo nadan los modelos con
	huesos de orca (hueso Raiz); los demás gigantes se quedan en su lugar.
	Cada pez que le llega (fed) dispara su animación especial al comer
	(OrcaMotion/Comer, sonidos en OrcaFx/Comida, volúmenes en Audio/OrcaVoces).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local OrcaFx = require(ReplicatedStorage.Shared.Orca.OrcaFx)
local OrcaMotion = require(ReplicatedStorage.Shared.Orca.OrcaMotion)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
require(script.Parent.Parent.Audio.OrcaVoces) -- volumen y alcance de los sonidos al comer
local CameraShake = require(script.Parent.Parent.Effects.CameraShake)
local Fx = require(script.Parent.Parent.Effects.Fx)
local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)

local FedInfo = require(script.Parent.FedInfo)

local SHAKE_REACH = 220 -- studs: más lejos no tiembla

export type FedInfo = FedInfo.FedInfo
export type Swim = {
	step: (
		dt: number,
		height: number,
		lift: number,
		spin: number,
		anger: number,
		inner: Model?
	) -> CFrame,
	top: () -> Vector3,
	mouth: () -> Vector3,
	water: () -> Vector3,
	bite: () -> (),
	fed: (info: FedInfo.FedInfo) -> (), -- le llegó un pez: su animación especial al comer
	destroy: () -> (),
}

local OrcaSwim = {}

local hooks: OrcaFx.Hooks = {
	play = Sounds.play,
	splash = Fx.splash,
	ring = Fx.ring,
	sparkle = Fx.sparkle,
	spout = Fx.spout,
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

-- template: el modelo de la etapa 1 del gigante; center: el centro del lago.
function OrcaSwim.attach(template: Model?, center: Vector3): Swim?
	if not template or not template:FindFirstChild("Espiraculo", true) then -- el dragón también tiene Raiz
		return nil
	end
	local motion = OrcaMotion.new(center)
	local fx = OrcaFx.new(motion, hooks)
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
		fed = motion.fed,
		destroy = function()
			motion.destroy()
			fx.destroy()
		end,
	}
end

return table.freeze(OrcaSwim)
