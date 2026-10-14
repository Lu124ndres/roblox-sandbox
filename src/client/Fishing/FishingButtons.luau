--!strict
--[[
	FishingButtons

	Los dos botones grandes de la pesca, pensados para el pulgar en móvil:
		Pescar  turquesa, abajo a la derecha (sobre el botón de saltar). Sale
		        cuando el jugador está en la orilla o en un muelle.
	En PC todo se hace con E (los botones muestran la tecla); en móvil, tocando.
		Alimentar  coral, en el mismo lugar; sale en la orilla del volcán con peces.
		¡TIRA!  rojo, al centro, con una barra que se vacía durante la ventana.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Ui = require(script.Parent.Parent.Ui)

local COLORS = UIConfig.Colors

local FishingButtons = {}

local function roundButton(
	screen: ScreenGui,
	name: string,
	text: string,
	color: Color3,
	maxSize: number
): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.BackgroundColor3 = color
	button.AutoButtonColor = true
	button.Text = text
	button.FontFace = UIConfig.Fonts.Title
	button.TextScaled = true
	button.TextColor3 = COLORS.Text
	button.TextStrokeColor3 = COLORS.TextStroke
	button.TextStrokeTransparency = 0.2
	button.Visible = false
	Ui.corner(button, 1000)
	Ui.stroke(button, COLORS.Text, 4, 0)
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.Parent = button
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.one * maxSize
	limit.MinSize = Vector2.one * (maxSize * 0.55)
	limit.Parent = button
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0.16, 0)
	padding.PaddingRight = UDim.new(0.16, 0)
	padding.Parent = button
	button.Parent = screen
	return button
end

-- Insignia con la tecla (solo si hay teclado): en PC no hace falta hacer clic.
local function keyBadge(button: TextButton, key: string)
	if not UserInputService.KeyboardEnabled then
		return
	end
	local badge = Instance.new("TextLabel")
	badge.Name = "Tecla"
	badge.AnchorPoint = Vector2.new(0.5, 0.5)
	badge.Position = UDim2.fromScale(0.86, 0.12)
	badge.Size = UDim2.fromScale(0.34, 0.34)
	badge.BackgroundColor3 = COLORS.Text
	badge.Text = key
	badge.TextScaled = true
	badge.FontFace = UIConfig.Fonts.Title
	badge.TextColor3 = COLORS.TextStroke
	badge.ZIndex = button.ZIndex + 1
	Ui.corner(badge, 8)
	badge.Parent = button
end

function FishingButtons.cast(screen: ScreenGui): TextButton
	local button =
		roundButton(screen, "Pescar", "Pescar", COLORS.Fishing, UIConfig.Spacing.CastButtonSize)
	button.AnchorPoint = Vector2.new(1, 1)
	button.Position = UDim2.new(1, -24, 1, -115)
	button.Size = UDim2.fromScale(0.16, 0.16)
	keyBadge(button, "E")
	return button
end

-- Mismo lugar que Pescar: en la orilla del volcán no se pesca, se alimenta.
function FishingButtons.feed(screen: ScreenGui): TextButton
	local button = roundButton(
		screen,
		"Alimentar",
		"Alimentar",
		COLORS.Feeding,
		UIConfig.Spacing.CastButtonSize
	)
	button.AnchorPoint = Vector2.new(1, 1)
	button.Position = UDim2.new(1, -24, 1, -115)
	button.Size = UDim2.fromScale(0.16, 0.16)
	local pulse = Instance.new("UIScale")
	pulse.Parent = button
	TweenService:Create(pulse, UIConfig.Tweens.Pulse, { Scale = 1.06 }):Play()
	return button
end

function FishingButtons.bite(screen: ScreenGui): (TextButton, Frame)
	local button =
		roundButton(screen, "Tira", "¡TIRA!", COLORS.Bite, UIConfig.Spacing.BiteButtonSize)
	button.Position = UDim2.fromScale(0.5, 0.74)
	button.Size = UDim2.fromScale(0.3, 0.3)
	local pulse = Instance.new("UIScale")
	pulse.Parent = button
	TweenService:Create(pulse, UIConfig.Tweens.Pulse, { Scale = 1.08 }):Play()
	keyBadge(button, "E")

	local timer = Instance.new("Frame")
	timer.Name = "Tiempo"
	timer.AnchorPoint = Vector2.new(0.5, 0)
	timer.Position = UDim2.new(0.5, 0, 1, 10)
	timer.Size = UDim2.new(1, 0, 0, 10)
	timer.BackgroundColor3 = COLORS.Text
	timer.BorderSizePixel = 0
	Ui.corner(timer, 5)
	timer.Parent = button
	return button, timer
end

return FishingButtons
