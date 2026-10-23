--!strict
--[[
	Music

	Música de fondo por zona, con fundido suave entre pistas:
		isla      MusicIsland (bossa tranquila para pescar)
		cráter    MusicCrater (drones de tensión, junto al ambiente de terror)
		descanso  MusicRest   (orquesta heroica con coro: se venció al monstruo; en el cráter)

	Las pistas van al SoundGroup Musica, que el ajuste "Música" silencia.
	Las que no tienen ID se ignoran.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)
local Sounds = require(script.Parent.Sounds)

local FADE_SHARPNESS = 0.8 -- qué tan rápido cambia de pista (1/s)
local REST_PHASE = "rest"

type Track = { sound: Sound, volume: number, level: number }

local Music = {}

local function track(key: string): Track?
	local sound = Sounds.loop(key)
	if not sound then
		return nil
	end
	sound.SoundGroup = ClientSettings.musicGroup()
	local volume = sound.Volume
	sound.Volume = 0
	return { sound = sound, volume = volume, level = 0 }
end

function Music.start()
	local tracks: { [string]: Track } = {}
	for _, key in { "MusicIsland", "MusicCrater", "MusicRest" } do
		local made = track(key)
		if made then
			tracks[key] = made
		end
	end
	local state = ReplicatedStorage:WaitForChild(Protocol.GiantStateFolder)

	RunService.Heartbeat:Connect(function(dt: number)
		local character = Players.LocalPlayer.Character
		local crater = if character
			then WorldZones.craterBlend(character:GetPivot().Position)
			else 0
		local resting = state:GetAttribute(Protocol.GiantAttributes.Phase) == REST_PHASE
		local targets = {
			MusicIsland = 1 - crater,
			MusicCrater = if resting then 0 else crater,
			MusicRest = if resting then crater else 0,
		}
		local step = 1 - math.exp(-dt * FADE_SHARPNESS)
		for key, item in tracks do
			local target = (targets :: { [string]: number })[key] or 0
			item.level += (target - item.level) * step
			item.sound.Volume = item.volume * item.level
		end
	end)
end

return Music
