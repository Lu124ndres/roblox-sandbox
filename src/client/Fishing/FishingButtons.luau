--!strict
--[[
	FishingButtons

	Los botones grandes de la pesca, pensados para el pulgar en móvil:
		Pescar     turquesa. Sale cuando el jugador está en la orilla o en un muelle.
		Alimentar  coral, en el mismo lugar; sale en la orilla del volcán con peces.
		¡TIRA!     rojo, en el mismo lugar y un poco más grande (el pulgar no se
		           mueve): se toca rápido para recoger (la barra es ReelBar).
	Dónde van (abajo a la derecha, sin tapar la columna derecha del HUD):
		teléfono  justo a la izquierda del botón de saltar de Roblox
		tablet    igual, más grande (el botón de saltar también lo es)
		PC        en la esquina; todo se hace con E (los botones muestran la tecla)
	Se reacomodan si cambia la pantalla (girar el teléfono, ventana en PC).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Ui = require(script.Parent.Parent.Ui)
local Device = require(script.Parent.Parent.Interface.Device)

local COLORS = UIConfig.Colors

-- Medidas en píxeles de pantalla (estos botones no usan la escala del HUD).
local PHONE_SIZE = 110
local PHONE_POSITION = UDim2.new(1, -110, 1, -24) -- a la izquierda del salto (70 px)
local TABLET_SIZE = 140
local TABLET_POSITION = UDim2.new(1, -190, 1, -90) -- a la izquierda del salto (120 px)
local PC_MARGIN = 32
local PC_HEIGHT_FRACTION = 0.16
local PC_MIN_SIZE = 96
local BITE_GROWTH = 1.25 -- ¡TIRA! es un poco más grande que Pescar
local BITE_HEIGHT = 0.36 -- ...pero nunca más de esta fracción del alto

type Spot = { position: UDim2, size: number }

local FishingButtons = {}

local placers: { () -> () } = {}
local listening = false

-- El lugar del botón principal según la pantalla.
local function spot(): Spot
	if Device.phone() then
		return { position = PHONE_POSITION, size = PHONE_SIZE }
	elseif Device.touch() then
		return { position = TABLET_POSITION, size = TABLET_SIZE }
	end
	local height = Device.viewport().Y
	local size = math.clamp(
		math.floor(height * PC_HEIGHT_FRACTION),
		PC_MIN_SIZE,
		UIConfig.Spacing.CastButtonSize
	)
	return { position = UDim2.new(1, -PC_MARGIN, 1, -PC_MARGIN), size = size }
end

local function addPlacer(placer: () -> ())
	table.insert(placers, placer)
	placer()
	if not listening then
		listening = true
		Device.onResize(function()
			for _, each in placers do
				each()
			end
		end)
	end
end

local function roundButton(screen: ScreenGui, name: string, text: string, color: Color3): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.AnchorPoint = Vector2.new(1, 1)
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
	aspect.DominantAxis = Enum.DominantAxis.Height
	aspect.Parent = button
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

-- Pescar y Alimentar: tamaño fijo en píxeles, en el lugar del pulgar.
local function mainButton(screen: ScreenGui, name: string, text: string, color: Color3): TextButton
	local button = roundButton(screen, name, text, color)
	addPlacer(function()
		local where = spot()
		button.Position = where.position
		button.Size = UDim2.fromOffset(where.size, where.size)
	end)
	return button
end

function FishingButtons.cast(screen: ScreenGui): TextButton
	local button = mainButton(screen, "Pescar", "Pescar", COLORS.Fishing)
	keyBadge(button, "E")
	return button
end

-- Mismo lugar que Pescar: en la orilla del volcán no se pesca, se alimenta.
function FishingButtons.feed(screen: ScreenGui): TextButton
	local button = mainButton(screen, "Alimentar", "Alimentar", COLORS.Feeding)
	local pulse = Instance.new("UIScale")
	pulse.Parent = button
	TweenService:Create(pulse, UIConfig.Tweens.Pulse, { Scale = 1.06 }):Play()
	return button
end

-- ¡TIRA!: su tamaño sale del alto de la pantalla (BITE_HEIGHT) con tope en
-- 1.25 veces Pescar; la esquina de abajo a la derecha es la misma que la de Pescar.
function FishingButtons.bite(screen: ScreenGui): TextButton
	local button = roundButton(screen, "Tira", "¡TIRA!", COLORS.Bite)
	button.Size = UDim2.fromScale(BITE_HEIGHT, BITE_HEIGHT)
	local limit = Instance.new("UISizeConstraint")
	limit.Parent = button
	addPlacer(function()
		local where = spot()
		button.Position = where.position
		limit.MaxSize = Vector2.one * math.floor(where.size * BITE_GROWTH)
	end)
	local pulse = Instance.new("UIScale")
	pulse.Parent = button
	TweenService:Create(pulse, UIConfig.Tweens.Pulse, { Scale = 1.08 }):Play()
	keyBadge(button, "E")

	return button
end

return FishingButtons
