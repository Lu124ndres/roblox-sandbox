--!strict
--[[
	FriendBoostLabel

	En la columna izquierda, debajo de las estadísticas: "Impulso de amigos:
	+20%" con el ícono de amigos (abajo a la izquierda quedaba bajo el joystick
	en los teléfonos).
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

local ORDER = 15 -- después de las estadísticas (1..4) y antes de la misión (20)
local HEIGHT = 40

function FriendBoostLabel.start(_screen: ScreenGui)
	local player = Players.LocalPlayer
	local frame = Instance.new("Frame")
	frame.Name = "ImpulsoAmigos"
	frame.LayoutOrder = ORDER
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromOffset(Layout.statWidth(), HEIGHT)
	frame.Parent = Layout.left() -- la columna ya escala con la pantalla
	local icon = Icons.view(frame, "friends")
	icon.Size = UDim2.fromOffset(HEIGHT + 4, HEIGHT)
	local label = Style.text(frame, "Texto", 26, nil, 2.5)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Position = UDim2.fromOffset(HEIGHT + 10, 4)
	label.Size = UDim2.new(1, -HEIGHT - 10, 0, HEIGHT - 8)

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
