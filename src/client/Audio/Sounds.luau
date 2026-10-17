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

	Con 40-50 jugadores se cuida cuánto suena a la vez: un sonido 3D más
	lejos de la cámara que su alcance (rollOff, o SoundDefaultReach) no se
	crea, cada clave tiene un tope de copias sonando (SoundMaxPerKey) y cada
	copia se destruye al terminar.

	Sounds.define(ajustes) agrega volumen, tono y alcance de claves que no
	están en UIConfig.Sounds (por ejemplo las voces del minotauro, MinoVoces).
	Sounds.play acepta además un multiplicador de volumen (capas más suaves).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Assets = require(ReplicatedStorage.Shared.Assets)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Performance = require(ReplicatedStorage.Shared.UIConfig.Performance)
local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)

local PITCH_VARIATION = 0.08 -- variación aleatoria para que no suene repetido

type SoundSettings = { volume: number, pitch: number?, rollOff: number? }

local Sounds = {}

local rng = Random.new()
local playing: { [string]: number } = {} -- copias sonando de cada clave
local defined: { [string]: SoundSettings } = {} -- ajustes de Sounds.define

local function settingsFor(key: string): SoundSettings?
	return UIConfig.Sounds[key] or defined[key]
end

-- Un sonido 3D fuera de su alcance no se oiría: ni se crea.
local function audible(key: string, position: Vector3): boolean
	local camera = Workspace.CurrentCamera
	if not camera then
		return true
	end
	local settings = settingsFor(key)
	local reach = if settings and settings.rollOff
		then settings.rollOff
		else Performance.SoundDefaultReach
	return (camera.CFrame.Position - position).Magnitude <= reach
end

local function make(key: string): Sound?
	local id = Assets.Sounds[key]
	if not id or id == Assets.MISSING then
		return nil
	end
	local settings = settingsFor(key)
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

-- Ajustes de claves que no están en UIConfig.Sounds (UIConfig manda si están en los dos).
function Sounds.define(settings: { [string]: SoundSettings })
	for key, value in settings do
		defined[key] = value
	end
end

function Sounds.play(key: string, position: Vector3?, pitchScale: number?, volumeScale: number?)
	if (playing[key] or 0) >= Performance.SoundMaxPerKey then
		return
	end
	if position and not audible(key, position) then
		return
	end
	local sound = make(key)
	if not sound then
		return
	end
	local variation = 1 + rng:NextNumber(-PITCH_VARIATION, PITCH_VARIATION)
	sound.PlaybackSpeed *= variation * (pitchScale or 1)
	sound.Volume *= volumeScale or 1
	local holder: Instance = sound
	if position then
		local attachment = Instance.new("Attachment")
		attachment.Name = `Sonido{key}`
		attachment.WorldPosition = position
		attachment.Parent = Workspace.Terrain
		sound.Parent = attachment
		holder = attachment
	else
		sound.Parent = SoundService
	end
	playing[key] = (playing[key] or 0) + 1
	local done = false
	local function finish()
		if done then
			return
		end
		done = true
		playing[key] = math.max(0, (playing[key] or 1) - 1)
		holder:Destroy()
	end
	sound.Ended:Once(finish)
	task.delay(Performance.SoundMaxLifetime, finish) -- por si nunca carga o nunca termina
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
