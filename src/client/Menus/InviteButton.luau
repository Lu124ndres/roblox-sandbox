--!strict
--[[
	InviteButton

	Botón Invitar en la barra de arriba (con Códigos y Ajustes): abre la ventana
	oficial de Roblox para invitar amigos al juego (SocialService). Funciona en
	teléfono, a diferencia de la insignia de amigos de abajo, que en táctil queda
	detrás del joystick. Quien entra por la invitación y quien invitó ganan el
	premio de Config.Social.referral (server/Social/Referrals).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Toasts = require(script.Parent.Parent.Toasts)
local HudButtons = require(script.Parent.HudButtons)

local InviteButton = {}

function InviteButton.start(toasts: Toasts.Toasts)
	local player = Players.LocalPlayer
	HudButtons.top("Invitar", "friends", function()
		local ok, allowed = pcall(SocialService.CanSendGameInviteAsync, SocialService, player)
		if ok and allowed then
			pcall(SocialService.PromptGameInvite, SocialService, player)
		else
			toasts.show("Ahora no se pueden mandar invitaciones", UIConfig.Colors.Warning)
		end
	end)
end

return InviteButton
