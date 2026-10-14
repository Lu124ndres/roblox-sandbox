--!strict
--[[
	Device

	Qué clase de pantalla tiene el jugador, para acomodar la interfaz al pulgar:
		touch   la pantalla es táctil (teléfono o tablet)
		phone   táctil y con el lado corto de 500 px o menos (el mismo corte que
		        usa Roblox para achicar su botón de saltar)
	`onResize` avisa cuando cambia el tamaño de la pantalla (girar el teléfono,
	cambiar el tamaño de la ventana en PC).
]]

local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local PHONE_SHORT_SIDE = 500
local FALLBACK_VIEWPORT = Vector2.new(1280, 720)

local Device = {}

function Device.viewport(): Vector2
	local camera = Workspace.CurrentCamera
	return if camera then camera.ViewportSize else FALLBACK_VIEWPORT
end

function Device.touch(): boolean
	return UserInputService.TouchEnabled
end

function Device.phone(): boolean
	local size = Device.viewport()
	return Device.touch() and math.min(size.X, size.Y) <= PHONE_SHORT_SIDE
end

function Device.onResize(callback: () -> ())
	local camera = Workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(callback)
	end
end

return Device
