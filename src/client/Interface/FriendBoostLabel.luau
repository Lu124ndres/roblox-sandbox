--!strict
--[[
	FriendBoostLabel

	En la esquina de abajo a la izquierda (pedido del usuario), en una placa de
	piedra volcánica: "Amigos +20%" con el ícono de amigos, o "Invita amigos:
	+10% c/u" si no hay ninguno. En táctil va más arriba, para no quedar sobre
	el joystick de Roblox (taparía los toques para moverse). Siempre
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
local Device = require(script.Parent.Device)
local Icons = require(script.Parent.Icons)
local Kit = require(script.Parent.Kit)
local Layout = require(script.Parent.Layout)
local Style = require(script.Parent.Style)

local FriendBoostLabel = {}

local HEIGHT = 34
local WIDTH = 250
local MARGIN = 12
local TOUCH_LIFT = 210 -- en táctil, por encima del joystick

function FriendBoostLabel.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	local frame = Instance.new("TextButton")
	frame.Text = ""
	frame.AutoButtonColor = false
	frame.Name = "ImpulsoAmigos"
	frame.AnchorPoint = Vector2.new(0, 1)
	frame.Size = UDim2.fromOffset(WIDTH, HEIGHT)
	Kit.press(frame, Kit.skin(frame, "panel"))
	local skin = frame:FindFirstChild("Piedra") :: ImageLabel
	skin.SliceScale = 0.28
	Layout.scaleWith(frame)
	local function place()
		local lift = if Device.touch() then TOUCH_LIFT else 0
		frame.Position = UDim2.new(0, MARGIN, 1, -MARGIN - lift)
	end
	place()
	Device.onResize(place)
	frame.Parent = screen
	local icon = Icons.view(frame, "friends")
	icon.Position = UDim2.fromOffset(4, -6)
	icon.Size = UDim2.fromOffset(HEIGHT + 6, HEIGHT + 6)
	icon.ZIndex = 2
	local label = Style.text(frame, "Texto", 20, nil, 2)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Position = UDim2.fromOffset(HEIGHT + 14, 5)
	label.Size = UDim2.new(1, -HEIGHT - 22, 0, HEIGHT - 10)
	label.ZIndex = 2

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
