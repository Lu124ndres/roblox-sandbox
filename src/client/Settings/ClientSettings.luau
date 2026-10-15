--!strict
--[[
	ClientSettings

	Ajustes del jugador en este cliente: música, sonidos, temblor de cámara y
	efectos reducidos. Se cargan del atributo Settings (JSON que publica el
	servidor al cargar los datos) y, al cambiar uno, se aplican al momento y
	se mandan a guardar (SaveSettings) un segundo después, juntando los
	cambios seguidos en un solo envío.

	La música y los sonidos se silencian con dos SoundGroup locales:
	Sounds pone cada efecto en Efectos y Music cada pista en Musica.

	Valores automáticos (setAutomatic): valen solo esta sesión y no se
	guardan. Así se encienden los efectos reducidos en un teléfono sin
	teclado si el jugador nunca eligió, o cuando FpsWatchdog ve el juego
	lento. Que el jugador "eligió" se marca con lowFxChosen al guardar.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local Protocol = require(ReplicatedStorage.Shared.Protocol)

local SAVE_DELAY_SECONDS = 1
local LOW_FX_SCALE = 0 -- modo rápido: sin partículas (mejor rendimiento)

export type Key = "music" | "sfx" | "shake" | "lowFx"

local ClientSettings = {}

local values: { [string]: boolean } = { music = true, sfx = true, shake = true, lowFx = false }
local listeners: { (key: string, value: boolean) -> () } = {}
local automatic: { [string]: boolean } = {} -- claves con valor de esta sesión, sin guardar
local saveScheduled = false
local lowFxChosen = false -- el jugador ya eligió los efectos reducidos alguna vez

local function group(name: string): SoundGroup
	local existing = SoundService:FindFirstChild(name)
	if existing and existing:IsA("SoundGroup") then
		return existing
	end
	local created = Instance.new("SoundGroup")
	created.Name = name
	created.Volume = 1
	created.Parent = SoundService
	return created
end

local musicGroup = group("Musica")
local sfxGroup = group("Efectos")

local function apply()
	musicGroup.Volume = if values.music then 1 else 0
	sfxGroup.Volume = if values.sfx then 1 else 0
end

function ClientSettings.get(key: Key): boolean
	return values[key] == true
end

function ClientSettings.musicGroup(): SoundGroup
	return musicGroup
end

function ClientSettings.sfxGroup(): SoundGroup
	return sfxGroup
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
