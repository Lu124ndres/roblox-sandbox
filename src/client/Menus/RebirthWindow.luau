--!strict
--[[
	RebirthWindow

	Renacer (botón RENACER de la columna derecha) con el estilo de la TIENDA:
	dos tarjetas con rayos, AHORA (azul) → AL RENACER (dorada), con los
	peces por segundo al alimentar (lo único que da renacer); las barras de
	monedas y de poder que pide; qué se reinicia (tarjeta roja) y qué se
	queda (verde); y el botón grande. El
	botón del HUD lleva un punto rojo cuando ya alcanza. Lo decide el
	servidor (remote Rebirth, Retention/Rebirth).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local RebirthMath = require(ReplicatedStorage.Shared.RebirthMath)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local CardParts = require(script.Parent.Parent.Interface.CardParts)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Style = require(script.Parent.Parent.Interface.Style)
local HudButtons = require(script.Parent.HudButtons)
local Window = require(script.Parent.Window)

local ATTR = Protocol.PlayerAttributes
local CARDS = Style.PALETTE.Cards

local RebirthWindow = {}

local function speedText(rebirths: number): string
	return `{RebirthMath.speedText(rebirths)}/s`
end

-- Tarjeta de multiplicador: título arriba, número grande y nota abajo.
local function multiplierCard(parent: Instance, title: string, color: Color3, x: number): TextLabel
	local card = CardParts.card(parent, title, color, 16)
	card.Position = UDim2.fromScale(x, 0)
	card.Size = UDim2.new(0.4, 0, 0, 132)
	local head = Style.text(card, "Titulo", 24, nil, 2.5)
	head.Text = title
	head.Position = UDim2.fromScale(0, 0.06)
	head.Size = UDim2.fromScale(1, 0.2)
	local value = Style.text(card, "Valor", 64, UIConfig.Colors.Coins, 4)
	value.Position = UDim2.fromScale(0, 0.26)
	value.Size = UDim2.fromScale(1, 0.48)
	local note = Style.text(card, "Nota", 18, nil, 2)
	note.Text = "peces al alimentar"
	note.Position = UDim2.fromScale(0, 0.76)
	note.Size = UDim2.fromScale(1, 0.18)
	return value
end

-- Tarjeta chica con título y una línea de texto.
local function infoCard(parent: Instance, title: string, text: string, color: Color3, x: number)
	local card = CardParts.card(parent, title, color, 12)
	card.Position = UDim2.new(x, 0, 0, 220)
	card.Size = UDim2.new(0.48, 0, 0, 84)
	local head = Style.text(card, "Titulo", 22, nil, 2.5)
	head.Text = title
	head.Position = UDim2.fromScale(0.04, 0.06)
	head.Size = UDim2.fromScale(0.92, 0.3)
	local body = Style.text(card, "Texto", 18, nil, 2)
	body.Text = text
	body.Position = UDim2.fromScale(0.04, 0.4)
	body.Size = UDim2.fromScale(0.92, 0.52)
end

function RebirthWindow.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	local remotes = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
	local remote = remotes:WaitForChild(Protocol.Remotes.Rebirth) :: RemoteEvent
	local window = Window.create(screen, "Renacer", "Renacer", Vector2.new(720, 500))
	local hud = HudButtons.side("Renacer", "arrow", window.toggle)
	local content = window.content

	local nowValue = multiplierCard(content, "AHORA", CARDS.Blue, 0.04)
	local afterValue = multiplierCard(content, "AL RENACER", CARDS.Yellow, 0.56)
	local arrow = Icons.view(content, "arrow")
	arrow.AnchorPoint = Vector2.new(0.5, 0.5)
	arrow.Position = UDim2.new(0.5, 0, 0, 66)
	arrow.Size = UDim2.fromOffset(72, 72)
	arrow.Rotation = 90
	local count = Style.text(content, "Veces", 22, nil, 2)
	count.Position = UDim2.fromOffset(0, 140)
	count.Size = UDim2.new(1, 0, 0, 26)
	-- Lo que pide: monedas y poder, una barra para cada uno.
	local bar = CardParts.bar(content, UIConfig.Colors.Coins, 22)
	bar.track.Position = UDim2.new(0.04, 0, 0, 172)
	bar.track.Size = UDim2.new(0.45, 0, 0, 36)
	local powerBar = CardParts.bar(content, UIConfig.Colors.Power, 22)
	powerBar.track.Position = UDim2.new(0.51, 0, 0, 172)
	powerBar.track.Size = UDim2.new(0.45, 0, 0, 36)
	infoCard(
		content,
		"SE REINICIAN",
		"Monedas, poder, mejoras de la tienda y canasta",
		CARDS.Red,
		0.01
	)
	infoCard(
		content,
		"TE QUEDAS",
		"Títulos, kills, estanques, colección, pases y compras",
		CARDS.Green,
		0.51
	)
	local button = Style.button(content, "Renacer", Style.PALETTE.Buy, "¡RENACER!")
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.Position = UDim2.fromScale(0.5, 1)
	button.Size = UDim2.new(0.5, 0, 0, 64)
	local buttonText = button:FindFirstChild("Texto") :: TextLabel

	local function render()
		local rebirths = RebirthMath.count(player)
		local cost, powerCost = RebirthMath.cost(rebirths), RebirthMath.powerCost(rebirths)
		local coins, power = player:GetAttribute(ATTR.Coins), player:GetAttribute(ATTR.Power)
		local have = if type(coins) == "number" then coins else 0
		local strength = if type(power) == "number" then power else 0
		nowValue.Text = speedText(rebirths)
		afterValue.Text = speedText(rebirths + 1)
		count.Text = `Has renacido {rebirths} {if rebirths == 1 then "vez" else "veces"}`
		bar.set(have / cost, `{NumberFormat.short(have)} / {NumberFormat.short(cost)} monedas`)
		powerBar.set(
			strength / powerCost,
			`{NumberFormat.short(strength)} / {NumberFormat.short(powerCost)} poder`
		)
		local ready = RebirthMath.canRebirth(have, strength, rebirths)
		buttonText.Text = if ready
			then "¡RENACER!"
			elseif have < cost then "Te faltan monedas"
			else "Te falta poder"
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
		local coins, power = player:GetAttribute(ATTR.Coins), player:GetAttribute(ATTR.Power)
		if
			type(coins) == "number"
			and type(power) == "number"
			and RebirthMath.canRebirth(coins, power, RebirthMath.count(player))
		then
			remote:FireServer()
		end
	end)
	player:GetAttributeChangedSignal(ATTR.Coins):Connect(render)
	player:GetAttributeChangedSignal(ATTR.Rebirths):Connect(render)
	player:GetAttributeChangedSignal(ATTR.Power):Connect(render)
	window.onOpen(render)
	render()
end

return RebirthWindow
