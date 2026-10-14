--!strict
--[[
	RebirthWindow

	Renacer (botón RENACER de la columna derecha): cuánto multiplica ahora y
	cuánto multiplicará, cuántas monedas faltan (barra), qué se pierde y qué
	se queda, y el botón grande. El botón del HUD lleva un punto rojo cuando
	ya alcanza. Lo decide el servidor (remote Rebirth, Retention/Rebirth).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local RebirthMath = require(ReplicatedStorage.Shared.RebirthMath)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Ui = require(script.Parent.Parent.Ui)
local Style = require(script.Parent.Parent.Interface.Style)
local HudButtons = require(script.Parent.HudButtons)
local Window = require(script.Parent.Window)

local ATTR = Protocol.PlayerAttributes

local RebirthWindow = {}

local function multiplierText(value: number): string
	return if value % 1 == 0 then `x{value}` else string.format("x%.1f", value)
end

function RebirthWindow.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	local remotes = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
	local remote = remotes:WaitForChild(Protocol.Remotes.Rebirth) :: RemoteEvent
	local window = Window.create(screen, "Renacer", "Renacer", Vector2.new(700, 470))
	local hud = HudButtons.side("Renacer", "arrow", window.toggle)
	local content = window.content

	local headline = Style.text(content, "Multiplicador", 40, UIConfig.Colors.Coins, 3)
	headline.Size = UDim2.new(1, 0, 0, 48)
	local count = Style.text(content, "Veces", 22, nil, 2)
	count.Position = UDim2.fromOffset(0, 50)
	count.Size = UDim2.new(1, 0, 0, 26)
	local track = Instance.new("Frame")
	track.BackgroundColor3 = Color3.fromRGB(30, 32, 42)
	track.Position = UDim2.new(0.05, 0, 0, 86)
	track.Size = UDim2.new(0.9, 0, 0, 34)
	track.ClipsDescendants = true
	Ui.corner(track, 10)
	Style.border(track, 3)
	track.Parent = content
	local fill = Instance.new("Frame")
	fill.BorderSizePixel = 0
	fill.BackgroundColor3 = UIConfig.Colors.Coins
	fill.Size = UDim2.fromScale(0, 1)
	Ui.corner(fill, 10)
	fill.Parent = track
	local money = Style.text(track, "Monedas", 24, nil, 2.5)
	money.Size = UDim2.fromScale(1, 1)
	money.ZIndex = 3
	local lose = Style.text(content, "Pierdes", 20, Color3.fromRGB(255, 140, 130), 2)
	lose.Position = UDim2.fromOffset(0, 130)
	lose.Size = UDim2.new(1, 0, 0, 24)
	lose.Text = "Se reinician: monedas, poder, mejoras de la tienda y canasta"
	local keep = Style.text(content, "Quedan", 20, Color3.fromRGB(150, 255, 140), 2)
	keep.Position = UDim2.fromOffset(0, 156)
	keep.Size = UDim2.new(1, 0, 0, 24)
	keep.Text = "Te quedas: kills, estanques, colección, pases y compras"
	local button = Style.button(content, "Renacer", Style.PALETTE.Buy, "¡RENACER!")
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.Position = UDim2.fromScale(0.5, 1)
	button.Size = UDim2.new(0.5, 0, 0, 64)
	local buttonText = button:FindFirstChild("Texto") :: TextLabel

	local function render()
		local rebirths = RebirthMath.count(player)
		local cost = RebirthMath.cost(rebirths)
		local coins = player:GetAttribute(ATTR.Coins)
		local have = if type(coins) == "number" then coins else 0
		local now, after = RebirthMath.multiplier(rebirths), RebirthMath.multiplier(rebirths + 1)
		headline.Text = `{multiplierText(now)} → {multiplierText(after)} monedas y poder`
		count.Text = `Has renacido {rebirths} {if rebirths == 1 then "vez" else "veces"}`
		fill.Size = UDim2.fromScale(math.clamp(have / cost, 0, 1), 1)
		money.Text = `{NumberFormat.short(have)} / {NumberFormat.short(cost)} monedas`
		local ready = have >= cost
		buttonText.Text = if ready then "¡RENACER!" else "Te faltan monedas"
		local tint = if ready then Style.PALETTE.Buy else Style.PALETTE.Disabled
		button.BackgroundColor3 = tint
		local gradient = button:FindFirstChildOfClass("UIGradient")
		if gradient then
			gradient:Destroy()
		end
		Style.gradient(button, tint)
		hud.setAlert(ready)
	end

	button.Activated:Connect(function()
		local cost = RebirthMath.cost(RebirthMath.count(player))
		local coins = player:GetAttribute(ATTR.Coins)
		if type(coins) == "number" and coins >= cost then
			remote:FireServer()
		end
	end)
	player:GetAttributeChangedSignal(ATTR.Coins):Connect(render)
	player:GetAttributeChangedSignal(ATTR.Rebirths):Connect(render)
	window.onOpen(render)
	render()
end

return RebirthWindow
