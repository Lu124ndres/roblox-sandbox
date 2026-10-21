--!strict
--[[
	FishingButtons

	Los botones grandes de la pesca, pensados para el pulgar en móvil:
		Pescar     turquesa. Sale cuando el jugador está en la playa.
		Alimentar  coral, en el mismo lugar; sale en la orilla del volcán con peces.
		¡TIRA!     rojo, en el mismo lugar y un poco más grande (el pulgar no se
		           mueve): se toca rápido para recoger (la barra es ReelBar).
	Dónde van: en Interface/ActionSpot (en táctil, a la izquierda del botón de
	saltar de Roblox y de su tamaño; en PC, en la esquina). En PC todo se hace
	con E y en el mando con X (Cuadrado en PlayStation) o R2: los botones
	muestran la tecla. Se reacomodan si cambia la pantalla o los controles.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local ActionSpot = require(script.Parent.Parent.Interface.ActionSpot)
local InputHints = require(script.Parent.Parent.Interface.InputHints)
local ActionButton = require(script.Parent.ActionButton)

local COLORS = UIConfig.Colors

local BITE_GROWTH = 1.25 -- ¡TIRA! es un poco más grande que Pescar
local BITE_HEIGHT = 0.36 -- ...pero nunca más de esta fracción del alto

local FishingButtons = {}

local placers: { () -> () } = {}
local listening = false

local function addPlacer(placer: () -> ())
	table.insert(placers, placer)
	placer()
	if not listening then
		listening = true
		ActionSpot.onChange(function()
			for _, each in placers do
				each()
			end
		end)
	end
end

-- Insignia con la tecla (E en PC, RT/R2 en el mando; nada en táctil).
local function keyBadge(button: TextButton)
	InputHints.badge(button, InputHints.ACTION_KEY, InputHints.HOLD_PAD)
end

-- Pescar y Alimentar: tamaño fijo en píxeles, en el lugar del pulgar.
local function mainButton(
	screen: ScreenGui,
	name: string,
	text: string,
	color: Color3,
	icon: string
): TextButton
	local button = ActionButton.new(screen, name, text, color, icon)
	addPlacer(function()
		local spot = ActionSpot.get()
		button.Position = UDim2.fromOffset(spot.right, spot.bottom)
		button.Size = UDim2.fromOffset(spot.size, spot.size)
	end)
	return button
end

function FishingButtons.cast(screen: ScreenGui): TextButton
	local button = mainButton(screen, "Pescar", "Pescar", COLORS.Fishing, "rod")
	keyBadge(button)
	return button
end

-- Mismo lugar que Pescar: en la orilla del volcán no se pesca, se alimenta.
function FishingButtons.feed(screen: ScreenGui): TextButton
	local button = mainButton(screen, "Alimentar", "Alimentar", COLORS.Feeding, "meat")
	ActionButton.rings(button, COLORS.Feeding, 1.1)
	keyBadge(button)
	return button
end

-- ¡TIRA!: su tamaño sale del alto de la pantalla (BITE_HEIGHT) con tope en
-- 1.25 veces Pescar; la esquina de abajo a la derecha es la misma que la de Pescar.
function FishingButtons.bite(screen: ScreenGui): TextButton
	local button = ActionButton.new(screen, "Tira", "¡TIRA!", COLORS.Bite, "fish")
	button.Size = UDim2.fromScale(BITE_HEIGHT, BITE_HEIGHT)
	local limit = Instance.new("UISizeConstraint")
	limit.Parent = button
	addPlacer(function()
		local spot = ActionSpot.get()
		button.Position = UDim2.fromOffset(spot.right, spot.bottom)
		limit.MaxSize = Vector2.one * math.floor(spot.size * BITE_GROWTH)
	end)
	ActionButton.rings(button, COLORS.Bite, 0.55)
	keyBadge(button)

	return button
end

return FishingButtons
