--!strict
--[[
	GamepadNav

	Jugar con mando (Xbox o PlayStation) sin mouse:
		Y (Triángulo)  entra al menú del HUD (Tienda, Mejoras...); otra vez Y sale
		A (Equis)      aprieta el botón marcado (lo hace Roblox)
		B (Círculo)    cierra la ventana abierta o sale del menú
	Al abrirse una ventana, la marca entra a su primer botón y no se sale de
	ella (SelectionGroup); al cerrarla vuelve al botón del HUD. La marca es un
	marco dorado; con mando, arriba de la columna derecha dice "Y Menú" y
	"Select Ratón" (GamepadHint): Select saca el cursor virtual de Roblox.
	Pescar, alimentar y entrenar no pasan por aquí: X (Cuadrado) o R2.
]]

local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

local InputHints = require(script.Parent.Parent.Interface.InputHints)
local HudButtons = require(script.Parent.HudButtons)
local Window = require(script.Parent.Window)
local GamepadHint = require(script.Parent.GamepadHint)

local GOLD = Color3.fromRGB(255, 214, 60)
local SELECT_DELAY = 0.15 -- espera a que la ventana termine de armarse

local GamepadNav = {}

local openWindow: Window.Window? = nil
local lastHud: GuiObject? = nil

local function shown(object: GuiObject): boolean
	local current: Instance? = object
	while current and current:IsA("GuiObject") do
		if not current.Visible then
			return false
		end
		current = current.Parent
	end
	return object:IsDescendantOf(Players.LocalPlayer.PlayerGui)
end

-- El botón de más arriba a la izquierda dentro de `root` (sin la X de cerrar).
local function firstButton(root: Instance): GuiButton?
	local best: GuiButton? = nil
	for _, item in root:GetDescendants() do
		if item:IsA("GuiButton") and item.Selectable and item.Name ~= "Cerrar" and shown(item) then
			local position = item.AbsolutePosition
			if
				not best
				or position.Y < best.AbsolutePosition.Y - 4
				or (
					math.abs(position.Y - best.AbsolutePosition.Y) <= 4
					and position.X < best.AbsolutePosition.X
				)
			then
				best = item
			end
		end
	end
	return best
end

local function hudButton(): GuiObject?
	for _, button in HudButtons.all() do
		if button.Name == "BotonTienda" and shown(button) then
			return button
		end
	end
	for _, button in HudButtons.all() do
		if shown(button) then
			return button
		end
	end
	return nil
end

local function gamepad(): boolean
	return InputHints.mode() == "gamepad"
end

local function onWindow(window: Window.Window, opened: boolean)
	if opened then
		openWindow = window
		window.frame.SelectionGroup = true
		for _, side in { "Up", "Down", "Left", "Right" } do
			(window.frame :: any)[`SelectionBehavior{side}`] = Enum.SelectionBehavior.Stop
		end
		if not gamepad() then
			return
		end
		local from = GuiService.SelectedObject
		if from and not from:IsDescendantOf(window.frame) then
			lastHud = from
		end
		task.wait(SELECT_DELAY)
		if openWindow == window then
			GuiService.SelectedObject = firstButton(window.panel)
		end
	elseif openWindow == window then
		openWindow = nil
		local selected = GuiService.SelectedObject
		if selected and selected:IsDescendantOf(window.frame) then
			GuiService.SelectedObject = if gamepad()
					and lastHud
					and shown(lastHud)
				then lastHud
				else nil
		end
	end
end

-- El marco dorado de lo que está elegido con el mando.
local function selectionImage(): Frame
	local frame = Instance.new("Frame")
	frame.Name = "MarcoMando"
	frame.BackgroundColor3, frame.BackgroundTransparency = GOLD, 0.82
	frame.Size, frame.Position = UDim2.new(1, 12, 1, 12), UDim2.fromOffset(-6, -6)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = GOLD
	stroke.Thickness = 4
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = frame
	return frame
end

function GamepadNav.start()
	Players.LocalPlayer.PlayerGui.SelectionImageObject = selectionImage()
	Window.onAnyChange(onWindow)
	GamepadHint.start(gamepad)
	ContextActionService:BindAction("MenuMando", function(_, state: Enum.UserInputState)
		if state ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end
		if openWindow then
			openWindow.close()
		elseif GuiService.SelectedObject then
			GuiService.SelectedObject = nil
		else
			GuiService.SelectedObject = hudButton()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.ButtonY)
	ContextActionService:BindActionAtPriority("AtrasMando", function(_, state: Enum.UserInputState)
		if state ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end
		if openWindow then
			openWindow.close()
			return Enum.ContextActionResult.Sink
		elseif GuiService.SelectedObject then
			GuiService.SelectedObject = nil
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.ButtonB)
	InputHints.onChange(function(mode)
		if mode ~= "gamepad" then
			GuiService.SelectedObject = nil
		end
	end)
end

return table.freeze(GamepadNav)
