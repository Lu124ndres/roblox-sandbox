--!strict
--[[
	ActionSpot

	El lugar del botón de acción principal (Pescar, Alimentar, ¡TIRA! y, en
	táctil, el aviso de los ProximityPrompt), abajo a la derecha:
		táctil  pegado a la izquierda del botón de saltar de Roblox, con la base
		        a su misma altura y 1.2 veces su tamaño (Roblox lo hace de 70 en
		        teléfonos y 120 en tablets: así el par se ve igual en todas)
		PC      en la esquina, según el alto de la pantalla
	`get` da la esquina de abajo a la derecha (en offset dentro de la pantalla
	del HUD, para AnchorPoint (1, 1)) y el lado del botón. `mount` deja una
	zona invisible del mismo tamaño para que las columnas del HUD no bajen ahí.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Device = require(script.Parent.Device)
local TouchControls = require(script.Parent.TouchControls)

local TOUCH_GROWTH = 1.2 -- el botón de acción, un poco más grande que Saltar
local GAP = 12 -- aire entre el botón y Saltar
-- Si el TouchGui todavía no está: dónde lo pone Roblox (tamaño, derecha, abajo).
local PHONE_JUMP = { size = 70, right = 95, bottom = 20 }
local TABLET_JUMP = { size = 120, right = 170, bottom = 90 }
local PC_MARGIN = 32
local PC_HEIGHT_FRACTION = 0.16
local PC_MIN_SIZE = 96

export type Spot = { right: number, bottom: number, size: number }

local ActionSpot = {}

local screen: ScreenGui? = nil
local listeners: { () -> () } = {}

local function area(): Vector2
	return if screen and screen.AbsoluteSize.Y > 0 then screen.AbsoluteSize else Device.viewport()
end

local function touchSpot(): Spot
	local origin = if screen then screen.AbsolutePosition else Vector2.zero
	local player = Players.LocalPlayer
	local playerGui = player and player:FindFirstChildOfClass("PlayerGui")
	local touchGui = playerGui and playerGui:FindFirstChild("TouchGui")
	local jump = touchGui and touchGui:FindFirstChild("JumpButton", true)
	if jump and jump:IsA("GuiObject") and TouchControls.jumpTop() then
		local left = jump.AbsolutePosition - origin
		return {
			right = left.X - GAP,
			bottom = left.Y + jump.AbsoluteSize.Y,
			size = math.floor(jump.AbsoluteSize.Y * TOUCH_GROWTH),
		}
	end
	local fallback = if Device.phone() then PHONE_JUMP else TABLET_JUMP
	local size = area()
	return {
		right = size.X - fallback.right - GAP,
		bottom = size.Y - fallback.bottom,
		size = math.floor(fallback.size * TOUCH_GROWTH),
	}
end

function ActionSpot.get(): Spot
	if Device.touch() then
		return touchSpot()
	end
	local size = area()
	local side = math.clamp(
		math.floor(size.Y * PC_HEIGHT_FRACTION),
		PC_MIN_SIZE,
		UIConfig.Spacing.CastButtonSize
	)
	return { right = size.X - PC_MARGIN, bottom = size.Y - PC_MARGIN, size = side }
end

-- `listener` corre cuando el lugar puede haber cambiado (pantalla o controles táctiles).
function ActionSpot.onChange(listener: () -> ())
	table.insert(listeners, listener)
end

local function notify()
	for _, listener in listeners do
		task.spawn(listener)
	end
end

-- Zona invisible del botón (las columnas la esquivan con Layout.avoid).
function ActionSpot.mount(gui: ScreenGui): Frame
	screen = gui
	local zone = Instance.new("Frame")
	zone.Name = "ZonaAccion"
	zone.BackgroundTransparency = 1
	zone.AnchorPoint = Vector2.new(1, 1)
	zone.Active = false
	zone.Interactable = false
	zone.Parent = gui
	local function place()
		local spot = ActionSpot.get()
		zone.Position = UDim2.fromOffset(spot.right, spot.bottom)
		zone.Size = UDim2.fromOffset(spot.size, spot.size)
	end
	ActionSpot.onChange(place)
	TouchControls.onChange(notify)
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(notify)
	place()
	return zone
end

return ActionSpot
