--!strict
--[[
	DragonComer

	Lo que se ve de la animación especial al comer del dragón: Dragon/Comer
	manda los eventos (por Dragon/Fx, como cues) y el sonido lo pone DragonCues
	con Audio/DragonRecetasComer. Aquí, los efectos de cada uno:
		savor       resoplido de humo de gusto por la nariz (a lo sumo cada
		            SAVOR_EVERY s: con muchos peces no humea sin parar)
		dedicate    el resoplido va hacia el jugador que le dio, con corazones
		treat       chispas doradas y del color del pez raro en la boca
		treatFlare  llamarada del color del pez hacia arriba y un temblor cerca
		joy         chispas doradas alrededor del cuerpo
		fireRing    anillo de fuego alrededor del dragón y temblor
		feast       lluvia de chispas doradas
	fed(info) recuerda el color de la rareza del último pez (FishCatalog y
	UIConfig.RarityColors) y de dónde vino. Nada si el dragón está escondido.
	Todo es local: cada cliente lo dibuja con sus GiantFed.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Dragon = require(ReplicatedStorage.Shared.Dragon)
local FishCatalog = require(ReplicatedStorage.Shared.FishCatalog)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local CameraShake = require(script.Parent.Parent.Effects.CameraShake)
local DragonFeast = require(script.Parent.Parent.Effects.DragonFeast)
local DragonKit = require(script.Parent.Parent.Effects.DragonKit)
local DragonSmoke = require(script.Parent.Parent.Effects.DragonSmoke)

local SAVOR_EVERY = 1.2 -- s
local SHAKE_REACH = 220
local GOLD = Color3.fromRGB(255, 214, 90)
local KINDS: { [string]: boolean } = {
	savor = true,
	dedicate = true,
	treat = true,
	treatFlare = true,
	joy = true,
	fireRing = true,
	feast = true,
}

export type Comer = {
	fed: (info: Dragon.Fed) -> (),
	cue: (kind: string) -> (),
}

local DragonComer = {}

local function shake(position: Vector3, magnitude: number, seconds: number)
	local character = Players.LocalPlayer.Character
	local near = if character
		then 1 - (character:GetPivot().Position - position).Magnitude / SHAKE_REACH
		else 0
	if near > 0 then
		CameraShake.shake(magnitude * near, seconds)
	end
end

function DragonComer.new(motion: Dragon.Motion): Comer
	local color = GOLD
	local from: Vector3? = nil
	local savorAt = -math.huge

	local function cue(kind: string)
		local state = motion.state
		if not KINDS[kind] or state.hidden then
			return
		end
		local L = state.length
		local s = DragonKit.scale(L)
		local head, mouth = motion.top(), motion.mouth()
		local forward = if (mouth - head).Magnitude > 1e-3
			then (mouth - head).Unit
			else Vector3.yAxis
		if kind == "savor" and os.clock() - savorAt > SAVOR_EVERY then
			savorAt = os.clock()
			DragonSmoke.nostrils(mouth, forward, 0.45 * s)
		elseif kind == "dedicate" then
			local toward = if from and (from - mouth).Magnitude > 1
				then (from - mouth).Unit
				else forward
			DragonSmoke.nostrils(mouth, toward:Lerp(forward, 0.4), 0.4 * s)
		elseif kind == "treat" then
			DragonFeast.sparkles(mouth, color, 0.6 * s)
		elseif kind == "treatFlare" then
			DragonFeast.flare(mouth, color, 0.7 * s)
			shake(head, 0.12 + L * 0.003, 0.6)
		elseif kind == "joy" then
			DragonFeast.sparkles(state.center, GOLD, 0.8 * s)
		elseif kind == "fireRing" then
			DragonFeast.fireRing(state.center, L * 0.8, 0.8 * s)
			shake(state.center, 0.2 + L * 0.004, 0.9)
		elseif kind == "feast" then
			DragonFeast.shower(state.center + Vector3.new(0, L * 0.3, 0), L, 0.7 * s)
		end
	end

	return {
		fed = function(info: Dragon.Fed)
			local def = FishCatalog.rarity(info.fishId)
			color = if info.rarity >= 3 then UIConfig.RarityColors[def.id] or GOLD else GOLD
			from = info.from
		end,
		cue = cue,
	}
end

return table.freeze(DragonComer)
