--!strict
--[[
	EvolveSound

	Los sonidos de la evolución (Assets.Sounds, bloque "Evolución"): la carga
	que sube y el golpe del estallido. Son sonidos de interfaz, no 3D: se oyen
	en toda la isla, más fuertes cuanto más cerca del cráter (near 0..1).
	Pasan por el grupo de efectos (respetan el ajuste de sonido) y se
	destruyen al terminar. skip = segundos ya pasados (quien llega tarde).
]]

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Assets = require(ReplicatedStorage.Shared.Assets)
local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)

local FAR_VOLUME = 0.35 -- volumen relativo lejos del cráter
local MAX_LIFETIME = 10 -- por si nunca carga o nunca termina

local EvolveSound = {}

function EvolveSound.play(
	key: string,
	volume: number,
	speed: number,
	skip: number,
	near: number
): Sound?
	local id = Assets.Sounds[key]
	if not id or id == Assets.MISSING then
		return nil
	end
	local sound = Instance.new("Sound")
	sound.Name = key
	sound.SoundId = id
	sound.SoundGroup = ClientSettings.sfxGroup()
	sound.Volume = volume * (FAR_VOLUME + (1 - FAR_VOLUME) * near)
	sound.PlaybackSpeed = speed
	sound.TimePosition = skip * speed
	sound.Parent = SoundService
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	Debris:AddItem(sound, MAX_LIFETIME)
	sound:Play()
	return sound
end

return table.freeze(EvolveSound)
