--!strict
--[[
	FriendBoostLabel

	En la columna izquierda, debajo de las estadísticas: "Amigos +20%" con el
	ícono de amigos, o "Invita amigos: +10% c/u" si no hay ninguno. Siempre
	se puede tocar: abre la invitación de Roblox (SocialService), y si un
	amigo nuevo entra por ella los dos ganan premio (server/Social/Referrals).
	Sube 10 % por cada amigo de Roblox en el servidor (hasta 5). Lo calcula
	el servidor (atributo AmigosEnServidor).
]]

local Players = game:GetService("Players")
local SocialService = game:GetService("SocialService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Perks = require(ReplicatedStorage.Shared.Perks)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Icons = require(script.Parent.Icons)
local Layout = require(script.Parent.Layout)
local Style = require(script.Parent.Style)

local FriendBoostLabel = {}

local ORDER = 15 -- después de las estadísticas (1..4) y antes de la misión (20)
local HEIGHT = 28

function FriendBoostLabel.start(_screen: ScreenGui)
	local player = Players.LocalPlayer
	local frame = Instance.new("TextButton")
	frame.Text = ""
	frame.AutoButtonColor = false
	frame.Name = "ImpulsoAmigos"
	frame.LayoutOrder = ORDER
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromOffset(Layout.statWidth(), HEIGHT)
	frame.Parent = Layout.left() -- la columna ya escala con la pantalla
	local icon = Icons.view(frame, "friends")
	icon.Size = UDim2.fromOffset(HEIGHT + 4, HEIGHT)
	local label = Style.text(frame, "Texto", 20, nil, 2)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Position = UDim2.fromOffset(HEIGHT + 6, 3)
	label.Size = UDim2.new(1, -HEIGHT - 6, 0, HEIGHT - 6)

	local function refresh()
		local percent = math.round((Perks.friendMultiplier(player) - 1) * 100)
		local per = math.round(Config.Social.friendBoost.perFriend * 100)
		label.Text = if percent > 0 then `Amigos +{percent}%` else `Invita amigos: +{per}% c/u`
		label.TextColor3 = if percent > 0
			then Color3.fromRGB(140, 255, 120)
			else Color3.new(1, 1, 1)
	end
	frame.Activated:Connect(function()
		local ok, allowed = pcall(SocialService.CanSendGameInviteAsync, SocialService, player)
		if ok and allowed then
			pcall(SocialService.PromptGameInvite, SocialService, player)
		end
	end)
	player:GetAttributeChangedSignal(Protocol.PlayerAttributes.FriendsInServer):Connect(refresh)
	refresh()
end

return FriendBoostLabel
