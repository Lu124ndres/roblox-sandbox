--!strict
--[[
	InputHints

	Con qué está jugando ahora (teclado y mouse, mando de Xbox/PlayStation o
	pantalla táctil, según lo último que tocó) y cómo nombrar los botones:
		mode      "keyboard" | "gamepad" | "touch"
		onChange  avisa cuando cambia (enchufa un mando, toca la pantalla...)
		action    texto del botón de acción para los avisos: "E", "X" (Xbox),
		          "Cuadrado" (PlayStation) o "el botón" en táctil
		holdAction  igual, para pescar y alimentar: en el mando dice el gatillo
		          (RT en Xbox, R2 en PlayStation)
		badge     insignia sobre un botón: la tecla en PC, el dibujo del botón
		          del mando en consola (el de Xbox o el de PlayStation, lo da
		          Roblox) y nada en táctil
	El botón de acción del mando es X (Cuadrado en PlayStation), igual que E.
	Pescar y alimentar aceptan X y el gatillo derecho, pero sus botones y
	avisos muestran el gatillo (HOLD_PAD, pedido del usuario: «que diga RT»).
]]

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Kit = require(script.Parent.Kit)

export type Mode = "keyboard" | "gamepad" | "touch"

local KEY_SLICE = 0.14 -- canto de la tecla de piedra (la insignia mide unos 20 px)
local PLAYSTATION_NAMES: { [Enum.KeyCode]: string } = {
	[Enum.KeyCode.ButtonX] = "Cuadrado",
	[Enum.KeyCode.ButtonY] = "Triángulo",
	[Enum.KeyCode.ButtonA] = "Equis",
	[Enum.KeyCode.ButtonB] = "Círculo",
	[Enum.KeyCode.ButtonR2] = "R2",
}
local XBOX_NAMES: { [Enum.KeyCode]: string } = {
	[Enum.KeyCode.ButtonX] = "X",
	[Enum.KeyCode.ButtonY] = "Y",
	[Enum.KeyCode.ButtonA] = "A",
	[Enum.KeyCode.ButtonB] = "B",
	[Enum.KeyCode.ButtonR2] = "RT",
}

local InputHints = {}

InputHints.ACTION_PAD = Enum.KeyCode.ButtonX
InputHints.HOLD_PAD = Enum.KeyCode.ButtonR2 -- el que se muestra para pescar y alimentar
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

-- Como action, para pescar y alimentar: en el mando, el gatillo derecho.
function InputHints.holdAction(): string
	if current == "gamepad" then
		return InputHints.padName(InputHints.HOLD_PAD)
	end
	return InputHints.action()
end

-- Insignia arriba a la derecha de `button`: tecla (PC) o botón del mando (consola).
function InputHints.badge(button: GuiObject, key: string, pad: Enum.KeyCode): Frame
	local badge = Instance.new("Frame")
	badge.Name = "Tecla"
	badge.AnchorPoint = Vector2.new(0.5, 0.5)
	badge.Position = UDim2.fromScale(0.84, 0.14)
	badge.Size = UDim2.fromScale(0.3, 0.3)
	badge.ZIndex = button.ZIndex + 2
	-- Tecla de piedra gris tallada (canto fino: la insignia es chica) con la letra dorada.
	Kit.skin(badge, "boton", Kit.STONE).SliceScale = KEY_SLICE
	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.Position = UDim2.fromScale(0.1, 0.14)
	text.Size = UDim2.fromScale(0.8, 0.72)
	text.Text = key
	text.TextScaled = true
	text.FontFace = UIConfig.Fonts.Title
	text.ZIndex = badge.ZIndex + 1
	text.Parent = badge
	Kit.gold(text)
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
