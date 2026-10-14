--!strict
--[[
	FriendBoostLabel

	Abajo a la izquierda: "Impulso de amigos: +20%" con el ícono de amigos.
	Sube 10 % por cada amigo de Roblox en el servidor (hasta 5); invita a
	jugar con amigos. Lo calcula el servidor (atributo AmigosEnServidor).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Perks = require(ReplicatedStorage.Shared.Perks)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Icons = require(script.Parent.Icons)
local Layout = require(script.Parent.Layout)
local Style = require(script.Parent.Style)

local FriendBoostLabel = {}

function FriendBoostLabel.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	local frame = Instance.new("Frame")
	frame.Name = "ImpulsoAmigos"
	frame.BackgroundTransparency = 1
	frame.AnchorPoint = Vector2.new(0, 1)
	frame.Position = UDim2.new(0, 12, 1, -10)
	frame.Size = UDim2.fromOffset(330, 44)
	frame.Parent = screen
	Layout.scaleWith(frame)
	local icon = Icons.view(frame, "friends")
	icon.Size = UDim2.fromOffset(48, 44)
	local label = Style.text(frame, "Texto", 26, nil, 2.5)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Position = UDim2.fromOffset(54, 6)
	label.Size = UDim2.new(1, -54, 0, 32)

	local function refresh()
		local percent = math.round((Perks.friendMultiplier(player) - 1) * 100)
		label.Text = `Impulso de amigos: +{percent}%`
		label.TextColor3 = if percent > 0
			then Color3.fromRGB(140, 255, 120)
			else Color3.new(1, 1, 1)
	end
	player:GetAttributeChangedSignal(Protocol.PlayerAttributes.FriendsInServer):Connect(refresh)
	refresh()
end

return FriendBoostLabel
