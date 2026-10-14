--!strict
--[[
	Sounds

	Reproduce los sonidos de Assets.Sounds con el volumen y tono de
	UIConfig.Sounds. Tres formas:
		Sounds.play(key)            sonido de interfaz (se oye igual en todos lados)
		Sounds.play(key, posición)  sonido 3D en un punto del mundo
		Sounds.loop(key)            ambiente en bucle

	Las claves sin ID (Assets.MISSING) se ignoran en silencio: el juego no
	depende de que un sonido exista.
]]

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Assets = require(ReplicatedStorage.Shared.Assets)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)

local MAX_LIFETIME_SECONDS = 12
local PITCH_VARIATION = 0.08 -- variación aleatoria para que no suene repetido

local Sounds = {}

local rng = Random.new()

local function make(key: string): Sound?
	local id = Assets.Sounds[key]
	if not id or id == Assets.MISSING then
		return nil
	end
	local settings = UIConfig.Sounds[key]
	local sound = Instance.new("Sound")
	sound.Name = key
	sound.SoundId = id
	sound.SoundGroup = ClientSettings.sfxGroup() -- Music lo cambia a Musica
	sound.Volume = if settings then settings.volume else 0.5
	sound.PlaybackSpeed = if settings and settings.pitch then settings.pitch else 1
	if settings and settings.rollOff then
		sound.RollOffMode = Enum.RollOffMode.InverseTapered
		sound.RollOffMinDistance = 8
		sound.RollOffMaxDistance = settings.rollOff
	end
	return sound
end

function Sounds.play(key: string, position: Vector3?, pitchScale: number?)
	local sound = make(key)
	if not sound then
		return
	end
	local variation = 1 + rng:NextNumber(-PITCH_VARIATION, PITCH_VARIATION)
	sound.PlaybackSpeed *= variation * (pitchScale or 1)
	if position then
		local holder = Instance.new("Attachment")
		holder.Name = `Sonido{key}`
		holder.WorldPosition = position
		holder.Parent = Workspace.Terrain
		sound.Parent = holder
		Debris:AddItem(holder, MAX_LIFETIME_SECONDS)
	else
		sound.Parent = SoundService
		Debris:AddItem(sound, MAX_LIFETIME_SECONDS)
	end
	sound:Play()
end

function Sounds.loop(key: string, parent: Instance?): Sound?
	local sound = make(key)
	if not sound then
		return nil
	end
	sound.Looped = true
	sound.Parent = parent or SoundService
	sound:Play()
	return sound
end

return Sounds
