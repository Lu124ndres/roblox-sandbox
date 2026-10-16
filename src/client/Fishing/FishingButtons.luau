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
		mando     igual que PC; X (Cuadrado en PlayStation) o R2, y lo muestran
	Se reacomodan si cambia la pantalla (girar el teléfono, ventana en PC).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Device = require(script.Parent.Parent.Interface.Device)
local InputHints = require(script.Parent.Parent.Interface.InputHints)
local ActionButton = require(script.Parent.ActionButton)

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

-- Insignia con la tecla (E en PC, X/Cuadrado en el mando; nada en táctil).
local function keyBadge(button: TextButton)
	InputHints.badge(button, InputHints.ACTION_KEY, InputHints.ACTION_PAD)
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
		local where = spot()
		button.Position = where.position
		button.Size = UDim2.fromOffset(where.size, where.size)
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
		local where = spot()
		button.Position = where.position
		limit.MaxSize = Vector2.one * math.floor(where.size * BITE_GROWTH)
	end)
	ActionButton.rings(button, COLORS.Bite, 0.55)
	keyBadge(button)

	return button
end

return FishingButtons
