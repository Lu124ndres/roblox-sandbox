--!strict
--[[
	SoundGroups

	Los dos SoundGroup locales con que ClientSettings silencia la música y los
	sonidos: Sounds pone cada efecto en Efectos y Music cada pista en Musica.
	Encendidos suenan a MUSIC_VOLUME y SFX_VOLUME (un tercio menos que antes,
	pedido del usuario el 2026-10-23).
]]

local SoundService = game:GetService("SoundService")

local MUSIC_VOLUME = 2 / 3
local SFX_VOLUME = 2 / 3

local SoundGroups = {}

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

SoundGroups.music = group("Musica")
SoundGroups.sfx = group("Efectos")

function SoundGroups.setVolumes(musicOn: boolean, sfxOn: boolean)
	SoundGroups.music.Volume = if musicOn then MUSIC_VOLUME else 0
	SoundGroups.sfx.Volume = if sfxOn then SFX_VOLUME else 0
end

return SoundGroups
