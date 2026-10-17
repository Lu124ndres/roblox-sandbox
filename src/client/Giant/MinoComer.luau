--!strict
--[[
	MinoComer

	Los efectos de las reacciones del minotauro al comer (Minotauro/Comer), para
	MinoStand (el sonido ya lo puso MinoVoces con Audio/MinoVocesComer):
		glow3..glow6  le brillan los ojos del color de la rareza (Effects/MinoComerFx)
		goldburst     revienta en oro alrededor de la cabeza
		cheer         ruge de gusto en un festejo: papelitos de colores, destellos
		              dorados y un temblor chico
		joy           salta de alegría: corazones y destellos rosas
		wink          le guiña al jugador local: un corazón
		burp          nubecita del eructo en la boca
		clap          destello entre las manos al atrapar el pez
		hop           cae del saltito: polvito o salpicadura chica
	gulp, pat, drum y yum solo suenan. play devuelve si el evento era suyo.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Minotauro = require(ReplicatedStorage.Shared.Minotauro)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Fx = require(script.Parent.Parent.Effects.Fx)
local MinoComerFx = require(script.Parent.Parent.Effects.MinoComerFx)
local SandFx = require(script.Parent.Parent.Effects.SandFx)

local PINK = Color3.fromRGB(255, 120, 180)
local SOUND_ONLY: { [string]: boolean } = { gulp = true, pat = true, drum = true, yum = true }

export type Shake = (position: Vector3, magnitude: number, seconds: number) -> ()

local MinoComer = {}

local function between(motion: Minotauro.Motion, a: string, b: string): Vector3?
	local rig = motion.state.rig
	local bone1 = rig and rig.bones[a]
	local bone2 = rig and rig.bones[b]
	if bone1 and bone2 then
		return bone1.TransformedWorldCFrame.Position:Lerp(
			bone2.TransformedWorldCFrame.Position,
			0.5
		)
	end
	return nil
end

function MinoComer.play(
	motion: Minotauro.Motion,
	kind: string,
	ground: Vector3,
	sand: boolean,
	shake: Shake
): boolean
	local height = motion.state.height
	local scale = math.max(1, height / 12)
	local top = motion.top()
	local level = tonumber(string.match(kind, "^glow(%d+)$"))
	if level then
		local rig = motion.state.rig
		local head = rig and rig.bones.Cabeza
		MinoComerFx.glow(head, between(motion, "Cabeza", "Boca") or top, level, scale)
	elseif kind == "goldburst" then
		MinoComerFx.goldburst(top, scale)
		Fx.sparkle(top, UIConfig.Colors.Coins, 30)
	elseif kind == "cheer" then
		MinoComerFx.confetti(top, scale)
		Fx.sparkle(top, UIConfig.Colors.Coins, 24)
		shake(top, 0.2 / motion.state.profile.voice, 0.8)
	elseif kind == "joy" then
		Fx.hearts(top, 6)
		Fx.sparkle(top, PINK, 20)
	elseif kind == "wink" then
		Fx.hearts(top, 1)
	elseif kind == "burp" then
		MinoComerFx.burp(motion.mouth(), scale)
	elseif kind == "clap" then
		MinoComerFx.clap(between(motion, "ManoIzq", "ManoDer") or motion.mouth(), scale)
	elseif kind == "hop" then
		if sand then
			SandFx.puff(ground, 0.8 * scale)
		else
			Fx.splash(ground, 0.8 * scale)
		end
	else
		return SOUND_ONLY[kind] == true
	end
	return true
end

return table.freeze(MinoComer)
