--!strict
--[[
	ClientSettings

	Ajustes del jugador en este cliente: música, sonidos, temblor de cámara y
	efectos reducidos. Se cargan del atributo Settings (JSON que publica el
	servidor al cargar los datos) y, al cambiar uno, se aplican al momento y
	se mandan a guardar (SaveSettings) un segundo después, juntando los
	cambios seguidos en un solo envío.

	La música y los sonidos se silencian con los SoundGroup de SoundGroups.

	Valores automáticos (setAutomatic): valen solo esta sesión y no se
	guardan. Así se encienden los efectos reducidos en un teléfono sin
	teclado si el jugador nunca eligió, o cuando FpsWatchdog ve el juego
	lento. Que el jugador "eligió" se marca con lowFxChosen al guardar.

	english: jugar en inglés. Mientras el jugador no lo toque (langChosen),
	vale lo que diga el idioma de su cuenta y no se guarda; al elegir, se
	guarda y queda en el atributo Idioma que lee Lang/AutoTranslate.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Lang = require(ReplicatedStorage.Shared.Lang)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local SoundGroups = require(script.Parent.SoundGroups)

local SAVE_DELAY_SECONDS = 1
local LOW_FX_SCALE = 0 -- modo rápido: sin partículas (mejor rendimiento)

export type Key = "music" | "sfx" | "shake" | "lowFx" | "english"

local LANG_ATTR = "Idioma" -- lo lee Lang/AutoTranslate

local ClientSettings = {}

local values: { [string]: boolean } =
	{ music = true, sfx = true, shake = true, lowFx = false, english = false }
local listeners: { (key: string, value: boolean) -> () } = {}
local automatic: { [string]: boolean } = {} -- claves con valor de esta sesión, sin guardar
local saveScheduled = false
local lowFxChosen = false -- el jugador ya eligió los efectos reducidos alguna vez
local langChosen = false -- el jugador ya eligió el idioma en Ajustes

local function apply()
	SoundGroups.setVolumes(values.music, values.sfx)
	if langChosen then
		Players.LocalPlayer:SetAttribute(LANG_ATTR, if values.english then "en" else "es")
	end
end

function ClientSettings.get(key: Key): boolean
	return values[key] == true
end

function ClientSettings.musicGroup(): SoundGroup
	return SoundGroups.music
end

function ClientSettings.sfxGroup(): SoundGroup
	return SoundGroups.sfx
end

-- 1 normal; menos con efectos reducidos (para las ráfagas de partículas).
function ClientSettings.fxScale(): number
	return if values.lowFx then LOW_FX_SCALE else 1
end

function ClientSettings.onChanged(callback: (key: string, value: boolean) -> ())
	table.insert(listeners, callback)
end

local function notifyAll()
	for key, value in values do
		for _, callback in listeners do
			task.spawn(callback, key, value)
		end
	end
end

local function change(key: Key, value: boolean)
	values[key] = value
	apply()
	for _, callback in listeners do
		task.spawn(callback, key, value)
	end
end

-- Solo los valores elegidos por el jugador; los automáticos no se guardan.
local function payload(): { [string]: boolean }
	local out: { [string]: boolean } = {}
	for key, value in values do
		if not automatic[key] then
			out[key] = value
		end
	end
	out.lowFxChosen = lowFxChosen
	out.langChosen = langChosen
	return out
end

-- Valor solo para esta sesión: no se guarda y no pisa lo que el jugador eligió.
function ClientSettings.setAutomatic(key: Key, value: boolean)
	if values[key] == value then
		return
	end
	automatic[key] = true
	change(key, value)
end

function ClientSettings.set(key: Key, value: boolean)
	if values[key] == value then
		return
	end
	automatic[key] = nil
	if key == "lowFx" then
		lowFxChosen = true
	elseif key == "english" then
		langChosen = true
	end
	change(key, value)
	if saveScheduled then
		return
	end
	saveScheduled = true
	task.delay(SAVE_DELAY_SECONDS, function()
		saveScheduled = false
		local remotes = ReplicatedStorage:FindFirstChild(Protocol.RemotesFolder)
		local remote = remotes and remotes:FindFirstChild(Protocol.Remotes.SaveSettings)
		if remote and remote:IsA("RemoteEvent") then
			remote:FireServer(payload())
		end
	end)
end

-- Teléfono o tableta sin teclado y sin elección guardada: efectos reducidos.
local function applyDeviceDefault()
	local touchOnly = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	if touchOnly and not lowFxChosen and not values.lowFx then
		automatic.lowFx = true
		values.lowFx = true
	end
	if not langChosen then
		automatic.english = true
		values.english = not Lang.isSpanish(Players.LocalPlayer.LocaleId)
	end
end

local function load(player: Player)
	local raw = player:GetAttribute(Protocol.PlayerAttributes.Settings)
	if type(raw) ~= "string" then
		return
	end
	local ok, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
	if not ok or type(decoded) ~= "table" then
		return
	end
	local saved = decoded :: { [string]: unknown }
	lowFxChosen = lowFxChosen or saved.lowFxChosen == true or saved.lowFx == true
	langChosen = langChosen or saved.langChosen == true
	if langChosen then
		automatic.english = nil
	end
	for key in values do
		local value = saved[key]
		if type(value) == "boolean" and not automatic[key] then
			values[key] = value
		end
	end
	applyDeviceDefault()
	apply()
	notifyAll()
end

function ClientSettings.start()
	local player = Players.LocalPlayer
	applyDeviceDefault()
	apply()
	load(player)
	player:GetAttributeChangedSignal(Protocol.PlayerAttributes.Settings):Connect(function()
		load(player)
	end)
end

return ClientSettings
