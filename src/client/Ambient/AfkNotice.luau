--!strict
--[[
	AfkNotice

	Roblox saca del servidor a quien pasa 20 minutos sin tocar nada, y eso
	choca con entrenar AFK. No se esquiva (sería ir contra cómo funciona
	Roblox): se avisa con tiempo para que el jugador se mueva un poco y siga
	entrenando. Player.Idled avisa cada 2 minutos de inactividad.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local Toasts = require(script.Parent.Parent.Toasts)

local WARN_FROM_SECONDS = 14 * 60
local KICK_SECONDS = 20 * 60

local AfkNotice = {}

function AfkNotice.start(toasts: Toasts.Toasts)
	Players.LocalPlayer.Idled:Connect(function(idleSeconds: number)
		if idleSeconds >= WARN_FROM_SECONDS then
			local minutes = math.max(1, math.floor((KICK_SECONDS - idleSeconds) / 60))
			Sounds.play("Bite")
			toasts.banner(
				`Roblox te sacará en ~{minutes} min por inactividad: muévete un poco para seguir entrenando`,
				UIConfig.Colors.Warning
			)
		end
	end)
end

return AfkNotice
