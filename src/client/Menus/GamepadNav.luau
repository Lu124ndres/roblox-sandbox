--!strict
--[[
	GamepadNav

	Jugar con mando (Xbox o PlayStation) sin mouse:
		flechas        abren un menú directo, sin nada marcado ni ventana abierta
		               (pedido del usuario el 2026-10-21): arriba Mejoras, abajo
		               Tienda, izquierda Misiones, derecha Renacer
		Y (Triángulo)  abre o cierra el regalo gratis (PlaytimeWindow, setGift)
		A (Equis)      aprieta el botón marcado (lo hace Roblox)
		B (Círculo)    cierra la ventana abierta
	Cada uno de esos botones lleva el dibujo de su flecha o de la Y
	(GamepadHints).
	Al abrirse una ventana, la marca entra a su primer botón y no se sale de
	ella (SelectionGroup); al cerrarla se quita. La marca es un
	marco dorado. Select saca el cursor virtual de Roblox.
	Pescar, alimentar y entrenar no pasan por aquí: X (Cuadrado) o R2.
]]

local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

local InputHints = require(script.Parent.Parent.Interface.InputHints)
local GamepadHints = require(script.Parent.GamepadHints)
local HudButtons = require(script.Parent.HudButtons)
local Window = require(script.Parent.Window)

local GOLD = Color3.fromRGB(255, 214, 60)
local SELECT_DELAY = 0.15 -- espera a que la ventana termine de armarse
-- Qué botón grande del menú abre cada flecha.
local ARROWS: { [Enum.KeyCode]: string } = {
	[Enum.KeyCode.DPadUp] = "Mejoras",
	[Enum.KeyCode.DPadDown] = "Tienda",
	[Enum.KeyCode.DPadLeft] = "Misiones",
	[Enum.KeyCode.DPadRight] = "Renacer",
}

local GamepadNav = {}

local openWindow: Window.Window? = nil
local lastHud: GuiObject? = nil
local toggleGift: (() -> ())? = nil

-- Lo que hace Y: abrir o cerrar la ventana del regalo gratis.
function GamepadNav.setGift(toggle: () -> ())
	toggleGift = toggle
end

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
	GamepadHints.attach(Players.LocalPlayer.PlayerGui, ARROWS)
	Window.onAnyChange(onWindow)
	-- Con algo marcado o una ventana abierta, las flechas mueven la marca (Roblox).
	ContextActionService:BindAction(
		"FlechasMando",
		function(_, state: Enum.UserInputState, input: InputObject)
			if state ~= Enum.UserInputState.Begin or openWindow or GuiService.SelectedObject then
				return Enum.ContextActionResult.Pass
			end
			local text = ARROWS[input.KeyCode]
			local pressed = text and HudButtons.sidePress(text)
			local button = text
				and Players.LocalPlayer.PlayerGui:FindFirstChild(`Boton{text}`, true)
			if not pressed or not (button and button:IsA("GuiObject") and shown(button)) then
				return Enum.ContextActionResult.Pass
			end
			pressed()
			return Enum.ContextActionResult.Sink
		end,
		false,
		Enum.KeyCode.DPadUp,
		Enum.KeyCode.DPadDown,
		Enum.KeyCode.DPadLeft,
		Enum.KeyCode.DPadRight
	)
	ContextActionService:BindAction("RegaloMando", function(_, state: Enum.UserInputState)
		if state ~= Enum.UserInputState.Begin or not toggleGift then
			return Enum.ContextActionResult.Pass
		end
		toggleGift()
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
