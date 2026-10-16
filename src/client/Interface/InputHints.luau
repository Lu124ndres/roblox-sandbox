--!strict
--[[
	InputHints

	Con qué está jugando ahora (teclado y mouse, mando de Xbox/PlayStation o
	pantalla táctil, según lo último que tocó) y cómo nombrar los botones:
		mode      "keyboard" | "gamepad" | "touch"
		onChange  avisa cuando cambia (enchufa un mando, toca la pantalla...)
		action    texto del botón de acción para los avisos: "E", "X" (Xbox),
		          "Cuadrado" (PlayStation) o "el botón" en táctil
		badge     insignia sobre un botón: la tecla en PC, el dibujo del botón
		          del mando en consola (el de Xbox o el de PlayStation, lo da
		          Roblox) y nada en táctil
	El botón de acción del mando es X (Cuadrado en PlayStation), igual que E.
]]

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)

export type Mode = "keyboard" | "gamepad" | "touch"

local COLORS = UIConfig.Colors
local PLAYSTATION_NAMES: { [Enum.KeyCode]: string } = {
	[Enum.KeyCode.ButtonX] = "Cuadrado",
	[Enum.KeyCode.ButtonY] = "Triángulo",
	[Enum.KeyCode.ButtonA] = "Equis",
	[Enum.KeyCode.ButtonB] = "Círculo",
}
local XBOX_NAMES: { [Enum.KeyCode]: string } = {
	[Enum.KeyCode.ButtonX] = "X",
	[Enum.KeyCode.ButtonY] = "Y",
	[Enum.KeyCode.ButtonA] = "A",
	[Enum.KeyCode.ButtonB] = "B",
}

local InputHints = {}

InputHints.ACTION_PAD = Enum.KeyCode.ButtonX
InputHints.ACTION_KEY = "E"

local function initial(): Mode
	if GuiService:IsTenFootInterface() then
		return "gamepad"
	elseif UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		return "touch"
	elseif UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled then
		return "gamepad"
	end
	return "keyboard"
end

local current: Mode = initial()
local listeners: { (mode: Mode) -> () } = {}

local function modeFor(input: Enum.UserInputType): Mode?
	if input == Enum.UserInputType.Touch then
		return "touch" :: Mode
	elseif input.Name:sub(1, 7) == "Gamepad" then
		return "gamepad" :: Mode
	elseif
		input == Enum.UserInputType.Keyboard
		or input == Enum.UserInputType.MouseButton1
		or input == Enum.UserInputType.MouseMovement
	then
		return "keyboard" :: Mode
	end
	return nil
end

UserInputService.LastInputTypeChanged:Connect(function(input: Enum.UserInputType)
	local found = modeFor(input)
	if found and found ~= current then
		local mode: Mode = found :: any
		current = mode
		for _, listener in listeners do
			task.spawn(listener, mode)
		end
	end
end)

function InputHints.mode(): Mode
	return current
end

function InputHints.onChange(listener: (mode: Mode) -> ())
	table.insert(listeners, listener)
end

-- ¿El mando es de PlayStation? (Roblox da los dibujos de su marca.)
function InputHints.playStation(): boolean
	local image = UserInputService:GetImageForKeyCode(Enum.KeyCode.ButtonX)
	return string.find(string.lower(image), "playstation", 1, true) ~= nil
end

-- Nombre del botón del mando para los textos.
function InputHints.padName(key: Enum.KeyCode): string
	local names = if InputHints.playStation() then PLAYSTATION_NAMES else XBOX_NAMES
	return names[key] or key.Name
end

-- Cómo se hace la acción principal (pescar, alimentar, entrenar) con lo que tiene.
function InputHints.action(): string
	if current == "gamepad" then
		return InputHints.padName(InputHints.ACTION_PAD)
	elseif current == "touch" then
		return "el botón"
	end
	return InputHints.ACTION_KEY
end

-- Insignia arriba a la derecha de `button`: tecla (PC) o botón del mando (consola).
function InputHints.badge(button: GuiObject, key: string, pad: Enum.KeyCode): Frame
	local badge = Instance.new("Frame")
	badge.Name = "Tecla"
	badge.AnchorPoint = Vector2.new(0.5, 0.5)
	badge.Position = UDim2.fromScale(0.84, 0.14)
	badge.Size = UDim2.fromScale(0.3, 0.3)
	badge.BackgroundColor3 = Color3.fromRGB(18, 26, 40)
	badge.ZIndex = button.ZIndex + 2
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.3, 0)
	corner.Parent = badge
	local stroke = Instance.new("UIStroke")
	stroke.Color = COLORS.Text
	stroke.Thickness = 2
	stroke.Parent = badge
	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.Position = UDim2.fromScale(0.1, 0.14)
	text.Size = UDim2.fromScale(0.8, 0.72)
	text.Text = key
	text.TextScaled = true
	text.FontFace = UIConfig.Fonts.Title
	text.TextColor3 = COLORS.Text
	text.ZIndex = badge.ZIndex + 1
	text.Parent = badge
	local glyph = Instance.new("ImageLabel")
	glyph.BackgroundTransparency = 1
	glyph.Position = UDim2.fromScale(0.08, 0.08)
	glyph.Size = UDim2.fromScale(0.84, 0.84)
	glyph.ScaleType = Enum.ScaleType.Fit
	glyph.ZIndex = badge.ZIndex + 1
	glyph.Parent = badge
	local function paint(mode: Mode)
		badge.Visible = mode ~= "touch"
		text.Visible = mode == "keyboard"
		glyph.Visible = mode == "gamepad"
		if mode == "gamepad" then
			glyph.Image = UserInputService:GetImageForKeyCode(pad)
		end
	end
	InputHints.onChange(paint)
	paint(current)
	badge.Parent = button
	return badge
end

return table.freeze(InputHints)
