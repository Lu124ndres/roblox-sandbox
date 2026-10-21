--!strict
--[[
	StarterSeen

	Anota una sola vez cuándo se le abrió solo el pack de inicio al jugador
	(guardado starterSeenAt, atributo PackVistoEn). Con eso el cliente no lo
	vuelve a abrir solo nunca más y el atajo del pack cuenta 24 horas desde
	ahí (Menus/StarterShortcut). El remote no lleva argumentos: la hora la pone
	el servidor, y solo si cargó sus datos, terminó el tutorial (el pack se abre
	después), todavía no lo compró y nunca se anotó.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.Parent.PlayerData)
local RateLimit = require(script.Parent.Parent.RateLimit)
local Remotes = require(script.Parent.Parent.Remotes)

local TUTORIAL_STEPS = #Config.Retention.tutorial

local StarterSeen = {}

local function mark(player: Player)
	local save = PlayerData.read(player)
	if not save or save.starterPack or save.starterSeenAt > 0 or save.tutorial < TUTORIAL_STEPS then
		return
	end
	local now = os.time()
	PlayerData.edit(player, function(data) -- publica el atributo PackVistoEn
		data.starterSeenAt = now
	end)
end

function StarterSeen.init()
	Remotes.StarterSeen.OnServerEvent:Connect(RateLimit.wrap("StarterSeen", 0.2, 2, mark))
end

return StarterSeen
