--!strict
--[[
	PromptDock

	En táctil, el aviso de los ProximityPrompt (PromptView) no flota sobre el
	objeto: va fijo en el lugar del botón de acción (Interface/ActionSpot), a la
	izquierda de Saltar, como Pescar (pedido del usuario, 2026-10-20). Así nunca
	se mete debajo de las columnas del HUD ni se sale de la pantalla según hacia
	dónde mire la cámara. Si Pescar, Alimentar o ¡TIRA! están a la vista, va
	justo encima de ellos. Queda debajo de las ventanas (DisplayOrder menor que
	el del HUD), así no se toca por error con un menú abierto.
]]

local ActionSpot = require(script.Parent.ActionSpot)

local HEIGHT_SHARE = 0.62 -- alto del aviso respecto del botón de acción
local GAP = 10 -- aire con el botón de acción si está a la vista
local ACTION_BUTTONS = { "Pescar", "Alimentar", "Tira" }

local PromptDock = {}

-- `size`: medida de la placa antes de escalar. Devuelve la pantalla y el marco
-- (anclado abajo a la derecha) donde va la placa.
function PromptDock.make(holder: Instance, size: Vector2): (ScreenGui, Frame)
	local gui = Instance.new("ScreenGui")
	gui.Name = "AvisoAccion"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false -- las mismas medidas que el HUD (ActionSpot)
	gui.DisplayOrder = 0
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local frame = Instance.new("Frame")
	frame.Name = "Marco"
	frame.BackgroundTransparency = 1
	frame.AnchorPoint = Vector2.new(1, 1)
	frame.Size = UDim2.fromOffset(size.X, size.Y)
	frame.Parent = gui
	local scale = Instance.new("UIScale")
	scale.Parent = frame

	local hud = holder:FindFirstChild("Juego")
	local function place()
		local spot = ActionSpot.get()
		local bottom = spot.bottom
		if hud and hud:IsA("GuiBase2d") then
			for _, name in ACTION_BUTTONS do
				local button = hud:FindFirstChild(name)
				if button and button:IsA("GuiObject") and button.Visible then
					local top = button.AbsolutePosition.Y - hud.AbsolutePosition.Y
					bottom = math.min(bottom, top - GAP)
				end
			end
		end
		scale.Scale = spot.size * HEIGHT_SHARE / size.Y
		frame.Position = UDim2.fromOffset(spot.right, bottom)
	end
	place()

	-- Se reacomoda si cambia el lugar de acción o aparece un botón de pesca.
	local connections: { RBXScriptConnection } = {}
	for _, name in { "ZonaAccion", table.unpack(ACTION_BUTTONS) } do
		local object = hud and hud:FindFirstChild(name)
		if object and object:IsA("GuiObject") then
			table.insert(connections, object:GetPropertyChangedSignal("Visible"):Connect(place))
			table.insert(
				connections,
				object:GetPropertyChangedSignal("AbsolutePosition"):Connect(place)
			)
			table.insert(
				connections,
				object:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
			)
		end
	end
	gui.Destroying:Connect(function()
		for _, connection in connections do
			connection:Disconnect()
		end
	end)
	return gui, frame
end

return PromptDock
